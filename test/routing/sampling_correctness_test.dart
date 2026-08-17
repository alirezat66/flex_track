import 'dart:convert';
import 'dart:io';

import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

class SamplingEvent extends BaseEvent {
  SamplingEvent({this.eventUserId, this.eventSessionId});

  final String? eventUserId;
  final String? eventSessionId;

  @override
  String get name => 'purchase';

  @override
  Map<String, Object>? get properties => null;

  @override
  String? get userId => eventUserId;

  @override
  String? get sessionId => eventSessionId;
}

class RecordingSampler implements EventSampler {
  BaseEvent? event;
  double? rate;

  @override
  bool shouldSample(BaseEvent event, double sampleRate) {
    this.event = event;
    rate = sampleRate;
    return false;
  }
}

void main() {
  group('cross-platform deterministic sampling', () {
    final fixture = jsonDecode(
      File('test/fixtures/sampling_vectors.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final vectors = fixture['vectors'] as List<dynamic>;

    test('uses the documented FNV-1a UTF-8 vectors', () {
      for (final value in vectors.cast<Map<String, dynamic>>()) {
        final input = value['input'] as String;

        expect(
          SamplingUtils.stableHash(input),
          value['hash'],
          reason: 'hash mismatch for ${jsonEncode(input)}',
        );
        expect(
          SamplingUtils.shouldSampleDeterministic(input, 0.25),
          value['at25'],
          reason: '25% decision mismatch for ${jsonEncode(input)}',
        );
        expect(
          SamplingUtils.shouldSampleDeterministic(input, 0.50),
          value['at50'],
          reason: '50% decision mismatch for ${jsonEncode(input)}',
        );
      }
    });

    test('uses user, session, then event name as the stable key', () {
      expect(SamplingUtils.samplingKey(SamplingEvent(eventUserId: 'user-1')),
          'user-1');
      expect(
        SamplingUtils.samplingKey(
          SamplingEvent(eventUserId: '', eventSessionId: 'session-1'),
        ),
        'session-1',
      );
      expect(SamplingUtils.samplingKey(SamplingEvent()), 'purchase');
    });

    test('makes repeated routing decisions independent of wall-clock time', () {
      final rule = RoutingRule(
        targetGroup: TrackerGroup.all,
        sampleRate: 0.5,
      );
      final event = SamplingEvent(eventUserId: 'stable-user');

      final decisions = List.generate(1000, (_) => rule.shouldSample(event));

      expect(decisions.toSet(), hasLength(1));
    });

    test('always keeps essential events and boundary rate one', () {
      final essential = _EssentialSamplingEvent();

      expect(
        const RoutingRule(
          targetGroup: TrackerGroup.all,
          sampleRate: 0,
        ).shouldSample(essential),
        isTrue,
      );
      expect(
        const RoutingRule(
          targetGroup: TrackerGroup.all,
          sampleRate: 1,
        ).shouldSample(SamplingEvent()),
        isTrue,
      );
    });

    test('allows the sampler to be injected through routing configuration', () {
      final sampler = RecordingSampler();
      final event = SamplingEvent(eventUserId: 'user-1');
      final configuration = RoutingConfiguration(
        rules: const [
          RoutingRule(targetGroup: TrackerGroup.all, sampleRate: 0.5),
        ],
        sampler: sampler,
      );

      final result = RoutingEngine(configuration).routeEvent(
        event,
        availableTrackers: {'console'},
      );

      expect(result.targetTrackers, isEmpty);
      expect(sampler.event, same(event));
      expect(sampler.rate, 0.5);
    });
  });
}

class _EssentialSamplingEvent extends SamplingEvent {
  @override
  bool get isEssential => true;
}
