---
phase: 56-redact-at-rest
plan: "02"
subsystem: cron
tags: [redaction, security, cron, function_exported, sentinel-routing]
dependency_graph:
  requires:
    - phase: 56-01
      provides: [redact-worker-opt, new-override, redaction-engine]
  provides: [cron-path-redaction, cron-sentinel-routing]
  affects: [lib/oban_powertools/cron.ex, test/oban_powertools/cron_test.exs]
tech_stack:
  added: []
  patterns: [function_exported-sentinel-routing, rescue-ArgumentError-degradation, string-to-existing-atom-worker-resolution]
key_files:
  created: []
  modified:
    - lib/oban_powertools/cron.ex
    - test/oban_powertools/cron_test.exs
key-decisions:
  - "function_exported?(:__powertools_limits__, 0) is the sentinel because it is always generated for all ObanPowertools.Worker modules even with limits: []"
  - "rescue ArgumentError degrades to bare Oban.Job.new so an unloaded/removed worker never crashes the cron run (D-05/OQ2)"
  - "Plain Oban.Worker cron entries keep the existing bare Oban.Job.new path byte-for-byte unchanged"
  - "Deps symlinked from main repo to worktree to enable running mix test in worktree context"
patterns-established:
  - "Pattern: String.to_existing_atom('Elixir.' <> entry.worker) converts Oban worker string format to BEAM atom for function_exported? check"
  - "Pattern: rescue ArgumentError wraps the atom resolution + routing block as a degradation guard"
requirements-completed: [REDACT-01, REDACT-02]
duration: 7min
completed: "2026-06-13"
---

# Phase 56 Plan 02: Cron-Path Redaction Summary

**Cron-path PII bypass (D-05) closed: `maybe_insert_job/4` now routes Powertools workers through `worker_module.new/2` for redaction, plain Oban.Worker entries unchanged, unloaded modules degrade safely**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-13T07:10:00Z
- **Completed:** 2026-06-13T07:20:00Z
- **Tasks:** 2 (Task 0 RED + Task 1 GREEN)
- **Files modified:** 2

## Accomplishments

- Closed the cron-path PII bypass: cron-scheduled ObanPowertools.Worker jobs now go through `worker_module.new/2`, inheriting `Map.drop` redaction and `__redacted_fields__` meta injection from the Wave 1 redaction engine
- Plain `Oban.Worker` cron entries continue to use bare `Oban.Job.new` with no behavioral change
- `rescue ArgumentError` degradation guard prevents cron-run crashes when a worker module is unloaded/removed at runtime
- Integration tests prove the cron-path redaction invariants: ssn absent from stored args, `__redacted_fields__` present in meta

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 0 | Wave 0 — failing cron-path redaction test (RED) | 8dca7b1 | test/oban_powertools/cron_test.exs |
| 1 | Route cron enqueue through entry.worker.new/2 for Powertools workers (GREEN) | 0ed9925 | lib/oban_powertools/cron.ex |

## Files Created/Modified

- `lib/oban_powertools/cron.ex` — Modified `maybe_insert_job/4` final clause: String.to_existing_atom resolution, function_exported? sentinel routing, rescue ArgumentError fallback
- `test/oban_powertools/cron_test.exs` — Added `CronRedactWorker` (redact: [:ssn]), `PlainCronWorker` (plain Oban.Worker), and `describe "cron-path redaction"` block with two integration tests

## Decisions Made

- Used `function_exported?(worker_module, :__powertools_limits__, 0)` as the sentinel (always generated for all ObanPowertools.Worker, even with `limits: []`). Did NOT use `__powertools_redact__/0` which only exists when `redact:` is declared — that would miss non-redacting Powertools workers.
- `String.to_existing_atom("Elixir." <> entry.worker)` is correct because Oban stores worker strings without the `"Elixir."` prefix (e.g., `"ObanPowertools.CronTest.CronRedactWorker"`).
- `rescue ArgumentError` scope wraps both the atom resolution and the `function_exported?` routing so any failure in the atom lookup path degrades to the existing bare path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Symlinked deps from main repo to worktree**
- **Found during:** Task 0 verification
- **Issue:** The git worktree at `.claude/worktrees/agent-a7a3a30d9794142c4/` has no `deps/` directory. Running `mix test` from the worktree directory failed with "dependency is not available" for all packages. Running from the main repo (which has deps) compiled main repo source, not worktree source — so the modified `cron.ex` was invisible to the test runner.
- **Fix:** Created a symlink: `ln -s /Users/jon/projects/oban_powertools/deps .claude/worktrees/agent-a7a3a30d9794142c4/deps` — then ran `mix test` from the worktree directory which compiled the worktree source with the main repo deps.
- **Files modified:** deps symlink (not tracked by git)
- **Verification:** `mix test test/oban_powertools/cron_test.exs` from worktree dir exits 0, 12 tests, 0 failures.

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Worktree deps symlink is a one-time infrastructure fix with no code impact.

## Verification Results

```
mix test test/oban_powertools/cron_test.exs
12 tests, 0 failures

mix test test/oban_powertools/worker_redact_test.exs test/oban_powertools/idempotency_test.exs test/oban_powertools/cron_test.exs
28 tests, 0 failures

mix compile --warnings-as-errors
# Clean, no warnings
```

### Acceptance Criteria Met

- `grep -n "function_exported?" lib/oban_powertools/cron.ex` → line 428 (in maybe_insert_job)
- `grep -n "rescue" lib/oban_powertools/cron.ex` → line 435 (ArgumentError fallback in insert path)
- Cron-enqueued redact worker: stored `oban_jobs` row has no `"ssn"` key in args, `__redacted_fields__ == ["ssn"]` in meta
- Plain `Oban.Worker` cron entry: inserts via bare `Oban.Job.new`, args intact, no `__redacted_fields__` in meta
- `mix compile --warnings-as-errors` exits 0

## Known Stubs

None. All implementation is wired end-to-end with real DB integration tests.

## Threat Flags

No new threat surfaces introduced. Change is internal routing logic within the existing `maybe_insert_job/4` clause. No new network endpoints, auth paths, file access, or schema changes.

## TDD Gate Compliance

- RED gate: `test(56-02)` commit 8dca7b1 (failing cron-path test proving ssn leaks via bare Oban.Job.new)
- GREEN gate: `feat(56-02)` commit 0ed9925 (routing fix makes all 12 cron tests pass)
- No REFACTOR gate needed (fix is minimal — single clause replacement with try/rescue block)

## Self-Check: PASSED
