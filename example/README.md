# flex_track flagship example

This app demonstrates **routing**, **consent**, **multiple trackers** (implemented as **mocks** in this repo—no real Firebase/Mixpanel/Amplitude keys required), and **widget wrappers** (`FlexClickTrack`, `FlexMountTrack`, `FlexTrackRouteObserver` + `FlexTrackRouteViewMixin` on the home shell).

## Run locally

From the repository root:

```bash
cd example
flutter pub get
flutter run
```

On first launch you will see a **privacy / consent** dialog (backed by an in-memory mock store, not real `SharedPreferences` persistence across restarts in tests).

In **debug** mode on mobile or desktop, the app starts the **FlexTrack Inspector** (local HTTP dashboard). Watch the console for `FlexTrack Inspector (open in browser): http://127.0.0.1:7788` and open that URL to see live events and tracker state. (Not available on Flutter Web.)

## Integration test

```bash
cd example
flutter test integration_test
```

## Smaller samples

For minimal patterns without this full demo UI, see:

| Directory | Purpose |
| --------- | ------- |
| `examples/static_app` | Static `FlexTrack.*` API only |
| `examples/riverpod_app` | `FlexTrackClient` via Riverpod after `FlexTrack.setup` |
| `examples/bloc_getit_app` | `FlexTrackClient` in GetIt; `Cubit` calls `client.track` |

## Web build (also used for the docs “Live demo”)

```bash
cd example
flutter build web --base-href /flex_track/demo/
```

Output is `example/build/web/`. The documentation workflow copies this tree into `website/static/demo/` before deploying to GitHub Pages.
