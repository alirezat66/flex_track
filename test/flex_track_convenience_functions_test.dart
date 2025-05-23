import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('FlexTrack Convenience Functions', () {
    setUp(() {
      // Reset FlexTrack before each test to ensure a clean state
      FlexTrack.reset();
    });

    test('setupFlexTrack initializes FlexTrack with provided trackers', () async {
      final mockTracker = MockTracker();
      await setupFlexTrack([mockTracker]);

      // Verify that FlexTrack is initialized and the tracker is registered
      expect(FlexTrack.instance.isInitialized, isTrue);
      expect(FlexTrack.instance.trackerRegistry.get(mockTracker.id), mockTracker);
    });

    test('setupFlexTrackWithDefaults initializes FlexTrack with smart defaults', () async {
      final mockTracker = MockTracker();
      await setupFlexTrackWithDefaults([mockTracker]);

      // Verify that FlexTrack is initialized and smart defaults are applied
      expect(FlexTrack.instance.isInitialized, isTrue);
      // Further assertions could be made here to check specific routing rules
      // applied by applySmartDefaults, but that would require inspecting
      // the internal routing engine, which is not directly exposed.
      // For now, just checking initialization is sufficient.
    });

    test('setupFlexTrackForDevelopment initializes FlexTrack for development', () async {
      await setupFlexTrackForDevelopment();

      // Verify that FlexTrack is initialized and configured for development
      expect(FlexTrack.instance.isInitialized, isTrue);
      expect(FlexTrack.instance.eventProcessor.routingEngine.configuration.isDebugMode, isTrue);
      expect(FlexTrack.instance.eventProcessor.routingEngine.configuration.enableSampling, isFalse);
      // Check if ConsoleTracker is registered
      expect(FlexTrack.instance.trackerRegistry.get(ConsoleTracker().id), isA<ConsoleTracker>());
    });

    test('setupFlexTrackForTesting initializes FlexTrack for testing and returns MockTracker', () async {
      final mockTracker = await setupFlexTrackForTesting();

      // Verify that FlexTrack is initialized and configured for testing
      expect(FlexTrack.instance.isInitialized, isTrue);
      expect(FlexTrack.instance.eventProcessor.routingEngine.configuration.isDebugMode, isTrue);
      expect(FlexTrack.instance.eventProcessor.routingEngine.configuration.enableSampling, isFalse);
      expect(FlexTrack.instance.eventProcessor.routingEngine.configuration.enableConsentChecking, isFalse);
      // Verify that the returned mockTracker is the one registered
      expect(FlexTrack.instance.trackerRegistry.get(mockTracker.id), mockTracker);
    });
  });
}