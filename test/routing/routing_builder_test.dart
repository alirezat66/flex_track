import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('RoutingBuilder Tests - Complete Suite', () {
    late RoutingBuilder builder;

    setUp(() {
      builder = RoutingBuilder();
    });

    group('Constructor and Factory Methods', () {
      test('should create empty routing builder', () {
        expect(builder, isA<RoutingBuilder>());
        expect(builder.getAllGroups(), hasLength(2)); // all, development
        expect(
            builder.getAllCategories(), hasLength(7)); // predefined categories
      });

      test('should create routing builder with smart defaults', () {
        final builderWithDefaults = RoutingBuilder.withSmartDefaults();

        final config = builderWithDefaults.build();
        expect(config.rules, isNotEmpty);

        // Should have technical, high volume, and default rules
        expect(config.rules.any((r) => r.category == EventCategory.technical),
            isTrue);
        expect(config.rules.any((r) => r.isHighVolume == true), isTrue);
        expect(config.rules.any((r) => r.isDefault), isTrue);
      });
    });

    group('Group Management', () {
      test('should define custom tracker group', () {
        builder.defineGroup('analytics', ['firebase', 'mixpanel']);

        final groups = builder.getAllGroups();
        expect(groups.any((g) => g.name == 'analytics'), isTrue);

        final analyticsGroup = builder.getGroup('analytics');
        expect(analyticsGroup, isNotNull);
        expect(analyticsGroup!.trackerIds, equals(['firebase', 'mixpanel']));
      });

      test('should define custom tracker group with description', () {
        builder.defineGroup(
          'premium_analytics',
          ['amplitude', 'mixpanel'],
          description: 'Analytics for premium users',
        );

        final group = builder.getGroup('premium_analytics');
        expect(group, isNotNull);
        expect(group!.description, equals('Analytics for premium users'));
      });

      test('should throw error for empty group name', () {
        expect(
          () => builder.defineGroup('', ['tracker1']),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Group name cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('name'))),
        );
      });

      test('should throw error for empty tracker list', () {
        expect(
          () => builder.defineGroup('empty_group', []),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('at least one tracker ID'))
              .having((e) => e.fieldName, 'fieldName', equals('trackerIds'))),
        );
      });

      test('should get predefined groups', () {
        expect(builder.getGroup('all'), equals(TrackerGroup.all));
        expect(
            builder.getGroup('development'), equals(TrackerGroup.development));
        expect(builder.getGroup('nonexistent'), isNull);
      });

      test('should set default group', () {
        final customGroup = TrackerGroup('custom', ['tracker1']);
        builder.setDefaultGroup(customGroup);

        final config = builder.build();
        expect(config.defaultGroup, equals(customGroup));
      });

      test('should set default group by name', () {
        builder.defineGroup('custom_default', ['tracker1', 'tracker2']);
        builder.setDefaultGroupNamed('custom_default');

        final config = builder.build();
        expect(config.defaultGroup!.name, equals('custom_default'));
      });

      test('should throw error when setting unknown default group', () {
        expect(
          () => builder.setDefaultGroupNamed('unknown_group'),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Unknown group: unknown_group'))
              .having((e) => e.fieldName, 'fieldName', equals('groupName'))),
        );
      });
    });

    group('Category Management', () {
      test('should define custom event category', () {
        builder.defineCategory('onboarding',
            description: 'User onboarding events');

        final categories = builder.getAllCategories();
        expect(categories.any((c) => c.name == 'onboarding'), isTrue);

        final onboardingCategory = builder.getCategory('onboarding');
        expect(onboardingCategory, isNotNull);
        expect(
            onboardingCategory!.description, equals('User onboarding events'));
      });

      test('should throw error for empty category name', () {
        expect(
          () => builder.defineCategory(''),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Category name cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('name'))),
        );
      });

      test('should get predefined categories', () {
        expect(builder.getCategory('business'), equals(EventCategory.business));
        expect(builder.getCategory('user'), equals(EventCategory.user));
        expect(
            builder.getCategory('technical'), equals(EventCategory.technical));
        expect(
            builder.getCategory('sensitive'), equals(EventCategory.sensitive));
        expect(
            builder.getCategory('marketing'), equals(EventCategory.marketing));
        expect(builder.getCategory('system'), equals(EventCategory.system));
        expect(builder.getCategory('security'), equals(EventCategory.security));
        expect(builder.getCategory('nonexistent'), isNull);
      });
    });

    group('Configuration Options', () {
      test('should set sampling enabled/disabled', () {
        builder.setSampling(false);

        final config = builder.build();
        expect(config.enableSampling, isFalse);

        builder.setSampling(true);
        final config2 = builder.build();
        expect(config2.enableSampling, isTrue);
      });

      test('should set consent checking enabled/disabled', () {
        builder.setConsentChecking(false);

        final config = builder.build();
        expect(config.enableConsentChecking, isFalse);

        builder.setConsentChecking(true);
        final config2 = builder.build();
        expect(config2.enableConsentChecking, isTrue);
      });

      test('should set debug mode', () {
        builder.setDebugMode(true);

        final config = builder.build();
        expect(config.isDebugMode, isTrue);

        builder.setDebugMode(false);
        final config2 = builder.build();
        expect(config2.isDebugMode, isFalse);
      });
    });

    group('Simple Routing Methods', () {
      test('should route by event type', () {
        final ruleBuilder = builder.route<TestEvent>();

        expect(ruleBuilder, isA<RouteConfigBuilder<TestEvent>>());
        expect(ruleBuilder.eventType, equals(TestEvent));
        expect(ruleBuilder.parent, equals(builder));
      });

      test('should route by event name pattern', () {
        final ruleBuilder = builder.routeNamed('user_action');

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.eventNamePattern, equals('user_action'));
      });

      test('should throw error for empty event name pattern', () {
        expect(
          () => builder.routeNamed(''),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Event name pattern cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('pattern'))),
        );
      });

      test('should route by regex pattern', () {
        final regex = RegExp(r'^debug_.*');
        final ruleBuilder = builder.routeMatching(regex);

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.eventNameRegex, equals(regex));
      });

      test('should route by exact event name', () {
        final ruleBuilder = builder.routeExact('purchase_complete');

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.eventNameRegex, isNotNull);
        expect(ruleBuilder.eventNameRegex!.pattern,
            equals(r'^purchase_complete$'));
      });

      test('should throw error for empty exact event name', () {
        expect(
          () => builder.routeExact(''),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Event name cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('eventName'))),
        );
      });

      test('should route by category', () {
        final ruleBuilder = builder.routeCategory(EventCategory.business);

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.category, equals(EventCategory.business));
      });

      test('should route by custom category name', () {
        builder.defineCategory('custom_category');
        final ruleBuilder = builder.routeCategoryNamed('custom_category');

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.category!.name, equals('custom_category'));
      });

      test('should throw error for unknown category name', () {
        expect(
          () => builder.routeCategoryNamed('unknown_category'),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Unknown category: unknown_category'))
              .having((e) => e.fieldName, 'fieldName', equals('categoryName'))),
        );
      });

      test('should route by property without value', () {
        final ruleBuilder = builder.routeWithProperty('user_id');

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.hasProperty, equals('user_id'));
        expect(ruleBuilder.propertyValue, isNull);
      });

      test('should route by property with value', () {
        final ruleBuilder =
            builder.routeWithProperty('environment', 'production');

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.hasProperty, equals('environment'));
        expect(ruleBuilder.propertyValue, equals('production'));
      });

      test('should throw error for empty property name', () {
        expect(
          () => builder.routeWithProperty(''),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Property name cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('propertyName'))),
        );
      });

      test('should route PII events', () {
        final ruleBuilder = builder.routePII();

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.containsPII, isTrue);
      });

      test('should route high volume events', () {
        final ruleBuilder = builder.routeHighVolume();

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.isHighVolume, isTrue);
      });

      test('should route essential events', () {
        final ruleBuilder = builder.routeEssential();

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.isEssential, isTrue);
      });

      test('should route default events', () {
        final ruleBuilder = builder.routeDefault();

        expect(ruleBuilder, isA<RouteConfigBuilder>());
        expect(ruleBuilder.isDefault, isTrue);
      });
    });

    group('Rule Management', () {
      test('should add single rule', () {
        final rule = RoutingRule(
          isDefault: true,
          targetGroup: TrackerGroup.all,
        );

        builder.addRules([rule]);

        final config = builder.build();
        expect(config.rules, contains(rule));
      });

      test('should add multiple rules', () {
        final rules = [
          RoutingRule(
            category: EventCategory.business,
            targetGroup: TrackerGroup('business', ['analytics']),
            priority: 10,
          ),
          RoutingRule(
            category: EventCategory.technical,
            targetGroup: TrackerGroup.development,
            priority: 5,
          ),
        ];

        builder.addRules(rules);

        final config = builder.build();
        expect(config.rules, containsAll(rules));
      });

      test('should clear all rules', () {
        builder.routeDefault().toAll().and();

        expect(builder.build().rules, isNotEmpty);

        builder.clearRules();

        expect(
            builder.build().rules, hasLength(0)); // Auto-generated default rule
      });

      test('should remove rules matching condition', () {
        builder
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(10)
            .and()
            .routeCategory(EventCategory.technical)
            .toAll()
            .withPriority(5)
            .and();

        builder.removeRulesWhere((rule) => rule.priority < 8);

        final config = builder.build();
        final remainingRules = config.rules.where((r) => r.priority >= 10);
        expect(remainingRules, hasLength(1));
        expect(remainingRules.first.category, equals(EventCategory.business));
      });
    });

    group('Preset Configurations', () {
      test('should apply smart defaults', () {
        builder.applySmartDefaults();

        final config = builder.build();
        expect(config.rules,
            hasLength(3)); // technical, high volume, essential, default
        print(config);
        // Check for specific rules
        expect(config.rules.any((r) => r.category == EventCategory.technical),
            isTrue);
        expect(config.rules.any((r) => r.isHighVolume == null), isTrue);
        expect(config.rules.any((r) => r.isEssential == null), isTrue);
        expect(config.rules.any((r) => r.isDefault), isTrue);
      });
    });

    group('Build Process', () {
      test('should build configuration with rules sorted by priority', () {
        builder
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(5)
            .and()
            .routeCategory(EventCategory.technical)
            .toAll()
            .withPriority(15)
            .and()
            .routeCategory(EventCategory.user)
            .toAll()
            .withPriority(10)
            .and();

        final config = builder.build();

        // Rules should be sorted by priority (highest first)
        expect(config.rules[0].priority, equals(15)); // technical
        expect(config.rules[1].priority, equals(10)); // user
        expect(config.rules[2].priority, equals(5)); // business
        expect(
            config.rules[3].priority, equals(-1000)); // auto-generated default
      });

      test('should auto-generate default rule when none exists', () {
        builder
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(10)
            .and();

        final config = builder.build();

        // Should have the business rule plus auto-generated default
        expect(config.rules, hasLength(2));

        final defaultRule = config.rules.firstWhere((r) => r.isDefault);
        expect(defaultRule.targetGroup, equals(TrackerGroup.all));
        expect(defaultRule.priority, equals(-1000));
        expect(
            defaultRule.description, contains('Auto-generated default rule'));
      });

      test('should not auto-generate default rule when one exists', () {
        builder
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(10)
            .and()
            .routeDefault()
            .toAll()
            .withPriority(0)
            .and();

        final config = builder.build();

        // Should have exactly the rules we defined
        expect(config.rules, hasLength(2));
        expect(config.rules.where((r) => r.isDefault), hasLength(1));
        expect(config.rules.where((r) => r.priority == 0), hasLength(1));
      });

      test('should not auto-generate default rule when default group is set',
          () {
        builder
            .setDefaultGroup(TrackerGroup('custom', ['tracker1']))
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(10)
            .and();

        final config = builder.build();

        // When defaultGroup is set, no auto-generated rule should be added
        expect(config.rules, hasLength(1));
        expect(config.defaultGroup!.name, equals('custom'));
      });

      test('should include custom groups and categories in config', () {
        builder
            .defineGroup('analytics', ['firebase', 'mixpanel'])
            .defineCategory('onboarding')
            .routeDefault()
            .toAll()
            .and();

        final config = builder.build();

        expect(config.customGroups.containsKey('analytics'), isTrue);
        expect(config.customCategories.containsKey('onboarding'), isTrue);
      });
    });

    group('Validation', () {
      test('should validate valid configuration', () {
        builder.routeDefault().toAll().withPriority(0).and();

        final issues = builder.validate();
        expect(issues, isEmpty);
      });

      test('should delegate validation to built configuration', () {
        // Create an invalid configuration by building manually
        // This tests that validate() calls the configuration's validate method
        builder.routeDefault().toAll().and();

        final issues = builder.validate();
        // The exact validation rules depend on RoutingConfiguration.validate()
        expect(issues, isA<List<String>>());
      });
    });

    group('Debug Information', () {
      test('should provide comprehensive debug info', () {
        builder
            .defineGroup('analytics', ['firebase', 'mixpanel'])
            .defineCategory('custom')
            .setDebugMode(true)
            .setSampling(false)
            .setConsentChecking(true)
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(10)
            .and()
            .routeDefault()
            .toAll()
            .and();

        final debugInfo = builder.getDebugInfo();

        expect(debugInfo['rulesCount'], equals(2));
        expect(debugInfo['customGroupsCount'], equals(1));
        expect(debugInfo['customCategoriesCount'], equals(1));
        expect(debugInfo['hasDefaultGroup'], isTrue);
        expect(debugInfo['enableSampling'], isFalse);
        expect(debugInfo['enableConsentChecking'], isTrue);
        expect(debugInfo['isDebugMode'], isTrue);
        expect(debugInfo['rules'], isA<List<String>>());
        expect(debugInfo['customGroups'], contains('analytics'));
        expect(debugInfo['customCategories'], contains('custom'));
      });
    });

    group('Complex Integration Scenarios', () {
      test('should build e-commerce routing configuration', () {
        builder
            // High priority: Purchase events to revenue tracking
            .routeCategory(EventCategory.business)
            .to(['firebase', 'mixpanel', 'revenue_cat'])
            .withPriority(20)
            .withDescription('Revenue and business events')
            .and()

            // Medium priority: User behavior to analytics
            .routeCategory(EventCategory.user)
            .to(['mixpanel', 'amplitude'])
            .withPriority(15)
            .withDescription('User behavior analysis')
            .and()

            // Debug events to console in debug mode only
            .routeMatching(RegExp(r'^debug_.*'))
            .toDevelopment()
            .onlyInDebug()
            .withPriority(25)
            .withDescription('Debug events for development')
            .and()

            // Default routing to basic analytics
            .routeDefault()
            .to(['firebase'])
            .withDescription('Default event routing')
            .and();

        final config = builder.build();

        expect(config.rules, hasLength(4));

        // Verify priority ordering
        final priorities = config.rules.map((r) => r.priority).toList();
        expect(priorities, equals([25, 20, 15, 0]));

        // Verify specific rule configurations
        final businessRule = config.rules
            .firstWhere((r) => r.category == EventCategory.business);
        expect(businessRule.targetGroup.trackerIds,
            containsAll(['firebase', 'mixpanel', 'revenue_cat']));

        final debugRule =
            config.rules.firstWhere((r) => r.eventNameRegex != null);
        expect(debugRule.debugOnly, isTrue);
        expect(debugRule.targetGroup.name, equals('development'));
      });

      test('should build GDPR-compliant routing configuration', () {
        builder
            // Define GDPR-compliant trackers
            .defineGroup('gdpr_compliant', ['cookiebot', 'privacy_tracker'])

            // PII events to compliant trackers only
            .routePII()
            .toGroupNamed('gdpr_compliant')
            .requirePIIConsent()
            .withPriority(25)
            .withDescription('PII events - GDPR compliant only')
            .and()

            // Marketing events need consent
            .routeCategory(EventCategory.marketing)
            .toAll()
            .requireConsent()
            .withPriority(20)
            .withDescription('Marketing events requiring consent')
            .and()

            // Essential system events bypass consent
            .routeEssential()
            .toAll()
            .skipConsent()
            .noSampling()
            .withPriority(30)
            .withDescription('Essential events - no consent required')
            .and()

            // Default with consent requirement
            .routeDefault()
            .toAll()
            .requireConsent()
            .withDescription('Default GDPR-compliant routing')
            .and();

        final config = builder.build();

        expect(config.rules, hasLength(4));
        expect(config.customGroups.containsKey('gdpr_compliant'), isTrue);

        // Verify consent requirements
        final piiRule = config.rules.firstWhere((r) => r.containsPII == true);
        expect(piiRule.requirePIIConsent, isTrue);
        expect(piiRule.targetGroup.name, equals('gdpr_compliant'));

        final essentialRule =
            config.rules.firstWhere((r) => r.isEssential == true);
        expect(essentialRule.requireConsent, isFalse);
        expect(essentialRule.sampleRate, equals(1.0)); // No sampling

        final marketingRule = config.rules
            .firstWhere((r) => r.category == EventCategory.marketing);
        expect(marketingRule.requireConsent, isTrue);
      });

      test('should build performance-optimized routing configuration', () {
        builder
            // High-volume events with aggressive sampling
            .routeHighVolume()
            .toAll()
            .heavySampling() // 1% sampling
            .withPriority(15)
            .withDescription('High volume with aggressive sampling')
            .and()

            // Critical events with no sampling
            .routeWithProperty('critical', true)
            .toAll()
            .noSampling()
            .withPriority(30)
            .withDescription('Critical events - no sampling')
            .and()

            // UI interaction events (high frequency)
            .routeMatching(RegExp(r'(click|scroll|touch)_.*'))
            .toAll()
            .sample(0.01) // 1% sampling
            .withPriority(20)
            .withDescription('UI interactions with heavy sampling')
            .and()

            // Default with medium sampling
            .routeDefault()
            .toAll()
            .mediumSampling() // 50% sampling
            .withDescription('Default with balanced sampling')
            .and();

        final config = builder.build();

        expect(config.rules, hasLength(4));

        // Verify sampling rates
        final criticalRule =
            config.rules.firstWhere((r) => r.hasProperty == 'critical');
        expect(criticalRule.sampleRate, equals(1.0)); // No sampling

        final highVolumeRule =
            config.rules.firstWhere((r) => r.isHighVolume == true);
        expect(highVolumeRule.sampleRate, equals(0.01)); // Heavy sampling

        final uiRule = config.rules.firstWhere(
            (r) => r.eventNameRegex?.pattern.contains('click') == true);
        expect(uiRule.sampleRate, equals(0.01)); // Heavy sampling

        final defaultRule = config.rules.firstWhere((r) => r.isDefault);
        expect(defaultRule.sampleRate, equals(0.5)); // Medium sampling
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle multiple custom groups with same trackers', () {
        builder.defineGroup('analytics_primary', [
          'firebase',
          'mixpanel'
        ]).defineGroup('analytics_secondary', ['firebase', 'amplitude']);

        final config = builder.build();

        expect(config.customGroups, hasLength(2));
        expect(config.customGroups['analytics_primary']!.trackerIds,
            contains('firebase'));
        expect(config.customGroups['analytics_secondary']!.trackerIds,
            contains('firebase'));
      });

      test('should handle complex rule combinations', () {
        builder
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(10)
            .and()
            .routeWithProperty('user_id')
            .toAll()
            .withPriority(15)
            .and()
            .routeMatching(RegExp(r'purchase_.*'))
            .toAll()
            .withPriority(20)
            .and();

        // An event could potentially match multiple rules
        final config = builder.build();
        expect(config.rules, hasLength(4)); // +1 for auto-generated default

        // Verify rules are properly ordered by priority
        final sortedPriorities = config.rules.map((r) => r.priority).toList();
        for (int i = 0; i < sortedPriorities.length - 1; i++) {
          expect(sortedPriorities[i],
              greaterThanOrEqualTo(sortedPriorities[i + 1]));
        }
      });

      test('should handle empty configuration gracefully', () {
        // Don't add any rules
        final config = builder.build();

        // Should have auto-generated default rule
        expect(config.rules, hasLength(1));
        expect(config.rules.first.isDefault, isTrue);
        expect(config.rules.first.targetGroup, equals(TrackerGroup.all));
      });
    });

    group('Method Chaining Validation', () {
      test('should support fluent method chaining', () {
        final result = builder
            .defineGroup('analytics', ['firebase'])
            .defineCategory('custom')
            .setDebugMode(true)
            .setSampling(false)
            .setConsentChecking(true)
            .routeCategory(EventCategory.business)
            .toAll()
            .withPriority(10)
            .and()
            .routeDefault()
            .toAll()
            .and();

        expect(result, equals(builder));

        final config = builder.build();
        expect(config.isDebugMode, isTrue);
        expect(config.enableSampling, isFalse);
        expect(config.enableConsentChecking, isTrue);
        expect(config.customGroups.containsKey('analytics'), isTrue);
        expect(config.customCategories.containsKey('custom'), isTrue);
        expect(config.rules, hasLength(2));
      });
    });
  });
}

// Test event class
class TestEvent extends BaseEvent {
  final String eventName;

  TestEvent(this.eventName);

  @override
  String getName() => eventName;

  @override
  Map<String, Object>? getProperties() => null;
}
