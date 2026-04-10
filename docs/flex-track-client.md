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

## Widgets and the global API

`FlexClickTrack`, `FlexMountTrack`, and other widgets that call **`FlexTrack.track`** still expect the **global** singleton. If you only use `FlexTrackClient` and never call `FlexTrack.setup`, those widgets will throw until you either:

- Also call `FlexTrack.setup` with the same trackers, or
- Refactor widgets to accept an optional client (not part of the current public widgets API).

Practical approach: call **`FlexTrack.setup`** in `main` for production so widgets work, and still use **`FlexTrackClient`** in injected services **if** you create that client with the same configuration—or use the global API everywhere for simplicity.

## Relation to `FlexTrack.instance.client`

After `FlexTrack.setup`, the default client is `FlexTrack.instance.client`. Static methods on `FlexTrack` forward to that instance. You can migrate incrementally: keep `setup` for widgets, inject `FlexTrack.instance.client` into Cubits during migration, then switch to a separately created `FlexTrackClient` if you need stricter isolation.
