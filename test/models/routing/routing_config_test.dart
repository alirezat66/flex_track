import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/routing/event_category.dart';
import 'package:flex_track/src/models/routing/routing_config.dart';
import 'package:flex_track/src/models/routing/routing_rule.dart';
import 'package:flex_track/src/models/routing/tracker_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'routing_config_test.mocks.dart'; // Generated mock file

@GenerateMocks([BaseEvent])
void main() {
  group('RoutingConfiguration', () {
    test('empty() should create an empty configuration', () {
      final config = RoutingConfiguration.empty();
      expect(config.rules, isEmpty);
      expect(config.customGroups, isEmpty);
      expect(config.customCategories, isEmpty);
      expect(config.defaultGroup, isNull);
      expect(config.enableSampling, isTrue);
      expect(config.enableConsentChecking, isTrue);
      expect(config.isDebugMode, isFalse);
    });

    test(
        'withSmartDefaults() should create a configuration with predefined rules',
        () {
      final config = RoutingConfiguration.withSmartDefaults();
      expect(config.rules, isNotEmpty);
      expect(config.rules.length, 3);
      expect(config.defaultGroup, TrackerGroup.all);

      // Verify specific rules
      final technicalRule =
          config.rules.firstWhere((r) => r.category == EventCategory.technical);
      expect(technicalRule.targetGroup, TrackerGroup.development);
      expect(technicalRule.debugOnly, isTrue);
      expect(technicalRule.sampleRate, 0.1);
      expect(technicalRule.priority, 8);

      final highVolumeRule =
          config.rules.firstWhere((r) => r.isHighVolume == true);
      expect(highVolumeRule.targetGroup, TrackerGroup.all);
      expect(highVolumeRule.sampleRate, 0.05);
      expect(highVolumeRule.priority, 5);

      final defaultRule = config.rules.firstWhere((r) => r.isDefault);
      expect(defaultRule.targetGroup, TrackerGroup.all);
      expect(defaultRule.priority, 0);
    });

    group('getMatchingRules', () {
      test('should return matching rules sorted by priority', () {
        final rule1 = RoutingRule(
            id: 'rule1', priority: 10, targetGroup: TrackerGroup.all);
        final rule2 = RoutingRule(
            id: 'rule2', priority: 5, targetGroup: TrackerGroup.all);
        final rule3 = RoutingRule(
            id: 'rule3', priority: 15, targetGroup: TrackerGroup.all);
        final config = RoutingConfiguration(rules: [rule1, rule2, rule3]);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');

        final matchingRules = config.getMatchingRules(event);
        expect(matchingRules,
            [rule3, rule1, rule2]); // Sorted by priority descending
      });

      test(
          'should return default rule if no rules match and default rule exists',
          () {
        final defaultRule = RoutingRule(
            id: 'default', isDefault: true, targetGroup: TrackerGroup.all);
        final config = RoutingConfiguration(rules: [defaultRule]);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('non_matching_event');

        final matchingRules = config.getMatchingRules(event);
        expect(matchingRules, [defaultRule]);
      });

      test(
          'should return fallback default rule if no rules match and defaultGroup exists',
          () {
        final config =
            RoutingConfiguration(rules: [], defaultGroup: TrackerGroup.all);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('non_matching_event');

        final matchingRules = config.getMatchingRules(event);
        expect(matchingRules.length, 1);
        expect(matchingRules.first.targetGroup, TrackerGroup.all);
        expect(matchingRules.first.isDefault, isTrue);
        expect(matchingRules.first.description, 'Fallback default rule');
      });

      test(
          'should return empty list if no rules match and no default rule/group',
          () {
        final config = RoutingConfiguration.empty();
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('non_matching_event');
        expect(config.getMatchingRules(event), isEmpty);
      });

      test('should filter debugOnly rules when not in debug mode', () {
        final debugRule = RoutingRule(
            id: 'debug', debugOnly: true, targetGroup: TrackerGroup.all);
        final normalRule =
            RoutingRule(id: 'normal', targetGroup: TrackerGroup.all);
        final config = RoutingConfiguration(
            rules: [debugRule, normalRule], isDebugMode: false);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');

        final matchingRules = config.getMatchingRules(event);
        expect(matchingRules, contains(normalRule));
        expect(matchingRules, isNot(contains(debugRule)));
      });

      test('should include debugOnly rules when in debug mode', () {
        final debugRule = RoutingRule(
            id: 'debug', debugOnly: true, targetGroup: TrackerGroup.all);
        final normalRule =
            RoutingRule(id: 'normal', targetGroup: TrackerGroup.all);
        final config = RoutingConfiguration(
            rules: [debugRule, normalRule], isDebugMode: true);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');

        final matchingRules = config.getMatchingRules(event);
        expect(matchingRules, contains(normalRule));
        expect(matchingRules, contains(debugRule));
      });
    });

    group('getPrimaryRule', () {
      test('should return the highest priority matching rule', () {
        final rule1 = RoutingRule(
            id: 'rule1', priority: 10, targetGroup: TrackerGroup.all);
        final rule2 = RoutingRule(
            id: 'rule2', priority: 5, targetGroup: TrackerGroup.all);
        final config = RoutingConfiguration(rules: [rule1, rule2]);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');

        expect(config.getPrimaryRule(event), rule1);
      });

      test('should return null if no rules match', () {
        final config = RoutingConfiguration.empty();
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');
        expect(config.getPrimaryRule(event), isNull);
      });
    });

    group('getTargetGroups', () {
      test(
          'should return target groups based on matching rules, consent, and sampling',
          () {
        final rule1 = RoutingRule(
            id: 'rule1', targetGroup: TrackerGroup.all, sampleRate: 1.0);
        final rule2 = RoutingRule(
            id: 'rule2',
            targetGroup: TrackerGroup.development,
            sampleRate: 0.0); // Will be sampled out
        final rule3 = RoutingRule(
            id: 'rule3',
            targetGroup: TrackerGroup('marketing', ['marketing_tracker']),
            requirePIIConsent: true);
        final config = RoutingConfiguration(rules: [rule1, rule2, rule3]);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');
        when(event.isEssential).thenReturn(false);
        when(event.requiresConsent).thenReturn(true);
        when(event.containsPII).thenReturn(true);

        // With full consent, sampling enabled
        var targetGroups = config.getTargetGroups(event,
            hasGeneralConsent: true, hasPIIConsent: true);
        expect(targetGroups, contains(TrackerGroup.all));
        expect(targetGroups,
            isNot(contains(TrackerGroup.development))); // Sampled out
        expect(targetGroups,
            contains(TrackerGroup('marketing', ['marketing_tracker'])));
        expect(targetGroups.length, 2);

        // With no PII consent
        targetGroups = config.getTargetGroups(event,
            hasGeneralConsent: true, hasPIIConsent: false);
        expect(targetGroups, contains(TrackerGroup.all));
        expect(
            targetGroups,
            isNot(contains(TrackerGroup(
                'marketing', ['marketing_tracker'])))); // PII consent missing
        expect(targetGroups.length, 1);

        // Sampling disabled
        final configNoSampling = RoutingConfiguration(
            rules: [rule1, rule2, rule3], enableSampling: false);
        targetGroups = configNoSampling.getTargetGroups(event,
            hasGeneralConsent: true, hasPIIConsent: true);
        expect(targetGroups, contains(TrackerGroup.all));
        expect(targetGroups,
            contains(TrackerGroup.development)); // Not sampled out
        expect(targetGroups,
            contains(TrackerGroup('marketing', ['marketing_tracker'])));
        expect(targetGroups.length, 3);
      });

      test('should only include highest priority group if priorities differ',
          () {
        final rule1 = RoutingRule(
            id: 'rule1', priority: 10, targetGroup: TrackerGroup.all);
        final rule2 = RoutingRule(
            id: 'rule2', priority: 5, targetGroup: TrackerGroup.development);
        final config = RoutingConfiguration(rules: [rule1, rule2]);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');
        when(event.isEssential).thenReturn(false);
        when(event.requiresConsent).thenReturn(true);
        when(event.containsPII).thenReturn(false);

        final targetGroups = config.getTargetGroups(event);
        print(targetGroups);
        expect(targetGroups, [TrackerGroup.all, TrackerGroup.development]);
      });

      test('should include multiple groups if rules have same highest priority',
          () {
        final rule1 = RoutingRule(
            id: 'rule1', priority: 10, targetGroup: TrackerGroup.all);
        final rule2 = RoutingRule(
            id: 'rule2', priority: 10, targetGroup: TrackerGroup.development);
        final config = RoutingConfiguration(rules: [rule1, rule2]);
        final event = MockBaseEvent();
        when(event.getName()).thenReturn('test_event');
        when(event.isEssential).thenReturn(false);
        when(event.requiresConsent).thenReturn(true);
        when(event.containsPII).thenReturn(false);

        final targetGroups = config.getTargetGroups(event);
        expect(targetGroups, contains(TrackerGroup.all));
        expect(targetGroups, contains(TrackerGroup.development));
        expect(targetGroups.length, 2);
      });
    });

    test('getCustomGroup should return custom group by name', () {
      final customGroup = TrackerGroup('my_group', ['tracker1']);
      final config = RoutingConfiguration(
          rules: [], customGroups: {'my_group': customGroup});
      expect(config.getCustomGroup('my_group'), customGroup);
      expect(config.getCustomGroup('non_existent'), isNull);
    });

    test('getCustomCategory should return custom category by name', () {
      final customCategory = EventCategory('my_category');
      final config = RoutingConfiguration(
          rules: [], customCategories: {'my_category': customCategory});
      expect(config.getCustomCategory('my_category'), customCategory);
      expect(config.getCustomCategory('non_existent'), isNull);
    });

    test('getAllGroups should return all predefined and custom groups', () {
      final customGroup = TrackerGroup('my_group', ['tracker1']);
      final config = RoutingConfiguration(
          rules: [], customGroups: {'my_group': customGroup});
      final allGroups = config.getAllGroups();
      expect(allGroups, contains(TrackerGroup.all));
      expect(allGroups, contains(TrackerGroup.development));
      expect(allGroups, contains(customGroup));
      expect(allGroups.length, 3); // All, Development, my_group
    });

    test('getAllCategories should return all predefined and custom categories',
        () {
      final customCategory = EventCategory('my_category');
      final config = RoutingConfiguration(
          rules: [], customCategories: {'my_category': customCategory});
      final allCategories = config.getAllCategories();
      expect(allCategories, contains(EventCategory.business));
      expect(allCategories, contains(EventCategory.user));
      expect(allCategories, contains(customCategory));
      expect(allCategories.length, EventCategory.predefined.length + 1);
    });

    group('copyWith', () {
      final originalConfig = RoutingConfiguration(
        rules: [RoutingRule(id: 'r1', targetGroup: TrackerGroup.all)],
        customGroups: {
          'cg1': TrackerGroup('cg1', ['tracker1'])
        },
        customCategories: {'cc1': EventCategory('cc1')},
        defaultGroup: TrackerGroup.development,
        enableSampling: false,
        enableConsentChecking: false,
        isDebugMode: true,
      );

      test('should copy all properties if no new values are provided', () {
        final newConfig = originalConfig.copyWith();
        expect(newConfig.rules, originalConfig.rules);
        expect(newConfig.customGroups, originalConfig.customGroups);
        expect(newConfig.customCategories, originalConfig.customCategories);
        expect(newConfig.defaultGroup, originalConfig.defaultGroup);
        expect(newConfig.enableSampling, originalConfig.enableSampling);
        expect(newConfig.enableConsentChecking,
            originalConfig.enableConsentChecking);
        expect(newConfig.isDebugMode, originalConfig.isDebugMode);
      });

      test('should update specified properties', () {
        final newRule =
            RoutingRule(id: 'r2', targetGroup: TrackerGroup.development);
        final newCustomGroup = TrackerGroup('cg2', ['tracker2']);
        final newCustomCategory = EventCategory('cc2');

        final newConfig = originalConfig.copyWith(
          rules: [newRule],
          customGroups: {'cg2': newCustomGroup},
          customCategories: {'cc2': newCustomCategory},
          defaultGroup: TrackerGroup('marketing', ['marketing_tracker']),
          enableSampling: true,
          enableConsentChecking: true,
          isDebugMode: false,
        );

        expect(newConfig.rules, [newRule]);
        expect(newConfig.customGroups, {'cg2': newCustomGroup});
        expect(newConfig.customCategories, {'cc2': newCustomCategory});
        expect(newConfig.defaultGroup,
            TrackerGroup('marketing', ['marketing_tracker']));
        expect(newConfig.enableSampling, isTrue);
        expect(newConfig.enableConsentChecking, isTrue);
        expect(newConfig.isDebugMode, isFalse);
      });
    });

    group('validate', () {
      test('should return empty list for a valid configuration', () {
        final config = RoutingConfiguration(
          rules: [
            RoutingRule(
                id: 'rule1', targetGroup: TrackerGroup.all, sampleRate: 0.5),
            RoutingRule(
                id: 'rule2',
                isDefault: true,
                targetGroup: TrackerGroup.development),
          ],
        );
        expect(config.validate(), isEmpty);
      });

      test('should detect duplicate rule IDs', () {
        final config = RoutingConfiguration(
          rules: [
            RoutingRule(id: 'rule1', targetGroup: TrackerGroup.all),
            RoutingRule(id: 'rule1', targetGroup: TrackerGroup.development),
          ],
        );
        expect(config.validate(), contains('Duplicate rule IDs found: rule1'));
      });


      test('should detect missing default rule or default group', () {
        final config = RoutingConfiguration(rules: [
          RoutingRule(id: 'rule1', targetGroup: TrackerGroup.all),
        ]);
        expect(config.validate(),
            contains('No default rule or default group specified'));
      });

      test('should not detect missing default rule if defaultGroup is provided',
          () {
        final config = RoutingConfiguration(
          rules: [
            RoutingRule(id: 'rule1', targetGroup: TrackerGroup.all),
          ],
          defaultGroup: TrackerGroup.all,
        );
        expect(config.validate(),
            isNot(contains('No default rule or default group specified')));
      });

      test('should detect unreferenced custom groups', () {
        final customGroup = TrackerGroup('my_custom_group', ['tracker_a']);
        final config = RoutingConfiguration(
          rules: [
            RoutingRule(id: 'rule1', targetGroup: TrackerGroup.all),
          ],
          customGroups: {'my_custom_group': customGroup},
        );
        expect(config.validate(),
            contains('Unreferenced custom groups: my_custom_group'));
      });

      test('should not detect unreferenced custom groups if referenced', () {
        final customGroup = TrackerGroup('my_custom_group', ['tracker_a']);
        final config = RoutingConfiguration(
          rules: [
            RoutingRule(id: 'rule1', targetGroup: customGroup),
          ],
          customGroups: {'my_custom_group': customGroup},
        );
        expect(config.validate(),
            isNot(contains('Unreferenced custom groups: my_custom_group')));
      });
    });

    test('toMap should return a correct map representation', () {
      final rule = RoutingRule(id: 'test_rule', targetGroup: TrackerGroup.all);
      final customGroup = TrackerGroup('test_group', ['test_tracker']);
      final customCategory = EventCategory('test_category');

      final config = RoutingConfiguration(
        rules: [rule],
        customGroups: {'test_group': customGroup},
        customCategories: {'test_category': customCategory},
        defaultGroup: TrackerGroup.development,
        enableSampling: false,
        enableConsentChecking: false,
        isDebugMode: true,
      );

      final map = config.toMap();
      expect(map['rules'], isA<List>());
      expect(map['rules'].length, 1);
      expect(map['customGroups'], isA<Map>());
      expect(map['customGroups'].length, 1);
      expect(map['customCategories'], isA<Map>());
      expect(map['customCategories'].length, 1);
      expect(map['defaultGroup'], isA<Map>());
      expect(map['enableSampling'], isFalse);
      expect(map['enableConsentChecking'], isFalse);
      expect(map['isDebugMode'], isTrue);
      expect(map['rulesCount'], 1);
      expect(map['customGroupsCount'], 1);
      expect(map['customCategoriesCount'], 1);
    });

    test('toString should return a correct string representation', () {
      final config = RoutingConfiguration(
        rules: [RoutingRule(id: 'r1', targetGroup: TrackerGroup.all)],
        customGroups: {
          'cg1': TrackerGroup('cg1', ['tracker1'])
        },
        customCategories: {'cc1': EventCategory('cc1')},
      );
      expect(config.toString(),
          'RoutingConfiguration(1 rules, 1 custom groups, 1 custom categories)');
    });
  });
}
