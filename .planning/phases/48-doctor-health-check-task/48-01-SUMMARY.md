---
phase: 48-doctor-health-check-task
plan: "01"
subsystem: doctor
tags: [doctor, health-check, catalog-sql, exit-codes, tdd]
dependency_graph:
  requires: []
  provides:
    - ObanPowertools.Doctor.Finding struct
    - ObanPowertools.Doctor.run/2 orchestrator
    - ObanPowertools.Doctor.exit_code_for/1
    - ObanPowertools.Doctor.Checks (five read-only catalog checks)
  affects:
    - lib/oban_powertools/doctor.ex
    - lib/oban_powertools/doctor/checks.ex
tech_stack:
  added: []
  patterns:
    - pg_catalog parameterized SQL via repo.query/3
    - information_schema presence queries with ANY($2) array binding
    - Oban.Migrations.Postgres.current_version/0 for compile-time version constant
    - Regex identifier validation before schema-qualified FROM clause (T-48-01 pattern b)
    - DataCase async:false for non-transactional catalog DDL tests
    - Direct Postgrex connection for on_exit index restoration (sandbox teardown workaround)
key_files:
  created:
    - lib/oban_powertools/doctor.ex
    - lib/oban_powertools/doctor/checks.ex
    - test/oban_powertools/doctor_test.exs
    - test/oban_powertools/doctor/checks_test.exs
  modified: []
decisions:
  - "Implemented uniqueness_timeout_risk in the same commit as other checks (Tasks 2+3 merged) — all five checks share the same module and the task boundary was a logical artifact of the TDD plan, not a technical boundary"
  - "on_exit index restoration uses direct Postgrex connection (not the sandbox) because CREATE INDEX CONCURRENTLY cannot run inside a transaction and the sandbox connection is torn down before on_exit runs"
  - "findings_for_index_rows/2 is a public @doc false helper to enable unit-testing INVALID index finding construction without needing a real INVALID index"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-29T16:45:45Z"
  tasks_completed: 3
  files_created: 4
  files_modified: 0
---

# Phase 48 Plan 01: Doctor Core — Finding Struct, Orchestrator, Five Read-Only Checks Summary

Five-check read-only doctor core: `%Finding{}` struct, `exit_code_for/1` reduction, `run/2` orchestrator, and all five `Checks.*` functions with parameterized SQL and identifier-safe count queries.

## What Was Built

### `lib/oban_powertools/doctor.ex`

Defines `ObanPowertools.Doctor.Finding` (nested `defstruct` with `@enforce_keys [:check, :severity, :message]` and optional `:remediation`) and the `ObanPowertools.Doctor` orchestrator module with:
- `run(repo, opts)`: pipes all five Checks.* calls into a flat `[%Finding{}]` list; reads `prefix:` (default `"public"`) and `strict:` from opts
- `exit_code_for(findings)`: pure severity reduction returning 0 (clean), 1 (warnings only), 2 (any error)

### `lib/oban_powertools/doctor/checks.ex`

Five strictly read-only catalog check functions:

1. **`index_validity/2`** — pg_catalog join query with `n.nspname = $1` binding; extracts a separately-testable `findings_for_index_rows/2` helper that maps `indisvalid=false || indisready=false` rows to `:error` findings with `REINDEX INDEX CONCURRENTLY` remediation
2. **`missing_indexes/2`** — same catalog query; compares present index names against the 5 expected v14 indexes; each absent index = `:error` finding
3. **`oban_migration_version/2`** — parameterized `pg_catalog.obj_description` query (prefix as `$1`); compares `db_version` against `Oban.Migrations.Postgres.current_version()` (compile-time constant 14); version 0 = absent = `:error`; drift = `:error`; parity = `[]`
4. **`powertools_tables/1`** — `information_schema.tables` query with `table_name = ANY($1)` for all 24 Powertools tables in 4 named migration groups (foundation/smart-engine/workflow/heartbeat-lifeline); always checks `public` schema; per-group `:error` finding with missing table list
5. **`uniqueness_timeout_risk/3`** — sub-check A: GIN index absence from pg_catalog (reusing same query); sub-check B: eligible job count via regex-validated identifier prefix (T-48-01 pattern b); severity `:warning` by default, `:error` under `strict: true` (D-05)

**Security:** `@uniqueness_backlog_threshold 50_000` module attribute; all prefix/array values bound as `$1`/`$2`; count query uses `valid_identifier?/1` regex guard (`/^[a-z_][a-z0-9_]*$/`) before the only identifier use of prefix; no `@requirements`, no `Oban.start_link`, no INSERT/UPDATE/DELETE

### Test Files

- `test/oban_powertools/doctor_test.exs` — `DataCase async:false`; exit_code_for/1 unit tests (0/1/2 cases), Finding struct enforcement tests, and integration test asserting `Doctor.run(TestRepo, prefix: "public")` returns `[%Finding{}]` with `exit_code_for == 0` on the healthy DB
- `test/oban_powertools/doctor/checks_test.exs` — `DataCase async:false`; per-describe blocks for all five checks; index drop/restore tests using direct Postgrex connection in on_exit callbacks

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `CREATE INDEX CONCURRENTLY` fails in sandbox transactions**

- **Found during:** Task 2/3 test execution
- **Issue:** `on_exit` callbacks run after the Sandbox connection is torn down; `CREATE INDEX CONCURRENTLY` also cannot run inside a transaction (which the Sandbox uses)
- **Fix:** Added `direct_postgrex_query!/1` helper in checks_test.exs that opens a direct Postgrex connection (with the `pool` key removed from config) for index restoration in `on_exit` callbacks
- **Files modified:** `test/oban_powertools/doctor/checks_test.exs`
- **Commit:** 0489cb3

**2. [Scope - Task consolidation] Tasks 2 and 3 implemented together**

- **Found during:** Planning execution
- **Issue:** The uniqueness_timeout_risk check is naturally part of the same checks.ex module as the four Task 2 checks; implementing it separately would require a stub-and-replace cycle with no benefit
- **Fix:** Implemented all five checks in the single Task 2 feat commit; the Task 3 acceptance criteria (integration test in doctor_test.exs) were already satisfied by the Task 1 stubs which became real assertions
- **Files modified:** None (no extra changes needed)
- **Commit:** 0489cb3 (contains all five checks)

### Dependency resolution: worktree deps isolation

The git worktree didn't have deps or `_build` compiled. `mix deps.get` was run in the worktree to pull and compile deps independently. This is a setup artifact of the worktree isolation model — not a code deviation.

## Known Stubs

None. All five checks are fully implemented and wired into `run/2`.

## Threat Flags

None. All threat-model mitigations from the plan's `<threat_model>` were applied:
- T-48-01: prefix bound as `$1` throughout; count query uses regex-validate-then-quote pattern
- T-48-02: all queries filter by namespace; Powertools tables pinned to `'public'`
- T-48-03: `{:error, reason}` from `repo.query/3` becomes a `:error`-severity cannot-run Finding
- T-48-04: no `@requirements`, no `Oban.start_link`, all five checks are SELECT-only

## Self-Check: PASSED

All source files verified present:
- FOUND: lib/oban_powertools/doctor.ex
- FOUND: lib/oban_powertools/doctor/checks.ex
- FOUND: test/oban_powertools/doctor_test.exs
- FOUND: test/oban_powertools/doctor/checks_test.exs
- FOUND: .planning/phases/48-doctor-health-check-task/48-01-SUMMARY.md

All commits verified present:
- FOUND: 28407a5 (Task 1: RED stubs)
- FOUND: 0489cb3 (Task 2+3: full implementation)
