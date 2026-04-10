import 'package:flex_track_example/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flagship example starts after consent flow', (tester) async {
    await app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('Accept All'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Preferences'));
    await tester.pumpAndSettle();

    expect(find.text('FlexTrack demo'), findsOneWidget);
    expect(find.textContaining('Widget wrappers'), findsOneWidget);
  });
}
