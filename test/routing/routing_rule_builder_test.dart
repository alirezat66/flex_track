import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('RoutingRuleBuilder Tests - Complete Suite', () {
    late RoutingBuilder parentBuilder;
    late RouteConfigBuilder routeConfigBuilder;
    late RoutingRuleBuilder ruleBuilder;

    setUp(() {
      parentBuilder = RoutingBuilder();
      routeConfigBuilder = RouteConfigBuilder(parentBuilder);
      ruleBuilder = RoutingRuleBuilder(
        parentBuilder,
        routeConfigBuilder,
        TrackerGroup.all,
      );
    });

    group('Constructor and Basic Setup', () {
      test('should create RoutingRuleBuilder with correct references', () {
        expect(ruleBuilder, isA<RoutingRuleBuilder>());
        // The internal references are private, so we test through behavior
      });
    });

    group('Sampling Configuration', () {
      test('should set valid sample rate', () {
        final result = ruleBuilder.sample(0.5);

        expect(result, equals(ruleBuilder)); // Should return self for chaining

        // Complete the rule to test it was applied
        result.and();
        final config = parentBuilder.build();

        expect(config.rules, hasLength(2)); // +1 for auto-generated default
        expect(config.rules.first.sampleRate, equals(0.5));
      });

      test('should reject invalid sample rates', () {
        expect(
          () => ruleBuilder.sample(-0.1),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Sample rate must be between 0.0 and 1.0'))
              .having((e) => e.fieldName, 'fieldName', equals('sampleRate'))),
        );

        expect(
          () => ruleBuilder.sample(1.5),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Sample rate must be between 0.0 and 1.0'))
              .having((e) => e.fieldName, 'fieldName', equals('sampleRate'))),
        );
      });

      test('should set heavy sampling (1%)', () {
        ruleBuilder.heavySampling().and();

        final config = parentBuilder.build();
        expect(config.rules.first.sampleRate, equals(0.01));
      });

      test('should set light sampling (10%)', () {
        ruleBuilder.lightSampling().and();

        final config = parentBuilder.build();
        expect(config.rules.first.sampleRate, equals(0.1));
      });

      test('should set medium sampling (50%)', () {
        ruleBuilder.mediumSampling().and();

        final config = parentBuilder.build();
        expect(config.rules.first.sampleRate, equals(0.5));
      });

      test('should set no sampling (100%)', () {
        ruleBuilder.noSampling().and();

        final config = parentBuilder.build();
        expect(config.rules.first.sampleRate, equals(1.0));
      });
    });

    group('Consent Configuration', () {
      test('should require consent', () {
        ruleBuilder.requireConsent().and();

        final config = parentBuilder.build();
        expect(config.rules.first.requireConsent, isTrue);
      });

      test('should skip consent', () {
        ruleBuilder.skipConsent().and();

        final config = parentBuilder.build();
        expect(config.rules.first.requireConsent, isFalse);
      });

      test('should require PII consent', () {
        ruleBuilder.requirePIIConsent().and();

        final config = parentBuilder.build();
        expect(config.rules.first.requirePIIConsent, isTrue);
      });
    });

    group('Environment Configuration', () {
      test('should set debug only', () {
        ruleBuilder.onlyInDebug().and();

        final config = parentBuilder.build();
        expect(config.rules.first.debugOnly, isTrue);
        expect(config.rules.first.productionOnly, isFalse);
      });

      test('should set production only', () {
        ruleBuilder.onlyInProduction().and();

        final config = parentBuilder.build();
        expect(config.rules.first.productionOnly, isTrue);
        expect(config.rules.first.debugOnly, isFalse);
      });

      test('should not allow both debug and production only', () {
        ruleBuilder.onlyInDebug().onlyInProduction().and();

        final config = parentBuilder.build();
        // The last one should win
        expect(config.rules.first.productionOnly, isTrue);
        expect(config.rules.first.debugOnly, isFalse);
      });
    });

    group('Priority and Metadata Configuration', () {
      test('should set priority', () {
        ruleBuilder.withPriority(15).and();

        final config = parentBuilder.build();
        expect(config.rules.first.priority, equals(15));
      });

      test('should set high priority', () {
        ruleBuilder.highPriority().and();

        final config = parentBuilder.build();
        expect(config.rules.first.priority, equals(10));
      });

      test('should set low priority', () {
        ruleBuilder.lowPriority().and();

        final config = parentBuilder.build();
        expect(config.rules.first.priority, equals(-10));
      });

      test('should set description', () {
        ruleBuilder.withDescription('Test rule description').and();

        final config = parentBuilder.build();
        expect(config.rules.first.description, equals('Test rule description'));
      });

      test('should throw error for empty description', () {
        expect(
          () => ruleBuilder.withDescription(''),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Description cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('description'))),
        );
      });

      test('should set rule ID', () {
        ruleBuilder.withId('test_rule_123').and();

        final config = parentBuilder.build();
        expect(config.rules.first.id, equals('test_rule_123'));
      });

      test('should throw error for empty rule ID', () {
        expect(
          () => ruleBuilder.withId(''),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Rule ID cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('id'))),
        );
      });
    });

    group('Convenience Methods', () {
      test('should configure essential rule', () {
        ruleBuilder.essential().and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.requireConsent, isFalse); // skipConsent
        expect(rule.sampleRate, equals(1.0)); // noSampling
        expect(rule.priority, equals(10)); // highPriority
      });
    });

    group('Chaining Methods - Route Creation', () {
      test('should chain to new route by type', () {
        final newRouteBuilder = ruleBuilder.andRoute<TestEvent>();

        expect(newRouteBuilder, isA<RouteConfigBuilder<TestEvent>>());
        expect(newRouteBuilder.eventType, equals(TestEvent));
        expect(newRouteBuilder.parent, equals(parentBuilder));
      });

      test('should chain to new named route', () {
        final newRouteBuilder = ruleBuilder.andRouteNamed('purchase');

        expect(newRouteBuilder, isA<RouteConfigBuilder>());
        expect(newRouteBuilder.eventNamePattern, equals('purchase'));
        expect(newRouteBuilder.parent, equals(parentBuilder));
      });

      test('should chain to new regex route', () {
        final regex = RegExp(r'^debug_.*');
        final newRouteBuilder = ruleBuilder.andRouteMatching(regex);

        expect(newRouteBuilder, isA<RouteConfigBuilder>());
        expect(newRouteBuilder.eventNameRegex, equals(regex));
        expect(newRouteBuilder.parent, equals(parentBuilder));
      });

      test('should chain to default route', () {
        final newRouteBuilder = ruleBuilder.andRouteDefault();

        expect(newRouteBuilder, isA<RouteConfigBuilder>());
        expect(newRouteBuilder.isDefault, isTrue);
        expect(newRouteBuilder.parent, equals(parentBuilder));
      });
    });

    group('Chaining Methods - Builder Return', () {
      test('should return parent builder with and()', () {
        final result = ruleBuilder.and();

        expect(result, equals(parentBuilder));

        // Verify the rule was actually added
        final config = parentBuilder.build();
        expect(config.rules, hasLength(2)); // +1 for auto-generated default
      });
    });

    group('Description Generation', () {
      test('should generate description for event type rule', () {
        // Create a rule builder for a specific event type
        final typeConfigBuilder =
            RouteConfigBuilder<TestEvent>(parentBuilder, eventType: TestEvent);
        final typeRuleBuilder = RoutingRuleBuilder(
            parentBuilder, typeConfigBuilder, TrackerGroup.all);

        typeRuleBuilder.and();

        final config = parentBuilder.build();
        expect(config.rules.first.description, contains('TestEvent events'));
        expect(config.rules.first.description, contains('to all'));
      });

      test('should generate description for event name pattern rule', () {
        final patternConfigBuilder =
            RouteConfigBuilder(parentBuilder, eventNamePattern: 'purchase');
        final patternRuleBuilder = RoutingRuleBuilder(
            parentBuilder, patternConfigBuilder, TrackerGroup.all);

        patternRuleBuilder.and();

        final config = parentBuilder.build();

        expect(config.rules.first.description, contains('to all'));
      });

      test('should generate description for regex pattern rule', () {
        final regex = RegExp(r'^debug_.*');
        final regexConfigBuilder =
            RouteConfigBuilder(parentBuilder, eventNameRegex: regex);
        final regexRuleBuilder = RoutingRuleBuilder(
            parentBuilder, regexConfigBuilder, TrackerGroup.all);

        regexRuleBuilder.and();

        final config = parentBuilder.build();
        expect(config.rules.first.description,
            contains('BaseEvent events to all'));
      });

      test('should generate description for category rule', () {
        final categoryConfigBuilder =
            RouteConfigBuilder(parentBuilder, category: EventCategory.business);
        final categoryRuleBuilder = RoutingRuleBuilder(
            parentBuilder, categoryConfigBuilder, TrackerGroup.all);

        categoryRuleBuilder.and();

        final config = parentBuilder.build();
        expect(config.rules.first.description,
            contains('BaseEvent events to all'));
      });

      test('should generate description for default rule', () {
        final defaultConfigBuilder =
            RouteConfigBuilder(parentBuilder, isDefault: true);
        final defaultRuleBuilder = RoutingRuleBuilder(
            parentBuilder, defaultConfigBuilder, TrackerGroup.all);

        defaultRuleBuilder.and();

        final config = parentBuilder.build();
        expect(config.rules.first.description,
            contains('BaseEvent events to all'));
      });

      test('should include sampling information in description', () {
        ruleBuilder.sample(0.1).and();

        final config = parentBuilder.build();
        expect(config.rules.first.description, contains('10.0% sampled'));
      });

      test('should include environment information in description', () {
        ruleBuilder.onlyInDebug().and();

        final config = parentBuilder.build();
        expect(config.rules.first.description, contains('(debug only)'));

        // Test production only
        final prodRuleBuilder = RoutingRuleBuilder(
          parentBuilder,
          RouteConfigBuilder(parentBuilder),
          TrackerGroup.all,
        );
        prodRuleBuilder.onlyInProduction().and();

        final config2 = parentBuilder.build();
        expect(config2.rules[1].description, contains('(production only)'));
      });

      test('should prefer custom description over generated one', () {
        ruleBuilder.withDescription('Custom rule description').and();

        final config = parentBuilder.build();
        expect(
            config.rules.first.description, equals('Custom rule description'));
      });
    });

    group('Complex Rule Configuration', () {
      test('should configure comprehensive business rule', () {
        ruleBuilder
            .sample(0.8)
            .requireConsent()
            .requirePIIConsent()
            .withPriority(20)
            .withId('business_rule_001')
            .withDescription('Comprehensive business event tracking')
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.sampleRate, equals(0.8));
        expect(rule.requireConsent, isTrue);
        expect(rule.requirePIIConsent, isTrue);
        expect(rule.priority, equals(20));
        expect(rule.id, equals('business_rule_001'));
        expect(
            rule.description, equals('Comprehensive business event tracking'));
      });

      test('should configure debug-only technical rule', () {
        ruleBuilder
            .onlyInDebug()
            .skipConsent()
            .noSampling()
            .withPriority(25)
            .withDescription('Debug events for development')
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.debugOnly, isTrue);
        expect(rule.productionOnly, isFalse);
        expect(rule.requireConsent, isFalse);
        expect(rule.sampleRate, equals(1.0));
        expect(rule.priority, equals(25));
        expect(rule.description, equals('Debug events for development'));
      });

      test('should configure production-only critical rule', () {
        ruleBuilder
            .onlyInProduction()
            .essential() // This includes skipConsent, noSampling, highPriority
            .withId('critical_prod_rule')
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.productionOnly, isTrue);
        expect(rule.debugOnly, isFalse);
        expect(rule.requireConsent, isFalse); // From essential()
        expect(rule.sampleRate, equals(1.0)); // From essential()
        expect(rule.priority, equals(10)); // From essential()
        expect(rule.id, equals('critical_prod_rule'));
      });

      test('should configure sampled marketing rule', () {
        ruleBuilder
            .lightSampling() // 10%
            .requireConsent()
            .withPriority(12)
            .withDescription('Marketing events with light sampling')
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.sampleRate, equals(0.1));
        expect(rule.requireConsent, isTrue);
        expect(rule.requirePIIConsent, isFalse);
        expect(rule.priority, equals(12));
        expect(
            rule.description, equals('Marketing events with light sampling'));
      });
    });

    group('Integration with Different Target Groups', () {
      test('should work with custom tracker groups', () {
        parentBuilder.defineGroup('analytics', ['firebase', 'mixpanel']);

        final customGroupBuilder = RoutingRuleBuilder(
          parentBuilder,
          RouteConfigBuilder(parentBuilder),
          parentBuilder.getGroup('analytics')!,
        );

        customGroupBuilder
            .withPriority(15)
            .withDescription('Analytics group routing')
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.targetGroup.name, equals('analytics'));
        expect(
            rule.targetGroup.trackerIds, containsAll(['firebase', 'mixpanel']));
      });

      test('should work with development tracker group', () {
        final devGroupBuilder = RoutingRuleBuilder(
          parentBuilder,
          RouteConfigBuilder(parentBuilder),
          TrackerGroup.development,
        );

        devGroupBuilder
            .onlyInDebug()
            .noSampling()
            .withDescription('Development tracking')
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.targetGroup.name, equals('development'));
        expect(rule.debugOnly, isTrue);
        expect(rule.sampleRate, equals(1.0));
      });

      test('should work with single tracker group', () {
        final singleTrackerGroup = TrackerGroup('single', ['firebase']);
        final singleGroupBuilder = RoutingRuleBuilder(
          parentBuilder,
          RouteConfigBuilder(parentBuilder),
          singleTrackerGroup,
        );

        singleGroupBuilder
            .withPriority(8)
            .withDescription('Single tracker routing')
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.targetGroup.trackerIds, equals(['firebase']));
      });
    });

    group('Method Chaining Validation', () {
      test('should support complex method chaining', () {
        final result = ruleBuilder
            .sample(0.5)
            .requireConsent()
            .requirePIIConsent()
            .withPriority(20)
            .withId('complex_rule')
            .withDescription('Complex chained rule')
            .and()
            .routeCategory(EventCategory.business)
            .toAll()
            .sample(0.8)
            .withPriority(15)
            .and();

        expect(result, equals(parentBuilder));

        final config = parentBuilder.build();
        expect(config.rules, hasLength(3)); // 2 rules + auto-generated default

        // Verify both rules were configured correctly
        final sortedRules = config.rules.where((r) => r.priority > 0).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

        expect(sortedRules[0].id, equals('complex_rule'));
        expect(sortedRules[0].priority, equals(20));
        expect(sortedRules[0].sampleRate, equals(0.5));

        expect(sortedRules[1].priority, equals(15));
        expect(sortedRules[1].sampleRate, equals(0.8));
      });

      test('should support chaining between different route types', () {
        final result = ruleBuilder
            .withPriority(10)
            .and()
            .routeNamed('purchase')
            .toAll()
            .withPriority(20)
            .andRoute<TestEvent>()
            .toAll()
            .withPriority(15)
            .andRouteDefault()
            .toAll()
            .withPriority(0)
            .and();

        expect(result, equals(parentBuilder));

        final config = parentBuilder.build();
        expect(config.rules,
            hasLength(4)); // 3 explicit + 1 default (from andRouteDefault)

        // Verify priority ordering
        final priorities = config.rules.map((r) => r.priority).toList();
        expect(priorities, contains(20)); // Named route
        expect(priorities, contains(15)); // Typed route
        expect(priorities, contains(10)); // Original route
        expect(priorities, contains(0)); // Default route
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle multiple calls to same configuration method', () {
        ruleBuilder
            .sample(0.1)
            .sample(0.5) // Should overwrite the first
            .withPriority(5)
            .withPriority(15) // Should overwrite the first
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.sampleRate, equals(0.5)); // Last value wins
        expect(rule.priority, equals(15)); // Last value wins
      });

      test('should handle conflicting environment settings gracefully', () {
        ruleBuilder
            .onlyInDebug()
            .onlyInProduction() // Should overwrite debug setting
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.productionOnly, isTrue);
        expect(rule.debugOnly, isFalse);
      });

      test('should handle conflicting consent settings', () {
        ruleBuilder
            .requireConsent()
            .skipConsent() // Should overwrite require setting
            .and();

        final config = parentBuilder.build();
        final rule = config.rules.first;

        expect(rule.requireConsent, isFalse);
      });

      test('should handle extreme priority values', () {
        ruleBuilder.withPriority(999).and();

        final config = parentBuilder.build();
        expect(config.rules.first.priority, equals(999));

        // Test negative priority
        final negativeRuleBuilder = RoutingRuleBuilder(
          parentBuilder,
          RouteConfigBuilder(parentBuilder),
          TrackerGroup.all,
        );
        negativeRuleBuilder.withPriority(-999).and();

        final config2 = parentBuilder.build();
        expect(config2.rules[1].priority, equals(-999));
      });

      test('should handle zero sampling rate', () {
        ruleBuilder.sample(0.0).and();

        final config = parentBuilder.build();
        expect(config.rules.first.sampleRate, equals(0.0));
      });

      test('should handle very long descriptions', () {
        final longDescription = 'A' * 500;
        ruleBuilder.withDescription(longDescription).and();

        final config = parentBuilder.build();
        expect(config.rules.first.description, equals(longDescription));
      });

      test('should handle very long rule IDs', () {
        final longId = 'rule_${'x' * 100}';
        ruleBuilder.withId(longId).and();

        final config = parentBuilder.build();
        expect(config.rules.first.id, equals(longId));
      });
    });

    group('Description Generation Edge Cases', () {
      test('should handle missing config properties gracefully', () {
        // Create a minimal config builder
        final minimalConfigBuilder = RouteConfigBuilder(parentBuilder);
        final minimalRuleBuilder = RoutingRuleBuilder(
          parentBuilder,
          minimalConfigBuilder,
          TrackerGroup.all,
        );

        minimalRuleBuilder.and();

        final config = parentBuilder.build();
        expect(config.rules.first.description, contains('events to all'));
      });

      test('should handle complex target group names', () {
        final complexGroup =
            TrackerGroup('analytics_premium_users', ['tracker1']);
        final complexRuleBuilder = RoutingRuleBuilder(
          parentBuilder,
          RouteConfigBuilder(parentBuilder),
          complexGroup,
        );

        complexRuleBuilder.and();

        final config = parentBuilder.build();
        expect(config.rules.first.description,
            contains('to analytics_premium_users'));
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
