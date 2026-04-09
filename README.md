# FlexTrack

> **Typed analytics for Flutter** — call `FlexTrack.track` with `BaseEvent` objects; **trackers** you register receive them. Optional **routing** and **widgets** keep analytics out of business logic without scattering SDK calls.

The package is **vendor-neutral** (no Firebase/Mixpanel in this package). Add SDKs in your app and plug them in via [`BaseTrackerStrategy`](lib/src/strategies/base_tracker_strategy.dart). Starters: [example](example/).

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  `print` / SDK calls spread across    ║  One pipeline: `FlexTrack.track` →    ║
║  widgets and services                 ║  trackers + optional routing rules    ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Different strings & map shapes per   ║  Shared `BaseEvent`: `getName()` +    ║
║  screen                               ║  `getProperties()` everywhere         ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

**Architecture at a glance** — screens stay the same; either every screen talks to every SDK, or every screen calls **one API** (`FlexTrack.track`) and FlexTrack routes to the **trackers you register**. The built-in [`ConsoleTracker`](lib/src/strategies/built_in/console_tracker.dart) is the usual choice in **debug** (readable logs); Firebase, Mixpanel, etc. are **examples** of extra adapters you add in your app, not dependencies of this package.

<table>
<tr valign="top">
<td>

<pre>
TRADITIONAL APPROACH (Manual Management)
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Login     │    │  Purchase   │    │  Page View  │
│   Screen    │    │   Screen    │    │   Screen    │
└─────┬───────┘    └─────┬───────┘    └─────┬───────┘
      │                  │                  │
      ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────┐
│           DUPLICATE CODE EVERYWHERE                 │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────┐  │
│  │Firebase │ │Mixpanel │ │Amplitude│ │Custom API│  │
│  └─────────┘ └─────────┘ └─────────┘ └──────────┘  │
└─────────────────────────────────────────────────────┘
</pre>

</td>
<td width="20"></td>
<td>

<pre>
FLEXTRACK APPROACH (Centralized Management)
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Login     │    │  Purchase   │    │  Page View  │
│   Screen    │    │   Screen    │    │   Screen    │
└─────┬───────┘    └─────┬───────┘    └─────┬───────┘
      │                  │                  │
      └──────────────────┼──────────────────┘
                         ▼
              ┌─────────────────┐
              │   FlexTrack     │◄─── ONE API
              │  (Smart Router) │
              └─────────┬───────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
    ┌─────────┐   ┌─────────┐   ┌─────────┐
    │ Console │   │Firebase │   │Mixpanel │
    └─────────┘   └─────────┘   └─────────┘
</pre>

</td>
</tr>
</table>

*Right column: first sink is **`ConsoleTracker`** (debug / human-readable); others are example vendor adapters.*

---

## What you gain while building

[`ConsoleTracker`](lib/src/strategies/built_in/console_tracker.dart) prints readable logs (name, category, properties, flags). With routing, [`FlexTrack.debugEvent`](lib/src/core/flex_track.dart) shows which rules matched — without sending. More: [docs/privacy-performance-debugging.md](docs/privacy-performance-debugging.md).

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Ad-hoc `debugPrint`, inconsistent    ║  Structured events + `ConsoleTracker` ║
║  payloads                             ║  (`showProperties`, `colorOutput`, …) ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Guessing why an event never reached  ║  `debugEvent`, `printDebugInfo`,      ║
║  a backend                            ║  `validate` (see privacy doc)         ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

---

## Install and initialize

```yaml
dependencies:
  flex_track: ^1.0.0
```

```dart
import 'package:flex_track/flex_track.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlexTrack.setup([ConsoleTracker()]);
  await FlexTrack.track(_HelloEvent());
  runApp(const SizedBox.shrink()); // your app root
}

class _HelloEvent extends BaseEvent {
  @override
  String getName() => 'app_open';

  @override
  Map<String, Object>? getProperties() => const {};
}
```

Run once and confirm output in the debug console.

---

## One destination (single tracker)

Start with **one** sink: `ConsoleTracker()` and/or a single custom `BaseTrackerStrategy`. Everything goes through `FlexTrack.track`.

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Every feature imports the analytics  ║  Features import `flex_track` only;   ║
║  SDK                                  ║  SDK lives in one tracker class       ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

**More than one tracker** or **different events → different backends** → [docs/trackers.md](docs/trackers.md) · [docs/routing-and-rules.md](docs/routing-and-rules.md)

---

## Define an event and send it

```dart
import 'package:flex_track/flex_track.dart';

class SignupCompletedEvent extends BaseEvent {
  SignupCompletedEvent({required this.method});

  final String method;

  @override
  String getName() => 'signup_completed';

  @override
  Map<String, Object>? getProperties() => {'method': method};

  @override
  EventCategory? get category => EventCategory.user;
}

await FlexTrack.track(SignupCompletedEvent(method: 'email'));
```

Optional `BaseEvent` flags (`containsPII`, `requiresConsent`, …) **future-proof** routing/consent without changing call sites — [docs/routing-and-rules.md](docs/routing-and-rules.md) · [docs/privacy-performance-debugging.md](docs/privacy-performance-debugging.md)

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  `logEvent('signup', {…})` strings    ║  Typed `BaseEvent` classes — same    ║
║  and maps everywhere                  ║  type in UI, tests, and trackers     ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

---

## Widget wrappers (overview)

| Widget | Role |
|--------|------|
| **`FlexClickTrack`** | Tap (not scroll/drag) in hit region |
| **`FlexImpressionTrack`** | Viewport visibility + optional min. duration |
| **`FlexMountTrack`** | First layout only — not “user saw it” |
| **`FlexTrackRouteObserver`** + **`FlexTrackRouteViewMixin`** | `PageRoute` / screen lifecycle |

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  `onTap: () { track(); … }` copied on ║  `FlexClickTrack`, impression, mount, ║
║  every control                        ║  route mixin — one consistent pattern ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

**Full API & samples:** [docs/widgets.md](docs/widgets.md)

---

## Testing

Suite covers **core**, **routing** (builders, engine, presets), **widgets**, **strategies**, **context/consent**, **exceptions**. For your tests: [`setupFlexTrackForTesting`](lib/flex_track.dart) + [`MockTracker`](lib/src/strategies/built_in/mock_tracker.dart) → [docs/testing-and-troubleshooting.md](docs/testing-and-troubleshooting.md)

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Common approach                      ║  With FlexTrack                       ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Mock static SDK globals per screen   ║  `MockTracker` + same `BaseEvent` as ║
║                                       ║  production                           ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

---

## More documentation (by goal)

```text
╔═══════════════════════════════════════╦═══════════════════════════════════════╗
║  Goal                                 ║  Document                             ║
╠═══════════════════════════════════════╬═══════════════════════════════════════╣
║  Multiple trackers & vendor adapters  ║  docs/trackers.md                     ║
║  Routing, sampling, rule priority     ║  docs/routing-and-rules.md            ║
║  Consent, presets, debug APIs         ║  docs/privacy-performance-debugging.md ║
║  Widget wrappers (full detail)        ║  docs/widgets.md                      ║
║  Tests, pitfalls, migration           ║  docs/testing-and-troubleshooting.md ║
╚═══════════════════════════════════════╩═══════════════════════════════════════╝
```

Index: [docs/README.md](docs/README.md)

---

## Example app

[example/](example/) — `main.dart`, sample events, sample trackers.

---

## API reference

[`flex_track.dart`](lib/flex_track.dart)

---

## Contributing

[Repository](https://github.com/alirezat66/flex_track)

---

## License

[LICENSE](LICENSE)
