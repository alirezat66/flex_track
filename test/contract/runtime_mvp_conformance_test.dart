import 'dart:convert';
import 'dart:io';

import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

const _casesPath = 'test/fixtures/conformance/runtime_mvp_cases.json';
const _schemaPath = 'test/fixtures/conformance/runtime_mvp.schema.json';
const _reportPath = 'test/fixtures/conformance/flutter_runtime_report.json';

void main() {
  final fixture = _json(_casesPath);
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  test('runtime fixture envelope and case identities are valid', () {
    final schema = _json(_schemaPath);
    expect(schema[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
    expect(fixture[r'$schema'], 'runtime_mvp.schema.json');
    expect(fixture['specVersion'], '1.0.0');
    expect(fixture['fixtureVersion'], matches(r'^1\.[0-9]+\.[0-9]+$'));
    expect(cases.map((value) => value['id']).toSet().length, cases.length);
    for (final value in cases) {
      expect(value.keys.toSet(), {'id', 'behavior', 'input', 'expected'});
      expect(['offline', 'partialFailure', 'flush', 'queue', 'lifecycle'],
          contains(value['behavior']));
    }
  });

  for (final value in cases) {
    test('runtime conformance: ${value['id']}', () async {
      expect(await _run(value), value['expected'],
          reason: value['id'] as String);
    });
  }

  test('runtime report covers every conformance case', () {
    final report = _json(_reportPath);
    expect(report['implementation'], 'flutter');
    expect(report['specVersion'], fixture['specVersion']);
    expect(report['fixtureVersion'], fixture['fixtureVersion']);
    expect(report['total'], cases.length);
    expect(report['passed'], cases.length);
    expect(report['failed'], 0);
    expect(report['caseIds'], cases.map((value) => value['id']).toList());
  });
}

Future<Map<String, dynamic>> _run(Map<String, dynamic> value) async {
  final input = value['input'] as Map<String, dynamic>;
  switch (value['behavior']) {
    case 'offline':
      final setup = await _client(
        targets: (input['targets'] as List).cast<String>(),
        online: false,
      );
      final result = await setup.client.track(_Event('event-1'));
      return {
        'attempted': setup.trackers.expand((value) => value.events).toList(),
        'queued': result.queuedTrackerIds,
        'queueSize': await setup.queue.size(),
      };
    case 'partialFailure':
      final setup = await _client(
        targets: (input['targets'] as List).cast<String>(),
        failing: (input['failing'] as List).cast<String>().toSet(),
      );
      final result = await setup.client.track(_Event('event-1'));
      return {
        'successful': [
          for (final item in result.trackingResults)
            if (item.successful) item.trackerId,
        ],
        'queued': result.queuedTrackerIds,
        'queueSize': await setup.queue.size(),
      };
    case 'flush':
      final pending = (input['pending'] as List).cast<String>();
      final online = input['online'] as bool;
      final onlineState = _OnlineState(online);
      final setup = await _client(
        targets: pending,
        failing: (input['failing'] as List).cast<String>().toSet(),
        onlineState: onlineState,
      );
      await setup.queue.enqueue(QueuedEvent(
        event: _Event('event-1'),
        trackerIds: pending,
      ));
      final result = await setup.client.flushQueue();
      final remaining = await setup.queue.read(limit: 10);
      return {
        'attemptedEvents': result.attemptedEvents,
        'deliveredEvents': result.deliveredEvents,
        'remainingEvents': result.remainingEvents,
        'pending': remaining.isEmpty ? <String>[] : remaining.single.trackerIds,
        if (remaining.isNotEmpty || !online)
          'attempts': remaining.isEmpty ? 0 : remaining.single.attempts,
      };
    case 'queue':
      return _queueCase(input);
    case 'lifecycle':
      final tracker = _Tracker('analytics');
      final client =
          await FlexTrackClient.create([tracker], autoInitialize: false);
      for (var i = 0; i < (input['initializeCalls'] as int); i++) {
        await client.initialize();
      }
      return {'trackerInitializeCalls': tracker.initializeCalls};
    default:
      throw StateError('Unsupported behavior ${value['behavior']}');
  }
}

Future<Map<String, dynamic>> _queueCase(Map<String, dynamic> input) async {
  final queue = InMemoryEventQueue();
  final ids = (input['eventIds'] as List).cast<String>();
  for (final id in ids) {
    await queue
        .enqueue(QueuedEvent(event: _Event(id), trackerIds: const ['a']));
  }
  if (input['operation'] == 'replace') {
    final first = (await queue.read(limit: 10)).first;
    await queue.replace(first.copyWith(attempts: 1));
  }
  final values = await queue.read(limit: input['limit'] as int? ?? 10);
  return {
    'eventIds': values.map((value) => value.id).toList(),
    'queueSize': await queue.size(),
    if (input['operation'] == 'replace')
      'attempts': values.map((value) => value.attempts).toList(),
  };
}

Future<_Setup> _client({
  required List<String> targets,
  Set<String> failing = const {},
  bool online = true,
  _OnlineState? onlineState,
}) async {
  final queue = InMemoryEventQueue();
  final trackers =
      targets.map((id) => _Tracker(id, failing: failing.contains(id))).toList();
  final config = RoutingConfiguration(
    rules: targets.isEmpty
        ? const []
        : [
            RoutingRule(
              targetGroup: TrackerGroup('fixture', targets),
              requireConsent: false,
            ),
          ],
  );
  final state = onlineState ?? _OnlineState(online);
  final client = await FlexTrackClient.create(
    trackers.isEmpty ? [_Tracker('unused')] : trackers,
    routing: config,
    queue: queue,
    onlineProvider: () => state.value,
  );
  return _Setup(client, queue, trackers);
}

Map<String, dynamic> _json(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, dynamic>();

class _Event extends BaseEvent {
  _Event(String id) : super(eventId: id, timestamp: DateTime.utc(2026, 8, 17));
  @override
  String get name => 'purchase';
  @override
  Map<String, Object> get properties => const {'plan': 'pro'};
  @override
  bool get requiresConsent => false;
}

class _Tracker extends TrackerStrategy {
  _Tracker(this.id, {this.failing = false});
  @override
  final String id;
  final bool failing;
  final List<String> events = [];
  int initializeCalls = 0;
  bool _enabled = true;
  @override
  String get name => id;
  @override
  bool get isEnabled => _enabled;
  @override
  Future<void> initialize() async => initializeCalls++;
  @override
  Future<void> track(BaseEvent event) async {
    events.add(id);
    if (failing) throw StateError('failure');
  }

  @override
  void enable() => _enabled = true;
  @override
  void disable() => _enabled = false;
}

class _OnlineState {
  _OnlineState(this.value);
  bool value;
}

class _Setup {
  const _Setup(this.client, this.queue, this.trackers);
  final FlexTrackClient client;
  final InMemoryEventQueue queue;
  final List<_Tracker> trackers;
}
