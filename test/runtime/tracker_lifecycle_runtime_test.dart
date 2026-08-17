import 'package:flex_track/flex_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'partial initialization failure rolls back and retry attempts all trackers',
      () async {
    final healthy = _LifecycleTracker('healthy');
    final flaky = _LifecycleTracker('flaky', initializeFailures: 1);
    final client = await FlexTrackClient.create(
      [healthy, flaky],
      autoInitialize: false,
    );

    await expectLater(
        client.initialize(), throwsA(isA<ConfigurationException>()));
    expect(client.isInitialized, isFalse);
    expect(healthy.initializeCalls, 1);
    expect(healthy.disposeCalls, 1);

    await client.initialize();
    expect(client.isInitialized, isTrue);
    expect(healthy.initializeCalls, 2);
    expect(flaky.initializeCalls, 2);
  });

  test('client disposal releases initialized trackers exactly once', () async {
    final tracker = _LifecycleTracker('tracker');
    final client = await FlexTrackClient.create([tracker]);

    await client.dispose();
    await client.dispose();

    expect(tracker.disposeCalls, 1);
    expect(client.isInitialized, isFalse);
  });
}

class _LifecycleTracker extends TrackerStrategy
    implements DisposableTrackerStrategy {
  _LifecycleTracker(this.id, {this.initializeFailures = 0});
  @override
  final String id;
  int initializeFailures;
  int initializeCalls = 0;
  int disposeCalls = 0;
  bool _enabled = true;
  @override
  String get name => id;
  @override
  bool get isEnabled => _enabled;
  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (initializeFailures > 0) {
      initializeFailures--;
      throw StateError('initialize failed');
    }
  }

  @override
  Future<void> track(BaseEvent event) async {}
  @override
  Future<void> dispose() async => disposeCalls++;
  @override
  void enable() => _enabled = true;
  @override
  void disable() => _enabled = false;
}
