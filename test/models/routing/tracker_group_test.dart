import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackerGroup', () {
    test('predefined all group includes the star sentinel and matches any id',
        () {
      expect(TrackerGroup.all.includesAll, isTrue);
      expect(TrackerGroup.all.containsTracker('firebase'), isTrue);
      expect(TrackerGroup.all.containsTracker('*'), isTrue);
    });

    test('predefined development group lists console by default', () {
      expect(TrackerGroup.development.includesAll, isFalse);
      expect(TrackerGroup.development.containsTracker('console'), isTrue);
      expect(TrackerGroup.development.containsTracker('firebase'), isFalse);
    });

    test('containsTracker returns false when id is not in a custom group', () {
      const g = TrackerGroup('analytics', ['a', 'b']);
      expect(g.containsTracker('a'), isTrue);
      expect(g.containsTracker('c'), isFalse);
    });

    test('combineWith unions tracker ids and names both groups', () {
      const g1 = TrackerGroup('g1', ['x']);
      const g2 = TrackerGroup('g2', ['y', 'x']);
      final combined = g1.combineWith(g2);
      expect(combined.trackerIds.toSet(), {'x', 'y'});
      expect(combined.trackerIds.length, 2);
      expect(combined.name, 'g1_g2');
      expect(combined.description, contains('g1'));
      expect(combined.description, contains('g2'));
    });

    test('excluding removes ids and updates description', () {
      const g = TrackerGroup('orig', ['a', 'b', 'c'], description: 'orig desc');
      final filtered = g.excluding(['b']);
      expect(filtered.trackerIds, ['a', 'c']);
      expect(filtered.name, 'orig_filtered');
      expect(filtered.description, contains('excluding'));
      expect(filtered.description, contains('b'));
    });

    test('toMap includes name, ids, description, and includesAll', () {
      final m = TrackerGroup.all.toMap();
      expect(m['name'], 'all');
      expect(m['trackerIds'], ['*']);
      expect(m['includesAll'], isTrue);
    });

    test('toString is readable for debugging', () {
      expect(TrackerGroup.all.toString(), contains('all'));
      expect(TrackerGroup.all.toString(), contains('*'));
    });

    test('equality uses name and tracker id list order', () {
      const a = TrackerGroup('same', ['1', '2']);
      const b = TrackerGroup('same', ['1', '2']);
      const c = TrackerGroup('same', ['2', '1']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
