---
phase: 43-read-only-job-browse
plan: "01"
subsystem: jobs-context
tags:
  - oban
  - ecto
  - context-module
  - display-policy
dependency_graph:
  requires: []
  provides:
    - ObanPowertools.Jobs context module
    - "%JobFilter{} struct"
    - Jobs.list/3
    - Jobs.get/2
    - Jobs.count_by_state/2
    - DisplayPolicy.render_job_field/3
    - Selectors.jobs_path/1
    - ":jobs canonical path entry"
  affects:
    - lib/oban_powertools/jobs.ex
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/web/selectors.ex
    - test/oban_powertools/jobs_test.exs
tech_stack:
  added: []
  patterns:
    - nil-pass-first private filter helpers (maybe_filter_*)
    - repo-as-first-arg context module convention (matches Cron, Lifeline)
    - state-leading WHERE clause for composite index usage (D-05)
    - rescue safety net wrapping host display policy calls (D-16)
key_files:
  created:
    - lib/oban_powertools/jobs.ex
    - test/oban_powertools/jobs_test.exs
  modified:
    - lib/oban_powertools/runtime_config.ex
    - lib/oban_powertools/web/selectors.ex
decisions:
  - "State leads every WHERE clause in Jobs.list/3 and Jobs.count_by_state/2 (D-05) — enforces composite index usage"
  - "count_by_state/2 iterates 7 states with separate queries (not GROUP BY) to guarantee all 7 keys even at zero count (D-13)"
  - "render_job_field/3 wraps entire body in rescue to prevent misbehaving host policy from crashing LiveView (D-16)"
  - "jobs_path/1 mirrors lifeline_path/1 exactly with optional params default to []"
metrics:
  duration: "5 minutes"
  completed: "2026-05-28"
  tasks_completed: 3
  files_count: 4
---

# Phase 43 Plan 01: Data + Helper Contract Layer Summary

**One-liner:** Ecto-native job query context (`ObanPowertools.Jobs`) with `%JobFilter{}` struct, state-leading queries, offset pagination, GIN-index caveat, keyset upgrade path, `DisplayPolicy.render_job_field/3` redaction helper, and `Selectors.jobs_path/1` — all 9 unit tests green.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create ObanPowertools.Jobs context module | 6468cff | lib/oban_powertools/jobs.ex (new) |
| 2 | Extend DisplayPolicy with render_job_field/3 and add Selectors.jobs_path/1 | ad0759c | runtime_config.ex, selectors.ex |
| 3 | Write unit tests for ObanPowertools.Jobs | aaa1825 | test/oban_powertools/jobs_test.exs (new) |

## File-by-File Diff Summary

### `lib/oban_powertools/jobs.ex` (new — 143 lines)

New `ObanPowertools.Jobs` context module with:
- `@moduledoc` documenting GIN index caveat (D-04), keyset upgrade path (D-03), and query ownership boundary
- `%JobFilter{}` defstruct: `state: :available, queue: nil, worker: nil, tags: nil, page: 1, page_size: 20` (D-01, D-10)
- `list/3` — `where([j], j.state == ^to_string(filter.state))` leads every WHERE clause, followed by optional `maybe_filter_*` helpers, `ORDER BY scheduled_at DESC, id DESC` (D-11), limit/offset pagination (D-03)
- `get/2` — delegates to `repo.get(Oban.Job, job_id)`
- `count_by_state/2` — iterates all 7 state strings, one COUNT query per state with non-state filters applied, returns `%{"available" => n, ...}` (D-13)
- Private helpers: `maybe_filter_queue/2`, `maybe_filter_worker/2`, `maybe_filter_tags/2` (nil-pass-first clause)

### `lib/oban_powertools/runtime_config.ex` (modified — +13 lines)

Added `def render_job_field(kind, value, context)` to `ObanPowertools.DisplayPolicy`:
- `nil` → `{:raw_json, Jason.encode!(value || %{}, pretty: true)}`
- `binary` → `{:string, text}`
- `%{} map` → `{:raw_json, Jason.encode!(redacted_map, pretty: true)}`
- other → `raise ArgumentError` (caught by rescue)
- `rescue _ -> {:fallback, "[redacted]"}` safety net (D-16, T-43-01-04)
- No existing functions modified

### `lib/oban_powertools/web/selectors.ex` (modified — +4 lines)

- Added `jobs: "/ops/jobs/jobs"` to `@canonical_paths` map
- Added `def jobs_path(params \\ []), do: encode(:jobs, params)` with matching `@doc`
- No existing functions modified

### `test/oban_powertools/jobs_test.exs` (new — 166 lines)

9 tests covering all behavioral requirements:
1. `list/3 filters by state with state leading the WHERE clause`
2. `list/3 narrows by queue`
3. `list/3 narrows by worker`
4. `list/3 narrows by tags via @> array contains`
5. `list/3 orders by scheduled_at DESC, id DESC` (D-11, identical scheduled_at, higher id first)
6. `list/3 paginates by page/page_size` (D-03)
7. `get/2 returns job by id, nil when not found`
8. `count_by_state/2 returns map with all 7 state keys including zero counts` (D-13)
9. `count_by_state/2 honors non-state filters from base_filter`

## Test Results

```
mix test test/oban_powertools/jobs_test.exs
9 tests, 0 failures
```

## Compile Warnings

Pre-existing warning in `lib/oban_powertools/web/forensics_live.ex:362`: `function continuity_action/1 is unused` — exists in main repo before this plan, not introduced by this plan. No new warnings in any files created or modified by this plan.

## Decision-ID Confirmation

| D-ID | Description | Implemented |
|------|-------------|-------------|
| D-01 | `%JobFilter{}` struct defined before any event handler | ✓ `defstruct` in `lib/oban_powertools/jobs.ex` |
| D-03 | Offset pagination with keyset upgrade path documented | ✓ limit/offset in `list/3`; upgrade path in `@moduledoc` |
| D-04 | GIN index caveat documented in module doc | ✓ `CREATE INDEX CONCURRENTLY oban_jobs_tags_gin ...` in `@moduledoc` |
| D-05 | State leads every WHERE clause | ✓ `where([j], j.state == ^to_string(filter.state))` is always first |
| D-10 | `Jobs.list/3`, `Jobs.get/2` with repo as first arg | ✓ both public functions follow `def func(repo, ...)` convention |
| D-11 | Default order `ORDER BY scheduled_at DESC, id DESC` | ✓ `order_by([j], [desc: j.scheduled_at, desc: j.id])` |
| D-13 | `count_by_state/2` returns map with all 7 state string keys | ✓ iterates `~w(available scheduled executing retryable cancelled discarded completed)` |
| D-16 | `render_job_field/3` with three-arm return contract + rescue | ✓ `{:raw_json, _}`, `{:string, _}`, `{:fallback, "[redacted]"}` arms present |

## Deviations from Plan

None — plan executed exactly as written. The pre-existing `continuity_action/1` warning in `forensics_live.ex` is an out-of-scope issue not introduced by this plan; logged as a pre-existing condition.

## Known Stubs

None — all functions fully implemented with production-ready Ecto queries.

## Self-Check: PASSED

Files verified:
- `lib/oban_powertools/jobs.ex` FOUND
- `lib/oban_powertools/runtime_config.ex` FOUND (modified)
- `lib/oban_powertools/web/selectors.ex` FOUND (modified)
- `test/oban_powertools/jobs_test.exs` FOUND

Commits verified:
- 6468cff FOUND (feat: Jobs context module)
- ad0759c FOUND (feat: DisplayPolicy + Selectors)
- aaa1825 FOUND (test: unit tests)
