import 'dart:async';

import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/event/event_transformer.dart';
import 'package:flutter/foundation.dart';

import '../routing/routing_engine.dart';
import '../exceptions/tracker_exception.dart';
import '../runtime/event_queue.dart';
import 'tracker_registry.dart';

/// Processes events through the routing system and sends them to appropriate trackers
class EventProcessor {
  final TrackerRegistry _trackerRegistry;
  final RoutingEngine _routingEngine;
  final List<EventTransformer> _transformers = [];
  final EventQueue _queue;
  final bool Function() _onlineProvider;
  Future<void> _flushTail = Future.value();

  bool _hasGeneralConsent = false;
  bool _hasPIIConsent = false;
  bool _isEnabled = true;

  EventProcessor({
    required TrackerRegistry trackerRegistry,
    required RoutingEngine routingEngine,
    EventQueue? queue,
    bool Function()? onlineProvider,
  })  : _trackerRegistry = trackerRegistry,
        _routingEngine = routingEngine,
        _queue = queue ?? InMemoryEventQueue(),
        _onlineProvider = onlineProvider ?? _alwaysOnline;

  EventQueue get queue => _queue;

  /// Get the routing engine (for debugging)
  RoutingEngine get routingEngine => _routingEngine;

  /// Whether the processor is enabled
  bool get isEnabled => _isEnabled;

  /// Current connectivity decision supplied by the host application.
  bool get isOnline => _onlineProvider();

  /// Current general consent status
  bool get hasGeneralConsent => _hasGeneralConsent;

  /// Current PII consent status
  bool get hasPIIConsent => _hasPIIConsent;

  /// Enable the event processor
  void enable() {
    _isEnabled = true;
  }

  /// Disable the event processor
  void disable() {
    _isEnabled = false;
  }

  /// Set general consent status
  void setGeneralConsent(bool hasConsent) {
    _hasGeneralConsent = hasConsent;
  }

  /// Set PII consent status
  void setPIIConsent(bool hasConsent) {
    _hasPIIConsent = hasConsent;
  }

  /// Set both consent statuses at once
  void setConsent({bool? general, bool? pii}) {
    if (general != null) _hasGeneralConsent = general;
    if (pii != null) _hasPIIConsent = pii;
  }

  /// Register a transformer that will be applied to every event before routing.
  void addTransformer(EventTransformer transformer) {
    _transformers.add(transformer);
  }

  /// Remove a previously registered transformer.
  void removeTransformer(EventTransformer transformer) {
    _transformers.remove(transformer);
  }

  /// Remove all registered transformers.
  void clearTransformers() {
    _transformers.clear();
  }

  /// The currently registered transformers (unmodifiable).
  List<EventTransformer> get transformers => List.unmodifiable(_transformers);

  BaseEvent _applyTransformers(BaseEvent event) {
    var current = event;
    for (final transformer in _transformers) {
      try {
        current = transformer(current);
      } catch (e, stack) {
        assert(() {
          debugPrint('[FlexTrack] Transformer threw, skipping: $e\n$stack');
          return true;
        }());
      }
    }
    return current;
  }

  /// Process a single event
  Future<EventProcessingResult> processEvent(BaseEvent event) async {
    if (!_isEnabled) {
      return EventProcessingResult(
        event: event,
        routingResult: RoutingResult(
          event: event,
          targetTrackers: [],
          appliedRules: [],
          skippedRules: [],
          warnings: ['Event processor is disabled'],
        ),
        trackingResults: [],
        successful: false,
      );
    }

    final processedEvent = _applyTransformers(event);

    // Route the event to determine target trackers
    final routingResult = _routingEngine.routeEvent(
      processedEvent,
      hasGeneralConsent: _hasGeneralConsent,
      hasPIIConsent: _hasPIIConsent,
      availableTrackers: _trackerRegistry.registeredTrackerIds,
    );

    // If no trackers to send to, return early
    if (routingResult.targetTrackers.isEmpty) {
      return EventProcessingResult(
        event: processedEvent,
        routingResult: routingResult,
        trackingResults: [],
        successful: false,
      );
    }

    if (!_onlineProvider()) {
      await _queue.enqueue(QueuedEvent(
        event: processedEvent,
        trackerIds: routingResult.targetTrackers,
      ));
      return EventProcessingResult(
        event: processedEvent,
        routingResult: routingResult,
        trackingResults: const [],
        successful: false,
        queuedTrackerIds: routingResult.targetTrackers,
      );
    }

    final trackingResults = await Future.wait(
      routingResult.targetTrackers.map(
        (trackerId) => _deliver(processedEvent, trackerId),
      ),
    );
    final failedTrackerIds = [
      for (final result in trackingResults)
        if (!result.successful) result.trackerId,
    ];
    if (failedTrackerIds.isNotEmpty) {
      await _queue.enqueue(QueuedEvent(
        event: processedEvent,
        trackerIds: failedTrackerIds,
      ));
    }

    return EventProcessingResult(
      event: processedEvent,
      routingResult: routingResult,
      trackingResults: trackingResults,
      successful: trackingResults.any((result) => result.successful),
      queuedTrackerIds: failedTrackerIds,
    );
  }

  Future<TrackingResult> _deliver(BaseEvent event, String trackerId) async {
    final tracker = _trackerRegistry.get(trackerId);

    if (tracker == null) {
      return TrackingResult(
        trackerId: trackerId,
        successful: false,
        error: TrackerException(
          'Tracker not found: $trackerId',
          trackerId: trackerId,
          eventName: event.name,
          code: 'NOT_FOUND',
        ),
      );
    }

    if (!tracker.isEnabled) {
      return TrackingResult(
        trackerId: trackerId,
        successful: false,
        error: TrackerException(
          'Tracker is disabled: $trackerId',
          trackerId: trackerId,
          eventName: event.name,
          code: 'DISABLED',
        ),
      );
    }

    try {
      await tracker.track(event);
      return TrackingResult(
        trackerId: trackerId,
        successful: true,
      );
    } catch (e) {
      return TrackingResult(
        trackerId: trackerId,
        successful: false,
        error: e is TrackerException
            ? e
            : TrackerException(
                'Failed to track event: $e',
                trackerId: trackerId,
                eventName: event.name,
                originalError: e,
              ),
      );
    }
  }

  Future<QueueFlushResult> flushQueue({int limit = 100}) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    final completer = Completer<QueueFlushResult>();
    _flushTail = _flushTail.then((_) async {
      try {
        completer.complete(await _flushQueuePass(limit));
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<QueueFlushResult> _flushQueuePass(int limit) async {
    if (!_onlineProvider()) {
      return QueueFlushResult(0, 0, await _queue.size());
    }
    final items = await _queue.read(limit: limit);
    var delivered = 0;
    for (final item in items) {
      final results = await Future.wait(
        item.trackerIds.map((id) => _deliver(item.event, id)),
      );
      final failures = [
        for (final result in results)
          if (!result.successful) result.trackerId,
      ];
      if (failures.isEmpty) {
        await _queue.remove(item.id);
        delivered++;
      } else {
        await _queue.replace(item.copyWith(
          trackerIds: failures,
          attempts: item.attempts + 1,
        ));
      }
    }
    return QueueFlushResult(items.length, delivered, await _queue.size());
  }

  /// Process multiple events as a batch
  Future<List<EventProcessingResult>> processEvents(
      List<BaseEvent> events) async {
    final results = <EventProcessingResult>[];

    for (final event in events) {
      final result = await processEvent(event);
      results.add(result);
    }

    return results;
  }

  /// Process events in parallel (use with caution for high volumes)
  Future<List<EventProcessingResult>> processEventsParallel(
      List<BaseEvent> events) async {
    final futures = events.map((event) => processEvent(event));
    return await Future.wait(futures);
  }

  /// Get debug information about the processor
  Map<String, dynamic> getDebugInfo() {
    return {
      'isEnabled': _isEnabled,
      'hasGeneralConsent': _hasGeneralConsent,
      'hasPIIConsent': _hasPIIConsent,
      'transformerCount': _transformers.length,
      'trackerRegistry': _trackerRegistry.getDebugInfo(),
      'routingEngine': {
        'configuration': _routingEngine.configuration.toMap(),
      },
    };
  }

  /// Validate the processor configuration
  List<String> validate() {
    final issues = <String>[];

    // Validate tracker registry
    issues.addAll(_trackerRegistry.validate());

    // Validate routing configuration
    issues.addAll(_routingEngine.validateConfiguration());

    return issues;
  }
}

/// Result of processing an event
class EventProcessingResult {
  final BaseEvent event;
  final RoutingResult routingResult;
  final List<TrackingResult> trackingResults;
  final bool successful;
  final List<String> queuedTrackerIds;

  const EventProcessingResult({
    required this.event,
    required this.routingResult,
    required this.trackingResults,
    required this.successful,
    this.queuedTrackerIds = const [],
  });

  /// Returns true if the event was routed to at least one tracker
  bool get wasRouted => routingResult.targetTrackers.isNotEmpty;

  /// Returns true if at least one tracker successfully tracked the event
  bool get wasTracked => trackingResults.any((result) => result.successful);

  /// Returns the number of successful tracking attempts
  int get successfulTrackingCount =>
      trackingResults.where((result) => result.successful).length;

  /// Returns the number of failed tracking attempts
  int get failedTrackingCount =>
      trackingResults.where((result) => !result.successful).length;

  /// Returns all errors that occurred during tracking
  List<Exception> get trackingErrors => trackingResults
      .where((result) => result.error != null)
      .map((result) => result.error!)
      .toList();

  /// Converts to a map for debugging/logging
  Map<String, dynamic> toMap() {
    return {
      'event': event.toMap(),
      'routingResult': routingResult.toMap(),
      'trackingResults':
          trackingResults.map((result) => result.toMap()).toList(),
      'successful': successful,
      'wasRouted': wasRouted,
      'wasTracked': wasTracked,
      'successfulTrackingCount': successfulTrackingCount,
      'failedTrackingCount': failedTrackingCount,
      'hasErrors': trackingErrors.isNotEmpty,
      'queuedTrackerIds': queuedTrackerIds,
    };
  }

  @override
  String toString() {
    return 'EventProcessingResult('
        'event: ${event.name}, '
        'routed: $wasRouted, '
        'tracked: $wasTracked, '
        'successful: $successfulTrackingCount/${trackingResults.length}'
        ')';
  }
}

class QueueFlushResult {
  const QueueFlushResult(
    this.attemptedEvents,
    this.deliveredEvents,
    this.remainingEvents,
  );

  final int attemptedEvents;
  final int deliveredEvents;
  final int remainingEvents;
}

bool _alwaysOnline() => true;

/// Result of tracking an event with a specific tracker
class TrackingResult {
  final String trackerId;
  final bool successful;
  final Exception? error;
  final DateTime timestamp;

  TrackingResult({
    required this.trackerId,
    required this.successful,
    this.error,
  }) : timestamp = DateTime.now();

  /// Converts to a map for debugging/logging
  Map<String, dynamic> toMap() {
    return {
      'trackerId': trackerId,
      'successful': successful,
      'error': error?.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TrackingResult($trackerId: ${successful ? 'success' : 'failed'})';
  }
}
