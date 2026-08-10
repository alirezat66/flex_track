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
* **`docs/flex-track-client.md`** — injectable client, Riverpod/Bloc, widget scope behavior.
* **`docs/assets/inspector.gif`** — demo of the inspector with the flagship app.

---

## 0.1.1

* Documentation updates based on community feedback.

---

## 0.1.0

* Initial release on pub.dev.
* Intelligent event routing, GDPR-oriented helpers, built-in trackers (Console, NoOp, Mock), performance presets, and debugging APIs.
