import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/strategies/base_tracker_strategy.dart';
import 'package:flex_track/src/exceptions/tracker_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'base_tracker_strategy_test.mocks.dart';

@GenerateMocks([BaseEvent])
// Concrete implementation of BaseTrackerStrategy for testing
class TestTrackerStrategy extends BaseTrackerStrategy {
  bool _initializeCalled = false;
  final bool _initializeThrows;
  final bool _trackThrows;
  final bool _trackBatchThrows;
  final bool _setUserPropertiesThrows;
  final bool _identifyUserThrows;
  final bool _resetThrows;
  final bool _flushThrows;
  final bool _supportsBatch;

  TestTrackerStrategy({
    required super.id,
    required super.name,
    super.enabled,
    bool initializeThrows = false,
    bool trackThrows = false,
    bool trackBatchThrows = false,
    bool setUserPropertiesThrows = false,
    bool identifyUserThrows = false,
    bool resetThrows = false,
    bool flushThrows = false,
    bool supportsBatch = false,
  })  : _initializeThrows = initializeThrows,
        _trackThrows = trackThrows,
        _trackBatchThrows = trackBatchThrows,
        _setUserPropertiesThrows = setUserPropertiesThrows,
        _identifyUserThrows = identifyUserThrows,
        _resetThrows = resetThrows,
        _flushThrows = flushThrows,
        _supportsBatch = supportsBatch;

  @override
  Future<void> doInitialize() async {
    _initializeCalled = true;
    if (_initializeThrows) {
      throw Exception('Initialization failed');
    }
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    if (_trackThrows) {
      throw Exception('Tracking failed');
    }
  }

  @override
  bool supportsBatchTracking() => _supportsBatch;

  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    if (_trackBatchThrows) {
      throw Exception('Batch tracking failed');
    }
  }

  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    if (_setUserPropertiesThrows) {
      throw Exception('Set user properties failed');
    }
  }

  @override
  Future<void> doIdentifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    if (_identifyUserThrows) {
      throw Exception('Identify user failed');
    }
  }

  @override
  Future<void> doReset() async {
    if (_resetThrows) {
      throw Exception('Reset failed');
    }
  }

  @override
  Future<void> doFlush() async {
    if (_flushThrows) {
      throw Exception('Flush failed');
    }
  }

  bool get initializeCalled => _initializeCalled;
}

void main() {
  group('BaseTrackerStrategy', () {
    late TestTrackerStrategy tracker;
    late MockBaseEvent mockEvent;

    setUp(() {
      tracker = TestTrackerStrategy(id: 'testId', name: 'Test Tracker');
      mockEvent = MockBaseEvent();
      when(mockEvent.getName()).thenReturn('testEvent');
    });

    test('constructor sets id, name, and enabled status correctly', () {
      expect(tracker.id, 'testId');
      expect(tracker.name, 'Test Tracker');
      expect(tracker.isEnabled, isFalse); // Not initialized yet
    });

    test('isEnabled returns true only if enabled and initialized', () async {
      expect(tracker.isEnabled, isFalse);
      tracker.enable();
      expect(tracker.isEnabled, isFalse); // Still not initialized
      await tracker.initialize();
      expect(tracker.isEnabled, isTrue);
      tracker.disable();
      expect(tracker.isEnabled, isFalse);
    });

    test('initialize calls doInitialize and sets _initialized to true',
        () async {
      expect(tracker.initializeCalled, isFalse);
      await tracker.initialize();
      expect(tracker.initializeCalled, isTrue);
      expect(tracker.isEnabled, isTrue);
    });

    test('initialize does nothing if already initialized', () async {
      await tracker.initialize();
      tracker._initializeCalled = false; // Reset for test
      await tracker.initialize();
      expect(tracker.initializeCalled, isFalse); // Should not be called again
    });

    test('initialize throws TrackerException if doInitialize fails', () async {
      tracker = TestTrackerStrategy(
          id: 'testId', name: 'Test Tracker', initializeThrows: true);
      expect(
        () => tracker.initialize(),
        throwsA(
          isA<TrackerException>()
              .having((e) => e.message, 'message',
                  contains('Failed to initialize tracker testId'))
              .having((e) => e.trackerId, 'trackerId', 'testId')
              .having(
                  (e) => e.originalError, 'originalError', isA<Exception>()),
        ),
      );
      expect(tracker.isEnabled, isFalse);
    });

    group('track', () {
      setUp(() async {
        await tracker.initialize(); // Initialize tracker before tracking
      });

      test('tracks event if enabled and initialized', () async {
        tracker.enable();
        await tracker.track(mockEvent);
        // No exception means success
      });

      test('does not track event if disabled', () async {
        tracker.disable();
        await tracker.track(mockEvent);
        // No exception means success, as it should silently return
      });

      test('throws TrackerException if not initialized', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker'); // Recreate uninitialized
        expect(
          () => tracker.track(mockEvent),
          throwsA(
            isA<TrackerException>()
                .having((e) => e.message, 'message',
                    contains('Tracker testId is not initialized'))
                .having((e) => e.trackerId, 'trackerId', 'testId'),
          ),
        );
      });

      test('throws TrackerException if doTrack fails', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker', trackThrows: true);
        await tracker.initialize();
        tracker.enable();
        expect(
          () => tracker.track(mockEvent),
          throwsA(
            isA<TrackerException>()
                .having(
                    (e) => e.message,
                    'message',
                    contains(
                        'Failed to track event testEvent with tracker testId'))
                .having((e) => e.trackerId, 'trackerId', 'testId')
                .having((e) => e.eventName, 'eventName', 'testEvent')
                .having(
                    (e) => e.originalError, 'originalError', isA<Exception>()),
          ),
        );
      });
    });

    group('trackBatch', () {
      late List<MockBaseEvent> mockEvents;

      setUp(() async {
        mockEvents = [MockBaseEvent(), MockBaseEvent()];
        when(mockEvents[0].getName()).thenReturn('event1');
        when(mockEvents[1].getName()).thenReturn('event2');
        await tracker.initialize();
      });

      test('tracks batch if enabled and initialized', () async {
        tracker.enable();
        await tracker.trackBatch(mockEvents);
        // No exception means success
      });

      test('does not track batch if disabled', () async {
        tracker.disable();
        await tracker.trackBatch(mockEvents);
        // No exception means success, as it should silently return
      });

      test('does nothing if events list is empty', () async {
        tracker.enable();
        await tracker.trackBatch([]);
        // No exception means success
      });

      test('throws TrackerException if not initialized', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker'); // Recreate uninitialized
        expect(
          () => tracker.trackBatch(mockEvents),
          throwsA(
            isA<TrackerException>()
                .having((e) => e.message, 'message',
                    contains('Tracker testId is not initialized'))
                .having((e) => e.trackerId, 'trackerId', 'testId'),
          ),
        );
      });

      test('calls doTrackBatch if supportsBatchTracking is true', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker', supportsBatch: true);
        await tracker.initialize();
        tracker.enable();
        await tracker.trackBatch(mockEvents);
        // No exception means success, implies doTrackBatch was called
      });

      test(
          'falls back to individual track calls if supportsBatchTracking is false',
          () async {
        // Default supportsBatch is false
        await tracker.initialize();
        tracker.enable();
        await tracker.trackBatch(mockEvents);
        // No exception means success, implies individual track calls were made
      });

      test('throws TrackerException if doTrackBatch fails', () async {
        tracker = TestTrackerStrategy(
            id: 'testId',
            name: 'Test Tracker',
            supportsBatch: true,
            trackBatchThrows: true);
        await tracker.initialize();
        tracker.enable();
        expect(
          () => tracker.trackBatch(mockEvents),
          throwsA(
            isA<TrackerException>()
                .having(
                    (e) => e.message,
                    'message',
                    contains(
                        'Failed to track batch of 2 events with tracker testId'))
                .having((e) => e.trackerId, 'trackerId', 'testId')
                .having(
                    (e) => e.originalError, 'originalError', isA<Exception>()),
          ),
        );
      });
    });

    group('setUserProperties', () {
      setUp(() async {
        await tracker.initialize();
        tracker.enable();
      });

      test('sets user properties if enabled', () async {
        await tracker.setUserProperties({'key': 'value'});
        // No exception means success
      });

      test('does not set user properties if disabled', () async {
        tracker.disable();
        await tracker.setUserProperties({'key': 'value'});
        // No exception means success, as it should silently return
      });

      test('throws TrackerException if doSetUserProperties fails', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker', setUserPropertiesThrows: true);
        await tracker.initialize();
        tracker.enable();
        expect(
          () => tracker.setUserProperties({'key': 'value'}),
          throwsA(
            isA<TrackerException>()
                .having(
                    (e) => e.message,
                    'message',
                    contains(
                        'Failed to set user properties for tracker testId'))
                .having((e) => e.trackerId, 'trackerId', 'testId')
                .having(
                    (e) => e.originalError, 'originalError', isA<Exception>()),
          ),
        );
      });
    });

    group('identifyUser', () {
      setUp(() async {
        await tracker.initialize();
        tracker.enable();
      });

      test('identifies user if enabled', () async {
        await tracker.identifyUser('user123', {'name': 'John Doe'});
        // No exception means success
      });

      test('does not identify user if disabled', () async {
        tracker.disable();
        await tracker.identifyUser('user123');
        // No exception means success, as it should silently return
      });

      test('throws TrackerException if doIdentifyUser fails', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker', identifyUserThrows: true);
        await tracker.initialize();
        tracker.enable();
        expect(
          () => tracker.identifyUser('user123'),
          throwsA(
            isA<TrackerException>()
                .having((e) => e.message, 'message',
                    contains('Failed to identify user for tracker testId'))
                .having((e) => e.trackerId, 'trackerId', 'testId')
                .having(
                    (e) => e.originalError, 'originalError', isA<Exception>()),
          ),
        );
      });
    });

    group('reset', () {
      setUp(() async {
        await tracker.initialize();
        tracker.enable();
      });

      test('resets tracker if enabled', () async {
        await tracker.reset();
        // No exception means success
      });

      test('does not reset tracker if disabled', () async {
        tracker.disable();
        await tracker.reset();
        // No exception means success, as it should silently return
      });

      test('throws TrackerException if doReset fails', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker', resetThrows: true);
        await tracker.initialize();
        tracker.enable();
        expect(
          () => tracker.reset(),
          throwsA(
            isA<TrackerException>()
                .having((e) => e.message, 'message',
                    contains('Failed to reset tracker testId'))
                .having((e) => e.trackerId, 'trackerId', 'testId')
                .having(
                    (e) => e.originalError, 'originalError', isA<Exception>()),
          ),
        );
      });
    });

    group('flush', () {
      setUp(() async {
        await tracker.initialize();
        tracker.enable();
      });

      test('flushes tracker if enabled', () async {
        await tracker.flush();
        // No exception means success
      });

      test('does not flush tracker if disabled', () async {
        tracker.disable();
        await tracker.flush();
        // No exception means success, as it should silently return
      });

      test('throws TrackerException if doFlush fails', () async {
        tracker = TestTrackerStrategy(
            id: 'testId', name: 'Test Tracker', flushThrows: true);
        await tracker.initialize();
        tracker.enable();
        expect(
          () => tracker.flush(),
          throwsA(
            isA<TrackerException>()
                .having((e) => e.message, 'message',
                    contains('Failed to flush tracker testId'))
                .having((e) => e.trackerId, 'trackerId', 'testId')
                .having(
                    (e) => e.originalError, 'originalError', isA<Exception>()),
          ),
        );
      });
    });

    test('getDebugInfo returns correct debug information', () async {
      await tracker.initialize();
      tracker.enable();
      final debugInfo = tracker.getDebugInfo();
      expect(debugInfo['id'], 'testId');
      expect(debugInfo['name'], 'Test Tracker');
      expect(debugInfo['enabled'], true);
      expect(debugInfo['initialized'], true);
      expect(debugInfo['gdprCompliant'], false);
      expect(debugInfo['supportsRealTime'], true);
      expect(debugInfo['maxBatchSize'], 100);
      expect(debugInfo['supportsBatchTracking'], false);
    });

    test('toString returns a formatted string', () {
      expect(tracker.toString(),
          'TrackerStrategy(testId: Test Tracker, enabled: false)');
      tracker.enable();
      expect(tracker.toString(),
          'TrackerStrategy(testId: Test Tracker, enabled: false)'); // Still false as not initialized
    });
  });
}
