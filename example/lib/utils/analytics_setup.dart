import 'package:flutter/foundation.dart';
import 'package:flex_track/flex_track.dart';
import '../trackers/firebase_tracker.dart';
import '../trackers/mixpanel_tracker.dart';
import '../trackers/amplitude_tracker.dart';
import '../trackers/custom_api_tracker.dart';
import '../events/app_events.dart';

class AnalyticsSetup {
  static Future<void> initialize() async {
    // Create trackers
    final trackers = await _createTrackers();

    // Set up FlexTrack with advanced routing
    await FlexTrack.setupWithRouting(trackers, (builder) {
      return _configureRouting(builder);
    });

    // Track app startup
    await FlexTrack.track(AppStartEvent());
  }

  static Future<List<TrackerStrategy>> _createTrackers() async {
    final trackers = <TrackerStrategy>[];

    // Always include console tracker for development
    trackers.add(ConsoleTracker(
      showProperties: true,
      showTimestamps: true,
      colorOutput: true,
    ));

    // Add production trackers based on environment
    if (!kDebugMode) {
      // Firebase Analytics (free tier, good for basic analytics)
      trackers.add(await FirebaseTracker.create());

      // Mixpanel (paid, advanced segmentation)
      const mixpanelToken =
          String.fromEnvironment('MIXPANEL_TOKEN', defaultValue: '');
      if (mixpanelToken.isNotEmpty) {
        trackers.add(await MixpanelTracker.create(mixpanelToken));
      }

      // Amplitude (freemium, good for product analytics)
      const amplitudeApiKey =
          String.fromEnvironment('AMPLITUDE_API_KEY', defaultValue: '');
      if (amplitudeApiKey.isNotEmpty) {
        trackers.add(AmplitudeTracker(apiKey: amplitudeApiKey));
      }

      // Custom API tracker (for internal analytics)
      const customApiUrl =
          String.fromEnvironment('CUSTOM_API_URL', defaultValue: '');
      if (customApiUrl.isNotEmpty) {
        trackers.add(CustomAPITracker(
          apiUrl: customApiUrl,
          apiKey: const String.fromEnvironment('CUSTOM_API_KEY'),
        ));
      }
    } else {
      // In debug mode, also add mock trackers for testing
      trackers.add(await FirebaseTracker.create());
      trackers.add(await MixpanelTracker.create('debug_token'));
      trackers.add(AmplitudeTracker(apiKey: 'debug_api_key'));
    }

    return trackers;
  }

  static RoutingBuilder _configureRouting(RoutingBuilder builder) {
    // Define custom tracker groups
    builder.defineGroup('free_tier', ['console', 'firebase']).defineGroup(
        'premium', ['mixpanel', 'amplitude']).defineGroup('internal', [
      'custom_api'
    ]).defineGroup('gdpr_compliant', ['firebase', 'custom_api']);

    // Apply GDPR defaults first (highest priority)
    GDPRDefaults.apply(builder, compliantTrackers: ['firebase', 'custom_api']);

    // E-commerce events (business critical)
    builder
        .routeCategory(EventCategory.business)
        .toAll()
        .essential() // No sampling, no consent bypass
        .withPriority(25)
        .withDescription('Business events - critical for revenue tracking')
        .and();

    // User behavior events for product analytics
    builder
        .routeCategory(EventCategory.user)
        .toGroupNamed('premium')
        .requireConsent()
        .lightSampling()
        .withPriority(15)
        .withDescription('User behavior for product analytics')
        .and();

    // High-frequency UI events
    builder
        .routeMatching(RegExp(r'(click|scroll|hover|focus)_.*'))
        .toGroupNamed('premium')
        .heavySampling() // 1% sampling
        .withPriority(10)
        .withDescription('High frequency UI interactions')
        .and();

    // Performance and error events
    builder
        .routeCategory(EventCategory.technical)
        .toGroupNamed('internal')
        .skipConsent() // Legitimate interest
        .lightSampling()
        .withPriority(20)
        .withDescription('Performance and error tracking')
        .and();

    // A/B testing events
    builder
        .routeMatching(RegExp(r'experiment_.*'))
        .toGroupNamed('premium')
        .requireConsent()
        .noSampling() // Important for statistical significance
        .withPriority(18)
        .withDescription('A/B testing and experiments')
        .and();

    // Marketing attribution
    builder
        .routeCategory(EventCategory.marketing)
        .toAll()
        .requireConsent()
        .mediumSampling()
        .withPriority(12)
        .withDescription('Marketing attribution and campaigns')
        .and();

    // Debug events (development only)
    builder
        .routeMatching(RegExp(r'debug_.*'))
        .toDevelopment()
        .onlyInDebug()
        .noSampling()
        .withPriority(30)
        .withDescription('Debug events for development')
        .and();

    // Default routing
    builder
        .routeDefault()
        .toGroupNamed('free_tier')
        .mediumSampling()
        .withPriority(0)
        .withDescription('Default routing for unmatched events');

    return builder;
  }
}
