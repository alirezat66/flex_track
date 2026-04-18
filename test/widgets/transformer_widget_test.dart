import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/mock_events.dart';

void main() {
  group('Transformer + widget integration', () {
    testWidgets(
        'transformer registered on FlexTrackScope client enriches FlexClickTrack events',
        (tester) async {
      final mock = MockTracker(id: 'tracker', name: 'Tracker');
      final client = await FlexTrackClient.create(
        [mock],
        routing: RoutingConfiguration(
          rules: [RoutingRule(isDefault: true, targetGroup: TrackerGroup.all)],
        ),
      );

      client.addTransformer(
        (e) => EnrichedEvent(e, {'current_route': '/test_route'}),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlexTrackScope(
            client: client,
            child: Scaffold(
              body: FlexClickTrack(
                event: CustomEvent.named('tap_test'),
                child: const Text('Tap me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(mock.capturedEvents, hasLength(1));
      final captured = mock.capturedEvents.single;
      expect(captured.getName(), 'tap_test');
      expect(captured.getProperties()!['current_route'], '/test_route');

      await client.dispose();
    });

    testWidgets(
        'transformer is not applied after clearTransformers on scoped client',
        (tester) async {
      final mock = MockTracker(id: 'tracker', name: 'Tracker');
      final client = await FlexTrackClient.create(
        [mock],
        routing: RoutingConfiguration(
          rules: [RoutingRule(isDefault: true, targetGroup: TrackerGroup.all)],
        ),
      );

      client.addTransformer(
        (e) => EnrichedEvent(e, {'current_route': '/test_route'}),
      );
      client.clearTransformers();

      await tester.pumpWidget(
        MaterialApp(
          home: FlexTrackScope(
            client: client,
            child: Scaffold(
              body: FlexClickTrack(
                event: CustomEvent.named('tap_test'),
                child: const Text('Tap me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(mock.capturedEvents, hasLength(1));
      final props = mock.capturedEvents.single.getProperties();
      expect(props?.containsKey('current_route'), isNot(true));

      await client.dispose();
    });

    testWidgets('enriched event name is preserved through dispatch',
        (tester) async {
      final mock = MockTracker(id: 'tracker', name: 'Tracker');
      final client = await FlexTrackClient.create(
        [mock],
        routing: RoutingConfiguration(
          rules: [RoutingRule(isDefault: true, targetGroup: TrackerGroup.all)],
        ),
      );

      client.addTransformer(
        (e) => EnrichedEvent(e, {'extra': 'data'}),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlexTrackScope(
            client: client,
            child: Scaffold(
              body: FlexClickTrack(
                event: CustomEvent.named('my_event'),
                child: const Text('Click'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Click'));
      await tester.pump();

      expect(mock.capturedEvents.single.getName(), 'my_event');

      await client.dispose();
    });
  });
}
