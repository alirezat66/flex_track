import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

// Concrete implementation for testing abstract FlexTrackException
class _TestFlexTrackException extends FlexTrackException {
  const _TestFlexTrackException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

void main() {
  group('FlexTrackException Tests', () {
    group('toString Method', () {
      test('should format basic exception correctly', () {
        final exception = _TestFlexTrackException('Basic error message');

        final result = exception.toString();

        expect(result, contains('_TestFlexTrackException'));
        expect(result, contains('Basic error message'));
      });

      test('should include error code when provided', () {
        final exception = _TestFlexTrackException(
          'Error with code',
          code: 'TEST_CODE',
        );

        final result = exception.toString();

        expect(result, contains('_TestFlexTrackException(TEST_CODE)'));
        expect(result, contains('Error with code'));
      });

      test('should include original error when provided', () {
        final originalError = Exception('Original cause');
        final exception = _TestFlexTrackException(
          'Wrapper error',
          originalError: originalError,
        );

        final result = exception.toString();

        expect(result, contains('Wrapper error'));
        expect(result, contains('Caused by: Exception: Original cause'));
      });

      test('should format complete exception with all fields', () {
        final originalError = ArgumentError('Invalid argument');
        final exception = _TestFlexTrackException(
          'Complete error',
          code: 'COMPLETE_ERROR',
          originalError: originalError,
        );

        final result = exception.toString();

        expect(result, contains('_TestFlexTrackException(COMPLETE_ERROR)'));
        expect(result, contains('Complete error'));
        expect(result, contains('Caused by: Invalid argument'));
      });

      test('should handle null original error gracefully', () {
        final exception = _TestFlexTrackException(
          'Error without cause',
          originalError: null,
        );

        final result = exception.toString();

        expect(result, contains('Error without cause'));
        expect(result, isNot(contains('Caused by:')));
      });

      test('should show correct runtime type', () {
        final trackingException = TrackerException('Tracker error');
        final configException = ConfigurationException('Config error');
        final routingException = RoutingException('Routing error');

        expect(trackingException.toString(), contains('TrackerException'));
        expect(configException.toString(), contains('ConfigurationException'));
        expect(routingException.toString(), contains('RoutingException'));
      });
    });

    group('Exception Properties', () {
      test('should store all properties correctly', () {
        final originalError = Exception('Test error');
        final stackTrace = StackTrace.current;

        final exception = _TestFlexTrackException(
          'Test message',
          code: 'TEST_CODE',
          originalError: originalError,
          stackTrace: stackTrace,
        );

        expect(exception.message, equals('Test message'));
        expect(exception.code, equals('TEST_CODE'));
        expect(exception.originalError, equals(originalError));
        expect(exception.stackTrace, equals(stackTrace));
      });

      test('should handle optional parameters as null', () {
        final exception = _TestFlexTrackException('Simple message');

        expect(exception.message, equals('Simple message'));
        expect(exception.code, isNull);
        expect(exception.originalError, isNull);
        expect(exception.stackTrace, isNull);
      });
    });
  });

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

      test('should include original error when provided', () {
        final originalError = ArgumentError('Invalid routing configuration');
        final exception = RoutingException(
          'Routing configuration error',
          originalError: originalError,
        );

        final result = exception.toString();

        expect(result, contains('Routing configuration error'));
        expect(result, contains('Caused by: Invalid argument(s): Invalid routing configuration'));
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

      test('should handle empty strings gracefully', () {
        final exception = RoutingException(
          'Error with empty strings',
          eventName: '',
          ruleName: '',
        );

        final result = exception.toString();

        expect(result, contains('Error with empty strings'));
        // Empty strings should still show the labels
        expect(result, contains('Event:'));
        expect(result, contains('Rule:'));
      });
    });

    group('Exception Interface', () {
      test('should implement FlexTrackException correctly', () {
        final exception = RoutingException('Test routing error');

        expect(exception, isA<FlexTrackException>());
        expect(exception, isA<Exception>());
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

        final result = exception.toString();

        expect(result, contains('RoutingException(NO_MATCHING_RULES)'));
        expect(result, contains('Failed to route event to trackers'));
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

        final result = exception.toString();

        expect(result, contains('RoutingException(RULE_EVALUATION_ERROR)'));
        expect(result, contains('Rule evaluation failed'));
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
    });
  });
}
