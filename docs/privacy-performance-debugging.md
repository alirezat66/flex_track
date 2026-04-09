# Privacy, performance, and debugging

## Why FlexTrack

Consent, high-volume noise, and “why didn’t this fire?” are cross-cutting concerns. FlexTrack centralizes **consent state**, **sampling**, and **debug introspection** next to routing so you do not reimplement checks beside every SDK call.

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Each SDK checks consent its own way  ║  `FlexTrack.setConsent` + event flags ║
║                                       ║  + routing rules (one model)          ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  No insight into drops / routing      ║  `debugEvent`, `printDebugInfo`,     ║
║                                       ║  `validate`, `ConsoleTracker` opts    ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

## Consent

[`FlexTrack.setConsent`](../lib/src/core/flex_track.dart) (and related APIs on the active instance) drive whether events that **require** consent are delivered. Event-level flags on [`BaseEvent`](../lib/src/models/event/base_event.dart) include:

- `requiresConsent` — general consent (default `true` for many events).
- `containsPII` — used with PII-specific rules and `requirePIIConsent()` on rules.
- `isEssential` — can bypass normal restrictions when your routing rules allow it.

```dart
FlexTrack.setConsent(general: true, pii: false);
```

Inspect current flags with [`FlexTrack.getConsentStatus`](../lib/src/core/flex_track.dart).

---

## GDPR presets

[`GDPRDefaults.apply`](../lib/src/routing/presets/gdpr_defaults.dart) mutates a [`RoutingBuilder`](../lib/src/routing/routing_builder.dart) with opinionated rules (sensitive category, PII, user/marketing paths, etc.). Optional `compliantTrackers` defines a `gdpr_compliant` group for stricter destinations.

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  // your trackers...
], (routing) {
  GDPRDefaults.apply(routing, compliantTrackers: ['firebase', 'internal_api']);
  return routing;
});
```

For stricter templates, see `GDPRDefaults.applyStrict` in the same file.

---

## Performance presets

[`PerformanceDefaults.apply`](../lib/src/routing/presets/performance_defaults.dart) adds sampling-oriented rules for high-volume and UI-style event names. Variants such as `applyMobileOptimized` / `applyWebOptimized` / `applyServerOptimized` tune the same idea for different platforms (see source for details).

Use together with routing: call `apply` **before** or **after** your custom rules depending on whether you want your rules to override defaults (always validate with [`FlexTrack.debugEvent`](../lib/src/core/flex_track.dart) if unsure).

---

## Batching

[`FlexTrack.trackAll`](../lib/src/core/flex_track.dart) accepts a list of events for batch-oriented processing through the pipeline (see API docs for exact behavior).

---

## Debugging

- [`FlexTrack.printDebugInfo`](../lib/src/core/flex_track.dart) / `getDebugInfo` — snapshot of setup and processor state.
- [`FlexTrack.debugEvent(BaseEvent)`](../lib/src/core/flex_track.dart) — see which rules matched and which trackers would receive the event.
- [`FlexTrack.validate`](../lib/src/core/flex_track.dart) — configuration warnings.
- [`ConsoleTracker`](../lib/src/strategies/built_in/console_tracker.dart) — constructor options such as `showProperties`, `showTimestamps`, `colorOutput`, `prefix`.

---

## Event categories

[`EventCategory`](../lib/src/models/routing/event_category.dart) provides shared buckets (`business`, `user`, `technical`, `sensitive`, `marketing`, `system`, …). They are optional on `BaseEvent` but unlock category-based routing and presets.

---

Back to [package README](../README.md) · [Documentation index](README.md)
