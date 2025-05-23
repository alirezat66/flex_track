import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:flex_track/flex_track.dart';
import 'trackers/firebase_tracker.dart';
import 'trackers/mixpanel_tracker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Mixpanel
  final mixpanel = await Mixpanel.init(
    'YOUR_MIXPANEL_TOKEN',
    trackAutomaticEvents: true,
  );

  // Create trackers
  final firebaseTracker =
      FirebaseTracker(analytics: FirebaseAnalytics.instance);
  final mixpanelTracker = MixpanelTracker(mixpanel: mixpanel);

  // Create events
  final purchaseEvent = PurchaseEvent(
    productId: 'premium_subscription',
    amount: 99.99,
    currency: 'USD',
  );

  final debugEvent = CustomEvent(
    name: 'debug_event',
    properties: {'debug_info': 'test_data'},
  );

  final testEvent = CustomEvent(
    name: 'test_event',
    properties: {'test_info': 'test_data'},
  );

  final sensitiveEvent = CustomEvent(
    name: 'sensitive_event',
    properties: {'user_data': 'sensitive_info'},
  );

  final userEvent = CustomEvent(
    name: 'user_event',
    properties: {'user_info': 'personal_data'},
  );

  // Configure routing
  final routingConfig = RoutingConfiguration(
    routes: [
      // Debug and test events only go to Mixpanel
      EventRouteConfig(
        events: [debugEvent, testEvent],
        strategies: [mixpanelTracker],
      ),
      // Sensitive and user events only go to Firebase
      EventRouteConfig(
        events: [sensitiveEvent, userEvent],
        strategies: [firebaseTracker],
      ),
      // Purchase events go to both
      EventRouteConfig(
        events: [purchaseEvent],
        strategies: [firebaseTracker, mixpanelTracker],
      ),
    ],
    // By default, send to all trackers
    defaultStrategies: [firebaseTracker, mixpanelTracker],
  );

  // Set up tracking manager
  final trackingManager = TrackingManager.instance
    ..registerTrackers([firebaseTracker, mixpanelTracker])
    ..setRoutingConfiguration(routingConfig);

  await trackingManager.initialize();

  runApp(MyApp(trackingManager: trackingManager));
}

class MyApp extends StatelessWidget {
  final TrackingManager trackingManager;

  const MyApp({super.key, required this.trackingManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlexTrack Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MyHomePage(trackingManager: trackingManager),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final TrackingManager trackingManager;

  const MyHomePage({super.key, required this.trackingManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlexTrack Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await trackingManager.track(PurchaseEvent(
                  productId: 'premium_subscription',
                  amount: 99.99,
                  currency: 'USD',
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchase event tracked')),
                  );
                }
              },
              child: const Text('Track Purchase Event'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await trackingManager.track(CustomEvent(
                  name: 'debug_event',
                  properties: {'debug_info': 'test_data'},
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Debug event tracked')),
                  );
                }
              },
              child: const Text('Track Debug Event'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await trackingManager.track(CustomEvent(
                  name: 'test_event',
                  properties: {'test_info': 'test_data'},
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test event tracked')),
                  );
                }
              },
              child: const Text('Track Test Event'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await trackingManager.track(CustomEvent(
                  name: 'sensitive_event',
                  properties: {'user_data': 'sensitive_info'},
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sensitive event tracked')),
                  );
                }
              },
              child: const Text('Track Sensitive Event'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await trackingManager.track(CustomEvent(
                  name: 'user_event',
                  properties: {'user_info': 'personal_data'},
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User event tracked')),
                  );
                }
              },
              child: const Text('Track User Event'),
            ),
          ],
        ),
      ),
    );
  }
}
