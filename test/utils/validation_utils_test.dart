import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('ValidationUtils Tests', () {
    group('Tracker ID Validation', () {
      test('should accept valid tracker IDs', () {
        final validIds = [
          'tracker1',
          'analytics_service',
          'firebase-analytics',
          'mixpanel_2024',
          'a',
          '1234567890',
        ];

        for (final id in validIds) {
          final result = ValidationUtils.validateTrackerId(id);
          expect(result.isValid, isTrue, reason: 'ID "$id" should be valid');
        }
      });

      test('should reject invalid tracker IDs', () {
        final invalidIds = [
          null,
          '',
          'tracker with spaces',
          'tracker@invalid',
          'tracker.invalid',
          'tracker#invalid',
          'x' * 51, // Too long
          'all', // Reserved
          'system', // Reserved
        ];

        for (final id in invalidIds) {
          final result = ValidationUtils.validateTrackerId(id);
          expect(result.isValid, isFalse, reason: 'ID "$id" should be invalid');
        }
      });
    });

    group('Event Name Validation', () {
      test('should accept valid event names', () {
        final validNames = [
          'user_action',
          'page-view',
          'purchase',
          'app.start',
          'event123',
          'a',
        ];

        for (final name in validNames) {
          final result = ValidationUtils.validateEventName(name);
          expect(result.isValid, isTrue,
              reason: 'Name "$name" should be valid');
        }
      });

      test('should reject invalid event names', () {
        final invalidNames = [
          null,
          '',
          '123invalid', // Starts with number
          '-invalid', // Starts with hyphen
          'event with spaces',
          'event@invalid',
          'x' * 101, // Too long
        ];

        for (final name in invalidNames) {
          final result = ValidationUtils.validateEventName(name);
          expect(result.isValid, isFalse,
              reason: 'Name "$name" should be invalid');
        }
      });
    });

    group('Event Properties Validation', () {
      test('should accept valid properties', () {
        final validProperties = <Map<String, Object>>[
          {'key': 'value'},
          {'number': 42},
          {'boolean': true},
          {'date': DateTime.now()},
          {'mixed': 'value', 'count': 100, 'active': false},
          {}, // Empty is valid
        ];

        for (final props in validProperties) {
          final result = ValidationUtils.validateEventProperties(props);
          expect(result.isValid, isTrue,
              reason: 'Properties $props should be valid');
        }
      });

      test('should reject invalid properties', () {
        // Too many properties
        final tooManyProps = Map.fromEntries(
          List.generate(51, (i) => MapEntry('key$i', 'value$i')),
        );
        expect(ValidationUtils.validateEventProperties(tooManyProps).isValid,
            isFalse);

        // Invalid property key
        final invalidKey = <String, Object>{'invalid key': 'value'};
        expect(ValidationUtils.validateEventProperties(invalidKey).isValid,
            isFalse);

        // Invalid property value type
        final invalidValue = <String, Object>{
          'key': [1, 2, 3]
        };
        expect(ValidationUtils.validateEventProperties(invalidValue).isValid,
            isFalse);
      });

      test('should handle null properties', () {
        final result = ValidationUtils.validateEventProperties(null);
        expect(result.isValid, isTrue);
      });
    });

    group('Property Key Validation', () {
      test('should accept valid property keys', () {
        final validKeys = [
          'key',
          'eventCount',
          'a',
          'key123',
          'custom_property'
        ];

        for (final key in validKeys) {
          final result = ValidationUtils.validatePropertyKey(key);
          expect(result.isValid, isTrue, reason: 'Key "$key" should be valid');
        }
      });

      test('should reject invalid property keys', () {
        final invalidKeys = [
          '',
          'key with spaces',
          'key-with-hyphens',
          'key.with.dots',
          'x' * 31, // Too long
          'timestamp', // Reserved
          'user_id', // Reserved
        ];

        for (final key in invalidKeys) {
          final result = ValidationUtils.validatePropertyKey(key);
          expect(result.isValid, isFalse,
              reason: 'Key "$key" should be invalid');
        }
      });
    });

    group('Property Value Validation', () {
      test('should accept valid property values', () {
        final validValues = <Object>[
          'string',
          42,
          3.14,
          true,
          false,
          DateTime.now(),
        ];

        for (final value in validValues) {
          final result = ValidationUtils.validatePropertyValue(value);
          expect(result.isValid, isTrue,
              reason: 'Value "$value" should be valid');
        }
      });

      test('should reject invalid property values', () {
        final invalidValues = <Object>[
          [1, 2, 3], // List
          {'nested': 'object'}, // Map
          'x' * 1001, // String too long
          double.nan, // NaN
          double.infinity, // Infinity
        ];

        for (final value in invalidValues) {
          final result = ValidationUtils.validatePropertyValue(value);
          expect(result.isValid, isFalse,
              reason: 'Value "$value" should be invalid');
        }
      });
    });

    group('User ID Validation', () {
      test('should accept valid user IDs', () {
        final validIds = [
          null, // Optional
          '', // Optional
          'user123',
          'user@example.com',
          'very-long-user-id-that-is-still-valid',
        ];

        for (final id in validIds) {
          final result = ValidationUtils.validateUserId(id);
          expect(result.isValid, isTrue,
              reason: 'User ID "$id" should be valid');
        }
      });

      test('should reject invalid user IDs', () {
        final invalidIds = [
          'x' * 101, // Too long
          'user\nwith\nnewlines',
          'user\twith\ttabs',
        ];

        for (final id in invalidIds) {
          final result = ValidationUtils.validateUserId(id);
          expect(result.isValid, isFalse,
              reason: 'User ID "$id" should be invalid');
        }
      });
    });

    group('Session ID Validation', () {
      test('should accept valid session IDs', () {
        final validIds = [
          null, // Optional
          '', // Optional
          'session123',
          'session-abc-def',
          'session_123_abc',
        ];

        for (final id in validIds) {
          final result = ValidationUtils.validateSessionId(id);
          expect(result.isValid, isTrue,
              reason: 'Session ID "$id" should be valid');
        }
      });

      test('should reject invalid session IDs', () {
        final invalidIds = [
          'x' * 101, // Too long
          'session with spaces',
          'session@invalid',
          'session.invalid',
        ];

        for (final id in invalidIds) {
          final result = ValidationUtils.validateSessionId(id);
          expect(result.isValid, isFalse,
              reason: 'Session ID "$id" should be invalid');
        }
      });
    });

    group('Sample Rate Validation', () {
      test('should accept valid sample rates', () {
        final validRates = [0.0, 0.5, 1.0, 0.001, 0.999];

        for (final rate in validRates) {
          final result = ValidationUtils.validateSampleRate(rate);
          expect(result.isValid, isTrue, reason: 'Rate $rate should be valid');
        }
      });

      test('should reject invalid sample rates', () {
        final invalidRates = [-0.1, 1.1, double.nan, double.infinity];

        for (final rate in invalidRates) {
          final result = ValidationUtils.validateSampleRate(rate);
          expect(result.isValid, isFalse,
              reason: 'Rate $rate should be invalid');
        }
      });
    });

    group('Rule Priority Validation', () {
      test('should accept valid priorities', () {
        final validPriorities = [-1000, -1, 0, 1, 500, 1000];

        for (final priority in validPriorities) {
          final result = ValidationUtils.validateRulePriority(priority);
          expect(result.isValid, isTrue,
              reason: 'Priority $priority should be valid');
        }
      });

      test('should reject invalid priorities', () {
        final invalidPriorities = [-1001, 1001, -2000, 5000];

        for (final priority in invalidPriorities) {
          final result = ValidationUtils.validateRulePriority(priority);
          expect(result.isValid, isFalse,
              reason: 'Priority $priority should be invalid');
        }
      });
    });

    group('Tracker Group Validation', () {
      test('should accept valid tracker groups', () {
        final result = ValidationUtils.validateTrackerGroup(
          'analytics',
          ['tracker1', 'tracker2'],
        );
        expect(result.isValid, isTrue);
      });

      test('should reject invalid tracker groups', () {
        // Invalid group name
        expect(
          ValidationUtils.validateTrackerGroup('', ['tracker1']).isValid,
          isFalse,
        );

        // Empty tracker list
        expect(
          ValidationUtils.validateTrackerGroup('group', []).isValid,
          isFalse,
        );

        // Too many trackers
        final tooManyTrackers = List.generate(21, (i) => 'tracker$i');
        expect(
          ValidationUtils.validateTrackerGroup('group', tooManyTrackers)
              .isValid,
          isFalse,
        );

        // Duplicate tracker IDs
        expect(
          ValidationUtils.validateTrackerGroup(
              'group', ['tracker1', 'tracker1']).isValid,
          isFalse,
        );

        // Invalid tracker ID
        expect(
          ValidationUtils.validateTrackerGroup('group', ['invalid tracker'])
              .isValid,
          isFalse,
        );
      });

      test('should handle special "*" tracker ID', () {
        // The "*" is a special case that should be valid in tracker groups
        // even though it's not a valid individual tracker ID
        final result = ValidationUtils.validateTrackerGroup('all_groups', ['*']);
        expect(result.isValid, isTrue);
      });
    });

    group('Routing Configuration Validation', () {
      test('should accept valid routing configuration', () {
        final rules = [
          ValidationRule(
            sampleRate: 1.0,
            priority: 10,
            targetGroup: ValidationTrackerGroup('group1', ['tracker1']),
          ),
          ValidationRule(
            sampleRate: 0.5,
            priority: 0,
            isDefault: true,
            targetGroup:
                ValidationTrackerGroup('something', ['tracker1', 'tracker2']),
          ),
        ];

        final result = ValidationUtils.validateRoutingConfiguration(rules);
        expect(result.isValid, isTrue);
      });

      test('should warn about missing default rule', () {
        final rules = [
          ValidationRule(
            sampleRate: 1.0,
            priority: 10,
            targetGroup: ValidationTrackerGroup('group1', ['tracker1']),
          ),
        ];

        final result = ValidationUtils.validateRoutingConfiguration(rules);
        expect(result.isWarning, isTrue);
        expect(result.error, contains('default'));
      });

      test('should reject duplicate rule IDs', () {
        final rules = [
          ValidationRule(
            id: 'rule1',
            sampleRate: 1.0,
            priority: 10,
            targetGroup: ValidationTrackerGroup('group1', ['tracker1']),
          ),
          ValidationRule(
            id: 'rule1', // Duplicate
            sampleRate: 0.5,
            priority: 5,
            targetGroup: ValidationTrackerGroup('group2', ['tracker2']),
          ),
        ];

        final result = ValidationUtils.validateRoutingConfiguration(rules);
        expect(result.isValid, isFalse);
        expect(result.error, contains('Duplicate rule IDs'));
      });

      test('should reject too many rules', () {
        final rules = List.generate(
          101,
          (i) => ValidationRule(
            id: 'rule$i',
            sampleRate: 1.0,
            priority: i,
            targetGroup: ValidationTrackerGroup('group$i', ['tracker$i']),
          ),
        );

        final result = ValidationUtils.validateRoutingConfiguration(rules);
        expect(result.isValid, isFalse);
        expect(result.error, contains('Too many'));
      });
    });

    group('Consent Configuration Validation', () {
      test('should accept valid consent configuration', () {
        final consentData = ConsentValidationData(
          isProduction: true,
          hasAnyConsent: true,
          hasPIIConsent: true,
          tracksPII: true,
          consentVersion: '1.0',
        );

        final result =
            ValidationUtils.validateConsentConfiguration(consentData);
        expect(result.isValid, isTrue);
      });

      test('should warn about missing consent in production', () {
        final consentData = ConsentValidationData(
          isProduction: true,
          hasAnyConsent: false,
          hasPIIConsent: false,
          tracksPII: false,
        );

        final result =
            ValidationUtils.validateConsentConfiguration(consentData);
        expect(result.isWarning, isTrue);
        expect(result.error, contains('production'));
      });

      test('should reject PII tracking without PII consent', () {
        final consentData = ConsentValidationData(
          isProduction: false,
          hasAnyConsent: true,
          hasPIIConsent: false,
          tracksPII: true,
        );

        final result =
            ValidationUtils.validateConsentConfiguration(consentData);
        expect(result.isValid, isFalse);
        expect(result.error, contains('PII consent'));
      });

      test('should warn about missing consent version', () {
        final consentData = ConsentValidationData(
          isProduction: false,
          hasAnyConsent: true,
          hasPIIConsent: true,
          tracksPII: false,
          consentVersion: null,
        );

        final result =
            ValidationUtils.validateConsentConfiguration(consentData);
        expect(result.isWarning, isTrue);
        expect(result.error, contains('version'));
      });
    });

    group('Complete Setup Validation', () {
      test('should validate complete FlexTrack setup', () {
        final setupData = SetupValidationData(
          trackers: [
            ValidationTracker('tracker1', 'Tracker 1'),
            ValidationTracker('tracker2', 'Tracker 2'),
          ],
          routingRules: [
            ValidationRule(
              sampleRate: 1.0,
              priority: 0,
              isDefault: true,
              targetGroup:
                  ValidationTrackerGroup('all', ['tracker1', 'tracker2']),
            ),
          ],
          consentData: ConsentValidationData(
            isProduction: false,
            hasAnyConsent: true,
            hasPIIConsent: true,
            tracksPII: true,
            consentVersion: '1.0',
          ),
        );

        final results = ValidationUtils.validateSetup(setupData);
        expect(results, isNotEmpty); // Expect validation issues
        expect(results.first.error, contains('Tracker ID "all" is reserved')); // Check for specific error message using .error
      });

      test('should detect multiple setup issues', () {
        final setupData = SetupValidationData(
          trackers: [], // No trackers
          routingRules: [], // No rules
          consentData: ConsentValidationData(
            isProduction: true,
            hasAnyConsent: false, // No consent in production
            hasPIIConsent: false,
            tracksPII: false,
          ),
        );

        final results = ValidationUtils.validateSetup(setupData);
        expect(results, isNotEmpty);
        expect(results.length, greaterThanOrEqualTo(2)); // Multiple issues
      });
    });
  });
}
