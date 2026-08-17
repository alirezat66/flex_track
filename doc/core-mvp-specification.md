# FlexTrack Core MVP Specification

Status: Normative  
Specification version: 1.0.0  
Target SDKs: Flutter 2.1.x and Kotlin 1.0.x

## 1. Purpose and terminology

This is the language-neutral contract for a conforming FlexTrack Core. It
defines observable behavior, not internal class structure. **MUST**, **MUST
NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are normative requirements. A
tracker is an adapter for one analytics destination; a dispatch is one attempt
to deliver one processed event to one tracker.

Example: Kotlin MAY use data classes and Flutter MAY use abstract classes, but
both MUST make the same routing decision from the same inputs.

## 2. MVP boundary

Core MVP includes events and enrichment, tracker lifecycle, routing, consent,
PII gates, deterministic sampling, decision records, setup, track, flush,
tracker reset, and disposal.

Durable/offline queues, persistence, retries/backoff, session management,
SDK-owned identity, and optimized batching are later capabilities. They MUST
NOT be required for Core MVP conformance. An adapter MAY implement them
privately, but Core 1.0 does not promise their semantics.

Example: a tracker MAY buffer internally, but Core need not restore its buffer
after process death.

## 3. Event model

An event MUST expose:

| Field | Type | Default or requirement |
|---|---|---|
| `eventId` | non-empty string | UUID v4 for a new occurrence |
| `name` | string | supplied by the event |
| `properties` | string-keyed object or null | null |
| `category` | string or null | null |
| `preferredGroup` | group or null | null |
| `containsPII` | boolean | false |
| `requiresConsent` | boolean | true |
| `isHighVolume` | boolean | false |
| `isEssential` | boolean | false |
| `timestamp` | instant | creation time in UTC |
| `userId` | string or null | null |
| `sessionId` | string or null | null |

`eventId` and `timestamp` MUST be captured once and remain unchanged.
Reconstructed events MUST accept their original values. Generated IDs MUST be
RFC 4122 UUID v4 values. Serialized timestamps MUST be ISO 8601 with an
explicit UTC offset. Core MUST preserve property values without implicit string
conversion.

Example:

```json
{
  "eventId": "123e4567-e89b-42d3-a456-426614174000",
  "name": "purchase",
  "properties": {"amount": 29.99, "currency": "EUR"},
  "category": "business",
  "containsPII": false,
  "requiresConsent": true,
  "isHighVolume": false,
  "isEssential": false,
  "timestamp": "2026-08-17T12:30:00.000Z",
  "userId": null,
  "sessionId": null
}
```

## 4. Enrichment

Transformers MUST run in registration order before routing. Each output MUST be
the next input. Added properties MUST win on duplicate keys. Enrichment MUST
preserve ID, timestamp, name, category, group preference, privacy flags,
volume/essential flags, user ID, and session ID. Type matching MUST inspect the
original type through nested wrappers; other conditions MUST inspect the
transformed event. A transformer failure SHOULD be isolated and processing
SHOULD continue from the last valid event.

Example: `{plan: free}` enriched with `{plan: pro, route: /pay}` becomes
`{plan: pro, route: /pay}` with the original ID and timestamp.

## 5. Tracker interface and lifecycle

Each tracker MUST have a unique non-empty stable ID, name, and enabled state.
Setup MUST reject an empty tracker list or duplicate IDs, then register and
initialize every tracker. Repeated client initialization MUST be idempotent.

Core MUST call `track(event)` on every selected enabled tracker and record each
outcome independently. One failure MUST NOT prevent later tracker attempts.
Disabled selected trackers MUST produce failed tracker results. Unavailable IDs
MUST already have been removed during group resolution.

`flush()` and tracker reset MUST delegate to all enabled registered trackers.
Disposal MUST flush enabled trackers when the client was initialized and release
client-owned debug resources. It does not guarantee durable delivery.

Example: if `a` throws and `b` succeeds, Core still calls `b` and returns one
failed plus one successful result.

## 6. Routing

### 6.1 Conditions

A rule matches only when every configured condition matches. MVP conditions are
original event type/subtype, name substring, name regex, category, property
presence and optional equality, PII, high-volume, essential, and environment.
An absent condition MUST NOT restrict matching.

Example: category `business` plus `currency = EUR` matches a EUR purchase, not
a USD purchase or technical event.

### 6.2 Priority tiers and merging

Matching rules MUST be sorted by descending integer priority. Core MUST evaluate
until a tier produces targets. All successful rules at that priority MUST merge
tracker IDs as an ordered, de-duplicated set. Lower tiers MUST NOT run afterward.
A rule blocked by consent, sampled out, or resolving to no tracker does not
establish a winning tier.

Example: priority-10 targets `[firebase]` and `[api, firebase]` merge to
`[firebase, api]`; priority 0 is ignored. If both are blocked, priority 0 runs.

### 6.3 Groups and fallback

A named group MUST resolve to configured IDs. `all` MUST resolve to every
available tracker. Unavailable IDs MUST be removed. An empty resolution MUST be
skipped with a warning. If no configured rule matches, Core MUST use a default
rule, otherwise an equivalent rule for `defaultGroup`; without either it MUST
return no targets.

Example: `[firebase, missing]` with only `firebase` available resolves to
`[firebase]`. With no match and `defaultGroup = all`, all trackers are targeted.

## 7. Consent and PII

New clients MUST start with general and PII consent `false`. With consent
checking enabled, a non-essential rule MUST be skipped when its general consent,
the event's general consent, or its PII consent requirement is unmet. Essential
events MUST bypass both gates. Disabling configuration-level consent checking
MUST bypass all consent gates. Consent changes affect future processing only.

Example: a purchase is rejected at startup, succeeds after general consent,
and a PII rule still waits for PII consent. An essential crash event is eligible
in every consent state.

## 8. Deterministic sampling

Essential events MUST bypass sampling. Rates `<= 0` MUST reject and rates `>= 1`
MUST accept. Otherwise choose the first non-empty `userId`, `sessionId`, then
`name`; hash its UTF-8 bytes with unsigned 32-bit FNV-1a; calculate
`bucket = hash / 4294967296`; accept exactly when `bucket < sampleRate`.
Implementations MUST pass
[`sampling_vectors.json`](https://github.com/alirezat66/flex_track/blob/main/test/fixtures/sampling_vectors.json). Locale
normalization and platform string hashes MUST NOT be used.

Example: `hello` hashes to `1335831723`, bucket about `0.3110`; it is rejected
at 25% and accepted at 50%.

## 9. Processing order

`track(event)` MUST execute in this order:

1. Stop unsuccessful with no targets when the processor is disabled.
2. Run transformers in registration order.
3. Match rules and sort them by descending priority.
4. Apply consent gates at each eligible tier.
5. Apply deterministic sampling.
6. Resolve groups against available trackers.
7. Merge successful rules in the first successful tier.
8. Attempt every selected tracker independently.
9. Return the processed event, routing decision, and tracker results.
10. In debug builds, emit one decision record after processing.

Example: an enriched PII event gains `route=/profile`, matches a property rule,
then fails its PII gate. It causes no tracker call, while the result records the
enriched event and skipped rule.

## 10. Results and debug decisions

A result MUST contain the processed event, target IDs, applied rules, skipped
rules and reasons, warnings, per-tracker outcomes, and overall success. Success
MUST mean at least one delivery succeeded. `routed` MUST mean at least one target
was selected; `tracked` MUST mean at least one delivery succeeded.

A tracker outcome MUST contain tracker ID, success, optional error, and attempt
timestamp. A debug decision MUST contain the processed event, selected IDs, and
successful IDs. Debug emission MAY be absent in release builds and MUST NOT
change delivery.

Example: targets `[a, b]` with only `b` succeeding gives `routed=true`,
`tracked=true`, `successful=true`, successful IDs `[b]`, and one failure.

## 11. Client operations

Each client MUST own isolated trackers, routing, consent, and transformers.
Sequential helpers MAY process in input order; parallel helpers MAY deliver
concurrently but MUST return results in input order. Optimized batching remains
outside MVP. Enablement and consent changes affect future processing. Global
facades MAY exist but MUST delegate without changing client semantics.

Example: a transformer added to client A MUST NOT affect client B.

## 12. Versioning and compatibility

The specification uses semantic versioning independently of SDK versions.
Patches clarify wording without behavior changes. Minors add backward-compatible
optional behavior. Majors may change required fields, evaluation order, or
decisions. Every SDK release MUST state its implemented spec version. SDKs on
the same spec major SHOULD interoperate on shared event and vector formats.

Example: Flutter 2.1.2 and Kotlin 1.0.1 can both implement Core Spec 1.0.0. An
optional debug field can enter 1.1.0; changed priority semantics require 2.0.0.
