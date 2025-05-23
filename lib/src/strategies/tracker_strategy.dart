import '../models/analytics_event.dart';

/// Interface for analytics tracker implementations
abstract class TrackerStrategy {
  /// Initializes the tracker
  Future<void> initialize();

  /// Tracks an event using this tracker
  Future<void> track(BaseEvent event);
}

/// Base implementation of TrackerStrategy with common functionality
abstract class BaseTrackerStrategy implements TrackerStrategy {
  final bool enabled;

  BaseTrackerStrategy({
    this.enabled = true,
  });

  @override
  Future<void> track(BaseEvent event) async {
    if (!enabled) return;
    await doTrack(event);
  }

  /// Implement this method to perform the actual tracking
  Future<void> doTrack(BaseEvent event);

  @override
  Future<void> initialize() async {
    if (!enabled) return;
    await doInitialize();
  }

  /// Implement this method to perform the actual initialization
  Future<void> doInitialize();
}
