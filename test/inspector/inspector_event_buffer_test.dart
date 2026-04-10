import 'package:flex_track/src/core/event_dispatch_record.dart';
import 'package:flex_track/src/inspector/inspector_event_buffer.dart';
import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flex_track/src/models/routing/event_category.dart';
import 'package:flutter_test/flutter_test.dart';

class _BufEvent extends BaseEvent {
  _BufEvent(this._name, {this.cat});

  final String _name;
  final EventCategory? cat;

  @override
  String getName() => _name;

  @override
  Map<String, Object>? getProperties() => {'n': 1};

  @override
  EventCategory? get category => cat;

  @override
  bool get isEssential => true;
}

EventDispatchRecord _rec(BaseEvent e, {List<String>? t, List<String>? ok}) {
  return EventDispatchRecord(
    event: e,
    targetTrackers: t ?? const [],
    successfulTrackerIds: ok ?? const [],
  );
}

void main() {
  test('drops oldest when over cap', () {
    final buf = InspectorEventBuffer();
    for (var i = 0; i < flexTrackInspectorMaxEvents + 5; i++) {
      buf.append(_rec(_BufEvent('e$i')), 'id-$i', '00:00:00.000');
    }
    expect(buf.snapshot.length, flexTrackInspectorMaxEvents);
    expect(buf.snapshot.first.name, 'e5');
    expect(buf.snapshot.last.name, 'e${flexTrackInspectorMaxEvents + 4}');
  });

  test('clear removes all', () {
    final buf = InspectorEventBuffer();
    buf.append(_rec(_BufEvent('a')), '1', 't');
    buf.clear();
    expect(buf.snapshot, isEmpty);
  });

  test('toEventPayload includes tracker routing fields', () {
    final buf = InspectorEventBuffer();
    final rec = buf.append(
      _rec(
        _BufEvent('x', cat: EventCategory.business),
        t: const ['console', 'firebase'],
        ok: const ['console'],
      ),
      'uuid',
      '12:00:00.001',
    );
    final p = rec.toEventPayload();
    expect(p['id'], 'uuid');
    expect(p['name'], 'x');
    expect(p['category'], 'business');
    expect(p['targetTrackers'], ['console', 'firebase']);
    expect(p['successfulTrackerIds'], ['console']);
    expect(p['flags'], {
      'essential': true,
      'highVolume': false,
      'containsPII': false,
    });
  });
}
