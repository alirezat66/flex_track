import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/mock_events.dart';

Future<(FlexTrackClient, MockTracker)> _makeClient() async {
  final mock = MockTracker(id: 'tracker', name: 'Tracker');
  final client = await FlexTrackClient.create(
    [mock],
    routing: RoutingConfiguration(
      rules: [RoutingRule(isDefault: true, targetGroup: TrackerGroup.all)],
    ),
  );
  return (client, mock);
}

void main() {
  group('FlexTrackClient transformers', () {
    test('addTransformer enriches events dispatched via track()', () async {
      final (client, mock) = await _makeClient();

      client.addTransformer((e) => EnrichedEvent(e, {'route': '/home'}));
      await client.track(CustomEvent.named('tap'));

      expect(mock.capturedEvents.single.getProperties()!['route'], '/home');
      await client.dispose();
    });

    test('removeTransformer stops that transformer from running', () async {
      final (client, mock) = await _makeClient();

      BaseEvent t1(BaseEvent e) => EnrichedEvent(e, {'t1': 'yes'});
      BaseEvent t2(BaseEvent e) => EnrichedEvent(e, {'t2': 'yes'});

      client.addTransformer(t1);
      client.addTransformer(t2);
      client.removeTransformer(t1);

      await client.track(CustomEvent.named('tap'));

      final props = mock.capturedEvents.single.getProperties()!;
      expect(props.containsKey('t1'), isFalse);
      expect(props['t2'], 'yes');
      await client.dispose();
    });

    test('clearTransformers removes all transformers', () async {
      final (client, mock) = await _makeClient();

      client.addTransformer((e) => EnrichedEvent(e, {'route': '/home'}));
      client.clearTransformers();

      await client.track(CustomEvent.named('tap'));

      expect(mock.capturedEvents.single.getProperties()?.containsKey('route'),
          isNot(true));
      await client.dispose();
    });

    test('two independent clients have isolated transformer lists', () async {
      final (client1, mock1) = await _makeClient();
      final (client2, mock2) = await _makeClient();

      client1.addTransformer((e) => EnrichedEvent(e, {'client': '1'}));

      await client1.track(CustomEvent.named('e1'));
      await client2.track(CustomEvent.named('e2'));

      expect(mock1.capturedEvents.single.getProperties()!['client'], '1');
      expect(mock2.capturedEvents.single.getProperties()?.containsKey('client'),
          isNot(true));

      await client1.dispose();
      await client2.dispose();
    });
  });
}
