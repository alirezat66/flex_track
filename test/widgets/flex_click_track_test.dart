import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/mock_events.dart';

void main() {
  group('FlexClickTrack', () {
    tearDown(() async {
      await FlexTrack.reset();
    });

    testWidgets(
        'tracks when child is InkWell (Listener sees pointer up on hit path)',
        (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexClickTrack(
              event: CustomEvent.named('cta_tap'),
              child: Material(
                child: InkWell(
                  onTap: () {},
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(mock.capturedEvents.single.getName(), 'cta_tap');
    });

    testWidgets('sends event when child is plain Text (tap on text)',
        (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexClickTrack(
              event: CustomEvent.named('label_tap'),
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(mock.capturedEvents.single.getName(), 'label_tap');
    });

    testWidgets(
        'ElevatedButton onPressed still runs when wrapped (child wins arena)',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexClickTrack(
              event: CustomEvent.named('button_wrap'),
              child: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: const Text('Submit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(buttonPressed, isTrue,
          reason: 'Material button must still receive the tap');
      expect(mock.capturedEvents.single.getName(), 'button_wrap');
    });

    testWidgets(
        'nested Container: ElevatedButton onPressed runs when tapping the button',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexClickTrack(
              event: CustomEvent.named('nested_container'),
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.blueGrey.shade100,
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () => buttonPressed = true,
                  child: const Text('Inner'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Inner'));
      await tester.pump();

      expect(buttonPressed, isTrue);
      expect(mock.capturedEvents.single.getName(), 'nested_container');
    });

    testWidgets(
        'tap on Container padding (non-button area) still tracks via outer Listener',
        (tester) async {
      final mock = await setupFlexTrackForTesting();
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexClickTrack(
              event: CustomEvent.named('padding_area'),
              child: Container(
                width: 320,
                height: 240,
                color: Colors.teal.shade100,
                padding: const EdgeInsets.all(48),
                alignment: Alignment.topLeft,
                child: ElevatedButton(
                  onPressed: () => buttonPressed = true,
                  child: const Text('OnlyButton'),
                ),
              ),
            ),
          ),
        ),
      );

      final outer = tester.getRect(find.byType(FlexClickTrack));
      // Corner of the wrapper, inside the colored Container but away from the button
      await tester.tapAt(outer.topLeft + const Offset(12, 12));
      await tester.pump();

      expect(buttonPressed, isFalse,
          reason: 'tap should not hit the ElevatedButton');
      expect(mock.capturedEvents.single.getName(), 'padding_area');
    });

    testWidgets('does NOT track on scroll/drag over widget', (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  FlexClickTrack(
                    event: CustomEvent.named('drag_test'),
                    child: Container(height: 200, color: Colors.red),
                  ),
                  Container(height: 1000, color: Colors.blue),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(FlexClickTrack), const Offset(0, -100));
      await tester.pump();

      expect(mock.capturedEvents, isEmpty);
    });
  });
}
