import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsoleTracker', () {
    late ConsoleTracker tracker;

    setUp(() {
      tracker = ConsoleTracker(
        showProperties: true,
        showTimestamps: false,
        colorOutput: false,
        prefix: 'TEST',
      );
    });

    test('initializes and records events in eventHistory', () async {
      await tracker.initialize();
      await tracker.track(_ConsoleTestEvent('hello'));
      expect(tracker.eventHistory, hasLength(1));
      expect(tracker.eventHistory.single.getName(), 'hello');
    });

    test('track includes category, user, and session in log output path',
        () async {
      await tracker.initialize();
      await tracker.track(_RichEvent());
      expect(tracker.eventHistory, hasLength(1));
      final info = tracker.getDebugInfo();
      expect(info['eventHistoryCount'], 1);
      expect(info['showTimestamps'], isFalse);
      expect(info['prefix'], 'TEST');
    });

    test('logs non-empty properties when showProperties is true', () async {
      await tracker.initialize();
      await tracker.track(_ConsoleTestEvent('x', props: {'k': 1}));
      expect(tracker.eventHistory.single.getProperties(), isNotEmpty);
    });

    test('skips property lines when showProperties is false', () async {
      final t = ConsoleTracker(
        showProperties: false,
        showTimestamps: false,
        colorOutput: false,
        prefix: 'TEST',
      );
      await t.initialize();
      await t.track(_ConsoleTestEvent('p', props: {'a': 1}));
      expect(t.eventHistory, hasLength(1));
    });

    test('logs event flags when any are set on the event', () async {
      await tracker.initialize();
      await tracker.track(_FlaggedEvent());
      expect(tracker.eventHistory, hasLength(1));
    });

    test('doTrackBatch appends every event to history', () async {
      await tracker.initialize();
      await tracker.trackBatch([
        _ConsoleTestEvent('one'),
        _ConsoleTestEvent('two'),
      ]);
      expect(tracker.eventHistory, hasLength(2));
      expect(
        tracker.eventHistory.map((e) => e.getName()).toList(),
        ['one', 'two'],
      );
    });

    test('setUserProperties and identifyUser complete after init', () async {
      await tracker.initialize();
      await tracker.setUserProperties({'plan': 'pro'});
      await tracker.identifyUser('user-1', {'locale': 'en'});
      await expectLater(tracker.flush(), completes);
      await tracker.reset();
    });

    test('clearHistory removes recorded events', () async {
      await tracker.initialize();
      await tracker.track(_ConsoleTestEvent('a'));
      tracker.clearHistory();
      expect(tracker.eventHistory, isEmpty);
      expect(tracker.getDebugInfo()['eventHistoryCount'], 0);
    });

    test('getDebugInfo merges base tracker fields with console options',
        () async {
      await tracker.initialize();
      final info = tracker.getDebugInfo();
      expect(info['id'], ConsoleTracker().id);
      expect(info['colorOutput'], isFalse);
      expect(info['showProperties'], isTrue);
    });

    test('colorOutput true exercises ansi print branches', () async {
      final t = ConsoleTracker(
        showTimestamps: false,
        colorOutput: true,
        prefix: 'ANSI',
      );
      await t.initialize();
      await t.track(_ConsoleTestEvent('colored'));
      expect(t.eventHistory, hasLength(1));
    });

    test('formats large property maps with multiline style when not compact',
        () async {
      final t = ConsoleTracker(showProperties: true, colorOutput: false);
      await t.initialize();
      await t.track(_ConsoleTestEvent(
        'many_props',
        props: {'a': 1, 'b': 2, 'c': 3, 'd': 4},
      ));
      expect(t.eventHistory.single.getProperties()!.length, 4);
    });
  });
}

class _ConsoleTestEvent extends BaseEvent {
  _ConsoleTestEvent(this._name, {this.props});

  final String _name;
  final Map<String, Object>? props;

  @override
  String getName() => _name;

  @override
  Map<String, Object>? getProperties() => props;
}

class _RichEvent extends BaseEvent {
  @override
  String getName() => 'rich';

  @override
  EventCategory? get category => EventCategory.user;

  @override
  String? get userId => 'u1';

  @override
  String? get sessionId => 's1';

  @override
  Map<String, Object>? getProperties() => const {'x': 1};
}

class _FlaggedEvent extends BaseEvent {
  @override
  String getName() => 'flagged';

  @override
  bool get containsPII => true;

  @override
  bool get isHighVolume => true;

  @override
  bool get isEssential => true;

  @override
  bool get requiresConsent => false;

  @override
  Map<String, Object>? getProperties() => const {};
}
