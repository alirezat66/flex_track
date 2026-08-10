import 'package:flex_track/flex_track.dart';
import 'package:flex_track/src/core/event_processor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/mock_events.dart';

void main() {
  group('EventProcessor Transformers', () {
    late TrackerRegistry trackerRegistry;
    late RoutingEngine routingEngine;
    late EventProcessor eventProcessor;
    late MockTracker mockTracker;

    setUp(() async {
      mockTracker = MockTracker(id: 'test_tracker', name: 'Test Tracker');
      trackerRegistry = TrackerRegistry();
      trackerRegistry.register(mockTracker);
      await trackerRegistry.initialize();

      final routingConfig = RoutingConfiguration(
        rules: [
          RoutingRule(isDefault: true, targetGroup: TrackerGroup.all),
        ],
      );
      routingEngine = RoutingEngine(routingConfig);
      eventProcessor = EventProcessor(
        trackerRegistry: trackerRegistry,
        routingEngine: routingEngine,
      );
    });

    test('single transformer enriches event reaching the tracker', () async {
      eventProcessor.addTransformer(
        (e) => EnrichedEvent(e, {'route': '/home'}),
      );

      final event = CustomEvent.named('tap');
      await eventProcessor.processEvent(event);

      final captured = mockTracker.capturedEvents.single;
      expect(captured.getProperties()!['route'], '/home');
    });

    test('multiple transformers are applied in registration order', () async {
      final order = <int>[];
      eventProcessor.addTransformer((e) {
        order.add(1);
        return EnrichedEvent(e, {'step1': 'a'});
      });
      eventProcessor.addTransformer((e) {
        order.add(2);
        return EnrichedEvent(e, {'step2': 'b'});
      });

      await eventProcessor.processEvent(CustomEvent.named('test'));

      expect(order, [1, 2]);
      final captured = mockTracker.capturedEvents.single;
      expect(captured.getProperties()!['step1'], 'a');
      expect(captured.getProperties()!['step2'], 'b');
    });

    test('throwing transformer is skipped and pipeline completes', () async {
      eventProcessor.addTransformer((_) => throw Exception('bad transformer'));
      eventProcessor.addTransformer(
        (e) => EnrichedEvent(e, {'after_throw': 'yes'}),
      );

      final result = await eventProcessor.processEvent(CustomEvent.named('x'));

      expect(result.successful, isTrue);
      final captured = mockTracker.capturedEvents.single;
      expect(captured.getProperties()!['after_throw'], 'yes');
    });

    test('EventProcessingResult.event is the enriched event', () async {
      eventProcessor.addTransformer(
        (e) => EnrichedEvent(e, {'enriched': true}),
      );

      final result =
          await eventProcessor.processEvent(CustomEvent.named('test'));

      expect(result.event, isA<EnrichedEvent>());
      expect(result.event.getProperties()!['enriched'], true);
    });

    test('disabled processor returns early without applying transformers',
        () async {
      var transformerCalled = false;
      eventProcessor.addTransformer((e) {
        transformerCalled = true;
        return e;
      });

      eventProcessor.disable();
      await eventProcessor.processEvent(CustomEvent.named('test'));

      expect(transformerCalled, isFalse);
    });

    test('getDebugInfo includes transformerCount', () {
      expect(eventProcessor.getDebugInfo()['transformerCount'], 0);
      eventProcessor.addTransformer((e) => e);
      expect(eventProcessor.getDebugInfo()['transformerCount'], 1);
    });

    test('clearTransformers removes all transformers', () async {
      eventProcessor.addTransformer(
        (e) => EnrichedEvent(e, {'route': '/home'}),
      );
      eventProcessor.clearTransformers();

      await eventProcessor.processEvent(CustomEvent.named('test'));

      final captured = mockTracker.capturedEvents.single;
      expect(captured.getProperties()?.containsKey('route'), isNot(true));
    });

    test('removeTransformer removes only the specified transformer', () async {
      EventTransformer t1 = (e) => EnrichedEvent(e, {'t1': 'yes'});
      EventTransformer t2 = (e) => EnrichedEvent(e, {'t2': 'yes'});

      eventProcessor.addTransformer(t1);
      eventProcessor.addTransformer(t2);
      eventProcessor.removeTransformer(t1);

      await eventProcessor.processEvent(CustomEvent.named('test'));

      final props = mockTracker.capturedEvents.single.getProperties()!;
      expect(props.containsKey('t1'), isFalse);
      expect(props['t2'], 'yes');
    });

    test('transformers getter returns unmodifiable list', () {
      eventProcessor.addTransformer((e) => e);
      final list = eventProcessor.transformers;
      expect(() => list.add((e) => e), throwsUnsupportedError);
    });
  });
}
