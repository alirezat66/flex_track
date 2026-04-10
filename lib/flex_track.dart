/// FlexTrack - A flexible analytics tracking system for Flutter
///
/// FlexTrack provides a powerful routing system that allows you to send events
/// to different analytics services based on configurable rules. It supports
/// GDPR compliance, sampling, environment-based routing, and much more.
///
/// ## Quick Start
///
/// ```dart
/// class UserSignupEvent extends BaseEvent {
///   @override
///   String getName() => 'user_signup';
///   @override
///   Map<String, Object>? getProperties() => const {};
/// }
///
/// await FlexTrack.setup([
///   ConsoleTracker(),
///   // Register your own BaseTrackerStrategy subclasses here
/// ]);
///
/// await FlexTrack.track(UserSignupEvent());
/// ```
///
/// ## Injectable client (Riverpod, Bloc, tests)
///
/// Use [FlexTrackClient.create] when you want a dedicated instance instead of
/// the global [FlexTrack.setup] singleton. Wrap subtrees with [FlexTrackScope]
/// so [FlexClickTrack] and related widgets use that client automatically.
/// See `docs/flex-track-client.md`.
///
/// ## Advanced Setup
///
/// ```dart
/// await FlexTrack.setupWithRouting([
///   ConsoleTracker(),
/// ], (routing) => routing
///   .defineGroup('analytics', ['firebase', 'mixpanel'])
///   .routeNamed('debug_').toDevelopment().onlyInDebug().and()
///   .routeDefault().toAll().and());
/// ```
library;

import 'src/core/flex_track.dart';
import 'src/strategies/built_in/console_tracker.dart';
import 'src/strategies/built_in/mock_tracker.dart';
import 'src/strategies/tracker_strategy.dart';

// ============= CORE EXPORTS =============

// Main FlexTrack API and injectable client
export 'src/core/event_dispatch_record.dart';
export 'src/core/flex_track.dart';
export 'src/core/flex_track_client.dart' show FlexTrackClient;
export 'src/core/event_processor.dart'
    show EventProcessingResult, TrackingResult;
export 'src/core/tracker_registry.dart' show TrackerRegistry;

// ============= EVENT MODELS =============

// Base event system
export 'src/models/event/base_event.dart';

// Context and consent management
export 'src/models/context/tracking_context.dart';
export 'src/models/context/consent_manager.dart';

// ============= ROUTING SYSTEM =============

// Routing models
export 'src/models/routing/tracker_group.dart';
export 'src/models/routing/event_category.dart';
export 'src/models/routing/routing_rule.dart';
export 'src/models/routing/routing_config.dart';

// Routing builders
export 'src/routing/routing_builder.dart';
export 'src/routing/route_config_builder.dart';
export 'src/routing/routing_rule_builder.dart';
export 'src/routing/routing_engine.dart'
    show RoutingEngine, RoutingResult, RoutingDebugInfo, SkippedRule;

// Routing presets
export 'src/routing/presets/smart_defaults.dart';
export 'src/routing/presets/gdpr_defaults.dart';
export 'src/routing/presets/performance_defaults.dart';

// ============= TRACKER STRATEGIES =============

// Strategy interfaces
export 'src/strategies/tracker_strategy.dart';
export 'src/strategies/base_tracker_strategy.dart';

// Built-in trackers
export 'src/strategies/built_in/console_tracker.dart';
export 'src/strategies/built_in/mock_tracker.dart';
export 'src/strategies/built_in/no_op_tracker.dart';

// ============= WIDGETS =============

// Click / view tracking wrappers
export 'src/widgets/flex_click_track.dart';
export 'src/widgets/flex_route_track.dart';
export 'src/widgets/flex_mount_track.dart';
export 'src/widgets/flex_impression_track.dart';
export 'src/widgets/flex_track_scope.dart';

// ============= UTILITIES =============

// Environment detection
export 'src/utils/environment_detector.dart';

// Pattern matching
export 'src/utils/pattern_matcher.dart';

// Sampling utilities
export 'src/utils/sampling_utils.dart';

// Validation utilities
export 'src/utils/validation_utils.dart';

// ============= EXCEPTIONS =============

// Exception classes
export 'src/exceptions/flex_track_exception.dart';
export 'src/exceptions/tracker_exception.dart';
export 'src/exceptions/routing_exception.dart';
export 'src/exceptions/configuration_exception.dart';

// ============= CONVENIENCE EXPORTS =============

// Common classes that users will frequently use
export 'src/models/event/base_event.dart' show BaseEvent;
export 'src/strategies/tracker_strategy.dart' show TrackerStrategy;
export 'src/strategies/base_tracker_strategy.dart' show BaseTrackerStrategy;
export 'src/models/routing/tracker_group.dart' show TrackerGroup;
export 'src/models/routing/event_category.dart' show EventCategory;
export 'src/routing/routing_builder.dart' show RoutingBuilder;
export 'src/core/flex_track.dart' show FlexTrack;

// ============= VERSION INFO =============

/// FlexTrack package version
const String flexTrackVersion = '1.0.0';

/// FlexTrack package description
const String flexTrackDescription =
    'A flexible analytics tracking system for Flutter';

// ============= CONVENIENCE FUNCTIONS =============

/// Quick setup function for simple use cases
///
/// This is equivalent to calling FlexTrack.setup() but provides a more
/// convenient API for simple scenarios.
///
/// ```dart
/// await setupFlexTrack([
///   ConsoleTracker(),
/// ]);
/// ```
Future<void> setupFlexTrack(List<TrackerStrategy> trackers) async {
  await FlexTrack.setup(trackers);
}

/// Quick setup with smart defaults
///
/// ```dart
/// await setupFlexTrackWithDefaults([
///   ConsoleTracker(),
/// ]);
/// ```
Future<void> setupFlexTrackWithDefaults(List<TrackerStrategy> trackers) async {
  await FlexTrack.setupWithRouting(
      trackers, (builder) => builder.applySmartDefaults());
}

/// Quick setup for development
///
/// Sets up FlexTrack with development-friendly configuration:
/// - Console tracker for debugging
/// - Debug-only routing for development events
/// - No sampling in debug mode
///
/// ```dart
/// await setupFlexTrackForDevelopment();
/// ```
Future<void> setupFlexTrackForDevelopment() async {
  await FlexTrack.setupWithRouting([
    ConsoleTracker(
      showProperties: true,
      showTimestamps: true,
      colorOutput: true,
    ),
  ], (builder) {
    // Use block body for explicit return
    builder
        .setDebugMode(true)
        .setSampling(false)
        .routeMatching(RegExp(r'debug_.*'))
        .toDevelopment()
        .noSampling()
        .and()
        .routeDefault()
        .toAll(); // This adds the rule to the builder

    return builder; // Explicitly return the builder
  });
}

/// Quick setup for testing
///
/// Sets up FlexTrack with test-friendly configuration:
/// - Mock tracker for assertions
/// - No consent requirements
/// - No sampling
///
/// ```dart
/// final mockTracker = await setupFlexTrackForTesting();
///
/// // Your tests...
/// expect(mockTracker.capturedEvents, hasLength(1));
/// ```
Future<MockTracker> setupFlexTrackForTesting() async {
  final mockTracker = MockTracker();

  await FlexTrack.setupWithRouting([mockTracker], (builder) {
    builder
        .setDebugMode(true)
        .setSampling(false)
        .setConsentChecking(false)
        .routeDefault()
        .toAll();
    return builder;
  });

  return mockTracker;
}
