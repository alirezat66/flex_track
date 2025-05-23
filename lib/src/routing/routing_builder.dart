import 'package:flex_track/src/exceptions/configuration_exception.dart';
import 'package:flex_track/src/models/event/base_event.dart';

import '../models/routing/event_category.dart';
import '../models/routing/tracker_group.dart';
import '../models/routing/routing_rule.dart';
import '../models/routing/routing_config.dart';
import 'route_config_builder.dart';

/// Main builder for creating routing configurations
class RoutingBuilder {
  final List<RoutingRule> _rules = [];
  final Map<String, TrackerGroup> _customGroups = {};
  final Map<String, EventCategory> _customCategories = {};
  TrackerGroup? _defaultGroup;
  bool _enableSampling = true;
  bool _enableConsentChecking = true;
  bool _isDebugMode = false;

  /// Creates a new routing builder
  RoutingBuilder();

  /// Creates a routing builder with smart defaults pre-applied
  factory RoutingBuilder.withSmartDefaults() {
    return RoutingBuilder()..applySmartDefaults();
  }

  // ========== GROUP MANAGEMENT ==========

  /// Define a custom tracker group
  RoutingBuilder defineGroup(String name, List<String> trackerIds,
      {String? description}) {
    if (name.isEmpty) {
      throw ConfigurationException('Group name cannot be empty',
          fieldName: 'name');
    }

    if (trackerIds.isEmpty) {
      throw ConfigurationException('Group must contain at least one tracker ID',
          fieldName: 'trackerIds');
    }

    _customGroups[name] =
        TrackerGroup(name, trackerIds, description: description);
    return this;
  }

  /// Define a custom event category
  RoutingBuilder defineCategory(String name, {String? description}) {
    if (name.isEmpty) {
      throw ConfigurationException('Category name cannot be empty',
          fieldName: 'name');
    }

    _customCategories[name] = EventCategory(name, description: description);
    return this;
  }

  /// Set the default tracker group for unmatched events
  RoutingBuilder setDefaultGroup(TrackerGroup group) {
    _defaultGroup = group;
    return this;
  }

  /// Set default group by name
  RoutingBuilder setDefaultGroupNamed(String groupName) {
    final group = getGroup(groupName);
    if (group == null) {
      throw ConfigurationException('Unknown group: $groupName',
          fieldName: 'groupName');
    }
    return setDefaultGroup(group);
  }

  // ========== CONFIGURATION OPTIONS ==========

  /// Enable or disable sampling globally
  RoutingBuilder setSampling(bool enabled) {
    _enableSampling = enabled;
    return this;
  }

  /// Enable or disable consent checking globally
  RoutingBuilder setConsentChecking(bool enabled) {
    _enableConsentChecking = enabled;
    return this;
  }

  /// Set debug mode
  RoutingBuilder setDebugMode(bool isDebug) {
    _isDebugMode = isDebug;
    return this;
  }

  // ========== SIMPLE ROUTING METHODS ==========

  /// Route specific event type to trackers
  RouteConfigBuilder<T> route<T extends BaseEvent>() {
    return RouteConfigBuilder<T>(this, eventType: T);
  }

  /// Route by event name pattern (substring match)
  RouteConfigBuilder routeNamed(String pattern) {
    if (pattern.isEmpty) {
      throw ConfigurationException('Event name pattern cannot be empty',
          fieldName: 'pattern');
    }
    return RouteConfigBuilder(this, eventNamePattern: pattern);
  }

  /// Route by regex pattern
  RouteConfigBuilder routeMatching(RegExp pattern) {
    return RouteConfigBuilder(this, eventNameRegex: pattern);
  }

  /// Route by exact event name
  RouteConfigBuilder routeExact(String eventName) {
    if (eventName.isEmpty) {
      throw ConfigurationException('Event name cannot be empty',
          fieldName: 'eventName');
    }
    return RouteConfigBuilder(this,
        eventNameRegex: RegExp('^${RegExp.escape(eventName)}\$'));
  }

  /// Route by category
  RouteConfigBuilder routeCategory(EventCategory category) {
    return RouteConfigBuilder(this, category: category);
  }

  /// Route by custom category name
  RouteConfigBuilder routeCategoryNamed(String categoryName) {
    final category = getCategory(categoryName);
    if (category == null) {
      throw ConfigurationException('Unknown category: $categoryName',
          fieldName: 'categoryName');
    }
    return RouteConfigBuilder(this, category: category);
  }

  /// Route events with specific properties
  RouteConfigBuilder routeWithProperty(String propertyName, [dynamic value]) {
    if (propertyName.isEmpty) {
      throw ConfigurationException('Property name cannot be empty',
          fieldName: 'propertyName');
    }
    return RouteConfigBuilder(this,
        hasProperty: propertyName, propertyValue: value);
  }

  /// Route events containing PII
  RouteConfigBuilder routePII() {
    return RouteConfigBuilder(this, containsPII: true);
  }

  /// Route high-volume events
  RouteConfigBuilder routeHighVolume() {
    return RouteConfigBuilder(this, isHighVolume: true);
  }

  /// Route essential events
  RouteConfigBuilder routeEssential() {
    return RouteConfigBuilder(this, isEssential: true);
  }

  /// Default fallback routing
  RouteConfigBuilder routeDefault() {
    _defaultGroup = TrackerGroup.all; // Ensure default group is set when a default rule is added
    return RouteConfigBuilder(this, isDefault: true);
  }

  // ========== PRESET CONFIGURATIONS ==========

  /// Apply smart defaults for common use cases
  RoutingBuilder applySmartDefaults() {
    // Technical events go to development trackers in debug mode
    routeCategory(EventCategory.technical)
        .toDevelopment()
        .onlyInDebug()
        .lightSampling()
        .withPriority(8)
        .and();

    // High volume events get sampled
    routeHighVolume().toAll().heavySampling().withPriority(5).and();

    // Everything else goes everywhere
    routeDefault().toAll().and();

    return this;
  }


  // ========== BULK OPERATIONS ==========

  /// Add multiple rules at once
  RoutingBuilder addRules(List<RoutingRule> rules) {
    _rules.addAll(rules);
    return this;
  }

  /// Add a single rule (called by RouteConfigBuilder)
  void addRule(RoutingRule rule) {
    _rules.add(rule);
  }

  /// Clear all rules
  RoutingBuilder clearRules() {
    _rules.clear();
    return this;
  }

  /// Remove rules matching a condition
  RoutingBuilder removeRulesWhere(bool Function(RoutingRule) test) {
    _rules.removeWhere(test);
    return this;
  }

  // ========== HELPER METHODS ==========

  /// Get a tracker group by name (custom or predefined)
  TrackerGroup? getGroup(String name) {
    // Check custom groups first
    if (_customGroups.containsKey(name)) {
      return _customGroups[name];
    }

    // Check predefined groups
    switch (name) {
      case 'all':
        return TrackerGroup.all;
      case 'development':
        return TrackerGroup.development;
      default:
        return null;
    }
  }

  /// Get a category by name (custom or predefined)
  EventCategory? getCategory(String name) {
    // Check custom categories first
    if (_customCategories.containsKey(name)) {
      return _customCategories[name];
    }

    // Check predefined categories
    switch (name) {
      case 'business':
        return EventCategory.business;
      case 'user':
        return EventCategory.user;
      case 'technical':
        return EventCategory.technical;
      case 'sensitive':
        return EventCategory.sensitive;
      case 'marketing':
        return EventCategory.marketing;
      case 'system':
        return EventCategory.system;
      case 'security':
        return EventCategory.security;
      default:
        return null;
    }
  }

  /// Get all available groups
  List<TrackerGroup> getAllGroups() {
    return [
      TrackerGroup.all,
      TrackerGroup.development,
      ..._customGroups.values,
    ];
  }

  /// Get all available categories
  List<EventCategory> getAllCategories() {
    return [
      ...EventCategory.predefined,
      ..._customCategories.values,
    ];
  }

  /// Build the final routing configuration
  RoutingConfiguration build() {
    // Ensure we have a default rule if no default group is set
    final hasDefaultRule = _rules.any((rule) => rule.isDefault);
    if (!hasDefaultRule && _defaultGroup == null) {
      // Add a fallback default rule that routes to all trackers
      _rules.add(RoutingRule(
        isDefault: true,
        targetGroup: TrackerGroup.all,
        description: 'Auto-generated default rule',
        priority: -1000, // Lowest priority
      ));
    }

    // Sort rules by priority (highest first)
    _rules.sort((a, b) => b.priority.compareTo(a.priority));

    return RoutingConfiguration(
      rules: List.unmodifiable(_rules),
      customGroups: Map.unmodifiable(_customGroups),
      customCategories: Map.unmodifiable(_customCategories),
      defaultGroup: _defaultGroup,
      enableSampling: _enableSampling,
      enableConsentChecking: _enableConsentChecking,
      isDebugMode: _isDebugMode,
    );
  }

  /// Validate the current configuration
  List<String> validate() {
    return build().validate();
  }

  /// Get debug information about the current state
  Map<String, dynamic> getDebugInfo() {
    return {
      'rulesCount': _rules.length,
      'customGroupsCount': _customGroups.length,
      'customCategoriesCount': _customCategories.length,
      'hasDefaultGroup': _defaultGroup != null,
      'enableSampling': _enableSampling,
      'enableConsentChecking': _enableConsentChecking,
      'isDebugMode': _isDebugMode,
      'rules': _rules.map((rule) => rule.toString()).toList(),
      'customGroups': _customGroups.keys.toList(),
      'customCategories': _customCategories.keys.toList(),
    };
  }
}
