import 'dart:async';

import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/event/event_transformer.dart';
import 'package:flutter/foundation.dart';

import '../exceptions/configuration_exception.dart';
import '../models/routing/routing_config.dart';
import '../routing/routing_builder.dart';
import '../routing/routing_engine.dart';
import '../strategies/tracker_strategy.dart';
import 'event_dispatch_record.dart';
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

  final StreamController<EventDispatchRecord> _dispatchStreamController =
      StreamController<EventDispatchRecord>.broadcast(sync: true);
  final StreamController<void> _debugStateController =
      StreamController<void>.broadcast(sync: true);

  /// Registry for this client (read-only use from outside).
  TrackerRegistry get trackerRegistry => _trackerRegistry;

  EventProcessor get eventProcessor => _eventProcessor;

  bool get isInitialized => _isInitialized;

  /// Whether event processing is enabled for this client.
  bool get isEnabled => _eventProcessor.isEnabled;

  /// Debug-only stream of each processed event with routing and delivery
  /// metadata. Empty/no-op in release mode.
  Stream<EventDispatchRecord> get eventDispatchStream =>
      _dispatchStreamController.stream;

  /// Debug-only stream of every [BaseEvent] passed to [track], [trackAll], or
  /// [trackParallel] after processing completes (same as [eventDispatchStream]
  /// mapped to [EventDispatchRecord.event]). Empty/no-op in release mode.
  Stream<BaseEvent> get eventStream =>
      _dispatchStreamController.stream.map((r) => r.event);

  /// Debug-only stream that emits when consent, tracker enablement, or
  /// processor enable flag changes. Empty/no-op in release mode.
  Stream<void> get debugStateStream => _debugStateController.stream;

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

  Future<EventProcessingResult> track(BaseEvent event) async {
    final result = await _eventProcessor.processEvent(event);
    _emitDispatchIfDebug(_recordFromResult(result));
    return result;
  }

  Future<List<EventProcessingResult>> trackAll(List<BaseEvent> events) async {
    final results = await _eventProcessor.processEvents(events);
    if (kDebugMode) {
      for (final result in results) {
        _emitDispatchIfDebug(_recordFromResult(result));
      }
    }
    return results;
  }

  Future<List<EventProcessingResult>> trackParallel(
      List<BaseEvent> events) async {
    final results = await _eventProcessor.processEventsParallel(events);
    if (kDebugMode) {
      for (final result in results) {
        _emitDispatchIfDebug(_recordFromResult(result));
      }
    }
    return results;
  }

  void setGeneralConsent(bool hasConsent) {
    _eventProcessor.setGeneralConsent(hasConsent);
    _notifyDebugStateIfDebug();
  }

  void setPIIConsent(bool hasConsent) {
    _eventProcessor.setPIIConsent(hasConsent);
    _notifyDebugStateIfDebug();
  }

  void setConsent({bool? general, bool? pii}) {
    _eventProcessor.setConsent(general: general, pii: pii);
    _notifyDebugStateIfDebug();
  }

  Map<String, bool> getConsentStatus() => {
        'general': _eventProcessor.hasGeneralConsent,
        'pii': _eventProcessor.hasPIIConsent,
      };

  void enableTracker(String trackerId) {
    _trackerRegistry.enable(trackerId);
    _notifyDebugStateIfDebug();
  }

  void disableTracker(String trackerId) {
    _trackerRegistry.disable(trackerId);
    _notifyDebugStateIfDebug();
  }

  void enableAllTrackers() {
    _trackerRegistry.enableAll();
    _notifyDebugStateIfDebug();
  }

  void disableAllTrackers() {
    _trackerRegistry.disableAll();
    _notifyDebugStateIfDebug();
  }

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

  void addTransformer(EventTransformer transformer) =>
      _eventProcessor.addTransformer(transformer);

  void removeTransformer(EventTransformer transformer) =>
      _eventProcessor.removeTransformer(transformer);

  void clearTransformers() => _eventProcessor.clearTransformers();

  void enable() {
    _eventProcessor.enable();
    _notifyDebugStateIfDebug();
  }

  void disable() {
    _eventProcessor.disable();
    _notifyDebugStateIfDebug();
  }

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

  static EventDispatchRecord _recordFromResult(EventProcessingResult result) {
    final targets = List<String>.from(result.routingResult.targetTrackers);
    final ok = <String>[
      for (final t in result.trackingResults)
        if (t.successful) t.trackerId,
    ];
    return EventDispatchRecord(
      event: result.event,
      targetTrackers: targets,
      successfulTrackerIds: ok,
    );
  }

  void _emitDispatchIfDebug(EventDispatchRecord record) {
    if (kDebugMode && !_dispatchStreamController.isClosed) {
      _dispatchStreamController.add(record);
    }
  }

  void _notifyDebugStateIfDebug() {
    if (kDebugMode && !_debugStateController.isClosed) {
      _debugStateController.add(null);
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      await _trackerRegistry.flush();
    }
    await _dispatchStreamController.close();
    await _debugStateController.close();
  }

  @override
  String toString() =>
      'FlexTrackClient(initialized: $_isInitialized, trackers: ${_trackerRegistry.count})';
}
