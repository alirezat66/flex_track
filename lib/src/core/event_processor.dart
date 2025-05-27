import 'package:flex_track/src/models/event/base_event.dart';

import '../routing/routing_engine.dart';
import '../exceptions/tracker_exception.dart';
import 'tracker_registry.dart';

/// Processes events through the routing system and sends them to appropriate trackers
class EventProcessor {
  final TrackerRegistry _trackerRegistry;
  final RoutingEngine _routingEngine;

  bool _hasGeneralConsent = true;
  bool _hasPIIConsent = true;
  bool _isEnabled = true;

  EventProcessor({
    required TrackerRegistry trackerRegistry,
    required RoutingEngine routingEngine,
  })  : _trackerRegistry = trackerRegistry,
        _routingEngine = routingEngine;

  /// Get the routing engine (for debugging)
  RoutingEngine get routingEngine => _routingEngine;

  /// Whether the processor is enabled
  bool get isEnabled => _isEnabled;

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

    // Route the event to determine target trackers
    final routingResult = _routingEngine.routeEvent(
      event,
      hasGeneralConsent: _hasGeneralConsent,
      hasPIIConsent: _hasPIIConsent,
      availableTrackers: _trackerRegistry.registeredTrackerIds,
    );

    // If no trackers to send to, return early
    if (routingResult.targetTrackers.isEmpty) {
      return EventProcessingResult(
        event: event,
        routingResult: routingResult,
        trackingResults: [],
        successful: false,
      );
    }

    // Send event to target trackers
    final trackingResults = <TrackingResult>[];
    bool anySuccessful = false;

    for (final trackerId in routingResult.targetTrackers) {
      final tracker = _trackerRegistry.get(trackerId);

      if (tracker == null) {
        trackingResults.add(TrackingResult(
          trackerId: trackerId,
          successful: false,
          error: TrackerException(
            'Tracker not found: $trackerId',
            trackerId: trackerId,
            eventName: event.name,
            code: 'NOT_FOUND',
          ),
        ));
        continue;
      }

      if (!tracker.isEnabled) {
        trackingResults.add(TrackingResult(
          trackerId: trackerId,
          successful: false,
          error: TrackerException(
            'Tracker is disabled: $trackerId',
            trackerId: trackerId,
            eventName: event.name,
            code: 'DISABLED',
          ),
        ));
        continue;
      }

      try {
        await tracker.track(event);
        trackingResults.add(TrackingResult(
          trackerId: trackerId,
          successful: true,
        ));
        anySuccessful = true;
      } catch (e) {
        trackingResults.add(TrackingResult(
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
        ));
      }
    }

    return EventProcessingResult(
      event: event,
      routingResult: routingResult,
      trackingResults: trackingResults,
      successful: anySuccessful,
    );
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

  const EventProcessingResult({
    required this.event,
    required this.routingResult,
    required this.trackingResults,
    required this.successful,
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
