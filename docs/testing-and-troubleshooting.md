# Testing and troubleshooting

## Why FlexTrack

Analytics code is hard to test when every screen calls a static SDK. FlexTrack’s **`setupFlexTrackForTesting`** + **`MockTracker`** let you assert on the same **`BaseEvent`** instances your production code emits, without touching real networks.

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Skip analytics tests or mock each    ║  One `setupFlexTrackForTesting`;     ║
║  vendor SDK per screen                ║  assert `mockTracker.capturedEvents`   ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Flaky widget tests from side-effect  ║  Consent/sampling off in test setup; ║
║  tracking                             ║  `FlexTrack.reset` between cases       ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

The package repo’s **`test/`** tree covers core (`flex_track`, processor, registry), routing (builders, engine, GDPR/smart/performance presets), widgets (`flex_*_track_test.dart`), strategies, context/consent models, and exceptions — useful as executable examples.

## Tests

[`setupFlexTrackForTesting`](../lib/flex_track.dart) configures FlexTrack with a [`MockTracker`](../lib/src/strategies/built_in/mock_tracker.dart), consent checking off, sampling off, and a default `.routeDefault().toAll()` rule. It returns the mock so assertions can inspect `capturedEvents`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_track/flex_track.dart';

class SignupCompletedEvent extends BaseEvent {
  SignupCompletedEvent({required this.method});
  final String method;

  @override
  String getName() => 'signup_completed';

  @override
  Map<String, Object>? getProperties() => {'method': method};
}

void main() {
  test('tracks signup', () async {
    final mock = await setupFlexTrackForTesting();

    await FlexTrack.track(SignupCompletedEvent(method: 'email'));

    expect(mock.capturedEvents, hasLength(1));
    expect(mock.capturedEvents.single.getName(), 'signup_completed');
  });
}
```

For widget tests that use `FlexImpressionTrack`, configure `VisibilityDetectorController` as in the package tests under `test/widgets/`.

Teardown: if tests re-run setup, call [`FlexTrack.reset`](../lib/src/core/flex_track.dart) where appropriate (see existing tests in `test/`).

---

## Common issues

### Nothing is logged

- Ensure [`FlexTrack.setup`](../lib/src/core/flex_track.dart) completed **before** any `track` call.
- Check [`FlexTrack.isSetUp`](../lib/src/core/flex_track.dart) and that routing does not drop the event (use `debugEvent`).
- Verify trackers are enabled and consent flags allow delivery.

### Events blocked “because of consent”

- Set consent with `FlexTrack.setConsent` or disable consent checking in tests via routing builder `setConsentChecking(false)`.
- Mark events `isEssential` or adjust rules **only** when that matches your privacy policy.

### Routing surprises

- Specific rules should appear **before** broad `routeDefault()` and usually with **higher** `withPriority`.
- Use `FlexTrack.debugEvent(yourEvent)` to see applied vs skipped rules.

### Widget wrappers do nothing

- [`FlexClickTrack`](../lib/src/widgets/flex_click_track.dart) / [`FlexMountTrack`](../lib/src/widgets/flex_mount_track.dart) / [`FlexImpressionTrack`](../lib/src/widgets/flex_impression_track.dart) early-out if FlexTrack is not set up (`FlexTrack.isSetUp`).

---

## Migrating from direct SDK calls

1. Introduce `FlexTrack.setup([ConsoleTracker(), ...])` in `main`.
2. For each raw `FirebaseAnalytics.instance.logEvent` (or similar), define a `BaseEvent` and replace with `FlexTrack.track`.
3. Move SDK calls into tracker subclasses so screens stay free of vendor imports.
4. Add `setupWithRouting` when you need per-event or per-category destinations.

---

## More examples

The repository `test/` directory contains unit and widget tests that exercise routing, consent, and widgets. Use them as executable documentation.

---

Back to [package README](../README.md) · [Documentation index](README.md)
