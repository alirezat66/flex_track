# flex_track

Analytics routing for Flutter: register **trackers** you implement, send **typed events** from one API, optionally **route** by category/consent/sampling/environment. Includes **widget wrappers** for taps, impressions, mount, and route lifecycle.

The package **does not** bundle Firebase, Mixpanel, or other vendor SDKs. You extend [`BaseTrackerStrategy`](lib/src/strategies/base_tracker_strategy.dart) — no hidden dependencies, no SDK version fights inside this library.

---

## Quick start

Four steps. **`MyFirebaseTracker`** and **`MyEvent`** are **your** classes. Only [`ConsoleTracker`](lib/src/strategies/built_in/console_tracker.dart) and [`MockTracker`](lib/src/strategies/built_in/mock_tracker.dart) ship with the package as ready-made trackers.

```dart
// 1) pubspec.yaml
//    dependencies:
//      flex_track: ^1.0.0
//      # firebase_core / firebase_analytics — only if you use Firebase below

import 'package:flex_track/flex_track.dart';
import 'package:flutter/widgets.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

/// 2) Your tracker — not part of flex_track.
class MyFirebaseTracker extends BaseTrackerStrategy {
  MyFirebaseTracker() : super(id: 'firebase', name: 'My Firebase');

  @override
  Future<void> doInitialize() async {
    // await Firebase.initializeApp();
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // await FirebaseAnalytics.instance.logEvent(name: event.getName());
  }
}

class MyEvent extends BaseEvent {
  @override
  String getName() => 'example';

  @override
  Map<String, Object>? getProperties() => const {};
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3) Setup — pass every tracker instance you implemented
  await FlexTrack.setup([ConsoleTracker(), MyFirebaseTracker()]);

  // 4) Track
  await FlexTrack.track(MyEvent());

  runApp(const SizedBox.shrink());
}
```

**No Firebase yet?** Drop `MyFirebaseTracker` and use `await FlexTrack.setup([ConsoleTracker()]);` — events appear in the debug console.

---

## Table of contents

- [Quick start](#quick-start)
- [What you get](#what-you-get)
- [Bring your own tracker](#bring-your-own-tracker)
- [Events](#events)
- [Setup and routing](#setup-and-routing)
- [Consent](#consent)
- [Widget wrappers](#widget-wrappers)
- [Testing](#testing)
- [Debugging](#debugging)
- [Further reading](#further-reading)
- [Reference — routing DSL](#reference--routing-dsl)
- [License](#license)

---

## What you get

- **One call site** in features: `FlexTrack.track(MyEvent())`.
- **Pluggable backends**: each tracker is a class you own (`BaseTrackerStrategy`).
- **Optional routing**: send different events to different trackers, with sampling and consent rules.
- **Flutter helpers**: [`FlexClickTrack`](#flexclicktrack), [`FlexImpressionTrack`](#fleximpressiontrack), [`FlexMountTrack`](#flexmounttrack), [`FlexTrackRouteViewMixin`](#flextrackrouteviewmixin) + [`FlexTrackRouteObserver`](lib/src/widgets/flex_route_track.dart).

Built-in tracker implementations in this repo: **`ConsoleTracker`**, **`MockTracker`**, **`NoOpTracker`**. Anything named like a product (Firebase, Mixpanel, …) is **your** code or lives under [`example/`](example/) as a sample.

---

## Bring your own tracker

This is intentional:

| Benefit | Why it matters |
|--------|----------------|
| No transitive analytics SDKs | Your `pubspec` only contains SDKs you chose |
| You control init, keys, errors | No magic global Firebase init inside `flex_track` |
| Same `track()` everywhere | Adapters live in one layer, not scattered across widgets |

Implement `doInitialize` and `doTrack`. Use a stable **`id`** — routing rules refer to it (e.g. `.to(['firebase'])` matches `super(id: 'firebase', ...)`.

**Example — Mixpanel-shaped (pseudo; add `mixpanel_flutter` in your app):**

```dart
class MyMixpanelTracker extends BaseTrackerStrategy {
  MyMixpanelTracker() : super(id: 'mixpanel', name: 'My Mixpanel');

  @override
  Future<void> doInitialize() async {
    // await Mixpanel.init('YOUR_TOKEN', trackAutomaticEvents: false);
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // _mixpanel.track(event.getName(), properties: event.getProperties());
  }
}
```

Copy longer samples from [`example/lib/trackers/`](example/lib/trackers/) — they are **not** exported by the package.

---

## Events

Subclasses of [`BaseEvent`](lib/src/models/event/base_event.dart) define name, properties, and optional hints for routing/consent.

```dart
class PurchaseEvent extends BaseEvent {
  PurchaseEvent({required this.amount});

  final double amount;

  @override
  String getName() => 'purchase';

  @override
  Map<String, Object>? getProperties() => {'amount': amount};

  @override
  EventCategory? get category => EventCategory.business;

  @override
  bool get isEssential => true;

  @override
  bool get containsPII => false;
}
```

**Batch:**

```dart
await FlexTrack.trackAll([PurchaseEvent(amount: 9.99), OtherEvent()]);
```

Useful flags (all optional except `getName` / `getProperties`): `category`, `containsPII`, `requiresConsent`, `isEssential`, `isHighVolume`, etc. Routing rules can match on these — see [routing doc](docs/routing-and-rules.md).

---

## Setup and routing

**Simple setup** (uses default routing configuration):

```dart
await FlexTrack.setup([
  ConsoleTracker(),
  MyFirebaseTracker(),
  // MyMixpanelTracker(), // any other BaseTrackerStrategy you implemented
]);
```

**Custom routing** — last rule should end with `.and()` so the builder returns a [`RoutingBuilder`](lib/src/routing/routing_builder.dart):

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  MyFirebaseTracker(), // id: 'firebase'
], (routing) => routing
    .routeCategory(EventCategory.business)
    .toAll()
    .noSampling()
    .and()
    .routeHighVolume()
    .to(['firebase'])
    .heavySampling()
    .and()
    .routeDefault()
    .toAll()
    .and());
```

Details and presets (`GDPRDefaults`, `PerformanceDefaults`, `applySmartDefaults`): [docs/routing-and-rules.md](docs/routing-and-rules.md), [docs/privacy-performance-debugging.md](docs/privacy-performance-debugging.md).

---

## Consent

```dart
FlexTrack.setConsent(general: true, pii: false);
```

How this interacts with rules and event flags: [docs/privacy-performance-debugging.md](docs/privacy-performance-debugging.md).

---

## Widget wrappers

Declarative UI tracking; each wrapper calls `FlexTrack.track` when appropriate. If `FlexTrack` was never set up, these no-op safely.

### FlexClickTrack

Completes a **tap** (short press, movement within [`kTouchSlop`](https://api.flutter.dev/flutter/gestures/kTouchSlop-constant.html)). Uses a [`Listener`](https://api.flutter.dev/flutter/widgets/Listener-class.html) with [`HitTestBehavior.translucent`](https://api.flutter.dev/flutter/rendering/HitTestBehavior.html) so nested [`InkWell`](https://api.flutter.dev/flutter/material/InkWell-class.html)s and buttons still receive gestures; drags/scrolls do not fire the analytics event.

```dart
FlexClickTrack(
  event: MyButtonTapEvent(),
  child: IconButton(icon: const Icon(Icons.share), onPressed: () {}),
)
```

### FlexImpressionTrack

Uses [`visibility_detector`](https://pub.dev/packages/visibility_detector) (dependency of `flex_track`). Requires a **stable** [`visibilityKey`](https://api.flutter.dev/flutter/widgets/Key-class.html) per logical slot (e.g. list item id).

```dart
FlexImpressionTrack(
  visibilityKey: const ValueKey('home_banner'),
  event: BannerImpressionEvent(),
  visibleFractionThreshold: 0.5,
  minVisibleDuration: const Duration(milliseconds: 300),
  fireOnce: true,
  child: const BannerAd(),
)
```

### FlexMountTrack

Fires **once** after the first frame the widget is laid out. **Not** the same as “user saw it” (off-screen build, hidden tabs, etc.). Prefer `FlexImpressionTrack` or route mixin when visibility matters.

```dart
FlexMountTrack(
  event: LazyRowMountedEvent(),
  child: const ProductTile(),
)
```

### FlexTrackRouteViewMixin

Mixin on [`State`](https://api.flutter.dev/flutter/widgets/State-class.html) for a screen backed by a [`PageRoute`](https://api.flutter.dev/flutter/widgets/PageRoute-class.html). Register a single [`FlexTrackRouteObserver`](lib/src/widgets/flex_route_track.dart) on `MaterialApp.navigatorObservers`.

```dart
final _routeObserver = FlexTrackRouteObserver();

// MaterialApp(navigatorObservers: [_routeObserver], ...)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with FlexTrackRouteViewMixin {
  @override
  FlexTrackRouteObserver get flexTrackRouteObserver => _routeObserver;

  @override
  BaseEvent get routeViewEvent => HomeViewedEvent();

  /// Default is false — set true if you want a new view event when popping back from a child route.
  @override
  bool get trackWhenReturningFromChildRoute => false;

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}
```

Full behavior and tests: [docs/widgets.md](docs/widgets.md).

---

## Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

void main() {
  test('captures event', () async {
    final mock = await setupFlexTrackForTesting();
    await FlexTrack.track(MyEvent());
    expect(mock.capturedEvents.single.getName(), 'example');
  });
}
```

`setupFlexTrackForTesting` turns off consent checks and sampling for predictable assertions. Reconfigure or call [`FlexTrack.reset`](lib/src/core/flex_track.dart) between tests if needed. More: [docs/testing-and-troubleshooting.md](docs/testing-and-troubleshooting.md).

---

## Debugging

```dart
FlexTrack.printDebugInfo();
FlexTrack.debugEvent(myEvent);
FlexTrack.validate();
```

[`ConsoleTracker`](lib/src/strategies/built_in/console_tracker.dart) accepts options such as `showProperties`, `colorOutput`, `prefix`.

---

## Further reading

| Topic | Location |
|-------|----------|
| Multiple trackers, mental model | [docs/trackers.md](docs/trackers.md) |
| Routing rules, priority, groups | [docs/routing-and-rules.md](docs/routing-and-rules.md) |
| GDPR/performance presets, consent detail | [docs/privacy-performance-debugging.md](docs/privacy-performance-debugging.md) |
| Widget semantics, widget tests | [docs/widgets.md](docs/widgets.md) |
| Pitfalls, migration | [docs/testing-and-troubleshooting.md](docs/testing-and-troubleshooting.md) |
| Doc index | [docs/README.md](docs/README.md) |
| Runnable app + sample trackers | [example/](example/) |

**API entrypoint:** [`package:flex_track/flex_track.dart`](lib/flex_track.dart).

---

## Reference — routing DSL

Matchers (on [`RoutingBuilder`](lib/src/routing/routing_builder.dart)):

- `.route<T extends BaseEvent>()` — by event type
- `.routeNamed('substring')` — name contains pattern
- `.routeMatching(RegExp(...))`
- `.routeExact('name')`
- `.routeCategory(EventCategory.business)` — values: `business`, `user`, `technical`, `sensitive`, `marketing`, `system`
- `.routeWithProperty('key')` / `.routeWithProperty('key', value)`
- `.routeEssential()` / `.routeHighVolume()` / `.routePII()`
- `.routeDefault()` — catch-all (usually last)

Targets:

- `.toAll()` / `.to(['id1', 'id2'])` / `.toGroupNamed('name')` / `.toDevelopment()`

Modifiers (chain before `.and()`):

- Sampling: `.noSampling()`, `.lightSampling()`, `.mediumSampling()`, `.heavySampling()`, `.sample(0.25)`
- Consent: `.requireConsent()`, `.requirePIIConsent()`, `.skipConsent()`
- Environment: `.onlyInDebug()`, `.onlyInProduction()`
- `.withPriority(20)`, `.withDescription('...')`
- `.and()` — finish rule and continue building

---

## Contributing / license

**Repository:** [github.com/alirezat66/flex_track](https://github.com/alirezat66/flex_track)

**License:** [LICENSE](LICENSE)
