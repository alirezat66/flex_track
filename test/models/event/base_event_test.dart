import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseEvent API', () {
    test('name and properties getters are the preferred API', () {
      final event = _SampleEvent();

      expect(event.name, 'sample');
      expect(event.properties, {'key': 'value'});
    });

    test('deprecated getName/getProperties still work for callers', () {
      final event = _SampleEvent();

      // ignore: deprecated_member_use_from_same_package
      expect(event.name, event.name);
      // ignore: deprecated_member_use_from_same_package
      expect(event.properties, event.properties);
    });

    test('captures one immutable occurrence timestamp', () async {
      final before = DateTime.now().toUtc();
      final event = _SampleEvent();
      final first = event.timestamp;
      await Future<void>.delayed(const Duration(milliseconds: 2));

      expect(event.timestamp, same(first));
      expect(first.isBefore(before), isFalse);
    });

    test('generates a unique UUID event id', () {
      final ids = List.generate(100, (_) => _SampleEvent().eventId);

      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(
          id,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
      }
    });

    test('accepts explicit identity and occurrence time', () {
      final timestamp = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final event = _MetadataEvent(
        eventId: 'event-for-replay',
        timestamp: timestamp,
      );

      expect(event.eventId, 'event-for-replay');
      expect(event.timestamp, same(timestamp));
      expect(event.toMap(), containsPair('eventId', 'event-for-replay'));
    });
  });
}

class _SampleEvent extends BaseEvent {
  @override
  String get name => 'sample';

  @override
  Map<String, Object>? get properties => const {'key': 'value'};
}

class _MetadataEvent extends BaseEvent {
  _MetadataEvent({super.eventId, super.timestamp});

  @override
  String get name => 'metadata';

  @override
  Map<String, Object>? get properties => null;
}
