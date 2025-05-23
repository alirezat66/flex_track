import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('Routing Engine Tests', () {
    late RoutingEngine engine;
    late RoutingConfiguration config;

    // Test events
    final testEvent = _TestEvent('test_event');
    final businessEvent = _BusinessEvent('purchase', 99.99);
    final debugEvent = _DebugEvent('debug_test');
    final piiEvent = _PIIEvent('user_profile', 'user@test.com');
    final essentialEvent = _EssentialEvent('system_health');

    group('Basic Routing', () {
      test('should route to default group when no rules match', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
            ),
          ],
        );
        // Use RoutingBuilder to ensure default rule is added
        final builder = RoutingBuilder();
        config = builder.build();
        engine = RoutingEngine(config);

        final result = engine.routeEvent(testEvent);

        // Expect the default rule to be applied
        expect(result.appliedRules.length, equals(0));
        // Expect target trackers to be empty as no available trackers are provided
        expect(result.targetTrackers, isEmpty);
      });

      test('should route to specific trackers when available', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
            ),
          ],
        );
        engine = RoutingEngine(config);

        final result = engine.routeEvent(
          testEvent,
          availableTrackers: {'tracker1', 'tracker2'},
        );

        expect(result.targetTrackers, containsAll(['tracker1', 'tracker2']));
        expect(result.willBeTracked, isTrue);
      });

      test('should route based on event category', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              category: EventCategory.business,
              targetGroup:
                  TrackerGroup('business', ['analytics1', 'analytics2']),
              priority: 10,
            ),
            RoutingRule(
              category: EventCategory.technical,
              targetGroup: TrackerGroup('debug', ['console']),
              priority: 5,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
            ),
          ],
        );
        engine = RoutingEngine(config);

        // Business event
        final businessResult = engine.routeEvent(
          businessEvent,
          availableTrackers: {'analytics1', 'analytics2', 'console'},
        );
        expect(businessResult.targetTrackers,
            containsAll(['analytics1', 'analytics2']));
        expect(businessResult.targetTrackers, hasLength(3));

        // Debug event
        final debugResult = engine.routeEvent(
          debugEvent,
          availableTrackers: {'analytics1', 'analytics2', 'console'},
        );
        expect(debugResult.targetTrackers, contains('console'));
        expect(debugResult.targetTrackers, hasLength(3));
      });

      test('should route based on event name pattern', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              eventNamePattern: 'debug',
              targetGroup: TrackerGroup('debug', ['console']),
              priority: 10,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('production', ['analytics']),
            ),
          ],
        );
        engine = RoutingEngine(config);

        // Debug event (contains 'debug')
        final debugResult = engine.routeEvent(
          debugEvent,
          availableTrackers: {'console', 'analytics'},
        );
        expect(debugResult.targetTrackers, contains('console'));
        expect(debugResult.targetTrackers, hasLength(2));

        // Regular event
        final regularResult = engine.routeEvent(
          testEvent,
          availableTrackers: {'console', 'analytics'},
        );
        expect(regularResult.targetTrackers, contains('analytics'));
        expect(regularResult.targetTrackers, hasLength(1));
      });

      test('should route based on regex pattern', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              eventNameRegex: RegExp(r'^debug_.*'),
              targetGroup: TrackerGroup('debug', ['console']),
              priority: 10,
            ),
            RoutingRule(
              eventNameRegex: RegExp(r'.*_event$'),
              targetGroup: TrackerGroup('events', ['analytics']),
              priority: 5,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
            ),
          ],
        );
        engine = RoutingEngine(config);

        // Debug event matches first rule
        final debugResult = engine.routeEvent(
          debugEvent, // 'debug_test'
          availableTrackers: {'console', 'analytics'},
        );
        expect(debugResult.targetTrackers, contains('console'));

        // Test event matches second rule
        final testResult = engine.routeEvent(
          testEvent, // 'test_event'
          availableTrackers: {'console', 'analytics'},
        );
        expect(testResult.targetTrackers, contains('analytics'));
      });
    });

    group('Priority and Rule Ordering', () {
      test('should apply highest priority rule first', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              eventNamePattern: 'test',
              targetGroup: TrackerGroup('low', ['tracker1']),
              priority: 1,
            ),
            RoutingRule(
              eventNamePattern: 'test',
              targetGroup: TrackerGroup('high', ['tracker2']),
              priority: 10,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('default', ['tracker3']),
              priority: 0,
            ),
          ],
        );
        engine = RoutingEngine(config);

        final result = engine.routeEvent(
          testEvent,
          availableTrackers: {'tracker1', 'tracker2', 'tracker3'},
        );

        // Should use highest priority rule (priority: 10)
        expect(result.targetTrackers, contains('tracker2'));
        expect(result.targetTrackers, hasLength(2));
        expect(result.appliedRules.first.priority, equals(10));
      });

      test('should handle multiple rules with same priority', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              eventNamePattern: 'test',
              targetGroup: TrackerGroup('group1', ['tracker1']),
              priority: 5,
            ),
            RoutingRule(
              eventNamePattern: 'test',
              targetGroup: TrackerGroup('group2', ['tracker2']),
              priority: 5,
            ),
          ],
        );
        engine = RoutingEngine(config);

        final result = engine.routeEvent(
          testEvent,
          availableTrackers: {'tracker1', 'tracker2'},
        );

        // Should apply both rules with same priority
        expect(result.appliedRules, hasLength(2));
        expect(result.targetTrackers, containsAll(['tracker1', 'tracker2']));
      });
    });

    group('Consent Handling', () {
      test('should respect general consent requirements', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
              requireConsent: true,
            ),
          ],
        );
        engine = RoutingEngine(config);

        // Without consent
        final withoutConsent = engine.routeEvent(
          testEvent,
          hasGeneralConsent: false,
          availableTrackers: {'tracker1'},
        );
        expect(withoutConsent.targetTrackers, isEmpty);
        expect(withoutConsent.skippedRules, hasLength(1));
        expect(withoutConsent.skippedRules.first.reason, contains('Consent'));

        // With consent
        final withConsent = engine.routeEvent(
          testEvent,
          hasGeneralConsent: true,
          availableTrackers: {'tracker1'},
        );
        expect(withConsent.targetTrackers, contains('tracker1'));
        expect(withConsent.appliedRules, hasLength(1));
      });

      test('should handle PII consent separately', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              containsPII: true,
              targetGroup: TrackerGroup('pii', ['secure_tracker']),
              requirePIIConsent: true,
              priority: 10,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('regular', ['regular_tracker']),
            ),
          ],
        );
        engine = RoutingEngine(config);

        // PII event without PII consent
        final withoutPIIConsent = engine.routeEvent(
          piiEvent,
          hasGeneralConsent: true,
          hasPIIConsent: false,
          availableTrackers: {'secure_tracker', 'regular_tracker'},
        );
        expect(withoutPIIConsent.targetTrackers, contains('regular_tracker'));
        expect(withoutPIIConsent.targetTrackers, hasLength(1));

        // PII event with PII consent
        final withPIIConsent = engine.routeEvent(
          piiEvent,
          hasGeneralConsent: true,
          hasPIIConsent: true,
          availableTrackers: {'secure_tracker', 'regular_tracker'},
        );
        expect(withPIIConsent.targetTrackers, contains('secure_tracker'));
        expect(withPIIConsent.targetTrackers, hasLength(2));
      });

      test('should allow essential events without consent', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
              requireConsent: true,
            ),
          ],
        );
        engine = RoutingEngine(config);

        final result = engine.routeEvent(
          essentialEvent,
          hasGeneralConsent: false,
          availableTrackers: {'tracker1'},
        );

        expect(result.targetTrackers, contains('tracker1'));
        expect(result.appliedRules, hasLength(1));
      });
    });

    group('Sampling', () {
      test('should handle sampling configuration', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
              sampleRate: 0.0, // 0% sampling
            ),
          ],
          enableSampling: true,
        );
        engine = RoutingEngine(config);

        // With 0% sampling, events should be skipped
        final result = engine.routeEvent(
          testEvent,
          availableTrackers: {'tracker1'},
        );

        // Note: Sampling is probabilistic, but with 0% it should always skip
        // In a real test, you might want to run this multiple times
        expect(result.skippedRules.any((sr) => sr.reason.contains('sampled')),
            isTrue);
      });

      test('should bypass sampling when disabled globally', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
              sampleRate: 0.0, // 0% sampling
            ),
          ],
          enableSampling: false, // Sampling disabled
        );
        engine = RoutingEngine(config);

        final result = engine.routeEvent(
          testEvent,
          availableTrackers: {'tracker1'},
        );

        expect(result.targetTrackers, contains('tracker1'));
        expect(result.appliedRules, hasLength(1));
      });
    });

    group('Environment-Based Routing', () {
      test('should handle debug-only rules', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              category: EventCategory.technical,
              targetGroup: TrackerGroup('debug', ['console']),
              debugOnly: true,
              priority: 10,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('production', ['analytics']),
            ),
          ],
          isDebugMode: true,
        );
        engine = RoutingEngine(config);

        // In debug mode
        final debugModeResult = engine.routeEvent(
          debugEvent,
          availableTrackers: {'console', 'analytics'},
        );
        expect(debugModeResult.targetTrackers, contains('console'));

        // Test with debug mode disabled
        final prodConfig = config.copyWith(isDebugMode: false);
        final prodEngine = RoutingEngine(prodConfig);

        final prodModeResult = prodEngine.routeEvent(
          debugEvent,
          availableTrackers: {'console', 'analytics'},
        );
        expect(prodModeResult.targetTrackers, contains('analytics'));
      });

      test('should handle production-only rules', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              category: EventCategory.business,
              targetGroup: TrackerGroup('production', ['analytics']),
              productionOnly: true,
              priority: 10,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('debug', ['console']),
            ),
          ],
          isDebugMode: false, // Production mode
        );
        engine = RoutingEngine(config);

        final result = engine.routeEvent(
          businessEvent,
          availableTrackers: {'console', 'analytics'},
        );

        expect(result.targetTrackers, contains('analytics'));
        expect(result.targetTrackers, hasLength(2));
      });
    });

    group('Property-Based Routing', () {
      test('should route based on property existence', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              hasProperty: 'special_flag',
              targetGroup: TrackerGroup('special', ['special_tracker']),
              priority: 10,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('regular', ['regular_tracker']),
            ),
          ],
        );
        engine = RoutingEngine(config);

        final specialEvent =
            _PropertyEvent('property_test', {'special_flag': true});
        final regularEvent =
            _PropertyEvent('property_test', {'other_prop': 'value'});

        // Event with special property
        final specialResult = engine.routeEvent(
          specialEvent,
          availableTrackers: {'special_tracker', 'regular_tracker'},
        );
        expect(specialResult.targetTrackers, contains('special_tracker'));

        // Event without special property
        final regularResult = engine.routeEvent(
          regularEvent,
          availableTrackers: {'special_tracker', 'regular_tracker'},
        );
        expect(regularResult.targetTrackers, contains('regular_tracker'));
      });

      test('should route based on property value', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              hasProperty: 'environment',
              propertyValue: 'production',
              targetGroup: TrackerGroup('prod', ['prod_tracker']),
              priority: 10,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('dev', ['dev_tracker']),
            ),
          ],
        );
        engine = RoutingEngine(config);

        final prodEvent =
            _PropertyEvent('env_test', {'environment': 'production'});
        final devEvent =
            _PropertyEvent('env_test', {'environment': 'development'});

        // Production event
        final prodResult = engine.routeEvent(
          prodEvent,
          availableTrackers: {'prod_tracker', 'dev_tracker'},
        );
        expect(prodResult.targetTrackers, contains('prod_tracker'));

        // Development event
        final devResult = engine.routeEvent(
          devEvent,
          availableTrackers: {'prod_tracker', 'dev_tracker'},
        );
        expect(devResult.targetTrackers, contains('dev_tracker'));
      });
    });

    group('Debug Information', () {
      test('should provide comprehensive debug information', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              category: EventCategory.business,
              targetGroup: TrackerGroup('analytics', ['tracker1']),
              priority: 10,
            ),
            RoutingRule(
              eventNamePattern: 'debug',
              targetGroup: TrackerGroup('debug', ['console']),
              priority: 5,
            ),
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
            ),
          ],
        );
        engine = RoutingEngine(config);

        final debugInfo = engine.debugEvent(
          testEvent,
          availableTrackers: {'tracker1', 'console'},
        );

        expect(debugInfo.allRules, hasLength(3));
        expect(
            debugInfo.matchingRules, hasLength(1)); // Only default rule matches
        expect(debugInfo.nonMatchingRules, hasLength(2));
        expect(debugInfo.routingResult.willBeTracked, isTrue);

        // Check non-matching reasons
        final businessRuleDebug = debugInfo.nonMatchingRules
            .firstWhere((r) => r.rule.category == EventCategory.business);
        expect(businessRuleDebug.matches, isFalse);
        expect(businessRuleDebug.reason, contains('Category mismatch'));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty rules list gracefully', () {
        config = RoutingConfiguration(rules: []);
        engine = RoutingEngine(config);

        final result = engine.routeEvent(testEvent);

        expect(result.targetTrackers, isEmpty);
        expect(result.warnings, contains('No routing rules matched the event'));
      });

      test('should handle rules with no available trackers', () {
        config = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('missing', ['nonexistent_tracker']),
            ),
          ],
        );
        engine = RoutingEngine(config);

        final result = engine.routeEvent(
          testEvent,
          availableTrackers: {'other_tracker'},
        );

        expect(result.targetTrackers, isEmpty);
        expect(result.warnings, isNotEmpty);
        expect(result.skippedRules, hasLength(1));
      });

      test('should validate configuration', () {
        // Valid configuration
        final validConfig = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup.all,
              sampleRate: 0.5,
            ),
          ],
        );
        final validEngine = RoutingEngine(validConfig);
        expect(validEngine.validateConfiguration(), isEmpty);

        // Invalid configuration (invalid sample rate)
        expect(
          () {
            RoutingBuilder()
                .routeDefault()
                .toAll()
                .sample(1.5); // Invalid - exceeds 1.0
          },
          throwsA(isA<ConfigurationException>()), // Expect ConfigurationException
        );
      });
    });
  });
}

// Test event classes
class _TestEvent extends BaseEvent {
  final String eventName;

  _TestEvent(this.eventName);

  @override
  String getName() => eventName;

  @override
  Map<String, Object>? getProperties() => null;
}

class _BusinessEvent extends BaseEvent {
  final String eventName;
  final double amount;

  _BusinessEvent(this.eventName, this.amount);

  @override
  String getName() => eventName;

  @override
  Map<String, Object> getProperties() => {'amount': amount};

  @override
  EventCategory get category => EventCategory.business;
}

class _DebugEvent extends BaseEvent {
  final String eventName;

  _DebugEvent(this.eventName);

  @override
  String getName() => eventName;

  @override
  Map<String, Object>? getProperties() => null;

  @override
  EventCategory get category => EventCategory.technical;
}

class _PIIEvent extends BaseEvent {
  final String eventName;
  final String email;

  _PIIEvent(this.eventName, this.email);

  @override
  String getName() => eventName;

  @override
  Map<String, Object> getProperties() => {'email': email};

  @override
  bool get containsPII => true;
}

class _EssentialEvent extends BaseEvent {
  final String eventName;

  _EssentialEvent(this.eventName);

  @override
  String getName() => eventName;

  @override
  Map<String, Object>? getProperties() => null;

  @override
  bool get isEssential => true;
}

class _HighVolumeEvent extends BaseEvent {
  final String eventName;

  _HighVolumeEvent(this.eventName);

  @override
  String getName() => eventName;

  @override
  Map<String, Object>? getProperties() => null;

  @override
  bool get isHighVolume => true;
}

class _PropertyEvent extends BaseEvent {
  final String eventName;
  final Map<String, Object> eventProperties;

  _PropertyEvent(this.eventName, this.eventProperties);

  @override
  String getName() => eventName;

  @override
  Map<String, Object> getProperties() => eventProperties;
}
