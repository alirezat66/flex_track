# FlexTrack Runtime Delivery Specification 1.0.0

Status: normative, language-neutral contract for Flutter, Kotlin, Swift, and
TypeScript implementations. RFC 2119 terms MUST, SHOULD, and MAY are normative.

## 1. Scope

Core Specification 1.0 decides which destinations should receive an event.
Runtime Delivery 1.0 defines tracker lifecycle, dispatch attempts, durable
queuing, replay, concurrency, failure isolation, and observable results. It does
not define vendor payload formats, network reachability detection, encryption at
rest, exponential backoff scheduling, or server acknowledgement protocols.

## 2. Terms and identity

- An event occurrence is identified by its non-empty `eventId`.
- A destination is identified by a non-empty tracker ID.
- A queued item is identified by the event occurrence ID and contains an
  ordered, duplicate-free list of destinations still awaiting delivery.
- An attempt is one invocation of one tracker for one event occurrence.
- A dispatch is the initial attempt set produced by one `track` operation.
- A flush is one bounded FIFO replay pass over queued items.

Event identity and timestamp MUST survive transformation, queue serialization,
process restart, and every retry. A retry MUST NOT create a new occurrence.

## 3. Lifecycle

Tracker initialization MUST be idempotent per client lifecycle. A client MUST
attempt every registered tracker even if another tracker fails initialization,
and MUST expose initialization failure. Initialization is transactional: after
any failure the client remains uninitialized, successfully initialized peers
are disposed, and a later initialize call MUST attempt every tracker again.
Tracking before successful client
initialization is SDK-defined for Core 1 compatibility; new APIs SHOULD reject
it. Disposal MUST be idempotent, flush tracker-owned buffers, and release
client-owned streams/resources. Queue persistence MUST survive disposal.

## 4. Initial dispatch

The runtime MUST transform and route an event exactly once. When online, all
resolved destinations MUST be attempted independently. One synchronous or
asynchronous tracker failure MUST NOT cancel or prevent other attempts. Results
MUST preserve routing destination order even when attempts execute concurrently.

When offline, no tracker may be invoked. If routing produced destinations, the
processed event and every destination MUST be queued. An event rejected before
routing completion (disabled processor, consent, sampling, or no target) MUST
NOT be queued.

## 5. Partial success and queue admission

After an online dispatch, only unsuccessful destinations MUST be queued.
Successful destinations MUST never be included in that queued item. Queue
admission is idempotent by event ID: enqueueing an already-present occurrence
MUST NOT duplicate or reorder it. Callers MUST use unique event IDs for distinct
occurrences.

## 6. Queue model

The queue MUST provide FIFO read, enqueue, replace, remove, size, and clear.
Reads MUST require a positive limit and MUST NOT mutate state. Replace and remove
of an absent ID MUST be no-ops. Returned collections MUST not permit callers to
mutate queue state. A durable implementation MUST serialize all mutating
operations and use atomic file replacement or equivalent transactional storage.

Queued properties MUST be JSON-compatible: null, boolean, finite number,
string, list, and string-keyed map composed recursively. Unsupported values MUST
fail queue persistence visibly; they MUST NOT be stringified or silently lost.
Malformed persisted data MUST raise a corruption/format error and MUST NOT be
silently discarded or partially replayed.

## 7. Flush and selective retry

A flush MUST process at most `limit` queued items in FIFO order. A non-positive
limit MUST fail before reading or mutating the queue. An offline flush MUST be a
no-op with zero attempted and delivered events.

Queued events MUST NOT be transformed or routed again. The stored processed
event and pending destinations are authoritative. Every pending destination is
attempted independently. If all succeed, remove the item. Otherwise replace it
in the same FIFO position with only failed destination IDs and increment
`attempts` exactly once for that flush pass. Successful destinations MUST NOT be
retried by a later flush.

Items added after a flush begins are outside that pass. Concurrent queue
mutations MUST be serialized. Concurrent flush calls MUST be serialized so one
occurrence/destination cannot be attempted twice concurrently.

## 8. Results

Initial dispatch results MUST expose the processed event, routing result,
ordered successful and failed per-tracker outcomes, and queued destination IDs.
Overall success means at least one tracker succeeded; queued-only is not success.

Flush results MUST expose:

- `attemptedEvents`: queued items selected at the beginning of the pass;
- `deliveredEvents`: selected items removed because every pending destination
  succeeded;
- `remainingEvents`: total queue size after the pass.

## 9. Error and cancellation semantics

Tracker errors are data and MUST be isolated into per-tracker results. Runtime,
programmer, queue corruption, serialization, and cancellation errors MUST remain
errors; they MUST NOT be mislabeled as tracker failures. Cancellation MUST stop
the caller's operation and MUST NOT enqueue an artificial failure. SDKs without
structured cancellation MUST document their closest equivalent.

## 10. Privacy

Core consent is evaluated before initial queue admission. Runtime 1.0 preserves
that routing decision during replay to guarantee deterministic delivery and to
avoid policy drift. Applications requiring revocation to purge queued data MUST
call queue `clear`; SDKs SHOULD provide a higher-level purge helper. Runtime 1.1
will define consent-revocation retention policy explicitly.

## 11. Conformance

Implementations claiming Runtime 1.0 MUST pass `runtime_mvp_cases.json`, validate
its envelope against `runtime_mvp.schema.json`, and publish a machine-readable
report containing implementation, spec version, fixture version, pass/fail
counts, and case IDs. Platform-specific persistence tests MUST additionally
cover restart recovery, atomic replacement, malformed JSON, invalid event
shape, concurrent mutations, and unsupported property values.
