import 'package:flex_track/flex_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils/mock_events.dart';

void main() {
  group('FlexMountTrack', () {
    tearDown(() async {
      await FlexTrack.reset();
    });

    testWidgets('sends event once after first frame', (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexMountTrack(
              event: CustomEvent.named('mounted_view'),
              child: const Text('content'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'mounted_view');

      await tester.pump();
      expect(mock.capturedEvents, hasLength(1));
    });

    testWidgets('fires again when widget is remounted after removal',
        (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        const MaterialApp(
          home: _MountToggleHost(),
        ),
      );

      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'mount_first');

      await tester.tap(find.text('toggle off'));
      await tester.pump();

      await tester.tap(find.text('toggle on'));
      await tester.pump();

      expect(mock.capturedEvents, hasLength(2));
      expect(mock.capturedEvents.map((e) => e.getName()).toList(),
          ['mount_first', 'mount_first']);
    });

    testWidgets('fires when ListView lazily builds item (scroll into range)',
        (tester) async {
      final mock = await setupFlexTrackForTesting();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 40,
              itemExtent: 72,
              itemBuilder: (context, index) {
                if (index == 18) {
                  return FlexMountTrack(
                    event: CustomEvent.named('lazy_mount'),
                    child: Container(
                      height: 72,
                      alignment: Alignment.center,
                      color: Colors.teal,
                      child: const Text('tracked cell'),
                    ),
                  );
                }
                return SizedBox(
                  height: 72,
                  child: Center(child: Text('item $index')),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      expect(mock.capturedEvents, isEmpty,
          reason: 'target item should not be built yet');

      await tester.scrollUntilVisible(
        find.text('tracked cell'),
        500,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(mock.capturedEvents, hasLength(1));
      expect(mock.capturedEvents.single.getName(), 'lazy_mount');
    });

    testWidgets('uses FlexTrackScope client without FlexTrack.setup',
        (tester) async {
      final mock = MockTracker();
      final client = await FlexTrackClient.create([mock]);
      addTearDown(() async {
        await client.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FlexTrackScope(
            client: client,
            child: Scaffold(
              body: FlexMountTrack(
                event: CustomEvent.named('scoped_mount'),
                child: const Text('content'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(mock.capturedEvents.single.getName(), 'scoped_mount');
    });

    testWidgets('scoped client is preferred when global is also set up',
        (tester) async {
      final globalMock = await setupFlexTrackForTesting();
      final scopedMock = MockTracker();
      final scopedClient = await FlexTrackClient.create([scopedMock]);
      addTearDown(() async {
        await scopedClient.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: FlexTrackScope(
            client: scopedClient,
            child: Scaffold(
              body: FlexMountTrack(
                event: CustomEvent.named('mount_scoped_wins'),
                child: const Text('x'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(scopedMock.capturedEvents.single.getName(), 'mount_scoped_wins');
      expect(globalMock.capturedEvents, isEmpty);
    });

    testWidgets('no-op when neither FlexTrackScope nor FlexTrack.setup',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlexMountTrack(
              event: CustomEvent.named('should_not_mount_track'),
              child: const Text('orphan'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
    });
  });
}

class _MountToggleHost extends StatefulWidget {
  const _MountToggleHost();

  @override
  State<_MountToggleHost> createState() => _MountToggleHostState();
}

class _MountToggleHostState extends State<_MountToggleHost> {
  bool _showMount = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_showMount)
            FlexMountTrack(
              event: CustomEvent.named('mount_first'),
              child: const Text('mounted block'),
            ),
          TextButton(
            onPressed: () => setState(() => _showMount = false),
            child: const Text('toggle off'),
          ),
          TextButton(
            onPressed: () => setState(() => _showMount = true),
            child: const Text('toggle on'),
          ),
        ],
      ),
    );
  }
}
