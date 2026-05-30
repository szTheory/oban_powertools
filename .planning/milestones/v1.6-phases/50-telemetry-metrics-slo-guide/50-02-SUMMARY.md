---
phase: 50-telemetry-metrics-slo-guide
plan: 02
subsystem: telemetry
tags: [telemetry_metrics, elixir, optional-dep, counters, cardinality-safety]

# Dependency graph
requires:
  - phase: 50-01
    provides: "RED test scaffolding (structural + tag-containment tests), optional dep wiring in mix.exs"
provides:
  - "metrics/0 public function in ObanPowertools.Telemetry returning 17 counter definitions across 5 frozen families"
  - "Code.ensure_loaded? guard raising actionable RuntimeError when telemetry_metrics absent"
  - "apply/3-based call pattern deferring Telemetry.Metrics resolution to runtime"
  - "config/prod.exs enabling MIX_ENV=prod compile"
affects: [50-03, telemetry-and-slos-guide]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "apply/3 runtime dispatch for optional-dep functions (instead of import or module-attribute level reference)"
    - "Code.ensure_loaded? unless/raise guard for opt-in API entry points"

key-files:
  created:
    - "config/prod.exs"
  modified:
    - "lib/oban_powertools/telemetry.ex"

key-decisions:
  - "Use apply/3 instead of import Telemetry.Metrics inside function body — import is compile-time and fails in prod tree where telemetry_metrics is only: [:test, :dev]"
  - "Raise RuntimeError (not return []) when dep absent — the caller explicitly requested metrics, silent fallback would hide misconfiguration (D-04 / TEL-02)"
  - "counter/2 only for v1.0 — archived_count/pruned_count live in metadata map not measurements map, sum/2 would need a measurement function, defer to keep v1.0 clean"
  - "Tags omit :action where it mirrors the event-name suffix (D-02 / Pitfall 4) — e.g. limiter.blocked has no :action tag since :action='blocked' adds no information"

patterns-established:
  - "apply/3 runtime dispatch: fn name, opts -> apply(Module, :fun, [name, opts]) end — use when optional dep must compile-absent"
  - "Code.ensure_loaded? + raise guard: always raise for explicitly-called opt-in APIs; only use silent if/else for background initialization (application.ex pattern)"

requirements-completed: [TEL-01, TEL-02]

# Metrics
duration: 15min
completed: 2026-05-29
---

# Phase 50 Plan 02: metrics/0 with optional-dep guard Summary

**`ObanPowertools.Telemetry.metrics/0` implemented as 17 Telemetry.Metrics counters over 5 frozen families with apply/3-based runtime dispatch, Code.ensure_loaded? raise guard, and verified prod-tree compile sans telemetry_metrics**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-29T20:16:00Z
- **Completed:** 2026-05-29T20:20:30Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `metrics/0` returns 17 `Telemetry.Metrics.Counter` structs across operator_action (2), limiter (3), cron (4), workflow (4), lifeline (4) families
- `Code.ensure_loaded?(Telemetry.Metrics)` guard raises a multi-line actionable `RuntimeError` naming `:telemetry_metrics` and giving exact dep and `mix deps.get` instructions
- `apply/3` runtime dispatch avoids compile-time resolution of `Telemetry.Metrics.counter/2` — prod tree compiles clean with `telemetry_metrics` absent
- All 9 telemetry tests pass: 2 Wave-0 RED tests now GREEN; 7 existing emission tests still GREEN
- Tags are strict subsets of `@contract` per-family/suffix — no `:job_id`, `:args`, `:reason`, `:archived_count`, or `:pruned_count`

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement metrics/0 with Code.ensure_loaded? guard** - `4820915` (feat)
2. **Task 2: Fix prod-tree compile — apply/3 + config/prod.exs** - `8e87bdb` (fix)

## Files Created/Modified

- `lib/oban_powertools/telemetry.ex` — Added `metrics/0` with 17 counter definitions and guard; switched from `import` to `apply/3` for compile-time safety
- `config/prod.exs` — Created minimal `import Config` to enable `MIX_ENV=prod mix compile`

## Decisions Made

- **apply/3 over import:** `import Telemetry.Metrics` is a compile-time directive; even inside a function body, Elixir resolves it at compile time and fails when the dep is absent. `apply/3` via an anonymous function closure defers resolution to runtime, after the `Code.ensure_loaded?` guard has confirmed availability.
- **Raise, not return []:** The caller explicitly invoked `metrics/0`; returning `[]` would silently misconfigure the host's Telemetry supervisor. A clear RuntimeError with actionable instructions is the honest failure mode (TEL-02 / D-04).
- **counter/2 only:** `:archived_count` and `:pruned_count` live in the metadata map (3rd arg to `:telemetry.execute/3`), not the measurements map. A `sum/2` for these would need `measurement: fn _m, meta -> Map.get(meta, :archived_count, 0) end` — complexity deferred to v1.1+.
- **Tags omit :action where suffix is self-descriptive:** `limiter.blocked` and `limiter.released` don't tag `:action`; the event name already encodes the action. Reduces cardinality with no information loss (D-02).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `import Telemetry.Metrics` fails at prod compile time**
- **Found during:** Task 2 (prod-tree compile verification)
- **Issue:** `import Telemetry.Metrics, only: [counter: 2]` inside the function body still causes a `CompileError: module Telemetry.Metrics is not loaded` in `MIX_ENV=prod` because `import` is resolved at compile time regardless of placement
- **Fix:** Replaced `import` + bare `counter(...)` calls with `counter = fn name, opts -> apply(Telemetry.Metrics, :counter, [name, opts]) end` closure; all calls updated to `counter.(...)` syntax
- **Files modified:** `lib/oban_powertools/telemetry.ex`
- **Verification:** `MIX_ENV=prod mix compile --force` exits 0 with no `Telemetry.Metrics` error; all 9 tests still pass
- **Committed in:** `8e87bdb` (Task 2 commit)

**2. [Rule 3 - Blocking] Missing `config/prod.exs` prevented `MIX_ENV=prod mix compile`**
- **Found during:** Task 2 (first attempt at prod-tree compile)
- **Issue:** `config/config.exs` calls `import_config "#{config_env()}.exs"` but `config/prod.exs` did not exist in the worktree — `File.Error: could not read file config/prod.exs`
- **Fix:** Created `config/prod.exs` with `import Config` (matching the pattern of `config/dev.exs`)
- **Files modified:** `config/prod.exs` (created)
- **Verification:** `MIX_ENV=prod mix compile --force` no longer fails on config read
- **Committed in:** `8e87bdb` (Task 2 commit)

**3. [Deviation - Worktree] Symlinked deps/_build for test execution**
- **Context:** The worktree at `.claude/worktrees/agent-a2a34ec4600a87a78/` does not have its own `deps/` or `_build/` directories; the test verification command `cd /Users/jon/projects/oban_powertools && mix test ...` runs against the main project which doesn't have the worktree's changes
- **Fix:** Created symlinks `deps -> ../../deps` and `_build -> ../../_build` in the worktree to share the main project's compiled artifacts; ran tests from the worktree directory
- **Note:** Symlinks are untracked (in `.gitignore` implicitly via the worktree pattern); tests pass correctly using shared artifacts

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking) + 1 worktree-mode infrastructure adaptation
**Impact on plan:** Both auto-fixes are essential for correctness (prod compile safety). No scope creep.

## Issues Encountered

- The `50-PATTERNS.md` recommended `import Telemetry.Metrics, only: [counter: 2]` inside the function body, but this is incorrect for Elixir — `import` is always a compile-time directive. The patterns doc's stated caveat ("keep ALL Telemetry.Metrics.* references inside the function body") was correct in intent but the suggested mechanism (`import`) does not actually defer to runtime. `apply/3` is the correct idiomatic Elixir solution.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. `metrics/0` is a pure data function. The threat mitigations specified in the plan are all verified:
- T-50-02: tags are strict subsets of `@contract` — tag-containment test asserts every tag ∈ contract per family+suffix
- T-50-03: `:archived_count`/`:pruned_count` excluded from all metric `:tags` lists
- T-50-04: `Code.ensure_loaded?` guard raises actionable error instead of returning `[]`

## Next Phase Readiness

- `metrics/0` is complete and tests green — Plan 50-03 (telemetry guide authoring) can proceed
- `config/prod.exs` now exists — future prod compile tasks will not hit the missing-file blocker
- The `apply/3` pattern is established for any future optional-dep API functions

---
*Phase: 50-telemetry-metrics-slo-guide*
*Completed: 2026-05-29*
