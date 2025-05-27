import 'package:flex_track/src/models/event/base_event.dart';

import '../base_tracker_strategy.dart';

/// Console tracker that prints events to the debug console
/// Perfect for development and debugging
class ConsoleTracker extends BaseTrackerStrategy {
  final bool _showProperties;
  final bool _showTimestamps;
  final bool _colorOutput;
  final String _prefix;
  final List<BaseEvent> _eventHistory = [];

  ConsoleTracker({
    super.id = 'console',
    super.name = 'Console Tracker',
    super.enabled,
    bool showProperties = true,
    bool showTimestamps = true,
    bool colorOutput = true,
    String prefix = '📊 FlexTrack',
  })  : _showProperties = showProperties,
        _showTimestamps = showTimestamps,
        _colorOutput = colorOutput,
        _prefix = prefix;

  @override
  bool get isGDPRCompliant => true; // Console output doesn't store data

  @override
  bool get supportsRealTime => true;

  @override
  int get maxBatchSize => 1000; // Console can handle large batches

  /// Get the event history (for testing/debugging)
  List<BaseEvent> get eventHistory => List.unmodifiable(_eventHistory);

  /// Clear the event history
  void clearHistory() {
    _eventHistory.clear();
  }

  @override
  Future<void> doInitialize() async {
    _log('🚀 Console Tracker initialized', isInfo: true);
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    _eventHistory.add(event);

    final buffer = StringBuffer();

    // Add prefix and timestamp
    if (_showTimestamps) {
      buffer.write('[${_formatTimestamp(event.timestamp)}] ');
    }
    buffer.write('$_prefix: ');

    // Add event name
    buffer.write(event.name);

    // Add category if available
    if (event.category != null) {
      buffer.write(' (${event.category!.name})');
    }

    // Add user info if available
    if (event.userId != null) {
      buffer.write(' [User: ${event.userId}]');
    }

    if (event.sessionId != null) {
      buffer.write(' [Session: ${event.sessionId}]');
    }

    _log(buffer.toString());

    // Show properties if enabled
    if (_showProperties && event.properties != null) {
      final properties = event.properties!;
      if (properties.isNotEmpty) {
        _log('  Properties: ${_formatProperties(properties)}', indent: 2);
      }
    }

    // Show flags if any are set
    final flags = <String>[];
    if (event.containsPII) flags.add('PII');
    if (event.isHighVolume) flags.add('HIGH_VOLUME');
    if (event.isEssential) flags.add('ESSENTIAL');
    if (!event.requiresConsent) flags.add('NO_CONSENT_REQUIRED');

    if (flags.isNotEmpty) {
      _log('  Flags: ${flags.join(', ')}', indent: 2);
    }
  }

  @override
  bool supportsBatchTracking() => true;

  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    _log('📦 Batch tracking ${events.length} events:', isInfo: true);

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      _eventHistory.add(event);

      final buffer = StringBuffer();
      buffer.write('  ${i + 1}. ${event.name}');

      if (event.category != null) {
        buffer.write(' (${event.category!.name})');
      }

      if (event.userId != null) {
        buffer.write(' [${event.userId}]');
      }

      _log(buffer.toString());

      if (_showProperties && event.properties != null) {
        final properties = event.properties!;
        if (properties.isNotEmpty) {
          _log('     Props: ${_formatProperties(properties, compact: true)}',
              indent: 6);
        }
      }
    }
  }

  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    _log('👤 User properties updated: ${_formatProperties(properties)}',
        isInfo: true);
  }

  @override
  Future<void> doIdentifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    final buffer = StringBuffer();
    buffer.write('🔍 User identified: $userId');

    if (properties != null && properties.isNotEmpty) {
      buffer.write(
          ' with properties: ${_formatProperties(properties, compact: true)}');
    }

    _log(buffer.toString(), isInfo: true);
  }

  @override
  Future<void> doReset() async {
    _log('🔄 Tracker reset - clearing user data', isInfo: true);
  }

  @override
  Future<void> doFlush() async {
    _log('💾 Flushed ${_eventHistory.length} events from history',
        isInfo: true);
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Format properties for display
  String _formatProperties(Map<String, dynamic> properties,
      {bool compact = false}) {
    if (properties.isEmpty) return '{}';

    if (compact || properties.length <= 3) {
      return '{${properties.entries.map((e) => '${e.key}: ${e.value}').join(', ')}}';
    }

    final buffer = StringBuffer('{\n');
    for (final entry in properties.entries) {
      buffer.write('    ${entry.key}: ${entry.value}\n');
    }
    buffer.write('  }');
    return buffer.toString();
  }

  /// Log a message with optional formatting
  void _log(String message, {bool isInfo = false, int indent = 0}) {
    final indentStr = '  ' * indent;
    final finalMessage = '$indentStr$message';

    if (_colorOutput && isInfo) {
      // Blue color for info messages (ANSI escape codes)
      // ignore: avoid_print
      print('\x1B[34m$finalMessage\x1B[0m');
    } else if (_colorOutput) {
      // Green color for regular events
      // ignore: avoid_print
      print('\x1B[32m$finalMessage\x1B[0m');
    } else {
      // ignore: avoid_print
      print(finalMessage);
    }
  }

  @override
  Map<String, dynamic> getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      'showProperties': _showProperties,
      'showTimestamps': _showTimestamps,
      'colorOutput': _colorOutput,
      'prefix': _prefix,
      'eventHistoryCount': _eventHistory.length,
      'lastEventTime': _eventHistory.isNotEmpty
          ? _eventHistory.last.timestamp.toIso8601String()
          : null,
    };
  }
}
