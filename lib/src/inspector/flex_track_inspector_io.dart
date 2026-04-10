import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flex_track/flex_track.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'dashboard.dart';
import 'inspector_event_buffer.dart';

/// Debug-only local HTTP + WebSocket inspector (VM / mobile / desktop).
///
/// Call [start] after [FlexTrack.setup]. In release mode or on unsupported
/// platforms this is a no-op. Use [url] for an in-app link or SnackBar.
class FlexTrackInspector {
  FlexTrackInspector._();

  /// Base URL when the server is running, e.g. `http://127.0.0.1:7788`.
  static String? get url => _FlexTrackInspectorServer.url;

  /// Starts the inspector server if [kDebugMode] is true.
  ///
  /// If [port] is in use, tries up to 10 consecutive ports. Prints the URL to
  /// the console. Returns the URL, or `null` if not started.
  static Future<String?> start({int port = 7788}) async {
    if (!kDebugMode) {
      return null;
    }
    return _FlexTrackInspectorServer.instance.start(port: port);
  }

  /// Stops the server and releases sockets and subscriptions.
  static Future<void> stop() async {
    if (!kDebugMode) {
      return;
    }
    await _FlexTrackInspectorServer.instance.stop();
  }
}

class _FlexTrackInspectorServer {
  _FlexTrackInspectorServer._();
  static final _FlexTrackInspectorServer instance =
      _FlexTrackInspectorServer._();

  static String? url;

  final InspectorEventBuffer _buffer = InspectorEventBuffer();
  final Set<WebSocketChannel> _channels = {};
  HttpServer? _server;
  Timer? _flexPoll;
  StreamSubscription<EventDispatchRecord>? _eventSub;
  StreamSubscription<void>? _stateSub;
  bool _alive = false;

  static final Random _secureRandom = Random.secure();

  Future<String?> start({int port = 7788}) async {
    if (_server != null) {
      return url;
    }

    final handler = _buildHandler();
    const maxAttempts = 10;
    HttpServer? server;
    var boundPort = port;

    for (var i = 0; i < maxAttempts; i++) {
      final tryPort = port + i;
      try {
        server = await shelf_io.serve(
          handler,
          InternetAddress.loopbackIPv4,
          tryPort,
        );
        boundPort = tryPort;
        break;
      } on SocketException {
        if (i == maxAttempts - 1) {
          debugPrint(
            '[FlexTrack Inspector] Could not bind a port in range '
            '$port..${port + maxAttempts - 1}',
          );
          return null;
        }
      }
    }

    if (server == null) {
      return null;
    }

    _server = server;
    _alive = true;
    final host = server.address.type == InternetAddressType.IPv6
        ? '[${server.address.address}]'
        : server.address.address;
    final base = 'http://$host:$boundPort';
    url = base;
    debugPrint('[FlexTrack Inspector] Running at $base');

    _startPollingFlex();
    _attachListeners();
    _broadcastStatus();

    return base;
  }

  Future<void> stop() async {
    _alive = false;
    _flexPoll?.cancel();
    _flexPoll = null;
    await _eventSub?.cancel();
    await _stateSub?.cancel();
    _eventSub = null;
    _stateSub = null;

    for (final ch in _channels.toList()) {
      try {
        await ch.sink.close();
      } catch (_) {}
    }
    _channels.clear();

    final s = _server;
    _server = null;
    url = null;
    if (s != null) {
      try {
        await s.close(force: true);
      } catch (_) {}
    }
  }

  Handler _buildHandler() {
    final router = Router()
      ..get('/', _handleRoot)
      ..get('/api/status', _handleStatus)
      ..get('/api/events', _handleEvents)
      ..delete('/api/events', _handleClearEvents)
      ..get('/ws', webSocketHandler(_handleWebSocket));

    return router.call;
  }

  Response _handleRoot(Request request) {
    return Response.ok(
      flexTrackInspectorDashboardHtml,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  Response _handleStatus(Request request) {
    final payload = _buildStatusPayload();
    return Response.ok(
      jsonEncode(payload),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Response _handleEvents(Request request) {
    final list =
        _buffer.snapshot.map((r) => r.toEventPayload()).toList(growable: false);
    return Response.ok(
      jsonEncode(list),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  Future<Response> _handleClearEvents(Request request) async {
    _buffer.clear();
    return Response.ok(
      jsonEncode({'ok': true}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  void _handleWebSocket(WebSocketChannel channel) {
    _channels.add(channel);
    try {
      channel.sink.add(jsonEncode(_statusMessageMap()));
    } catch (_) {}

    channel.stream.listen(
      (_) {},
      onDone: () => _channels.remove(channel),
      onError: (_) => _channels.remove(channel),
      cancelOnError: true,
    );
  }

  Map<String, Object?> _buildStatusPayload() {
    if (!FlexTrack.isSetUp) {
      return {
        'isSetUp': false,
        'isEnabled': false,
        'trackers': <Object>[],
        'consent': <String, bool>{},
        'validation': <String>['FlexTrack is not set up'],
      };
    }

    final trackers = <Map<String, Object?>>[];
    for (final t in FlexTrack.instance.trackerRegistry.registeredTrackers) {
      trackers.add({
        'id': t.id,
        'name': t.name,
        'enabled': t.isEnabled,
      });
    }

    return {
      'isSetUp': true,
      'isEnabled': FlexTrack.isEnabled,
      'trackers': trackers,
      'consent': FlexTrack.getConsentStatus(),
      'validation': FlexTrack.validate(),
    };
  }

  Map<String, Object?> _statusMessageMap() => {
        'type': 'status',
        'data': _buildStatusPayload(),
      };

  void _broadcastStatus() {
    _broadcastWs(jsonEncode(_statusMessageMap()));
  }

  void _broadcastWs(String message) {
    for (final ch in _channels.toList()) {
      try {
        ch.sink.add(message);
      } catch (_) {
        _channels.remove(ch);
      }
    }
  }

  void _onFlexDispatch(EventDispatchRecord dispatch) {
    final now = DateTime.now();
    final label = _formatTime(now);
    final id = _uuidV4();
    final rec = _buffer.append(dispatch, id, label);
    _broadcastWs(jsonEncode(rec.toWsMessage()));
  }

  void _attachListeners() {
    if (!_alive) {
      return;
    }
    if (!FlexTrack.isSetUp) {
      return;
    }
    _eventSub ??= FlexTrack.eventDispatchStream.listen(
      _onFlexDispatch,
      onDone: () => _eventSub = null,
    );
    _stateSub ??= FlexTrack.debugStateStream.listen(
      (_) => _broadcastStatus(),
      onDone: () => _stateSub = null,
    );
  }

  void _startPollingFlex() {
    _flexPoll?.cancel();
    _flexPoll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_alive) {
        return;
      }
      _attachListeners();
    });
  }

  static String _formatTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}.${three(d.millisecond)}';
  }

  static String _uuidV4() {
    final b = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    const hex = '0123456789abcdef';
    final sb = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        sb.write('-');
      }
      sb.write(hex[b[i] >> 4]);
      sb.write(hex[b[i] & 0x0f]);
    }
    return sb.toString();
  }
}
