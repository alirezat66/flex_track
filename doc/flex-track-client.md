# FlexTrackClient — injectable analytics

`FlexTrackClient` is the same routing engine and tracker registry as the global `FlexTrack` API, but as an **instance you create and pass explicitly**. Use it when you want:

- **Constructor injection** (Bloc `Cubit`, Riverpod `Provider`, etc.)
- **Tests without** `FlexTrack.reset()` and the global singleton
- **Multiple isolated configurations** in one process (rare; mostly for tests)

Global setup is unchanged: `await FlexTrack.setup([...])` still installs a default client; static methods like `FlexTrack.track` delegate to it. After setup, `FlexTrack.instance.client` is that underlying `FlexTrackClient`.

## Create a client

```dart
import 'package:flex_track/flex_track.dart';

final client = await FlexTrackClient.create(
  [ConsoleTracker(), FirebaseTracker()],
  routing: myRoutingConfig, // optional; defaults to smart defaults
);

await client.track(AppOpenedEvent());
```

With the routing builder (same pattern as `FlexTrack.setupWithRouting`):

```dart
final client = await FlexTrackClient.createWithRouting(
  [ConsoleTracker()],
  (b) {
    b.routeDefault().toAll();
    return b;
  },
);
```

Call `await client.dispose()` when you tear down (e.g. test `tearDown`) to flush trackers. Prefer **discarding** the client after dispose rather than reusing it.

## Domain layer and Riverpod

Keep **domain** free of Flutter UI, but it is normal for domain or application services to depend on a narrow **port** you define. Two styles:

1. **Port + adapter (recommended for strict clean architecture)**  
   Domain depends on `abstract class AnalyticsPort { Future<void> log(BaseEvent e); }`.  
   Infrastructure implements it with a wrapper that calls `FlexTrackClient.track`.

2. **Pass `FlexTrackClient` into application services**  
   Simpler; your “domain” types still depend on the `flex_track` package.

Example: **Riverpod** — provide the client once, read it where you run use cases (e.g. a `Notifier`, async callback, or service class constructed with `Ref`).

```dart
import 'package:flex_track/flex_track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flexTrackClientProvider = Provider<FlexTrackClient>((ref) {
  throw UnimplementedError('Override in ProviderScope (main / tests)');
});

// Anywhere you have a Ref (e.g. inside Notifier.build / methods):
Future<void> completePurchase(Ref ref) async {
  final analytics = ref.read(flexTrackClientProvider);
  await analytics.track(PurchaseCompletedEvent());
}
```

**App bootstrap** (after `WidgetsFlutterBinding.ensureInitialized()`):

```dart
final client = await FlexTrackClient.create([ConsoleTracker(), FirebaseTracker()]);

runApp(
  ProviderScope(
    overrides: [
      flexTrackClientProvider.overrideWithValue(client),
    ],
    child: const MyApp(),
  ),
);
```

**Tests:** override `flexTrackClientProvider` with `FlexTrackClient.create([MockTracker()], ...)`.

## Domain layer and Bloc / Cubit

Inject the client (or your `AnalyticsPort`) through the Cubit constructor.

```dart
import 'package:flex_track/flex_track.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._analytics) : super(const CartState());

  final FlexTrackClient _analytics;

  Future<void> checkout() async {
    await _analytics.track(CheckoutStartedEvent());
    // ...
  }
}

// Registration (e.g. with get_it, riverpod, or manual wiring):
// CartCubit(analyticsClient)
```

## Widgets: `FlexTrackScope` vs the global API

`FlexClickTrack`, `FlexImpressionTrack`, `FlexMountTrack`, and `FlexTrackRouteViewMixin` resolve events in this order:

1. **`FlexTrackScope.maybeOf(context)`** — if a `FlexTrackScope` ancestor provides a `FlexTrackClient`, that instance receives the event.
2. **Else `FlexTrack.track`** — if `FlexTrack.isSetUp` is true (after `FlexTrack.setup` / `quickSetup`).
3. **Else** — no-op (no throw).

So you can run **only** an injected `FlexTrackClient` (no `FlexTrack.setup`) as long as you wrap the relevant subtree:

```dart
FlexTrackScope(
  client: myClient,
  child: MyFeatureScreen(),
);
```

**Riverpod:** create the client in `main`, override a `Provider<FlexTrackClient>`, and wrap `MaterialApp`’s `home` (or a feature root) with `FlexTrackScope(client: ref.watch(...), child: ...)`. See `examples/riverpod_app`.

**Simplest app:** omit `FlexTrackScope`; call `FlexTrack.setup` once and widgets use the static API automatically.

**Explicit scope with the default client:** after `FlexTrack.setup`, you can still wrap with `FlexTrackScope(client: FlexTrack.instance.client, child: ...)` so the same instance is used both from scope and from `FlexTrack.track`. See `examples/static_app`.

## Relation to `FlexTrack.instance.client`

After `FlexTrack.setup`, the default client is `FlexTrack.instance.client`. Static methods on `FlexTrack` forward to that instance. You can migrate incrementally: keep `setup` for widgets, inject `FlexTrack.instance.client` into Cubits during migration, then switch to a separately created `FlexTrackClient` if you need stricter isolation.
