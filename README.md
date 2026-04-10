# flex_track

Analytics routing for Flutter. Register trackers you implement, send typed events from one call site, and optionally route by category, consent, sampling, or environment.

The package ships **no vendor SDKs**. You extend [`BaseTrackerStrategy`](lib/src/strategies/base_tracker_strategy.dart) — no hidden transitive dependencies, no SDK version conflicts.

---

## Quick start

Four steps. `MyFirebaseTracker` is **your** class — only [`ConsoleTracker`](lib/src/strategies/built_in/console_tracker.dart) and [`MockTracker`](lib/src/strategies/built_in/mock_tracker.dart) ship with the package.

```dart
// 1. pubspec.yaml
//    dependencies:
//      flex_track: ^1.0.0
//      firebase_core: ...        # only if you're adding Firebase
//      firebase_analytics: ...   # only if you're adding Firebase

import 'package:flex_track/flex_track.dart';
import 'package:flutter/widgets.dart';

// 2. Implement your tracker (not part of the package).
class MyFirebaseTracker extends BaseTrackerStrategy {
  MyFirebaseTracker() : super(id: 'firebase', name: 'Firebase');

  @override
  Future<void> doInitialize() async {
    // await Firebase.initializeApp();
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // await FirebaseAnalytics.instance.logEvent(name: event.getName(),
    //   parameters: event.getProperties()?.cast<String, Object>());
  }
}

// 2b. Define an event.
class AppOpenedEvent extends BaseEvent {
  @override String getName() => 'app_opened';
  @override Map<String, Object>? getProperties() => null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Set up — pass every tracker you implemented.
  await FlexTrack.setup([ConsoleTracker(), MyFirebaseTracker()]);

  // 4. Track.
  await FlexTrack.track(AppOpenedEvent());

  runApp(const MyApp());
}
```

No Firebase yet? Use `await FlexTrack.setup([ConsoleTracker()])` — events appear in the debug console.

---

## Table of contents

- [What this package does (and doesn't)](#what-this-package-does-and-doesnt)
- [Bring your own tracker](#bring-your-own-tracker)
  - [Required methods](#required-methods)
  - [Optional overrides](#optional-overrides)
  - [Tracker id convention](#tracker-id-convention)
  - [Example: Mixpanel-shaped tracker](#example-mixpanel-shaped-tracker)
  - [Example: custom backend tracker](#example-custom-backend-tracker)
- [Events](#events)
  - [BaseEvent fields](#baseevent-fields)
  - [EventCategory values](#eventcategory-values)
- [Setup](#setup)
  - [Simple setup](#simple-setup)
  - [Setup with routing](#setup-with-routing)
  - [Convenience setup functions](#convenience-setup-functions)
- [Routing DSL](#routing-dsl)
  - [Matchers](#matchers)
  - [Targets](#targets)
  - [Modifiers](#modifiers)
  - [Rule priority](#rule-priority)
  - [Tracker groups](#tracker-groups)
- [Consent](#consent)
- [Sampling](#sampling)
- [Preset configurations](#preset-configurations)
  - [SmartDefaults](#smartdefaults)
  - [GDPRDefaults](#gdprdefaults)
  - [PerformanceDefaults](#performancedefaults)
- [Widget wrappers](#widget-wrappers)
  - [FlexClickTrack](#flexclicktrack)
  - [FlexImpressionTrack](#fleximpressiontrack)
  - [FlexMountTrack](#flexmounttrack)
  - [FlexTrackRouteViewMixin](#flextrackrouteviewmixin)
- [User identification](#user-identification)
- [Tracker lifecycle](#tracker-lifecycle)
- [Testing](#testing)
- [Debugging](#debugging)
- [Reference — event flags](#reference--event-flags)
- [Reference — routing DSL](#reference--routing-dsl)
- [Reference — preset index](#reference--preset-index)
- [Contributing / license](#contributing--license)

---

## What this package does (and doesn't)

**Does:**
- Provides a single `FlexTrack.track(event)` call site for all analytics
- Routes each event to one or more trackers based on configurable rules
- Handles consent gating, sampling, and environment filtering per rule
- Includes Flutter widget wrappers for taps, impressions, mount, and route transitions
- Ships `ConsoleTracker` (dev/debug), `MockTracker` (tests), and `NoOpTracker` (disable without removing)

**Doesn't:**
- Bundle Firebase, Mixpanel, Amplitude, or any other analytics SDK
- Call any external service on its own
- Manage app-level navigation or state

**Why no built-in Firebase tracker?** The package owner cannot take on your Firebase project config, your SDK version requirements, or your initialisation sequencing. You write a thin adapter once; it stays in your repo, under your control.

The [`example/lib/trackers/`](example/lib/trackers/) directory contains working reference implementations for Firebase, Mixpanel, Amplitude, and a custom API — they are not exported by the package but are there to copy from.

---

## Bring your own tracker

All tracker implementations extend `BaseTrackerStrategy`.

### Required methods

```dart
class MyTracker extends BaseTrackerStrategy {
  MyTracker() : super(id: 'my_tracker', name: 'My Tracker');

  @override
  Future<void> doInitialize() async {
    // Called once by FlexTrack.setup(). Perform SDK init, open DB, etc.
    // Throw here to abort setup for this tracker.
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // Called for each routed event. Do the actual SDK call here.
    // event.getName()         → event name string
    // event.getProperties()   → Map<String, Object>? (may be null)
    // event.category          → EventCategory? (for reference)
  }
}
```

`BaseTrackerStrategy` wraps both methods in error handling and guards against double-init and calls before init. You never need to call `initialize()` directly.

### Optional overrides

Override only what your backend supports:

```dart
@override
bool supportsBatchTracking() => true;   // opt in to batched delivery

@override
Future<void> doTrackBatch(List<BaseEvent> events) async {
  // called instead of individual doTrack when supportsBatchTracking() == true
}

@override
Future<void> doSetUserProperties(Map<String, dynamic> properties) async {
  // called by FlexTrack.setUserProperties(...)
}

@override
Future<void> doIdentifyUser(String userId, [Map<String, dynamic>? properties]) async {
  // called by FlexTrack.identifyUser(...)
}

@override
Future<void> doReset() async {
  // called by FlexTrack.resetTrackers() — use on logout
}

@override
Future<void> doFlush() async {
  // called by FlexTrack.flush() — force-send any buffered events
}

@override
bool get isGDPRCompliant => true;   // informational; used in debug output
```

### Tracker id convention

The `id` string you pass to `super(id: '...')` is how routing rules reference your tracker:

```dart
.to(['firebase', 'mixpanel'])   // matches super(id: 'firebase') and super(id: 'mixpanel')
```

Use a stable, lowercase slug. Changing it after setup breaks routing rules that reference it.

### Example: Mixpanel-shaped tracker

Add `mixpanel_flutter` to your own `pubspec.yaml`, then:

```dart
class MyMixpanelTracker extends BaseTrackerStrategy {
  MyMixpanelTracker() : super(id: 'mixpanel', name: 'Mixpanel');

  late Mixpanel _mp;

  @override
  Future<void> doInitialize() async {
    _mp = await Mixpanel.init('YOUR_TOKEN', trackAutomaticEvents: false);
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    _mp.track(event.getName(), properties: event.getProperties());
  }

  @override
  Future<void> doIdentifyUser(String userId, [Map<String, dynamic>? props]) async {
    _mp.identify(userId);
    if (props != null) _mp.getPeople().set('\$name', props['name']);
  }

  @override
  Future<void> doReset() async => _mp.reset();
}
```

### Example: custom backend tracker

```dart
class MyApiTracker extends BaseTrackerStrategy {
  MyApiTracker({required this.endpoint})
    : super(id: 'api', name: 'My Analytics API');

  final String endpoint;

  @override
  Future<void> doInitialize() async {
    // Optionally verify endpoint reachability.
  }

  @override
  bool supportsBatchTracking() => true;

  @override
  Future<void> doTrackBatch(List<BaseEvent> events) async {
    final payload = events.map((e) => {
      'name': e.getName(),
      'props': e.getProperties(),
      'ts': e.timestamp.millisecondsSinceEpoch,
    }).toList();

    await http.post(Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload));
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    await doTrackBatch([event]);
  }
}
```

---

## Events

All events extend `BaseEvent`. The only two abstract members are `getName()` and `getProperties()`. Everything else is optional and defaults to safe values.

```dart
class PurchaseEvent extends BaseEvent {
  PurchaseEvent({required this.amount, required this.currency});

  final double amount;
  final String currency;

  @override
  String getName() => 'purchase';

  @override
  Map<String, Object>? getProperties() => {
    'amount': amount,
    'currency': currency,
  };

  // Optional routing / consent hints:
  @override EventCategory? get category => EventCategory.business;
  @override bool get isEssential => true;    // bypass consent + sampling
  @override bool get containsPII => false;
  @override bool get requiresConsent => true; // default is true
  @override bool get isHighVolume => false;
}
```

Track one or many:

```dart
await FlexTrack.track(PurchaseEvent(amount: 9.99, currency: 'USD'));

await FlexTrack.trackAll([
  PageViewEvent(page: 'checkout'),
  PurchaseEvent(amount: 9.99, currency: 'USD'),
]);

// Fire events in parallel (unordered delivery; use when order doesn't matter).
await FlexTrack.trackParallel([Event1(), Event2(), Event3()]);
```

### BaseEvent fields

| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `getName()` | `String` | **required** | Event name sent to backends |
| `getProperties()` | `Map<String, Object>?` | **required** | Event payload (return `null` or `{}` if none) |
| `category` | `EventCategory?` | `null` | Enables category-based routing rules |
| `containsPII` | `bool` | `false` | Triggers PII consent rules |
| `requiresConsent` | `bool` | `true` | Gated by general consent (set `false` for crash reporters) |
| `isEssential` | `bool` | `false` | Bypasses consent checks and sampling when `true` |
| `isHighVolume` | `bool` | `false` | Signals the routing engine to apply sampling rules |
| `timestamp` | `DateTime` | `DateTime.now()` | Override for historical / replayed events |
| `userId` | `String?` | `null` | Passed through to trackers and debug output |
| `sessionId` | `String?` | `null` | Groups related events in debug output |
| `preferredGroup` | `TrackerGroup?` | `null` | Hint to the routing engine; routing rules take precedence |

### EventCategory values

| Constant | When to use |
|----------|-------------|
| `EventCategory.business` | Revenue, conversions, funnels |
| `EventCategory.user` | Behavioural actions, preferences |
| `EventCategory.technical` | Errors, performance, debug |
| `EventCategory.sensitive` | Events that contain PII data |
| `EventCategory.marketing` | Campaign attribution, ad tracking |
| `EventCategory.system` | Internal health checks, lifecycle |
| `EventCategory.security` | Auth, access control, anomalies |

You can also define custom categories on the routing builder:

```dart
routing.defineCategory('payments', description: 'Payment-related events')
```

---

## Setup

### Simple setup

```dart
await FlexTrack.setup([
  ConsoleTracker(),
  MyFirebaseTracker(),
]);
```

`FlexTrack.setup` calls `initialize()` on every tracker, then applies smart defaults for routing. The singleton throws if called twice — call `await FlexTrack.reset()` before reconfiguring (e.g. between tests).

### Setup with routing

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  MyFirebaseTracker(), // id: 'firebase'
  MyMixpanelTracker(), // id: 'mixpanel'
], (routing) => routing

  // Business events to all trackers, never sampled.
  .routeCategory(EventCategory.business)
  .toAll()
  .noSampling()
  .and()

  // High-volume scroll/interaction events only to firebase, 1% sampled.
  .routeHighVolume()
  .to(['firebase'])
  .heavySampling()
  .and()

  // PII events require explicit PII consent.
  .routePII()
  .toAll()
  .requirePIIConsent()
  .and()

  // Technical/debug events only appear in debug builds.
  .routeCategory(EventCategory.technical)
  .toDevelopment()
  .onlyInDebug()
  .and()

  // Catch-all.
  .routeDefault()
  .toAll()
  .and()
);
```

Rules are evaluated in priority order (highest first). The first matching rule wins. If no rule matches (shouldn't happen with a `.routeDefault()`), the engine falls back to all trackers.

### Convenience setup functions

The library exports three ready-made setup functions for common scenarios:

```dart
// Smart defaults (samples high-volume, routes technical to debug only).
await setupFlexTrackWithDefaults([ConsoleTracker(), MyFirebaseTracker()]);

// Development only — ConsoleTracker, no sampling, debug mode on.
await setupFlexTrackForDevelopment();

// Tests — MockTracker, no consent checks, no sampling.
final mock = await setupFlexTrackForTesting();
```

---

## Routing DSL

Every routing configuration is a chain of: **matcher → target → modifiers → `.and()`**.

```
routing
  .<matcher>(...)   // what events to match
  .<target>(...)    // where to send them
  .<modifier>()     // how to send them
  .<modifier>()
  .and()            // commit rule, return builder for next rule
```

### Matchers

| Method | Matches |
|--------|---------|
| `.route<MyEvent>()` | Exact Dart type |
| `.routeNamed('pattern')` | Event name **contains** pattern (substring) |
| `.routeExact('name')` | Event name equals `name` exactly |
| `.routeMatching(RegExp(...))` | Event name matches regex |
| `.routeCategory(EventCategory.x)` | `event.category == x` |
| `.routeCategoryNamed('custom')` | Category defined via `defineCategory(...)` |
| `.routeWithProperty('key')` | `getProperties()` contains the key |
| `.routeWithProperty('key', value)` | Key present and equals value |
| `.routeEssential()` | `event.isEssential == true` |
| `.routeHighVolume()` | `event.isHighVolume == true` |
| `.routePII()` | `event.containsPII == true` |
| `.routeDefault()` | Catch-all; should be the last rule |

### Targets

| Method | Sends to |
|--------|---------|
| `.toAll()` | Every registered tracker |
| `.to(['id1', 'id2'])` | Specific trackers by id |
| `.toTracker('id')` | Single tracker |
| `.toDevelopment()` | `TrackerGroup.development` (see below) |
| `.toGroup(group)` | A `TrackerGroup` instance |
| `.toGroupNamed('name')` | A group defined via `defineGroup(...)` |

### Modifiers

**Sampling:**

| Method | Rate |
|--------|------|
| `.noSampling()` | 100% (default) |
| `.lightSampling()` | 10% |
| `.mediumSampling()` | 50% |
| `.heavySampling()` | 1% |
| `.sample(0.25)` | Custom rate 0.0–1.0 |

**Consent:**

| Method | Effect |
|--------|--------|
| `.requireConsent()` | Gate on general consent (default) |
| `.requirePIIConsent()` | Gate on PII consent |
| `.skipConsent()` | Always fire regardless of consent state |

**Environment:**

| Method | Effect |
|--------|--------|
| `.onlyInDebug()` | Skipped in release builds |
| `.onlyInProduction()` | Skipped in debug builds |

**Other:**

| Method | Effect |
|--------|--------|
| `.withPriority(n)` | Higher n evaluated first (default: 0) |
| `.withDescription('...')` | Label for debug output |
| `.withId('rule_id')` | Identify rule programmatically |
| `.essential()` | Shorthand: `skipConsent().noSampling().highPriority()` |

### Rule priority

Rules are sorted by priority before any event is processed. Higher priority wins. When two rules share the same priority, registration order breaks the tie. Predefined presets assign explicit priorities so your custom rules can slot in:

```dart
.routeMatching(RegExp(r'^purchase'))
.toAll()
.noSampling()
.withPriority(50)   // beats any preset rule (max preset priority ≈ 25)
.and()
```

### Tracker groups

Groups let you name a fixed set of trackers and reference it across rules.

```dart
routing
  .defineGroup('analytics', ['firebase', 'mixpanel'])
  .defineGroup('gdpr_safe', ['console', 'my_eu_backend'])

  .routeCategory(EventCategory.sensitive)
  .toGroupNamed('gdpr_safe')
  .requirePIIConsent()
  .and()

  .routeDefault()
  .toGroupNamed('analytics')
  .and()
```

Two predefined groups exist without any `defineGroup` call:
- `TrackerGroup.all` — every registered tracker
- `TrackerGroup.development` — trackers registered with a `'console'` or `'dev'` id (convention, not enforced)

---

## Consent

```dart
// After user accepts your consent dialog:
FlexTrack.setConsent(general: true, pii: false);

// Or individually:
FlexTrack.setGeneralConsent(true);
FlexTrack.setPIIConsent(true);

// Read back:
final status = FlexTrack.getConsentStatus();
// {'general': true, 'pii': false}
```

How consent interacts with events and rules:

| Event flag | Rule modifier | Outcome |
|------------|---------------|---------|
| `requiresConsent: true` (default) | `.requireConsent()` (default) | Blocked until `general: true` |
| `requiresConsent: false` | any | Always fires |
| `isEssential: true` | — | Bypasses both consent checks |
| `containsPII: true` | `.requirePIIConsent()` | Blocked until `pii: true` |

If no consent state has been set yet, `general` defaults to `false` and `pii` defaults to `false`. Events that require consent are dropped silently (no exception).

---

## Sampling

Sampling is applied per-rule. When a rule has `sample(0.1)`, each matching event independently has a 10% chance of being forwarded. The decision is made fresh per event using `dart:math`'s `Random`.

```dart
// Disable sampling globally (useful for testing or critical apps):
routing.setSampling(false)

// Or per-rule:
.routeHighVolume().toAll().heavySampling().and()  // 1%
.routeDefault().toAll().noSampling().and()         // 100%
```

`isEssential: true` on the event bypasses the sampling check for that event regardless of the rule's sample rate.

---

## Preset configurations

Three static preset classes are available. Call them inside `setupWithRouting`:

```dart
await FlexTrack.setupWithRouting(trackers, (routing) {
  SmartDefaults.apply(routing);
  return routing;
});
```

### SmartDefaults

`SmartDefaults.apply(builder)` — sensible starting point for most apps:
- `security` events: always fire, no consent, no sampling
- `essential` events: always fire, no consent, no sampling
- `technical` events: debug builds only, 10% sampling
- `system` events: skip consent, 10% sampling
- `sensitive` events: require both consents
- PII events: require PII consent
- high-volume events: 1% sampling
- default: everything else goes everywhere

Variants: `SmartDefaults.applyPerformanceFocused`, `SmartDefaults.applyPrivacyFocused`, `SmartDefaults.applyDevelopmentFriendly`.

### GDPRDefaults

`GDPRDefaults.apply(builder, compliantTrackers: ['my_eu_backend'])`:
- Defines a `gdpr_compliant` group from your compliantTrackers list
- Routes PII, sensitive, and property-keyed events (`email`, `phone`, `ip_address`, `location`) to that group with PII consent required
- `security` and `essential` events skip consent (legitimate interest basis)
- Default rule requires general consent with 50% sampling

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  MyFirebaseTracker(),    // id: 'firebase' — not GDPR safe
  MyEuBackendTracker(),   // id: 'eu_backend' — GDPR safe
], (routing) {
  GDPRDefaults.apply(routing, compliantTrackers: ['eu_backend']);
  return routing;
});
```

Variants: `applyStrict` (EU), `applyMinimal`, `applyCCPA` (California), `applyForRegion(GDPRRegion.eu)`.

### PerformanceDefaults

`PerformanceDefaults.apply(builder)` — for high-event-rate apps:
- UI interaction events (`click_*`, `tap_*`, `scroll_*`): 1% sampling
- Mouse/pointer events: 0.1% sampling
- Critical events (`purchase_*`, `error_*`): 0% sampling
- Default: 50% sampling

Variants: `applyMobileOptimized`, `applyWebOptimized`, `applyLowLatency`, `applyBandwidthConscious`, `applyHighThroughput`.

---

## Widget wrappers

All wrappers call `FlexTrack.track` and no-op safely if `FlexTrack` was never set up.

### FlexClickTrack

Wraps any widget. Fires on a completed tap (finger down + up without exceeding `kTouchSlop`). Drags and scrolls do not trigger tracking.

Uses a `Listener` with `HitTestBehavior.translucent`, so nested `InkWell`s, buttons, and `GestureDetector`s still receive their own gestures. You do not need to remove your existing `onPressed` to add analytics.

```dart
FlexClickTrack(
  event: ShareButtonTappedEvent(),
  child: IconButton(
    icon: const Icon(Icons.share),
    onPressed: _onShare,
  ),
)
```

No configuration beyond `event` and `child` is needed. The wrapper does not interfere with `Semantics` or accessibility.

### FlexImpressionTrack

Fires when the child becomes sufficiently visible in the viewport. Depends on [`visibility_detector`](https://pub.dev/packages/visibility_detector), which is a direct dependency of `flex_track`.

```dart
FlexImpressionTrack(
  // Must be stable for the same logical slot (e.g. item id, not list index).
  visibilityKey: ValueKey('product_${product.id}'),
  event: ProductImpressionEvent(product.id),

  // Required: fraction of the widget that must be visible (0 < x ≤ 1).
  visibleFractionThreshold: 0.5,

  // Optional: fraction must stay above threshold for this long.
  minVisibleDuration: const Duration(milliseconds: 300),

  // Optional: fire only once per State instance (default: true).
  // Set false to re-fire each time visibility crosses the threshold.
  fireOnce: true,

  child: ProductTile(product: product),
)
```

Important:
- **`visibilityKey` must be stable.** If your list rebuilds with a new key for the same slot, a new impression will fire.
- `fireOnce: true` (default) fires at most once per `State` lifecycle. Re-inserting the widget into the tree resets the counter.
- `fireOnce: false` fires once per visibility streak. The streak resets when the fraction drops below the threshold.

### FlexMountTrack

Fires exactly once after the widget's first frame is laid out. Useful for screen-view events in lazily-built lists (e.g. `ListView.builder`) when you want to know a row was rendered, not necessarily seen.

```dart
FlexMountTrack(
  event: ProductTileRenderedEvent(product.id),
  child: ProductTile(product: product),
)
```

`FlexMountTrack` does **not** mean the user saw the widget — the widget may be off-screen at mount time. For viewable-impression semantics, use `FlexImpressionTrack`.

### FlexTrackRouteViewMixin

For screen-level route tracking via Flutter's navigator observer system.

**Register one observer on `MaterialApp`:**

```dart
final _routeObserver = FlexTrackRouteObserver();

MaterialApp(
  navigatorObservers: [_routeObserver],
  home: const HomeScreen(),
)
```

**Apply the mixin on each screen's `State`:**

```dart
class _HomeScreenState extends State<HomeScreen> with FlexTrackRouteViewMixin {
  @override
  FlexTrackRouteObserver get flexTrackRouteObserver => _routeObserver;

  @override
  BaseEvent get routeViewEvent => HomeViewedEvent();

  /// Set true to fire another view event when the user pops back to this screen.
  @override
  bool get trackWhenReturningFromChildRoute => false;

  @override
  Widget build(BuildContext context) => Scaffold(/* ... */);
}
```

The mixin subscribes via `RouteAware` and fires `routeViewEvent` on initial push and (optionally) on pop-back. It unsubscribes automatically in `dispose`.

Full widget semantics and widget test examples: [docs/widgets.md](docs/widgets.md).

---

## User identification

Call these after setup and after consent is confirmed:

```dart
// Attach a user id and optional traits to all subsequent events.
await FlexTrack.identifyUser('user_123', {
  'plan': 'pro',
  'country': 'DE',
});

// Update user properties without changing the id.
await FlexTrack.setUserProperties({'last_seen': DateTime.now().toIso8601String()});

// On logout: clear identity in all trackers.
await FlexTrack.resetTrackers();
```

Each method is forwarded to every enabled tracker's `doIdentifyUser` / `doSetUserProperties` / `doReset`. If your tracker doesn't override these, they no-op by default.

---

## Tracker lifecycle

```dart
// Enable or disable a tracker at runtime (persists until reset()).
FlexTrack.enableTracker('firebase');
FlexTrack.disableTracker('mixpanel');

FlexTrack.enableAllTrackers();
FlexTrack.disableAllTrackers();

FlexTrack.isTrackerEnabled('firebase'); // → bool

// List registered ids.
final ids = FlexTrack.getTrackerIds(); // → Set<String>

// Force-flush any buffered events (call before app background/suspend).
await FlexTrack.flush();

// Check setup state.
FlexTrack.isSetUp;   // → bool (safe to call before setup)
FlexTrack.isEnabled; // → bool
```

---

## Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  late MockTracker mock;

  setUp(() async {
    mock = await setupFlexTrackForTesting();
    // Disables consent checks and sampling.
    // Sets debug mode on.
  });

  tearDown(() async {
    await FlexTrack.reset(); // mandatory between tests
  });

  test('tracks purchase event', () async {
    await FlexTrack.track(PurchaseEvent(amount: 9.99, currency: 'USD'));

    expect(mock.capturedEvents, hasLength(1));
    expect(mock.capturedEvents.single.getName(), 'purchase');
    expect(mock.capturedEvents.single.getProperties()?['amount'], 9.99);
  });

  test('captures user identification', () async {
    await FlexTrack.identifyUser('u_1', {'plan': 'pro'});

    expect(mock.capturedUserIds, contains('u_1'));
    expect(mock.capturedUserProperties.first['plan'], 'pro');
  });
}
```

`MockTracker` exposes:
- `capturedEvents` — `List<BaseEvent>` (unmodifiable view)
- `capturedUserProperties` — `List<Map<String, dynamic>>`
- `capturedUserIds` — `List<String>`
- `clearCapturedData()` — reset between assertions in the same test

If you need to test consent gating or sampling behaviour, set up with a custom routing config instead of `setupFlexTrackForTesting`:

```dart
setUp(() async {
  final mock = MockTracker();
  await FlexTrack.setupWithRouting([mock], (r) => r
    .routePII().toAll().requirePIIConsent().and()
    .routeDefault().toAll().and());
});
```

More patterns and widget test examples: [docs/testing-and-troubleshooting.md](docs/testing-and-troubleshooting.md).

---

## Debugging

**Print a summary of all registered trackers, consent state, and routing config:**

```dart
FlexTrack.printDebugInfo();
```

**Dry-run an event through the routing engine without actually tracking it:**

```dart
final info = FlexTrack.debugEvent(PurchaseEvent(amount: 9.99, currency: 'USD'));
// info.matchedRule      → RoutingRule?
// info.targetTrackers   → List<String>
// info.skippedRules     → List<SkippedRule> (with reasons)
// info.wouldSample      → bool
// info.wouldPassConsent → bool
```

**Validate the routing configuration for common mistakes:**

```dart
final errors = FlexTrack.validate();
if (errors.isNotEmpty) {
  for (final e in errors) debugPrint('Config error: $e');
}
```

**Get raw debug map (for logging or remote diagnostics):**

```dart
final info = FlexTrack.getDebugInfo();
// {'isSetUp': true, 'isInitialized': true, 'isEnabled': true, 'eventProcessor': {...}}
```

**ConsoleTracker options:**

```dart
ConsoleTracker(
  showProperties: true,   // default: true
  showTimestamps: true,   // default: true
  colorOutput: true,      // default: true — ANSI colours in terminal
  prefix: '📊 Analytics', // default: '📊 FlexTrack'
)
```

`ConsoleTracker` also maintains an in-memory `eventHistory` list for inspection during development:

```dart
final console = ConsoleTracker();
// ... after some tracking ...
console.eventHistory.last.getName(); // last tracked event name
console.clearHistory();
```

---

## Reference — event flags

| Flag | Type | Default | Routing effect |
|------|------|---------|----------------|
| `category` | `EventCategory?` | `null` | Matched by `.routeCategory(...)` |
| `containsPII` | `bool` | `false` | Matched by `.routePII()`; triggers `.requirePIIConsent()` rules |
| `requiresConsent` | `bool` | `true` | Blocks on `.requireConsent()` rules when consent is `false` |
| `isEssential` | `bool` | `false` | Bypasses consent checks and sampling for this event |
| `isHighVolume` | `bool` | `false` | Matched by `.routeHighVolume()`; sampling rules often target this |
| `userId` | `String?` | `null` | Displayed in `ConsoleTracker` output; not used for routing |
| `sessionId` | `String?` | `null` | Displayed in `ConsoleTracker` output; not used for routing |
| `timestamp` | `DateTime` | `DateTime.now()` | Not used by routing; forwarded to trackers via `getProperties()` if included |

---

## Reference — routing DSL

**Matchers** (on `RoutingBuilder`):

```
.route<T>()                              exact Dart type
.routeNamed('substring')                 name contains substring
.routeExact('name')                      name == 'name'
.routeMatching(RegExp(r'...'))           regex
.routeCategory(EventCategory.x)          category == x
.routeCategoryNamed('custom')            user-defined category
.routeWithProperty('key')                property key exists
.routeWithProperty('key', value)         property key == value
.routeEssential()                        isEssential == true
.routeHighVolume()                       isHighVolume == true
.routePII()                              containsPII == true
.routeDefault()                          catch-all (put last)
```

**Targets** (on `RouteConfigBuilder`):

```
.toAll()                  TrackerGroup.all
.to(['id1', 'id2'])       explicit tracker ids
.toTracker('id')          single tracker
.toDevelopment()          TrackerGroup.development
.toGroupNamed('name')     user-defined group
.toGroup(group)           TrackerGroup instance
```

**Modifiers** (on `RoutingRuleBuilder`):

```
Sampling:
  .noSampling()            100%
  .lightSampling()          10%
  .mediumSampling()         50%
  .heavySampling()           1%
  .sample(0.05)           custom

Consent:
  .requireConsent()        gate on general consent (default)
  .requirePIIConsent()     gate on PII consent
  .skipConsent()           always fire

Environment:
  .onlyInDebug()           skipped in release
  .onlyInProduction()      skipped in debug

Priority / metadata:
  .withPriority(n)         higher = evaluated first (default: 0)
  .withDescription('...')  label in debug output
  .withId('rule_id')       programmatic reference

Shorthand:
  .essential()             skipConsent + noSampling + highPriority(10)
  .highPriority()          withPriority(10)
  .lowPriority()           withPriority(-10)

Chain:
  .and()                   commit rule, return RoutingBuilder
```

**RoutingBuilder global options:**

```dart
routing
  .setSampling(false)          // disable sampling globally
  .setConsentChecking(false)   // disable consent globally (useful in tests)
  .setDebugMode(true)          // used by environment-based rules
  .defineGroup('name', ['id1', 'id2'])
  .defineCategory('custom_name')
```

---

## Reference — preset index

| Class | Method | Summary |
|-------|--------|---------|
| `SmartDefaults` | `apply` | Sensible defaults for most apps |
| `SmartDefaults` | `applyPerformanceFocused` | Adds `high_frequency`/`batchable` property rules |
| `SmartDefaults` | `applyPrivacyFocused` | Adds consent rules for user + marketing categories |
| `SmartDefaults` | `applyDevelopmentFriendly` | Routes `debug_*`, `test_*`, `dev_*` to development only |
| `GDPRDefaults` | `apply` | Standard GDPR (UK/global) |
| `GDPRDefaults` | `applyStrict` | EU GDPR + behavioral event consent |
| `GDPRDefaults` | `applyMinimal` | PII/sensitive only; everything else unguarded |
| `GDPRDefaults` | `applyCCPA` | California opt-out model |
| `GDPRDefaults` | `applyForRegion` | Dispatches to above by `GDPRRegion` enum |
| `PerformanceDefaults` | `apply` | Aggressive sampling for UI interaction events |
| `PerformanceDefaults` | `applyMobileOptimized` | Even more aggressive; adds touch/location rules |
| `PerformanceDefaults` | `applyWebOptimized` | Adds SPA navigation and DOM event rules |
| `PerformanceDefaults` | `applyLowLatency` | Only essential + critical events; 1% default |
| `PerformanceDefaults` | `applyBandwidthConscious` | Only business-critical events; 0.1% default |
| `PerformanceDefaults` | `applyHighThroughput` | Extreme sampling; 0.001% default |

All presets can be combined — call them sequentially on the same builder. Rules added later at equal priority are evaluated after rules added earlier, so order matters.

---

## Contributing / license

**Repository:** [github.com/alirezat66/flex_track](https://github.com/alirezat66/flex_track)

**Further reading:**

| Topic | File |
|-------|------|
| Tracker mental model, multiple backends | [docs/trackers.md](docs/trackers.md) |
| Routing rules, priority, groups | [docs/routing-and-rules.md](docs/routing-and-rules.md) |
| GDPR / performance presets, consent detail | [docs/privacy-performance-debugging.md](docs/privacy-performance-debugging.md) |
| Widget semantics, widget tests | [docs/widgets.md](docs/widgets.md) |
| Pitfalls, migration notes | [docs/testing-and-troubleshooting.md](docs/testing-and-troubleshooting.md) |
| Runnable app + reference tracker implementations | [example/](example/) |

**API entrypoint:** [`package:flex_track/flex_track.dart`](lib/flex_track.dart)

**License:** [LICENSE](LICENSE)
