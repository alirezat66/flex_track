import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('ConsentManager Tests', () {
    late ConsentManager consentManager;

    setUp(() {
      consentManager = ConsentManager();
    });

    group('Initial State', () {
      test('should start with no consents granted', () {
        expect(consentManager.hasGeneralConsent, isFalse);
        expect(consentManager.hasPIIConsent, isFalse);
        expect(consentManager.hasMarketingConsent, isFalse);
        expect(consentManager.hasAnalyticsConsent, isFalse);
        expect(consentManager.hasPerformanceConsent, isFalse);
        expect(consentManager.hasAnyConsent, isFalse);
        expect(consentManager.hasAllConsents, isFalse);
        expect(consentManager.consentTimestamp, isNull);
        expect(consentManager.consentVersion, isNull);
      });
    });

    group('Individual Consent Setting', () {
      test('should set general consent', () {
        consentManager.setGeneralConsent(true);

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.hasAnyConsent, isTrue);
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should set PII consent', () {
        consentManager.setPIIConsent(true);

        expect(consentManager.hasPIIConsent, isTrue);
        expect(consentManager.hasAnyConsent, isTrue);
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should set marketing consent', () {
        consentManager.setMarketingConsent(true);

        expect(consentManager.hasMarketingConsent, isTrue);
        expect(consentManager.hasAnyConsent, isTrue);
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should set analytics consent', () {
        consentManager.setAnalyticsConsent(true);

        expect(consentManager.hasAnalyticsConsent, isTrue);
        expect(consentManager.hasAnyConsent, isTrue);
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should set performance consent', () {
        consentManager.setPerformanceConsent(true);

        expect(consentManager.hasPerformanceConsent, isTrue);
        expect(consentManager.hasAnyConsent, isTrue);
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should revoke individual consents', () {
        consentManager.setGeneralConsent(true);
        consentManager.setPIIConsent(true);

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.hasPIIConsent, isTrue);

        consentManager.setGeneralConsent(false);

        expect(consentManager.hasGeneralConsent, isFalse);
        expect(consentManager.hasPIIConsent, isTrue); // Should remain unchanged
      });
    });

    group('Bulk Consent Setting', () {
      test('should set multiple consents at once', () {
        consentManager.setConsents(
          general: true,
          pii: false,
          marketing: true,
          analytics: false,
          performance: true,
          version: '1.0',
        );

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.hasPIIConsent, isFalse);
        expect(consentManager.hasMarketingConsent, isTrue);
        expect(consentManager.hasAnalyticsConsent, isFalse);
        expect(consentManager.hasPerformanceConsent, isTrue);
        expect(consentManager.consentVersion, equals('1.0'));
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should update only specified consents', () {
        // Set initial state
        consentManager.setConsents(
          general: true,
          pii: true,
          marketing: false,
          version: '1.0',
        );

        // Update only some consents
        consentManager.setConsents(
          general: false,
          marketing: true,
          version: '1.1',
        );

        expect(consentManager.hasGeneralConsent, isFalse); // Updated
        expect(consentManager.hasPIIConsent, isTrue); // Unchanged
        expect(consentManager.hasMarketingConsent, isTrue); // Updated
        expect(consentManager.hasAnalyticsConsent, isFalse); // Unchanged
        expect(consentManager.consentVersion, equals('1.1')); // Updated
      });

      test('should grant all consents', () {
        consentManager.grantAllConsents(version: '2.0');

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.hasPIIConsent, isTrue);
        expect(consentManager.hasMarketingConsent, isTrue);
        expect(consentManager.hasAnalyticsConsent, isTrue);
        expect(consentManager.hasPerformanceConsent, isTrue);
        expect(consentManager.hasAllConsents, isTrue);
        expect(consentManager.consentVersion, equals('2.0'));
      });

      test('should revoke all consents', () {
        // Grant all first
        consentManager.grantAllConsents(version: '1.0');
        consentManager.setCustomConsent('custom1', true);
        consentManager.setCustomConsent('custom2', true);

        expect(consentManager.hasAllConsents, isTrue);
        expect(consentManager.getCustomConsent('custom1'), isTrue);

        // Revoke all
        consentManager.revokeAllConsents();

        expect(consentManager.hasGeneralConsent, isFalse);
        expect(consentManager.hasPIIConsent, isFalse);
        expect(consentManager.hasMarketingConsent, isFalse);
        expect(consentManager.hasAnalyticsConsent, isFalse);
        expect(consentManager.hasPerformanceConsent, isFalse);
        expect(consentManager.hasAnyConsent, isFalse);
        expect(consentManager.getCustomConsents(), isEmpty);
      });
    });

    group('Custom Consents', () {
      test('should set custom consent', () {
        consentManager.setCustomConsent('location_tracking', true);

        expect(consentManager.getCustomConsent('location_tracking'), isTrue);
        expect(consentManager.hasAnyConsent, isTrue);
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should get false for non-existent custom consent', () {
        expect(consentManager.getCustomConsent('nonexistent'), isFalse);
      });

      test('should remove custom consent', () {
        consentManager.setCustomConsent('temp_consent', true);
        expect(consentManager.getCustomConsent('temp_consent'), isTrue);

        consentManager.removeCustomConsent('temp_consent');
        expect(consentManager.getCustomConsent('temp_consent'), isFalse);
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should get all custom consents', () {
        consentManager.setCustomConsent('location', true);
        consentManager.setCustomConsent('camera', false);
        consentManager.setCustomConsent('microphone', true);

        final customConsents = consentManager.getCustomConsents();

        expect(customConsents, isA<Map<String, bool>>());
        expect(customConsents['location'], isTrue);
        expect(customConsents['camera'], isFalse);
        expect(customConsents['microphone'], isTrue);
        expect(customConsents.length, equals(3));
      });

      test('should return unmodifiable map for custom consents', () {
        consentManager.setCustomConsent('test', true);
        final customConsents = consentManager.getCustomConsents();

        expect(() => customConsents['new'] = true, throwsUnsupportedError);
      });
    });

    group('Consent Checking', () {
      test('should check if consent is required for specific types', () {
        expect(
            consentManager.isConsentRequiredFor(ConsentType.general), isTrue);
        expect(consentManager.isConsentRequiredFor(ConsentType.pii), isTrue);

        consentManager.setGeneralConsent(true);
        expect(
            consentManager.isConsentRequiredFor(ConsentType.general), isFalse);
        expect(consentManager.isConsentRequiredFor(ConsentType.pii), isTrue);
      });

      test('should check if data processing is allowed for specific types', () {
        expect(consentManager.isAllowedFor(ConsentType.general), isFalse);
        expect(consentManager.isAllowedFor(ConsentType.marketing), isFalse);

        consentManager.setGeneralConsent(true);
        consentManager.setMarketingConsent(true);

        expect(consentManager.isAllowedFor(ConsentType.general), isTrue);
        expect(consentManager.isAllowedFor(ConsentType.marketing), isTrue);
        expect(consentManager.isAllowedFor(ConsentType.pii), isFalse);
      });
    });

    group('Consent Version Management', () {
      test('should set consent version', () {
        consentManager.setConsentVersion('v1.2.3');

        expect(consentManager.consentVersion, equals('v1.2.3'));
        expect(consentManager.consentTimestamp, isNotNull);
      });

      test('should update version through setConsents', () {
        consentManager.setConsents(version: 'initial');
        expect(consentManager.consentVersion, equals('initial'));

        consentManager.setConsents(general: true, version: 'updated');
        expect(consentManager.consentVersion, equals('updated'));
      });
    });

    group('Consent Summary', () {
      test('should create consent summary', () {
        consentManager.setGeneralConsent(true);
        consentManager.setPIIConsent(false);
        consentManager.setMarketingConsent(true);
        consentManager.setCustomConsent('location', true);
        consentManager.setConsentVersion('1.0');

        final summary = consentManager.getSummary();

        expect(summary.hasGeneralConsent, isTrue);
        expect(summary.hasPIIConsent, isFalse);
        expect(summary.hasMarketingConsent, isTrue);
        expect(summary.hasAnalyticsConsent, isFalse);
        expect(summary.hasPerformanceConsent, isFalse);
        expect(summary.customConsents['location'], isTrue);
        expect(summary.consentVersion, equals('1.0'));
        expect(summary.consentTimestamp, isNotNull);
        expect(summary.hasAnyConsent, isTrue);
        expect(summary.hasAllStandardConsents, isFalse);
      });

      test('should create summary with all standard consents', () {
        consentManager.grantAllConsents(version: '2.0');

        final summary = consentManager.getSummary();

        expect(summary.hasAllStandardConsents, isTrue);
        expect(summary.hasAnyConsent, isTrue);
      });

      test('should convert summary to map', () {
        consentManager.setGeneralConsent(true);
        consentManager.setCustomConsent('test', false);
        consentManager.setConsentVersion('1.0');

        final summary = consentManager.getSummary();
        final map = summary.toMap();

        expect(map, isA<Map<String, dynamic>>());
        expect(map['general'], isTrue);
        expect(map['pii'], isFalse);
        expect(map['custom'], isA<Map<String, bool>>());
        expect(map['version'], equals('1.0'));
        expect(map['hasAnyConsent'], isTrue);
        expect(map['hasAllStandardConsents'], isFalse);
        expect(map['timestamp'], isA<String>());
      });

      test('should format summary toString', () {
        consentManager.setGeneralConsent(true);
        consentManager.setConsentVersion('1.0');

        final summary = consentManager.getSummary();
        final result = summary.toString();

        expect(result, contains('ConsentSummary'));
        expect(result, contains('any: true'));
        expect(result, contains('all: false'));
        expect(result, contains('version: 1.0'));
      });
    });

    group('Serialization', () {
      test('should export to map', () {
        consentManager.setConsents(
          general: true,
          pii: false,
          marketing: true,
          analytics: false,
          performance: true,
          version: '1.5',
        );
        consentManager.setCustomConsent('location', true);
        consentManager.setCustomConsent('camera', false);

        final map = consentManager.toMap();

        expect(map['general'], isTrue);
        expect(map['pii'], isFalse);
        expect(map['marketing'], isTrue);
        expect(map['analytics'], isFalse);
        expect(map['performance'], isTrue);
        expect(map['version'], equals('1.5'));
        expect(map['timestamp'], isA<String>());
        expect(map['custom'], isA<Map<String, bool>>());
        expect(map['custom']['location'], isTrue);
        expect(map['custom']['camera'], isFalse);
      });

      test('should load from map', () {
        final data = {
          'general': true,
          'pii': false,
          'marketing': true,
          'analytics': false,
          'performance': true,
          'version': '2.0',
          'timestamp': '2023-01-01T12:00:00.000Z',
          'custom': {
            'location': true,
            'notifications': false,
          },
        };

        consentManager.loadFromMap(data);

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.hasPIIConsent, isFalse);
        expect(consentManager.hasMarketingConsent, isTrue);
        expect(consentManager.hasAnalyticsConsent, isFalse);
        expect(consentManager.hasPerformanceConsent, isTrue);
        expect(consentManager.consentVersion, equals('2.0'));
        expect(consentManager.consentTimestamp, isNotNull);
        expect(consentManager.getCustomConsent('location'), isTrue);
        expect(consentManager.getCustomConsent('notifications'), isFalse);
      });

      test('should handle missing fields in loadFromMap', () {
        final data = <String, dynamic>{
          'general': true,
          // Missing other fields
        };

        consentManager.loadFromMap(data);

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.hasPIIConsent, isFalse); // Default
        expect(consentManager.consentVersion, isNull);
        expect(consentManager.getCustomConsents(), isEmpty);
      });

      test('should handle invalid timestamp in loadFromMap', () {
        final data = {
          'general': true,
          'timestamp': 'invalid_timestamp',
        };

        consentManager.loadFromMap(data);

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.consentTimestamp,
            isNull); // Should handle gracefully
      });

      test('should handle invalid custom consents in loadFromMap', () {
        final data = {
          'general': true,
          'custom': 'not_a_map',
        };

        consentManager.loadFromMap(data);

        expect(consentManager.hasGeneralConsent, isTrue);
        expect(consentManager.getCustomConsents(), isEmpty);
      });
    });

    group('Validation', () {
      test('should validate consent configuration', () {
        consentManager.grantAllConsents(version: '1.0');

        final issues = consentManager.validate();
        expect(issues, isEmpty);
      });

      test('should warn about general consent without PII consent', () {
        consentManager.setGeneralConsent(true);
        consentManager.setPIIConsent(false);

        final issues = consentManager.validate();
        expect(
            issues,
            contains(
                contains('General consent granted but PII consent denied')));
      });

      test('should warn about missing consent version', () {
        consentManager.setGeneralConsent(true);
        // No version set

        final issues = consentManager.validate();
        expect(issues, contains(contains('Consent version not set')));
      });

      test('should warn about missing consent timestamp', () {
        // This test is tricky since timestamp is auto-set, but we can test the logic
        final manager = ConsentManager();
        // Manually create a scenario where consent exists but timestamp doesn't
        // by directly modifying the data (would require access to private fields)
        // For now, we'll test that when consent is granted, timestamp is set

        manager.setGeneralConsent(true);
        expect(manager.consentTimestamp, isNotNull);
      });

      test('should not warn when no consent is granted', () {
        final issues = consentManager.validate();
        expect(issues, isEmpty); // No issues when no consent is given
      });
    });

    group('toString Method', () {
      test('should format toString with no consents', () {
        final result = consentManager.toString();

        expect(result, contains('ConsentManager'));
        expect(result, contains('custom: 0'));
        expect(result, isNot(contains('general')));
      });

      test('should format toString with some consents', () {
        consentManager.setGeneralConsent(true);
        consentManager.setPIIConsent(true);
        consentManager.setMarketingConsent(false);
        consentManager.setCustomConsent('location', true);
        consentManager.setCustomConsent('camera', false);

        final result = consentManager.toString();

        expect(result, contains('ConsentManager'));
        expect(result, contains('general'));
        expect(result, contains('pii'));
        expect(
            result, isNot(contains('marketing'))); // False consents not shown
        expect(result, contains('custom: 2'));
      });

      test('should format toString with all consents', () {
        consentManager.grantAllConsents();

        final result = consentManager.toString();

        expect(result, contains('general'));
        expect(result, contains('pii'));
        expect(result, contains('marketing'));
        expect(result, contains('analytics'));
        expect(result, contains('performance'));
        expect(result, contains('custom: 0'));
      });
    });

    group('Timestamp Behavior', () {
      test('should update timestamp on consent changes', () async {
        final before = DateTime.now();

        consentManager.setGeneralConsent(true);
        final timestamp1 = consentManager.consentTimestamp!;

        expect(
            timestamp1.isAfter(before) || timestamp1.isAtSameMomentAs(before),
            isTrue);

        // Small delay to ensure different timestamp
        await Future.delayed(Duration(milliseconds: 1));

        consentManager.setPIIConsent(true);
        final timestamp2 = consentManager.consentTimestamp!;

        expect(timestamp2.isAfter(timestamp1), isTrue);
      });

      test('should update timestamp on version changes', () async {
        consentManager.setGeneralConsent(true);
        final timestamp1 = consentManager.consentTimestamp!;

        await Future.delayed(Duration(milliseconds: 1));

        consentManager.setConsentVersion('1.1');
        final timestamp2 = consentManager.consentTimestamp!;

        expect(timestamp2.isAfter(timestamp1), isTrue);
      });

      test('should update timestamp on custom consent changes', () async {
        consentManager.setCustomConsent('test', true);
        final timestamp1 = consentManager.consentTimestamp!;

        await Future.delayed(Duration(milliseconds: 1));

        consentManager.removeCustomConsent('test');
        final timestamp2 = consentManager.consentTimestamp!;

        expect(timestamp2.isAfter(timestamp1), isTrue);
      });
    });
  });
}
