---
phase: 56-redact-at-rest
plan: "04"
subsystem: documentation
tags: [redaction, documentation, support-truth, docs-contract, tdd]
dependency_graph:
  requires: [56-01]
  provides: [redact-support-truth-docs, redact-docs-contract-lock]
  affects:
    - guides/workers-and-idempotency.md
    - test/oban_powertools/docs_contract_test.exs
tech_stack:
  added: []
  patterns: [docs-contract-lock-test, support-truth-section, tdd-red-green]
key_files:
  created: []
  modified:
    - guides/workers-and-idempotency.md
    - test/oban_powertools/docs_contract_test.exs
decisions:
  - "D-11 verbatim sentence locked verbatim in guide and asserted by docs-contract test"
  - "D-10 honest boundary documented: meta/errors/stacktraces not scrubbed; JobRecord.redacted stays false"
  - "Guide follows Output recording section shape: 1-line description, code block, bulleted support truth"
metrics:
  duration: "3 minutes"
  completed: "2026-06-13"
  tasks: 2
  files: 2
requirements: [REDACT-01]
---

# Phase 56 Plan 04: At-rest Redaction Documentation Summary

D-11 support-truth documented verbatim and locked by a docs-contract test: `redact:` removes fields from args at enqueue; it does NOT scrub recorded outputs; workers must not return redacted/sensitive data from `process/1`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 0 | Wave 0 — failing docs-contract lock test for redact: support truth | 130f5b4 | test/oban_powertools/docs_contract_test.exs |
| 1 | Add "At-rest argument redaction" section to the workers guide | 0f1475b | guides/workers-and-idempotency.md |

## What Was Built

### `guides/workers-and-idempotency.md` (new section)

Added `## At-rest argument redaction` section after `## Output recording`, following the same feature section pattern (1-line description, `use ObanPowertools.Worker` code block, bulleted support truth).

The section covers all required D-XX boundary notes:
- **D-02** (key-absent): fields are removed, not nulled or replaced with a placeholder
- **D-03** (fingerprint-first): idempotency fingerprint computed from full unredacted args before redaction; different SSN values produce different fingerprints
- **D-05** (cron path): redaction applies to both direct-insert and cron-scheduled paths
- **D-06** (required-field exemption): redacted typed fields are automatically exempt from `validate_required`
- **D-07** (typo guard): undeclared `redact:` key raises at compile time
- **D-08** (top-level only): v1.7 scope is top-level `args:` fields only
- **D-09** (partition-key guard): `redact:` key that is also a `partition_by` limiter key raises at compile time
- **D-10** (honest boundary): `meta`, `errors`, and stacktraces are not scrubbed; `JobRecord.redacted` stays `false`
- **D-11** (verbatim): "`redact:` removes fields from args at enqueue; it does NOT scrub recorded outputs. Workers must not return redacted/sensitive data from `process/1`."

No false assurance: guide does not claim outputs/meta/errors are scrubbed; no "Hidden"/"Masked"/"Encrypted" framing in the new section.

### `test/oban_powertools/docs_contract_test.exs` (new test)

Added test `"redact: support truth stays locked in builder docs"` following the existing `"worker lifecycle hook support truth stays locked in builder docs"` pattern. Asserts five D-11 phrases against `@worker_guide_path`:
- `"At-rest argument redaction"` (section heading)
- `"redact:"` (option name)
- `"does NOT scrub recorded outputs"`
- `"Workers must not return redacted/sensitive data from"`
- `"removes fields from args at enqueue"`

## Verification Results

```
mix test test/oban_powertools/docs_contract_test.exs
18 tests, 0 failures
```

### Acceptance Criteria Met

- `grep -c "At-rest argument redaction" guides/workers-and-idempotency.md` → 1
- `grep -c "does NOT scrub recorded outputs" guides/workers-and-idempotency.md` → 1
- Guide does NOT claim meta/errors or recorded output are scrubbed
- `grep -c "Hidden\|Masked\|Encrypted" guides/workers-and-idempotency.md` → 0 (no encryption framing)
- `mix test test/oban_powertools/docs_contract_test.exs` exits 0 (18 tests, 0 failures)

## Deviations from Plan

None — plan executed exactly as written. TDD RED/GREEN cycle followed:
- Task 0 committed as RED (test failed: "At-rest argument redaction" not found in guide)
- Task 1 committed as GREEN (18 tests, 0 failures after guide section added)

## Known Stubs

None. Documentation is fully wired to the implementation delivered by 56-01 (engine) and 56-02 (cron path).

## Threat Flags

No new threat surfaces. Documentation-only change; no new network endpoints, auth paths, file access patterns, or schema changes.

| Flag | Description |
|------|-------------|
| T-56-14 mitigated | D-11 exact boundary sentence present in guide + docs-contract lock test prevents silent regression of false-assurance vector |

## TDD Gate Compliance

- RED gate: `test(56-04)` commit 130f5b4 — failing test scaffold (1 failure: "At-rest argument redaction" not found)
- GREEN gate: `feat(56-04)` commit 0f1475b — guide section makes all 18 tests pass
- No REFACTOR gate needed (docs section is already minimal and complete)

## Self-Check: PASSED
