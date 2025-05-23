import 'analytics_event.dart';
import '../strategies/tracker_strategy.dart';

/// Configuration for routing events to specific trackers
class EventRouteConfig {
  final List<BaseEvent> events;
  final List<TrackerStrategy> strategies;

  const EventRouteConfig({
    required this.events,
    required this.strategies,
  });

  /// Returns true if this route config handles the given event
  bool handlesEvent(BaseEvent event) {
    return events.any((e) => e.getName() == event.getName());
  }

  /// Returns a map of event names to tracker names for debugging
  Map<String, Set<String>> toRouteMap() {
    return {
      for (var event in events)
        event.getName():
            strategies.map((s) => s.runtimeType.toString()).toSet(),
    };
  }
}
