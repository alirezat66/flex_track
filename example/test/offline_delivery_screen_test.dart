import 'package:flex_track/flex_track.dart';
import 'package:flex_track_example/runtime/offline_delivery_demo.dart';
import 'package:flex_track_example/screens/offline_delivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OfflineDeliveryDemo demo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FlexTrack.reset();
    demo = OfflineDeliveryDemo();
    await demo.initialize();
    await FlexTrack.setupWithRouting(
      [demo.successTracker, demo.retryTracker],
      (builder) => builder
          .routeExact('demo_offline_delivery')
          .to(['demo_delivery_success', 'demo_delivery_retry'])
          .skipConsent()
          .noSampling()
          .withPriority(100)
          .and(),
      onlineProvider: () => demo.onlineProvider,
    );
  });

  tearDown(() => FlexTrack.reset());

  Future<void> pumpLab(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: OfflineDeliveryScreen(demo: demo)),
    ));
    await tester.pumpAndSettle();
  }

  test('restores simulated network state across controller instances',
      () async {
    await demo.setOnline(false);

    final restored = OfflineDeliveryDemo();
    await restored.initialize();

    expect(restored.isOnline, isFalse);
    restored.dispose();
  });

  testWidgets('visualizes offline enqueue and successful flush',
      (tester) async {
    await demo.setOnline(false);
    await pumpLab(tester);

    await tester.tap(find.byKey(const Key('track-delivery-event')));
    await tester.pumpAndSettle();

    expect(find.text('Pending events: 1'), findsOneWidget);
    expect(
      find.text('Queued: demo_delivery_success, demo_delivery_retry'),
      findsOneWidget,
    );
    expect(demo.successTracker.attemptCount, 0);
    expect(demo.retryTracker.attemptCount, 0);

    await demo.setOnline(true);
    await tester.runAsync(demo.flush);
    await tester.pump();

    expect(find.text('Pending events: 0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('flush-result')),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('1 attempted · 1 delivered · 0 remaining'),
        findsOneWidget);
    expect(demo.successTracker.successCount, 1);
    expect(demo.retryTracker.successCount, 1);
  });

  testWidgets('visualizes partial failure and selective retry', (tester) async {
    demo.setRetryTrackerFails(true);
    await pumpLab(tester);

    await tester.tap(find.byKey(const Key('track-delivery-event')));
    await tester.pumpAndSettle();

    expect(find.text('Pending events: 1'), findsOneWidget);
    expect(find.text('Delivered: demo_delivery_success'), findsOneWidget);
    expect(find.text('Failed: demo_delivery_retry'), findsOneWidget);
    expect(find.text('Queued: demo_delivery_retry'), findsOneWidget);
    expect(demo.successTracker.attemptCount, 1);

    demo.setRetryTrackerFails(false);
    await tester.runAsync(demo.flush);
    await tester.pump();

    expect(demo.successTracker.attemptCount, 1,
        reason: 'successful destinations must never be retried');
    expect(demo.retryTracker.attemptCount, 2);
    expect(find.text('Pending events: 0'), findsOneWidget);
  });
}
