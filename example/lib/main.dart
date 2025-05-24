import 'package:flutter/material.dart';
import 'package:flex_track/flex_track.dart';
import 'screens/home_screen.dart';
import 'utils/analytics_setup.dart';
import 'utils/gdpr_manager.dart';
import 'events/app_events.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FlexTrack with comprehensive configuration
  await AnalyticsSetup.initialize();

  // Set up GDPR compliance
  await GDPRManager.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexTrack Comprehensive Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(),
      // Global navigation observer for page tracking
      navigatorObservers: [
        AnalyticsNavigatorObserver(),
      ],
    );
  }
}

/// Custom navigator observer for automatic page tracking
class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackPageView(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackPageView(previousRoute);
    }
  }

  void _trackPageView(Route<dynamic> route) {
    if (route.settings.name != null) {
      FlexTrack.track(PageViewEvent(
        pageName: route.settings.name!,
        timestamp: DateTime.now(),
      ));
    }
  }
}
