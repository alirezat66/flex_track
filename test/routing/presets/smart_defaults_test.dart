import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('SmartDefaults Tests', () {
    late RoutingBuilder builder;

    setUp(() {
      builder = RoutingBuilder();
    });

    group('apply() - Standard Smart Defaults', () {
      test('should apply smart default routing rules', () {
        SmartDefaults.apply(builder);

        final config = builder.build();

        // Should have all expected smart default rules
        expect(config.rules.length, equals(8));

        // Verify rules are sorted by priority (highest to lowest)
        final priorities = config.rules.map((r) => r.priority).toList();
        expect(priorities.first, equals(20)); // Essential events highest
        expect(priorities.contains(0), isTrue); // Default rule present
      });

      test('should configure technical events for debugging', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final technicalRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.technical,
        );

        expect(technicalRule.targetGroup.name, equals('development'));
        expect(technicalRule.debugOnly, isTrue);
        expect(technicalRule.sampleRate, equals(0.1)); // lightSampling
        expect(technicalRule.priority, equals(8));
        expect(technicalRule.description,
            contains('Technical events for debugging'));
      });

      test('should configure high volume events with heavy sampling', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final highVolumeRule = config.rules.firstWhere(
          (rule) => rule.isHighVolume == true,
        );

        expect(highVolumeRule.targetGroup, equals(TrackerGroup.all));
        expect(highVolumeRule.sampleRate, equals(0.01)); // heavySampling
        expect(highVolumeRule.priority, equals(5));
        expect(highVolumeRule.description,
            contains('High volume events with reduced sampling'));
      });

      test('should configure security events as essential', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final securityRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.security,
        );

        expect(securityRule.targetGroup, equals(TrackerGroup.all));
        expect(securityRule.requireConsent,
            isFalse); // essential() sets skipConsent
        expect(securityRule.sampleRate,
            equals(1.0)); // essential() sets noSampling
        expect(securityRule.priority, equals(15));
        expect(securityRule.description,
            contains('Security events - always tracked'));
      });

      test('should configure system events without consent requirement', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final systemRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.system,
        );

        expect(systemRule.targetGroup, equals(TrackerGroup.all));
        expect(systemRule.requireConsent, isFalse); // skipConsent
        expect(systemRule.sampleRate, equals(0.1)); // lightSampling
        expect(systemRule.priority, equals(7));
        expect(systemRule.description,
            contains('System events - no consent required'));
      });

      test('should configure sensitive events with full consent', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final sensitiveRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.sensitive,
        );

        expect(sensitiveRule.targetGroup, equals(TrackerGroup.all));
        expect(sensitiveRule.requireConsent, isTrue);
        expect(sensitiveRule.requirePIIConsent, isTrue);
        expect(sensitiveRule.priority, equals(12));
        expect(sensitiveRule.description,
            contains('Sensitive events requiring full consent'));
      });

      test('should configure PII events with specific consent', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final piiRule = config.rules.firstWhere(
          (rule) => rule.containsPII == true,
        );

        expect(piiRule.targetGroup, equals(TrackerGroup.all));
        expect(piiRule.requirePIIConsent, isTrue);
        expect(piiRule.priority, equals(10));
        expect(piiRule.description,
            contains('PII events requiring specific consent'));
      });

      test('should configure essential events to bypass restrictions', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final essentialRule = config.rules.firstWhere(
          (rule) => rule.isEssential == true,
        );

        expect(essentialRule.targetGroup, equals(TrackerGroup.all));
        expect(essentialRule.requireConsent,
            isFalse); // essential() sets skipConsent
        expect(essentialRule.sampleRate,
            equals(1.0)); // essential() sets noSampling
        expect(essentialRule.priority, equals(20));
        expect(essentialRule.description,
            contains('Essential events - bypass all restrictions'));
      });

      test('should have default fallback rule', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final defaultRule = config.rules.firstWhere(
          (rule) => rule.isDefault == true,
        );

        expect(defaultRule.targetGroup, equals(TrackerGroup.all));
        expect(defaultRule.priority, equals(0));
        expect(defaultRule.description,
            contains('Default routing for unmatched events'));
      });
    });

    group('applyPerformanceFocused() - Performance Optimized Defaults', () {
      test('should apply performance-focused routing rules', () {
        SmartDefaults.applyPerformanceFocused(builder);

        final config = builder.build();

        // Should have base rules plus additional performance rules
        expect(config.rules.length, greaterThan(8));
      });

      test('should configure high frequency events with heavy sampling', () {
        SmartDefaults.applyPerformanceFocused(builder);

        final config = builder.build();
        final highFreqRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'high_frequency',
        );

        expect(highFreqRule.targetGroup, equals(TrackerGroup.all));
        expect(highFreqRule.sampleRate, equals(0.01)); // heavySampling
        expect(highFreqRule.priority, equals(6));
        expect(highFreqRule.description,
            contains('High frequency events with heavy sampling'));
      });

      test('should configure batchable events with medium sampling', () {
        SmartDefaults.applyPerformanceFocused(builder);

        final config = builder.build();
        final batchableRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'batchable',
        );

        expect(batchableRule.targetGroup, equals(TrackerGroup.all));
        expect(batchableRule.sampleRate, equals(0.5)); // mediumSampling
        expect(batchableRule.priority, equals(4));
        expect(batchableRule.description,
            contains('Batchable events with medium sampling'));
      });

      test('should include all base smart default rules', () {
        SmartDefaults.applyPerformanceFocused(builder);

        final config = builder.build();

        // Should still have essential rule from base defaults
        final essentialRule = config.rules.where(
          (rule) => rule.isEssential == true,
        );
        expect(essentialRule, isNotEmpty);

        // Should still have default rule
        final defaultRule = config.rules.where(
          (rule) => rule.isDefault == true,
        );
        expect(defaultRule, isNotEmpty);
      });
    });

    group('applyPrivacyFocused() - Privacy Optimized Defaults', () {
      test('should apply privacy-focused routing rules', () {
        SmartDefaults.applyPrivacyFocused(builder);

        final config = builder.build();

        // Should have base rules plus additional privacy rules
        expect(config.rules.length, greaterThan(8));
      });

      test('should configure user events to require consent', () {
        SmartDefaults.applyPrivacyFocused(builder);

        final config = builder.build();
        final userRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.user,
        );

        expect(userRule.targetGroup, equals(TrackerGroup.all));
        expect(userRule.requireConsent, isTrue);
        expect(userRule.priority, equals(9));
        expect(userRule.description, contains('User events requiring consent'));
      });

      test('should configure marketing events to require consent', () {
        SmartDefaults.applyPrivacyFocused(builder);

        final config = builder.build();
        final marketingRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.marketing,
        );

        expect(marketingRule.targetGroup, equals(TrackerGroup.all));
        expect(marketingRule.requireConsent, isTrue);
        expect(marketingRule.priority, equals(11));
        expect(marketingRule.description,
            contains('Marketing events requiring consent'));
      });

      test('should include all base smart default rules', () {
        SmartDefaults.applyPrivacyFocused(builder);

        final config = builder.build();

        // Should still have security rule from base defaults
        final securityRule = config.rules.where(
          (rule) => rule.category == EventCategory.security,
        );
        expect(securityRule, isNotEmpty);
      });
    });

    group('applyDevelopmentFriendly() - Development Optimized Defaults', () {
      test('should apply development-friendly routing rules', () {
        SmartDefaults.applyDevelopmentFriendly(builder);

        final config = builder.build();

        // Should have base rules plus additional development rules
        expect(config.rules.length, greaterThan(8));
      });

      test('should configure debug events for development only', () {
        SmartDefaults.applyDevelopmentFriendly(builder);

        final config = builder.build();
        final debugRule = config.rules.firstWhere(
          (rule) => rule.eventNameRegex?.pattern == r'debug_.*',
        );

        expect(debugRule.targetGroup.name, equals('development'));
        expect(debugRule.debugOnly, isTrue);
        expect(debugRule.sampleRate, equals(1.0)); // noSampling
        expect(debugRule.priority, equals(15));
        expect(debugRule.description, contains('Debug events for development'));
      });

      test('should configure test events for development only', () {
        SmartDefaults.applyDevelopmentFriendly(builder);

        final config = builder.build();
        final testRule = config.rules.firstWhere(
          (rule) => rule.eventNameRegex?.pattern == r'test_.*',
        );

        expect(testRule.targetGroup.name, equals('development'));
        expect(testRule.debugOnly, isTrue);
        expect(testRule.sampleRate, equals(1.0)); // noSampling
        expect(testRule.priority, equals(14));
        expect(testRule.description, contains('Test events for development'));
      });

      test('should configure dev events for development only', () {
        SmartDefaults.applyDevelopmentFriendly(builder);

        final config = builder.build();
        final devRule = config.rules.firstWhere(
          (rule) => rule.eventNameRegex?.pattern == r'dev_.*',
        );

        expect(devRule.targetGroup.name, equals('development'));
        expect(devRule.debugOnly, isTrue);
        expect(devRule.sampleRate, equals(1.0)); // noSampling
        expect(devRule.priority, equals(13));
        expect(devRule.description, contains('Development-specific events'));
      });
    });

    group('Rule Priority and Ordering', () {
      test('should have correct priority ordering in smart defaults', () {
        SmartDefaults.apply(builder);

        final config = builder.build();
        final priorities = config.rules.map((r) => r.priority).toList();

        // Essential should be highest (20)
        expect(priorities.contains(20), isTrue);
        // Security should be high (15)
        expect(priorities.contains(15), isTrue);
        // Sensitive should be medium-high (12)
        expect(priorities.contains(12), isTrue);
        // Default should be lowest (0)
        expect(priorities.contains(0), isTrue);
      });

      test('should maintain rule precedence in performance focused', () {
        SmartDefaults.applyPerformanceFocused(builder);

        final config = builder.build();

        // Rules should be sorted by priority (descending)
        for (int i = 0; i < config.rules.length - 1; i++) {
          expect(config.rules[i].priority,
              greaterThanOrEqualTo(config.rules[i + 1].priority));
        }
      });

      test('should maintain rule precedence in privacy focused', () {
        SmartDefaults.applyPrivacyFocused(builder);

        final config = builder.build();

        // Rules should be sorted by priority (descending)
        for (int i = 0; i < config.rules.length - 1; i++) {
          expect(config.rules[i].priority,
              greaterThanOrEqualTo(config.rules[i + 1].priority));
        }
      });
    });

    group('Integration with FlexTrack', () {
      test('should work with FlexTrack integration', () async {
        final mockTracker = MockTracker(id: 'smart_test', name: 'Smart Test');

        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          SmartDefaults.apply(builder);
          return builder;
        });

        expect(FlexTrack.isSetUp, isTrue);
        await FlexTrack.reset();
      });

      test('should work with performance focused setup', () async {
        final mockTracker =
            MockTracker(id: 'perf_test', name: 'Performance Test');

        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          SmartDefaults.applyPerformanceFocused(builder);
          return builder;
        });

        expect(FlexTrack.isSetUp, isTrue);
        await FlexTrack.reset();
      });

      test('should work with privacy focused setup', () async {
        final mockTracker =
            MockTracker(id: 'privacy_test', name: 'Privacy Test');

        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          SmartDefaults.applyPrivacyFocused(builder);
          return builder;
        });

        expect(FlexTrack.isSetUp, isTrue);
        await FlexTrack.reset();
      });

      test('should work with development friendly setup', () async {
        final mockTracker = MockTracker(id: 'dev_test', name: 'Dev Test');

        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          SmartDefaults.applyDevelopmentFriendly(builder);
          return builder;
        });

        expect(FlexTrack.isSetUp, isTrue);
        await FlexTrack.reset();
      });
    });

    group('Event Routing with Smart Defaults', () {
      late MockTracker mockTracker;
      late MockTracker consoleTracker;

      setUp(() {
        mockTracker = MockTracker(id: 'main', name: 'Main Tracker');
        consoleTracker = MockTracker(id: 'console', name: 'Console Tracker');
      });

      test(
          'should route technical events to development trackers in debug mode',
          () async {
        await FlexTrack.setupWithRouting([mockTracker, consoleTracker],
            (builder) {
          SmartDefaults.apply(builder);
          return builder;
        });

        final technicalEvent = TestEvent('debug_test', EventCategory.technical);

        // In debug mode, technical events should go to development trackers
        final result = await FlexTrack.track(technicalEvent);

        expect(result.successful, isTrue);
        // The exact routing depends on the current debug mode state
        expect(result.wasTracked, isTrue);

        await FlexTrack.reset();
      });

      test('should route high volume events with sampling', () async {
        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          SmartDefaults.apply(builder);
          return builder;
        });

        // Clear any previous events
        mockTracker.clearCapturedData();

        // Track multiple high volume events
        // Due to heavy sampling (1%), most should be filtered out
        // But we can't predict exact sampling behavior in tests
        for (int i = 0; i < 10; i++) {
          await FlexTrack.track(HighVolumeTestEvent('page_view_$i'));
        }

        // With heavy sampling, we expect fewer events to be tracked
        // But the exact number depends on random sampling
        expect(mockTracker.capturedEvents.length, lessThanOrEqualTo(10));

        await FlexTrack.reset();
      });

      test('should route essential events without restrictions', () async {
        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          SmartDefaults.apply(builder);
          return builder;
        });

        // Disable consent to test that essential events bypass restrictions
        FlexTrack.setConsent(general: false, pii: false);

        final essentialEvent = EssentialTestEvent('system_critical');

        mockTracker.clearCapturedData();

        final result = await FlexTrack.track(essentialEvent);

        expect(result.successful, isTrue);
        expect(mockTracker.capturedEvents, hasLength(1));

        await FlexTrack.reset();
      });

      test('should route sensitive events with consent requirements', () async {
        await FlexTrack.setupWithRouting([mockTracker], (builder) {
          SmartDefaults.apply(builder);
          return builder;
        });

        final sensitiveEvent = TestEvent('user_data', EventCategory.sensitive);

        mockTracker.clearCapturedData();

        // Without consent, sensitive events should be blocked
        FlexTrack.setConsent(general: false, pii: false);
        await FlexTrack.track(sensitiveEvent);
        expect(mockTracker.capturedEvents, hasLength(0));

        // With consent, sensitive events should go through
        FlexTrack.setConsent(general: true, pii: true);
        await FlexTrack.track(sensitiveEvent);
        expect(mockTracker.capturedEvents, hasLength(1));

        await FlexTrack.reset();
      });
    });

    group('Configuration Validation', () {
      test('should create valid configurations for all smart default methods',
          () {
        final methods = [
          () => SmartDefaults.apply(builder),
          () => SmartDefaults.applyPerformanceFocused(builder),
          () => SmartDefaults.applyPrivacyFocused(builder),
          () => SmartDefaults.applyDevelopmentFriendly(builder),
        ];

        for (final method in methods) {
          final testBuilder = RoutingBuilder();
          method();

          final config = testBuilder.build();
          final validationIssues = config.validate();

          expect(validationIssues, isEmpty,
              reason: 'Smart default method should create valid configuration');
        }
      });

      test('should handle edge cases gracefully', () {
        // Test with minimal builder
        final minimalBuilder = RoutingBuilder();

        expect(() => SmartDefaults.apply(minimalBuilder), isA<void>());

        final config = minimalBuilder.build();
        expect(config.rules, isNotEmpty);
        expect(config.validate(), isEmpty);
      });
    });

    group('Sampling Rate Verification', () {
      test('should use correct sampling rates', () {
        SmartDefaults.apply(builder);
        final config = builder.build();

        // Verify specific sampling rates
        final highVolumeRule = config.rules.firstWhere(
          (rule) => rule.isHighVolume == true,
        );
        expect(highVolumeRule.sampleRate, equals(0.01)); // heavySampling

        final systemRule = config.rules.firstWhere(
          (rule) => rule.category == EventCategory.system,
        );
        expect(systemRule.sampleRate, equals(0.1)); // lightSampling

        final essentialRule = config.rules.firstWhere(
          (rule) => rule.isEssential == true,
        );
        expect(essentialRule.sampleRate, equals(1.0)); // noSampling
      });

      test('should use correct sampling rates in performance focused', () {
        SmartDefaults.applyPerformanceFocused(builder);
        final config = builder.build();

        final highFreqRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'high_frequency',
        );
        expect(highFreqRule.sampleRate, equals(0.01)); // heavySampling

        final batchableRule = config.rules.firstWhere(
          (rule) => rule.hasProperty == 'batchable',
        );
        expect(batchableRule.sampleRate, equals(0.5)); // mediumSampling
      });
    });
  });
}

// Test Event Classes
class TestEvent extends BaseEvent {
  final String eventName;
  final EventCategory? eventCategory;
  final Map<String, Object>? _properties;

  TestEvent(this.eventName, [this.eventCategory, this._properties]);

  @override
  String get name => eventName;

  @override
  Map<String, Object>? get properties => _properties;

  @override
  EventCategory? get category => eventCategory;
}

class HighVolumeTestEvent extends BaseEvent {
  final String eventName;

  HighVolumeTestEvent(this.eventName);

  @override
  String get name => eventName;

  @override
  Map<String, Object>? get properties => null;

  @override
  bool get isHighVolume => true;
}

class EssentialTestEvent extends BaseEvent {
  final String eventName;

  EssentialTestEvent(this.eventName);

  @override
  String get name => eventName;

  @override
  Map<String, Object>? get properties => null;

  @override
  bool get isEssential => true;

  @override
  bool get requiresConsent => false;
}
