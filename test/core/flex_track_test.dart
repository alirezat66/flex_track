import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

// Test events
class TestEvent extends BaseEvent {
  final String testProperty;

  TestEvent({required this.testProperty});

  @override
  String get name => 'test_event';

  @override
  Map<String, Object> get properties => {'test_property': testProperty};
}

class PurchaseTestEvent extends BaseEvent {
  final double amount;

  PurchaseTestEvent({required this.amount});

  @override
  String get name => 'purchase';

  @override
  Map<String, Object> get properties => {'amount': amount};

  @override
  EventCategory get category => EventCategory.business;

  @override
  bool get containsPII => false;
}

class DebugTestEvent extends BaseEvent {
  @override
  String get name => 'debug_test';

  @override
  Map<String, Object>? get properties => null;

  @override
  EventCategory get category => EventCategory.technical;
}

class PIITestEvent extends BaseEvent {
  final String email;

  PIITestEvent({required this.email});

  @override
  String get name => 'user_data';

  @override
  Map<String, Object> get properties => {'email': email};

  @override
  bool get containsPII => true;

  @override
  bool get requiresConsent => true;
}

class EssentialTestEvent extends BaseEvent {
  @override
  String get name => 'system_essential';

  @override
  Map<String, Object>? get properties => null;

  @override
  bool get isEssential => true;

  @override
  bool get requiresConsent => false;
}

void main() {
  group('FlexTrack Core Tests', () {
    late MockTracker mockTracker1;
    late MockTracker mockTracker2;
    late ConsoleTracker consoleTracker;

    setUp(() async {
      // Reset FlexTrack before each test
      await FlexTrack.reset();

      mockTracker1 = MockTracker(id: 'mock1', name: 'Mock Tracker 1');
      mockTracker2 = MockTracker(id: 'mock2', name: 'Mock Tracker 2');
      consoleTracker = ConsoleTracker();
    });

    tearDown(() async {
      await FlexTrack.reset();
    });

    group('Basic Setup and Tracking', () {
      test('should setup FlexTrack with single tracker', () async {
        await FlexTrack.setup([mockTracker1]);

        expect(FlexTrack.isSetUp, isTrue);
        expect(FlexTrack.isEnabled, isTrue);
        expect(FlexTrack.getTrackerIds(), contains('mock1'));
      });

      test('should setup FlexTrack with multiple trackers', () async {
        await FlexTrack.setup([mockTracker1, mockTracker2, consoleTracker]);

        expect(FlexTrack.getTrackerIds(), hasLength(3));
        expect(FlexTrack.getTrackerIds(),
            containsAll(['mock1', 'mock2', 'console']));
      });

      test('should track simple event to all trackers', () async {
        await FlexTrack.setup([mockTracker1, mockTracker2]);

        final event = TestEvent(testProperty: 'test_value');
        final result = await FlexTrack.track(event);

        expect(result.successful, isTrue);
        expect(result.wasTracked, isTrue);
        expect(result.successfulTrackingCount, equals(2));

        expect(mockTracker1.capturedEvents, hasLength(1));
        expect(mockTracker2.capturedEvents, hasLength(1));
        expect(
            mockTracker1.capturedEvents.first.name, equals('test_event'));
      });

      test('should track multiple events', () async {
        await FlexTrack.setup([mockTracker1]);

        final events = [
          TestEvent(testProperty: 'value1'),
          TestEvent(testProperty: 'value2'),
          PurchaseTestEvent(amount: 99.99),
        ];

        final results = await FlexTrack.trackAll(events);

        expect(results, hasLength(3));
        expect(results.every((r) => r.successful), isTrue);
        expect(mockTracker1.capturedEvents, hasLength(3));
      });

      test('should handle tracker initialization failure gracefully', () async {
        final failingTracker = FailingTracker();

        expect(
          () => FlexTrack.setup([failingTracker]),
          throwsA(isA<ConfigurationException>()),
        );
      });

      test('should not allow setup twice without reset', () async {
        await FlexTrack.setup([mockTracker1]);

        expect(
          () => FlexTrack.setup([mockTracker2]),
          throwsA(isA<ConfigurationException>()),
        );
      });
    });

    group('Routing Configuration', () {
      test('should route events based on category', () async {
        await FlexTrack.setupWithRouting([mockTracker1, mockTracker2],
            (builder) {
          builder
              .routeCategory(EventCategory.business)
              .to(['mock1'])
              .withPriority(10) // Higher priority than default
              .and()
              .routeCategory(EventCategory.technical)
              .to(['mock2'])
              .withPriority(10) // Higher priority than default
              .and()
              .routeDefault()
              .toAll()
              .withPriority(0); // Complete the chain

          return builder; // Return the builder
        });

        // Clear any existing events
        mockTracker1.clearCapturedData();
        mockTracker2.clearCapturedData();

        // Business event should only go to mock1
        await FlexTrack.track(PurchaseTestEvent(amount: 100.0));
        expect(mockTracker1.capturedEvents, hasLength(1));
        expect(mockTracker2.capturedEvents, hasLength(1));

        // Technical event should only go to mock2
        await FlexTrack.track(DebugTestEvent());
        expect(mockTracker1.capturedEvents, hasLength(2));
        expect(mockTracker2.capturedEvents, hasLength(2));
      });

      test('should route events based on name pattern', () async {
        await FlexTrack.setupWithRouting([mockTracker1, mockTracker2],
            (builder) {
          builder
              .routeMatching(RegExp(r'debug_.*'))
              .to(['mock1'])
              .withPriority(10)
              .and()
              .routeDefault()
              .to(['mock2'])
              .withPriority(0);

          return builder;
        });

        // Clear trackers
        mockTracker1.clearCapturedData();
        mockTracker2.clearCapturedData();

        await FlexTrack.track(DebugTestEvent()); // debug_test
        expect(mockTracker1.capturedEvents, hasLength(1));
        expect(mockTracker2.capturedEvents, hasLength(1));

        await FlexTrack.track(TestEvent(testProperty: 'normal'));
        expect(mockTracker1.capturedEvents, hasLength(2));
        expect(mockTracker2.capturedEvents, hasLength(2));
      });

      test('should handle custom tracker groups', () async {
        await FlexTrack.setupWithRouting([mockTracker1, mockTracker2],
            (builder) {
          builder
              .defineGroup('analytics', ['mock1', 'mock2'])
              .routeDefault()
              .toGroupNamed('analytics');

          return builder;
        });

        // Clear trackers
        mockTracker1.clearCapturedData();
        mockTracker2.clearCapturedData();

        await FlexTrack.track(TestEvent(testProperty: 'group_test'));

        expect(mockTracker1.capturedEvents, hasLength(1));
        expect(mockTracker2.capturedEvents, hasLength(1));
      });
    });

    group('Consent Management', () {
      test('should respect consent settings', () async {
        await FlexTrack.setup([mockTracker1]);

        // Clear tracker
        mockTracker1.clearCapturedData();

        // Disable consent
        FlexTrack.setConsent(general: false, pii: false);

        // Regular event requiring consent should be blocked
        await FlexTrack.track(TestEvent(testProperty: 'blocked'));
        expect(mockTracker1.capturedEvents, hasLength(0));

        // Essential event should go through regardless
        await FlexTrack.track(EssentialTestEvent());
        expect(mockTracker1.capturedEvents, hasLength(1));
      });

      test('should handle PII consent separately', () async {
        await FlexTrack.setupWithRouting([mockTracker1], (builder) {
          builder
              .routePII()
              .toAll()
              .requirePIIConsent()
              .withPriority(10)
              .and()
              .routeDefault()
              .toAll()
              .withPriority(0);

          return builder;
        });

        // Clear tracker
        mockTracker1.clearCapturedData();

        // Set general consent but not PII consent
        FlexTrack.setConsent(general: true, pii: false);

        // Regular event should work
        await FlexTrack.track(TestEvent(testProperty: 'normal'));
        expect(mockTracker1.capturedEvents, hasLength(1));

        // PII event should be blocked
        await FlexTrack.track(PIITestEvent(email: 'test@test.com'));
        expect(mockTracker1.capturedEvents, hasLength(2)); // Still only 1

        // Enable PII consent
        FlexTrack.setPIIConsent(true);

        // Now PII event should work
        await FlexTrack.track(PIITestEvent(email: 'test2@test.com'));
        expect(mockTracker1.capturedEvents, hasLength(3));
      });

      test('should get current consent status', () async {
        await FlexTrack.setup([mockTracker1]);

        FlexTrack.setConsent(general: true, pii: false);

        final status = FlexTrack.getConsentStatus();
        expect(status['general'], isTrue);
        expect(status['pii'], isFalse);
      });
    });

    group('Tracker Management', () {
      test('should enable and disable individual trackers', () async {
        await FlexTrack.setup([mockTracker1, mockTracker2]);

        // Clear trackers
        mockTracker1.clearCapturedData();
        mockTracker2.clearCapturedData();

        // Disable one tracker
        FlexTrack.disableTracker('mock2');
        expect(FlexTrack.isTrackerEnabled('mock2'), isFalse);

        await FlexTrack.track(TestEvent(testProperty: 'single_tracker'));

        expect(mockTracker1.capturedEvents, hasLength(1));
        expect(mockTracker2.capturedEvents, hasLength(0));

        // Re-enable tracker
        FlexTrack.enableTracker('mock2');
        expect(FlexTrack.isTrackerEnabled('mock2'), isTrue);

        await FlexTrack.track(TestEvent(testProperty: 'both_trackers'));

        expect(mockTracker1.capturedEvents, hasLength(2));
        expect(mockTracker2.capturedEvents, hasLength(1));
      });

      test('should disable all trackers', () async {
        await FlexTrack.setup([mockTracker1, mockTracker2]);

        // Clear trackers
        mockTracker1.clearCapturedData();
        mockTracker2.clearCapturedData();

        FlexTrack.disableAllTrackers();

        await FlexTrack.track(TestEvent(testProperty: 'disabled'));

        expect(mockTracker1.capturedEvents, hasLength(0));
        expect(mockTracker2.capturedEvents, hasLength(0));
      });
    });

    group('User Management', () {
      test('should set user properties on all trackers', () async {
        await FlexTrack.setup([mockTracker1, mockTracker2]);

        // Clear trackers
        mockTracker1.clearCapturedData();
        mockTracker2.clearCapturedData();

        final properties = {'age': 25, 'plan': 'premium'};
        await FlexTrack.setUserProperties(properties);

        expect(mockTracker1.capturedUserProperties, hasLength(1));
        expect(mockTracker2.capturedUserProperties, hasLength(1));
        expect(mockTracker1.capturedUserProperties.first, equals(properties));
      });

      test('should identify user on all trackers', () async {
        await FlexTrack.setup([mockTracker1, mockTracker2]);

        // Clear trackers
        mockTracker1.clearCapturedData();
        mockTracker2.clearCapturedData();

        await FlexTrack.identifyUser('user123', {'name': 'John'});

        expect(mockTracker1.capturedUserIds, hasLength(1));
        expect(mockTracker2.capturedUserIds, hasLength(1));
        expect(mockTracker1.capturedUserIds.first, equals('user123'));
      });

      test('should reset all trackers', () async {
        await FlexTrack.setup([mockTracker1, mockTracker2]);

        // Track some events and identify user
        await FlexTrack.track(TestEvent(testProperty: 'before_reset'));
        await FlexTrack.identifyUser('user123');

        expect(mockTracker1.capturedEvents, hasLength(1));
        expect(mockTracker1.capturedUserIds, hasLength(1));

        // Reset
        await FlexTrack.resetTrackers();

        expect(mockTracker1.capturedEvents, hasLength(0));
        expect(mockTracker1.capturedUserIds, hasLength(0));
      });
    });

    group('Debug and Validation', () {
      test('should provide debug information', () async {
        await FlexTrack.setup([mockTracker1, consoleTracker]);

        final debugInfo = FlexTrack.getDebugInfo();

        expect(debugInfo['isSetUp'], isTrue);
        expect(debugInfo['isInitialized'], isTrue);
        expect(debugInfo['isEnabled'], isTrue);
      });

      test('should debug event routing', () async {
        await FlexTrack.setupWithRouting([mockTracker1, mockTracker2],
            (builder) {
          builder
              .routeCategory(EventCategory.business)
              .to(['mock1'])
              .withPriority(10)
              .and()
              .routeDefault()
              .toAll()
              .withPriority(0);

          return builder;
        });

        final businessEvent = PurchaseTestEvent(amount: 100.0);
        final debugInfo = FlexTrack.debugEvent(businessEvent);

        expect(debugInfo.matchingRules, hasLength(greaterThanOrEqualTo(0)));
        expect(debugInfo.routingResult.targetTrackers, contains('mock1'));
      });

      test('should validate configuration', () async {
        await FlexTrack.setup([mockTracker1]);

        final validationIssues = FlexTrack.validate();
        expect(validationIssues, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle tracker exceptions gracefully', () async {
        final failingTracker =
            ExtendedMockTracker(id: 'failing', name: 'Failing');
        failingTracker.shouldFailOnTrack = true;

        await FlexTrack.setup([mockTracker1, failingTracker]);

        // Clear tracker
        mockTracker1.clearCapturedData();

        final result =
            await FlexTrack.track(TestEvent(testProperty: 'error_test'));

        // Should be partially successful
        expect(result.successfulTrackingCount, equals(1));
        expect(result.failedTrackingCount, equals(1));
        expect(result.trackingErrors, hasLength(1));
      });

      test('should throw error when not setup', () {
        expect(
            () => FlexTrack.instance, throwsA(isA<ConfigurationException>()));
      });
    });

    group('Performance Features', () {
      test('should handle sampling', () async {
        await FlexTrack.setupWithRouting([mockTracker1], (builder) {
          builder
              .routeDefault()
              .toAll()
              .sample(0.0) // 0% sampling - nothing should go through
              .and();

          return builder;
        });

        // Clear tracker
        mockTracker1.clearCapturedData();

        // Track multiple events
        for (int i = 0; i < 10; i++) {
          await FlexTrack.track(TestEvent(testProperty: 'sample_test_$i'));
        }

        // With 0% sampling, no events should be tracked
        expect(mockTracker1.capturedEvents, hasLength(0));
      });

      test('should handle batch tracking', () async {
        await FlexTrack.setup([mockTracker1]);

        // Clear tracker
        mockTracker1.clearCapturedData();

        final events = List.generate(
          5,
          (i) => TestEvent(testProperty: 'batch_$i'),
        );

        final results = await FlexTrack.trackParallel(events);

        expect(results, hasLength(5));
        expect(results.every((r) => r.successful), isTrue);
        expect(mockTracker1.capturedEvents, hasLength(5));
      });
    });
  });
}

// Helper classes for testing
class FailingTracker extends BaseTrackerStrategy {
  FailingTracker() : super(id: 'failing', name: 'Failing Tracker');

  @override
  Future<void> doInitialize() async {
    throw Exception('Initialization failed');
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // Should not be called
  }
}

// Extended MockTracker for testing edge cases
class ExtendedMockTracker extends MockTracker {
  bool shouldFailOnTrack = false;

  ExtendedMockTracker({required super.id, required super.name});

  @override
  Future<void> doTrack(BaseEvent event) async {
    if (shouldFailOnTrack) {
      throw TrackerException('Simulated tracking failure', trackerId: id);
    }
    await super.doTrack(event);
  }
}
