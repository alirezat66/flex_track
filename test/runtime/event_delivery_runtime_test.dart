import 'dart:async';
import 'dart:io';

import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('retry never reruns transformers or redelivers successful targets',
      () async {
    var transforms = 0;
    final success = _Tracker('success');
    final retry = _Tracker('retry', failCount: 1);
    final client = await _client([success, retry]);
    client.addTransformer((event) {
      transforms++;
      return EnrichedEvent(event, const {'transform': 'once'});
    });

    final first = await client.track(_Event('event-1'));
    expect(first.queuedTrackerIds, ['retry']);
    await client.flushQueue();

    expect(transforms, 1);
    expect(success.events, hasLength(1));
    expect(retry.events, hasLength(2));
    expect(retry.events.last.properties, containsPair('transform', 'once'));
    expect(await client.queuedEventCount, 0);
  });

  test('concurrent flush calls cannot duplicate a queued delivery', () async {
    final gate = Completer<void>();
    final tracker = _Tracker('analytics', gate: gate.future);
    final queue = InMemoryEventQueue();
    final client = await _client([tracker], queue: queue);
    await queue.enqueue(QueuedEvent(
      event: _Event('event-1'),
      trackerIds: const ['analytics'],
    ));

    final first = client.flushQueue();
    final second = client.flushQueue();
    await Future<void>.delayed(Duration.zero);
    expect(tracker.events, hasLength(1));
    gate.complete();

    expect((await first).deliveredEvents, 1);
    expect((await second).attemptedEvents, 0);
    expect(tracker.events, hasLength(1));
  });

  test('queue read result cannot mutate in-memory queue state', () async {
    final queue = InMemoryEventQueue();
    await queue.enqueue(QueuedEvent(
      event: _Event('event-1'),
      trackerIds: const ['analytics'],
    ));
    final result = await queue.read(limit: 10);

    expect(() => result.clear(), throwsUnsupportedError);
    expect(() => result.single.trackerIds.clear(), throwsUnsupportedError);
    expect(await queue.size(), 1);
  });

  test('serialization failure never replaces a valid durable queue', () async {
    final directory =
        await Directory.systemTemp.createTemp('flextrack-atomic-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/queue.json');
    final queue = FileEventQueue(file);
    await queue.enqueue(QueuedEvent(
      event: _Event('valid'),
      trackerIds: const ['analytics'],
    ));
    final originalBytes = await file.readAsBytes();

    await expectLater(
      queue.enqueue(QueuedEvent(
        event: _UnsupportedEvent('invalid'),
        trackerIds: const ['analytics'],
      )),
      throwsA(anything),
    );
    expect(await file.readAsBytes(), originalBytes);
    expect((await queue.read(limit: 10)).single.id, 'valid');
  });
}

Future<FlexTrackClient> _client(List<_Tracker> trackers, {EventQueue? queue}) =>
    FlexTrackClient.create(
      trackers,
      queue: queue,
      routing: RoutingConfiguration(
        rules: [
          RoutingRule(
            targetGroup: TrackerGroup(
              'all',
              trackers.map((value) => value.id).toList(),
            ),
            requireConsent: false,
          ),
        ],
      ),
    );

class _Event extends BaseEvent {
  _Event(String id) : super(eventId: id, timestamp: DateTime.utc(2026, 8, 17));
  @override
  String get name => 'purchase';
  @override
  Map<String, Object> get properties => const {'plan': 'pro'};
  @override
  bool get requiresConsent => false;
}

class _UnsupportedEvent extends _Event {
  _UnsupportedEvent(super.id);
  @override
  Map<String, Object> get properties => {'unsupported': Object()};
}

class _Tracker extends TrackerStrategy {
  _Tracker(this.id, {this.failCount = 0, this.gate});
  @override
  final String id;
  int failCount;
  final Future<void>? gate;
  final List<BaseEvent> events = [];
  bool _enabled = true;
  @override
  String get name => id;
  @override
  bool get isEnabled => _enabled;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> track(BaseEvent event) async {
    events.add(event);
    if (gate != null) await gate;
    if (failCount > 0) {
      failCount--;
      throw StateError('failure');
    }
  }

  @override
  void enable() => _enabled = true;
  @override
  void disable() => _enabled = false;
}
