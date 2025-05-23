import 'package:flex_track/src/core/event_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('EventProcessor Tests', () {
    late TrackerRegistry trackerRegistry;
    late RoutingEngine routingEngine;
    late EventProcessor eventProcessor;
    late MockTracker mockTracker;

    setUp(() {
      mockTracker = MockTracker(id: 'test_tracker', name: 'Test Tracker');
      trackerRegistry = TrackerRegistry();
      trackerRegistry.register(mockTracker);

      final routingConfig = RoutingConfiguration(
        rules: [
          RoutingRule(
            isDefault: true,
            targetGroup: TrackerGroup.all,
          ),
        ],
      );

      routingEngine = RoutingEngine(routingConfig);
      eventProcessor = EventProcessor(
        trackerRegistry: trackerRegistry,
        routingEngine: routingEngine,
      );
    });

    group('Enable/Disable Functionality', () {
      test('should enable processor', () {
        eventProcessor.disable();
        expect(eventProcessor.isEnabled, isFalse);

        eventProcessor.enable();
        expect(eventProcessor.isEnabled, isTrue);
      });

      test('should disable processor', () {
        expect(eventProcessor.isEnabled, isTrue);

        eventProcessor.disable();
        expect(eventProcessor.isEnabled, isFalse);
      });

      test('should not process events when disabled', () async {
        eventProcessor.disable();

        final event = _TestEvent('disabled_test');
        final result = await eventProcessor.processEvent(event);

        expect(result.successful, isFalse);
        expect(result.routingResult.warnings,
            contains('Event processor is disabled'));
        expect(result.trackingResults, isEmpty);
      });
    });

    group('Consent Management', () {
      test('should set general consent', () {
        eventProcessor.setGeneralConsent(false);
        expect(eventProcessor.hasGeneralConsent, isFalse);

        eventProcessor.setGeneralConsent(true);
        expect(eventProcessor.hasGeneralConsent, isTrue);
      });

      test('should set PII consent', () {
        eventProcessor.setPIIConsent(false);
        expect(eventProcessor.hasPIIConsent, isFalse);

        eventProcessor.setPIIConsent(true);
        expect(eventProcessor.hasPIIConsent, isTrue);
      });

      test('should set both consent types at once', () {
        eventProcessor.setConsent(general: false, pii: true);
        expect(eventProcessor.hasGeneralConsent, isFalse);
        expect(eventProcessor.hasPIIConsent, isTrue);

        eventProcessor.setConsent(general: true, pii: false);
        expect(eventProcessor.hasGeneralConsent, isTrue);
        expect(eventProcessor.hasPIIConsent, isFalse);
      });

      test('should set only specified consent types', () {
        // Initial state
        eventProcessor.setConsent(general: true, pii: true);

        // Change only general consent
        eventProcessor.setConsent(general: false);
        expect(eventProcessor.hasGeneralConsent, isFalse);
        expect(eventProcessor.hasPIIConsent, isTrue); // Should remain unchanged

        // Change only PII consent
        eventProcessor.setConsent(pii: false);
        expect(eventProcessor.hasGeneralConsent,
            isFalse); // Should remain unchanged
        expect(eventProcessor.hasPIIConsent, isFalse);
      });
    });

    group('Event Processing Error Cases', () {
      test('should handle tracker not found error', () async {
        // Create routing that targets non-existent tracker
        final routingConfig = RoutingConfiguration(
          rules: [
            RoutingRule(
              isDefault: true,
              targetGroup: TrackerGroup('missing', ['nonexistent_tracker']),
            ),
          ],
        );

        final processor = EventProcessor(
          trackerRegistry: trackerRegistry,
          routingEngine: RoutingEngine(routingConfig),
        );

        final event = _TestEvent('not_found_test');
        final result = await processor.processEvent(event);

        expect(result.successful, isFalse);
        expect(result.trackingResults, hasLength(0));
      });

      test('should handle disabled tracker', () async {
        // Disable the tracker
        mockTracker.disable();
        await trackerRegistry.initialize();

        final event = _TestEvent('disabled_tracker_test');
        final result = await eventProcessor.processEvent(event);

        expect(result.successful, isFalse);
        expect(result.trackingResults, hasLength(1));
        expect(result.trackingResults.first.successful, isFalse);
        expect(result.trackingResults.first.error, isA<TrackerException>());
        expect(result.trackingResults.first.error!.toString(),
            contains('Tracker is disabled'));
        expect((result.trackingResults.first.error as TrackerException).code,
            equals('DISABLED'));
      });

      test('should handle tracker throwing non-TrackerException', () async {
        // Create a tracker that throws a regular exception
        final failingTracker = _NonTrackerExceptionTracker();
        trackerRegistry.register(failingTracker);
        await trackerRegistry.initialize();

        final event = _TestEvent('non_tracker_exception_test');
        final result = await eventProcessor.processEvent(event);

        expect(result.successful, isTrue); // mockTracker should still succeed
        expect(result.trackingResults, hasLength(2));

        // Find the failing tracker result
        final failingResult = result.trackingResults
            .firstWhere((r) => r.trackerId == 'failing_non_tracker');

        expect(failingResult.successful, isFalse);
        expect(failingResult.error, isA<TrackerException>());
        expect(
            failingResult.error!.toString(), contains('Failed to track event'));
        expect((failingResult.error as TrackerException).originalError,
            isA<Exception>());
      });

      test('should handle tracker throwing TrackerException', () async {
        // Create a tracker that throws TrackerException
        final failingTracker = _TrackerExceptionTracker();
        trackerRegistry.register(failingTracker);
        await trackerRegistry.initialize();

        final event = _TestEvent('tracker_exception_test');
        final result = await eventProcessor.processEvent(event);

        expect(result.successful, isTrue); // mockTracker should still succeed
        expect(result.trackingResults, hasLength(2));

        // Find the failing tracker result
        final failingResult = result.trackingResults
            .firstWhere((r) => r.trackerId == 'failing_tracker_exception');

        expect(failingResult.successful, isFalse);
        expect(failingResult.error, isA<TrackerException>());
        expect(
            failingResult.error!.toString(), contains('Custom tracker error'));
      });
    });

    group('EventProcessingResult Coverage', () {
      test('should test wasRouted property', () async {
        await trackerRegistry.initialize();

        // Test with successful routing
        final event = _TestEvent('routed_test');
        final result = await eventProcessor.processEvent(event);

        expect(result.wasRouted, isTrue);
        expect(result.routingResult.targetTrackers, isNotEmpty);

        // Test with no routing (empty target trackers)
        final emptyRoutingConfig = RoutingConfiguration(rules: []);
        final emptyProcessor = EventProcessor(
          trackerRegistry: trackerRegistry,
          routingEngine: RoutingEngine(emptyRoutingConfig),
        );

        final emptyResult = await emptyProcessor.processEvent(event);
        expect(emptyResult.wasRouted, isFalse);
        expect(emptyResult.routingResult.targetTrackers, isEmpty);
      });

      test('should test toString method', () async {
        await trackerRegistry.initialize();

        final event = _TestEvent('toString_test');
        final result = await eventProcessor.processEvent(event);

        final stringResult = result.toString();
        expect(stringResult, contains('EventProcessingResult'));
        expect(stringResult, contains(event.getName()));
        expect(stringResult, contains('routed: true'));
        expect(stringResult, contains('tracked: true'));
        expect(stringResult, contains('successful: 1/1'));
      });

      test('should test toMap method', () async {
        await trackerRegistry.initialize();

        final event = _TestEvent('toMap_test');
        final result = await eventProcessor.processEvent(event);

        final map = result.toMap();
        expect(map, isA<Map<String, dynamic>>());
        expect(map['event'], isA<Map<String, dynamic>>());
        expect(map['routingResult'], isA<Map<String, dynamic>>());
        expect(map['trackingResults'], isA<List>());
        expect(map['successful'], isA<bool>());
        expect(map['wasRouted'], isA<bool>());
        expect(map['wasTracked'], isA<bool>());
        expect(map['successfulTrackingCount'], isA<int>());
        expect(map['failedTrackingCount'], isA<int>());
        expect(map['hasErrors'], isA<bool>());
      });
    });

    group('TrackingResult Coverage', () {
      test('should test TrackingResult toMap method', () {
        final result = TrackingResult(
          trackerId: 'test_tracker',
          successful: true,
        );

        final map = result.toMap();
        expect(map, isA<Map<String, dynamic>>());
        expect(map['trackerId'], equals('test_tracker'));
        expect(map['successful'], isTrue);
        expect(map['error'], isNull);
        expect(map['timestamp'], isA<String>());
      });

      test('should test TrackingResult toString method', () {
        final successResult = TrackingResult(
          trackerId: 'success_tracker',
          successful: true,
        );

        final failResult = TrackingResult(
          trackerId: 'fail_tracker',
          successful: false,
          error: Exception('Test error'),
        );

        expect(successResult.toString(), contains('success_tracker: success'));
        expect(failResult.toString(), contains('fail_tracker: failed'));
      });

      test('should test TrackingResult with error', () {
        final error = TrackerException('Test error', trackerId: 'test');
        final result = TrackingResult(
          trackerId: 'error_tracker',
          successful: false,
          error: error,
        );

        expect(result.error, equals(error));
        expect(result.toMap()['error'], contains('Test error'));
      });
    });
  });
}

// Test helper classes
class _TestEvent extends BaseEvent {
  final String eventName;

  _TestEvent(this.eventName);

  @override
  String getName() => eventName;

  @override
  Map<String, Object>? getProperties() => {'test': 'value'};
}

class _NonTrackerExceptionTracker extends BaseTrackerStrategy {
  _NonTrackerExceptionTracker()
      : super(
          id: 'failing_non_tracker',
          name: 'Failing Non-Tracker Exception',
        );

  @override
  Future<void> doInitialize() async {}

  @override
  Future<void> doTrack(BaseEvent event) async {
    throw Exception('Regular exception from tracker');
  }
}

class _TrackerExceptionTracker extends BaseTrackerStrategy {
  _TrackerExceptionTracker()
      : super(
          id: 'failing_tracker_exception',
          name: 'Failing Tracker Exception',
        );

  @override
  Future<void> doInitialize() async {}

  @override
  Future<void> doTrack(BaseEvent event) async {
    throw TrackerException(
      'Custom tracker error',
      trackerId: id,
      eventName: event.getName(),
    );
  }
}
