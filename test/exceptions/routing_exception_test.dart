import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('RoutingException Tests', () {
    group('Constructor and Properties', () {
      test('should create basic routing exception', () {
        final exception = RoutingException('Routing failed');

        expect(exception.message, equals('Routing failed'));
        expect(exception.eventName, isNull);
        expect(exception.ruleName, isNull);
        expect(exception.code, isNull);
        expect(exception.originalError, isNull);
        expect(exception.stackTrace, isNull);
      });

      test('should create routing exception with event name', () {
        final exception = RoutingException(
          'Event routing failed',
          eventName: 'user_action',
        );

        expect(exception.message, equals('Event routing failed'));
        expect(exception.eventName, equals('user_action'));
        expect(exception.ruleName, isNull);
      });

      test('should create routing exception with rule name', () {
        final exception = RoutingException(
          'Rule processing failed',
          ruleName: 'business_rule',
        );

        expect(exception.message, equals('Rule processing failed'));
        expect(exception.eventName, isNull);
        expect(exception.ruleName, equals('business_rule'));
      });

      test('should create routing exception with all properties', () {
        final originalError = Exception('Original error');
        final stackTrace = StackTrace.current;

        final exception = RoutingException(
          'Complete routing error',
          code: 'ROUTING_FAILED',
          originalError: originalError,
          stackTrace: stackTrace,
          eventName: 'test_event',
          ruleName: 'test_rule',
        );

        expect(exception.message, equals('Complete routing error'));
        expect(exception.code, equals('ROUTING_FAILED'));
        expect(exception.originalError, equals(originalError));
        expect(exception.stackTrace, equals(stackTrace));
        expect(exception.eventName, equals('test_event'));
        expect(exception.ruleName, equals('test_rule'));
      });
    });

    group('toString Method', () {
      test('should format basic routing exception', () {
        final exception = RoutingException('Basic routing error');

        final result = exception.toString();

        expect(result, contains('RoutingException'));
        expect(result, contains('Basic routing error'));
        expect(result, isNot(contains('Event:')));
        expect(result, isNot(contains('Rule:')));
        expect(result, isNot(contains('Caused by:')));
      });

      test('should include error code when provided', () {
        final exception = RoutingException(
          'Routing error with code',
          code: 'INVALID_ROUTE',
        );

        final result = exception.toString();

        expect(result, contains('RoutingException(INVALID_ROUTE)'));
        expect(result, contains('Routing error with code'));
      });

      test('should include event name when provided', () {
        final exception = RoutingException(
          'Event routing failed',
          eventName: 'user_action',
        );

        final result = exception.toString();

        expect(result, contains('Event routing failed'));
        expect(result, contains('Event: user_action'));
      });

      test('should include rule name when provided', () {
        final exception = RoutingException(
          'Rule processing failed',
          ruleName: 'business_rule',
        );

        final result = exception.toString();

        expect(result, contains('Rule processing failed'));
        expect(result, contains('Rule: business_rule'));
      });

      test('should include both event and rule names', () {
        final exception = RoutingException(
          'Event and rule error',
          eventName: 'purchase_event',
          ruleName: 'purchase_rule',
        );

        final result = exception.toString();

        expect(result, contains('Event and rule error'));
        expect(result, contains('Event: purchase_event'));
        expect(result, contains('Rule: purchase_rule'));
      });

      test('should include original error when provided', () {
        final originalError = ArgumentError('Invalid routing configuration');
        final exception = RoutingException(
          'Routing configuration error',
          originalError: originalError,
        );

        final result = exception.toString();

        expect(result, contains('Routing configuration error'));
        expect(
            result,
            contains(
                'Caused by: Invalid argument(s): Invalid routing configuration'));
      });

      test('should format complete routing exception with all fields', () {
        final originalError = Exception('Configuration parse error');
        final exception = RoutingException(
          'Complete routing failure',
          code: 'COMPLETE_FAILURE',
          originalError: originalError,
          eventName: 'purchase_event',
          ruleName: 'purchase_routing_rule',
        );

        final result = exception.toString();

        expect(result, contains('RoutingException(COMPLETE_FAILURE)'));
        expect(result, contains('Complete routing failure'));
        expect(result, contains('Event: purchase_event'));
        expect(result, contains('Rule: purchase_routing_rule'));
        expect(result,
            contains('Caused by: Exception: Configuration parse error'));
      });

      test('should handle null values gracefully', () {
        final exception = RoutingException(
          'Error with nulls',
          code: null,
          eventName: null,
          ruleName: null,
          originalError: null,
        );

        final result = exception.toString();

        expect(result, contains('Error with nulls'));
        expect(result, isNot(contains('Event:')));
        expect(result, isNot(contains('Rule:')));
        expect(result, isNot(contains('Caused by:')));
      });

      test('should handle empty strings', () {
        final exception = RoutingException(
          'Error with empty strings',
          eventName: '',
          ruleName: '',
        );

        final result = exception.toString();

        expect(result, contains('Error with empty strings'));
        expect(result, contains('Event:'));
        expect(result, contains('Rule:'));
      });

      test('should handle complex original error types', () {
        final nestedError = RoutingException('Nested routing error');
        final exception = RoutingException(
          'Outer routing error',
          originalError: nestedError,
        );

        final result = exception.toString();

        expect(result, contains('Outer routing error'));
        expect(result,
            contains('Caused by: RoutingException: Nested routing error'));
      });
    });

    group('Exception Interface', () {
      test('should implement FlexTrackException correctly', () {
        final exception = RoutingException('Test routing error');

        expect(exception, isA<FlexTrackException>());
        expect(exception, isA<Exception>());
        expect(exception.message, equals('Test routing error'));
      });

      test('should be throwable', () {
        expect(() {
          throw RoutingException('Test routing throw');
        }, throwsA(isA<RoutingException>()));
      });

      test('should be catchable as FlexTrackException', () {
        try {
          throw RoutingException('Catchable error');
        } on FlexTrackException catch (e) {
          expect(e, isA<RoutingException>());
          expect(e.message, equals('Catchable error'));
        }
      });

      test('should be catchable as specific RoutingException', () {
        try {
          throw RoutingException(
            'Specific routing error',
            eventName: 'test_event',
            ruleName: 'test_rule',
          );
        } on RoutingException catch (e) {
          expect(e.message, equals('Specific routing error'));
          expect(e.eventName, equals('test_event'));
          expect(e.ruleName, equals('test_rule'));
        }
      });
    });

    group('Real-world Scenarios', () {
      test('should handle event routing failure scenario', () {
        final exception = RoutingException(
          'Failed to route event to trackers',
          code: 'NO_MATCHING_RULES',
          eventName: 'user_signup',
        );

        expect(exception.message, equals('Failed to route event to trackers'));
        expect(exception.code, equals('NO_MATCHING_RULES'));
        expect(exception.eventName, equals('user_signup'));
        expect(exception.ruleName, isNull);

        final result = exception.toString();
        expect(result, contains('RoutingException(NO_MATCHING_RULES)'));
        expect(result, contains('Event: user_signup'));
      });

      test('should handle rule evaluation failure scenario', () {
        final originalError = Exception('Invalid regex pattern');
        final exception = RoutingException(
          'Rule evaluation failed',
          code: 'RULE_EVALUATION_ERROR',
          ruleName: 'regex_matching_rule',
          originalError: originalError,
        );

        expect(exception.message, equals('Rule evaluation failed'));
        expect(exception.code, equals('RULE_EVALUATION_ERROR'));
        expect(exception.ruleName, equals('regex_matching_rule'));
        expect(exception.originalError, equals(originalError));

        final result = exception.toString();
        expect(result, contains('Rule: regex_matching_rule'));
        expect(result, contains('Caused by: Exception: Invalid regex pattern'));
      });

      test('should handle configuration validation scenario', () {
        final exception = RoutingException(
          'Invalid routing configuration detected',
          code: 'INVALID_CONFIG',
          eventName: 'configuration_validation',
          ruleName: 'validation_rule',
        );

        expect(exception.message, contains('Invalid routing configuration'));
        expect(exception.code, equals('INVALID_CONFIG'));
        expect(exception.eventName, equals('configuration_validation'));
        expect(exception.ruleName, equals('validation_rule'));
      });

      test('should handle tracker group resolution failure', () {
        final exception = RoutingException(
          'Failed to resolve tracker group',
          code: 'GROUP_NOT_FOUND',
          eventName: 'business_event',
          ruleName: 'business_routing_rule',
        );

        final result = exception.toString();
        expect(result, contains('RoutingException(GROUP_NOT_FOUND)'));
        expect(result, contains('Failed to resolve tracker group'));
        expect(result, contains('Event: business_event'));
        expect(result, contains('Rule: business_routing_rule'));
      });

      test('should handle consent validation failure', () {
        final exception = RoutingException(
          'Event blocked due to consent requirements',
          code: 'CONSENT_REQUIRED',
          eventName: 'pii_event',
          ruleName: 'pii_consent_rule',
        );

        expect(exception.message, contains('consent requirements'));
        expect(exception.code, equals('CONSENT_REQUIRED'));
        expect(exception.eventName, equals('pii_event'));
        expect(exception.ruleName, equals('pii_consent_rule'));
      });

      test('should handle sampling rejection scenario', () {
        final exception = RoutingException(
          'Event rejected by sampling',
          code: 'SAMPLED_OUT',
          eventName: 'high_volume_event',
          ruleName: 'sampling_rule',
        );

        expect(exception.message, equals('Event rejected by sampling'));
        expect(exception.code, equals('SAMPLED_OUT'));
        expect(exception.eventName, equals('high_volume_event'));
        expect(exception.ruleName, equals('sampling_rule'));
      });
    });

    group('Edge Cases', () {
      test('should handle very long strings', () {
        final longMessage = 'A' * 1000;
        final longEventName = 'B' * 500;
        final longRuleName = 'C' * 500;

        final exception = RoutingException(
          longMessage,
          eventName: longEventName,
          ruleName: longRuleName,
        );

        expect(exception.message, equals(longMessage));
        expect(exception.eventName, equals(longEventName));
        expect(exception.ruleName, equals(longRuleName));

        final result = exception.toString();
        expect(result, contains(longMessage));
        expect(result, contains('Event: $longEventName'));
        expect(result, contains('Rule: $longRuleName'));
      });

      test('should handle special characters in names', () {
        final exception = RoutingException(
          'Special character test',
          eventName: 'event-with_special.chars@123',
          ruleName: 'rule/with\\special*chars?',
        );

        final result = exception.toString();
        expect(result, contains('Event: event-with_special.chars@123'));
        expect(result, contains('Rule: rule/with\\special*chars?'));
      });

      test('should handle unicode characters', () {
        final exception = RoutingException(
          'Unicode test 🚀',
          eventName: 'événement_unicode_测试',
          ruleName: 'règle_unicode_テスト',
        );

        final result = exception.toString();
        expect(result, contains('Unicode test 🚀'));
        expect(result, contains('Event: événement_unicode_测试'));
        expect(result, contains('Rule: règle_unicode_テスト'));
      });
    });
  });
}
