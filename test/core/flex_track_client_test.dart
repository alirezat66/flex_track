import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlexTrackClient', () {
    group('creation', () {
      test(
        'throws ConfigurationException when the tracker list is empty',
        () async {
          expect(
            () => FlexTrackClient.create([]),
            throwsA(
              isA<ConfigurationException>().having(
                (e) => e.fieldName,
                'fieldName',
                'trackers',
              ),
            ),
          );
        },
      );

      test(
        'does not initialize trackers until initialize() when autoInitialize is false',
        () async {
          final mock = MockTracker();
          final client = await FlexTrackClient.create(
            [mock],
            autoInitialize: false,
          );

          expect(client.isInitialized, isFalse);

          final beforeInit = await client.track(_TestEvent());
          expect(beforeInit.successful, isFalse);
          expect(beforeInit.wasTracked, isFalse);
          expect(mock.capturedEvents, isEmpty);

          await client.initialize();
          expect(client.isInitialized, isTrue);

          await client.track(_TestEvent());
          expect(mock.capturedEvents, hasLength(1));

          await client.dispose();
        },
      );

      test(
        'initialize() is safe to call more than once (idempotent)',
        () async {
          final mock = MockTracker();
          final client = await FlexTrackClient.create([mock]);
          await client.initialize();
          await client.initialize();
          await client.track(_TestEvent());
          expect(mock.capturedEvents, hasLength(1));
          await client.dispose();
        },
      );

      test(
        'wraps tracker initialization failures in ConfigurationException',
        () async {
          expect(
            () => FlexTrackClient.create([_BrokenInitTracker()]),
            throwsA(
              isA<ConfigurationException>().having(
                (e) => e.code,
                'code',
                'INITIALIZATION_FAILED',
              ),
            ),
          );
        },
      );
    });

    group('isolation and global FlexTrack', () {
      test(
        'two clients keep separate tracker state and routing',
        () async {
          final mockA = MockTracker(id: 'a', name: 'A');
          final mockB = MockTracker(id: 'b', name: 'B');

          final clientA = await _clientWithRelaxedRouting([mockA]);
          final clientB = await _clientWithRelaxedRouting([mockB]);

          await clientA.track(_TestEvent());
          await clientB.track(_TestEvent());

          expect(mockA.capturedEvents, hasLength(1));
          expect(mockB.capturedEvents, hasLength(1));

          await clientA.dispose();
          await clientB.dispose();
        },
      );

      test(
        'FlexTrack.setup exposes the same client through instance.client',
        () async {
          final mock = MockTracker();
          await FlexTrack.setup([mock]);
          expect(FlexTrack.instance.client.trackerRegistry.get(mock.id), mock);
          await FlexTrack.track(_TestEvent());
          expect(mock.capturedEvents, hasLength(1));
          await FlexTrack.reset();
        },
      );
    });

    group('consent and processor control', () {
      test(
        'events that require consent are not delivered when general consent is denied',
        () async {
          final mock = MockTracker();
          final client = await FlexTrackClient.createWithRouting(
            [mock],
            (b) {
              b.routeDefault().toAll().requireConsent();
              return b;
            },
          );

          client.setGeneralConsent(false);
          final result = await client.track(_TestEvent());
          expect(result.successful, isFalse);
          expect(mock.capturedEvents, isEmpty);

          client.setGeneralConsent(true);
          await client.track(_TestEvent());
          expect(mock.capturedEvents, hasLength(1));

          await client.dispose();
        },
      );

      test(
        'setConsent updates getConsentStatus for general and PII flags',
        () async {
          final client = await _clientWithRelaxedRouting([MockTracker()]);

          client.setConsent(general: false, pii: false);
          expect(client.getConsentStatus(), {
            'general': false,
            'pii': false,
          });

          client.setConsent(general: true, pii: true);
          expect(client.getConsentStatus(), {
            'general': true,
            'pii': true,
          });

          await client.dispose();
        },
      );

      test(
        'when the event processor is disabled, track completes without sending to trackers',
        () async {
          final mock = MockTracker();
          final client = await _clientWithRelaxedRouting([mock]);

          client.disable();
          expect(client.isEnabled, isFalse);

          final result = await client.track(_TestEvent());
          expect(result.successful, isFalse);
          expect(
            result.routingResult.warnings,
            contains('Event processor is disabled'),
          );
          expect(mock.capturedEvents, isEmpty);

          client.enable();
          await client.track(_TestEvent());
          expect(mock.capturedEvents, hasLength(1));

          await client.dispose();
        },
      );
    });

    group('per-tracker enablement', () {
      test(
        'a disabled tracker does not receive events while others still do',
        () async {
          final primary = MockTracker(id: 'primary', name: 'Primary');
          final secondary = MockTracker(id: 'secondary', name: 'Secondary');
          final client = await _clientWithRelaxedRouting([primary, secondary]);

          client.disableTracker('secondary');
          await client.track(_TestEvent());

          expect(primary.capturedEvents, hasLength(1));
          expect(secondary.capturedEvents, isEmpty);

          client.enableTracker('secondary');
          await client.track(_TestEvent());
          expect(secondary.capturedEvents, hasLength(1));

          await client.dispose();
        },
      );

      test(
        'disableAllTrackers stops delivery; enableAllTrackers restores it',
        () async {
          final mock = MockTracker();
          final client = await _clientWithRelaxedRouting([mock]);

          client.disableAllTrackers();
          await client.track(_TestEvent());
          expect(mock.capturedEvents, isEmpty);

          client.enableAllTrackers();
          await client.track(_TestEvent());
          expect(mock.capturedEvents, hasLength(1));

          expect(client.isTrackerEnabled(mock.id), isTrue);
          expect(client.getTrackerIds(), contains(mock.id));

          await client.dispose();
        },
      );
    });

    group('batch tracking', () {
      test(
        'trackAll processes events in order and delivers each to the tracker',
        () async {
          final mock = MockTracker();
          final client = await _clientWithRelaxedRouting([mock]);

          await client.trackAll([
            _NamedTestEvent('first'),
            _NamedTestEvent('second'),
            _NamedTestEvent('third'),
          ]);

          expect(
            mock.capturedEvents.map((e) => e.getName()).toList(),
            ['first', 'second', 'third'],
          );

          await client.dispose();
        },
      );

      test(
        'trackParallel delivers all events (each processed independently)',
        () async {
          final mock = MockTracker();
          final client = await _clientWithRelaxedRouting([mock]);

          await client.trackParallel([
            _NamedTestEvent('a'),
            _NamedTestEvent('b'),
          ]);

          expect(mock.capturedEvents, hasLength(2));
          expect(
            mock.capturedEvents.map((e) => e.getName()).toSet(),
            {'a', 'b'},
          );

          await client.dispose();
        },
      );
    });

    group('user and tracker lifecycle', () {
      test(
        'identifyUser and setUserProperties reach the underlying tracker',
        () async {
          final mock = MockTracker();
          final client = await _clientWithRelaxedRouting([mock]);

          await client.identifyUser('user-42', {'plan': 'pro'});
          await client.setUserProperties({'locale': 'en'});

          expect(mock.capturedUserIds, ['user-42']);
          expect(mock.capturedUserProperties.length, greaterThanOrEqualTo(1));
          expect(
            mock.capturedUserProperties.any((m) => m['plan'] == 'pro'),
            isTrue,
          );
          expect(
            mock.capturedUserProperties.any((m) => m['locale'] == 'en'),
            isTrue,
          );

          await client.dispose();
        },
      );

      test(
        'resetTrackers clears mock captured state as seen by the tracker',
        () async {
          final mock = MockTracker();
          final client = await _clientWithRelaxedRouting([mock]);

          await client.track(_TestEvent());
          expect(mock.capturedEvents, isNotEmpty);

          await client.resetTrackers();
          expect(mock.capturedEvents, isEmpty);

          await client.dispose();
        },
      );
    });

    group('debug and validation', () {
      test(
        'getDebugInfo reflects initialization, enabled flag, and nested processor info',
        () async {
          final mock = MockTracker();
          final client = await _clientWithRelaxedRouting([mock]);

          final info = client.getDebugInfo();
          expect(info['isInitialized'], isTrue);
          expect(info['isEnabled'], isTrue);
          expect(info['eventProcessor'], isA<Map<String, dynamic>>());

          await client.dispose();
        },
      );

      test(
        'debugEvent returns debug data for the same event instance',
        () async {
          final client = await _clientWithRelaxedRouting([MockTracker()]);
          final event = _TestEvent();
          final debug = client.debugEvent(event);

          expect(debug.event, same(event));
          expect(debug.routingResult.event, same(event));

          await client.dispose();
        },
      );

      test(
        'validate returns no issues for a minimal valid client',
        () async {
          final client = await _clientWithRelaxedRouting([MockTracker()]);
          expect(client.validate(), isEmpty);
          await client.dispose();
        },
      );

      test(
        'printDebugInfo runs without throwing for a healthy client',
        () async {
          final client = await _clientWithRelaxedRouting([MockTracker()]);
          expect(client.printDebugInfo, returnsNormally);
          await client.dispose();
        },
      );
    });
  });
}

/// Routing that sends everything to all trackers, with consent checks and sampling off (predictable tests).
Future<FlexTrackClient> _clientWithRelaxedRouting(
  List<TrackerStrategy> trackers,
) {
  return FlexTrackClient.createWithRouting(
    trackers,
    (b) {
      b.setConsentChecking(false).setSampling(false).routeDefault().toAll();
      return b;
    },
  );
}

class _TestEvent extends BaseEvent {
  @override
  String getName() => 'test_event';

  @override
  Map<String, Object>? getProperties() => const {};
}

class _NamedTestEvent extends BaseEvent {
  _NamedTestEvent(this._name);

  final String _name;

  @override
  String getName() => _name;

  @override
  Map<String, Object>? getProperties() => const {};
}

class _BrokenInitTracker extends NoOpTracker {
  _BrokenInitTracker() : super(id: 'broken', name: 'Broken init');

  @override
  Future<void> doInitialize() async {
    throw Exception('deliberate init failure');
  }
}
