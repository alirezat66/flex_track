import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_utils/mock_events.dart';

void main() {
  group('EnrichedEvent', () {
    late CustomEvent original;

    setUp(() {
      original = CustomEvent.named(
        'test_event',
        properties: {'original_key': 'original_value', 'shared_key': 'original'},
        category: EventCategory.user,
        containsPII: true,
        isHighVolume: true,
        isEssential: true,
      );
    });

    test('forwards getName from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.getName(), 'test_event');
    });

    test('returns only extra properties when original has none', () {
      final bare = CustomEvent.named('bare');
      final enriched = EnrichedEvent(bare, {'route': '/home'});
      expect(enriched.getProperties(), {'route': '/home'});
    });

    test('merges original and extra properties', () {
      final enriched = EnrichedEvent(original, {'extra_key': 'extra_value'});
      final props = enriched.getProperties();
      expect(props['original_key'], 'original_value');
      expect(props['extra_key'], 'extra_value');
    });

    test('extra properties take precedence over original on key collision', () {
      final enriched = EnrichedEvent(original, {'shared_key': 'enriched'});
      expect(enriched.getProperties()['shared_key'], 'enriched');
    });

    test('forwards category from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.category, EventCategory.user);
    });

    test('forwards containsPII from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.containsPII, isTrue);
    });

    test('forwards isHighVolume from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.isHighVolume, isTrue);
    });

    test('forwards isEssential from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.isEssential, isTrue);
    });

    test('forwards requiresConsent from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.requiresConsent, original.requiresConsent);
    });

    test('forwards timestamp from original', () {
      // Capture once — BaseEvent.timestamp calls DateTime.now() each time
      final fixedTime = DateTime(2024, 1, 1);
      final fixedEvent = _FixedTimestampEvent(fixedTime);
      final enriched = EnrichedEvent(fixedEvent, {});
      expect(enriched.timestamp, equals(fixedTime));
    });

    test('forwards userId from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.userId, original.userId);
    });

    test('forwards sessionId from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.sessionId, original.sessionId);
    });

    test('forwards preferredGroup from original', () {
      final enriched = EnrichedEvent(original, {});
      expect(enriched.preferredGroup, original.preferredGroup);
    });

    test('original getter returns the wrapped event', () {
      final enriched = EnrichedEvent(original, {'k': 'v'});
      expect(enriched.original, same(original));
    });

    test('extraProperties is unmodifiable', () {
      final enriched = EnrichedEvent(original, {'k': 'v'});
      expect(
        () => enriched.extraProperties['new'] = 'val',
        throwsUnsupportedError,
      );
    });

    test('stacking EnrichedEvents layers properties correctly', () {
      final first = EnrichedEvent(original, {'layer1': 'a'});
      final second = EnrichedEvent(first, {'layer2': 'b', 'shared_key': 'top'});
      final props = second.getProperties();
      expect(props['original_key'], 'original_value');
      expect(props['layer1'], 'a');
      expect(props['layer2'], 'b');
      expect(props['shared_key'], 'top');
    });
  });
}

class _FixedTimestampEvent extends BaseEvent {
  final DateTime _timestamp;
  _FixedTimestampEvent(this._timestamp);

  @override
  String getName() => 'fixed';

  @override
  Map<String, Object>? getProperties() => null;

  @override
  DateTime get timestamp => _timestamp;
}
