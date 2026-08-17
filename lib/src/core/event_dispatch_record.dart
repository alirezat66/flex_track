import '../models/event/base_event.dart';

/// Debug payload emitted after an event is processed: the [event] plus which
/// trackers were selected by routing and which received a successful `track`.
///
/// Used by [FlexTrackClient.eventDispatchStream] and the FlexTrack Inspector.
class EventDispatchRecord {
  const EventDispatchRecord({
    required this.event,
    this.targetTrackers = const [],
    this.successfulTrackerIds = const [],
    this.queuedTrackerIds = const [],
    this.queueSize = 0,
  });

  final BaseEvent event;

  /// Tracker ids the routing engine selected for this dispatch (may be empty).
  final List<String> targetTrackers;

  /// Subset of [targetTrackers] where `doTrack` completed successfully.
  final List<String> successfulTrackerIds;

  /// Subset of [targetTrackers] retained for a later delivery attempt.
  final List<String> queuedTrackerIds;

  /// Total number of events in the runtime queue after this dispatch.
  final int queueSize;
}
