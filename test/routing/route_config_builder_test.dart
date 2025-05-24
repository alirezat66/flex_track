import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('RouteConfigBuilder Tests - Complete Suite', () {
    late RoutingBuilder parentBuilder;
    late RouteConfigBuilder routeConfigBuilder;

    setUp(() {
      parentBuilder = RoutingBuilder();
    });

    group('Constructor and Basic Setup', () {
      test('should create RouteConfigBuilder with event type', () {
        routeConfigBuilder = RouteConfigBuilder<TestEvent>(
          parentBuilder,
          eventType: TestEvent,
        );

        expect(routeConfigBuilder.eventType, equals(TestEvent));
        expect(routeConfigBuilder.parent, equals(parentBuilder));
      });

      test('should create RouteConfigBuilder with event name pattern', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventNamePattern: 'user_action',
        );

        expect(routeConfigBuilder.eventNamePattern, equals('user_action'));
        expect(routeConfigBuilder.parent, equals(parentBuilder));
      });

      test('should create RouteConfigBuilder with regex pattern', () {
        final regex = RegExp(r'^debug_.*');
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventNameRegex: regex,
        );

        expect(routeConfigBuilder.eventNameRegex, equals(regex));
        expect(routeConfigBuilder.parent, equals(parentBuilder));
      });

      test('should create RouteConfigBuilder with category', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          category: EventCategory.business,
        );

        expect(routeConfigBuilder.category, equals(EventCategory.business));
      });

      test('should create RouteConfigBuilder with property conditions', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          hasProperty: 'user_id',
          propertyValue: '12345',
        );

        expect(routeConfigBuilder.hasProperty, equals('user_id'));
        expect(routeConfigBuilder.propertyValue, equals('12345'));
      });

      test('should create RouteConfigBuilder with event flags', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          containsPII: true,
          isHighVolume: false,
          isEssential: true,
        );

        expect(routeConfigBuilder.containsPII, isTrue);
        expect(routeConfigBuilder.isHighVolume, isFalse);
        expect(routeConfigBuilder.isEssential, isTrue);
      });

      test('should create default RouteConfigBuilder', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          isDefault: true,
        );

        expect(routeConfigBuilder.isDefault, isTrue);
      });
    });

    group('Target Specification - Basic Methods', () {
      test('should route to all trackers', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder = routeConfigBuilder.toAll();

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
        // We can't directly test the internal target group, but we can verify
        // the method returns a RoutingRuleBuilder which should be properly configured
      });

      test('should route to specific trackers by ID', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);
        final trackerIds = ['firebase', 'mixpanel', 'amplitude'];

        final ruleBuilder = routeConfigBuilder.to(trackerIds);

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should throw error when routing to empty tracker list', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        expect(
          () => routeConfigBuilder.to([]),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Cannot route to empty tracker list'))
              .having((e) => e.fieldName, 'fieldName', equals('trackerIds'))),
        );
      });

      test('should route to custom tracker group', () {
        final customGroup = TrackerGroup('analytics', ['firebase', 'mixpanel']);
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder = routeConfigBuilder.toGroup(customGroup);

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should route to group by name when group exists', () {
        // First, define a custom group in the parent builder
        parentBuilder.defineGroup('custom_analytics', ['firebase', 'mixpanel']);
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder = routeConfigBuilder.toGroupNamed('custom_analytics');

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should throw error when routing to non-existent group name', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        expect(
          () => routeConfigBuilder.toGroupNamed('nonexistent_group'),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Unknown tracker group: nonexistent_group'))
              .having((e) => e.fieldName, 'fieldName', equals('groupName'))),
        );
      });

      test('should route to development trackers', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder = routeConfigBuilder.toDevelopment();

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });
    });

    group('Target Specification - Predefined Groups', () {
      test('should route to predefined "all" group', () {
        parentBuilder.defineGroup('all', ['*']); // Define 'all' group
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder = routeConfigBuilder.toGroupNamed('all');

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should route to predefined "development" group', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder = routeConfigBuilder.toGroupNamed('development');

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });
    });

    group('Convenience Methods', () {
      test('should use everywhere() as alias for toAll()', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder1 = routeConfigBuilder.toAll();

        // Create a new instance to test the alias
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);
        final ruleBuilder2 = routeConfigBuilder.everywhere();

        expect(ruleBuilder1, isA<RoutingRuleBuilder>());
        expect(ruleBuilder2, isA<RoutingRuleBuilder>());
        // Both should create similar rule builders
      });

      test('should use debugOnly() as alias for toDevelopment()', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder1 = routeConfigBuilder.toDevelopment();

        // Create a new instance to test the alias
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);
        final ruleBuilder2 = routeConfigBuilder.debugOnly();

        expect(ruleBuilder1, isA<RoutingRuleBuilder>());
        expect(ruleBuilder2, isA<RoutingRuleBuilder>());
      });

      test('should route to single tracker', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final ruleBuilder = routeConfigBuilder.toTracker('firebase');

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should throw error when routing to tracker with empty ID', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        expect(
          () => routeConfigBuilder.toTracker(''),
          throwsA(isA<ConfigurationException>()
              .having((e) => e.message, 'message',
                  contains('Tracker ID cannot be empty'))
              .having((e) => e.fieldName, 'fieldName', equals('trackerId'))),
        );
      });
    });

    group('Integration with RoutingRuleBuilder', () {
      test('should create properly configured RoutingRuleBuilder', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventNamePattern: 'purchase',
          category: EventCategory.business,
        );

        final ruleBuilder = routeConfigBuilder.to(['firebase', 'mixpanel']);

        expect(ruleBuilder, isA<RoutingRuleBuilder>());

        // Test that we can continue chaining
        final finalBuilder = ruleBuilder
            .withPriority(10)
            .withDescription('Purchase events')
            .and();

        expect(finalBuilder, equals(parentBuilder));
      });

      test('should maintain parent builder reference through chaining', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        final chainedBuilder = routeConfigBuilder.toAll().withPriority(5).and();

        expect(chainedBuilder, equals(parentBuilder));
      });
    });

    group('Complex Routing Scenarios', () {
      test('should handle business events to multiple specific trackers', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventType: BusinessEvent,
          category: EventCategory.business,
        );

        final ruleBuilder = routeConfigBuilder.to(
            ['firebase_analytics', 'mixpanel', 'amplitude', 'revenue_tracker']);

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should handle PII events to secure trackers only', () {
        // Define a secure group
        parentBuilder.defineGroup(
            'secure_trackers', ['gdpr_compliant_analytics', 'secure_storage']);

        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          containsPII: true,
          category: EventCategory.sensitive,
        );

        final ruleBuilder = routeConfigBuilder.toGroupNamed('secure_trackers');

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should handle debug events to development environment', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventNameRegex: RegExp(r'^debug_.*'),
          category: EventCategory.technical,
        );

        final ruleBuilder = routeConfigBuilder.toDevelopment();

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should handle high-volume events with specific routing', () {
        parentBuilder.defineGroup(
            'high_capacity', ['scalable_analytics', 'data_warehouse']);

        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          isHighVolume: true,
          hasProperty: 'batch_id',
        );

        final ruleBuilder = routeConfigBuilder.toGroupNamed('high_capacity');

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should handle essential events to critical systems', () {
        parentBuilder.defineGroup('critical_systems',
            ['health_monitor', 'alert_system', 'audit_log']);

        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          isEssential: true,
          category: EventCategory.security,
        );

        final ruleBuilder = routeConfigBuilder.toGroupNamed('critical_systems');

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });
    });

    group('Property-Based Routing Configuration', () {
      test('should configure routing based on property existence', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          hasProperty: 'experiment_id',
        );

        final ruleBuilder = routeConfigBuilder.to(['experiment_tracker']);

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should configure routing based on property value', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          hasProperty: 'environment',
          propertyValue: 'production',
        );

        final ruleBuilder = routeConfigBuilder.to(['prod_analytics']);

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });

      test('should configure routing for user tier properties', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          hasProperty: 'user_tier',
          propertyValue: 'premium',
        );

        final ruleBuilder = routeConfigBuilder
            .to(['premium_analytics', 'customer_success_tracker']);

        expect(ruleBuilder, isA<RoutingRuleBuilder>());
      });
    });

    group('Full Integration Test Scenarios', () {
      test('should build complete routing configuration for e-commerce app',
          () {
        // Business events to revenue tracking
        parentBuilder
            .routeCategory(EventCategory.business)
            .to(['firebase', 'mixpanel', 'revenue_cat'])
            .withPriority(20)
            .withDescription('Revenue events')
            .and();

        // User behavior to user analytics
        parentBuilder
            .routeCategory(EventCategory.user)
            .to(['mixpanel', 'amplitude'])
            .withPriority(15)
            .withDescription('User behavior')
            .and();

        // Debug events to console only
        parentBuilder
            .routeMatching(RegExp(r'^debug_.*'))
            .toDevelopment()
            .onlyInDebug()
            .withPriority(25)
            .and();

        // Default routing
        parentBuilder
            .routeDefault()
            .to(['firebase']).withDescription('Default events');

        final config = parentBuilder.build();

        expect(config.rules, hasLength(3));
        expect(config.rules.map((r) => r.priority).toList(),
            containsAll([25, 20, 15]));
      });

      test('should build GDPR-compliant routing configuration', () {
        // Define GDPR-compliant trackers
        parentBuilder.defineGroup(
            'gdpr_compliant', ['cookiebot_analytics', 'privacy_first_tracker']);

        // PII events to compliant trackers only
        parentBuilder
            .routePII()
            .toGroupNamed('gdpr_compliant')
            .requirePIIConsent()
            .withPriority(25)
            .and();

        // Marketing events need consent
        parentBuilder
            .routeCategory(EventCategory.marketing)
            .toAll()
            .requireConsent()
            .withPriority(20)
            .and();

        // Essential system events bypass consent
        parentBuilder
            .routeEssential()
            .toAll()
            .skipConsent()
            .withPriority(30)
            .and();

        final config = parentBuilder.build();

        expect(config.rules, hasLength(4));
        expect(config.customGroups.containsKey('gdpr_compliant'), isTrue);

        // Verify priorities are correct
        final priorities = config.rules.map((r) => r.priority).toList()..sort();
        expect(priorities, equals([-1000, 20, 25, 30]));
      });

      test('should build performance-optimized routing configuration', () {
        // High-volume events with heavy sampling
        parentBuilder
            .routeHighVolume()
            .toAll()
            .heavySampling() // 1% sampling
            .withPriority(15)
            .withDescription('High volume with sampling')
            .and();

        // Critical events with no sampling
        parentBuilder
            .routeWithProperty('critical', true)
            .toAll()
            .noSampling()
            .withPriority(30)
            .withDescription('Critical events - no sampling')
            .and();

        // Regular events with medium sampling
        parentBuilder
            .routeDefault()
            .toAll()
            .mediumSampling() // 50% sampling
            .withDescription('Default with medium sampling');

        final config = parentBuilder.build();

        expect(config.rules, hasLength(2));

        // Check sampling rates are properly configured
        final criticalRule = config.rules.firstWhere((r) => r.priority == 30);
        expect(criticalRule.sampleRate, equals(1.0)); // No sampling

        final highVolumeRule = config.rules.firstWhere((r) => r.priority == 15);
        expect(highVolumeRule.sampleRate, equals(0.01)); // Heavy sampling
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle null parent builder gracefully', () {
        // This test depends on the constructor implementation
        // If null parent is not allowed, this should throw
        expect(
          () => RouteConfigBuilder(null as dynamic),
          throwsA(anything), // Expecting some kind of error
        );
      });

      test('should handle complex tracker ID validation', () {
        routeConfigBuilder = RouteConfigBuilder(parentBuilder);

        // Valid tracker IDs
        expect(
          () => routeConfigBuilder.to(['valid_tracker_123', 'another-tracker']),
          returnsNormally,
        );

        // Invalid empty list already tested above
      });

      test('should maintain consistency with multiple method calls', () {
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventNamePattern: 'test',
        );

        // Multiple calls should all return RoutingRuleBuilder
        expect(routeConfigBuilder.toAll(), isA<RoutingRuleBuilder>());

        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventNamePattern: 'test',
        );
        expect(routeConfigBuilder.toDevelopment(), isA<RoutingRuleBuilder>());

        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventNamePattern: 'test',
        );
        expect(routeConfigBuilder.to(['tracker1']), isA<RoutingRuleBuilder>());
      });
    });

    group('Getter Methods Coverage', () {
      test('should expose all configuration properties through getters', () {
        final regex = RegExp(r'^test_.*');
        routeConfigBuilder = RouteConfigBuilder(
          parentBuilder,
          eventType: TestEvent,
          eventNamePattern: 'test_pattern',
          eventNameRegex: regex,
          category: EventCategory.marketing,
          hasProperty: 'campaign_id',
          propertyValue: 'summer_2024',
          containsPII: true,
          isHighVolume: false,
          isEssential: true,
          isDefault: false,
        );

        expect(routeConfigBuilder.eventType, equals(TestEvent));
        expect(routeConfigBuilder.eventNamePattern, equals('test_pattern'));
        expect(routeConfigBuilder.eventNameRegex, equals(regex));
        expect(routeConfigBuilder.category, equals(EventCategory.marketing));
        expect(routeConfigBuilder.hasProperty, equals('campaign_id'));
        expect(routeConfigBuilder.propertyValue, equals('summer_2024'));
        expect(routeConfigBuilder.containsPII, isTrue);
        expect(routeConfigBuilder.isHighVolume, isFalse);
        expect(routeConfigBuilder.isEssential, isTrue);
        expect(routeConfigBuilder.isDefault, isFalse);
        expect(routeConfigBuilder.parent, equals(parentBuilder));
      });
    });
  });
}

// Test event classes
class TestEvent extends BaseEvent {
  final String eventName;

  TestEvent(this.eventName);

  @override
  String getName() => eventName;

  @override
  Map<String, Object>? getProperties() => null;
}

class BusinessEvent extends BaseEvent {
  final String eventName;
  final double revenue;

  BusinessEvent(this.eventName, this.revenue);

  @override
  String getName() => eventName;

  @override
  Map<String, Object> getProperties() => {'revenue': revenue};

  @override
  EventCategory get category => EventCategory.business;
}
