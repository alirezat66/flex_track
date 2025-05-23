import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('TrackingContext Tests', () {
    group('Factory Constructors', () {
      test('should create basic tracking context', () {
        final context = TrackingContext.create();

        expect(context.userId, isNull);
        expect(context.sessionId, isNull);
        expect(context.deviceId, isNull);
        expect(context.userProperties, isEmpty);
        expect(context.sessionProperties, isEmpty);
        expect(context.environment, equals(Environment.production));
        expect(context.appVersion, isNull);
        expect(context.buildNumber, isNull);
        expect(context.createdAt, isA<DateTime>());
        expect(context.consentManager, isA<ConsentManager>());
      });

      test('should create tracking context with all parameters', () {
        final consentManager = ConsentManager();
        final userProps = {'age': 25, 'plan': 'premium'};
        final sessionProps = {
          'session_start': DateTime.now().toIso8601String()
        };

        final context = TrackingContext.create(
          userId: 'user123',
          sessionId: 'session456',
          deviceId: 'device789',
          userProperties: userProps,
          sessionProperties: sessionProps,
          consentManager: consentManager,
          environment: Environment.staging,
          appVersion: '1.2.3',
          buildNumber: '456',
        );

        expect(context.userId, equals('user123'));
        expect(context.sessionId, equals('session456'));
        expect(context.deviceId, equals('device789'));
        expect(context.userProperties, equals(userProps));
        expect(context.sessionProperties, equals(sessionProps));
        expect(context.consentManager, equals(consentManager));
        expect(context.environment, equals(Environment.staging));
        expect(context.appVersion, equals('1.2.3'));
        expect(context.buildNumber, equals('456'));
      });

      test('should create development context', () {
        final context = TrackingContext.development(
          userId: 'dev_user',
          sessionId: 'dev_session',
        );

        expect(context.userId, equals('dev_user'));
        expect(context.sessionId, equals('dev_session'));
        expect(context.deviceId, equals('dev-device'));
        expect(context.environment, equals(Environment.development));
        expect(context.appVersion, equals('dev'));
        expect(context.buildNumber, equals('debug'));
        expect(context.isDebugMode, isTrue);
        expect(context.isProduction, isFalse);
      });

      test('should create testing context', () {
        final context = TrackingContext.testing(
          userId: 'test_user',
          sessionId: 'test_session',
        );

        expect(context.userId, equals('test_user'));
        expect(context.sessionId, equals('test_session'));
        expect(context.deviceId, equals('test-device'));
        expect(context.environment, equals(Environment.testing));
        expect(context.appVersion, equals('test'));
        expect(context.buildNumber, equals('0'));
        expect(context.isTesting, isTrue);
        expect(context.isProduction, isFalse);
        expect(context.consentManager.hasAllConsents, isTrue);
        expect(context.consentManager.consentVersion, equals('test'));
      });
    });

    group('Environment Properties', () {
      test('should correctly identify debug mode', () {
        final devContext = TrackingContext.development();
        final prodContext =
            TrackingContext.create(environment: Environment.production);
        final testContext = TrackingContext.testing();

        expect(devContext.isDebugMode, isTrue);
        expect(prodContext.isDebugMode, isFalse);
        expect(testContext.isDebugMode, isFalse); // Testing is not debug mode
      });

      test('should correctly identify production', () {
        final prodContext =
            TrackingContext.create(environment: Environment.production);
        final devContext = TrackingContext.development();
        final stagingContext =
            TrackingContext.create(environment: Environment.staging);

        expect(prodContext.isProduction, isTrue);
        expect(devContext.isProduction, isFalse);
        expect(stagingContext.isProduction, isFalse);
      });

      test('should correctly identify testing', () {
        final testContext = TrackingContext.testing();
        final prodContext = TrackingContext.create();
        final devContext = TrackingContext.development();

        expect(testContext.isTesting, isTrue);
        expect(prodContext.isTesting, isFalse);
        expect(devContext.isTesting, isFalse);
      });
    });

    group('Immutable Updates', () {
      test('should create new context with updated user ID', () {
        final original = TrackingContext.create(userId: 'user1');
        final updated = original.withUserId('user2');

        expect(original.userId, equals('user1'));
        expect(updated.userId, equals('user2'));
        expect(original, isNot(equals(updated)));

        // Other properties should remain the same
        expect(updated.sessionId, equals(original.sessionId));
        expect(updated.environment, equals(original.environment));
      });

      test('should create new context with updated session ID', () {
        final original = TrackingContext.create(sessionId: 'session1');
        final updated = original.withSessionId('session2');

        expect(original.sessionId, equals('session1'));
        expect(updated.sessionId, equals('session2'));
        expect(original, isNot(equals(updated)));
      });

      test('should create new context with updated user properties', () {
        final original = TrackingContext.create(
          userProperties: {'age': 25, 'plan': 'basic'},
        );

        final updated =
            original.withUserProperties({'age': 26, 'premium': true});

        expect(original.userProperties, equals({'age': 25, 'plan': 'basic'}));
        expect(
            updated.userProperties,
            equals({
              'age': 26, // Updated
              'plan': 'basic', // Preserved
              'premium': true, // Added
            }));
      });

      test('should create new context with updated session properties', () {
        final original = TrackingContext.create(
          sessionProperties: {'start_time': '10:00', 'source': 'direct'},
        );

        final updated = original
            .withSessionProperties({'start_time': '10:30', 'page_count': 5});

        expect(original.sessionProperties,
            equals({'start_time': '10:00', 'source': 'direct'}));
        expect(
            updated.sessionProperties,
            equals({
              'start_time': '10:30', // Updated
              'source': 'direct', // Preserved
              'page_count': 5, // Added
            }));
      });

      test('should create new context with updated environment', () {
        final original =
            TrackingContext.create(environment: Environment.development);
        final updated = original.withEnvironment(Environment.production);

        expect(original.environment, equals(Environment.development));
        expect(updated.environment, equals(Environment.production));
        expect(original.isDebugMode, isTrue);
        expect(updated.isDebugMode, isFalse);
      });
    });

    group('Convenience Properties', () {
      test('should check if user is identified', () {
        final anonymous = TrackingContext.create();
        final identified = TrackingContext.create(userId: 'user123');
        final emptyUserId = TrackingContext.create(userId: '');

        expect(anonymous.isUserIdentified, isFalse);
        expect(identified.isUserIdentified, isTrue);
        expect(emptyUserId.isUserIdentified, isFalse);
      });

      test('should check if session is active', () {
        final noSession = TrackingContext.create();
        final activeSession = TrackingContext.create(sessionId: 'session123');
        final emptySession = TrackingContext.create(sessionId: '');

        expect(noSession.hasActiveSession, isFalse);
        expect(activeSession.hasActiveSession, isTrue);
        expect(emptySession.hasActiveSession, isFalse);
      });

      test('should get user property by key', () {
        final context = TrackingContext.create(
          userProperties: {
            'age': 25,
            'name': 'John',
            'premium': true,
          },
        );

        expect(context.getUserProperty<int>('age'), equals(25));
        expect(context.getUserProperty<String>('name'), equals('John'));
        expect(context.getUserProperty<bool>('premium'), isTrue);
        expect(context.getUserProperty<String>('nonexistent'), isNull);
        expect(context.getUserProperty<int>('name'), isNull); // Wrong type
      });

      test('should get session property by key', () {
        final context = TrackingContext.create(
          sessionProperties: {
            'duration': 300,
            'source': 'google',
            'mobile': false,
          },
        );

        expect(context.getSessionProperty<int>('duration'), equals(300));
        expect(context.getSessionProperty<String>('source'), equals('google'));
        expect(context.getSessionProperty<bool>('mobile'), isFalse);
        expect(context.getSessionProperty<String>('nonexistent'), isNull);
        expect(context.getSessionProperty<int>('source'), isNull); // Wrong type
      });
    });

    group('Context Properties for Events', () {
      test('should generate context properties for events', () {
        final context = TrackingContext.create(
          userId: 'user123',
          sessionId: 'session456',
          deviceId: 'device789',
          appVersion: '1.0.0',
          buildNumber: '100',
          environment: Environment.staging,
        );

        final properties = context.getContextProperties();

        expect(properties['user_id'], equals('user123'));
        expect(properties['session_id'], equals('session456'));
        expect(properties['device_id'], equals('device789'));
        expect(properties['app_version'], equals('1.0.0'));
        expect(properties['build_number'], equals('100'));
        expect(properties['environment'], equals('staging'));
        expect(properties['context_created_at'], isA<String>());
      });

      test('should handle null values in context properties', () {
        final context = TrackingContext.create();
        final properties = context.getContextProperties();

        expect(properties.containsKey('user_id'), isFalse);
        expect(properties.containsKey('session_id'), isFalse);
        expect(properties.containsKey('device_id'), isFalse);
        expect(properties.containsKey('app_version'), isFalse);
        expect(properties.containsKey('build_number'), isFalse);
        expect(properties['environment'], equals('production'));
        expect(properties['context_created_at'], isA<String>());
      });
    });

    group('Serialization', () {
      test('should convert to map', () {
        final context = TrackingContext.create(
          userId: 'user123',
          sessionId: 'session456',
          deviceId: 'device789',
          userProperties: {'age': 25},
          sessionProperties: {'source': 'direct'},
          environment: Environment.development,
          appVersion: '1.0.0',
          buildNumber: '100',
        );

        final map = context.toMap();

        expect(map['userId'], equals('user123'));
        expect(map['sessionId'], equals('session456'));
        expect(map['deviceId'], equals('device789'));
        expect(map['userProperties'], equals({'age': 25}));
        expect(map['sessionProperties'], equals({'source': 'direct'}));
        expect(map['environment'], equals('development'));
        expect(map['appVersion'], equals('1.0.0'));
        expect(map['buildNumber'], equals('100'));
        expect(map['createdAt'], isA<String>());
        expect(map['isUserIdentified'], isTrue);
        expect(map['hasActiveSession'], isTrue);
        expect(map['consent'], isA<Map<String, dynamic>>());
      });

      test('should create from map', () {
        final originalMap = {
          'userId': 'user123',
          'sessionId': 'session456',
          'deviceId': 'device789',
          'userProperties': {'age': 25, 'plan': 'premium'},
          'sessionProperties': {'source': 'google'},
          'environment': 'staging',
          'appVersion': '2.0.0',
          'buildNumber': '200',
          'consent': {
            'general': true,
            'pii': false,
            'version': '1.0',
          },
        };

        final context = TrackingContext.fromMap(originalMap);

        expect(context.userId, equals('user123'));
        expect(context.sessionId, equals('session456'));
        expect(context.deviceId, equals('device789'));
        expect(context.userProperties, equals({'age': 25, 'plan': 'premium'}));
        expect(context.sessionProperties, equals({'source': 'google'}));
        expect(context.environment, equals(Environment.staging));
        expect(context.appVersion, equals('2.0.0'));
        expect(context.buildNumber, equals('200'));
        expect(context.consentManager.hasGeneralConsent, isTrue);
        expect(context.consentManager.hasPIIConsent, isFalse);
        expect(context.consentManager.consentVersion, equals('1.0'));
      });

      test('should handle unknown environment in fromMap', () {
        final map = {
          'environment': 'unknown_environment',
        };

        final context = TrackingContext.fromMap(map);
        expect(context.environment,
            equals(Environment.production)); // Default fallback
      });

      test('should handle missing fields in fromMap', () {
        final map = <String, dynamic>{};

        final context = TrackingContext.fromMap(map);

        expect(context.userId, isNull);
        expect(context.sessionId, isNull);
        expect(context.deviceId, isNull);
        expect(context.userProperties, isEmpty);
        expect(context.sessionProperties, isEmpty);
        expect(context.environment, equals(Environment.production));
        expect(context.appVersion, isNull);
        expect(context.buildNumber, isNull);
      });
    });

    group('Validation', () {
      test('should validate production context', () {
        final context = TrackingContext.create(
          environment: Environment.production,
          userId: 'user123',
          sessionId: 'session456',
          appVersion: '1.0.0',
        );

        final issues = context.validate();
        expect(issues, isEmpty);
      });

      test('should warn about anonymous user in production', () {
        final context = TrackingContext.create(
          environment: Environment.production,
          sessionId: 'session456',
          appVersion: '1.0.0',
        );

        final issues = context.validate();
        expect(issues, contains(contains('User not identified in production')));
      });

      test('should warn about missing session in production', () {
        final context = TrackingContext.create(
          environment: Environment.production,
          userId: 'user123',
          appVersion: '1.0.0',
        );

        final issues = context.validate();
        expect(issues, contains(contains('No active session in production')));
      });

      test('should warn about missing app version in production', () {
        final context = TrackingContext.create(
          environment: Environment.production,
          userId: 'user123',
          sessionId: 'session456',
        );

        final issues = context.validate();
        expect(issues, contains(contains('App version not set')));
      });

      test('should include consent validation issues', () {
        final consentManager = ConsentManager();
        consentManager.setGeneralConsent(true);
        // Missing consent version should trigger warning

        final context = TrackingContext.create(
          consentManager: consentManager,
          environment: Environment.production,
          userId: 'user123',
          sessionId: 'session456',
          appVersion: '1.0.0',
        );

        final issues = context.validate();
        expect(issues, isNotEmpty); // Should contain consent-related warnings
      });
    });

    group('Equality and HashCode', () {
      test('should be equal for same properties', () {
        final context1 = TrackingContext.create(
          userId: 'user123',
          sessionId: 'session456',
          deviceId: 'device789',
          environment: Environment.development,
        );

        final context2 = TrackingContext.create(
          userId: 'user123',
          sessionId: 'session456',
          deviceId: 'device789',
          environment: Environment.development,
        );

        expect(context1, equals(context2));
        expect(context1.hashCode, equals(context2.hashCode));
      });

      test('should not be equal for different properties', () {
        final context1 = TrackingContext.create(userId: 'user123');
        final context2 = TrackingContext.create(userId: 'user456');

        expect(context1, isNot(equals(context2)));
        expect(context1.hashCode, isNot(equals(context2.hashCode)));
      });

      test('should not be equal for different environments', () {
        final context1 =
            TrackingContext.create(environment: Environment.development);
        final context2 =
            TrackingContext.create(environment: Environment.production);

        expect(context1, isNot(equals(context2)));
      });
    });

    group('toString Method', () {
      test('should format toString correctly', () {
        final context = TrackingContext.create(
          userId: 'user123',
          sessionId: 'session456',
          environment: Environment.development,
        );

        final result = context.toString();

        expect(result, contains('TrackingContext'));
        expect(result, contains('user: user123'));
        expect(result, contains('session: session456'));
        expect(result, contains('environment: development'));
      });

      test('should handle anonymous user in toString', () {
        final context = TrackingContext.create(
          sessionId: 'session456',
          environment: Environment.production,
        );

        final result = context.toString();

        expect(result, contains('user: anonymous'));
        expect(result, contains('session: session456'));
        expect(result, contains('environment: production'));
      });

      test('should handle no session in toString', () {
        final context = TrackingContext.create(
          userId: 'user123',
          environment: Environment.staging,
        );

        final result = context.toString();

        expect(result, contains('user: user123'));
        expect(result, contains('session: none'));
        expect(result, contains('environment: staging'));
      });
    });
  });
}
