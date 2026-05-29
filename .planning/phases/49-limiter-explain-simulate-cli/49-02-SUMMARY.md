---
phase: 49-limiter-explain-simulate-cli
plan: "02"
subsystem: cli
tags: [mix-task, explain, limiter, cli, ops]
dependency_graph:
  requires: ["49-01"]
  provides: ["Mix.Tasks.ObanPowertools.Limiter.Explain", "OPS-06", "OPS-08-partial"]
  affects: ["lib/mix/tasks/", "test/mix/tasks/"]
tech_stack:
  added: []
  patterns:
    - "Resource-primary explain path via explain_snapshot/2 (D-03)"
    - "Worker-secondary explain path via Explain.explain/3"
    - "Honest empty state: nil snapshot -> runnable (D-04)"
    - "Module.safe_concat with ArgumentError rescue for unknown module guard (T-49-03)"
    - "Closed status normalization at DB boundary (never String.to_atom)"
    - "Jason.decode/1 string-keyed args (T-49-04)"
    - "Source-inspection + DB-integration test split"
    - "Code.fetch_docs for compiled moduledoc glossary assertion (OPS-08)"
key_files:
  created:
    - lib/mix/tasks/oban_powertools.limiter.explain.ex
    - test/mix/tasks/oban_powertools.limiter.explain_test.exs
  modified: []
decisions:
  - "Used Module.safe_concat + rescue ArgumentError to handle unknown worker module atom (not yet in VM) — satisfies T-49-03 without using String.to_atom"
  - "Removed resolve_prefix/1 (unused — explain task does not need schema prefix for its queries); prefix switch is declared in @switches for CLI family consistency"
  - "Tested compiled @moduledoc for glossary terms via Code.fetch_docs (not File.read!) since Glossary.text/0 interpolation is evaluated at compile time, not visible in raw source"
metrics:
  duration: "~15m"
  completed: "2026-05-29T19:52:01Z"
  tasks_completed: 2
  files_created: 2
---

# Phase 49 Plan 02: Limiter Explain CLI Summary

Read-only operator CLI (`mix oban_powertools.limiter.explain`) that diagnoses a limiter's current blocking state via `ObanPowertools.Explain.explain_snapshot/2` (resource path) and `Explain.explain/3` (worker path), with the rate-limit glossary surfaced in `@moduledoc`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create the limiter.explain Mix task | be97468 | lib/mix/tasks/oban_powertools.limiter.explain.ex |
| 2 | Test the explain task (source-inspection + DB integration) | ec55f37 | test/mix/tasks/oban_powertools.limiter.explain_test.exs, lib/mix/tasks/oban_powertools.limiter.explain.ex |

## Verification

- `mix compile --warnings-as-errors`: clean
- `mix test test/mix/tasks/oban_powertools.limiter.explain_test.exs`: 20 tests, 0 failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rescue ArgumentError from Module.safe_concat for unknown worker modules**
- **Found during:** Task 2 (test run)
- **Issue:** `Module.safe_concat(["Does.Not.Exist.Worker"])` raises `ArgumentError` when the module atom doesn't exist in the VM yet, rather than returning the atom. The original implementation only checked `Code.ensure_loaded?` but `safe_concat` raises before we get there.
- **Fix:** Wrapped `Module.safe_concat/1` call in `try/rescue ArgumentError` in `resolve_worker/1`, returning `{:error, :not_loaded, worker_string}` on failure.
- **Files modified:** lib/mix/tasks/oban_powertools.limiter.explain.ex
- **Commit:** ec55f37

**2. [Rule 2 - Missing Critical Functionality] Added job_id: 0 to test snapshot inserts**
- **Found during:** Task 2 (test run)
- **Issue:** `oban_powertools_blocker_snapshots.job_id` has a NOT NULL constraint; the `Explain.changeset/2` validates `job_id` as optional in the code but the DB schema requires it.
- **Fix:** Added `job_id: 0` to the test helper `insert_explain_snapshot!/2`.
- **Files modified:** test/mix/tasks/oban_powertools.limiter.explain_test.exs
- **Commit:** ec55f37

**3. [Rule 1 - Adaptation] Removed unused resolve_prefix/1 function**
- **Found during:** Task 1 (compilation with --warnings-as-errors)
- **Issue:** `resolve_prefix/1` copied from doctor.ex but never called in the explain task (explain doesn't need schema prefix for its queries). Compiler emitted unused-function warning.
- **Fix:** Removed the function. The `--prefix` switch is still declared in `@switches` for CLI family consistency.
- **Files modified:** lib/mix/tasks/oban_powertools.limiter.explain.ex
- **Commit:** be97468 (included in Task 1 commit)

**4. [Rule 1 - Adaptation] Used Code.fetch_docs for glossary term assertion**
- **Found during:** Task 2 (test failure)
- **Issue:** The plan's source-inspection test checked `File.read!(@task_path) =~ "token_bucket"`, but the source file contains `#{ObanPowertools.Limits.Glossary.text()}` as a literal interpolation expression (D-08 single-source pattern). File.read! sees the unexpanded template.
- **Fix:** Changed test to use `Code.fetch_docs/1` to inspect the compiled `@moduledoc`, which contains the expanded glossary text. The source-inspection test now asserts `source =~ "Glossary"` (reference to the module).
- **Files modified:** test/mix/tasks/oban_powertools.limiter.explain_test.exs
- **Commit:** ec55f37

## Known Stubs

None — all paths return real data or honest empty-state messages.

## Threat Flags

None — no new network endpoints, no auth paths, no schema changes introduced. The task is read-only by construction (only `repo.one/2` queries, no inserts or updates).

## Self-Check: PASSED

- lib/mix/tasks/oban_powertools.limiter.explain.ex: FOUND
- test/mix/tasks/oban_powertools.limiter.explain_test.exs: FOUND
- .planning/phases/49-limiter-explain-simulate-cli/49-02-SUMMARY.md: FOUND
- commit be97468: FOUND
- commit ec55f37: FOUND
- commit 81422dc: FOUND
