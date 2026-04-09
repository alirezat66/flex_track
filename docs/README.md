# FlexTrack documentation (by goal)

Pick the topic that matches what you are doing. The [main README](../README.md) covers installation, a single-tracker setup, defining events, and short summaries; these pages go deeper with examples and edge cases.

| Goal | Document |
|------|----------|
| Multiple backends, vendor adapters, `BaseTrackerStrategy` | [trackers.md](trackers.md) |
| Send different events to different trackers; sampling; rule priority | [routing-and-rules.md](routing-and-rules.md) |
| Consent, GDPR presets, performance presets, batching, debug APIs | [privacy-performance-debugging.md](privacy-performance-debugging.md) |
| Click, impression, mount, route / screen tracking | [widgets.md](widgets.md) |
| `setupFlexTrackForTesting`, `MockTracker`, pitfalls, migration | [testing-and-troubleshooting.md](testing-and-troubleshooting.md) |

Also see the [example app](../example/) for runnable setup, events, and sample trackers.
