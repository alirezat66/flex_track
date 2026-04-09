# FlexTrack

> **Where this README comes from:** On **GitHub** (`main`), this file is the canonical guide (~330 lines) with a [table of contents](#table-of-contents), honest **Quick start** (`MyFirebaseTracker` = *your* class), and [widget wrappers](#widget-wrappers-overview). **`FirebaseTracker` / `MixpanelTracker` in the repo live only under [`example/`](example/)** — they are **not** exported by the `flex_track` package. If **pub.dev** still shows thousands of lines or built-in vendor classes, that page is pinned to an **older published version**; publish a new version or open the [raw README on GitHub](https://raw.githubusercontent.com/alirezat66/flex_track/main/README.md).

## Quick start

Four steps. **`MyFirebaseTracker`** and **`MyEvent`** are **your** code — this package does **not** ship Firebase, Mixpanel, or any vendor tracker; it only provides [`BaseTrackerStrategy`](lib/src/strategies/base_tracker_strategy.dart), [`FlexTrack`](lib/src/core/flex_track.dart), and built-ins like [`ConsoleTracker`](lib/src/strategies/built_in/console_tracker.dart) / [`MockTracker`](lib/src/strategies/built_in/mock_tracker.dart).

```dart
// 1) pubspec.yaml
//    dependencies:
//      flex_track: ^1.0.0
//      # firebase_core: ...
//      # firebase_analytics: ...   ← your app adds vendor SDKs

import 'package:flex_track/flex_track.dart';
import 'package:flutter/widgets.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

/// 2) Your tracker — wire the SDK you already depend on.
class MyFirebaseTracker extends BaseTrackerStrategy {
  MyFirebaseTracker() : super(id: 'firebase', name: 'My Firebase');

  @override
  Future<void> doInitialize() async {
    // await Firebase.initializeApp();
  }

  @override
  Future<void> doTrack(BaseEvent event) async {
    // await FirebaseAnalytics.instance.logEvent(name: event.getName());
  }
}

class MyEvent extends BaseEvent {
  @override
  String getName() => 'example';

  @override
  Map<String, Object>? getProperties() => const {};
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 3) Setup — list every tracker you implemented
  await FlexTrack.setup([MyFirebaseTracker()]);
  // 4) Track
  await FlexTrack.track(MyEvent());
  runApp(const SizedBox.shrink());
}
```

**No Firebase yet?** Use only the built-in sink: `await FlexTrack.setup([ConsoleTracker()]);` — you will see events in the debug console.

**Flutter UI helpers (optional):** [`FlexClickTrack`](#widget-wrappers-overview) · [`FlexImpressionTrack`](#widget-wrappers-overview) · [`FlexMountTrack`](#widget-wrappers-overview) · [`FlexTrackRouteObserver` / `FlexTrackRouteViewMixin`](#widget-wrappers-overview) — [full widget guide](docs/widgets.md).

---

## Table of contents

- [Overview](#overview)
- [Architecture diagrams](#architecture-diagrams)
- [What you gain while building](#what-you-gain-while-building)
- [Install and initialize](#install-and-initialize)
- [One destination (single tracker)](#one-destination-single-tracker)
- [Define an event and send it](#define-an-event-and-send-it)
- [Widget wrappers (overview)](#widget-wrappers-overview)
- [Testing](#testing)
- [More documentation (by goal)](#more-documentation-by-goal)
- [Example app](#example-app)
- [API reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

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

---

## Architecture diagrams

Screens stay the same; either every screen talks to every SDK, or every screen calls **one API** (`FlexTrack.track`) and FlexTrack routes to the **trackers you register**. Labels like “Firebase” in the **traditional** column are **illustrative products**, not classes from this package. The **FlexTrack** column shows **[`ConsoleTracker`](lib/src/strategies/built_in/console_tracker.dart)** (shipped, for debug logs) plus **example** slots for adapters **you** write.

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
│  │Your SDK │ │Your SDK │ │Your SDK │ │Your API  │  │
│  │  #1     │ │  #2     │ │  #3     │ │          │  │
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
    │ Console │   │Your SDK │   │Your SDK │
    │ Tracker │   │adapter  │   │adapter  │
    └─────────┘   └─────────┘   └─────────┘
</pre>

</td>
</tr>
</table>

*Left: generic “your SDKs”. Right: **`ConsoleTracker`** is built-in; other boxes are **your** `BaseTrackerStrategy` subclasses (Firebase, Mixpanel, HTTP, …).*

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

Minimal run with **only** a built-in tracker (no vendor code):

```dart
import 'package:flex_track/flex_track.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlexTrack.setup([ConsoleTracker()]);
  await FlexTrack.track(_HelloEvent());
  runApp(const SizedBox.shrink());
}

class _HelloEvent extends BaseEvent {
  @override
  String getName() => 'app_open';

  @override
  Map<String, Object>? getProperties() => const {};
}
```

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

These types are **exported from `flex_track`** — use them when you want tap / visibility / mount / route lifecycle to call `FlexTrack.track` with less boilerplate.

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

[example/](example/) — `main.dart`, sample events, **sample** trackers you copy into your app (not re-exported by the package).

---

## API reference

[`flex_track.dart`](lib/flex_track.dart)

---

## Contributing

[Repository](https://github.com/alirezat66/flex_track)

---

## License

[LICENSE](LICENSE)
