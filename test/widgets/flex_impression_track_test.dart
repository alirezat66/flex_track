import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../test_utils/mock_events.dart';

void main() {
  group('FlexImpressionTrack', () {
    tearDown(() async {
      await FlexTrack.reset();
    });

    setUp(() {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
    });

    tearDown(() {
      VisibilityDetectorController.instance.updateInterval =
          const Duration(milliseconds: 500);
    });

    testWidgets('fires when widget is largely visible', (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexImpressionTrack(
              visibilityKey: const Key('imp1'),
              visibleFractionThreshold: 0.1,
              event: CustomEvent.named('banner_impression'),
              child: Container(
                height: 200,
                color: Colors.orange,
                alignment: Alignment.center,
                child: const Text('banner'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      VisibilityDetectorController.instance.notifyNow();
      await tester.pump();

      expect(mock.capturedEvents, isNotEmpty);
      expect(
        mock.capturedEvents.map((e) => e.getName()),
        contains('banner_impression'),
      );
    });

    testWidgets('minVisibleDuration delays track until elapsed',
        (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexImpressionTrack(
              visibilityKey: const Key('imp2'),
              visibleFractionThreshold: 0.01,
              minVisibleDuration: const Duration(milliseconds: 400),
              event: CustomEvent.named('delayed_impression'),
              child: const SizedBox(
                height: 120,
                width: double.infinity,
                child: ColoredBox(color: Colors.green),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      VisibilityDetectorController.instance.notifyNow();
      await tester.pump();
      expect(mock.capturedEvents, isEmpty);

      await tester.pump(const Duration(milliseconds: 100));
      expect(mock.capturedEvents, isEmpty);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'delayed_impression');
    });

    testWidgets('fires only once even if visibility updates multiple times',
        (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexImpressionTrack(
              visibilityKey: const Key('imp_once'),
              visibleFractionThreshold: 0.1,
              fireOnce: true,
              event: CustomEvent.named('once_only'),
              child: const SizedBox(
                height: 100,
                width: double.infinity,
                child: ColoredBox(color: Colors.purple),
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump();
        VisibilityDetectorController.instance.notifyNow();
        await tester.pump();
      }

      expect(mock.capturedEvents, hasLength(1));
      expect(mock.capturedEvents.single.getName(), 'once_only');
    });

    testWidgets('does NOT fire when visibility stays below threshold',
        (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Offstage(
              offstage: true,
              child: FlexImpressionTrack(
                visibilityKey: const Key('imp_offstage'),
                visibleFractionThreshold: 0.01,
                event: CustomEvent.named('never_visible'),
                child: const SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: ColoredBox(color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      VisibilityDetectorController.instance.notifyNow();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(mock.capturedEvents, isEmpty);
    });

    testWidgets(
        'cancels pending track if widget hides before minVisibleDuration',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      // Start scrolled so the impression row is in view; then scroll away
      // before 400ms elapses so the pending timer must be cancelled.
      final scrollController = ScrollController(initialScrollOffset: 320);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  const SizedBox(height: 300),
                  FlexImpressionTrack(
                    visibilityKey: const Key('imp_scroll_cancel'),
                    visibleFractionThreshold: 0.01,
                    minVisibleDuration: const Duration(milliseconds: 400),
                    event: CustomEvent.named('fast_scroll_cancel'),
                    child: Container(
                      height: 120,
                      color: Colors.amber,
                      alignment: Alignment.center,
                      child: const Text('impression row'),
                    ),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      VisibilityDetectorController.instance.notifyNow();
      await tester.pump();
      expect(mock.capturedEvents, isEmpty);

      await tester.pump(const Duration(milliseconds: 100));
      expect(mock.capturedEvents, isEmpty);

      scrollController.jumpTo(600);
      await tester.pump();
      VisibilityDetectorController.instance.notifyNow();
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(mock.capturedEvents, isEmpty);
    });
  });
}
