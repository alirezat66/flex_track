import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flutter/foundation.dart';

import '../exceptions/configuration_exception.dart';
import '../models/routing/routing_config.dart';
import '../routing/routing_builder.dart';
import '../routing/routing_engine.dart';
import '../strategies/tracker_strategy.dart';
import 'event_processor.dart';
import 'tracker_registry.dart';

/// Injectable analytics client: owns routing, consent state, and trackers for
/// this instance. Use [create] or [createWithRouting] instead of the global
/// [FlexTrack.setup] API when you want constructor injection, tests without
/// globals, or multiple isolated configurations.
class FlexTrackClient {
  FlexTrackClient._({
    required TrackerRegistry trackerRegistry,
    required EventProcessor eventProcessor,
  })  : _trackerRegistry = trackerRegistry,
        _eventProcessor = eventProcessor;

  final TrackerRegistry _trackerRegistry;
  final EventProcessor _eventProcessor;
  bool _isInitialized = false;

  /// Registry for this client (read-only use from outside).
  TrackerRegistry get trackerRegistry => _trackerRegistry;

  EventProcessor get eventProcessor => _eventProcessor;

  bool get isInitialized => _isInitialized;

  /// Whether event processing is enabled for this client.
  bool get isEnabled => _eventProcessor.isEnabled;

  /// Builds a new client with its own registry, routing engine, and processor.
  static Future<FlexTrackClient> create(
    List<TrackerStrategy> trackers, {
    RoutingConfiguration? routing,
    bool autoInitialize = true,
  }) async {
    if (trackers.isEmpty) {
      throw ConfigurationException(
        'At least one tracker must be provided',
        fieldName: 'trackers',
      );
    }

    final trackerRegistry = TrackerRegistry()..registerAll(trackers);
    final routingConfig = routing ?? RoutingConfiguration.withSmartDefaults();
    final routingEngine = RoutingEngine(routingConfig);
    final eventProcessor = EventProcessor(
      trackerRegistry: trackerRegistry,
      routingEngine: routingEngine,
    );

    final client = FlexTrackClient._(
      trackerRegistry: trackerRegistry,
      eventProcessor: eventProcessor,
    );

    if (autoInitialize) {
      await client.initialize();
    }
    return client;
  }

  /// Same as [create] but configures routing via [RoutingBuilder].
  static Future<FlexTrackClient> createWithRouting(
    List<TrackerStrategy> trackers,
    RoutingBuilder Function(RoutingBuilder) configureRouting, {
    bool autoInitialize = true,
  }) async {
    final routingBuilder = RoutingBuilder();
    final configuredBuilder = configureRouting(routingBuilder);
    final routingConfig = configuredBuilder.build();

    return create(
      trackers,
      routing: routingConfig,
      autoInitialize: autoInitialize,
    );
  }

  /// Initializes registered trackers. No-op if already initialized.
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _trackerRegistry.initialize();
      _isInitialized = true;
    } catch (e) {
      throw ConfigurationException(
        'Failed to initialize FlexTrackClient: $e',
        originalError: e,
        code: 'INITIALIZATION_FAILED',
      );
    }
  }

  Future<EventProcessingResult> track(BaseEvent event) =>
      _eventProcessor.processEvent(event);

  Future<List<EventProcessingResult>> trackAll(List<BaseEvent> events) =>
      _eventProcessor.processEvents(events);

  Future<List<EventProcessingResult>> trackParallel(List<BaseEvent> events) =>
      _eventProcessor.processEventsParallel(events);

  void setGeneralConsent(bool hasConsent) =>
      _eventProcessor.setGeneralConsent(hasConsent);

  void setPIIConsent(bool hasConsent) =>
      _eventProcessor.setPIIConsent(hasConsent);

  void setConsent({bool? general, bool? pii}) =>
      _eventProcessor.setConsent(general: general, pii: pii);

  Map<String, bool> getConsentStatus() => {
        'general': _eventProcessor.hasGeneralConsent,
        'pii': _eventProcessor.hasPIIConsent,
      };

  void enableTracker(String trackerId) => _trackerRegistry.enable(trackerId);

  void disableTracker(String trackerId) => _trackerRegistry.disable(trackerId);

  void enableAllTrackers() => _trackerRegistry.enableAll();

  void disableAllTrackers() => _trackerRegistry.disableAll();

  bool isTrackerEnabled(String trackerId) =>
      _trackerRegistry.isEnabled(trackerId);

  Set<String> getTrackerIds() => _trackerRegistry.registeredTrackerIds;

  Future<void> setUserProperties(Map<String, dynamic> properties) =>
      _trackerRegistry.setUserProperties(properties);

  Future<void> identifyUser(String userId,
          [Map<String, dynamic>? properties]) =>
      _trackerRegistry.identifyUser(userId, properties);

  Future<void> resetTrackers() => _trackerRegistry.reset();

  Future<void> flush() => _trackerRegistry.flush();

  void enable() => _eventProcessor.enable();

  void disable() => _eventProcessor.disable();

  Map<String, dynamic> getDebugInfo() => {
        'isInitialized': isInitialized,
        'isEnabled': isEnabled,
        'eventProcessor': _eventProcessor.getDebugInfo(),
      };

  RoutingDebugInfo debugEvent(BaseEvent event) {
    return _eventProcessor.routingEngine.debugEvent(
      event,
      hasGeneralConsent: _eventProcessor.hasGeneralConsent,
      hasPIIConsent: _eventProcessor.hasPIIConsent,
      availableTrackers: _trackerRegistry.registeredTrackerIds,
    );
  }

  List<String> validate() => _eventProcessor.validate();

  void printDebugInfo() {
    final info = getDebugInfo();
    debugPrint('=== FlexTrackClient Debug Info ===');
    debugPrint('Initialized: ${info['isInitialized']}');
    debugPrint('Enabled: ${info['isEnabled']}');

    final processor = info['eventProcessor'] as Map<String, dynamic>?;
    if (processor != null) {
      final trackerInfo = processor['trackerRegistry'] as Map<String, dynamic>;
      debugPrint(
          'Trackers: ${trackerInfo['trackerCount']} registered, ${trackerInfo['enabledTrackers']} enabled');
      debugPrint(
          'Consent: General=${processor['hasGeneralConsent']}, PII=${processor['hasPIIConsent']}');
    }
  }

  /// Flushes trackers if this client was initialized. Call when disposing
  /// the client (e.g. test tearDown). Does not reset initialization state;
  /// discard the client after [dispose] if you need a fresh configuration.
  Future<void> dispose() async {
    if (_isInitialized) {
      await _trackerRegistry.flush();
    }
  }

  @override
  String toString() =>
      'FlexTrackClient(initialized: $_isInitialized, trackers: ${_trackerRegistry.count})';
}
