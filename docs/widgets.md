# Widget wrappers — UI analytics

## Why FlexTrack

UI analytics often ends up as copy-pasted `onTap` handlers, inconsistent event names, and scroll gestures mistaken for taps. FlexTrack’s widgets centralize **when** to call `FlexTrack.track` and align with the same **`BaseEvent`** types you use elsewhere, so console output, routing, and tests stay consistent.

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  `track()` or SDK calls in every      ║  One wrapper: `FlexClickTrack`,       ║
║  `onTap` / homemade visibility hack   ║  impression, mount, or route mixin    ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  “Fire on build” ≠ user saw it        ║  `FlexImpressionTrack`: visible       ║
║                                       ║  fraction + optional min duration     ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Screen views in `initState` — easy   ║  `FlexTrackRouteViewMixin` follows   ║
║  to double-fire on rebuild            ║  `PageRoute` / `RouteAware` lifecycle ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

Sources: [`flex_click_track.dart`](../lib/src/widgets/flex_click_track.dart), [`flex_impression_track.dart`](../lib/src/widgets/flex_impression_track.dart), [`flex_mount_track.dart`](../lib/src/widgets/flex_mount_track.dart), [`flex_route_track.dart`](../lib/src/widgets/flex_route_track.dart). The package depends on `visibility_detector` (see [pubspec.yaml](../pubspec.yaml)).

---

## `FlexClickTrack`

Wraps `child` and tracks when the user completes a **tap** in the hit region (short press, little movement). Drags and scrolls are ignored via touch slop, and `HitTestBehavior.translucent` keeps nested `InkWell` / buttons working.

All widgets early-out if [`FlexTrack.isSetUp`](../lib/src/core/flex_track.dart) is false.

```dart
class PayTapEvent extends BaseEvent {
  @override
  String getName() => 'pay_tap';
  @override
  Map<String, Object>? getProperties() => const {'surface': 'checkout'};
}

FlexClickTrack(
  event: PayTapEvent(),
  child: const Text('Pay'), // or wrap your button
)
```

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  `onTap: () { track(); … }` on every  ║  `FlexClickTrack` — tap vs scroll     ║
║  widget                               ║  handled consistently                 ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

---

## `FlexImpressionTrack`

Tracks when `child` is **visible** in the viewport (lists, scroll views).

**Policy** (see class dartdoc for details):

- **`visibleFractionThreshold`**: `VisibilityInfo.visibleFraction` must reach at least this value (default `0.5`).
- **`minVisibleDuration`**: if set, the fraction must stay at or above the threshold for at least this long; leaving view resets the timer.
- **`fireOnce`**: default `true` — at most one impression per state instance; set `false` to allow refires after visibility drops and meets again.
- **`visibilityKey`**: stable for the same logical slot (e.g. list item id).

```dart
class PromoSeenEvent extends BaseEvent {
  @override
  String getName() => 'promo_impression';
  @override
  Map<String, Object>? getProperties() => const {'placement': 'home_banner'};
}

FlexImpressionTrack(
  visibilityKey: const ValueKey('promo_banner'),
  event: PromoSeenEvent(),
  minVisibleDuration: const Duration(milliseconds: 400),
  child: const SizedBox(height: 80, child: Placeholder()),
)
```

(`ValueKey` — `package:flutter/foundation.dart`; `Placeholder` — `package:flutter/widgets.dart`.)

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Impression in `build` / first frame  ║  Threshold + optional min duration — ║
║  counts off-screen & hidden tabs      ║  closer to “meaningfully visible”      ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

---

## `FlexMountTrack`

Fires **once** after the first frame where the widget is laid out. It does **not** mean the user saw the widget (off-screen subtrees, hidden tabs, backgrounded apps). Prefer **`FlexImpressionTrack`** or route-level tracking when “visible on screen” or “screen shown” matters.

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  `addPostFrameCallback` + guards on   ║  `FlexMountTrack` — same `BaseEvent`  ║
║  many screens                         ║  pipeline as the rest of the app     ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

---

## `FlexTrackRouteObserver` and `FlexTrackRouteViewMixin`

Register **one** [`FlexTrackRouteObserver`](../lib/src/widgets/flex_route_track.dart) on `MaterialApp.navigatorObservers` / `CupertinoApp`. On a `State` class for a screen backed by a `PageRoute`, mix in `FlexTrackRouteViewMixin` and implement:

- `FlexTrackRouteObserver get flexTrackRouteObserver`
- `BaseEvent get routeViewEvent`

**Semantics:**

- **`trackOnInitialPush`** (default `true`): track when the route first becomes current (including a post-frame fallback for `home` routes that never get `didPush`).
- **`trackWhenReturningFromChildRoute`** (default **`false`**): when `true`, tracks again on `didPopNext`. **`didPushNext` / `didPop` do not send events.**

```dart
final flexRouteObserver = FlexTrackRouteObserver();

MaterialApp(
  navigatorObservers: [flexRouteObserver],
  home: const HomeScreen(),
);
```

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Re-track on rebuild or miss `home`   ║  `FlexTrackRouteViewMixin` +          ║
║  route edge cases                     ║  `RouteAware`; explicit return flags   ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

---

## Widget tests and `FlexImpressionTrack`

In tests, the visibility pipeline may need explicit updates. See [`test/widgets/flex_impression_track_test.dart`](../test/widgets/flex_impression_track_test.dart) for patterns such as `VisibilityDetectorController.instance.notifyNow()` after layout or scroll.

---

## See also

- [Testing and troubleshooting](testing-and-troubleshooting.md) — `setupFlexTrackForTesting`, `FlexTrack.reset`
- [Routing and rules](routing-and-rules.md) — if UI events use `EventCategory` for routing

Back to [package README](../README.md) · [Documentation index](README.md)
