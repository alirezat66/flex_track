# FlexTrack 🎯

**The Complete Analytics Routing Solution for Flutter Apps**

Stop wrestling with multiple analytics services, GDPR compliance, and performance issues. FlexTrack gives you **one simple API** that intelligently handles everything.

---

## 🤔 What Problem Does This Solve?

### The Nightmare of Modern App Analytics

Imagine you're building an e-commerce Flutter app. You need:

- **Firebase Analytics** (free, basic metrics)
- **Mixpanel** (detailed user behavior) 
- **Amplitude** (product analytics)
- **Your own API** (business intelligence)
- **Console logging** (debugging)

**Without FlexTrack**, your code looks like this mess:

```dart
// 😱 SCATTERED THROUGHOUT YOUR APP
void onUserPurchase(double amount) {
  // Firebase
  FirebaseAnalytics.instance.logEvent(
    name: 'purchase', 
    parameters: {'amount': amount}
  );
  
  // Mixpanel - but only if user consented
  if (userConsentedToTracking) {
    MixpanelFlutter.getInstance().track('purchase', {
      'amount': amount
    });
  }
  
  // Amplitude - different format
  Amplitude.getInstance().logEvent('purchase', {
    'revenue': amount
  });
  
  // Your API - only in production
  if (!kDebugMode) {
    customAPI.sendEvent('purchase', {'amount': amount});
  }
  
  // Console - only in debug
  if (kDebugMode) {
    print('Purchase: $amount');
  }
}

// 😱 REPEATED FOR EVERY EVENT TYPE
void onUserSignup() { /* same mess */ }
void onPageView() { /* same mess */ }
void onButtonClick() { /* same mess */ }
```

**Problems with this approach:**
- ❌ Code duplicated everywhere
- ❌ Hard to maintain
- ❌ Easy to forget analytics calls
- ❌ GDPR compliance is manual and error-prone
- ❌ Performance issues (all services hit for every event)
- ❌ Different formats for each service
- ❌ Environment logic mixed with business logic

### The FlexTrack Solution

**With FlexTrack**, the same functionality becomes:

```dart
// ✅ ONE SIMPLE CALL ANYWHERE
await FlexTrack.track(PurchaseEvent(amount: amount));

// FlexTrack automatically:
// → Sends to Firebase (always)
// → Sends to Mixpanel (only with consent)
// → Sends to Amplitude (only in production)
// → Sends to your API (only in production)
// → Prints to console (only in debug)
// → Handles all formatting differences
// → Respects GDPR consent
// → Applies performance optimizations
```

---

## 📊 How FlexTrack Works (Visual Guide)

### Traditional Approach vs FlexTrack

```
TRADITIONAL APPROACH (Manual Management)
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Login     │    │  Purchase   │    │  Page View  │
│   Screen    │    │   Screen    │    │   Screen    │
└─────┬───────┘    └─────┬───────┘    └─────┬───────┘
      │                  │                  │
      ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────┐
│           DUPLICATE CODE EVERYWHERE                 │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │Firebase │ │Mixpanel │ │Amplitude│ │Custom API│  │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘  │
└─────────────────────────────────────────────────────┘

FLEXTRACK APPROACH (Centralized Management)
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Login     │    │  Purchase   │    │  Page View  │
│   Screen    │    │   Screen    │    │   Screen    │
└─────┬───────┘    └─────┬───────┘    └─────┬───────┘
      │                  │                  │
      └──────────────────┼──────────────────┘
                         ▼
              ┌─────────────────┐
              │   FlexTrack     │◄─── ONE API
              │  (Smart Router) │
              └─────────┬───────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
    ┌─────────┐   ┌─────────┐   ┌─────────┐
    │Firebase │   │Mixpanel │   │Amplitude│
    └─────────┘   └─────────┘   └─────────┘
```

### FlexTrack Internal Architecture

```
EVENT FLOW THROUGH FLEXTRACK
┌─────────────────┐
│  Your Event     │ ──┐
│ (PurchaseEvent) │   │
└─────────────────┘   │
                      ▼
┌─────────────────────────────────────┐
│           FLEXTRACK CORE            │
│                                     │
│  ┌─────────────┐  ┌─────────────┐   │
│  │   Event     │  │  Routing    │   │
│  │ Processor   │──│   Engine    │   │
│  └─────────────┘  └─────────────┘   │
│          │                │         │
│          ▼                ▼         │
│  ┌─────────────┐  ┌─────────────┐   │
│  │  Consent    │  │  Sampling   │   │
│  │  Manager    │  │   System    │   │
│  └─────────────┘  └─────────────┘   │
└─────────────────┬───────────────────┘
                  │
      ┌───────────┼───────────┐
      ▼           ▼           ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│Tracker 1 │ │Tracker 2 │ │Tracker 3 │
│(Firebase)│ │(Mixpanel)│ │(Console) │
└──────────┘ └──────────┘ └──────────┘
```

---

## 🚀 Step-by-Step Setup Guide

### Step 1: Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flex_track: ^0.1.0
  
  # If using Firebase
  firebase_analytics: ^10.0.0
  
  # If using Mixpanel  
  mixpanel_flutter: ^2.0.0
```

### Step 2: Basic Setup (Beginner)

In your `main.dart`:

```dart
import 'package:flex_track/flex_track.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🎯 SETUP FLEXTRACK WITH ONE LINE
  await FlexTrack.setup([
    ConsoleTracker(), // Shows events in debug console
    // Add your other trackers here later
  ]);
  
  runApp(MyApp());
}
```

### Step 3: Create Your First Event

Create a file `lib/events/my_events.dart`:

```dart
import 'package:flex_track/flex_track.dart';

// 📝 USER SIGNUP EVENT
class UserSignupEvent extends BaseEvent {
  final String method; // 'email', 'google', 'apple'
  final bool acceptedMarketing;
  
  UserSignupEvent({
    required this.method,
    this.acceptedMarketing = false,
  });
  
  @override
  String get name => 'user_signup';
  
  @override
  Map<String, Object> get properties => {
    'signup_method': method,
    'accepted_marketing': acceptedMarketing,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  
  @override
  EventCategory get category => EventCategory.business; // Important!
  
  @override
  bool get containsPII => false; // No personal data
}

// 💰 PURCHASE EVENT  
class PurchaseEvent extends BaseEvent {
  final String productId;
  final double amount;
  final String currency;
  
  PurchaseEvent({
    required this.productId,
    required this.amount,
    this.currency = 'USD',
  });
  
  @override
  String get name => 'purchase';
  
  @override
  Map<String, Object> get properties => {
    'product_id': productId,
    'amount': amount,
    'currency': currency,
  };
  
  @override
  EventCategory get category => EventCategory.business;
  
  @override
  bool get isEssential => true; // Never sample this!
}

// 🖱️ BUTTON CLICK EVENT
class ButtonClickEvent extends BaseEvent {
  final String buttonId;
  final String screenName;
  
  ButtonClickEvent({
    required this.buttonId,
    required this.screenName,
  });
  
  @override
  String get name => 'button_click';
  
  @override
  Map<String, Object> get properties => {
    'button_id': buttonId,
    'screen_name': screenName,
  };
  
  @override
  EventCategory get category => EventCategory.user;
  
  @override
  bool get isHighVolume => true; // Will be sampled
}
```

### Step 4: Track Events in Your App

```dart
// In your signup screen
class SignupScreen extends StatelessWidget {
  void _onSignupSuccess(String method) async {
    // 🎯 ONE LINE TO TRACK
    await FlexTrack.track(UserSignupEvent(
      method: method,
      acceptedMarketing: true,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _onSignupSuccess('email'),
            child: Text('Sign Up with Email'),
          ),
          ElevatedButton(
            onPressed: () => _onSignupSuccess('google'),
            child: Text('Sign Up with Google'),
          ),
        ],
      ),
    );
  }
}

// In your purchase screen
class PurchaseScreen extends StatelessWidget {
  void _onPurchaseComplete(String productId, double amount) async {
    await FlexTrack.track(PurchaseEvent(
      productId: productId,
      amount: amount,
    ));
  }
}

// Track button clicks automatically
class MyButton extends StatelessWidget {
  final String id;
  final VoidCallback onPressed;
  final Widget child;
  
  const MyButton({
    required this.id,
    required this.onPressed,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Track the click
        FlexTrack.track(ButtonClickEvent(
          buttonId: id,
          screenName: 'home', // You can make this dynamic
        ));
        
        // Execute the original action
        onPressed();
      },
      child: child,
    );
  }
}
```

### Step 5: See Your Events in Action

Run your app in debug mode and watch the console:

```
📊 FlexTrack: user_signup (business)
  Properties: {signup_method: email, accepted_marketing: true, timestamp: 1641234567890}
  Flags: ESSENTIAL

📊 FlexTrack: button_click (user)
  Properties: {button_id: signup_btn, screen_name: home}
  Flags: HIGH_VOLUME
```

**Congratulations! 🎉 You're now tracking events with FlexTrack!**

---

## 🔧 Adding Real Analytics Services

### Adding Firebase Analytics

1. **Setup Firebase** (follow official Firebase setup guide)

2. **Create Firebase Tracker:**

```dart
// lib/trackers/firebase_tracker.dart
import 'package:flex_track/flex_track.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseTracker extends BaseTrackerStrategy {
  late FirebaseAnalytics _analytics;
  
  FirebaseTracker() : super(
    id: 'firebase',
    name: 'Firebase Analytics',
  );
  
  @override
  bool get isGDPRCompliant => true;
  
  @override
  Future<void> doInitialize() async {
    _analytics = FirebaseAnalytics.instance;
    print('🔥 Firebase Analytics initialized');
  }
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    await _analytics.logEvent(
      name: event.name,
      parameters: _convertProperties(event.properties),
    );
  }
  
  // Firebase has parameter name/value restrictions
  Map<String, Object>? _convertProperties(Map<String, Object>? props) {
    if (props == null) return null;
    
    final converted = <String, Object>{};
    props.forEach((key, value) {
      // Firebase parameter names must be <= 40 chars, alphanumeric + underscore
      final cleanKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final shortKey = cleanKey.length > 40 ? cleanKey.substring(0, 40) : cleanKey;
      converted[shortKey] = value;
    });
    
    return converted;
  }
}
```

3. **Add to FlexTrack Setup:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FlexTrack.setup([
    ConsoleTracker(),
    FirebaseTracker(), // 🔥 Added Firebase!
  ]);
  
  runApp(MyApp());
}
```

Now your events go to both Console (debug) and Firebase (production)!

### Adding Mixpanel

1. **Add Mixpanel dependency:**

```yaml
dependencies:
  mixpanel_flutter: ^2.0.0
```

2. **Create Mixpanel Tracker:**

```dart
// lib/trackers/mixpanel_tracker.dart
import 'package:flex_track/flex_track.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixpanelTracker extends BaseTrackerStrategy {
  late Mixpanel _mixpanel;
  final String _token;
  
  MixpanelTracker({required String token}) 
    : _token = token,
      super(
        id: 'mixpanel',
        name: 'Mixpanel Analytics',
      );
  
  @override
  bool get isGDPRCompliant => true;
  
  @override
  Future<void> doInitialize() async {
    _mixpanel = await Mixpanel.init(_token, trackAutomaticEvents: false);
    print('🎯 Mixpanel initialized');
  }
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    _mixpanel.track(event.name, properties: event.properties);
  }
  
  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    _mixpanel.getPeople().set(properties);
  }
  
  @override
  Future<void> doIdentifyUser(String userId, [Map<String, dynamic>? properties]) async {
    _mixpanel.identify(userId);
    if (properties != null) {
      await doSetUserProperties(properties);
    }
  }
}
```

3. **Add to Setup:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FlexTrack.setup([
    ConsoleTracker(),
    FirebaseTracker(),
    MixpanelTracker(token: 'YOUR_MIXPANEL_TOKEN'), // 🎯 Added Mixpanel!
  ]);
  
  runApp(MyApp());
}
```

### Adding Your Custom API

```dart
// lib/trackers/custom_api_tracker.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flex_track/flex_track.dart';

class CustomAPITracker extends BaseTrackerStrategy {
  final String _baseUrl;
  final String? _apiKey;
  
  CustomAPITracker({
    required String baseUrl,
    String? apiKey,
  }) : _baseUrl = baseUrl,
       _apiKey = apiKey,
       super(
         id: 'custom_api',
         name: 'Custom API Tracker',
       );
  
  @override
  Future<void> doInitialize() async {
    // Test API connection
    try {
      await http.get(Uri.parse('$_baseUrl/health'));
      print('🌐 Custom API tracker initialized');
    } catch (e) {
      throw Exception('Failed to connect to custom API: $e');
    }
  }
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    final payload = {
      'event_name': event.name,
      'properties': event.properties,
      'timestamp': DateTime.now().toIso8601String(),
      'category': event.category?.name,
    };
    
    await http.post(
      Uri.parse('$_baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(payload),
    );
  }
}
```

---

## 🎯 Smart Routing (The Real Power)

Now that you have multiple trackers, you want different events to go to different places. This is where FlexTrack really shines!

### Basic Routing Examples

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  FirebaseTracker(),
  MixpanelTracker(token: 'your-token'),
  CustomAPITracker(baseUrl: 'https://your-api.com'),
], (routing) => routing
  
  // 🏠 EXAMPLE 1: Route by event category
  .routeCategory(EventCategory.business)
  .toAll() // Send business events to ALL trackers
  .and()
  
  // 👤 EXAMPLE 2: Route user behavior only to Mixpanel
  .routeCategory(EventCategory.user)
  .to(['mixpanel']) // Only to Mixpanel
  .and()
  
  // 🐛 EXAMPLE 3: Debug events only to console in development
  .routeMatching(RegExp(r'debug_.*'))
  .to(['console'])
  .onlyInDebug()
  .and()
  
  // 🎯 EXAMPLE 4: Everything else goes to Firebase and Console
  .routeDefault()
  .to(['firebase', 'console'])
);
```

### Real-World Routing Scenarios

#### Scenario 1: E-commerce App

```dart
routing
  // 💰 CRITICAL BUSINESS EVENTS - Go everywhere, never sample
  .routeCategory(EventCategory.business)
  .toAll()
  .noSampling() // 100% of events
  .withPriority(20) // High priority
  .and()
  
  // 🛒 SHOPPING BEHAVIOR - Only to detailed analytics
  .routeMatching(RegExp(r'(cart|product|checkout)_.*'))
  .to(['mixpanel', 'custom_api'])
  .and()
  
  // 🖱️ UI INTERACTIONS - High volume, sample heavily
  .routeMatching(RegExp(r'(click|scroll|hover)_.*'))
  .toAll()
  .heavySampling() // Only 1% of events
  .and()
  
  // 📄 PAGE VIEWS - Medium volume
  .routeMatching(RegExp(r'page_view'))
  .to(['firebase', 'mixpanel'])
  .lightSampling() // 10% of events
  .and()
  
  // 🏠 EVERYTHING ELSE - Basic tracking
  .routeDefault()
  .to(['firebase', 'console'])
  .mediumSampling() // 50% of events
```

#### Scenario 2: SaaS App with Privacy Requirements

```dart
routing
  // Define tracker groups first
  .defineGroup('privacy_safe', ['firebase', 'console'])
  .defineGroup('full_analytics', ['firebase', 'mixpanel', 'amplitude'])
  .defineGroup('internal_only', ['custom_api', 'console'])
  
  // 🔒 SENSITIVE DATA - Only to privacy-safe trackers
  .routeCategory(EventCategory.sensitive)
  .toGroupNamed('privacy_safe')
  .requirePIIConsent() // Must have PII consent
  .noSampling()
  .and()
  
  // 👤 USER DATA - Requires consent
  .routePII() // Events marked as containing PII
  .toGroupNamed('privacy_safe')
  .requirePIIConsent()
  .and()
  
  // 💼 BUSINESS METRICS - Internal tracking only
  .routeWithProperty('internal_metric')
  .toGroupNamed('internal_only')
  .skipConsent() // Legitimate business interest
  .and()
  
  // 📊 GENERAL ANALYTICS - Full tracking with consent
  .routeDefault()
  .toGroupNamed('full_analytics')
  .requireConsent()
```

### Understanding Routing Priority

Events are matched against rules in **priority order** (highest first):

```dart
routing
  // Priority 30 - Checked first
  .routeEssential()
  .toAll()
  .withPriority(30)
  .and()
  
  // Priority 20 - Checked second  
  .routeCategory(EventCategory.business)
  .toAll()
  .withPriority(20)
  .and()
  
  // Priority 10 - Checked third
  .routeHighVolume()
  .to(['firebase'])
  .withPriority(10)
  .and()
  
  // Priority 0 - Checked last (default)
  .routeDefault()
  .toAll()
  .withPriority(0)
```

**Visual Priority Flow:**
```
Event: PurchaseEvent (business, essential)
    ↓
Priority 30: routeEssential() ← MATCHES! (Goes to all trackers)
    ↓
Priority 20: routeCategory(business) ← Would match but skipped
    ↓  
Priority 10: routeHighVolume() ← Skipped
    ↓
Priority 0: routeDefault() ← Skipped
```

---

## 📊 Event Categories Explained

Event categories help FlexTrack automatically route events. Here's what each category means:

### EventCategory.business
**What**: Revenue, conversions, subscriptions, critical business metrics  
**Characteristics**: High priority, never sampled, goes to all analytics  
**Examples**:
```dart 
class PurchaseEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.business;
}

class SubscriptionEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.business;
}
```

### EventCategory.user
**What**: User behavior, preferences, actions  
**Characteristics**: Requires consent, may be sampled  
**Examples**:
```dart
class ProfileUpdateEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.user;
}

class SettingsChangeEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.user;
}
```

### EventCategory.technical
**What**: Errors, performance, debugging info  
**Characteristics**: Often debug-only, may skip consent (legitimate interest)  
**Examples**:
```dart
class ErrorEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.technical;
}

class PerformanceEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.technical;
}
```

### EventCategory.sensitive
**What**: Events with personal data  
**Characteristics**: Requires PII consent, privacy-safe trackers only  
**Examples**:
```dart
class LocationEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.sensitive;
  
  @override
  bool get containsPII => true;
}
```

### EventCategory.marketing
**What**: Campaign tracking, attribution, ads  
**Characteristics**: Requires marketing consent  
**Examples**:
```dart
class AdClickEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.marketing;
}
```

### EventCategory.system
**What**: App lifecycle, health checks, system status  
**Characteristics**: Usually essential, no consent required  
**Examples**:
```dart
class AppStartEvent extends BaseEvent {
  @override
  EventCategory get category => EventCategory.system;
  
  @override
  bool get isEssential => true;
  
  @override
  bool get requiresConsent => false;
}
```

---

## 🛡️ GDPR Compliance Made Easy

FlexTrack handles GDPR automatically once you set it up correctly.

### Understanding Consent Types

```dart
// Set consent status (usually from your privacy settings screen)
FlexTrack.setConsent(
  general: true,  // Can track general analytics
  pii: false,     // Cannot track personal information
);

// Check current consent
final consent = FlexTrack.getConsentStatus();
print('General consent: ${consent['general']}');
print('PII consent: ${consent['pii']}');
```

### How Events Are Filtered by Consent

```
USER HAS GENERAL CONSENT = true, PII CONSENT = false

Event: LoginEvent (requires general consent)
  ✅ Has general consent → Event is tracked

Event: ProfileUpdateEvent (requires PII consent)  
  ❌ No PII consent → Event is blocked

Event: CrashReportEvent (essential, no consent required)
  ✅ Essential event → Always tracked
```

### Automatic GDPR Routing

```dart
await FlexTrack.setupWithRouting([
  FirebaseTracker(),
  MixpanelTracker(token: 'token'),
  GDPRCompliantTracker(), // Your privacy-safe tracker
], (routing) {
  // Apply GDPR defaults - this sets up intelligent consent handling
  GDPRDefaults.apply(routing, compliantTrackers: ['gdpr_compliant']);
  
  return routing;
});
```

What `GDPRDefaults.apply()` does automatically:

```dart
// Equivalent manual setup:
routing
  // PII events only to compliant trackers
  .routePII()
  .toGroupNamed('gdpr_compliant')
  .requirePIIConsent()
  .noSampling()
  .and()
  
  // Sensitive category requires PII consent
  .routeCategory(EventCategory.sensitive)
  .toGroupNamed('gdpr_compliant')
  .requirePIIConsent()
  .and()
  
  // Essential events bypass consent
  .routeEssential()
  .toAll()
  .skipConsent()
  .and()
  
  // Everything else requires general consent
  .routeDefault()
  .toAll()
  .requireConsent()
```

### Complete GDPR Setup Example

```dart
// 1. Create your events with proper PII flags
class UserProfileEvent extends BaseEvent {
  final String email;
  final String name;
  
  @override
  bool get containsPII => true; // 🔒 Mark as containing PII
  
  @override
  EventCategory get category => EventCategory.sensitive;
}

class CrashReportEvent extends BaseEvent {
  @override
  bool get isEssential => true; // ✅ Always track (legitimate interest)
  
  @override
  bool get requiresConsent => false;
}

// 2. Set up privacy-compliant routing
void main() async {
  await FlexTrack.setupWithRouting([
    ConsoleTracker(),
    FirebaseTracker(), // GDPR compliant
    MixpanelTracker(token: 'token'), // Check their privacy policy!
    YourInternalAPI(), // Your compliant tracker
  ], (routing) {
    // Apply GDPR rules automatically
    GDPRDefaults.apply(routing, compliantTrackers: [
      'firebase',
      'your_internal_api'
    ]);
    
    return routing;
  });
}

// 3. Handle consent in your app
class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _generalConsent = false;
  bool _piiConsent = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Settings')),
      body: Column(
        children: [
          SwitchListTile(
            title: Text('General Analytics'),
            subtitle: Text('Help us improve the app'),
            value: _generalConsent,
            onChanged: (value) {
              setState(() => _generalConsent = value);
              _updateConsent();
            },
          ),
          SwitchListTile(
            title: Text('Personalization'),
            subtitle: Text('Personalized content and recommendations'),
            value: _piiConsent,
            onChanged: (value) {
              setState(() => _piiConsent = value);
              _updateConsent();
            },
          ),
        ],
      ),
    );
  }
  
  void _updateConsent() {
    FlexTrack.setConsent(
      general: _generalConsent,
      pii: _piiConsent,
    );
  }
}
```

---

## ⚡ Performance Optimization

FlexTrack includes several performance features to keep your app fast.

### Sampling (Reducing Event Volume)

Sampling reduces the number of events sent to prevent performance issues and reduce costs.

**Sampling Rates:**
- `noSampling()` = 100% of events (1.0)
- `lightSampling()` = 10% of events (0.1)  
- `mediumSampling()` = 50% of events (0.5)
- `heavySampling()` = 1% of events (0.01)
- `sample(0.25)` = 25% of events (custom)

**When to use each:**

```dart
routing
  // 💰 NEVER sample business events - too important
  .routeCategory(EventCategory.business)
  .toAll()
  .noSampling() // 100%
  .and()
  
  // 📄 PAGE VIEWS - Medium volume, light sampling
  .routeMatching(RegExp(r'page_view'))
  .toAll()
  .lightSampling() // 10%
  .and()
  
  // 🖱️ BUTTON CLICKS - High volume, medium sampling
  .routeMatching(RegExp(r'button_click'))
  .toAll()
  .mediumSampling() // 50%
  .and()
  
  // 📊 SCROLL EVENTS - Very high volume, heavy sampling
  .routeMatching(RegExp(r'scroll_.*'))
  .toAll()
  .heavySampling() // 1%
  .and()
  
  // 🎨 MOUSE MOVES - Extremely high volume, minimal sampling
  .routeMatching(RegExp(r'mouse_move'))
  .toAll()
  .sample(0.001) // 0.1%
```

### Batch Processing

Send multiple events at once for better performance:

```dart
// Instead of multiple individual calls:
await FlexTrack.track(Event1());
await FlexTrack.track(Event2());
await FlexTrack.track(Event3());

// Batch them together:
await FlexTrack.trackAll([
  Event1(),
  Event2(),
  Event3(),
]);
```

### Performance Presets

FlexTrack includes performance presets for common scenarios:

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  FirebaseTracker(),
], (routing) {
  // Apply performance optimizations automatically
  PerformanceDefaults.apply(routing);
  
  return routing;
});
```

What `PerformanceDefaults.apply()` does:

```dart
// Equivalent manual setup:
routing
  // High volume events get aggressive sampling
  .routeHighVolume()
  .toAll()
  .heavySampling() // 1%
  .and()
  
  // UI interactions are high volume
  .routeMatching(RegExp(r'(click|scroll|hover)_.*'))
  .toAll()
  .heavySampling()
  .and()
  
  // Critical events never sampled
  .routeMatching(RegExp(r'(purchase|error|crash)_.*'))
  .toAll()
  .noSampling()
  .and()
  
  // Default moderate sampling
  .routeDefault()
  .toAll()
  .mediumSampling() // 50%
```

### Platform-Specific Performance

```dart
// Mobile apps need more aggressive optimization
PerformanceDefaults.applyMobileOptimized(routing);

// Web apps have different patterns
PerformanceDefaults.applyWebOptimized(routing);

// Server/backend optimization
PerformanceDefaults.applyServerOptimized(routing);
```

---

## 🔍 Debugging and Development

### Console Tracker Features

The console tracker is your best friend during development:

```dart
ConsoleTracker(
  showProperties: true,    // Show all event properties
  showTimestamps: true,    // Show when events happened
  colorOutput: true,       // Colored output for better readability
  prefix: '🎯 MyApp',     // Custom prefix
)
```

**Console Output Examples:**

```
🎯 MyApp: [14:23:45.123] user_signup (business) [User: user123]
  Properties: {
    signup_method: email,
    accepted_marketing: true,
    timestamp: 1641234567890
  }
  Flags: ESSENTIAL

🎯 MyApp: [14:23:46.456] button_click (user)
  Properties: {
    button_id: header_logo,
    screen_name: home
  }
  Flags: HIGH_VOLUME
```

### Event Routing Debugger

See exactly how your events are being routed:

```dart
// Debug a specific event
final event = PurchaseEvent(productId: 'abc', amount: 99.99);
final debugInfo = FlexTrack.debugEvent(event);

print('Event: ${debugInfo.event.name}');
print('Target trackers: ${debugInfo.routingResult.targetTrackers}');
print('Applied rules: ${debugInfo.routingResult.appliedRules.length}');
print('Skipped rules: ${debugInfo.routingResult.skippedRules.length}');

// Print detailed information
for (final rule in debugInfo.routingResult.appliedRules) {
  print('✅ Applied: ${rule.description}');
}

for (final skipped in debugInfo.routingResult.skippedRules) {
  print('❌ Skipped: ${skipped.rule.description} - ${skipped.reason}');
}
```

**Example Debug Output:**
```
Event: purchase
Target trackers: [firebase, mixpanel, custom_api]
Applied rules: 1
Skipped rules: 2

✅ Applied: business events to all trackers (priority: 20)
❌ Skipped: high volume events to firebase only - Event not high volume
❌ Skipped: debug events to console - Event name doesn't match pattern
```

### System Debug Information

Get comprehensive information about FlexTrack's status:

```dart
// Print debug info to console
FlexTrack.printDebugInfo();

// Or get as data
final debugInfo = FlexTrack.getDebugInfo();
print('Is setup: ${debugInfo['isSetUp']}');
print('Is enabled: ${debugInfo['isEnabled']}');
print('Tracker count: ${debugInfo['eventProcessor']['trackerRegistry']['trackerCount']}');
```

**Example System Debug Output:**
```
=== FlexTrack Debug Info ===
Setup: true
Initialized: true
Enabled: true
Trackers: 4 registered, 4 enabled
Consent: General=true, PII=false
```

### Configuration Validation

Check for configuration issues:

```dart
final issues = FlexTrack.validate();

if (issues.isEmpty) {
  print('✅ Configuration is valid!');
} else {
  print('⚠️  Configuration issues found:');
  for (final issue in issues) {
    print('  • $issue');
  }
}
```

**Example Validation Output:**
```
⚠️  Configuration issues found:
  • No default routing rule specified
  • Tracker 'mixpanel' is not GDPR compliant but receives PII events
  • Sample rate 1.5 is invalid (must be between 0.0 and 1.0)
```

### Development vs Production

Set up different behavior for development and production:

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  FirebaseTracker(),
  if (!kDebugMode) MixpanelTracker(token: 'prod-token'),
  if (kDebugMode) MockTracker(),
], (routing) => routing
  
  // Debug events only in development
  .routeMatching(RegExp(r'debug_.*'))
  .to(['console'])
  .onlyInDebug()
  .and()
  
  // Production analytics only in production
  .routeCategory(EventCategory.business)
  .to(kDebugMode ? ['console'] : ['firebase', 'mixpanel'])
  .and()
  
  // Default routing
  .routeDefault()
  .to(['console', 'firebase'])
);
```

---

## 🧪 Testing Your Analytics

### Mock Tracker for Testing

FlexTrack includes a mock tracker perfect for unit tests:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  group('Analytics Tests', () {
    late MockTracker mockTracker;
    
    setUp(() async {
      // Setup FlexTrack with mock tracker
      mockTracker = await setupFlexTrackForTesting();
    });
    
    testWidgets('should track user signup', (tester) async {
      // Act
      await FlexTrack.track(UserSignupEvent(method: 'email'));
      
      // Assert
      expect(mockTracker.capturedEvents, hasLength(1));
      
      final event = mockTracker.capturedEvents.first;
      expect(event.name, equals('user_signup'));
      
      final properties = event.properties;
      expect(properties?['signup_method'], equals('email'));
    });
    
    testWidgets('should track purchase with correct amount', (tester) async {
      // Act
      await FlexTrack.track(PurchaseEvent(
        productId: 'test_product',
        amount: 99.99,
      ));
      
      // Assert
      expect(mockTracker.capturedEvents, hasLength(1));
      
      final event = mockTracker.capturedEvents.first;
      expect(event.name, equals('purchase'));
      expect(event.properties?['amount'], equals(99.99));
      expect(event.properties?['product_id'], equals('test_product'));
    });
    
    testWidgets('should not track when disabled', (tester) async {
      // Arrange
      FlexTrack.disable();
      
      // Act
      await FlexTrack.track(UserSignupEvent(method: 'email'));
      
      // Assert
      expect(mockTracker.capturedEvents, isEmpty);
      
      // Cleanup
      FlexTrack.enable();
    });
    
    testWidgets('should respect consent settings', (tester) async {
      // Arrange
      FlexTrack.setConsent(general: false, pii: false);
      
      // Act - event requires consent
      await FlexTrack.track(UserSignupEvent(method: 'email'));
      
      // Assert - should be blocked
      expect(mockTracker.capturedEvents, isEmpty);
      
      // Arrange - grant consent
      FlexTrack.setConsent(general: true);
      
      // Act
      await FlexTrack.track(UserSignupEvent(method: 'email'));
      
      // Assert - should be tracked
      expect(mockTracker.capturedEvents, hasLength(1));
    });
  });
}
```

### Testing Custom Trackers

```dart
void main() {
  group('Custom Tracker Tests', () {
    test('should initialize correctly', () async {
      final tracker = MyCustomTracker();
      
      expect(tracker.isEnabled, isTrue);
      expect(tracker.id, equals('my_custom'));
      
      await tracker.initialize();
      // Add your specific initialization tests
    });
    
    test('should track events correctly', () async {
      final tracker = MyCustomTracker();
      await tracker.initialize();
      
      final event = UserSignupEvent(method: 'email');
      await tracker.track(event);
      
      // Verify your tracker's behavior
      // This depends on your implementation
    });
  });
}
```

### Integration Testing

Test the complete flow in widget tests:

```dart
testWidgets('complete user signup flow', (tester) async {
  // Setup
  final mockTracker = await setupFlexTrackForTesting();
  
  // Build the signup screen
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Navigate to signup
  await tester.tap(find.text('Sign Up'));
  await tester.pumpAndSettle();
  
  // Fill in form
  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  
  // Submit form
  await tester.tap(find.text('Create Account'));
  await tester.pumpAndSettle();
  
  // Verify analytics were tracked
  expect(mockTracker.capturedEvents.length, greaterThan(0));
  
  final signupEvent = mockTracker.capturedEvents.firstWhere(
    (event) => event.name == 'user_signup',
  );
  
  expect(signupEvent, isNotNull);
  expect(signupEvent.getProperties()?['signup_method'], equals('email'));
});
```

---

## 🚨 Common Pitfalls and Solutions

### Problem 1: Events Not Appearing

**Symptoms:**
- No events in console
- Analytics dashboard shows no data

**Common Causes & Solutions:**

```dart
// ❌ WRONG: FlexTrack not initialized
void main() {
  runApp(MyApp()); // No FlexTrack setup!
}

// ✅ CORRECT: Initialize FlexTrack
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlexTrack.setup([ConsoleTracker()]);
  runApp(MyApp());
}

// ❌ WRONG: Tracking before initialization
void main() async {
  FlexTrack.track(AppStartEvent()); // Too early!
  await FlexTrack.setup([ConsoleTracker()]);
  runApp(MyApp());
}

// ✅ CORRECT: Track after initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlexTrack.setup([ConsoleTracker()]);
  await FlexTrack.track(AppStartEvent()); // Now it works!
  runApp(MyApp());
}
```

**Debug Steps:**
1. Check console for FlexTrack initialization messages
2. Verify trackers are enabled: `FlexTrack.printDebugInfo()`
3. Test with ConsoleTracker first
4. Check if FlexTrack is disabled: `FlexTrack.isEnabled`

### Problem 2: GDPR Consent Issues

**Symptoms:**
- Events blocked unexpectedly
- Some events work, others don't

**Common Causes & Solutions:**

```dart
// ❌ WRONG: Not setting consent
FlexTrack.track(UserProfileEvent()); // Blocked! Requires consent

// ✅ CORRECT: Set consent first
FlexTrack.setConsent(general: true, pii: true);
await FlexTrack.track(UserProfileEvent()); // Now works!

// ❌ WRONG: PII event without PII consent
class EmailEvent extends BaseEvent {
  @override
  bool get containsPII => true; // Requires PII consent
}

FlexTrack.setConsent(general: true); // No PII consent!
await FlexTrack.track(EmailEvent()); // Blocked!

// ✅ CORRECT: Grant PII consent
FlexTrack.setConsent(general: true, pii: true);
await FlexTrack.track(EmailEvent()); // Works!
```

**Debug Steps:**
1. Check consent status: `FlexTrack.getConsentStatus()`
2. Debug event routing: `FlexTrack.debugEvent(yourEvent)`
3. Look for "consent" in skipped rules
4. Mark essential events: `@override bool get isEssential => true;`

### Problem 3: Performance Issues

**Symptoms:**
- App feels slow
- High network usage
- Analytics costs too high

**Solutions:**

```dart
// ❌ WRONG: No sampling on high-volume events
class ScrollEvent extends BaseEvent {
  @override
  bool get isHighVolume => true; // But no sampling configured!
}

// ✅ CORRECT: Configure sampling
routing
  .routeHighVolume()
  .toAll()
  .heavySampling() // Only 1% of scroll events
  .and()

// ❌ WRONG: Individual tracking of many events
for (final item in items) {
  await FlexTrack.track(ItemViewEvent(itemId: item.id));
}

// ✅ CORRECT: Batch tracking
final events = items.map((item) => ItemViewEvent(itemId: item.id)).toList();
await FlexTrack.trackAll(events);
```

### Problem 4: Routing Not Working

**Symptoms:**
- Events going to wrong trackers
- Debug events appearing in production

**Common Issues:**

```dart
// ❌ WRONG: Rules in wrong order (priority issue)
routing
  .routeDefault().toAll().and() // Priority 0 - matches everything first!
  .routeCategory(EventCategory.business).to(['firebase']).and() // Never reached!

// ✅ CORRECT: Specific rules first, default last
routing
  .routeCategory(EventCategory.business).to(['firebase']).withPriority(10).and()
  .routeDefault().toAll().withPriority(0).and() // Default has lowest priority

// ❌ WRONG: Environment conditions backwards
routing
  .routeMatching(RegExp(r'debug_.*'))
  .toAll()
  .onlyInProduction() // Debug events in PRODUCTION?!
  .and()

// ✅ CORRECT: Debug events in debug mode
routing
  .routeMatching(RegExp(r'debug_.*'))
  .to(['console'])
  .onlyInDebug()
  .and()
```

### Problem 5: Custom Tracker Issues

**Common Implementation Mistakes:**

```dart
// ❌ WRONG: Not calling super.doInitialize()
class MyTracker extends BaseTrackerStrategy {
  @override
  Future<void> doInitialize() async {
    // Missing super call!
    await mySDK.initialize();
  }
}

// ✅ CORRECT: Always call parent methods when overriding
class MyTracker extends BaseTrackerStrategy {
  @override
  Future<void> doInitialize() async {
    await super.doInitialize(); // Don't forget this!
    await mySDK.initialize();
  }
}

// ❌ WRONG: Not handling errors
@override
Future<void> doTrack(BaseEvent event) async {
  await myAPI.send(event.name); // What if this fails?
}

// ✅ CORRECT: Handle errors gracefully
@override
Future<void> doTrack(BaseEvent event) async {
  try {
    await myAPI.send(event.name);
  } catch (e) {
    // Log error but don't crash the app
    print('Failed to track ${event.name}: $e');
    // FlexTrack will handle the TrackerException
  }
}
```

---

## 📈 Real-World Complete Examples

### Example 1: E-commerce Flutter App

Complete setup for a shopping app with multiple analytics needs:

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await setupECommerceAnalytics();
  
  runApp(ECommerceApp());
}

Future<void> setupECommerceAnalytics() async {
  await FlexTrack.setupWithRouting([
    // Development
    ConsoleTracker(showProperties: true, colorOutput: true),
    
    // Free analytics
    FirebaseTracker(),
    
    // Paid analytics for detailed insights
    MixpanelTracker(token: 'YOUR_MIXPANEL_TOKEN'),
    
    // Revenue analytics
    AmplitudeTracker(apiKey: 'YOUR_AMPLITUDE_KEY'),
    
    // Internal business intelligence
    CustomAPITracker(
      baseUrl: 'https://analytics.yourstore.com',
      apiKey: 'your-api-key',
    ),
  ], (routing) => routing
    
    // Define tracker groups
    .defineGroup('free_analytics', ['console', 'firebase'])
    .defineGroup('paid_analytics', ['mixpanel', 'amplitude'])
    .defineGroup('business_intel', ['custom_api'])
    .defineGroup('all_external', ['firebase', 'mixpanel', 'amplitude'])
    
    // 💰 REVENUE EVENTS - Highest priority, all trackers, never sample
    .routeMatching(RegExp(r'(purchase|refund|subscription)_.*'))
    .toAll()
    .noSampling()
    .withPriority(30)
    .withDescription('Critical revenue events')
    .and()
    
    // 🛒 SHOPPING FUNNEL - Detailed analytics only
    .routeMatching(RegExp(r'(product_view|add_to_cart|checkout_start|checkout_complete)'))
    .toGroupNamed('paid_analytics')
    .noSampling()
    .withPriority(25)
    .and()
    
    // 🔍 SEARCH & DISCOVERY - User behavior insights
    .routeMatching(RegExp(r'(search|filter|sort|category_view)'))
    .toGroupNamed('paid_analytics')
    .lightSampling()
    .withPriority(20)
    .and()
    
    // 📱 UI INTERACTIONS - High volume, heavy sampling
    .routeMatching(RegExp(r'(tap|swipe|scroll|zoom)'))
    .toGroupNamed('free_analytics')
    .heavySampling()
    .withPriority(10)
    .and()
    
    // 🐛 DEBUG EVENTS - Development only
    .routeMatching(RegExp(r'debug_.*'))
    .to(['console'])
    .onlyInDebug()
    .withPriority(35)
    .and()
    
    // 📊 BUSINESS METRICS - Internal tracking
    .routeWithProperty('business_metric')
    .toGroupNamed('business_intel')
    .requireConsent()
    .withPriority(15)
    .and()
    
    // 🏠 DEFAULT - All external analytics
    .routeDefault()
    .toGroupNamed('all_external')
    .mediumSampling()
    .withPriority(0)
  );
  
  // Set up initial consent (you'd get this from user preferences)
  FlexTrack.setConsent(general: true, pii: false);
}

// events/ecommerce_events.dart
class ProductViewEvent extends BaseEvent {
  final String productId;
  final String productName;
  final double price;
  final String category;
  
  ProductViewEvent({
    required this.productId,
    required this.productName,
    required this.price,
    required this.category,
  });
  
  @override
  String get name => 'product_view';
  
  @override
  Map<String, Object> get properties => {
    'product_id': productId,
    'product_name': productName,
    'price': price,
    'category': category,
  };
  
  @override
  EventCategory get category => EventCategory.user;
}

class PurchaseCompleteEvent extends BaseEvent {
  final String orderId;
  final double totalAmount;
  final String currency;
  final List<Map<String, dynamic>> items;
  final String paymentMethod;
  
  PurchaseCompleteEvent({
    required this.orderId,
    required this.totalAmount,
    this.currency = 'USD',
    required this.items,
    required this.paymentMethod,
  });
  
  @override
  String get name => 'purchase_complete';
  
  @override
  Map<String, Object> get properties => {
    'order_id': orderId,
    'total_amount': totalAmount,
    'currency': currency,
    'item_count': items.length,
    'payment_method': paymentMethod,
    'items': items,
  };
  
  @override
  EventCategory get category => EventCategory.business;
  
  @override
  bool get isEssential => true; // Never sample revenue events
}

// Usage in your app
class ProductScreen extends StatelessWidget {
  final Product product;
  
  const ProductScreen({required this.product});
  
  @override
  void initState() {
    super.initState();
    
    // Track product view
    FlexTrack.track(ProductViewEvent(
      productId: product.id,
      productName: product.name,
      price: product.price,
      category: product.category,
    ));
  }
  
  void _onAddToCart() {
    // Track add to cart
    FlexTrack.track(AddToCartEvent(
      productId: product.id,
      productName: product.name,
      price: product.price,
    ));
    
    // Your add to cart logic
    CartService.addItem(product);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Your UI here
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddToCart,
        child: Icon(Icons.add_shopping_cart),
      ),
    );
  }
}
```

### Example 2: SaaS App with Strict Privacy

Setup for a B2B SaaS app with GDPR requirements:

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await setupSaaSAnalytics();
  
  runApp(SaaSApp());
}

Future<void> setupSaaSAnalytics() async {
  await FlexTrack.setupWithRouting([
    ConsoleTracker(),
    FirebaseTracker(), // GDPR compliant
    PostHogTracker(), // Privacy-focused analytics
    InternalAPITracker(), // Your compliant tracker
  ], (routing) {
    // Apply strict GDPR compliance
    GDPRDefaults.applyStrict(routing, compliantTrackers: [
      'firebase',
      'posthog',
      'internal_api'
    ]);
    
    return routing
      // 🔒 SENSITIVE BUSINESS DATA - Internal only
      .routeWithProperty('revenue')
      .to(['internal_api'])
      .skipConsent() // Legitimate business interest
      .withPriority(25)
      .and()
      
      // 👤 USER BEHAVIOR - Privacy-safe analytics
      .routeCategory(EventCategory.user)
      .to(['posthog'])
      .requireConsent()
      .withPriority(15)
      .and()
      
      // ⚡ PERFORMANCE MONITORING - System health
      .routeCategory(EventCategory.technical)
      .to(['internal_api'])
      .skipConsent()
      .lightSampling()
      .withPriority(10)
      .and();
  });
}

// Custom privacy-focused events
class FeatureUsageEvent extends BaseEvent {
  final String featureName;
  final int timeSpentSeconds;
  final bool isFirstTime;
  
  FeatureUsageEvent({
    required this.featureName,
    required this.timeSpentSeconds,
    this.isFirstTime = false,
  });
  
  @override
  String get name => 'feature_usage';
  
  @override
  Map<String, Object> get properties => {
    'feature_name': featureName,
    'time_spent_seconds': timeSpentSeconds,
    'is_first_time': isFirstTime,
  };
  
  @override
  EventCategory get category => EventCategory.user;
  
  @override
  bool get containsPII => false; // No personal data
}

class SubscriptionChangeEvent extends BaseEvent {
  final String planFrom;
  final String planTo;
  final double priceChange;
  final String changeReason;
  
  SubscriptionChangeEvent({
    required this.planFrom,
    required this.planTo,
    required this.priceChange,
    required this.changeReason,
  });
  
  @override
  String get name => 'subscription_change';
  
  @override
  Map<String, Object> get properties => {
    'plan_from': planFrom,
    'plan_to': planTo,
    'price_change': priceChange,
    'change_reason': changeReason,
    'business_metric': true, // Will route to internal API
  };
  
  @override
  EventCategory get category => EventCategory.business;
}
```

---

## 🎓 Migration Guide

### From Firebase Analytics Only

**Before:**
```dart
// Scattered throughout your app
FirebaseAnalytics.instance.logEvent(
  name: 'user_signup',
  parameters: {'method': 'email'},
);

FirebaseAnalytics.instance.logEvent(
  name: 'purchase',
  parameters: {
    'transaction_id': orderId,
    'value': amount,
    'currency': 'USD',
  },
);
```

**After (Step by Step):**

1. **Add FlexTrack and keep existing code:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add FlexTrack alongside existing Firebase
  await FlexTrack.setup([
    ConsoleTracker(), // For debugging
    FirebaseTracker(), // Wrap your existing Firebase
  ]);
  
  runApp(MyApp());
}
```

2. **Create events for new features:**
```dart
// For new features, use FlexTrack events
await FlexTrack.track(UserSignupEvent(method: 'email'));

// Keep existing Firebase calls as-is
FirebaseAnalytics.instance.logEvent(name: 'legacy_event');
```

3. **Gradually migrate existing events:**
```dart
// Replace this:
FirebaseAnalytics.instance.logEvent(
  name: 'purchase',
  parameters: {'value': amount},
);

// With this:
await FlexTrack.track(PurchaseEvent(
  orderId: orderId,
  amount: amount,
  currency: 'USD',
));
```

### From Multiple Manual Analytics

**Before:**
```dart
// Nightmare code scattered everywhere
void trackPurchase(String orderId, double amount) {
  // Firebase
  FirebaseAnalytics.instance.logEvent(
    name: 'purchase',
    parameters: {'value': amount},
  );
  
  // Mixpanel
  if (userConsentedToTracking) {
    Mixpanel.getInstance().track('Purchase', {
      'Amount': amount,
      'Order ID': orderId,
    });
  }
  
  // Internal API
  if (!kDebugMode) {
    customAPI.track('purchase', {
      'order_id': orderId,
      'amount': amount,
    });
  }
}
```

**After:**
```dart
// One line replaces all of that
await FlexTrack.track(PurchaseEvent(
  orderId: orderId,
  amount: amount,
));

// FlexTrack handles:
// ✅ Routing to all trackers
// ✅ Consent checking
// ✅ Environment detection
// ✅ Format conversion
// ✅ Error handling
```

**Migration Steps:**
1. Set up FlexTrack with all your existing trackers
2. Create FlexTrack events for your existing tracking calls
3. Replace manual tracking calls one by one
4. Remove duplicate analytics code
5. Enjoy cleaner, more maintainable code!

---

## 📋 Quick Reference

### Essential Event Properties
```dart
class MyEvent extends BaseEvent {
  @override
  String get name => 'my_event'; // Required
  
  @override
  Map<String, Object> get properties => {}; // Required
  
  @override
  EventCategory? get category => EventCategory.user; // Recommended
  
  @override
  bool get containsPII => false; // Important for GDPR
  
  @override
  bool get isEssential => false; // Bypasses consent/sampling
  
  @override
  bool get isHighVolume => false; // Triggers sampling
  
  @override
  bool get requiresConsent => true; // GDPR compliance
}
```

### Routing Syntax Cheat Sheet
```dart
routing
  // By event type
  .route<MyEvent>().toAll().and()
  
  // By name pattern
  .routeNamed('purchase').toAll().and()
  .routeMatching(RegExp(r'debug_.*')).to(['console']).and()
  
  // By category
  .routeCategory(EventCategory.business).toAll().and()
  
  // By properties
  .routeWithProperty('internal_metric').to(['internal']).and()
  .routePII().to(['gdpr_compliant']).and()
  
  // By flags
  .routeEssential().toAll().and()
  .routeHighVolume().toAll().heavySampling().and()
  
  // Environment
  .routeMatching(RegExp(r'debug_.*')).onlyInDebug().and()
  .routeCategory(EventCategory.business).onlyInProduction().and()
  
  // Consent requirements
  .routeCategory(EventCategory.user).requireConsent().and()
  .routePII().requirePIIConsent().and()
  .routeEssential().skipConsent().and()
  
  // Sampling
  .routeHighVolume().heavySampling().and() // 1%
  .routeCategory(EventCategory.user).lightSampling().and() // 10%
  .routeDefault().mediumSampling().and() // 50%
  
  // Priority (higher = more important)
  .routeEssential().withPriority(30).and()
  .routeCategory(EventCategory.business).withPriority(20).and()
  .routeDefault().withPriority(0).and()
```

### Sampling Rates Quick Reference
```dart
// Sampling methods
.noSampling()      // 100% - All events
.lightSampling()   // 10% - Low volume reduction
.mediumSampling()  // 50% - Moderate reduction  
.heavySampling()   // 1% - Aggressive reduction
.sample(0.25)      // 25% - Custom rate

// When to use each:
EventCategory.business → noSampling()     // Never miss revenue
EventCategory.user → lightSampling()      // Some user behavior
UI interactions → heavySampling()         // Too many clicks
Default events → mediumSampling()         // Balanced approach
```

### Consent Management Quick Reference
```dart
// Set consent
FlexTrack.setConsent(general: true, pii: false);

// Check consent
final consent = FlexTrack.getConsentStatus();
bool hasGeneral = consent['general'] ?? false;
bool hasPII = consent['pii'] ?? false;

// Event consent requirements
@override bool get requiresConsent => true;  // Needs general consent
@override bool get containsPII => true;      // Needs PII consent  
@override bool get isEssential => true;      // Bypasses consent
```

### Debugging Commands
```dart
// System info
FlexTrack.printDebugInfo();
final info = FlexTrack.getDebugInfo();

// Event routing
final debug = FlexTrack.debugEvent(myEvent);
print(debug.routingResult.targetTrackers);

// Configuration validation
final issues = FlexTrack.validate();
issues.forEach(print);

// Tracker status
print('Is enabled: ${FlexTrack.isEnabled}');
print('Trackers: ${FlexTrack.getTrackerIds()}');
```

---

## 🚀 Advanced Use Cases

### Multi-Tenant SaaS Application

For apps serving multiple organizations with different analytics needs:

```dart
class TenantAwareTracker extends BaseTrackerStrategy {
  final Map<String, String> _tenantConfigs;
  
  TenantAwareTracker(this._tenantConfigs) : super(
    id: 'tenant_aware',
    name: 'Tenant-Aware Analytics',
  );
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    final tenantId = event.properties?['tenant_id'] as String?;
    if (tenantId == null) return;
    
    final config = _tenantConfigs[tenantId];
    if (config == null) return;
    
    // Route to tenant-specific analytics endpoint
    await _sendToTenantEndpoint(config, event);
  }
}

// Setup with tenant-aware routing
await FlexTrack.setupWithRouting([
  TenantAwareTracker({
    'tenant_1': 'https://analytics.tenant1.com',
    'tenant_2': 'https://analytics.tenant2.com',
  }),
], (routing) => routing
  .routeWithProperty('tenant_id')
  .to(['tenant_aware'])
  .and()
  
  .routeDefault()
  .to(['console'])
);

// Usage
await FlexTrack.track(TenantEvent(
  tenantId: 'tenant_1',
  eventName: 'feature_used',
));
```

### A/B Test Integration

Track experiment participation and outcomes:

```dart
class ExperimentEvent extends BaseEvent {
  final String experimentId;
  final String variant;
  final String outcome;
  
  ExperimentEvent({
    required this.experimentId,
    required this.variant,
    required this.outcome,
  });
  
  @override
  String get name => 'experiment_outcome';
  
  @override
  Map<String, Object> get properties => {
    'experiment_id': experimentId,
    'variant': variant,
    'outcome': outcome,
  };
  
  @override
  EventCategory get category => EventCategory.business;
  
  @override
  bool get isEssential => true; // Never sample A/B test data
}

// Routing for experiments
routing
  .routeMatching(RegExp(r'experiment_.*'))
  .toAll()
  .noSampling() // Critical for statistical significance
  .withPriority(25)
  .and()
```

### Real-Time Dashboard Integration

For apps that need real-time analytics dashboards:

```dart
class WebSocketTracker extends BaseTrackerStrategy {
  WebSocketChannel? _channel;
  
  WebSocketTracker() : super(
    id: 'websocket',
    name: 'Real-Time Dashboard',
  );
  
  @override
  bool get supportsRealTime => true;
  
  @override
  Future<void> doInitialize() async {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://dashboard.yourapp.com/analytics'),
    );
  }
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    if (_channel == null) return;
    
    final payload = {
      'type': 'analytics_event',
      'event': event.name,
      'properties': event.properties,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _channel!.sink.add(jsonEncode(payload));
  }
}

// Setup for real-time events
routing
  .routeCategory(EventCategory.business)
  .to(['websocket', 'firebase']) // Real-time + persistent
  .and()
```

---

## 🔧 Custom Tracker Templates

### REST API Tracker Template

```dart
class RESTAPITracker extends BaseTrackerStrategy {
  final String baseUrl;
  final String? apiKey;
  final http.Client _client;
  final List<Map<String, dynamic>> _eventBuffer = [];
  
  RESTAPITracker({
    required this.baseUrl,
    this.apiKey,
  }) : _client = http.Client(),
       super(
         id: 'rest_api',
         name: 'REST API Tracker',
       );
  
  @override
  bool get isGDPRCompliant => true; // Assuming your API is compliant
  
  @override
  bool supportsBatchTracking() => true;
  
  @override
  int get maxBatchSize => 100;
  
  @override
  Future<void> doInitialize() async {
    // Test API connection
    final response = await _client.get(
      Uri.parse('$baseUrl/health'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API health check failed: ${response.statusCode}');
    }
  }
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    final eventData = {
      'name': event.name,
      'properties': event.properties,
      'timestamp': event.timestamp.toIso8601String(),
      'category': event.category?.name,
    };
    
    _eventBuffer.add(eventData);
    
    // Auto-flush when buffer is full
    if (_eventBuffer.length >= maxBatchSize) {
      await doFlush();
    }
  }
  
  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    for (final event in events) {
      await doTrack(event);
    }
  }
  
  @override
  Future<void> doFlush() async {
    if (_eventBuffer.isEmpty) return;
    
    final eventsToSend = List<Map<String, dynamic>>.from(_eventBuffer);
    _eventBuffer.clear();
    
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/events/batch'),
        headers: _getHeaders(),
        body: jsonEncode({
          'events': eventsToSend,
          'batch_timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Re-add events on failure for retry
      _eventBuffer.addAll(eventsToSend);
      rethrow;
    }
  }
  
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': 'FlexTrack-RESTTracker/1.0',
    };
    
    if (apiKey != null) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    
    return headers;
  }
  
  @override
  Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
    await _client.post(
      Uri.parse('$baseUrl/users/properties'),
      headers: _getHeaders(),
      body: jsonEncode({
        'properties': properties,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
  
  @override
  Future<void> doIdentifyUser(String userId, [Map<String, dynamic>? properties]) async {
    await _client.post(
      Uri.parse('$baseUrl/users/identify'),
      headers: _getHeaders(),
      body: jsonEncode({
        'user_id': userId,
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}
```

### Database Tracker Template

For storing analytics in your local database:

```dart
class DatabaseTracker extends BaseTrackerStrategy {
  late Database _database;
  
  DatabaseTracker() : super(
    id: 'database',
    name: 'Local Database Tracker',
  );
  
  @override
  Future<void> doInitialize() async {
    _database = await openDatabase(
      'analytics.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            properties TEXT,
            category TEXT,
            timestamp TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    await _database.insert('events', {
      'name': event.name,
      'properties': jsonEncode(event.properties),
      'category': event.category?.name,
      'timestamp': event.timestamp.toIso8601String(),
    });
  }
  
  // Method to retrieve stored events
  Future<List<Map<String, dynamic>>> getStoredEvents({
    int? limit,
    String? category,
    DateTime? since,
  }) async {
    String query = 'SELECT * FROM events';
    List<dynamic> args = [];
    
    List<String> conditions = [];
    
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }
    
    if (since != null) {
      conditions.add('timestamp >= ?');
      args.add(since.toIso8601String());
    }
    
    if (conditions.isNotEmpty) {
      query += ' WHERE ' + conditions.join(' AND ');
    }
    
    query += ' ORDER BY created_at DESC';
    
    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }
    
    return await _database.rawQuery(query, args);
  }
}
```

---

## 📊 Performance Monitoring

### Track FlexTrack's Own Performance

Monitor how FlexTrack affects your app:

```dart
class PerformanceMonitoringTracker extends BaseTrackerStrategy {
  final Stopwatch _processingTime = Stopwatch();
  int _eventsProcessed = 0;
  int _eventsDropped = 0;
  
  PerformanceMonitoringTracker() : super(
    id: 'performance_monitor',
    name: 'Performance Monitor',
  );
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    _processingTime.start();
    
    try {
      _eventsProcessed++;
      
      // Your actual tracking logic here
      await _actualTracking(event);
      
    } catch (e) {
      _eventsDropped++;
      rethrow;
    } finally {
      _processingTime.stop();
    }
  }
  
  Map<String, dynamic> getPerformanceStats() {
    return {
      'events_processed': _eventsProcessed,
      'events_dropped': _eventsDropped,
      'total_processing_time_ms': _processingTime.elapsedMilliseconds,
      'average_processing_time_ms': _eventsProcessed > 0 
          ? _processingTime.elapsedMilliseconds / _eventsProcessed 
          : 0,
      'success_rate': _eventsProcessed > 0 
          ? (_eventsProcessed - _eventsDropped) / _eventsProcessed 
          : 0,
    };
  }
}
```

### Memory Usage Monitoring

```dart
class MemoryAwareTracker extends BaseTrackerStrategy {
  final List<BaseEvent> _eventBuffer = [];
  static const int MAX_BUFFER_SIZE = 1000;
  static const int MEMORY_CHECK_INTERVAL = 100;
  int _eventCount = 0;
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    _eventCount++;
    
    // Check memory usage periodically
    if (_eventCount % MEMORY_CHECK_INTERVAL == 0) {
      await _checkMemoryUsage();
    }
    
    _eventBuffer.add(event);
    
    // Prevent memory leaks
    if (_eventBuffer.length > MAX_BUFFER_SIZE) {
      _eventBuffer.removeRange(0, _eventBuffer.length ~/ 2);
    }
  }
  
  Future<void> _checkMemoryUsage() async {
    // In a real implementation, you'd check actual memory usage
    // For example, using dart:developer or platform-specific methods
    
    if (_eventBuffer.length > MAX_BUFFER_SIZE * 0.8) {
      print('⚠️  FlexTrack buffer approaching limit: ${_eventBuffer.length}');
      await doFlush();
    }
  }
}
```

---

## 🧪 Advanced Testing Strategies

### Integration Testing with Real Analytics

```dart
// Test with real analytics services in a controlled way
testWidgets('analytics integration test', (tester) async {
  // Use test tokens/keys that don't affect production data
  await FlexTrack.setup([
    FirebaseTracker(), // Uses test Firebase project
    TestMixpanelTracker(token: 'test_token'),
  ]);
  
  // Build your app widget
  await tester.pumpWidget(MyApp());
  
  // Perform user actions
  await tester.tap(find.text('Sign Up'));
  await tester.enterText(find.byType(TextField), 'test@example.com');
  await tester.tap(find.text('Submit'));
  
  // Wait for analytics to be sent
  await tester.pumpAndSettle();
  
  // Verify with your test analytics dashboard
  // (This would be specific to your testing setup)
});
```

### Property-Based Testing

```dart
import 'package:test/test.dart';

void main() {
  group('FlexTrack Property Tests', () {
    test('all events should have valid names', () {
      final testEvents = [
        UserSignupEvent(method: 'email'),
        PurchaseEvent(productId: 'abc', amount: 99.99),
        ButtonClickEvent(buttonId: 'test', screenName: 'home'),
      ];
      
      for (final event in testEvents) {
        expect(event.name, isNotEmpty);
        expect(event.name, matches(RegExp(r'^[a-z_]+)));
        expect(event.name.length, lessThan(50));
      }
    });
    
    test('all events should have serializable properties', () {
      final testEvents = [
        UserSignupEvent(method: 'email'),
        PurchaseEvent(productId: 'abc', amount: 99.99),
      ];
      
      for (final event in testEvents) {
        final properties = event.properties;
        if (properties != null) {
          // Should be JSON serializable
          expect(() => jsonEncode(properties), returnsNormally);
          
          // All values should be basic types
          for (final value in properties.values) {
            expect(
              value is String || value is num || value is bool || value is List || value is Map,
              isTrue,
              reason: 'Property value $value is not serializable',
            );
          }
        }
      }
    });
  });
}
```

### Load Testing

```dart
testWidgets('high load analytics test', (tester) async {
  final mockTracker = await setupFlexTrackForTesting();
  
  // Simulate high load
  const eventCount = 10000;
  final stopwatch = Stopwatch()..start();
  
  final futures = <Future>[];
  for (int i = 0; i < eventCount; i++) {
    futures.add(FlexTrack.track(
      ButtonClickEvent(buttonId: 'test_$i', screenName: 'test')
    ));
  }
  
  await Future.wait(futures);
  stopwatch.stop();
  
  // Verify performance
  expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Less than 5 seconds
  expect(mockTracker.capturedEvents.length, equals(eventCount));
  
  print('Processed $eventCount events in ${stopwatch.elapsedMilliseconds}ms');
  print('Average: ${stopwatch.elapsedMilliseconds / eventCount}ms per event');
});
```

---

## 🔒 Security Best Practices

### Secure API Key Management

```dart
class SecureAPITracker extends BaseTrackerStrategy {
  final String _encryptedApiKey;
  
  SecureAPITracker({required String encryptedApiKey})
      : _encryptedApiKey = encryptedApiKey,
        super(id: 'secure_api', name: 'Secure API Tracker');
  
  @override
  Future<void> doInitialize() async {
    // Decrypt API key only when needed
    final apiKey = await _decryptApiKey(_encryptedApiKey);
    
    // Use the key for initialization
    await _initializeWithKey(apiKey);
    
    // Clear the key from memory
    apiKey.replaceAll(RegExp(r'.'), '0'); // Basic key clearing
  }
  
  Future<String> _decryptApiKey(String encrypted) async {
    // Implement your key decryption logic
    // Consider using flutter_secure_storage or similar
    return encrypted; // Placeholder
  }
}
```

### Data Sanitization

```dart
class SanitizingTracker extends BaseTrackerStrategy {
  final Set<String> _piiFields = {
    'email', 'phone', 'ssn', 'credit_card', 'password',
    'first_name', 'last_name', 'address', 'ip_address'
  };
  
  @override
  Future<void> doTrack(BaseEvent event) async {
    final sanitizedProperties = _sanitizeProperties(event.properties);
    
    // Create sanitized event
    final sanitizedEvent = SanitizedEvent(
      originalEvent: event,
      sanitizedProperties: sanitizedProperties,
    );
    
    await _actualTracking(sanitizedEvent);
  }
  
  Map<String, Object>? _sanitizeProperties(Map<String, Object>? properties) {
    if (properties == null) return null;
    
    final sanitized = <String, Object>{};
    
    properties.forEach((key, value) {
      if (_piiFields.contains(key.toLowerCase())) {
        // Replace PII with hashed or masked value
        sanitized[key] = _hashValue(value.toString());
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }
  
  String _hashValue(String value) {
    // Use a proper hashing algorithm
    return 'hashed_${value.hashCode.abs()}';
  }
}
```

---

## 📈 Business Intelligence Integration

### Revenue Attribution Tracking

```dart
class RevenueAttributionEvent extends BaseEvent {
  final double revenue;
  final String currency;
  final String source; // 'organic', 'paid_search', 'social', etc.
  final String medium; // 'cpc', 'email', 'referral', etc.
  final String campaign;
  final String? couponCode;
  
  RevenueAttributionEvent({
    required this.revenue,
    this.currency = 'USD',
    required this.source,
    required this.medium,
    required this.campaign,
    this.couponCode,
  });
  
  @override
  String get name => 'revenue_attribution';
  
  @override
  Map<String, Object> get properties => {
    'revenue': revenue,
    'currency': currency,
    'source': source,
    'medium': medium,
    'campaign': campaign,
    if (couponCode != null) 'coupon_code': couponCode!,
    'attribution_timestamp': DateTime.now().toIso8601String(),
  };
  
  @override
  EventCategory get category => EventCategory.business;
  
  @override
  bool get isEssential => true;
}

// Usage in your app
class PurchaseService {
  static Future<void> completePurchase({
    required double amount,
    required String orderId,
    String? couponCode,
  }) async {
    // Your purchase logic
    await _processPurchase(orderId, amount);
    
    // Track revenue with attribution
    final attribution = await _getAttributionData();
    
    await FlexTrack.track(RevenueAttributionEvent(
      revenue: amount,
      source: attribution.source,
      medium: attribution.medium,
      campaign: attribution.campaign,
      couponCode: couponCode,
    ));
  }
}
```

### Customer Lifetime Value Tracking

```dart
class CLVUpdateEvent extends BaseEvent {
  final String userId;
  final double currentCLV;
  final double previousCLV;
  final String trigger; // 'purchase', 'subscription', 'churn'
  
  CLVUpdateEvent({
    required this.userId,
    required this.currentCLV,
    required this.previousCLV,
    required this.trigger,
  });
  
  @override
  String get name => 'clv_update';
  
  @override
  Map<String, Object> get properties => {
    'user_id': userId,
    'current_clv': currentCLV,
    'previous_clv': previousCLV,
    'clv_change': currentCLV - previousCLV,
    'trigger': trigger,
  };
  
  @override
  EventCategory get category => EventCategory.business;
  
  @override
  bool get containsPII => true; // Contains user ID
}
```

---

## 🌟 Final Tips and Best Practices

### 1. Start Simple, Scale Gradually

```dart
// ✅ GOOD: Start with basic setup
await FlexTrack.setup([
  ConsoleTracker(),
  FirebaseTracker(),
]);

// ❌ AVOID: Complex setup from day one
await FlexTrack.setupWithRouting([...], (routing) => routing
  .defineGroup(...)
  .routeCategory(...)
  .routeMatching(...)
  // 50 more lines of complex routing
);
```

### 2. Always Use Console Tracker in Development

```dart
// ✅ ALWAYS include console tracker for debugging
await FlexTrack.setup([
  ConsoleTracker(), // Essential for development
  YourProductionTracker(),
]);
```

### 3. Test Your Events Early

```dart
void main() async {
  await FlexTrack.setup([ConsoleTracker()]);
  
  // Test your events immediately after setup
  await FlexTrack.track(TestEvent());
  
  runApp(MyApp());
}
```

### 4. Use Meaningful Event Names

```dart
// ✅ GOOD: Clear, descriptive names
class UserCompletedPurchaseEvent extends BaseEvent {
  @override
  String get name => 'user_completed_purchase';
}

// ❌ BAD: Vague or abbreviated names
class UCPEvent extends BaseEvent {
  @override
  String get name => 'ucp';
}
```

### 5. Group Related Events

```dart
// ✅ GOOD: Consistent naming patterns
class UserRegistrationStartedEvent extends BaseEvent {
  @override
  String get name => 'user_registration_started';
}

class UserRegistrationCompletedEvent extends BaseEvent {
  @override
  String get name => 'user_registration_completed';
}

class UserRegistrationAbandonedEvent extends BaseEvent {
  @override
  String get name => 'user_registration_abandoned';
}
```

### 6. Document Your Events

```dart
/// Tracks when a user completes a purchase
/// 
/// This event is critical for revenue tracking and should never be sampled.
/// It's sent to all analytics trackers and includes detailed product information.
/// 
/// Properties:
/// - product_id: Unique identifier for the purchased product
/// - amount: Purchase amount in the specified currency
/// - currency: 3-letter currency code (e.g., 'USD', 'EUR')
/// - payment_method: How the user paid ('credit_card', 'paypal', etc.)
class PurchaseCompletedEvent extends BaseEvent {
  final String productId;
  final double amount;
  final String currency;
  final String paymentMethod;
  
  // ... implementation
}
```

### 7. Monitor Your Analytics

```dart
// Set up monitoring to catch issues early
class AnalyticsHealthMonitor {
  static Timer? _healthCheckTimer;
  
  static void startMonitoring() {
    _healthCheckTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _checkAnalyticsHealth();
    });
  }
  
  static void _checkAnalyticsHealth() {
    final debugInfo = FlexTrack.getDebugInfo();
    final issues = FlexTrack.validate();
    
    if (issues.isNotEmpty) {
      print('⚠️  Analytics issues detected: $issues');
      // Send alert to your monitoring system
    }
    
    if (!debugInfo['isEnabled']) {
      print('🚨 Analytics is disabled!');
      // Send critical alert
    }
  }
}
```

---

## 🎉 Congratulations!

You've now learned everything you need to know about FlexTrack! You can:

✅ **Set up FlexTrack** with multiple analytics services  
✅ **Create custom events** that fit your app's needs  
✅ **Configure intelligent routing** based on your requirements  
✅ **Handle GDPR compliance** automatically  
✅ **Optimize performance** with sampling and batching  
✅ **Debug issues** when they arise  
✅ **Test your analytics** comprehensively  
✅ **Scale your setup** as your app grows  

## 🆘 Getting Help

- **Issues**: [GitHub Issues](https://github.com/your-repo/flex_track/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/flex_track/discussions)  
- **Documentation**: [Full Documentation](https://flex-track.dev/docs)
- **Examples**: [Example Repository](https://github.com/your-repo/flex_track_examples)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Happy Tracking! 🎯**