import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'app_route_observer.dart';
import 'screens/home_screen.dart';
import 'utils/analytics_setup.dart';
import 'utils/gdpr_manager.dart';

/// Flagship demo: routing, GDPR, multi-tracker mocks, widget wrappers.
/// Smaller integration patterns live under ../examples/ (static, Riverpod, BLoC+GetIt).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 200);

  await AnalyticsSetup.initialize();
  await GDPRManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexTrack demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      navigatorObservers: [appFlexRouteObserver],
    );
  }
}
