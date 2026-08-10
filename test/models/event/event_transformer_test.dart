import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils/mock_events.dart';

void main() {
  group('conditionalTransformer', () {
    test('applies transformer when condition is true', () {
      final event = CustomEvent.named('test');
      final transformer = conditionalTransformer(
        (_) => true,
        (e) => EnrichedEvent(e, {'added': 'yes'}),
      );

      final result = transformer(event);
      expect(result, isA<EnrichedEvent>());
      expect(result.getProperties()!['added'], 'yes');
    });

    test('passes event through unchanged when condition is false', () {
      final event = CustomEvent.named('test');
      final transformer = conditionalTransformer(
        (_) => false,
        (e) => EnrichedEvent(e, {'added': 'yes'}),
      );

      final result = transformer(event);
      expect(result, same(event));
    });

    test('condition receives the current event (not the original)', () {
      final event = CustomEvent.named('test');
      BaseEvent? receivedEvent;

      final transformer = conditionalTransformer(
        (e) {
          receivedEvent = e;
          return true;
        },
        (e) => EnrichedEvent(e, {}),
      );

      transformer(event);
      expect(receivedEvent, same(event));
    });

    test('condition can inspect event category', () {
      final uiEvent = CustomEvent.named('click', category: EventCategory.user);
      final sysEvent = CustomEvent.named('log', category: EventCategory.system);

      final transformer = conditionalTransformer(
        (e) => e.category == EventCategory.user,
        (e) => EnrichedEvent(e, {'enriched': true}),
      );

      final uiResult = transformer(uiEvent);
      final sysResult = transformer(sysEvent);

      expect(uiResult, isA<EnrichedEvent>());
      expect(sysResult, same(sysEvent));
    });
  });
}
