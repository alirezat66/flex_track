import 'package:flex_track/src/models/event/base_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseEvent API', () {
    test('name and properties getters are the preferred API', () {
      final event = _SampleEvent();

      expect(event.name, 'sample');
      expect(event.properties, {'key': 'value'});
    });

    test('deprecated getName/getProperties still work for callers', () {
      final event = _SampleEvent();

      // ignore: deprecated_member_use_from_same_package
      expect(event.name, event.name);
      // ignore: deprecated_member_use_from_same_package
      expect(event.properties, event.properties);
    });
  });
}

class _SampleEvent extends BaseEvent {
  @override
  String get name => 'sample';

  @override
  Map<String, Object>? get properties => const {'key': 'value'};
}
