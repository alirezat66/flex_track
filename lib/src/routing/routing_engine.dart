import 'package:flex_track/src/models/event/base_event.dart';

import '../models/routing/routing_config.dart';
import '../models/routing/routing_rule.dart';
import '../models/routing/tracker_group.dart';
import '../exceptions/routing_exception.dart';

/// Engine responsible for matching events to routing rules and determining target trackers
class RoutingEngine {
  final RoutingConfiguration _configuration;

  RoutingEngine(this._configuration);

  /// Get the configuration being used by this engine
  RoutingConfiguration get configuration => _configuration;

  /// Routes an event and returns the list of tracker IDs that should handle it
  RoutingResult routeEvent(
    BaseEvent event, {
    bool hasGeneralConsent = true,
    bool hasPIIConsent = true,
    Set<String>? availableTrackers,
  }) {
    try {
      // Get matching rules for the event
      final matchingRules = _configuration.getMatchingRules(event);

      if (matchingRules.isEmpty) {
        return RoutingResult(
          event: event,
          targetTrackers: [],
          appliedRules: [],
          skippedRules: [],
          warnings: ['No routing rules matched the event'],
        );
      }

      final appliedRules = <RoutingRule>[];
      final skippedRules = <SkippedRule>[];
      final allTargetTrackers = <String>{};
      final warnings = <String>[];

      // Process each matching rule
      for (final rule in matchingRules) {
        // Check if rule should be applied based on consent
        if (!rule.shouldApply(event,
            hasGeneralConsent: hasGeneralConsent,
            hasPIIConsent: hasPIIConsent)) {
          skippedRules.add(SkippedRule(
            rule: rule,
            reason: 'Consent requirements not met',
          ));
          continue;
        }

        // Check sampling
        if (_configuration.enableSampling && !rule.shouldSample()) {
          skippedRules.add(SkippedRule(
            rule: rule,
            reason:
                'Event was sampled out (${(rule.sampleRate * 100).toStringAsFixed(1)}% sample rate)',
          ));
          continue;
        }

        // Resolve tracker IDs from the target group
        final resolvedTrackers = _resolveTrackerGroup(
          rule.targetGroup,
          availableTrackers: availableTrackers,
        );

        if (resolvedTrackers.isEmpty) {
          warnings.add(
              'Rule "${rule.description ?? rule.toString()}" resolved to no available trackers');
          skippedRules.add(SkippedRule(
            rule: rule,
            reason: 'No available trackers in target group',
          ));
          continue;
        }

        allTargetTrackers.addAll(resolvedTrackers);
        appliedRules.add(rule);

        // For most cases, we only apply the highest priority rule
        // But allow multiple rules with the same priority
        if (appliedRules.length > 1 &&
            appliedRules.first.priority != rule.priority) {
          break;
        }
      }

      return RoutingResult(
        event: event,
        targetTrackers: allTargetTrackers.toList(),
        appliedRules: appliedRules,
        skippedRules: skippedRules,
        warnings: warnings,
      );
    } catch (e, stackTrace) {
      throw RoutingException(
        'Failed to route event ${event.name}: $e',
        eventName: event.name,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Resolves a tracker group to a list of actual tracker IDs
  List<String> _resolveTrackerGroup(TrackerGroup group,
      {Set<String>? availableTrackers}) {
    // Handle the special "all" group
    if (group.includesAll) {
      return availableTrackers?.toList() ?? [];
    }

    // Filter by available trackers if provided
    if (availableTrackers != null) {
      return group.trackerIds
          .where((id) => availableTrackers.contains(id))
          .toList();
    }

    return group.trackerIds;
  }

  /// Validates that all rules in the configuration are valid
  List<String> validateConfiguration() {
    return _configuration.validate();
  }

  /// Returns debug information about how an event would be routed
  RoutingDebugInfo debugEvent(
    BaseEvent event, {
    bool hasGeneralConsent = true,
    bool hasPIIConsent = true,
    Set<String>? availableTrackers,
  }) {
    final allRules = _configuration.rules;
    final matchingRules = <RoutingRule>[];
    final nonMatchingRules = <RuleDebugInfo>[];

    for (final rule in allRules) {
      final matches =
          rule.matches(event, isDebugMode: _configuration.isDebugMode);

      if (matches) {
        matchingRules.add(rule);
      } else {
        nonMatchingRules.add(RuleDebugInfo(
          rule: rule,
          matches: false,
          reason: _getRuleNonMatchReason(rule, event),
        ));
      }
    }

    final routingResult = routeEvent(
      event,
      hasGeneralConsent: hasGeneralConsent,
      hasPIIConsent: hasPIIConsent,
      availableTrackers: availableTrackers,
    );

    return RoutingDebugInfo(
      event: event,
      allRules: allRules,
      matchingRules: matchingRules,
      nonMatchingRules: nonMatchingRules,
      routingResult: routingResult,
      configuration: _configuration,
    );
  }

  /// Determines why a rule didn't match an event
  String _getRuleNonMatchReason(RoutingRule rule, BaseEvent event) {
    final reasons = <String>[];

    if (rule.eventType != null && event.runtimeType != rule.eventType) {
      reasons.add(
          'Event type mismatch: expected ${rule.eventType}, got ${event.runtimeType}');
    }

    if (rule.eventNamePattern != null &&
        !event.name.contains(rule.eventNamePattern!)) {
      reasons.add(
          'Event name pattern mismatch: "${event.name}" does not contain "${rule.eventNamePattern}"');
    }

    if (rule.eventNameRegex != null &&
        !rule.eventNameRegex!.hasMatch(event.name)) {
      reasons.add(
          'Event name regex mismatch: "${event.name}" does not match /${rule.eventNameRegex!.pattern}/');
    }

    if (rule.category != null && event.category != rule.category) {
      reasons.add(
          'Category mismatch: expected ${rule.category?.name}, got ${event.category?.name}');
    }

    if (rule.debugOnly && !_configuration.isDebugMode) {
      reasons.add('Rule is debug-only but not in debug mode');
    }

    if (rule.productionOnly && _configuration.isDebugMode) {
      reasons.add('Rule is production-only but in debug mode');
    }

    return reasons.isNotEmpty ? reasons.join('; ') : 'Unknown reason';
  }
}

/// Result of routing an event through the engine
class RoutingResult {
  final BaseEvent event;
  final List<String> targetTrackers;
  final List<RoutingRule> appliedRules;
  final List<SkippedRule> skippedRules;
  final List<String> warnings;

  const RoutingResult({
    required this.event,
    required this.targetTrackers,
    required this.appliedRules,
    required this.skippedRules,
    required this.warnings,
  });

  /// Returns true if the event will be tracked
  bool get willBeTracked => targetTrackers.isNotEmpty;

  /// Returns true if there were any issues during routing
  bool get hasIssues => warnings.isNotEmpty || skippedRules.isNotEmpty;

  /// Converts to a map for debugging/logging
  Map<String, dynamic> toMap() {
    return {
      'event': event.toMap(),
      'targetTrackers': targetTrackers,
      'appliedRulesCount': appliedRules.length,
      'skippedRulesCount': skippedRules.length,
      'warnings': warnings,
      'willBeTracked': willBeTracked,
      'hasIssues': hasIssues,
      'appliedRules': appliedRules.map((rule) => rule.toMap()).toList(),
      'skippedRules': skippedRules.map((sr) => sr.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'RoutingResult(${targetTrackers.length} trackers, ${appliedRules.length} rules applied)';
  }
}

/// Information about a rule that was skipped during routing
class SkippedRule {
  final RoutingRule rule;
  final String reason;

  const SkippedRule({
    required this.rule,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'rule': rule.toMap(),
      'reason': reason,
    };
  }

  @override
  String toString() =>
      'SkippedRule(${rule.description ?? rule.toString()}: $reason)';
}

/// Debug information about routing an event
class RoutingDebugInfo {
  final BaseEvent event;
  final List<RoutingRule> allRules;
  final List<RoutingRule> matchingRules;
  final List<RuleDebugInfo> nonMatchingRules;
  final RoutingResult routingResult;
  final RoutingConfiguration configuration;

  const RoutingDebugInfo({
    required this.event,
    required this.allRules,
    required this.matchingRules,
    required this.nonMatchingRules,
    required this.routingResult,
    required this.configuration,
  });

  Map<String, dynamic> toMap() {
    return {
      'event': event.toMap(),
      'totalRulesCount': allRules.length,
      'matchingRulesCount': matchingRules.length,
      'nonMatchingRulesCount': nonMatchingRules.length,
      'routingResult': routingResult.toMap(),
      'matchingRules': matchingRules.map((rule) => rule.toMap()).toList(),
      'nonMatchingRules': nonMatchingRules.map((info) => info.toMap()).toList(),
    };
  }
}

/// Debug information about a single rule
class RuleDebugInfo {
  final RoutingRule rule;
  final bool matches;
  final String reason;

  const RuleDebugInfo({
    required this.rule,
    required this.matches,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'rule': rule.toMap(),
      'matches': matches,
      'reason': reason,
    };
  }
}
