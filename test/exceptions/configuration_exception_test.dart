import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('ConfigurationException Tests', () {
    group('toString Method', () {
      test('should format basic exception correctly', () {
        final exception = ConfigurationException('Basic error message');

        final result = exception.toString();

        expect(result, contains('ConfigurationException'));
        expect(result, contains('Basic error message'));
      });

      test('should include error code when provided', () {
        final exception = ConfigurationException(
          'Error with code',
          code: 'TEST_CODE',
        );

        final result = exception.toString();

        expect(result, contains('ConfigurationException(TEST_CODE)'));
        expect(result, contains('Error with code'));
      });

      test('should include configuration type when provided', () {
        final exception = ConfigurationException(
          'Type-specific error',
          configType: 'RoutingConfig',
        );

        final result = exception.toString();

        expect(result, contains('Configuration Type: RoutingConfig'));
        expect(result, contains('Type-specific error'));
      });

      test('should include field name when provided', () {
        final exception = ConfigurationException(
          'Field validation error',
          fieldName: 'sampleRate',
        );

        final result = exception.toString();

        expect(result, contains('Field: sampleRate'));
        expect(result, contains('Field validation error'));
      });

      test('should include original error when provided', () {
        final originalError = Exception('Original cause');
        final exception = ConfigurationException(
          'Wrapper error',
          originalError: originalError,
        );

        final result = exception.toString();

        expect(result, contains('Wrapper error'));
        expect(result, contains('Caused by: Exception: Original cause'));
      });

      test('should format complete exception with all fields', () {
        final originalError = ArgumentError('Invalid argument');
        final exception = ConfigurationException(
          'Complete configuration error',
          code: 'INVALID_CONFIG',
          configType: 'TrackerRegistry',
          fieldName: 'trackerId',
          originalError: originalError,
        );

        final result = exception.toString();

        expect(result, contains('ConfigurationException(INVALID_CONFIG)'));
        expect(result, contains('Complete configuration error'));
        expect(result, contains('Configuration Type: TrackerRegistry'));
        expect(result, contains('Field: trackerId'));
        expect(result, contains('Caused by: Invalid argument'));
      });

      test('should handle null original error gracefully', () {
        final exception = ConfigurationException(
          'Error without cause',
          originalError: null,
        );

        final result = exception.toString();

        expect(result, contains('Error without cause'));
        expect(result, isNot(contains('Caused by:')));
      });

      test('should handle empty strings gracefully', () {
        final exception = ConfigurationException(
          'Error with empty fields',
          code: '',
          configType: '',
          fieldName: '',
        );

        final result = exception.toString();

        expect(result, contains('Error with empty fields'));
        // Should not include empty sections
        expect(result, isNot(contains('Configuration Type: \n')));
        expect(result, isNot(contains('Field: \n')));
      });

      test('should format stack trace when provided', () {
        final stackTrace = StackTrace.current;
        final exception = ConfigurationException(
          'Error with stack trace',
          stackTrace: stackTrace,
        );

        // The toString method doesn't include stack trace in the output
        // but it should be stored in the exception
        expect(exception.stackTrace, equals(stackTrace));

        final result = exception.toString();
        expect(result, contains('Error with stack trace'));
      });

      test('should handle complex original error types', () {
        final originalError = ConfigurationException(
          'Nested configuration error',
          code: 'NESTED_ERROR',
        );

        final exception = ConfigurationException(
          'Outer error',
          code: 'OUTER_ERROR',
          originalError: originalError,
        );

        final result = exception.toString();

        expect(result, contains('ConfigurationException(OUTER_ERROR)'));
        expect(result, contains('Outer error'));
        expect(result,
            contains('Caused by: ConfigurationException(NESTED_ERROR)'));
        expect(result, contains('Nested configuration error'));
      });
    });

    group('Exception Properties', () {
      test('should store all properties correctly', () {
        final originalError = Exception('Test error');
        final stackTrace = StackTrace.current;

        final exception = ConfigurationException(
          'Test message',
          code: 'TEST_CODE',
          configType: 'TestConfig',
          fieldName: 'testField',
          originalError: originalError,
          stackTrace: stackTrace,
        );

        expect(exception.message, equals('Test message'));
        expect(exception.code, equals('TEST_CODE'));
        expect(exception.configType, equals('TestConfig'));
        expect(exception.fieldName, equals('testField'));
        expect(exception.originalError, equals(originalError));
        expect(exception.stackTrace, equals(stackTrace));
      });

      test('should handle optional parameters as null', () {
        final exception = ConfigurationException('Simple message');

        expect(exception.message, equals('Simple message'));
        expect(exception.code, isNull);
        expect(exception.configType, isNull);
        expect(exception.fieldName, isNull);
        expect(exception.originalError, isNull);
        expect(exception.stackTrace, isNull);
      });
    });

    group('FlexTrackException Interface', () {
      test('should implement FlexTrackException correctly', () {
        final exception = ConfigurationException('Test message');

        expect(exception, isA<FlexTrackException>());
        expect(exception.message, equals('Test message'));
      });

      test('should be throwable as Exception', () {
        expect(() {
          throw ConfigurationException('Test throw');
        }, throwsA(isA<ConfigurationException>()));
      });
    });
  });
}
