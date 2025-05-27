import 'package:flutter/material.dart';
import 'package:flex_track/flex_track.dart';
import '../events/app_events.dart';
import '../events/business_events.dart';
import '../events/user_events.dart';
import '../utils/gdpr_manager.dart';
import 'ecommerce_screen.dart';
import 'user_journey_screen.dart';
import 'setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DemoHomeTab(),
    const ECommerceScreen(),
    UserJourneyScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConsentAndShow();
  }

  Future<void> _checkConsentAndShow() async {
    // Show consent dialog if needed
    if (GDPRManager.needsConsentUpdate) {
      await GDPRManager.showConsentDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FlexTrack Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _showDebugInfo,
            tooltip: 'Debug Info',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          // Track navigation
          FlexTrack.track(ButtonClickEvent(
            buttonId: 'nav_tab_$index',
            buttonText: _getTabName(index),
            screenName: 'home',
          ));
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'E-commerce',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'User Journey',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'E-commerce';
      case 2:
        return 'User Journey';
      case 3:
        return 'Settings';
      default:
        return 'Unknown';
    }
  }

  void _showDebugInfo() {
    final debugInfo = FlexTrack.getDebugInfo();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('FlexTrack Debug Info'),
        content: SingleChildScrollView(
          child: Text(debugInfo.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class DemoHomeTab extends StatelessWidget {
  const DemoHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FlexTrack Demo',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          Text(
            'This demo showcases FlexTrack\'s powerful analytics routing system with GDPR compliance, multiple tracker integrations, and intelligent event handling.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _DemoCard(
                  title: 'Basic Events',
                  description: 'Track simple user interactions',
                  icon: Icons.touch_app,
                  onTap: () => _trackBasicEvent(context),
                ),
                _DemoCard(
                  title: 'Business Events',
                  description: 'E-commerce and revenue tracking',
                  icon: Icons.shopping_bag,
                  onTap: () => _trackBusinessEvent(context),
                ),
                _DemoCard(
                  title: 'User Events',
                  description: 'User behavior and engagement',
                  icon: Icons.person_outline,
                  onTap: () => _trackUserEvent(context),
                ),
                _DemoCard(
                  title: 'Error Simulation',
                  description: 'Test error tracking',
                  icon: Icons.error_outline,
                  onTap: () => _trackErrorEvent(context),
                ),
                _DemoCard(
                  title: 'Performance',
                  description: 'Performance metrics',
                  icon: Icons.speed,
                  onTap: () => _trackPerformanceEvent(context),
                ),
                _DemoCard(
                  title: 'Debug Events',
                  description: 'Development debugging',
                  icon: Icons.bug_report,
                  onTap: () => _trackDebugEvent(context),
                ),
              ],
            ),
          ),

          // Additional Demo Features
          _AdditionalDemoSection(),
        ],
      ),
    );
  }

  void _trackBasicEvent(BuildContext context) {
    FlexTrack.track(ButtonClickEvent(
      buttonId: 'demo_basic',
      buttonText: 'Basic Event Demo',
      screenName: 'home',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Basic event tracked!')),
    );
  }

  void _trackBusinessEvent(BuildContext context) {
    FlexTrack.track(PurchaseEvent(
      productId: 'demo_product',
      productName: 'Demo Product',
      amount: 99.99,
      currency: 'USD',
      paymentMethod: 'credit_card',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Business event tracked!')),
    );
  }

  void _trackUserEvent(BuildContext context) {
    FlexTrack.track(FeatureUsageEvent(
      featureName: 'demo_feature',
      action: 'start',
      context: {'source': 'home_screen'},
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User event tracked!')),
    );
  }

  void _trackErrorEvent(BuildContext context) {
    FlexTrack.track(ErrorEvent(
      errorType: 'demo_error',
      errorMessage: 'This is a demo error for testing',
      context: 'home_screen_demo',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error event tracked!')),
    );
  }

  void _trackPerformanceEvent(BuildContext context) {
    FlexTrack.track(PerformanceEvent(
      metricName: 'screen_load_time',
      value: 1.23,
      unit: 'seconds',
      context: 'home_screen',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Performance event tracked!')),
    );
  }

  void _trackDebugEvent(BuildContext context) {
    FlexTrack.track(DebugEvent(
      debugInfo: 'Demo debug event from home screen',
      level: 'info',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Debug event tracked!')),
    );
  }
}

/// Additional demo features section
class _AdditionalDemoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32),
        Text(
          'Advanced Features',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),

        // Batch Events Demo
        Card(
          child: ListTile(
            leading: Icon(Icons.batch_prediction, color: Colors.blue),
            title: Text('Batch Events'),
            subtitle: Text('Send multiple events at once'),
            trailing: ElevatedButton(
              onPressed: () => _sendBatchEvents(context),
              child: Text('Send'),
            ),
          ),
        ),

        // User Identification Demo
        Card(
          child: ListTile(
            leading: Icon(Icons.person, color: Colors.green),
            title: Text('User Identification'),
            subtitle: Text('Identify user across trackers'),
            trailing: ElevatedButton(
              onPressed: () => _identifyUser(context),
              child: Text('Identify'),
            ),
          ),
        ),

        // User Properties Demo
        Card(
          child: ListTile(
            leading: Icon(Icons.settings_applications, color: Colors.orange),
            title: Text('User Properties'),
            subtitle: Text('Set user properties across trackers'),
            trailing: ElevatedButton(
              onPressed: () => _setUserProperties(context),
              child: Text('Set'),
            ),
          ),
        ),

        // Consent Demo
        Card(
          child: ListTile(
            leading: Icon(Icons.privacy_tip, color: Colors.purple),
            title: Text('Privacy Controls'),
            subtitle: Text('Test consent management'),
            trailing: ElevatedButton(
              onPressed: () => _showConsentDemo(context),
              child: Text('Demo'),
            ),
          ),
        ),

        // Sampling Demo
        Card(
          child: ListTile(
            leading: Icon(Icons.tune, color: Colors.red),
            title: Text('Sampling Test'),
            subtitle: Text('Test event sampling with high volume'),
            trailing: ElevatedButton(
              onPressed: () => _testSampling(context),
              child: Text('Test'),
            ),
          ),
        ),

        // Event Routing Demo
        Card(
          child: ListTile(
            leading: Icon(Icons.alt_route, color: Colors.teal),
            title: Text('Routing Analysis'),
            subtitle: Text('Analyze how events are routed'),
            trailing: ElevatedButton(
              onPressed: () => _analyzeRouting(context),
              child: Text('Analyze'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendBatchEvents(BuildContext context) async {
    final events = [
      ButtonClickEvent(
        buttonId: 'batch_1',
        buttonText: 'Batch Event 1',
        screenName: 'home',
      ),
      ButtonClickEvent(
        buttonId: 'batch_2',
        buttonText: 'Batch Event 2',
        screenName: 'home',
      ),
      PerformanceEvent(
        metricName: 'batch_performance',
        value: 45.6,
        unit: 'ms',
        context: 'batch_demo',
      ),
    ];

    final results = await FlexTrack.trackAll(events);
    final successCount = results.where((r) => r.successful).length;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Batch sent: $successCount/${events.length} events successful')),
      );
    }
  }

  Future<void> _identifyUser(BuildContext context) async {
    final userId = 'demo_user_${DateTime.now().millisecondsSinceEpoch}';

    await FlexTrack.identifyUser(userId, {
      'name': 'Demo User',
      'email': 'demo@example.com',
      'signup_date': DateTime.now().toIso8601String(),
      'demo_user': true,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User identified: $userId')),
      );
    }
  }

  Future<void> _setUserProperties(BuildContext context) async {
    await FlexTrack.setUserProperties({
      'plan_type': 'premium',
      'team_size': 5,
      'industry': 'technology',
      'feature_flags': ['analytics_v2', 'advanced_routing'],
      'last_active': DateTime.now().toIso8601String(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User properties updated')),
      );
    }
  }

  Future<void> _showConsentDemo(BuildContext context) async {
    final currentStatus = FlexTrack.getConsentStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Consent Status Demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Consent Status:'),
            SizedBox(height: 8),
            Text('General: ${currentStatus['general'] == true ? '✅' : '❌'}'),
            Text('PII: ${currentStatus['pii'] == true ? '✅' : '❌'}'),
            SizedBox(height: 16),
            Text('Test consent changes:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              FlexTrack.setConsent(general: false, pii: false);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Consent disabled - tracking limited')),
              );
            },
            child: Text('Disable All'),
          ),
          TextButton(
            onPressed: () {
              FlexTrack.setConsent(general: true, pii: true);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Consent enabled - full tracking')),
              );
            },
            child: Text('Enable All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _testSampling(BuildContext context) async {
    // Send many events to test sampling
    const eventCount = 100;
    var successCount = 0;

    for (int i = 0; i < eventCount; i++) {
      final result = await FlexTrack.track(HighVolumeTestEvent(
        sequenceNumber: i,
        batchId: 'sampling_test_${DateTime.now().millisecondsSinceEpoch}',
      ));

      if (result.successful) successCount++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Sampling test: $successCount/$eventCount events tracked'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _analyzeRouting(BuildContext context) {
    // Test different event types and show routing results
    final testEvents = [
      ButtonClickEvent(
          buttonId: 'test', buttonText: 'Test', screenName: 'home'),
      PurchaseEvent(
          productId: 'p1',
          productName: 'Product',
          amount: 99.99,
          currency: 'USD',
          paymentMethod: 'card'),
      ErrorEvent(errorType: 'test', errorMessage: 'Test error'),
      DebugEvent(debugInfo: 'Debug test'),
    ];

    final routingResults = testEvents.map((event) {
      final debug = FlexTrack.debugEvent(event);
      return {
        'event': event.name,
        'category': event.category?.name ?? 'none',
        'trackers': debug.routingResult.targetTrackers,
        'rules': debug.routingResult.appliedRules.length,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Event Routing Analysis'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: routingResults
                .map((result) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${result['event']} (${result['category']})',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                              '→ Trackers: ${(result['trackers'] as List).join(', ')}'),
                          Text('→ Rules: ${result['rules']}'),
                          SizedBox(height: 8),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// High volume test event
class HighVolumeTestEvent extends BaseEvent {
  final int sequenceNumber;
  final String batchId;

  HighVolumeTestEvent({
    required this.sequenceNumber,
    required this.batchId,
  });

  @override
  String get name => 'high_volume_test';

  @override
  Map<String, Object> get properties => {
        'sequence_number': sequenceNumber,
        'batch_id': batchId,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.technical;

  @override
  bool get isHighVolume => true; // This will trigger sampling

  @override
  bool get requiresConsent => false; // Test event
}

class _DemoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _DemoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Debug event for testing
class DebugEvent extends BaseEvent {
  final String debugInfo;
  final String level;

  DebugEvent({
    required this.debugInfo,
    this.level = 'debug',
  });

  @override
  String get name => 'debug_event';

  @override
  Map<String, Object> get properties => {
        'debug_info': debugInfo,
        'level': level,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  EventCategory get category => EventCategory.technical;

  @override
  bool get requiresConsent => false; // Debug events for development
}
