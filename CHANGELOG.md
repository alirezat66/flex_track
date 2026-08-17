# 2.1.0 (2026-08-17)

## Added

- Published the versioned, language-neutral FlexTrack Core MVP specification
  shared by the Flutter and Kotlin implementations.
- Added versioned JSON conformance fixtures, a Flutter runner and report, and
  the Kotlin runner contract for cross-SDK behavior parity.

## Fixed

- Type-based routing now matches event subclasses and preserves the original
  routing identity through `EnrichedEvent` transformers. Other routing
  conditions still evaluate the transformed event.
- Replaced clock-modulo routing sampling with deterministic FNV-1a sampling
  keyed by user id, session id, or event name. Essential events bypass
  sampling, and published UTF-8 vectors keep future SDK implementations in
  parity.
- Event instances now capture an immutable UUID v4 identifier and UTC
  occurrence timestamp. Enrichment preserves both values.
- New clients now start with general and PII consent denied, matching the
  documented privacy-safe default. Disabling consent checking on a routing
  configuration now bypasses those checks as configured.
- `flexTrackVersion` now matches the package version declared in `pubspec.yaml`.

## 2.0.0

### Breaking changes

`BaseEvent.getName()` and `BaseEvent.getProperties()` have been removed. Event implementations must now override the `name` and `properties` getters.

Before:

```dart
class PurchaseEvent extends BaseEvent {
  @override
  String getName() => 'purchase';

  @override
  Map<String, Object>? getProperties() => {'amount': 29.99};
}
```

After:

```dart
class PurchaseEvent extends BaseEvent {
  @override
  String get name => 'purchase';

  @override
  Map<String, Object>? get properties => {'amount': 29.99};
}
```

### Added

* Add an `EventTransformer` pipeline for enriching and normalizing events before routing and dispatch.
* Add `EnrichedEvent` for layering additional properties onto an event while preserving its routing, consent, and privacy metadata.
* Add support for custom event categories and subcategories.
* Add the interactive FlexTrack guide at [flextrack.taghizadeh.dev](https://flextrack.taghizadeh.dev/).

### Changed

* Replace `BaseEvent.getName()` and `BaseEvent.getProperties()` with the `BaseEvent.name` and `BaseEvent.properties` getter API.
* Update examples, tests, and documentation to use the getter API.

### Fixed

* Align transformer signatures around `BaseEvent` so transformed events flow consistently through clients, widgets, routing, and trackers.

---

## 1.0.1

* Improve package presentation and pub.dev listing metadata.
* Add screenshot entries in `pubspec.yaml` for logo and banner assets.
* README improvements and image path fixes for inspector demo rendering.

---

## 1.0.0

This release promotes the package to **1.0.0** and focuses on **injectable analytics**, **widget ergonomics**, **local debugging**, and **documentation**.

### New features

* **`FlexTrackScope`** — `InheritedWidget` that provides a `FlexTrackClient` to descendant widgets. `FlexClickTrack`, `FlexImpressionTrack`, `FlexMountTrack`, and `FlexTrackRouteViewMixin` resolve the client in order: scoped client → `FlexTrack.track` (if set up) → no-op.
* **Shared widget dispatch** — `dispatchFlexTrackWidgetTrack` centralizes scoped/global dispatch and `FlutterError` reporting (`FlexTrackWidgetSurface` for stable error labels).
* **`FlexTrackClient`** — create and own a client with `FlexTrackClient.create` / `createWithRouting`; optional `eventDispatchStream` / `debugStateStream` in debug for tooling.
* **FlexTrack Inspector** (IO platforms) — optional `package:flex_track/flex_track_inspector.dart` starts a local dashboard (default port **7788**); console logs `FlexTrack Inspector (open in browser): http://127.0.0.1:7788`. No-op on Flutter Web.

### Widgets & examples

* **Examples** — `examples/static_app` (`FlexTrackScope` with `FlexTrack.instance.client`), `examples/riverpod_app` (scoped client without global `setup`), `examples/bloc_getit_app`, flagship `example/` with inspector wiring in debug.
* **Tests** — expanded coverage for clients, trackers, routing presets, inspector helpers, and **scope vs global** behavior for all tracking widgets.

### Documentation

* README: `FlexTrackClient`, `FlexTrackScope`, inspector section, table of contents.
* **`doc/flex-track-client.md`** — injectable client, Riverpod/Bloc, widget scope behavior.
* **`doc/assets/inspector.gif`** — demo of the inspector with the flagship app.

---

## 0.1.1

* Documentation updates based on community feedback.

---

## 0.1.0

* Initial release on pub.dev.
* Intelligent event routing, GDPR-oriented helpers, built-in trackers (Console, NoOp, Mock), performance presets, and debugging APIs.
