import 'package:flex_track/src/core/event_dispatch_record.dart';

import 'inspector_json.dart';

const int flexTrackInspectorMaxEvents = 200;

/// In-memory ring of inspector event records (newest at end).
class InspectorEventBuffer {
  final List<InspectorEventRecord> _items = [];

  List<InspectorEventRecord> get snapshot => List.unmodifiable(_items);

  void clear() => _items.clear();

  InspectorEventRecord append(
    EventDispatchRecord dispatch,
    String id,
    String timeLabel,
  ) {
    final rec = InspectorEventRecord.fromDispatch(
      id: id,
      timeLabel: timeLabel,
      dispatch: dispatch,
    );
    _items.add(rec);
    while (_items.length > flexTrackInspectorMaxEvents) {
      _items.removeAt(0);
    }
    return rec;
  }
}

/// One row in the inspector log, aligned with WebSocket / REST JSON shape.
class InspectorEventRecord {
  InspectorEventRecord({
    required this.id,
    required this.timeLabel,
    required this.name,
    required this.category,
    required this.properties,
    required this.flags,
    required this.targetTrackers,
    required this.successfulTrackerIds,
  });

  final String id;
  final String timeLabel;
  final String name;
  final String? category;
  final Map<String, Object?>? properties;
  final Map<String, bool> flags;
  final List<String> targetTrackers;
  final List<String> successfulTrackerIds;

  factory InspectorEventRecord.fromDispatch({
    required String id,
    required String timeLabel,
    required EventDispatchRecord dispatch,
  }) {
    final event = dispatch.event;
    return InspectorEventRecord(
      id: id,
      timeLabel: timeLabel,
      name: event.getName(),
      category: event.category?.name,
      properties: jsonSafeProperties(event.getProperties()),
      flags: {
        'essential': event.isEssential,
        'highVolume': event.isHighVolume,
        'containsPII': event.containsPII,
      },
      targetTrackers: List<String>.from(dispatch.targetTrackers),
      successfulTrackerIds: List<String>.from(dispatch.successfulTrackerIds),
    );
  }

  Map<String, Object?> toEventPayload() {
    return {
      'id': id,
      'timestamp': timeLabel,
      'name': name,
      'category': category,
      'properties': properties ?? <String, Object?>{},
      'flags': flags,
      'targetTrackers': targetTrackers,
      'successfulTrackerIds': successfulTrackerIds,
    };
  }

  Map<String, Object?> toWsMessage() {
    return {
      'type': 'event',
      'data': toEventPayload(),
    };
  }
}
