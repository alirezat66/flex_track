![FlexTrack Banner](docs/assets/banner.png)

# FlexTrack

Multi-tracker analytics orchestration for Flutter: route events, enforce consent, and debug dispatch decisions from one call site.

[![pub package](https://img.shields.io/pub/v/flex_track.svg)](https://pub.dev/packages/flex_track)
[![CI](https://github.com/alirezat66/flex_track/actions/workflows/ci.yml/badge.svg)](https://github.com/alirezat66/flex_track/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/alirezat66/flex_track/blob/main/LICENSE)

**Settings → Pages** to that branch if the site is not live yet). API reference: [pub.dev documentation](https://pub.dev/documentation/flex_track/latest/).

---

## The Problem

In many Flutter apps, analytics logic drifts into multiple layers and becomes difficult to reason about.

- Events are scattered across widgets, cubits, repositories, and services.
- Different trackers (Firebase, Mixpanel, internal APIs) need different routing rules.
- Consent and PII checks are often duplicated or inconsistently applied.
- High-volume events can flood pipelines and increase cost.
- Teams struggle to verify what was sent, where it went, and why.

This creates fragile analytics implementations that are hard to maintain and hard to trust.

## The Solution

FlexTrack introduces a centralized orchestration layer for analytics in Flutter.

- One tracking call can dispatch to multiple trackers.
- Declarative routing rules decide target trackers per event.
- Consent, PII, and sampling policy are enforced in one place.
- Debug tooling helps you inspect decisions and payload flow live.

Instead of spreading analytics policy throughout the app, define it once and apply it consistently.

## Visual Demo

![Inspector Demo](docs/assets/inspector.gif)

## Quick Example

```dart
await FlexTrack.track(AppOpenedEvent());
```

One call site, multiple tracker destinations, centralized policy.

---

## Table of contents

- [FlexTrack](#flextrack)
  - [Table of contents](#table-of-contents)
  - [Quick start](#quick-start)
  - [Compare with the usual approach](#compare-with-the-usual-approach)
  - [Why this exists](#why-this-exists)
  - [Who this is for / not for](#who-this-is-for--not-for)
  - [Features](#features)
  - [Examples](#examples)
  - [FlexTrackClient and dependency injection](#flextrackclient-and-dependency-injection)
    - [Riverpod](#riverpod)
    - [Bloc / Cubit](#bloc--cubit)
  - [Design philosophy](#design-philosophy)
  - [Creating events](#creating-events)
    - [Event flags](#event-flags)
    - [EventCategory values](#eventcategory-values)
  - [Creating trackers](#creating-trackers)
    - [Firebase example](#firebase-example)
    - [Mixpanel example](#mixpanel-example)
  - [Smart routing](#smart-routing)
    - [Routing DSL](#routing-dsl)
    - [Tracker groups](#tracker-groups)
    - [Priority](#priority)
    - [Environment modifiers](#environment-modifiers)
  - [Widget wrappers](#widget-wrappers)
    - [FlexClickTrack](#flexclicktrack)
    - [FlexImpressionTrack](#fleximpressiontrack)
    - [FlexMountTrack](#flexmounttrack)
    - [FlexTrackRouteViewMixin](#flextrackrouteviewmixin)
  - [GDPR and consent](#gdpr-and-consent)
  - [Sampling and performance](#sampling-and-performance)
  - [Debugging](#debugging)
    - [FlexTrack Inspector](#flextrack-inspector)
  - [Testing](#testing)
  - [Common pitfalls](#common-pitfalls)
    - [1. Calling track() before setup()](#1-calling-track-before-setup)
    - [2. Forgetting FlexTrack.reset() between tests](#2-forgetting-flextrackreset-between-tests)
    - [3. Unstable visibilityKey in FlexImpressionTrack](#3-unstable-visibilitykey-in-fleximpressiontrack)
    - [4. Missing .routeDefault() at the end of a routing config](#4-missing-routedefault-at-the-end-of-a-routing-config)
  - [Contributing and license](#contributing-and-license)
  - [Support](#support)

---

## Quick start

**Step 1 — add the dependency:**

```yaml
# pubspec.yaml
dependencies:
  flex_track: ^1.0.0
```

**Step 2 — implement your tracker** (the package ships no vendor SDKs; you write a thin adapter):

```dart
// lib/trackers/firebase_tracker.dart
import 'package:flex_track/flex_track.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseTracker extends BaseTrackerStrategy {
  FirebaseTracker() : super(id: 'firebase', name: 'Firebase Analytics');

  @override
  Future<void> doInitialize() async {
    // Firebase.initializeApp() should be called before FlexTrack.setup().
    // Put any tracker-specific init here.
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    await FirebaseAnalytics.instance.logEvent(
      name: event.getName(),
      parameters: event.getProperties(),
    );
  }
}
```

**Step 3 — set up:**

```dart
// lib/main.dart
import 'package:flex_track/flex_track.dart';
import 'trackers/firebase_tracker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FlexTrack.setup([
    ConsoleTracker(),   // built-in — prints to debug console
    FirebaseTracker(),  // your class from step 2
  ]);

  runApp(const MyApp());
}
```

**Step 4 — track:**

```dart
await FlexTrack.track(AppOpenedEvent());
```

That's it. Both trackers receive every event. Add routing rules when you need more control.

---


## Compare with the usual approach

| Approach | Trade-offs |
| --- | --- |
| Direct SDK calls | Fast to start, but logic becomes scattered and difficult to audit. |
| Custom wrappers | Centralizes calls, but often lacks routing, consent policy, and sampling controls. |
| FlexTrack | Centralized, rule-driven, consent-aware, and testable orchestration across trackers. |

## Why this exists

Most production apps eventually use more than one analytics destination. Teams need to blend product analytics, growth metrics, and internal reporting while still enforcing consent and performance constraints.

FlexTrack exists to make that architecture explicit, maintainable, and debuggable in Flutter.

## Who this is for / not for

**This is for:**
- Flutter teams using multiple analytics providers
- Apps with consent, GDPR, or PII controls
- Teams that want clean routing policy and testable analytics behavior

**This is not for:**
- Tiny apps with one tracker and no policy requirements
- Quick throwaway prototypes where minimal setup matters more than architecture

## Features

- Multi-tracker routing with a fluent DSL
- Event policy controls (consent, PII, sampling, environment modifiers)
- Debug Inspector with live event visibility
- `FlexTrackClient` for dependency injection patterns
- Widget wrappers for click, impression, mount, and route-view tracking

---

## Examples

| Path | What it shows |
| ---- | ------------- |
| [`example/`](example/) | Flagship Flutter app: routing, consent UI, mock trackers, widget wrappers, `FlexTrackRouteObserver`. Run with `cd example && flutter run`. |
| [`examples/static_app`](examples/static_app) | `FlexTrack.setup` / `FlexTrack.track` only (no DI). |
| [`examples/riverpod_app`](examples/riverpod_app) | `FlexTrack.setup` in `main`, then `FlexTrack.instance.client` from a Riverpod `Provider`. |
| [`examples/bloc_getit_app`](examples/bloc_getit_app) | Same client registered in GetIt; a `Cubit` calls `client.track`. |

**Live web build** of the flagship example ships with the doc site: from the [documentation site](https://alirezat66.github.io/flex_track/) use **Live demo** in the navbar (`/demo/`), built in CI from `example/`.

---

## FlexTrackClient and dependency injection

`FlexTrack.setup()` still installs a **singleton** and `FlexTrack.track()` delegates to it. For **constructor injection** (Bloc/Cubit, Riverpod, tests without globals), build a **`FlexTrackClient`** with the same routing stack:

```dart
final analytics = await FlexTrackClient.create(
  [ConsoleTracker(), FirebaseTracker()],
  // routing: optional RoutingConfiguration; defaults to smart defaults
);

await analytics.track(AppOpenedEvent());
await analytics.dispose(); // flush trackers when tearing down (e.g. tests)
```

With the routing DSL (mirror of `FlexTrack.setupWithRouting`):

```dart
final analytics = await FlexTrackClient.createWithRouting(
  [ConsoleTracker()],
  (b) {
    b.routeDefault().toAll();
    return b;
  },
);
```

After `FlexTrack.setup`, the underlying client is available as **`FlexTrack.instance.client`** if you need both global widgets and an injectable reference to the same instance.

### Riverpod

Define a provider (overridden in `main` and in tests):

```dart
// analytics_providers.dart — add flutter_riverpod to the app, not to flex_track
import 'package:flex_track/flex_track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flexTrackClientProvider = Provider<FlexTrackClient>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});
```

Bootstrap:

```dart
final client = await FlexTrackClient.create([ConsoleTracker(), FirebaseTracker()]);

runApp(ProviderScope(
  overrides: [flexTrackClientProvider.overrideWithValue(client)],
  child: const MyApp(),
));
```

Use inside a notifier or service:

```dart
Future<void> onPurchaseComplete(WidgetRef ref) async {
  await ref.read(flexTrackClientProvider).track(PurchaseEvent(amount: 9.99));
}
```

### Bloc / Cubit

Pass the client into the cubit; domain code stays testable by injecting a client backed by `MockTracker`.

```dart
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._analytics) : super(const CheckoutState());
  final FlexTrackClient _analytics;

  Future<void> complete() async {
    await _analytics.track(OrderCompletedEvent());
    // ...
  }
}
```

For **strict** clean architecture, wrap `FlexTrackClient` behind your own `Analytics` interface in the domain module and implement the adapter in infrastructure.

More detail: [docs/flex-track-client.md](docs/flex-track-client.md).

---

## Design philosophy

This package does not bundle Firebase, Mixpanel, Amplitude, or any other analytics SDK. You extend `BaseTrackerStrategy` — the adapter lives in your codebase, under your control. This means no transitive dependency conflicts, no surprise SDK version requirements, and no opaque initialisation happening inside the package. The package routes; you decide where events go and how they get there.

---

## Creating events

Extend `BaseEvent` and implement `getName()` and `getProperties()`. Everything else is optional.

```dart
class PurchaseEvent extends BaseEvent {
  final double amount;
  PurchaseEvent({required this.amount});

  @override
  String getName() => 'purchase';

  @override
  Map<String, Object> getProperties() => {'amount': amount};

  @override
  EventCategory get category => EventCategory.business;

  @override
  bool get isEssential => true;

  @override
  bool get containsPII => false;
}
```

### Event flags

All flags have safe defaults — override only the ones relevant to your event.

| Flag | Default | Effect |
|------|---------|--------|
| `isEssential` | `false` | Bypasses consent checks and sampling — always sent |
| `isHighVolume` | `false` | Signals to routing rules that sampling should apply |
| `containsPII` | `false` | Blocks the event until PII consent is granted |
| `requiresConsent` | `true` | Blocks the event until general consent is granted |

Rules of thumb:
- Crash reporters, security events → `isEssential: true`
- Scroll position, hover events → `isHighVolume: true`
- Profile updates, search queries → `containsPII: true`
- App open, session start → `requiresConsent: false` if no personal data is sent

### EventCategory values

| Category | When to use |
|----------|-------------|
| `EventCategory.business` | Revenue, conversions, checkout funnel |
| `EventCategory.user` | Behaviour, preferences, feature usage |
| `EventCategory.technical` | Errors, performance, debug events |
| `EventCategory.sensitive` | Events that combine PII with behaviour |
| `EventCategory.marketing` | Campaign attribution, ad interactions |
| `EventCategory.system` | App lifecycle, background tasks |

### Custom categories

If the predefined categories don't fit your domain, define your own with `defineCategory()` on the `RoutingBuilder`:

```dart
FlexTrack.configure(
  RoutingBuilder()
    .defineCategory('experiments', description: 'A/B test and feature flag events')
    .defineCategory('payments', description: 'Payment flow events')
    // ... rest of your config
);
```

Then assign it in your event:

```dart
class ExperimentEvent extends TrackableEvent {
  @override
  EventCategory get category => const EventCategory('experiments');
}
```

And route it like any predefined category:

```dart
.routeCategory(const EventCategory('experiments')).to(['analytics']).and()
```

You can also create a subcategory of an existing one:

```dart
final paymentsCategory = EventCategory.business.createSubcategory('payments');
// results in name: 'business_payments'
```

---

## Creating trackers

All trackers extend `BaseTrackerStrategy`. Implement `doInitialize()` and `doTrack()`. The base class handles:
- Guarding against double-initialisation
- Catching and wrapping errors from your implementation
- Enabling/disabling at runtime

```dart
class MyTracker extends BaseTrackerStrategy {
  MyTracker() : super(id: 'my_tracker', name: 'My Tracker');

  @override
  Future<void> doInitialize() async {
    // Called once by FlexTrack.setup(). Perform SDK init here.
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // Called for each routed event.
    // event.getName()       → String
    // event.getProperties() → Map<String, Object>
    // event.category        → EventCategory?
  }
}
```

The `id` you pass to `super` is how routing rules reference this tracker:

```dart
.to(['my_tracker'])   // matches super(id: 'my_tracker', ...)
```

Use a stable, lowercase slug. Changing the id breaks any routing rule that references it.

### Firebase example

```dart
// lib/trackers/firebase_tracker.dart
import 'package:flex_track/flex_track.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseTracker extends BaseTrackerStrategy {
  FirebaseTracker() : super(id: 'firebase', name: 'Firebase Analytics');

  @override
  Future<void> doInitialize() async {
    // Firebase.initializeApp() should already be called before FlexTrack.setup().
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    await FirebaseAnalytics.instance.logEvent(
      name: event.getName(),
      parameters: event.getProperties(),
    );
  }
}
```

### Mixpanel example

```dart
// lib/trackers/mixpanel_tracker.dart
import 'package:flex_track/flex_track.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixpanelTracker extends BaseTrackerStrategy {
  MixpanelTracker() : super(id: 'mixpanel', name: 'Mixpanel');

  late Mixpanel _mixpanel;

  @override
  Future<void> doInitialize() async {
    _mixpanel = await Mixpanel.init('YOUR_PROJECT_TOKEN', trackAutomaticEvents: false);
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    _mixpanel.track(event.getName(), properties: event.getProperties());
  }
}
```

Use both in setup:

```dart
// lib/main.dart
import 'trackers/firebase_tracker.dart';
import 'trackers/mixpanel_tracker.dart';

await FlexTrack.setup([
  ConsoleTracker(),
  FirebaseTracker(),
  MixpanelTracker(),
]);
```

---

## Smart routing

Without a routing config, every event goes to every tracker. Routing rules let you control which events go where, with what sampling, and under what consent conditions.

### Routing DSL

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  FirebaseTracker(),    // id: 'firebase'
  MixpanelTracker(),   // id: 'mixpanel'
], (routing) => routing

  // Business events: everywhere, never sampled.
  .routeCategory(EventCategory.business)
  .toAll()
  .noSampling()
  .withPriority(20)
  .and()

  // High-volume events: firebase only, 1% sampling.
  .routeHighVolume()
  .to(['firebase'])
  .heavySampling()
  .and()

  // PII events: require explicit PII consent.
  .routePII()
  .to(['internal'])
  .requirePIIConsent()
  .and()

  // Essential events: always fire, no consent check.
  .routeEssential()
  .toAll()
  .skipConsent()
  .and()

  // Events with an internal_metric property: api tracker only.
  .routeWithProperty('internal_metric')
  .to(['api'])
  .and()

  // Specific name pattern.
  .routeMatching(RegExp(r'purchase_.*'))
  .toAll()
  .noSampling()
  .and()

  // Exact name match.
  .routeNamed('app_start')
  .to(['firebase'])
  .and()

  // Catch-all — always include this.
  .routeDefault()
  .toAll()
);
```

Rules are evaluated in priority order. The first matching rule wins.

**Full list of matchers:**

| Matcher | Matches when |
|---------|-------------|
| `.routeCategory(EventCategory.x)` | `event.category == x` |
| `.routeHighVolume()` | `event.isHighVolume == true` |
| `.routeEssential()` | `event.isEssential == true` |
| `.routePII()` | `event.containsPII == true` |
| `.routeMatching(RegExp(...))` | event name matches the regex |
| `.routeNamed('pattern')` | event name contains the substring |
| `.routeWithProperty('key')` | `getProperties()` contains the key |
| `.routeDefault()` | catch-all (put this last) |

**Full list of targets:**

| Target | Sends to |
|--------|---------|
| `.toAll()` | Every registered tracker |
| `.to(['id1', 'id2'])` | Specific trackers by id |
| `.toGroupNamed('name')` | A named group (see below) |

**Consent modifiers:**

| Modifier | Effect |
|----------|--------|
| `.requireConsent()` | Blocked until `general: true` (default behaviour) |
| `.requirePIIConsent()` | Blocked until `pii: true` |
| `.skipConsent()` | Always fires regardless of consent state |

### Tracker groups

Name a fixed set of trackers and reference them across rules:

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  FirebaseTracker(),
  MixpanelTracker(),
], (routing) => routing
  .defineGroup('paid', ['mixpanel', 'amplitude'])
  .defineGroup('internal', ['console', 'api'])

  .routeCategory(EventCategory.user)
  .toGroupNamed('paid')
  .and()

  .routeCategory(EventCategory.technical)
  .toGroupNamed('internal')
  .and()

  .routeDefault()
  .toAll()
);
```

### Priority

Higher priority rules are evaluated first. Rules with equal priority are evaluated in the order they were added. The default priority is 0.

```dart
routing
  .routeCategory(EventCategory.business).toAll().withPriority(20).and()
  .routeHighVolume().to(['firebase']).withPriority(10).and()
  .routeDefault().toAll()
  // business events (priority 20) are matched before high-volume (priority 10)
```

This matters when an event matches multiple rules — only the first match is applied.

### Environment modifiers

```dart
// Only in debug builds (kDebugMode == true).
.routeCategory(EventCategory.technical).to(['console']).onlyInDebug().and()

// Only in release builds.
.routeCategory(EventCategory.marketing).toAll().onlyInProduction().and()
```

These work per-rule, so you can send the same event to the console in debug and to Firebase in production:

```dart
routing
  .routeCategory(EventCategory.technical).to(['console']).onlyInDebug().and()
  .routeDefault().toAll()
```

---

## Widget wrappers

All wrappers call `FlexTrack.track` internally and no-op safely if `FlexTrack.setup` was never called.

### FlexClickTrack

Wraps any widget and fires an event on tap. Uses `GestureDetector` with `HitTestBehavior.translucent`, so child interactive widgets (`ElevatedButton`, `InkWell`, `TextButton`) still receive their own tap events as well. You do not need to remove existing `onPressed` handlers.

```dart
// Works on non-interactive widgets directly:
FlexClickTrack(
  event: BannerClickEvent(),
  child: Image.network('https://example.com/banner.png'),
)

// Also works when the child is already interactive — both fire:
FlexClickTrack(
  event: SignUpButtonClickedEvent(),
  child: ElevatedButton(
    onPressed: _navigateToSignUp,
    child: const Text('Sign up'),
  ),
)
```

### FlexImpressionTrack

Fires when the child widget crosses a visibility threshold. Requires the [`visibility_detector`](https://pub.dev/packages/visibility_detector) package in your app.

```dart
FlexImpressionTrack(
  // Must be stable for the same logical slot across rebuilds.
  // Use item id, not list index.
  visibilityKey: ValueKey('banner_${banner.id}'),

  event: BannerImpressionEvent(bannerId: banner.id),

  // Fire when 50% of the widget is visible (default: 0.5).
  visibleFractionThreshold: 0.5,

  // Optional: widget must stay visible for this long before firing.
  minVisibleDuration: const Duration(milliseconds: 500),

  // Default: true — fires at most once per widget lifecycle.
  // Set false to re-fire after the widget leaves and re-enters view.
  fireOnce: true,

  child: BannerWidget(banner: banner),
)
```

Two things to get right:

1. **`visibilityKey` must be stable for the same content.** If your list rebuilds and a different `Key` instance refers to the same banner slot, a new impression fires. Use `ValueKey(item.id)`, not `ValueKey(index)`.

2. **`fireOnce: true` (default) is per `State` instance.** The event fires once and won't fire again even if the user scrolls away and back. Set `fireOnce: false` if you want re-impression tracking on each visibility streak.

### FlexMountTrack

Fires exactly once after the widget is first inserted into the widget tree. Useful in `ListView.builder` to know when an item was built (rendered on scroll), not necessarily seen.

```dart
// Each time this ProductTile is built by ListView.builder, one event fires.
FlexMountTrack(
  event: ProductTileRenderedEvent(productId: product.id),
  child: ProductTile(product: product),
)
```

`FlexMountTrack` fires on **mount**, not on visibility. The widget may be off-screen when it mounts (e.g. Flutter over-renders scroll views). Use `FlexImpressionTrack` when you need confirmed visibility.

### FlexTrackRouteViewMixin

Tracks screen views via Flutter's navigator observer. Register one `FlexTrackRouteObserver` instance on `MaterialApp`, then apply the mixin to each screen's `State`.

```dart
// lib/main.dart — register once
final routeObserver = FlexTrackRouteObserver();

MaterialApp(
  navigatorObservers: [routeObserver],
  home: const HomeScreen(),
)
```

```dart
// lib/screens/home_screen.dart
import 'package:flex_track/flex_track.dart';
import '../main.dart' show routeObserver;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with FlexTrackRouteViewMixin {
  @override
  FlexTrackRouteObserver get flexTrackRouteObserver => routeObserver;

  @override
  BaseEvent get routeViewEvent => HomeViewedEvent();

  /// Set true to fire another view event when the user pops back to this screen.
  @override
  bool get trackWhenReturningFromChildRoute => false;

  @override
  Widget build(BuildContext context) => const Scaffold(/* ... */);
}
```

The mixin subscribes via `RouteAware` and fires `routeViewEvent` on push, and optionally on pop-back. It unsubscribes automatically in `dispose` — no cleanup needed.

---

## GDPR and consent

```dart
// Call this after the user responds to your consent dialog.
FlexTrack.setConsent(general: true, pii: false);

// Read the current state.
final status = FlexTrack.getConsentStatus();
// Returns: {'general': true, 'pii': false}
```

Until consent is set, `general` and `pii` both default to `false`. Events that require consent are dropped silently — no exception is thrown.

**Consent interaction table:**

| Event flag | Rule modifier | What happens |
|------------|---------------|-------------|
| `requiresConsent: true` (default) | `.requireConsent()` (default) | Dropped until `general: true` |
| `requiresConsent: false` | — | Always fires |
| `isEssential: true` | — | Always fires regardless of any consent state |
| `containsPII: true` | `.requirePIIConsent()` | Dropped until `pii: true` |

**GDPR presets:**

`GDPRDefaults.apply` adds pre-configured rules for PII, sensitive, user, marketing, and system categories. Pass `compliantTrackers` to limit PII events to specific backends.

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  FirebaseTracker(),        // id: 'firebase' — you've verified it's GDPR compliant
  InternalApiTracker(),     // id: 'internal'
], (routing) {
  GDPRDefaults.apply(routing, compliantTrackers: ['firebase', 'internal']);
  return routing;
});
```

For stricter controls (e.g. EU deployment), use `GDPRDefaults.applyStrict`:

```dart
GDPRDefaults.applyStrict(routing, compliantTrackers: ['internal']);
```

`applyStrict` additionally requires consent for behavioral events (click, view, scroll patterns) and restricts more property keys.

---

## Sampling and performance

Sampling is applied per-rule. Each matching event independently has a random chance of being forwarded at the specified rate.

| Method | Rate |
|--------|------|
| `.noSampling()` | 100% — all events |
| `.lightSampling()` | 10% |
| `.mediumSampling()` | 50% |
| `.heavySampling()` | 1% |
| `.sample(0.25)` | Custom rate (0.0–1.0) |

`isEssential: true` on the event bypasses sampling for that event regardless of the rule's sample rate.

**Performance presets:**

```dart
await FlexTrack.setupWithRouting(trackers, (routing) {
  PerformanceDefaults.apply(routing);
  return routing;
});

// More aggressive for mobile:
PerformanceDefaults.applyMobileOptimized(routing);
```

`PerformanceDefaults.apply` applies heavy sampling to high-volume and UI interaction events, and no sampling to critical business events like purchases and errors.

**Batch tracking:**

```dart
// Track multiple events in one call — more efficient than sequential track() calls.
await FlexTrack.trackAll([
  PageViewEvent(page: 'checkout'),
  CheckoutStartedEvent(cartValue: 49.99),
]);
```

**Pausing and resuming:**

```dart
// Pause all tracking (e.g. user opts out mid-session).
FlexTrack.disable();

// Resume.
FlexTrack.enable();
```

---

## Debugging

### FlexTrack Inspector

In **debug** builds on **mobile/desktop** (not Flutter Web), you can start a local dashboard that streams events as they are dispatched. The console prints a URL such as:

```text
FlexTrack Inspector (open in browser): http://127.0.0.1:7788
```

Open that address in a browser to inspect the live event list, tracker status, consent snapshot, and per-event JSON.

![FlexTrack Inspector dashboard with the flagship example app](docs/assets/inspector.gif)

```dart
import 'package:flex_track/flex_track_inspector.dart';
import 'package:flutter/foundation.dart';

// After FlexTrack.setup — e.g. in kDebugMode only:
if (kDebugMode) {
  final inspectorUrl = await FlexTrackInspector.start(port: 7788);
  if (inspectorUrl != null) {
    debugPrint('FlexTrack Inspector (open in browser): $inspectorUrl');
  }
}
```

See the flagship [`example/`](example/) app (`example/lib/utils/analytics_setup.dart`). On **Flutter Web**, `FlexTrackInspector.start` is a no-op (no embedded HTTP server).

---

**Print a summary** of registered trackers, consent state, and routing config:

```dart
FlexTrack.printDebugInfo();
```

**Dry-run an event** through the routing engine without sending it:

```dart
final result = FlexTrack.debugEvent(PurchaseEvent(amount: 9.99));
// Shows which rule matched, which trackers would receive the event,
// whether consent passes, and whether sampling would drop it.
```

**Validate** the routing config for common mistakes (unreachable rules, missing default, etc.):

```dart
final errors = FlexTrack.validate();
if (errors.isNotEmpty) {
  for (final e in errors) debugPrint('Config error: $e');
}
```

**ConsoleTracker options:**

`ConsoleTracker` is the only built-in tracker. It accepts a few options:

```dart
ConsoleTracker(
  showProperties: true,   // print event properties (default: true)
  showTimestamps: true,   // prefix with HH:mm:ss.ms (default: true)
  colorOutput: true,      // ANSI colours in terminal (default: true)
  prefix: '📊 Analytics', // default: '📊 FlexTrack'
)
```

Use it in production builds alongside your real trackers if you want a local audit log, or only include it conditionally:

```dart
await FlexTrack.setup([
  if (kDebugMode) ConsoleTracker(),
  FirebaseTracker(),
]);
```

---

## Testing

**Global singleton** (existing pattern): use `setupFlexTrackForTesting()` and `FlexTrack.reset()` in `tearDown`.

**Injectable client** (no global): create a `FlexTrackClient` with a `MockTracker`, pass it into your class under test, and call `await client.dispose()` in `tearDown`. See [docs/flex-track-client.md](docs/flex-track-client.md).

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  late MockTracker mock;

  setUp(() async {
    // Returns a MockTracker pre-wired to FlexTrack.
    // Consent checks and sampling are both disabled.
    mock = await setupFlexTrackForTesting();
  });

  tearDown(() async {
    // FlexTrack is a singleton — always reset between tests.
    await FlexTrack.reset();
  });

  test('tracks a purchase event', () async {
    await FlexTrack.track(PurchaseEvent(amount: 9.99));

    expect(mock.capturedEvents, hasLength(1));
    expect(mock.capturedEvents.single.getName(), 'purchase');
    expect(mock.capturedEvents.single.getProperties()['amount'], 9.99);
  });

  test('does not send event without consent', () async {
    // For consent tests, set up with a real routing config instead.
    await FlexTrack.reset();
    final customMock = MockTracker();
    await FlexTrack.setupWithRouting([customMock], (r) => r
      .routeDefault().toAll().requireConsent().and());

    FlexTrack.setConsent(general: false);
    await FlexTrack.track(PageViewEvent());

    expect(customMock.capturedEvents, isEmpty);
  });
}
```

`MockTracker` exposes:
- `capturedEvents` — `List<BaseEvent>` of every event that reached the tracker
- Use `mock.capturedEvents.single` when you expect exactly one event
- Use `mock.capturedEvents.where(...)` to filter by name or type

`setupFlexTrackForTesting()` disables consent checking and sampling so your assertions aren't affected by those concerns unless you're specifically testing them. For those cases, bypass it and set up manually as shown above.

---

## Common pitfalls

### 1. Calling track() before setup()

```dart
// ❌ Throws ConfigurationException — FlexTrack is not set up.
await FlexTrack.track(MyEvent());
```

```dart
// ✅ Always await setup() before tracking.
await FlexTrack.setup([ConsoleTracker(), FirebaseTracker()]);
await FlexTrack.track(MyEvent());
```

`FlexTrack.setup()` must complete before any call to `track()`, `setConsent()`, or other instance methods.

---

### 2. Forgetting FlexTrack.reset() between tests

```dart
// ❌ Second test throws 'FlexTrack is already set up'.
setUp(() async { await setupFlexTrackForTesting(); });
```

```dart
// ✅ Always reset in tearDown.
setUp(() async { mock = await setupFlexTrackForTesting(); });
tearDown(() async { await FlexTrack.reset(); });
```

FlexTrack is a singleton. Without `reset()`, `setup()` in the second test throws because the instance from the first test is still alive.

---

### 3. Unstable visibilityKey in FlexImpressionTrack

```dart
// ❌ Using list index as key — impression re-fires when items shift position.
FlexImpressionTrack(
  visibilityKey: ValueKey(index),   // wrong
  event: ProductImpressionEvent(product.id),
  child: ProductTile(product: product),
)
```

```dart
// ✅ Use a stable identifier tied to the content, not its position.
FlexImpressionTrack(
  visibilityKey: ValueKey(product.id),  // correct
  event: ProductImpressionEvent(product.id),
  child: ProductTile(product: product),
)
```

When the key changes, `FlexImpressionTrack` treats it as a new widget and fires another impression — even if the same product was already shown.

---

### 4. Missing .routeDefault() at the end of a routing config

```dart
// ❌ Events not matched by any rule are silently dropped.
await FlexTrack.setupWithRouting(trackers, (routing) => routing
  .routeCategory(EventCategory.business).toAll().and()
  .routeHighVolume().to(['firebase']).and()
  // No default — any other event is dropped.
);
```

```dart
// ✅ Always end with routeDefault().
await FlexTrack.setupWithRouting(trackers, (routing) => routing
  .routeCategory(EventCategory.business).toAll().and()
  .routeHighVolume().to(['firebase']).and()
  .routeDefault().toAll()  // catches everything else
);
```

Run `FlexTrack.validate()` during development — it will flag a missing default rule.

---

## Contributing and license

Source: [github.com/alirezat66/flex_track](https://github.com/alirezat66/flex_track)

Issues and pull requests are welcome. Please open an issue before starting large changes.

**License:** [MIT](https://github.com/alirezat66/flex_track/blob/main/LICENSE)


---

## Support

If this project helps you:

- ⭐ Star the repo
- 💬 Share feedback
- 🐛 Open issues
