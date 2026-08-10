import 'package:flex_track/src/models/event/base_event.dart';

import 'no_op_tracker.dart';

/// Mock tracker for tests: records events, user properties, and user ids.
///
/// Prefer this over [NoOpTracker] when you need assertions on captured data.
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
