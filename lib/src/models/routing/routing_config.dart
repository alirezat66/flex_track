
import 'package:flex_track/src/models/event/base_event.dart';

import 'routing_rule.dart';
import 'tracker_group.dart';
import 'event_category.dart';

/// Complete routing configuration that contains all rules and settings
class RoutingConfiguration {
  final List<RoutingRule> rules;
  final Map<String, TrackerGroup> customGroups;
  final Map<String, EventCategory> customCategories;
  final TrackerGroup? defaultGroup;
  final bool enableSampling;
  final bool enableConsentChecking;
  final bool isDebugMode;

  const RoutingConfiguration({
    required this.rules,
    this.customGroups = const {},
    this.customCategories = const {},
    this.defaultGroup,
    this.enableSampling = true,
    this.enableConsentChecking = true,
    this.isDebugMode = false,
  });

  /// Creates an empty routing configuration
  factory RoutingConfiguration.empty() {
    return const RoutingConfiguration(rules: []);
  }

  /// Creates a routing configuration with smart defaults
  factory RoutingConfiguration.withSmartDefaults() {
    return RoutingConfiguration(
      rules: [
        // Technical events go to development trackers in debug mode
        RoutingRule(
          category: EventCategory.technical,
          targetGroup: TrackerGroup.development,
          debugOnly: true,
          sampleRate: 0.1,
          priority: 8,
          description: 'Technical events in debug mode',
        ),

        // High volume events get sampled
        RoutingRule(
          isHighVolume: true,
          targetGroup: TrackerGroup.all,
          sampleRate: 0.05,
          priority: 5,
          description: 'High volume events with sampling',
        ),

        // Default rule
        RoutingRule(
          isDefault: true,
          targetGroup: TrackerGroup.all,
          priority: 0,
          description: 'Default routing rule',
        ),
      ],
      defaultGroup: TrackerGroup.all,
    );
  }

  /// Returns all rules that match the given event, sorted by priority
  List<RoutingRule> getMatchingRules(BaseEvent event) {
    final matchingRules = rules
        .where((rule) => rule.matches(event, isDebugMode: isDebugMode))
        .toList();

    if (matchingRules.isEmpty) {
      // If no rules match, use default rule if available
      final defaultRule = rules.where((rule) => rule.isDefault).firstOrNull;
      if (defaultRule != null) {
        return [defaultRule];
      }

      // Last resort: create a temporary rule with default group
      if (defaultGroup != null) {
        return [
          RoutingRule(
            targetGroup: defaultGroup!,
            isDefault: true,
            description: 'Fallback default rule',
          )
        ];
      }

      return [];
    }

    // Sort by priority (higher priority first)
    matchingRules.sort((a, b) => b.priority.compareTo(a.priority));
    return matchingRules;
  }

  /// Returns the primary rule for routing an event (highest priority match)
  RoutingRule? getPrimaryRule(BaseEvent event) {
    final matchingRules = getMatchingRules(event);
    return matchingRules.isNotEmpty ? matchingRules.first : null;
  }

  /// Returns all tracker groups that should handle the given event
  List<TrackerGroup> getTargetGroups(
    BaseEvent event, {
    bool hasGeneralConsent = true,
    bool hasPIIConsent = true,
  }) {
    final matchingRules = getMatchingRules(event);
    final targetGroups = <TrackerGroup>[];

    for (final rule in matchingRules) {
      // Check consent requirements
      if (!rule.shouldApply(event,
          hasGeneralConsent: hasGeneralConsent, hasPIIConsent: hasPIIConsent)) {
        continue;
      }

      // Check sampling
      if (enableSampling && !rule.shouldSample()) {
        continue;
      }

      targetGroups.add(rule.targetGroup);

      // For most cases, we only want the highest priority rule
      // But allow multiple rules if they have the same priority
      if (matchingRules.length > 1 &&
          matchingRules[0].priority != rule.priority) {
        break;
      }
    }

    return targetGroups;
  }

  /// Returns a custom group by name, or null if not found
  TrackerGroup? getCustomGroup(String name) {
    return customGroups[name];
  }

  /// Returns a custom category by name, or null if not found
  EventCategory? getCustomCategory(String name) {
    return customCategories[name];
  }

  /// Returns all available groups (predefined + custom)
  List<TrackerGroup> getAllGroups() {
    return [
      TrackerGroup.all,
      TrackerGroup.development,
      ...customGroups.values,
    ];
  }

  /// Returns all available categories (predefined + custom)
  List<EventCategory> getAllCategories() {
    return [
      ...EventCategory.predefined,
      ...customCategories.values,
    ];
  }

  /// Creates a copy of this configuration with updated properties
  RoutingConfiguration copyWith({
    List<RoutingRule>? rules,
    Map<String, TrackerGroup>? customGroups,
    Map<String, EventCategory>? customCategories,
    TrackerGroup? defaultGroup,
    bool? enableSampling,
    bool? enableConsentChecking,
    bool? isDebugMode,
  }) {
    return RoutingConfiguration(
      rules: rules ?? this.rules,
      customGroups: customGroups ?? this.customGroups,
      customCategories: customCategories ?? this.customCategories,
      defaultGroup: defaultGroup ?? this.defaultGroup,
      enableSampling: enableSampling ?? this.enableSampling,
      enableConsentChecking:
          enableConsentChecking ?? this.enableConsentChecking,
      isDebugMode: isDebugMode ?? this.isDebugMode,
    );
  }

  /// Validates the configuration and returns any issues found
  List<String> validate() {
    final issues = <String>[];

    // Check for duplicate rule IDs
    final ruleIds =
        rules.where((rule) => rule.id != null).map((rule) => rule.id!);
    final duplicateIds = <String>[];
    final seenIds = <String>{};

    for (final id in ruleIds) {
      if (seenIds.contains(id)) {
        duplicateIds.add(id);
      } else {
        seenIds.add(id);
      }
    }

    if (duplicateIds.isNotEmpty) {
      issues.add('Duplicate rule IDs found: ${duplicateIds.join(', ')}');
    }

    // Check for rules with invalid sample rates
    final invalidSampleRates = rules
        .where((rule) => rule.sampleRate < 0.0 || rule.sampleRate > 1.0)
        .map((rule) => rule.id ?? 'unnamed')
        .toList();

    if (invalidSampleRates.isNotEmpty) {
      issues.add(
          'Invalid sample rates in rules: ${invalidSampleRates.join(', ')}');
    }

    // Check for missing default rule
    final hasDefaultRule = rules.any((rule) => rule.isDefault);
    if (!hasDefaultRule && defaultGroup == null) {
      issues.add('No default rule or default group specified');
    }

    // Check for unreferenced custom groups in rules
    final referencedGroups = rules.map((rule) => rule.targetGroup.name).toSet();
    final unreferencedGroups = customGroups.keys
        .where((name) => !referencedGroups.contains(name))
        .toList();

    if (unreferencedGroups.isNotEmpty) {
      issues
          .add('Unreferenced custom groups: ${unreferencedGroups.join(', ')}');
    }

    return issues;
  }

  /// Converts to a map for serialization/debugging
  Map<String, dynamic> toMap() {
    return {
      'rules': rules.map((rule) => rule.toMap()).toList(),
      'customGroups':
          customGroups.map((key, value) => MapEntry(key, value.toMap())),
      'customCategories':
          customCategories.map((key, value) => MapEntry(key, value.toMap())),
      'defaultGroup': defaultGroup?.toMap(),
      'enableSampling': enableSampling,
      'enableConsentChecking': enableConsentChecking,
      'isDebugMode': isDebugMode,
      'rulesCount': rules.length,
      'customGroupsCount': customGroups.length,
      'customCategoriesCount': customCategories.length,
    };
  }

  @override
  String toString() {
    return 'RoutingConfiguration('
        '${rules.length} rules, '
        '${customGroups.length} custom groups, '
        '${customCategories.length} custom categories'
        ')';
  }
}
