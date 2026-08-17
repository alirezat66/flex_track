import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flex_track/flex_track.dart';
import 'package:flex_track/flex_track_inspector.dart';
import 'package:path_provider/path_provider.dart';
import '../trackers/firebase_tracker.dart';
import '../trackers/mixpanel_tracker.dart';
import '../trackers/amplitude_tracker.dart';
import '../trackers/custom_api_tracker.dart';
import '../events/app_events.dart';
import '../runtime/offline_delivery_demo.dart';

class AnalyticsSetup {
  static Future<void> initialize() async {
    // Create trackers
    final trackers = await _createTrackers();
    final deliveryDemo = OfflineDeliveryDemo.instance;
    await deliveryDemo.initialize();
    final supportDirectory = await getApplicationSupportDirectory();
    final queue = FileEventQueue(
      File('${supportDirectory.path}/flex_track/event_queue.json'),
    );

    // Set up FlexTrack with advanced routing
    await FlexTrack.setupWithRouting(trackers, (builder) {
      return _configureRouting(builder);
    }, queue: queue, onlineProvider: () => deliveryDemo.onlineProvider);

    await deliveryDemo.refreshQueueSize();

    // Track app startup
    await FlexTrack.track(AppStartEvent());

    if (kDebugMode) {
      final inspectorUrl = await FlexTrackInspector.start(port: 7788);
      if (inspectorUrl != null) {
        debugPrint('FlexTrack Inspector (open in browser): $inspectorUrl');
      }
    }
  }

  /// Replays events restored from disk after consent has been loaded.
  /// If the demo is still offline, [FlexTrack.flush] is a safe no-op and the
  /// durable queue remains intact for a later manual or startup retry.
  static Future<QueueFlushResult> flushRecoveredEvents() async {
    final result = await FlexTrack.flush();
    await OfflineDeliveryDemo.instance.refreshQueueSize();
    return result;
  }

  static Future<List<TrackerStrategy>> _createTrackers() async {
    final trackers = <TrackerStrategy>[];

    // Always include console tracker for development
    trackers.add(ConsoleTracker(
      showProperties: true,
      showTimestamps: true,
      colorOutput: true,
    ));
    trackers
      ..add(OfflineDeliveryDemo.instance.successTracker)
      ..add(OfflineDeliveryDemo.instance.retryTracker);

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

    builder
        .routeExact('demo_offline_delivery')
        .to(['demo_delivery_success', 'demo_delivery_retry'])
        .skipConsent()
        .noSampling()
        .withPriority(100)
        .withDescription('Offline Delivery Lab destinations')
        .and();

    // Example: same app, different destinations — explicit tracker lists
    builder
        .routeExact('demo_free_tier_only')
        .to(['console', 'firebase'])
        .skipConsent()
        .noSampling()
        .withPriority(28)
        .withDescription(
            'Demo: console + Firebase only (no Mixpanel/Amplitude)')
        .and();

    builder
        .routeExact('demo_premium_only')
        .to(['mixpanel', 'amplitude'])
        .requireConsent()
        .noSampling()
        .withPriority(28)
        .withDescription(
            'Demo: Mixpanel + Amplitude only (no console/Firebase)')
        .and();

    builder
        .routeExact('demo_banner_impression')
        .toGroupNamed('premium')
        .requireConsent()
        .noSampling()
        .withPriority(27)
        .withDescription(
            'Demo: impression events always to premium (no sampling)')
        .and();

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
        .withDescription('Default routing for unmatched events')
        .and();

    return builder;
  }
}
