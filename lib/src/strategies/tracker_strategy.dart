import 'package:flex_track/src/models/event/base_event.dart';

/// Interface for analytics tracker implementations
abstract class TrackerStrategy {
  /// Unique identifier for this tracker
  String get id;

  /// Human-readable name for this tracker
  String get name;

  /// Whether this tracker is currently enabled
  bool get isEnabled;

  /// Whether this tracker is GDPR compliant
  /// Used for automatic routing of PII and sensitive data
  bool get isGDPRCompliant => false;

  /// Whether this tracker supports real-time events
  /// Used for routing time-sensitive events
  bool get supportsRealTime => true;

  /// Maximum events per batch for this tracker
  /// Used for batch optimization
  int get maxBatchSize => 100;

  /// Initializes the tracker
  /// Called once during FlexTrack setup
  Future<void> initialize();

  /// Tracks a single event using this tracker
  /// Should handle the actual implementation details
  Future<void> track(BaseEvent event);

  /// Tracks multiple events as a batch
  /// Override for trackers that support efficient batching
  Future<void> trackBatch(List<BaseEvent> events) async {
    for (final event in events) {
      await track(event);
    }
  }

  /// Flushes any pending events
  /// Called during app shutdown or when immediate delivery is needed
  Future<void> flush() async {
    // Default implementation does nothing
    // Override for trackers that buffer events
  }

  /// Enables the tracker
  void enable();

  /// Disables the tracker
  void disable();

  /// Sets user properties for this tracker
  /// Called when user information changes
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    // Default implementation does nothing
    // Override for trackers that support user properties
  }

  /// Identifies a user for this tracker
  /// Called when user logs in or user ID changes
  Future<void> identifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    // Default implementation does nothing
    // Override for trackers that support user identification
  }

  /// Resets the tracker state
  /// Called when user logs out or privacy reset is requested
  Future<void> reset() async {
    // Default implementation does nothing
    // Override for trackers that maintain state
  }

  /// Returns debug information about this tracker
  /// Useful for troubleshooting and monitoring
  Map<String, dynamic> getDebugInfo() {
    return {
      'id': id,
      'name': name,
      'enabled': isEnabled,
      'gdprCompliant': isGDPRCompliant,
      'supportsRealTime': supportsRealTime,
      'maxBatchSize': maxBatchSize,
    };
  }
}
