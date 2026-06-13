---
phase: 57-doctor-manifest-fix
plan: "01"
subsystem: doctor
tags: [doctor, manifest, output-recording, integration-fix, INT-01]
dependency_graph:
  requires: [Phase 55 output-recording shipped oban_powertools_job_records]
  provides: [Doctor detects missing oban_powertools_job_records table]
  affects: [lib/oban_powertools/doctor/checks.ex, test/oban_powertools/doctor/checks_test.exs]
tech_stack:
  added: []
  patterns: [manifest-driven table detection via Enum.flat_map]
key_files:
  created: []
  modified:
    - lib/oban_powertools/doctor/checks.ex
    - test/oban_powertools/doctor/checks_test.exs
decisions:
  - Group name "output-recording" matches the record_output: worker option and ObanPowertools.JobRecord naming convention
  - No change to powertools_tables/1 function — existing Enum.flat_map iteration handles the new group automatically
metrics:
  duration: ~5 min
  completed: "2026-06-13"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 2
---

# Phase 57 Plan 01: Doctor Manifest Fix (INT-01) Summary

**One-liner:** Added `"output-recording" => ["oban_powertools_job_records"]` to `@powertools_manifest` in Doctor/checks.ex so the health check detects the missing Phase 55 output-recording table.

## What Was Built

Closed the silent INT-01 integration gap from Phase 55: the `oban_powertools_job_records` table was shipped without being added to the Doctor manifest, meaning `mix oban_powertools.doctor` gave a clean bill of health on under-migrated databases.

Two co-dependent edits:

1. **`lib/oban_powertools/doctor/checks.ex`** — Added a trailing comma to the closing `]` of the `"heartbeat-lifeline"` entry and appended a new `"output-recording" => ["oban_powertools_job_records"]` group as the fifth entry in `@powertools_manifest`. The existing `powertools_tables/1` function iterates the manifest via `Enum.flat_map` and requires no change — it now automatically includes the new group.

2. **`test/oban_powertools/doctor/checks_test.exs`** — Updated the happy-path test description on line 104 from `"returns [] on the migrated test DB (all 4 groups present)"` to `"returns [] on the migrated test DB (all 5 groups present)"`.

## Verification

- `mix compile --warnings-as-errors` exits 0 (no SyntaxError from the manifest edit)
- `mix test test/oban_powertools/doctor/checks_test.exs` — 18 tests, 0 failures
- Happy-path test confirms `oban_powertools_job_records` is present in test DB (returns `[]`)
- `"output-recording" =>` found in checks.ex
- `"oban_powertools_job_records"` found in checks.ex output-recording group
- `"all 5 groups present"` in test file; `"all 4 groups present"` absent

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add output-recording group to manifest and update test description | a41adc9 | lib/oban_powertools/doctor/checks.ex, test/oban_powertools/doctor/checks_test.exs |

## Deviations from Plan

None - plan executed exactly as written. Both edits were straightforward data-only additions with no structural changes required.

## Known Stubs

None.

## Threat Flags

None. This change is purely additive to a read-only manifest used by a diagnostic CLI (`mix oban_powertools.doctor`). No new network endpoints, auth paths, or schema mutations introduced.

## Self-Check: PASSED

- [x] `lib/oban_powertools/doctor/checks.ex` exists and contains `"output-recording" =>` at line 59
- [x] `test/oban_powertools/doctor/checks_test.exs` exists and contains `"all 5 groups present"` at line 104
- [x] Commit a41adc9 verified: `git log --oneline -1` confirms `feat(57-01): add output-recording group to @powertools_manifest`
- [x] 18 tests, 0 failures on the Doctor checks test suite
