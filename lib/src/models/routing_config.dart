import 'package:flex_track/src/models/event_route_config.dart';

import 'analytics_event.dart';
import '../strategies/tracker_strategy.dart';

/// Configuration for routing events to specific trackers
class RoutingConfiguration {
  final List<EventRouteConfig> routes;
  final List<TrackerStrategy> defaultStrategies;

  const RoutingConfiguration({
    required this.routes,
    required this.defaultStrategies,
  });

  /// Returns the list of trackers that should handle the given event
  List<TrackerStrategy> getStrategiesForEvent(BaseEvent event) {
    final eventName = event.getName();
    final matchingRoute = routes.firstWhere(
      (route) => route.events.any((e) => e.getName() == eventName),
      orElse: () => EventRouteConfig(
        events: [event],
        strategies: defaultStrategies,
      ),
    );
    return matchingRoute.strategies;
  }
}
