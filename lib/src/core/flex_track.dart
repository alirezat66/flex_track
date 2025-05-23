import 'package:flex_track/src/models/event/base_event.dart';

import '../models/routing/routing_config.dart';
import '../routing/routing_engine.dart';
import '../routing/routing_builder.dart';
import '../strategies/tracker_strategy.dart';
import '../exceptions/configuration_exception.dart';
import 'tracker_registry.dart';
import 'event_processor.dart';

/// Main FlexTrack class - the entry point for the analytics routing system
class FlexTrack {
  static FlexTrack? _instance;

  final TrackerRegistry _trackerRegistry;
  final EventProcessor _eventProcessor;
  bool _isInitialized = false;

  FlexTrack._({
    required TrackerRegistry trackerRegistry,
    required EventProcessor eventProcessor,
  })  : _trackerRegistry = trackerRegistry,
        _eventProcessor = eventProcessor;

  /// Get the singleton instance of FlexTrack
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
  bool get isInitialized => _isInitialized;

  /// Get the tracker registry
  TrackerRegistry get trackerRegistry => _trackerRegistry;

  /// Get the event processor
  EventProcessor get eventProcessor => _eventProcessor;

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

    if (trackers.isEmpty) {
      throw ConfigurationException(
        'At least one tracker must be provided',
        fieldName: 'trackers',
      );
    }

    // Create tracker registry and register trackers
    final trackerRegistry = TrackerRegistry();
    trackerRegistry.registerAll(trackers);

    // Use provided routing or create smart defaults
    final routingConfig = routing ?? RoutingConfiguration.withSmartDefaults();

    // Create routing engine
    final routingEngine = RoutingEngine(routingConfig);

    // Create event processor
    final eventProcessor = EventProcessor(
      trackerRegistry: trackerRegistry,
      routingEngine: routingEngine,
    );

    // Create FlexTrack instance
    _instance = FlexTrack._(
      trackerRegistry: trackerRegistry,
      eventProcessor: eventProcessor,
    );

    // Auto-initialize if requested
    if (autoInitialize) {
      await _instance!.initialize();
    }

    return _instance!;
  }

  /// Set up FlexTrack with a routing builder for more control
  static Future<FlexTrack> setupWithRouting(
    List<TrackerStrategy> trackers,
    RoutingBuilder Function(RoutingBuilder) configureRouting, {
    bool autoInitialize = true,
  }) async {
    final routingBuilder = RoutingBuilder();
    final configuredBuilder = configureRouting(routingBuilder);
    final routingConfig = configuredBuilder.build();

    return setup(
      trackers,
      routing: routingConfig,
      autoInitialize: autoInitialize,
    );
  }

  /// Quick setup with smart defaults
  static Future<FlexTrack> quickSetup(List<TrackerStrategy> trackers) async {
    return setup(trackers, autoInitialize: true);
  }

  /// Reset FlexTrack (useful for testing or reconfiguration)
  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!._cleanup();
      _instance = null;
    }
  }

  // ========== INITIALIZATION ==========

  /// Initialize FlexTrack (set up trackers)
  Future<void> initialize() async {
    if (_isInitialized) {
      return; // Already initialized
    }

    try {
      await _trackerRegistry.initialize();
      _isInitialized = true;
    } catch (e) {
      throw ConfigurationException(
        'Failed to initialize FlexTrack: $e',
        originalError: e,
        code: 'INITIALIZATION_FAILED',
      );
    }
  }

  // ========== EVENT TRACKING ==========

  /// Track a single event
  static Future<EventProcessingResult> track(BaseEvent event) async {
    return instance._eventProcessor.processEvent(event);
  }

  /// Track multiple events
  static Future<List<EventProcessingResult>> trackAll(
      List<BaseEvent> events) async {
    return instance._eventProcessor.processEvents(events);
  }

  /// Track events in parallel (use with caution)
  static Future<List<EventProcessingResult>> trackParallel(
      List<BaseEvent> events) async {
    return instance._eventProcessor.processEventsParallel(events);
  }

  // ========== CONSENT MANAGEMENT ==========

  /// Set general consent status
  static void setGeneralConsent(bool hasConsent) {
    instance._eventProcessor.setGeneralConsent(hasConsent);
  }

  /// Set PII consent status
  static void setPIIConsent(bool hasConsent) {
    instance._eventProcessor.setPIIConsent(hasConsent);
  }

  /// Set both consent types at once
  static void setConsent({bool? general, bool? pii}) {
    instance._eventProcessor.setConsent(general: general, pii: pii);
  }

  /// Get current consent status
  static Map<String, bool> getConsentStatus() {
    final processor = instance._eventProcessor;
    return {
      'general': processor.hasGeneralConsent,
      'pii': processor.hasPIIConsent,
    };
  }

  // ========== TRACKER MANAGEMENT ==========

  /// Enable a specific tracker
  static void enableTracker(String trackerId) {
    instance._trackerRegistry.enable(trackerId);
  }

  /// Disable a specific tracker
  static void disableTracker(String trackerId) {
    instance._trackerRegistry.disable(trackerId);
  }

  /// Enable all trackers
  static void enableAllTrackers() {
    instance._trackerRegistry.enableAll();
  }

  /// Disable all trackers
  static void disableAllTrackers() {
    instance._trackerRegistry.disableAll();
  }

  /// Check if a tracker is enabled
  static bool isTrackerEnabled(String trackerId) {
    return instance._trackerRegistry.isEnabled(trackerId);
  }

  /// Get all registered tracker IDs
  static Set<String> getTrackerIds() {
    return instance._trackerRegistry.registeredTrackerIds;
  }

  // ========== USER MANAGEMENT ==========

  /// Set user properties for all trackers
  static Future<void> setUserProperties(Map<String, dynamic> properties) async {
    await instance._trackerRegistry.setUserProperties(properties);
  }

  /// Identify a user across all trackers
  static Future<void> identifyUser(String userId,
      [Map<String, dynamic>? properties]) async {
    await instance._trackerRegistry.identifyUser(userId, properties);
  }

  /// Reset all trackers (e.g., on user logout)
  static Future<void> resetTrackers() async {
    await instance._trackerRegistry.reset();
  }

  /// Flush all pending events
  static Future<void> flush() async {
    await instance._trackerRegistry.flush();
  }

  // ========== CONTROL ==========

  /// Enable event processing
  static void enable() {
    instance._eventProcessor.enable();
  }

  /// Disable event processing
  static void disable() {
    instance._eventProcessor.disable();
  }

  /// Check if FlexTrack is enabled
  static bool get isEnabled {
    return isSetUp && instance._eventProcessor.isEnabled;
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
      'eventProcessor': instance._eventProcessor.getDebugInfo(),
    };
  }

  /// Debug how an event would be routed
  static RoutingDebugInfo debugEvent(BaseEvent event) {
    return instance._eventProcessor.routingEngine.debugEvent(
      event,
      hasGeneralConsent: instance._eventProcessor.hasGeneralConsent,
      hasPIIConsent: instance._eventProcessor.hasPIIConsent,
      availableTrackers: instance._trackerRegistry.registeredTrackerIds,
    );
  }

  /// Validate the current configuration
  static List<String> validate() {
    if (!isSetUp) {
      return ['FlexTrack is not set up'];
    }

    return instance._eventProcessor.validate();
  }

  /// Print debug information to console
  static void printDebugInfo() {
    final info = getDebugInfo();
    print('=== FlexTrack Debug Info ===');
    print('Setup: ${info['isSetUp']}');
    print('Initialized: ${info['isInitialized']}');
    print('Enabled: ${info['isEnabled']}');

    if (info['eventProcessor'] != null) {
      final processor = info['eventProcessor'] as Map<String, dynamic>;
      final trackerInfo = processor['trackerRegistry'] as Map<String, dynamic>;
      print(
          'Trackers: ${trackerInfo['trackerCount']} registered, ${trackerInfo['enabledTrackers']} enabled');
      print(
          'Consent: General=${processor['hasGeneralConsent']}, PII=${processor['hasPIIConsent']}');
    }
  }

  // ========== INTERNAL METHODS ==========

  /// Clean up resources
  Future<void> _cleanup() async {
    if (_isInitialized) {
      await _trackerRegistry.flush();
    }
  }

  @override
  String toString() {
    return 'FlexTrack(initialized: $_isInitialized, trackers: ${_trackerRegistry.count})';
  }
}
