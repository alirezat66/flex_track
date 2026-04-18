import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/mock_events.dart';

void main() {
  group('FlexTrack static transformer facade', () {
    late MockTracker mock;

    setUp(() async {
      mock = MockTracker(id: 'tracker', name: 'Tracker');
      await FlexTrack.setup(
        [mock],
        routing: RoutingConfiguration(
          rules: [RoutingRule(isDefault: true, targetGroup: TrackerGroup.all)],
        ),
      );
    });

    tearDown(() async {
      await FlexTrack.reset();
    });

    test('addTransformer enriches events via FlexTrack.track()', () async {
      FlexTrack.addTransformer((e) => EnrichedEvent(e, {'route': '/test'}));
      await FlexTrack.track(CustomEvent.named('tap'));

      expect(mock.capturedEvents.single.getProperties()!['route'], '/test');
    });

    test('removeTransformer stops enrichment', () async {
      BaseEvent transformer(BaseEvent e) =>
          EnrichedEvent(e, {'route': '/test'});

      FlexTrack.addTransformer(transformer);
      FlexTrack.removeTransformer(transformer);

      await FlexTrack.track(CustomEvent.named('tap'));

      expect(
        mock.capturedEvents.single.getProperties()?.containsKey('route'),
        isNot(true),
      );
    });

    test('clearTransformers removes all transformers', () async {
      FlexTrack.addTransformer((e) => EnrichedEvent(e, {'a': '1'}));
      FlexTrack.addTransformer((e) => EnrichedEvent(e, {'b': '2'}));
      FlexTrack.clearTransformers();

      await FlexTrack.track(CustomEvent.named('tap'));

      final props = mock.capturedEvents.single.getProperties();
      expect(props?.containsKey('a'), isNot(true));
      expect(props?.containsKey('b'), isNot(true));
    });
  });
}
