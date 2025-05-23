import '../../models/analytics_event.dart';

/// Interface for event routing strategies
abstract class EventRouterStrategy {
  /// Returns the set of tracker IDs that should receive this event
  Set<String> getTargetTrackers(BaseEvent event);
}


