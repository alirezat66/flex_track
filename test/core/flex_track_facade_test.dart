import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlexTrack global facade', () {
    tearDown(() async {
      await FlexTrack.reset();
    });

    test(
      'printDebugInfo does not throw before setup and only logs that setup is missing',
      () {
        expect(FlexTrack.printDebugInfo, returnsNormally);
      },
    );

    test(
      'getDebugInfo before setup reports a clear error entry',
      () {
        final info = FlexTrack.getDebugInfo();
        expect(info['error'], 'FlexTrack is not set up');
      },
    );

    test(
      'validate before setup returns a single actionable message',
      () {
        expect(FlexTrack.validate(), ['FlexTrack is not set up']);
      },
    );

    test(
      'after reset(), setup can run again with a fresh configuration',
      () async {
        final first = MockTracker(id: 'm1', name: 'First');
        await FlexTrack.setup([first]);
        await FlexTrack.track(_FacadeTestEvent('e1'));
        expect(first.capturedEvents, hasLength(1));

        await FlexTrack.reset();
        expect(FlexTrack.isSetUp, isFalse);

        final second = MockTracker(id: 'm2', name: 'Second');
        await FlexTrack.setup([second]);
        await FlexTrack.track(_FacadeTestEvent('e2'));

        expect(second.capturedEvents, hasLength(1));
        expect(second.capturedEvents.single.getName(), 'e2');
      },
    );

    test(
      'static track and instance.client.track hit the same underlying client',
      () async {
        final mock = MockTracker();
        await FlexTrack.setup([mock]);

        await FlexTrack.track(_FacadeTestEvent('via_static'));
        await FlexTrack.instance.client.track(_FacadeTestEvent('via_client'));

        expect(
          mock.capturedEvents.map((e) => e.getName()).toList(),
          ['via_static', 'via_client'],
        );
      },
    );
  });
}

class _FacadeTestEvent extends BaseEvent {
  _FacadeTestEvent(this._name);

  final String _name;

  @override
  String getName() => _name;

  @override
  Map<String, Object>? getProperties() => const {};
}
