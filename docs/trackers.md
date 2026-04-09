# Trackers — destinations for your events

## Why FlexTrack

You keep **one** call site (`FlexTrack.track`) in features and widgets. **Trackers** are the only place that talk to Firebase, Mixpanel, your REST API, or the debug console. That keeps vendor SDKs out of the `flex_track` package (your `pubspec` only includes what you use) and makes it obvious where to add keys, retries, and formatting.

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  SDK imports & `if (kDebugMode)` /    ║  Register trackers once; events flow ║
║  consent checks duplicated per screen ║  through one pipeline                 ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Second backend → touch every call    ║  Add a tracker + optional routing    ║
║  site                                 ║  — call sites stay unchanged          ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

See [routing and rules](routing-and-rules.md) for per-event destinations.

FlexTrack does **not** ship Firebase, Mixpanel, or Amplitude as dependencies. You add the SDKs you need to **your app** and implement one small class per backend by extending [`BaseTrackerStrategy`](../lib/src/strategies/base_tracker_strategy.dart).

**Why this is a feature**

- Your `pubspec` stays free of analytics SDKs you do not use.
- You control initialization order, API keys, and error handling.
- The same `FlexTrack.track(MyEvent())` call can fan out to zero, one, or many trackers depending on [`setup` / `setupWithRouting`](../lib/src/core/flex_track.dart).

**Starting point**

The [example](../example/) package includes illustrative trackers (some are mocks without real SDK calls) under `example/lib/trackers/`. Copy them into your app and replace `doInitialize` / `doTrack` with real SDK usage.

---

## Register multiple trackers

Each tracker must have a **unique `id`** (passed to `super(id: ..., name: ...)`). Those ids are used in routing rules (e.g. `.to(['firebase', 'console'])`).

```dart
await FlexTrack.setup([
  ConsoleTracker(),
  FirebaseTracker(), // your subclass
  MixpanelTracker(token: '...'), // your subclass
]);
```

With default routing (`FlexTrack.setup` without a custom `RoutingConfiguration`), the package uses [`RoutingConfiguration.withSmartDefaults()`](../lib/src/models/routing/routing_config.dart) so events still flow sensibly. For explicit control, use [`FlexTrack.setupWithRouting`](../lib/src/core/flex_track.dart) — see [routing-and-rules.md](routing-and-rules.md).

---

## Convenience setup

From the main library export:

- [`setupFlexTrack`](../lib/flex_track.dart) — alias for `FlexTrack.setup`.
- [`setupFlexTrackWithDefaults`](../lib/flex_track.dart) — `setupWithRouting` + `applySmartDefaults()` on the builder.
- [`setupFlexTrackForDevelopment`](../lib/flex_track.dart) — console tracker + debug-friendly routing.

---

## Example: Firebase-shaped tracker

The following pattern matches what many apps do: wrap `FirebaseAnalytics.logEvent` inside `doTrack`. **This is not built into the package** — adapt names and parameter mapping to your app.

```dart
import 'package:flex_track/flex_track.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseTracker extends BaseTrackerStrategy {
  FirebaseTracker() : super(id: 'firebase', name: 'Firebase Analytics');

  // late final FirebaseAnalytics _analytics;

  @override
  bool get isGDPRCompliant => true;

  @override
  Future<void> doInitialize() async {
    // _analytics = FirebaseAnalytics.instance;
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // await _analytics.logEvent(
    //   name: event.getName(),
    //   parameters: _firebaseParams(event.getProperties()),
    // );
  }
}
```

---

## Example: Mixpanel-shaped tracker

Same idea: implement `doTrack` to call Mixpanel’s API with `event.getName()` and `event.getProperties()`.

```dart
import 'package:flex_track/flex_track.dart';
// import 'package:mixpanel_flutter/mixpanel_flutter.dart';

class MixpanelTracker extends BaseTrackerStrategy {
  MixpanelTracker({required String token})
      : _token = token,
        super(id: 'mixpanel', name: 'Mixpanel');

  final String _token;
  // late Mixpanel _mixpanel;

  @override
  Future<void> doInitialize() async {
    // _mixpanel = await Mixpanel.init(_token, trackAutomaticEvents: false);
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // _mixpanel.track(event.getName(), properties: event.getProperties());
  }
}
```

---

## Example: HTTP / custom API tracker

Use `dart:convert` and `package:http/http.dart` in **your** app (not in `flex_track` itself) to POST JSON payloads built from `BaseEvent`.

---

## Mental model

| Layer | Responsibility |
|-------|----------------|
| Your widgets / services | Call `FlexTrack.track(event)` |
| `FlexTrack` | Routing, consent checks, sampling (when configured) |
| Your `BaseTrackerStrategy` subclasses | Talk to Firebase, Mixpanel, your server, files, etc. |

One line in product code can still mean “send to many backends” — the **adapters** live in one place instead of being scattered across the app.

---

Back to [package README](../README.md) · [Documentation index](README.md)
