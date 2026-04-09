# Routing and rules

## Why FlexTrack

Without a router, “send purchases to Firebase and Mixpanel but debug taps only to console” becomes nested `if` statements at every call site. FlexTrack keeps **call sites** as `FlexTrack.track(event)` and moves **who receives what** into a single routing configuration you can test and evolve.

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Nested env/consent + destination     ║  One config: category, name regex,   ║
║  lists copied at every call site      ║  PII, env, sampling, rule priority    ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Opaque: wrong SDK got the event      ║  `FlexTrack.debugEvent` — see matched ║
║                                       ║  rules & tracker targets              ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

Details: [privacy-performance-debugging.md](privacy-performance-debugging.md).

Use [`FlexTrack.setupWithRouting`](../lib/src/core/flex_track.dart) when you need to send different events to different trackers, apply sampling, or respect consent per rule.

```dart
await FlexTrack.setupWithRouting([
  ConsoleTracker(),
  // ... trackers with stable ids, e.g. id: 'firebase', id: 'mixpanel'
], (routing) => routing
  .defineGroup('paid', ['mixpanel', 'custom_api'])
  .routeCategory(EventCategory.business)
  .toAll()
  .noSampling()
  .withPriority(20)
  .and()
  .routeCategory(EventCategory.user)
  .toGroupNamed('paid')
  .lightSampling()
  .withPriority(10)
  .and()
  .routeMatching(RegExp(r'debug_.*'))
  .to(['console'])
  .onlyInDebug()
  .and()
  .routeDefault()
  .toAll()
  .mediumSampling()
  .and());
```

The closure receives a fresh [`RoutingBuilder`](../lib/src/routing/routing_builder.dart). Chain rules, then return the builder (the last expression in a `=>` arrow function is the return value).

---

## Matching events

Common entry points on `RoutingBuilder`:

| Method | Use when |
|--------|----------|
| `route<T extends BaseEvent>()` | Match exact event type |
| `routeNamed(String pattern)` | Event name contains pattern |
| `routeMatching(RegExp pattern)` | Regex on event name |
| `routeExact(String name)` | Exact event name |
| `routeCategory(EventCategory c)` | Event category |
| `routeWithProperty(String key, [dynamic value])` | Property present (or equals value) |
| `routePII()` | `containsPII == true` |
| `routeHighVolume()` | `isHighVolume == true` |
| `routeEssential()` | `isEssential == true` |
| `routeDefault()` | Fallback for unmatched events |

---

## Targets and groups

- `toAll()` — every registered tracker.
- `to(['id1', 'id2'])` — specific tracker ids.
- `defineGroup('name', ['id', ...])` then `toGroupNamed('name')`.

---

## Rule modifiers ([`RoutingRuleBuilder`](../lib/src/routing/routing_rule_builder.dart))

- **Sampling**: `noSampling()`, `lightSampling()`, `mediumSampling()`, `heavySampling()`, `sample(0.25)`.
- **Consent**: `requireConsent()`, `skipConsent()`, `requirePIIConsent()`.
- **Environment**: `onlyInDebug()`, `onlyInProduction()`.
- **Priority**: `withPriority(n)` — higher runs first when ordering matters.
- **Metadata**: `withDescription('...')`, `withId('...')`.

End each rule with `.and()` to return to `RoutingBuilder` and start the next rule.

---

## Priority (overview)

Rules are evaluated with priority in mind: more specific or higher-priority rules should win over broad defaults. Put your **catch-all** `routeDefault()` **last** with a low priority so it does not swallow events meant for earlier rules.

---

## Builder-level toggles

On `RoutingBuilder`:

- `setSampling(bool)` — global sampling on/off.
- `setConsentChecking(bool)` — global consent checks on/off (useful in tests).
- `setDebugMode(bool)` — debug-oriented behavior where applicable.
- `applySmartDefaults()` — opinionated baseline rules (also used by [`setupFlexTrackWithDefaults`](../lib/flex_track.dart)).

---

## Further reading

- Source: [`routing_builder.dart`](../lib/src/routing/routing_builder.dart), [`route_config_builder.dart`](../lib/src/routing/route_config_builder.dart), [`routing_rule_builder.dart`](../lib/src/routing/routing_rule_builder.dart).
- Presets: [privacy-performance-debugging.md](privacy-performance-debugging.md) for `GDPRDefaults` and `PerformanceDefaults`.

---

Back to [package README](../README.md) · [Documentation index](README.md)
