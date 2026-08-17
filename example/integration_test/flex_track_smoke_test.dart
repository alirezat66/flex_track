import 'dart:io';

import 'package:flex_track/flex_track.dart';
import 'package:flex_track_example/main.dart' as app;
import 'package:flex_track_example/runtime/offline_delivery_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flagship example starts after consent flow', (tester) async {
    SharedPreferences.setMockInitialValues({
      'flex_track_demo_network_available': true,
    });
    final supportDirectory = await getApplicationSupportDirectory();
    final queueFile =
        File('${supportDirectory.path}/flex_track/event_queue.json');
    if (await queueFile.exists()) await queueFile.delete();
    final persistedQueue = FileEventQueue(queueFile);
    final restoredEvent = OfflineDeliveryDemoEvent(sequence: 0);
    await persistedQueue.enqueue(QueuedEvent(
      event: restoredEvent,
      trackerIds: const [
        'demo_delivery_success',
        'demo_delivery_retry',
      ],
    ));

    await app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(await FlexTrack.queuedEventCount, 0,
        reason: 'the event persisted before startup must be replayed');
    expect(
      OfflineDeliveryDemo.instance.successTracker.deliveredEventIds,
      contains(restoredEvent.eventId),
    );
    expect(
      OfflineDeliveryDemo.instance.retryTracker.deliveredEventIds,
      contains(restoredEvent.eventId),
    );

    await tester.tap(find.text('Accept All'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Preferences'));
    await tester.pumpAndSettle();

    expect(find.text('FlexTrack demo'), findsOneWidget);
    expect(find.textContaining('Widget wrappers'), findsOneWidget);

    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();
    expect(find.text('Offline Delivery Lab'), findsOneWidget);

    await tester.tap(find.byKey(const Key('network-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('track-delivery-event')));
    await tester.pumpAndSettle();
    expect(find.text('Pending events: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('network-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('flush-delivery-queue')));
    await tester.pumpAndSettle();
    expect(find.text('Pending events: 0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('flush-result')),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(find.textContaining('1 attempted · 1 delivered · 0 remaining'),
        findsOneWidget);
  });
}
