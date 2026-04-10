import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flutter/foundation.dart';

import '../models/routing/routing_config.dart';
import '../routing/routing_builder.dart';
import '../routing/routing_engine.dart' show RoutingDebugInfo;
import '../strategies/tracker_strategy.dart';
import '../exceptions/configuration_exception.dart';
import 'flex_track_client.dart';
import 'tracker_registry.dart';
import 'event_processor.dart';

/// Global entry point for FlexTrack. [setup] installs a default [FlexTrackClient]
/// and static methods delegate to it. For injection (Riverpod, Bloc, tests), use
/// [FlexTrackClient.create] instead and pass the instance explicitly.
class FlexTrack {
  static FlexTrack? _instance;

  final FlexTrackClient _client;

  FlexTrack._(this._client);

  /// The default client installed by [setup]. Prefer injecting [FlexTrackClient]
  /// in new code; this getter exists for advanced access to the same instance.
  FlexTrackClient get client => _client;

  /// Get the singleton [FlexTrack] facade (not the raw client).
  static FlexTrack get instance {
    if (_instance == null) {
      throw ConfigurationException(
        'FlexTrack has not been set up. Call FlexTrack.setup() first.',
        code: 'NOT_INITIALIZED',
      );
    }
    return _instance!;
  }

  /// Check if FlexTrack has been set up
  static bool get isSetUp => _instance != null;

  /// Whether FlexTrack is initialized and ready to track events
  bool get isInitialized => _client.isInitialized;

  /// Get the tracker registry
  TrackerRegistry get trackerRegistry => _client.trackerRegistry;

  /// Get the event processor
  EventProcessor get eventProcessor => _client.eventProcessor;

  // ========== SETUP METHODS ==========

  /// Set up FlexTrack with trackers and routing configuration
  static Future<FlexTrack> setup(
    List<TrackerStrategy> trackers, {
    RoutingConfiguration? routing,
    bool autoInitialize = true,
  }) async {
    if (_instance != null) {
      throw ConfigurationException(
        'FlexTrack is already set up. Call FlexTrack.reset() first if you need to reconfigure.',
        code: 'ALREADY_SETUP',
      );
    }

    final client = await FlexTrackClient.create(
      trackers,
      routing: routing,
      autoInitialize: autoInitialize,
    );
    _instance = FlexTrack._(client);
    return _instance!;
  }

  /// Set up FlexTrack with a routing builder for more control
  static Future<FlexTrack> setupWithRouting(
    List<TrackerStrategy> trackers,
    RoutingBuilder Function(RoutingBuilder) configureRouting, {
    bool autoInitialize = true,
  }) async {
    return setup(
      trackers,
      routing: _routingFromBuilder(configureRouting),
      autoInitialize: autoInitialize,
    );
  }

  static RoutingConfiguration _routingFromBuilder(
    RoutingBuilder Function(RoutingBuilder) configureRouting,
  ) {
    final routingBuilder = RoutingBuilder();
    final configuredBuilder = configureRouting(routingBuilder);
    return configuredBuilder.build();
  }

  /// Quick setup with smart defaults
  static Future<FlexTrack> quickSetup(List<TrackerStrategy> trackers) async {
    return setup(trackers, autoInitialize: true);
  }

  /// Reset FlexTrack (useful for testing or reconfiguration)
  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!._client.dispose();
      _instance = null;
    }
  }

  // ========== INITIALIZATION ==========

  /// Initialize FlexTrack (set up trackers)
  Future<void> initialize() async {
    await _client.initialize();
  }

  // ========== EVENT TRACKING ==========

  /// Track a single event
  static Future<EventProcessingResult> track(BaseEvent event) async {
    return instance._client.track(event);
  }

  /// Track multiple events
  static Future<List<EventProcessingResult>> trackAll(
      List<BaseEvent> events) async {
    return instance._client.trackAll(events);
  }

  /// Track events in parallel (use with caution)
  static Future<List<EventProcessingResult>> trackParallel(
      List<BaseEvent> events) async {
    return instance._client.trackParallel(events);
  }

  // ========== CONSENT MANAGEMENT ==========

  /// Set general consent status
  static void setGeneralConsent(bool hasConsent) {
    instance._client.setGeneralConsent(hasConsent);
  }

  /// Set PII consent status
  static void setPIIConsent(bool hasConsent) {
    instance._client.setPIIConsent(hasConsent);
  }

  /// Set both consent types at once
  static void setConsent({bool? general, bool? pii}) {
    instance._client.setConsent(general: general, pii: pii);
  }

  /// Get current consent status
  static Map<String, bool> getConsentStatus() {
    return instance._client.getConsentStatus();
  }

  // ========== TRACKER MANAGEMENT ==========

  /// Enable a specific tracker
  static void enableTracker(String trackerId) {
    instance._client.enableTracker(trackerId);
  }

  /// Disable a specific tracker
  static void disableTracker(String trackerId) {
    instance._client.disableTracker(trackerId);
  }

  /// Enable all trackers
  static void enableAllTrackers() {
    instance._client.enableAllTrackers();
  }

  /// Disable all trackers
  static void disableAllTrackers() {
    instance._client.disableAllTrackers();
  }

  /// Check if a tracker is enabled
  static bool isTrackerEnabled(String trackerId) {
    return instance._client.isTrackerEnabled(trackerId);
  }

  /// Get all registered tracker IDs
  static Set<String> getTrackerIds() {
    return instance._client.getTrackerIds();
  }

  // ========== USER MANAGEMENT ==========

  /// Set user properties for all trackers
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    await instance._client.setUserProperties(properties);
  }

  /// Identify a user across all trackers
  static Future<void> identifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    await instance._client.identifyUser(userId, properties);
  }

  /// Reset all trackers (e.g., on user logout)
  static Future<void> resetTrackers() async {
    await instance._client.resetTrackers();
  }

  /// Flush all pending events
  static Future<void> flush() async {
    await instance._client.flush();
  }

  // ========== CONTROL ==========

  /// Enable event processing
  static void enable() {
    instance._client.enable();
  }

  /// Disable event processing
  static void disable() {
    instance._client.disable();
  }

  /// Check if FlexTrack is enabled
  static bool get isEnabled {
    return isSetUp && instance._client.isEnabled;
  }

  // ========== DEBUGGING ==========

  /// Get comprehensive debug information
  static Map<String, dynamic> getDebugInfo() {
    if (!isSetUp) {
      return {'error': 'FlexTrack is not set up'};
    }

    return {
      'isSetUp': isSetUp,
      'isInitialized': instance.isInitialized,
      'isEnabled': isEnabled,
      'eventProcessor': instance._client.eventProcessor.getDebugInfo(),
    };
  }

  /// Debug how an event would be routed
  static RoutingDebugInfo debugEvent(BaseEvent event) {
    return instance._client.debugEvent(event);
  }

  /// Validate the current configuration
  static List<String> validate() {
    if (!isSetUp) {
      return ['FlexTrack is not set up'];
    }

    return instance._client.validate();
  }

  /// Print debug information to console
  static void printDebugInfo() {
    if (!isSetUp) {
      debugPrint('FlexTrack is not set up');
      return;
    }
    instance._client.printDebugInfo();
  }

  @override
  String toString() {
    return 'FlexTrack(${_client.toString()})';
  }
}
