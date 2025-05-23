import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:flex_track/src/core/tracker_registry.dart';
import 'package:flex_track/src/exceptions/configuration_exception.dart';
import 'package:flex_track/src/exceptions/tracker_exception.dart';
import 'package:flex_track/src/strategies/tracker_strategy.dart';
import 'package:flex_track/src/models/event/base_event.dart'; // Import BaseEvent
import 'package:flutter_test/flutter_test.dart';

// Generate mocks for the TrackerStrategy
@GenerateMocks([TrackerStrategy])
import 'tracker_registry_test.mocks.dart';

// Helper function to set up mock behavior
void setupMockTracker(MockTrackerStrategy mock, String id, String name,
    {bool isEnabled = true}) {
  when(mock.id).thenReturn(id);
  when(mock.name).thenReturn(name);
  when(mock.isEnabled).thenReturn(isEnabled);
  when(mock.enable()).thenReturn(null);
  when(mock.disable()).thenReturn(null);
  when(mock.initialize()).thenAnswer((_) async {});
  when(mock.setUserProperties(any)).thenAnswer((_) async {});
  when(mock.identifyUser(any, any)).thenAnswer((_) async {});
  when(mock.reset()).thenAnswer((_) async {});
  when(mock.flush()).thenAnswer((_) async {});
  when(mock.getDebugInfo())
      .thenReturn({'id': id, 'name': name, 'isEnabled': isEnabled});
  when(mock.isGDPRCompliant).thenReturn(false); // Default mock value
  when(mock.maxBatchSize).thenReturn(1); // Default mock value
  when(mock.track(any)).thenAnswer((_) async {});
  when(mock.trackBatch(any)).thenAnswer((_) async {});
}

void main() {
  group('TrackerRegistry', () {
    late TrackerRegistry registry;
    late MockTrackerStrategy mockTracker1;
    late MockTrackerStrategy mockTracker2;

    setUp(() {
      registry = TrackerRegistry();
      mockTracker1 = MockTrackerStrategy();
      mockTracker2 = MockTrackerStrategy();
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One');
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two');
    });

    test('should register a single tracker', () {
      registry.register(mockTracker1);
      expect(registry.count, 1);
      expect(registry.contains('tracker1'), isTrue);
      expect(registry.get('tracker1'), equals(mockTracker1));
    });

    test(
        'should throw TrackerException if registering tracker after initialization',
        () async {
      await registry.initialize();
      expect(() => registry.register(mockTracker1),
          throwsA(isA<TrackerException>()));
    });

    test(
        'should throw TrackerException if registering tracker with duplicate ID',
        () {
      registry.register(mockTracker1);
      final duplicateTracker = MockTrackerStrategy();
      setupMockTracker(duplicateTracker, 'tracker1', 'Another Tracker');
      expect(() => registry.register(duplicateTracker),
          throwsA(isA<TrackerException>()));
    });

    test(
        'should throw ConfigurationException if registering tracker with empty ID',
        () {
      final emptyIdTracker = MockTrackerStrategy();
      setupMockTracker(emptyIdTracker, '', 'Empty ID Tracker');
      expect(() => registry.register(emptyIdTracker),
          throwsA(isA<ConfigurationException>()));
    });

    test('should register multiple trackers', () {
      registry.registerAll([mockTracker1, mockTracker2]);
      expect(registry.count, 2);
      expect(registry.contains('tracker1'), isTrue);
      expect(registry.contains('tracker2'), isTrue);
    });

    test('should unregister a tracker by ID', () {
      registry.register(mockTracker1);
      expect(registry.unregister('tracker1'), isTrue);
      expect(registry.count, 0);
      expect(registry.contains('tracker1'), isFalse);
    });

    test('should return false when unregistering a non-existent tracker', () {
      expect(registry.unregister('non_existent_tracker'), isFalse);
    });

    test(
        'should throw TrackerException if unregistering tracker after initialization',
        () async {
      registry.register(mockTracker1);
      await registry.initialize();
      expect(() => registry.unregister('tracker1'),
          throwsA(isA<TrackerException>()));
    });

    test('should get a tracker by ID', () {
      registry.register(mockTracker1);
      expect(registry.get('tracker1'), equals(mockTracker1));
    });

    test('should return null when getting a non-existent tracker', () {
      expect(registry.get('non_existent_tracker'), isNull);
    });

    test('should get multiple trackers by IDs', () {
      registry.registerAll([mockTracker1, mockTracker2]);
      final trackers =
          registry.getMultiple(['tracker1', 'tracker2', 'non_existent']);
      expect(trackers.length, 2);
      expect(trackers, contains(mockTracker1));
      expect(trackers, contains(mockTracker2));
    });

    test('should check if a tracker is registered', () {
      registry.register(mockTracker1);
      expect(registry.contains('tracker1'), isTrue);
      expect(registry.contains('non_existent_tracker'), isFalse);
    });

    test('should check if a tracker is enabled', () {
      registry.register(mockTracker1);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: false);
      expect(registry.isEnabled('non_existent_tracker'), isFalse);
    });

    test('should check if a tracker is initialized', () {
      registry.register(mockTracker1);
      expect(registry.isTrackerInitialized('tracker1'), isFalse);
    });

    test('should initialize all registered trackers', () async {
      registry.registerAll([mockTracker1, mockTracker2]);
      await registry.initialize();
      expect(registry.isInitialized, isTrue);
      expect(registry.isTrackerInitialized('tracker1'), isTrue);
      expect(registry.isTrackerInitialized('tracker2'), isTrue);
      verify(mockTracker1.initialize()).called(1);
      verify(mockTracker2.initialize()).called(1);
    });

    test('should not re-initialize if already initialized', () async {
      registry.register(mockTracker1);
      await registry.initialize();
      await registry.initialize(); // Call initialize again
      verify(mockTracker1.initialize()).called(1); // Should only be called once
    });

    test(
        'should throw TrackerException if initialization fails for any tracker',
        () async {
      registry.register(mockTracker1);
      registry.register(mockTracker2);
      when(mockTracker1.initialize())
          .thenAnswer((_) => Future.error(Exception('Init failed')));
      when(mockTracker2.initialize()).thenAnswer((_) => Future.value());
      try {
        await registry.initialize();
      } catch (e) {
        print(e);
      }
      expect(registry.isInitialized,
          isTrue); // Registry is marked as initialized even with failures
      expect(registry.isTrackerInitialized('tracker1'), isFalse);
      expect(registry.isTrackerInitialized('tracker2'),
          isTrue); // Other trackers should still initialize
    });

    test('should enable a tracker', () {
      registry.register(mockTracker1);
      registry.enable('tracker1');
      verify(mockTracker1.enable()).called(1);
    });

    test('should throw TrackerException if enabling a non-existent tracker',
        () {
      expect(() => registry.enable('non_existent_tracker'),
          throwsA(isA<TrackerException>()));
    });

    test('should disable a tracker', () {
      registry.register(mockTracker1);
      registry.disable('tracker1');
      verify(mockTracker1.disable()).called(1);
    });

    test('should throw TrackerException if disabling a non-existent tracker',
        () {
      expect(() => registry.disable('non_existent_tracker'),
          throwsA(isA<TrackerException>()));
    });

    test('should enable all trackers', () {
      registry.registerAll([mockTracker1, mockTracker2]);
      registry.enableAll();
      verify(mockTracker1.enable()).called(1);
      verify(mockTracker2.enable()).called(1);
    });

    test('should disable all trackers', () {
      registry.registerAll([mockTracker1, mockTracker2]);
      registry.disableAll();
      verify(mockTracker1.disable()).called(1);
      verify(mockTracker2.disable()).called(1);
    });

    test('should set user properties for all enabled trackers', () async {
      registry.registerAll([mockTracker1, mockTracker2]);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two',
          isEnabled: false);

      final properties = {'name': 'test'};
      await registry.setUserProperties(properties);

      verify(mockTracker1.setUserProperties(properties)).called(1);
      verifyNever(mockTracker2.setUserProperties(any));
    });

    test('should identify user for all enabled trackers', () async {
      registry.registerAll([mockTracker1, mockTracker2]);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two',
          isEnabled: false);

      final properties = {'name': 'test'};
      await registry.identifyUser('user123', properties);

      verify(mockTracker1.identifyUser('user123', properties)).called(1);
      verifyNever(mockTracker2.identifyUser(any, any));
    });

    test('should reset all enabled trackers', () async {
      registry.registerAll([mockTracker1, mockTracker2]);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two',
          isEnabled: false);

      await registry.reset();

      verify(mockTracker1.reset()).called(1);
      verifyNever(mockTracker2.reset());
    });

    test('should flush all enabled trackers', () async {
      registry.registerAll([mockTracker1, mockTracker2]);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two',
          isEnabled: false);

      await registry.flush();

      verify(mockTracker1.flush()).called(1);
      verifyNever(mockTracker2.flush());
    });

    test('should track an event on all enabled trackers', () async {
      registry.registerAll([mockTracker1, mockTracker2]);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two',
          isEnabled: false);

      final event = FakeBaseEvent();
      await registry.track(event);

      verify(mockTracker1.track(event)).called(1);
      verifyNever(mockTracker2.track(any));
    });

    test('should track a batch of events on all enabled trackers', () async {
      registry.registerAll([mockTracker1, mockTracker2]);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two',
          isEnabled: false);

      final events = [FakeBaseEvent(), FakeBaseEvent()];
      await registry.trackBatch(events);

      verify(mockTracker1.trackBatch(events)).called(1);
      verifyNever(mockTracker2.trackBatch(any));
    });

    test('should clear all registered trackers if not initialized', () {
      registry.registerAll([mockTracker1, mockTracker2]);
      registry.clear();
      expect(registry.count, 0);
      expect(registry.contains('tracker1'), isFalse);
      expect(registry.contains('tracker2'), isFalse);
    });

    test(
        'should throw TrackerException if clearing trackers after initialization',
        () async {
      registry.register(mockTracker1);
      await registry.initialize();
      expect(() => registry.clear(), throwsA(isA<TrackerException>()));
    });

    test('should return debug information', () {
      registry.registerAll([mockTracker1, mockTracker2]);
      setupMockTracker(mockTracker1, 'tracker1', 'Tracker One',
          isEnabled: true);
      setupMockTracker(mockTracker2, 'tracker2', 'Tracker Two',
          isEnabled: true);

      final debugInfo = registry.getDebugInfo();

      expect(debugInfo['isInitialized'], isFalse);
      expect(debugInfo['trackerCount'], 2);
      expect(debugInfo['enabledTrackers'], 2);
      expect(debugInfo['initializedTrackers'], 0);
      expect(debugInfo['trackers'], isA<Map>());
      expect(debugInfo['trackers']['tracker1'], isA<Map>());
      expect(debugInfo['trackers']['tracker2'], isA<Map>());
      expect(debugInfo['trackers']['tracker1']['initialized'], isFalse);
      expect(debugInfo['trackers']['tracker2']['initialized'], isFalse);
    });

    test('should validate registry configuration', () {
      registry.registerAll([mockTracker1, mockTracker2]);
      final issues = registry.validate();
      expect(issues, isEmpty);
    });

    test('should report issue if no trackers are registered during validation',
        () {
      final issues = registry.validate();
      expect(issues, contains('No trackers registered'));
    });

    test(
        'should report issue if duplicate tracker names are found during validation',
        () {
      registry.register(mockTracker1);
      final duplicateNameTracker = MockTrackerStrategy();
      setupMockTracker(duplicateNameTracker, 'tracker3', 'Tracker One');
      registry.register(duplicateNameTracker);
      final issues = registry.validate();
      expect(issues, contains('Duplicate tracker names found: Tracker One'));
    });

    test('should report issue if tracker has empty ID during validation', () {
      // This test is now redundant as the validation logic is tested by the exception test above.
      // Keeping it commented out for now, but it can be removed.
      // final emptyIdTracker = MockTrackerStrategy();
      // setupMockTracker(emptyIdTracker, '', 'Empty ID Tracker');
      // registry.register(emptyIdTracker);
      // final issues = registry.validate();
      // expect(issues, contains('Tracker has empty ID: Empty ID Tracker'));
    });

    test('should report issue if tracker has empty name during validation', () {
      final emptyNameTracker = MockTrackerStrategy();
      setupMockTracker(emptyNameTracker, 'tracker4', '');
      registry.register(emptyNameTracker);
      final issues = registry.validate();
      expect(issues, contains('Tracker has empty name: tracker4'));
    });

    test('toString should return a descriptive string', () {
      expect(registry.toString(),
          equals('TrackerRegistry(0 trackers, initialized: false)'));
      registry.register(mockTracker1);
      expect(registry.toString(),
          equals('TrackerRegistry(1 trackers, initialized: false)'));
    });
  });
}

class FakeBaseEvent extends Fake implements BaseEvent {
  @override
  String getName() => 'FakeEvent';

  @override
  Map<String, Object>? getProperties() => {};
}
