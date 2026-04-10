import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackerStrategy interface defaults', () {
    test(
      'default capability getters match the documented baseline',
      () {
        final tracker = _BareTracker();
        expect(tracker.isGDPRCompliant, isFalse);
        expect(tracker.supportsRealTime, isTrue);
        expect(tracker.maxBatchSize, 100);
      },
    );

    test(
      'default trackBatch forwards each event to track in order',
      () async {
        final tracker = _BareTracker();
        final events = [
          _NamedEvent('a'),
          _NamedEvent('b'),
          _NamedEvent('c'),
        ];

        await tracker.trackBatch(events);

        expect(tracker.trackedNames, ['a', 'b', 'c']);
      },
    );

    test(
      'default flush, setUserProperties, identifyUser, and reset complete without error',
      () async {
        final tracker = _BareTracker();

        await expectLater(tracker.flush(), completes);
        await expectLater(
          tracker.setUserProperties({'k': 1}),
          completes,
        );
        await expectLater(
          tracker.identifyUser('u1', {'tier': 'pro'}),
          completes,
        );
        await expectLater(tracker.reset(), completes);
      },
    );

    test(
      'getDebugInfo includes id, name, enabled flag, and default capability fields',
      () {
        final tracker = _BareTracker();
        tracker.disable();

        final info = tracker.getDebugInfo();
        expect(info['id'], 'bare');
        expect(info['name'], 'Bare TrackerStrategy test double');
        expect(info['enabled'], isFalse);
        expect(info['gdprCompliant'], isFalse);
        expect(info['supportsRealTime'], isTrue);
        expect(info['maxBatchSize'], 100);

        tracker.enable();
        expect(tracker.getDebugInfo()['enabled'], isTrue);
      },
    );
  });
}

/// Minimal [TrackerStrategy]: only abstract members; all other behavior comes
/// from the interface defaults in `tracker_strategy.dart`.
class _BareTracker extends TrackerStrategy {
  _BareTracker();

  final List<String> trackedNames = [];
  bool _enabled = true;

  @override
  String get id => 'bare';

  @override
  String get name => 'Bare TrackerStrategy test double';

  @override
  bool get isEnabled => _enabled;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> track(BaseEvent event) async {
    trackedNames.add(event.getName());
  }

  @override
  void enable() {
    _enabled = true;
  }

  @override
  void disable() {
    _enabled = false;
  }
}

class _NamedEvent extends BaseEvent {
  _NamedEvent(this._name);

  final String _name;

  @override
  String getName() => _name;

  @override
  Map<String, Object>? getProperties() => const {};
}
