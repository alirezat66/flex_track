# FlexTrack 🎯

A powerful and flexible analytics tracking system for Flutter that provides intelligent event routing, GDPR compliance, and seamless multi-platform support.

## ✨ Features

- **🎯 Intelligent Routing**: Route events to different analytics services based on configurable rules
- **🔒 GDPR Compliant**: Built-in consent management and privacy controls
- **📊 Multi-Platform**: Works seamlessly across iOS, Android, Web, and Desktop
- **⚡ Performance Optimized**: Smart sampling, batching, and performance presets
- **🧪 Developer Friendly**: Comprehensive debugging tools and console tracker
- **🔧 Highly Configurable**: Extensive customization options for any use case

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flex_track: ^0.1.0
```

### Basic Setup

```dart
import 'package:flex_track/flex_track.dart';

void main() async {
  // Quick setup with smart defaults
  await FlexTrack.setup([
    ConsoleTracker(), // For development
    YourAnalyticsTracker(), // Your production tracker
  ]);

  runApp(MyApp());
}

// Track events anywhere in your app
await FlexTrack.track(CustomEvent(
  name: 'user_signup',
  properties: {'method': 'email'},
));
```

### Advanced Routing

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  FirebaseTracker(),
  MixpanelTracker(),
], (routing) => routing
  // Debug events only to console in development
  .routeMatching(RegExp(r'debug_.*'))
  .toDevelopment()
  .onlyInDebug()
  .and()
  
  // Sensitive data requires PII consent
  .routeCategory(EventCategory.sensitive)
  .toAll()
  .requirePIIConsent()
  .and()
  
  // High volume events get sampled
  .routeHighVolume()
  .toAll()
  .lightSampling()
  .and()
  
  // Default: everything to all trackers
  .routeDefault()
  .toAll()
);
```

## 📚 Documentation

### Core Concepts

- **Events**: Data points you want to track
- **Trackers**: Analytics services (Firebase, Mixpanel, etc.)
- **Routing Rules**: Logic that determines which events go to which trackers
- **Groups**: Collections of trackers for easier management

### Event Types

Create custom events by implementing `BaseEvent`:

```dart
class PurchaseEvent extends BaseEvent {
  final String productId;
  final double amount;
  final String currency;

  PurchaseEvent({
    required this.productId,
    required this.amount,
    required this.currency,
  });

  @override
  String getName() => 'purchase';

  @override
  Map<String, Object> getProperties() => {
    'product_id': productId,
    'amount': amount,
    'currency': currency,
  };
  
  @override
  EventCategory get category => EventCategory.business;
  
  @override
  bool get containsPII => false;
}
```

### Custom Trackers

Implement your own tracker by extending `BaseTrackerStrategy`:

```dart
class MyAnalyticsTracker extends BaseTrackerStrategy {
  MyAnalyticsTracker() : super(
    id: 'my_analytics',
    name: 'My Analytics Service',
  );

  @override
  Future<void> doInitialize() async {
    // Initialize your analytics SDK
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // Send event to your analytics service
    await myAnalytics.track(
      event.getName(),
      event.getProperties(),
    );
  }
}
```

## 🔧 Configuration Examples

### Performance-Focused Setup

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  ProductionTracker(),
], (builder) => builder
  .applyPerformanceFocused() // Applies aggressive sampling
);
```

### Privacy-Focused Setup

```dart
await FlexTrack.setupWithRouting([
  GDPRCompliantTracker(),
], (builder) => builder
  .applyPrivacyFocused() // Strict consent requirements
);
```

### Development Setup

```dart
await setupFlexTrackForDevelopment(); // Convenience method
```

## 🛡️ GDPR Compliance

FlexTrack makes GDPR compliance straightforward:

```dart
// Set consent status
FlexTrack.setConsent(general: true, pii: false);

// Events requiring PII consent won't be tracked
await FlexTrack.track(SensitiveEvent()); // Blocked without PII consent

// Essential events always go through
await FlexTrack.track(EssentialEvent());
```

## 🐛 Debugging

### Debug Events

```dart
// See exactly how events are routed
final debugInfo = FlexTrack.debugEvent(myEvent);
print(debugInfo.routingResult);

// Get comprehensive system info
FlexTrack.printDebugInfo();
```

### Console Tracker

Perfect for development and debugging:

```dart
ConsoleTracker(
  showProperties: true,
  showTimestamps: true,
  colorOutput: true,
)
```

## 🧪 Testing

FlexTrack includes testing utilities:

```dart
testWidgets('analytics test', (tester) async {
  final mockTracker = await setupFlexTrackForTesting();
  
  // Your test code
  await FlexTrack.track(TestEvent());
  
  // Verify events were tracked
  expect(mockTracker.capturedEvents, hasLength(1));
  expect(mockTracker.capturedEvents.first.getName(), 'test_event');
});
```

## 🏗️ Architecture

FlexTrack follows a clean, modular architecture:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   FlexTrack     │───▶│  RoutingEngine   │───▶│   Trackers      │
│   (Main API)    │    │  (Rule Matching) │    │  (Analytics)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ EventProcessor  │    │ RoutingBuilder   │    │ TrackerRegistry │
│ (Processing)    │    │ (Configuration)  │    │ (Management)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need for flexible analytics in Flutter apps
- Built with GDPR compliance and developer experience in mind
- Thanks to the Flutter community for feedback and suggestions