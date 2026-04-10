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
  });

  final BaseEvent event;

  /// Tracker ids the routing engine selected for this dispatch (may be empty).
  final List<String> targetTrackers;

  /// Subset of [targetTrackers] where `doTrack` completed successfully.
  final List<String> successfulTrackerIds;
}
