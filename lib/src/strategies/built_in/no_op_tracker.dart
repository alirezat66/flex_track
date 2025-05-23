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

/// Factory for creating mock trackers for testing
class MockTracker extends NoOpTracker {
  final List<BaseEvent> _capturedEvents = [];
  final List<Map<String, dynamic>> _capturedUserProperties = [];
  final List<String> _capturedUserIds = [];

  MockTracker({
    super.id = 'mock',
    super.name = 'Mock Tracker',
    super.enabled,
  }) : super(
          trackingEnabled: true,
        );

  /// Get all captured events (for testing assertions)
  List<BaseEvent> get capturedEvents => List.unmodifiable(_capturedEvents);

  /// Get all captured user properties (for testing assertions)
  List<Map<String, dynamic>> get capturedUserProperties =>
      List.unmodifiable(_capturedUserProperties);

  /// Get all captured user IDs (for testing assertions)
  List<String> get capturedUserIds => List.unmodifiable(_capturedUserIds);

  /// Clear all captured data
  void clearCapturedData() {
    _capturedEvents.clear();
    _capturedUserProperties.clear();
    _capturedUserIds.clear();
    resetCounters();
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    await super.doTrack(event); // Update counters
    _capturedEvents.add(event);
  }

  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    await super.doTrackBatch(events); // Update counters
    _capturedEvents.addAll(events);
  }

  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    _capturedUserProperties.add(Map<String, dynamic>.from(properties));
  }

  @override
  Future<void> doIdentifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    _capturedUserIds.add(userId);
    if (properties != null) {
      _capturedUserProperties.add(Map<String, dynamic>.from(properties));
    }
  }

  @override
  Future<void> doReset() async {
    await super.doReset();
    clearCapturedData();
  }

  @override
  Map<String, dynamic> getDebugInfo() {
    return {
      ...super.getDebugInfo(),
      'capturedEventsCount': _capturedEvents.length,
      'capturedUserPropertiesCount': _capturedUserProperties.length,
      'capturedUserIdsCount': _capturedUserIds.length,
    };
  }
}
