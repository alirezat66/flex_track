import 'package:flex_track/flex_track.dart';

/// Implementation of EventRouterStrategy that routes all events to all trackers
class BroadcastEventRouter implements EventRouterStrategy {
  final Set<String> _allTrackers = {};

  /// Updates the set of all available trackers
  void updateAvailableTrackers(Set<String> trackerIds) {
    _allTrackers.clear();
    _allTrackers.addAll(trackerIds);
  }

  @override
  Set<String> getTargetTrackers(BaseEvent event) => _allTrackers;
}
