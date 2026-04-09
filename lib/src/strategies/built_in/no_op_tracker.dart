import 'package:flex_track/src/models/event/base_event.dart';

import '../base_tracker_strategy.dart';

/// No-operation tracker that silently ignores all events
/// Useful for testing, feature flags, or temporarily disabling tracking
class NoOpTracker extends BaseTrackerStrategy {
  int _trackedEventsCount = 0;
  int _batchesTrackedCount = 0;
  DateTime? _lastEventTime;
  bool _trackingEnabled;

  NoOpTracker({
    super.id = 'no_op',
    super.name = 'No-Op Tracker',
    super.enabled,
    bool trackingEnabled = false, // Whether to count events (for testing)
  }) : _trackingEnabled = trackingEnabled;

  @override
  bool get isGDPRCompliant => true; // Doesn't store any data

  @override
  bool get supportsRealTime => true;

  @override
  int get maxBatchSize => 10000; // Can "handle" any batch size

  /// Number of events that have been "tracked" (for testing)
  int get trackedEventsCount => _trackedEventsCount;

  /// Number of batches that have been "tracked" (for testing)
  int get batchesTrackedCount => _batchesTrackedCount;

  /// Last event timestamp (for testing)
  DateTime? get lastEventTime => _lastEventTime;

  /// Reset counters (for testing)
  void resetCounters() {
    _trackedEventsCount = 0;
    _batchesTrackedCount = 0;
    _lastEventTime = null;
  }

  /// Enable/disable event counting
  void setTrackingEnabled(bool enabled) {
    _trackingEnabled = enabled;
  }

  @override
  Future<void> doInitialize() async {
    // No-op: nothing to initialize
    resetCounters();
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // No-op: silently ignore the event
    if (_trackingEnabled) {
      _trackedEventsCount++;
      _lastEventTime = event.timestamp;
    }
  }

  @override
  bool supportsBatchTracking() => true;

  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    // No-op: silently ignore all events
    if (_trackingEnabled) {
      _trackedEventsCount += events.length;
      _batchesTrackedCount++;
      if (events.isNotEmpty) {
        _lastEventTime = events.last.timestamp;
      }
    }
  }

  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    // No-op: silently ignore user properties
  }

  @override
  Future<void> doIdentifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    // No-op: silently ignore user identification
  }

  @override
  Future<void> doReset() async {
    // No-op: nothing to reset
    if (_trackingEnabled) {
      resetCounters();
    }
  }

  @override
  Future<void> doFlush() async {
    // No-op: nothing to flush
  }

  @override
  Map<String, dynamic> getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      'trackedEventsCount': _trackedEventsCount,
      'batchesTrackedCount': _batchesTrackedCount,
      'lastEventTime': _lastEventTime?.toIso8601String(),
      'trackingEnabled': _trackingEnabled,
    };
  }

  @override
  String toString() =>
      'NoOpTracker($id: silent tracker, events: $_trackedEventsCount)';
}

/// Factory for creating disabled no-op trackers
/// Useful for feature flags or environment-based configuration
class DisabledTracker extends NoOpTracker {
  DisabledTracker({
    super.id = 'disabled',
    super.name = 'Disabled Tracker',
  }) : super(
          enabled: false, // Always disabled
          trackingEnabled: false,
        );

  @override
  void enable() {
    // Override to prevent enabling
    // This tracker should always stay disabled
  }
}
