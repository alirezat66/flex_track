import 'package:flex_track/src/exceptions/tracker_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackerException', () {
    test('should create an instance with a message', () {
      const exception = TrackerException('Test message');
      expect(exception, isA<TrackerException>());
      expect(exception.message, 'Test message');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
      expect(exception.stackTrace, isNull);
      expect(exception.trackerId, isNull);
      expect(exception.eventName, isNull);
    });

    test('should create an instance with all properties', () {
      final originalError = Exception('Original error');
      final stackTrace = StackTrace.current;
      final exception = TrackerException(
        'Detailed message',
        code: 'TRACKER_ERROR_001',
        originalError: originalError,
        stackTrace: stackTrace,
        trackerId: 'testTracker',
        eventName: 'testEvent',
      );

      expect(exception.message, 'Detailed message');
      expect(exception.code, 'TRACKER_ERROR_001');
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception.trackerId, 'testTracker');
      expect(exception.eventName, 'testEvent');
    });

    test('toString should return a formatted string with message only', () {
      const exception = TrackerException('Simple message');
      expect(exception.toString(), 'TrackerException: Simple message');
    });

    test('toString should include code if present', () {
      const exception = TrackerException('Message with code', code: 'CODE_123');
      expect(exception.toString(),
          'TrackerException(CODE_123): Message with code');
    });

    test('toString should include trackerId if present', () {
      const exception = TrackerException('Message', trackerId: 'myTracker');
      expect(exception.toString(),
          'TrackerException: Message\nTracker ID: myTracker');
    });

    test('toString should include eventName if present', () {
      const exception = TrackerException('Message', eventName: 'myEvent');
      expect(exception.toString(), 'TrackerException: Message\nEvent: myEvent');
    });

    test('toString should include originalError if present', () {
      final originalError = ArgumentError('Invalid arg');
      final exception =
          TrackerException('Message', originalError: originalError);
      expect(exception.toString(),
          'TrackerException: Message\nCaused by: $originalError');
    });

    test('toString should include all optional fields if present', () {
      final originalError = StateError('Bad state');
      final stackTrace = StackTrace.current;
      final exception = TrackerException(
        'Full message',
        code: 'FULL_CODE',
        originalError: originalError,
        stackTrace: stackTrace,
        trackerId: 'fullTracker',
        eventName: 'fullEvent',
      );

      final expectedString = 'TrackerException(FULL_CODE): Full message\n'
          'Tracker ID: fullTracker\n'
          'Event: fullEvent\n'
          'Caused by: $originalError';
      expect(exception.toString(), expectedString);
    });
  });
}
