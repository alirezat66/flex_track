import 'package:flex_track/flex_track.dart';

/// Implementation of EventRouterStrategy that uses rules to determine target trackers
class RuleBasedEventRouter implements EventRouterStrategy {
  final Map<String, Set<String>> _rules;
  final Set<String> _allTrackers = {};

  RuleBasedEventRouter({
    Map<String, Set<String>>? rules,
  }) : _rules = rules ?? {};

  /// Updates the set of all available trackers
  void updateAvailableTrackers(Set<String> trackerIds) {
    _allTrackers.clear();
    _allTrackers.addAll(trackerIds);
  }

  /// Adds a routing rule for a specific event name
  void addRule(String eventName, Set<String> trackerIds) {
    _rules[eventName] = trackerIds;
  }

  /// Removes a routing rule for a specific event name
  void removeRule(String eventName) {
    _rules.remove(eventName);
  }

  @override
  Set<String> getTargetTrackers(BaseEvent event) {
    final eventName = event.getName();
    // If there's a specific rule, use it; otherwise, use all trackers
    return _rules[eventName] ?? _allTrackers;
  }
}
