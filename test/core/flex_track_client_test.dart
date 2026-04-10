import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlexTrackClient', () {
    test('create + track without FlexTrack.setup', () async {
      final mock = MockTracker();
      final client = await FlexTrackClient.create([mock]);
      await client.track(_TestEvent());

      expect(mock.capturedEvents, hasLength(1));
      expect(mock.capturedEvents.single.getName(), 'test_event');
      await client.dispose();
    });

    test('multiple clients are isolated from FlexTrack singleton', () async {
      final mockA = MockTracker(id: 'a', name: 'A');
      final mockB = MockTracker(id: 'b', name: 'B');

      final clientA = await FlexTrackClient.createWithRouting(
        [mockA],
        (b) {
          b.setConsentChecking(false).setSampling(false).routeDefault().toAll();
          return b;
        },
      );
      final clientB = await FlexTrackClient.createWithRouting(
        [mockB],
        (b) {
          b.setConsentChecking(false).setSampling(false).routeDefault().toAll();
          return b;
        },
      );

      await clientA.track(_TestEvent());
      await clientB.track(_TestEvent());

      expect(mockA.capturedEvents, hasLength(1));
      expect(mockB.capturedEvents, hasLength(1));

      await clientA.dispose();
      await clientB.dispose();
    });

    test('FlexTrack.setup uses same client surface via facade', () async {
      final mock = MockTracker();
      await FlexTrack.setup([mock]);
      expect(FlexTrack.instance.client.trackerRegistry.get(mock.id), mock);
      await FlexTrack.track(_TestEvent());
      expect(mock.capturedEvents, hasLength(1));
      await FlexTrack.reset();
    });
  });
}

class _TestEvent extends BaseEvent {
  @override
  String getName() => 'test_event';

  @override
  Map<String, Object>? getProperties() => const {};
}
