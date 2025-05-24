import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('GDPRDefaults Tests', () {
    late RoutingBuilder builder;

    setUp(() {
      builder = RoutingBuilder();
    });

    group('apply() - Standard GDPR Defaults', () {
      test('should apply GDPR routing rules without compliant trackers', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();

        // Should have all expected GDPR rules
        expect(config.rules.length, equals(14));

        // Check priority ordering (highest to lowest)
        final priorities = config.rules.map((r) => r.priority).toList();
        expect(priorities.first, equals(25)); // Security events highest
        expect(priorities.contains(0), isTrue); // Default rule present
      });

      test('should apply GDPR routing rules with compliant trackers', () {
        final compliantTrackers = ['gdpr_tracker_1', 'gdpr_tracker_2'];
        GDPRDefaults.apply(builder, compliantTrackers: compliantTrackers);

        final config = builder.build();

        // Should define the compliant group
        expect(config.customGroups.containsKey('gdpr_compliant'), isTrue);
        expect(config.customGroups['gdpr_compliant']!.trackerIds,
            equals(compliantTrackers));
      });

      test('should configure sensitive data events with strictest controls',
          () {
        final compliantTrackers = ['gdpr_tracker'];
        GDPRDefaults.apply(builder, compliantTrackers: compliantTrackers);

        final config = builder.build();
        final sensitiveRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.sensitive,
        );

        expect(sensitiveRule.targetGroup.name, equals('gdpr_compliant'));
        expect(sensitiveRule.requirePIIConsent, isTrue);
        expect(sensitiveRule.requireConsent, isTrue);
        expect(sensitiveRule.sampleRate, equals(1.0)); // noSampling
        expect(sensitiveRule.priority, equals(20));
        expect(sensitiveRule.description,
            contains('Sensitive data - GDPR compliant trackers only'));
      });

      test('should configure PII events with explicit consent', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final piiRule = config.rules.firstWhere(
          (rule) => rule.containsPII == true,
        );

        expect(piiRule.requirePIIConsent, isTrue);
        expect(piiRule.sampleRate, equals(1.0)); // noSampling
        expect(piiRule.priority, equals(18));
        expect(piiRule.description,
            contains('PII events requiring explicit consent'));
      });

      test('should configure user behavior events with general consent', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final userRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.user,
        );

        expect(userRule.targetGroup, equals(TrackerGroup.all));
        expect(userRule.requireConsent, isTrue);
        expect(userRule.sampleRate, equals(0.5)); // mediumSampling
        expect(userRule.priority, equals(12));
        expect(userRule.description,
            contains('User behavior events requiring consent'));
      });

      test('should configure marketing events with full consent', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final marketingRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.marketing,
        );

        expect(marketingRule.requireConsent, isTrue);
        expect(marketingRule.requirePIIConsent, isTrue);
        expect(marketingRule.sampleRate, equals(0.1)); // lightSampling
        expect(marketingRule.priority, equals(15));
        expect(marketingRule.description,
            contains('Marketing events requiring full consent'));
      });

      test('should configure email property events', () {
        final compliantTrackers = ['gdpr_tracker'];
        GDPRDefaults.apply(builder, compliantTrackers: compliantTrackers);

        final config = builder.build();
        final emailRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'email',
        );

        expect(emailRule.targetGroup.name, equals('gdpr_compliant'));
        expect(emailRule.requirePIIConsent, isTrue);
        expect(emailRule.sampleRate, equals(1.0)); // noSampling
        expect(emailRule.priority, equals(19));
        expect(emailRule.description,
            contains('Events with email - PII consent required'));
      });

      test('should configure phone property events', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final phoneRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'phone',
        );

        expect(phoneRule.requirePIIConsent, isTrue);
        expect(phoneRule.sampleRate, equals(1.0)); // noSampling
        expect(phoneRule.priority, equals(19));
        expect(phoneRule.description,
            contains('Events with phone - PII consent required'));
      });

      test('should configure IP address property events', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final ipRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'ip_address',
        );

        expect(ipRule.requirePIIConsent, isTrue);
        expect(ipRule.sampleRate, equals(1.0)); // noSampling
        expect(ipRule.priority, equals(19));
        expect(ipRule.description,
            contains('Events with IP address - PII consent required'));
      });

      test('should configure location data events', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final locationRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'location',
        );

        expect(locationRule.requirePIIConsent, isTrue);
        expect(locationRule.sampleRate, equals(1.0)); // noSampling
        expect(locationRule.priority, equals(17));
        expect(locationRule.description,
            contains('Location data - strict PII consent required'));
      });

      test('should configure GPS coordinates events', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final latitudeRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'latitude',
        );

        expect(latitudeRule.requirePIIConsent, isTrue);
        expect(latitudeRule.sampleRate, equals(1.0)); // noSampling
        expect(latitudeRule.priority, equals(17));
        expect(latitudeRule.description,
            contains('GPS coordinates - strict PII consent required'));
      });

      test('should configure security events with legitimate interest', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final securityRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.security,
        );

        expect(securityRule.targetGroup, equals(TrackerGroup.all));
        expect(securityRule.requireConsent, isFalse); // skipConsent
        expect(securityRule.sampleRate, equals(1.0)); // noSampling
        expect(securityRule.priority, equals(25));
        expect(securityRule.description,
            contains('Security events - legitimate interest basis'));
      });

      test('should configure essential events with legitimate interest', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final essentialRule = config.rules.firstWhere(
          (rule) => rule.isEssential == true,
        );

        expect(essentialRule.targetGroup, equals(TrackerGroup.all));
        expect(essentialRule.requireConsent, isFalse); // skipConsent
        expect(essentialRule.sampleRate, equals(1.0)); // noSampling
        expect(essentialRule.priority, equals(24));
        expect(essentialRule.description,
            contains('Essential events - legitimate interest basis'));
      });

      test('should configure system events as non-personal', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final systemRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.system,
        );

        expect(systemRule.targetGroup, equals(TrackerGroup.all));
        expect(systemRule.requireConsent, isFalse); // skipConsent
        expect(systemRule.sampleRate, equals(0.1)); // lightSampling
        expect(systemRule.priority, equals(8));
        expect(systemRule.description,
            contains('System events - no personal data'));
      });

      test('should configure technical events as anonymous debug data', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final technicalRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.technical,
        );

        expect(technicalRule.targetGroup.name, equals('development'));
        expect(technicalRule.requireConsent, isFalse); // skipConsent
        expect(technicalRule.sampleRate, equals(0.1)); // lightSampling
        expect(technicalRule.debugOnly, isTrue);
        expect(technicalRule.priority, equals(6));
        expect(technicalRule.description,
            contains('Technical events - anonymous debug data'));
      });

      test('should have GDPR-compliant default rule', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final defaultRule = config.rules.firstWhere(
          (rule) => rule.isDefault == true,
        );

        expect(defaultRule.targetGroup, equals(TrackerGroup.all));
        expect(defaultRule.requireConsent, isTrue);
        expect(defaultRule.sampleRate, equals(0.5)); // mediumSampling
        expect(defaultRule.priority, equals(0));
        expect(defaultRule.description,
            contains('Default GDPR-compliant routing'));
      });
    });

    group('applyStrict() - Strict GDPR Compliance', () {
      test('should apply strict GDPR routing rules', () {
        GDPRDefaults.applyStrict(builder);

        final config = builder.build();

        // Should have base rules plus additional strict rules
        expect(config.rules.length, greaterThan(14));
      });

      test('should require PII consent for user_id events', () {
        final compliantTrackers = ['strict_tracker'];
        GDPRDefaults.applyStrict(builder, compliantTrackers: compliantTrackers);

        final config = builder.build();
        final userIdRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'user_id',
        );

        expect(userIdRule.targetGroup.name, equals('gdpr_compliant'));
        expect(userIdRule.requirePIIConsent, isTrue);
        expect(userIdRule.sampleRate, equals(1.0)); // noSampling
        expect(userIdRule.priority, equals(22));
        expect(userIdRule.description,
            contains('User ID events - strict PII consent'));
      });

      test('should require consent for session_id events', () {
        GDPRDefaults.applyStrict(builder);

        final config = builder.build();
        final sessionIdRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'session_id',
        );

        expect(sessionIdRule.requireConsent, isTrue);
        expect(sessionIdRule.sampleRate, equals(0.1)); // lightSampling
        expect(sessionIdRule.priority, equals(13));
        expect(sessionIdRule.description,
            contains('Session tracking - consent required'));
      });

      test('should require consent for behavioral events', () {
        GDPRDefaults.applyStrict(builder);

        final config = builder.build();
        final behavioralRule = config.rules.firstWhere(
          (rule) =>
              rule.eventNameRegex?.pattern ==
              r'(click|view|scroll|interaction)_.*',
        );

        expect(behavioralRule.targetGroup, equals(TrackerGroup.all));
        expect(behavioralRule.requireConsent, isTrue);
        expect(behavioralRule.sampleRate, equals(0.5)); // mediumSampling
        expect(behavioralRule.priority, equals(14));
        expect(behavioralRule.description,
            contains('Behavioral events - consent required'));
      });
    });

    group('applyMinimal() - Minimal GDPR Compliance', () {
      test('should apply minimal GDPR routing rules', () {
        GDPRDefaults.applyMinimal(builder);

        final config = builder.build();

        // Should have fewer rules than standard GDPR
        expect(config.rules.length, equals(5));
      });

      test('should handle PII events in minimal compliance', () {
        final compliantTrackers = ['minimal_tracker'];
        GDPRDefaults.applyMinimal(builder,
            compliantTrackers: compliantTrackers);

        final config = builder.build();
        final piiRule = config.rules.firstWhere(
          (rule) => rule.containsPII == true,
        );

        expect(piiRule.targetGroup.name,
            equals(compliantTrackers.isNotEmpty ? 'gdpr_compliant' : 'all'));
        expect(piiRule.requirePIIConsent, isTrue);
        expect(piiRule.priority, equals(16));
        expect(piiRule.description,
            contains('PII events - minimal GDPR compliance'));
      });

      test('should handle sensitive events in minimal compliance', () {
        GDPRDefaults.applyMinimal(builder);

        final config = builder.build();
        final sensitiveRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.sensitive,
        );

        expect(sensitiveRule.requirePIIConsent, isTrue);
        expect(sensitiveRule.priority, equals(15));
        expect(sensitiveRule.description,
            contains('Sensitive events - minimal GDPR compliance'));
      });

      test(
          'should allow essential events without consent in minimal compliance',
          () {
        GDPRDefaults.applyMinimal(builder);

        final config = builder.build();
        final essentialRule = config.rules.firstWhere(
          (rule) => rule.isEssential == true,
        );

        expect(essentialRule.requireConsent, isFalse); // skipConsent
        expect(essentialRule.priority, equals(20));
        expect(essentialRule.description,
            contains('Essential events - legitimate interest'));
      });

      test('should allow security events without consent in minimal compliance',
          () {
        GDPRDefaults.applyMinimal(builder);

        final config = builder.build();
        final securityRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.security,
        );

        expect(securityRule.requireConsent, isFalse); // skipConsent
        expect(securityRule.priority, equals(18));
        expect(securityRule.description,
            contains('Security events - legitimate interest'));
      });

      test('should have minimal default rule', () {
        GDPRDefaults.applyMinimal(builder);

        final config = builder.build();
        final defaultRule = config.rules.firstWhere(
          (rule) => rule.isDefault == true,
        );

        expect(defaultRule.priority, equals(0));
        expect(
            defaultRule.description, contains('Default minimal GDPR routing'));
      });
    });

    group('applyForRegion() - Regional Compliance', () {
      test('should apply strict rules for EU region', () {
        GDPRDefaults.applyForRegion(builder, GDPRRegion.eu);

        final config = builder.build();

        // Should have many rules like applyStrict
        expect(config.rules.length, greaterThan(14));

        // Should have the strict user_id rule
        final userIdRule = config.rules.where(
          (rule) => rule.hasProperty == 'user_id',
        );
        expect(userIdRule, isNotEmpty);
      });

      test('should apply standard rules for UK region', () {
        GDPRDefaults.applyForRegion(builder, GDPRRegion.uk);

        final config = builder.build();

        // Should have same number as standard apply()
        expect(config.rules.length, equals(14));

        // Should NOT have the strict user_id rule
        final userIdRule = config.rules.where(
          (rule) => rule.hasProperty == 'user_id',
        );
        expect(userIdRule, isEmpty);
      });

      test('should apply CCPA rules for California region', () {
        GDPRDefaults.applyForRegion(builder, GDPRRegion.california);

        final config = builder.build();

        // Should have fewer rules like CCPA
        expect(config.rules.length, equals(3));
      });

      test('should apply minimal rules for global region', () {
        GDPRDefaults.applyForRegion(builder, GDPRRegion.global);

        final config = builder.build();

        // Should have minimal rules
        expect(config.rules.length, equals(5));
      });

      test('should work with compliant trackers for different regions', () {
        final compliantTrackers = ['region_tracker'];

        for (final region in GDPRRegion.values) {
          final testBuilder = RoutingBuilder();
          GDPRDefaults.applyForRegion(testBuilder, region,
              compliantTrackers: compliantTrackers);

          final config = testBuilder.build();

          // Should define compliant group for all regions except minimal cases
          if (region != GDPRRegion.california || config.rules.length > 3) {
            expect(config.customGroups.containsKey('gdpr_compliant'), isTrue);
          }
        }
      });
    });

    group('applyCCPA() - California Consumer Privacy Act', () {
      test('should apply CCPA routing rules', () {
        GDPRDefaults.applyCCPA(builder);

        final config = builder.build();

        // Should have minimal rules for CCPA
        expect(config.rules.length, equals(3));
      });

      test('should require consent for PII events under CCPA', () {
        final compliantTrackers = ['ccpa_tracker'];
        GDPRDefaults.applyCCPA(builder, compliantTrackers: compliantTrackers);

        final config = builder.build();
        final piiRule = config.rules.firstWhere(
          (rule) => rule.containsPII == true,
        );

        expect(piiRule.targetGroup.name,
            equals(compliantTrackers.isNotEmpty ? 'gdpr_compliant' : 'all'));
        expect(piiRule.requireConsent, isTrue);
        expect(piiRule.requirePIIConsent, isFalse); // CCPA is less strict
        expect(piiRule.priority, equals(15));
        expect(piiRule.description, contains('PII events - CCPA compliance'));
      });

      test('should require consent for marketing events under CCPA', () {
        GDPRDefaults.applyCCPA(builder);

        final config = builder.build();
        final marketingRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.marketing,
        );

        expect(marketingRule.requireConsent, isTrue);
        expect(marketingRule.priority, equals(12));
        expect(marketingRule.description,
            contains('Marketing events - CCPA compliance'));
      });

      test('should have CCPA-compliant default rule', () {
        GDPRDefaults.applyCCPA(builder);

        final config = builder.build();
        final defaultRule = config.rules.firstWhere(
          (rule) => rule.isDefault == true,
        );

        expect(defaultRule.priority, equals(0));
        expect(defaultRule.description,
            contains('Default CCPA-compliant routing'));
      });
    });

    group('Edge Cases and Validation', () {
      test('should handle empty compliant trackers list', () {
        GDPRDefaults.apply(builder, compliantTrackers: []);

        final config = builder.build();

        // Should not define compliant group with empty list
        expect(config.customGroups.containsKey('gdpr_compliant'), isFalse);
      });

      test('should create valid routing configurations for all methods', () {
        final methods = [
          () => GDPRDefaults.apply(builder),
          () => GDPRDefaults.applyStrict(builder),
          () => GDPRDefaults.applyMinimal(builder),
          () => GDPRDefaults.applyCCPA(builder),
        ];

        for (final method in methods) {
          final testBuilder = RoutingBuilder();
          method();

          final config = testBuilder.build();
          final validationIssues = config.validate();

          expect(validationIssues, isEmpty,
              reason: 'GDPR method should create valid configuration');
        }
      });

      test('should work with FlexTrack integration', () async {
        final mockTracker = MockTracker(id: 'gdpr_test', name: 'GDPR Test');

        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          GDPRDefaults.apply(builder, compliantTrackers: ['gdpr_test']);
          return builder;
        });

        expect(FlexTrack.isSetUp, isTrue);
        await FlexTrack.reset();
      });

      test('should handle all GDPRRegion enum values', () {
        for (final region in GDPRRegion.values) {
          final testBuilder = RoutingBuilder();

          expect(() => GDPRDefaults.applyForRegion(testBuilder, region),
              isA<void>());

          final config = testBuilder.build();
          expect(config.rules, isNotEmpty);
        }
      });
    });

    group('Priority and Rule Ordering', () {
      test('should have correct priority ordering in standard GDPR', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();
        final priorities = config.rules.map((r) => r.priority).toList();

        // Security should be highest (25)
        expect(priorities.contains(25), isTrue);
        // Essential should be second highest (24)
        expect(priorities.contains(24), isTrue);
        // User ID (in strict) should not be present
        expect(priorities.contains(22), isFalse);
        // Default should be lowest (0)
        expect(priorities.contains(0), isTrue);
      });

      test('should have correct priority ordering in strict GDPR', () {
        GDPRDefaults.applyStrict(builder);

        final config = builder.build();
        final priorities = config.rules.map((r) => r.priority).toList();

        // Should include strict priorities
        expect(priorities.contains(25), isTrue); // Security
        expect(priorities.contains(22), isTrue); // User ID (strict)
        expect(priorities.contains(14), isTrue); // Behavioral (strict)
        expect(priorities.contains(0), isTrue); // Default
      });

      test('should maintain rule precedence', () {
        GDPRDefaults.apply(builder);

        final config = builder.build();

        // Rules should be sorted by priority (descending)
        for (int i = 0; i < config.rules.length - 1; i++) {
          expect(config.rules[i].priority,
              greaterThanOrEqualTo(config.rules[i + 1].priority));
        }
      });
    });
  });

  group('GDPRRegion Enum Tests', () {
    test('should have all expected enum values', () {
      final values = GDPRRegion.values;

      expect(values, hasLength(4));
      expect(values, contains(GDPRRegion.eu));
      expect(values, contains(GDPRRegion.uk));
      expect(values, contains(GDPRRegion.california));
      expect(values, contains(GDPRRegion.global));
    });

    test('should have correct enum names', () {
      expect(GDPRRegion.eu.name, equals('eu'));
      expect(GDPRRegion.uk.name, equals('uk'));
      expect(GDPRRegion.california.name, equals('california'));
      expect(GDPRRegion.global.name, equals('global'));
    });

    test('should be usable in switch statements', () {
      for (final region in GDPRRegion.values) {
        String result;
        switch (region) {
          case GDPRRegion.eu:
            result = 'European Union';
            break;
          case GDPRRegion.uk:
            result = 'United Kingdom';
            break;
          case GDPRRegion.california:
            result = 'California';
            break;
          case GDPRRegion.global:
            result = 'Global';
            break;
        }

        expect(result, isNotNull);
        expect(result, isNotEmpty);
      }
    });
  });
}
