import 'package:flex_track/src/models/event/base_event.dart';

import '../models/routing/event_category.dart';
import '../models/routing/tracker_group.dart';
import '../exceptions/configuration_exception.dart';
import 'routing_builder.dart';
import 'routing_rule_builder.dart';

/// Builder for configuring individual route targets
class RouteConfigBuilder<T extends BaseEvent> {
  final RoutingBuilder _parent;
  final Type? _eventType;
  final String? eventNamePattern;
  final RegExp? eventNameRegex;
  final EventCategory? category;
  final String? hasProperty;
  final dynamic propertyValue;
  final bool? containsPII;
  final bool? isHighVolume;
  final bool? isEssential;
  final bool isDefault;

  RouteConfigBuilder(
    this._parent, {
    Type? eventType,
    this.eventNamePattern,
    this.eventNameRegex,
    this.category,
    this.hasProperty,
    this.propertyValue,
    this.containsPII,
    this.isHighVolume,
    this.isEssential,
    this.isDefault = false,
  }) : _eventType = eventType ?? T;

  // ========== TARGET SPECIFICATION ==========

  /// Send to all registered trackers
  RoutingRuleBuilder toAll() {
    return RoutingRuleBuilder(_parent, this, TrackerGroup.all);
  }

  /// Send to specific trackers by ID
  RoutingRuleBuilder to(List<String> trackerIds) {
    if (trackerIds.isEmpty) {
      throw ConfigurationException(
        'Cannot route to empty tracker list',
        fieldName: 'trackerIds',
      );
    }

    final group = TrackerGroup('custom_${trackerIds.hashCode}', trackerIds);
    return RoutingRuleBuilder(_parent, this, group);
  }

  /// Send to predefined or custom group
  RoutingRuleBuilder toGroup(TrackerGroup group) {
    return RoutingRuleBuilder(_parent, this, group);
  }

  /// Send to group by name
  RoutingRuleBuilder toGroupNamed(String groupName) {
    final group = _parent.getGroup(groupName);
    if (group == null) {
      throw ConfigurationException(
        'Unknown tracker group: $groupName',
        fieldName: 'groupName',
      );
    }
    return RoutingRuleBuilder(_parent, this, group);
  }

  /// Send to development trackers only
  RoutingRuleBuilder toDevelopment() {
    return RoutingRuleBuilder(_parent, this, TrackerGroup.development);
  }

  // ========== CONVENIENCE METHODS ==========

  /// Route to all trackers (alias for toAll)
  RoutingRuleBuilder everywhere() => toAll();

  /// Route to development trackers (alias for toDevelopment)
  RoutingRuleBuilder debugOnly() => toDevelopment();

  /// Route to a single tracker
  RoutingRuleBuilder toTracker(String trackerId) {
    if (trackerId.isEmpty) {
      throw ConfigurationException(
        'Tracker ID cannot be empty',
        fieldName: 'trackerId',
      );
    }
    return to([trackerId]);
  }

  // ========== GETTERS FOR RULE BUILDER ==========

  Type? get eventType => _eventType;
  RoutingBuilder get parent => _parent;
}
