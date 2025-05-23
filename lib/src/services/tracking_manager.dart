import '../models/analytics_event.dart';
import '../models/routing_config.dart';
import '../strategies/tracker_strategy.dart';

/// Manages analytics tracking and routing
class TrackingManager {
  static TrackingManager? _instance;
  final List<TrackerStrategy> _trackers = [];
  late final RoutingConfiguration _routingConfig;
  bool _initialized = false;

  TrackingManager._();

  /// Returns the singleton instance of TrackingManager
  static TrackingManager get instance {
    _instance ??= TrackingManager._();
    return _instance!;
  }

  /// Registers multiple trackers with the manager
  void registerTrackers(List<TrackerStrategy> trackers) {
    _trackers.addAll(trackers);
  }

  /// Sets the routing configuration for event tracking
  void setRoutingConfiguration(RoutingConfiguration config) {
    _routingConfig = config;
  }

  /// Initializes all registered trackers
  Future<void> initialize() async {
    if (_initialized) return;

    for (final tracker in _trackers) {
      await tracker.initialize();
    }

    _initialized = true;
  }

  /// Tracks an event using the configured routing
  Future<void> track(BaseEvent event) async {
    if (!_initialized) {
      throw StateError(
          'TrackingManager must be initialized before tracking events');
    }

    final targetStrategies = _routingConfig.getStrategiesForEvent(event);
    for (final strategy in targetStrategies) {
      await strategy.track(event);
    }
  }
}
