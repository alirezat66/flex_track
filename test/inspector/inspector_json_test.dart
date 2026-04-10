import 'package:flex_track/src/inspector/inspector_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jsonSafeForInspector', () {
    test('preserves primitives', () {
      expect(jsonSafeForInspector('a'), 'a');
      expect(jsonSafeForInspector(1), 1);
      expect(jsonSafeForInspector(1.5), 1.5);
      expect(jsonSafeForInspector(true), true);
      expect(jsonSafeForInspector(null), null);
    });

    test('converts nested maps and lists', () {
      final out = jsonSafeForInspector(<String, Object?>{
        'x': 1,
        'y': <String, Object>{'z': true},
        'l': <Object>[1, 'a'],
      });
      expect(out, isA<Map>());
      final m = out! as Map<String, Object?>;
      expect(m['x'], 1);
      expect(m['y'], {'z': true});
      expect(m['l'], [1, 'a']);
    });

    test('falls back to toString for unknown types', () {
      expect(jsonSafeForInspector(Uri.parse('https://a')), 'https://a');
    });
  });

  group('jsonSafeProperties', () {
    test('returns null for null properties', () {
      expect(jsonSafeProperties(null), isNull);
    });

    test('maps object values safely', () {
      final m = jsonSafeProperties({'k': 1, 'u': Uri.parse('x')});
      expect(m, {'k': 1, 'u': 'x'});
    });
  });
}
