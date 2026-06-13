---
phase: 56-redact-at-rest
plan: "01"
subsystem: worker
tags: [redaction, security, worker-macro, idempotency, compile-time-guards]
dependency_graph:
  requires: []
  provides: [redact-worker-opt, redaction-engine, compile-time-guards, new-override, required-field-exemption]
  affects: [lib/oban_powertools/worker.ex, lib/oban_powertools/worker/redaction.ex, test/oban_powertools/worker_redact_test.exs, test/oban_powertools/idempotency_test.exs]
tech_stack:
  added: [ObanPowertools.Worker.Redaction]
  patterns: [compile-time-guard, defoverridable-override, explicit-delegation-no-super, deep-merge-meta-injection, atom-key-normalization]
key_files:
  created:
    - lib/oban_powertools/worker/redaction.ex
    - test/oban_powertools/worker_redact_test.exs
  modified:
    - lib/oban_powertools/worker.ex
    - test/oban_powertools/idempotency_test.exs
decisions:
  - "OQ1-resolved: __powertools_new_delegate__/2 uses Oban.Job.new + Oban.Worker.merge_opts — no super in quote block"
  - "RedactIdempotencyWorker in idempotency_test uses global limits so fingerprint meta appears in oban_powertools key"
  - "DataCase already does Sandbox.checkout — removed duplicate from worker_redact_test setup"
metrics:
  duration: "8 minutes"
  completed: "2026-06-13"
  tasks: 3
  files: 4
requirements: [REDACT-01, REDACT-02]
---

# Phase 56 Plan 01: Redaction Engine Summary

At-rest redaction engine: `redact:` worker opt with compile-time guards, `new/2` override via `ObanPowertools.Worker.Redaction` helper, required-field exemption, sorted-string `__redacted_fields__` meta injection, fingerprint-ordering and meta non-clobber invariants proven.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 0 | Wave 0 — failing redaction test scaffold | e95c9df | test/oban_powertools/worker_redact_test.exs |
| 1 | Redaction helper + worker.ex parse, guards, exemption, new/2 override | 47ed1b2 | lib/oban_powertools/worker/redaction.ex, lib/oban_powertools/worker.ex, test/oban_powertools/worker_redact_test.exs |
| 2 | Fingerprint-ordering + single-meta-injection invariant tests in idempotency_test | f74a479 | test/oban_powertools/idempotency_test.exs |

## What Was Built

### `ObanPowertools.Worker.Redaction` (new module)

Pure internal helper (`@moduledoc false`, no struct, no schema). Public `apply/4`:
- No-op clause `apply(worker_mod, args, opts, [])` — delegates via `worker_mod.__powertools_new_delegate__(args, opts)`
- Work clause `apply(worker_mod, args, opts, redact_keys)`:
  - Computes `redact_strings = Enum.map(&Atom.to_string/1) |> Enum.sort()` (D-17)
  - `normalize_to_atom_keys/2` — re-keys string keys that map to declared redact atoms (D-16)
  - `Map.drop(normalized, redact_keys)` — key-absent, never nil (D-02)
  - `inject_meta/2` — deep-merges `%{"__redacted_fields__" => redact_strings}` into `opts[:meta]` (D-04, D-17)
  - Delegates to `worker_mod.__powertools_new_delegate__(clean_args, opts_with_meta)`

### `worker.ex` changes

- `redact_config = Keyword.get(opts, :redact, [])` extraction + `Keyword.delete(:redact)` strip
- `validate_redact_config!/3` compile-time guards: D-07 (typo — undeclared field raises), D-09 (partition key collision raises)
- `required_fields = Keyword.keys(args_config) -- redact_config` at macro time
- `@powertools_redact unquote(redact_config)` attribute + `__powertools_redact__/0` accessor
- `Args.changeset/2` updated: cast ALL fields, `validate_required(required_fields)` only (D-06)
- `new/2` override: `ObanPowertools.Worker.Redaction.apply(__MODULE__, args, opts, @powertools_redact)` (`@impl Oban.Worker`)
- `__powertools_new_delegate__/2`: `Oban.Job.new(args, Oban.Worker.merge_opts(__opts__(), opts))` (OQ1-resolved explicit delegation, no super)
- `defoverridable new: 1, new: 2`

### `idempotency_test.exs` additions

- `RedactIdempotencyWorker` with `redact: [:ssn]` + global limits (limits provide oban_powertools meta key for fingerprint assertion)
- D-03 test: two jobs with same user_id but different ssn produce DIFFERENT idempotency fingerprints (proves fingerprint runs before new/2 drop)
- D-04 test: caller `meta: %{"source" => "host"}` preserved, fingerprint present, `__redacted_fields__ == ["ssn"]` is flat string list

## Verification Results

```
mix test test/oban_powertools/worker_redact_test.exs test/oban_powertools/idempotency_test.exs
16 tests, 0 failures

mix compile --warnings-as-errors
# Clean, no warnings
```

### Acceptance Criteria Met

- `grep -n "def __powertools_redact__" lib/oban_powertools/worker.ex` → line 92
- `grep -n "ObanPowertools.Worker.Redaction.apply" lib/oban_powertools/worker.ex` → line 139
- `grep -n "__powertools_new_delegate__" lib/oban_powertools/worker.ex` → line 143
- `grep -n "Oban.Worker.merge_opts" lib/oban_powertools/worker.ex` → line 144
- `grep -c "super" lib/oban_powertools/worker.ex` → 1 (comment only: "no super")
- `grep -n "defoverridable new: 1, new: 2" lib/oban_powertools/worker.ex` → line 147
- `lib/oban_powertools/worker/redaction.ex` starts with `defmodule ObanPowertools.Worker.Redaction do` + `@moduledoc false`
- `grep -c "__redacted_fields__" lib/oban_powertools/idempotency.ex` → 0 (single-injection guarantee held in new/2)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed duplicate Sandbox.checkout from worker_redact_test.exs setup**
- **Found during:** Task 0 verification
- **Issue:** Test used `use ObanPowertools.DataCase` which already calls `Ecto.Adapters.SQL.Sandbox.checkout` in its setup block. Adding a manual checkout caused `{:already, :owner}` error on all tests.
- **Fix:** Removed the `Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)` line from the test module's setup; kept the repo Application env setup/teardown.
- **Files modified:** test/oban_powertools/worker_redact_test.exs
- **Commit:** 47ed1b2

**2. [Rule 1 - Bug] Added limits to RedactIdempotencyWorker to make fingerprint meta appear**
- **Found during:** Task 2 verification
- **Issue:** `Idempotency.merge_powertools_meta` only writes `oban_powertools.idempotency_fingerprint` to meta when the worker has limits configured (the `{:ok, nil}` clause returns `%{}`). Without limits, the fingerprint is not stored in meta. The D-04 test asserting `is_binary(get_in(meta, ["oban_powertools", "idempotency_fingerprint"]))` would always fail.
- **Fix:** Added `limits: [name: "redact-idempotency", scope: :global, ...]` to `RedactIdempotencyWorker`.
- **Files modified:** test/oban_powertools/idempotency_test.exs
- **Commit:** f74a479

## Known Stubs

None. All implementation is wired end-to-end with real DB integration tests.

## Threat Flags

No new threat surfaces introduced by this plan. All changes are internal worker macro code and test files. No new network endpoints, auth paths, or schema changes.

## TDD Gate Compliance

- RED gate: `test(56-01)` commit e95c9df (failing test scaffold — ArgumentError at compile time)
- GREEN gate: `feat(56-01)` commit 47ed1b2 (implementation makes all 6 tests pass)
- No REFACTOR gate needed (code is already minimal; logic lives in Redaction helper module)

## Self-Check: PASSED
