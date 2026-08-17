# Cross-SDK conformance

The files in [`test/fixtures/conformance/`](../test/fixtures/conformance/) are
the shared executable contract for Flutter and Kotlin Core MVP implementations.

## Version 1.0.0 files

- `core_mvp.schema.json` defines the fixture envelope.
- `core_mvp_cases.json` contains deterministic inputs and expected outputs.
- `flutter_report.json` is the machine-readable Flutter conformance report.
- `sampling_vectors.json` contains the complete Unicode FNV-1a vectors used by
  both SDKs.

Fixture case IDs are stable within a fixture major version. Adding a
backward-compatible case increments the fixture minor version. Changing an
existing input or expected result increments the fixture major version.

## Kotlin runner contract

The Android repository MUST copy or consume the fixture files without rewriting
their values. Its runner MUST:

1. Reject an unsupported `specVersion` or fixture major version.
2. Validate the fixture envelope against `core_mvp.schema.json`.
3. Execute every case according to its `behavior` value.
4. Compare ordered arrays exactly; tracker ordering is observable.
5. Use UTF-8 and unsigned 32-bit FNV-1a for sampling cases.
6. Avoid wall-clock time, random identifiers, network calls, and Android device
   state while evaluating fixtures.
7. Emit a JSON report with `specVersion`, `fixtureVersion`, `implementation`,
   `total`, `passed`, `failed`, and ordered `caseIds`.
8. Exit unsuccessfully when schema validation or any case fails.

Example Kotlin report:

```json
{
  "specVersion": "1.0.0",
  "fixtureVersion": "1.0.0",
  "implementation": "kotlin",
  "total": 8,
  "passed": 8,
  "failed": 0,
  "caseIds": ["routing.priority-overlap"]
}
```

The abbreviated `caseIds` above is illustrative; a real passing report MUST
contain every fixture ID in fixture order.

## Covered behavior

The MVP suite covers priority overlap, same-tier merging, fallback, missing
general consent, missing PII consent, Unicode sampling, enrichment identity and
property precedence, and the debug dispatch decision. Later capabilities such
as offline queues and retry are intentionally excluded until their contracts
are versioned.

Run the Flutter suite with:

```bash
flutter test test/contract
```

