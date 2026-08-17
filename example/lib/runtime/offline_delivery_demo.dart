import 'package:flex_track/flex_track.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mutable, deterministic network and tracker failure controls used only by
/// the example application's Offline Delivery Lab.
class OfflineDeliveryDemo extends ChangeNotifier {
  OfflineDeliveryDemo();

  static final OfflineDeliveryDemo instance = OfflineDeliveryDemo();
  static const _networkAvailableKey = 'flex_track_demo_network_available';

  bool _isOnline = true;
  bool _retryTrackerFails = false;
  int _queueSize = 0;
  EventProcessingResult? _lastDispatch;
  QueueFlushResult? _lastFlush;
  SharedPreferences? _preferences;

  final DemoDeliveryTracker successTracker = DemoDeliveryTracker(
    id: 'demo_delivery_success',
    name: 'Demo reliable destination',
  );
  late final DemoDeliveryTracker retryTracker = DemoDeliveryTracker(
    id: 'demo_delivery_retry',
    name: 'Demo retry destination',
    shouldFail: () => _retryTrackerFails,
  );

  bool get isOnline => _isOnline;
  bool get retryTrackerFails => _retryTrackerFails;
  int get queueSize => _queueSize;
  EventProcessingResult? get lastDispatch => _lastDispatch;
  QueueFlushResult? get lastFlush => _lastFlush;

  bool get onlineProvider => _isOnline;

  /// Restores the simulated connectivity before FlexTrack starts. This makes
  /// process-restart behavior deterministic for the Delivery Lab.
  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    _isOnline = _preferences!.getBool(_networkAvailableKey) ?? true;
  }

  Future<void> setOnline(bool value) async {
    if (_isOnline == value) return;
    _isOnline = value;
    notifyListeners();
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_networkAvailableKey, value);
  }

  void setRetryTrackerFails(bool value) {
    if (_retryTrackerFails == value) return;
    _retryTrackerFails = value;
    notifyListeners();
  }

  Future<EventProcessingResult> track() async {
    _lastDispatch = await FlexTrack.track(
      OfflineDeliveryDemoEvent(
        sequence: successTracker.attemptCount + retryTracker.attemptCount + 1,
      ),
    );
    await refreshQueueSize();
    return _lastDispatch!;
  }

  Future<QueueFlushResult> flush() async {
    _lastFlush = await FlexTrack.flush();
    await refreshQueueSize();
    return _lastFlush!;
  }

  Future<void> refreshQueueSize() async {
    _queueSize = await FlexTrack.queuedEventCount;
    notifyListeners();
  }
}

class OfflineDeliveryDemoEvent extends BaseEvent {
  OfflineDeliveryDemoEvent({required this.sequence});

  final int sequence;

  @override
  String get name => 'demo_offline_delivery';

  @override
  Map<String, Object> get properties => {
        'sequence': sequence,
        'source': 'offline_delivery_lab',
      };

  @override
  bool get requiresConsent => false;
}

class DemoDeliveryTracker extends BaseTrackerStrategy {
  DemoDeliveryTracker({
    required super.id,
    required super.name,
    this.shouldFail,
  });

  final bool Function()? shouldFail;
  int attemptCount = 0;
  int successCount = 0;
  final List<String> deliveredEventIds = [];

  @override
  Future<void> doInitialize() async {}

  @override
  Future<void> doTrack(BaseEvent event) async {
    // These trackers are registered globally so broad demo rules can resolve
    // to them. Keep Lab metrics and intentional failures scoped to its event.
    if (event.name != 'demo_offline_delivery') return;
    attemptCount++;
    if (shouldFail?.call() ?? false) {
      throw StateError('Intentional demo failure from $id');
    }
    successCount++;
    deliveredEventIds.add(event.eventId);
  }
}
