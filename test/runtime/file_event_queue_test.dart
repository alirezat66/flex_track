import 'dart:io';

import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('flextrack-queue-');
    file = File('${directory.path}/queue.json');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('survives recreation and preserves event identity and metadata',
      () async {
    final original = _Event('stable-id');
    await FileEventQueue(file).enqueue(
      QueuedEvent(event: original, trackerIds: const ['a', 'b']),
    );

    final restored = (await FileEventQueue(file).read(limit: 10)).single;
    expect(restored.id, original.eventId);
    expect(restored.event.timestamp, original.timestamp);
    expect(restored.event.name, original.name);
    expect(restored.event.properties, original.properties);
    expect(restored.trackerIds, ['a', 'b']);
  });

  test('malformed JSON fails visibly without deleting persisted bytes',
      () async {
    await file.writeAsString('{broken');
    final queue = FileEventQueue(file);

    await expectLater(queue.read(limit: 10), throwsFormatException);
    expect(await file.readAsString(), '{broken');
  });

  test('invalid persisted shape fails visibly', () async {
    await file.writeAsString('{}');
    await expectLater(FileEventQueue(file).size(), throwsFormatException);
  });

  test('concurrent enqueue operations are serialized without loss', () async {
    final queue = FileEventQueue(file);
    await Future.wait([
      for (var i = 0; i < 50; i++)
        queue.enqueue(QueuedEvent(
          event: _Event('event-$i'),
          trackerIds: const ['analytics'],
        )),
    ]);

    expect(await queue.size(), 50);
    expect(
      (await queue.read(limit: 50)).map((value) => value.id),
      [for (var i = 0; i < 50; i++) 'event-$i'],
    );
  });

  test('non-positive read limit does not mutate storage', () async {
    final queue = FileEventQueue(file);
    await queue
        .enqueue(QueuedEvent(event: _Event('one'), trackerIds: const ['a']));
    await expectLater(queue.read(limit: 0), throwsArgumentError);
    expect(await queue.size(), 1);
  });
}

class _Event extends BaseEvent {
  _Event(String id)
      : super(eventId: id, timestamp: DateTime.utc(2026, 8, 17, 12, 30));
  @override
  String get name => 'purchase';
  @override
  Map<String, Object> get properties => const {
        'plan': 'pro',
        'nested': <String, Object>{'enabled': true},
        'items': <Object>[1, 'two'],
      };
  @override
  bool get requiresConsent => false;
}
