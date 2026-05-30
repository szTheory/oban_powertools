---
phase: 50-telemetry-metrics-slo-guide
plan: 01
subsystem: telemetry
tags: [telemetry_metrics, telemetry_poller, optional-deps, tdd, red-baseline]

# Dependency graph
requires: []
provides:
  - "Optional telemetry_metrics (only: [:test, :dev]) + telemetry_poller deps declared in mix.exs, gated like oban_web"
  - "guides/telemetry-and-slos.md reserved under Operations group in groups_for_extras"
  - "Failing RED tests for metrics/0 structural and tag-containment assertions"
affects: [50-02, 50-03]

# Tech tracking
tech-stack:
  added: [telemetry_metrics 1.1.0, telemetry_poller 1.3.0]
  patterns:
    - "optional: true + only: [:test, :dev] for test-accessible optional deps (mirrors oban_web posture)"
    - "RED baseline committed before implementation (TDD Wave 0 → Wave 1 cycle)"

key-files:
  created: []
  modified:
    - mix.exs
    - mix.lock
    - test/oban_powertools/telemetry_test.exs

key-decisions:
  - "telemetry_metrics declared only: [:test, :dev] so Telemetry.Metrics is loadable under mix test without a runtime dep"
  - "telemetry_poller declared with no only: restriction (guide-documentation only; no test or lib code calls it)"
  - "guides/telemetry-and-slos.md group entry inserted as second Operations entry (after optional-oban-web-bridge.md, closest thematic neighbor) — guide file itself deferred to Plan 03"

patterns-established:
  - "optional-dep declaration shape: {:pkg, version, only: [:test, :dev], optional: true} for test-accessible optional deps"
  - "groups_for_extras entry required even when guide file deferred — prevents ungrouped sidebar landing"
  - "RED tests committed before implementation file touched — metrics/0 undefined error is the expected baseline"

requirements-completed: [TEL-02]

# Metrics
duration: 5min
completed: 2026-05-30
---

# Phase 50 Plan 01: Telemetry Metrics & SLO Guide — Wave 0 Foundation Summary

**Optional telemetry_metrics + telemetry_poller deps declared in mix.exs (gated like oban_web), guide group reserved under Operations, and two failing RED tests scaffolded for metrics/0 as the TDD baseline.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-30T00:10:00Z
- **Completed:** 2026-05-30T00:13:25Z
- **Tasks:** 2
- **Files modified:** 3 (mix.exs, mix.lock, telemetry_test.exs)

## Accomplishments
- Added `{:telemetry_metrics, "~> 1.0", only: [:test, :dev], optional: true}` and `{:telemetry_poller, "~> 1.0", optional: true}` to mix.exs immediately after the oban_web optional dep, mirroring its shape exactly (TEL-02)
- Ran `mix deps.get`; mix.lock gained telemetry_metrics 1.1.0 and telemetry_poller 1.3.0; `Code.ensure_loaded?(Telemetry.Metrics)` returns `true` under `MIX_ENV=test`
- Reserved `"guides/telemetry-and-slos.md"` as the second Operations entry in groups_for_extras (guide file deferred to Plan 03)
- Scaffolded two failing tests in telemetry_test.exs: structural list assertion + tag-containment cardinality-safety check; both fail RED with `UndefinedFunctionError` as expected

## Task Commits

Each task was committed atomically:

1. **Task 1: Add optional telemetry deps + Operations guide group to mix.exs** - `4470d70` (chore)
2. **Task 2: Scaffold failing metrics/0 structural + tag-containment tests (RED)** - `31d1704` (test)

## Files Created/Modified
- `mix.exs` - Added two optional dep tuples + telemetry-and-slos.md group entry
- `mix.lock` - Gained telemetry_metrics 1.1.0 + telemetry_poller 1.3.0 entries
- `test/oban_powertools/telemetry_test.exs` - Two new failing tests for metrics/0 RED baseline

## Decisions Made
- `telemetry_metrics` gets `only: [:test, :dev]` so test suite can call `ObanPowertools.Telemetry.metrics()` without making it a required runtime dep; `telemetry_poller` gets no `only:` (no test or lib code references it, guide-documentation only)
- `guides/telemetry-and-slos.md` group entry inserted now even though the file doesn't exist yet — without it the guide would land ungrouped in the ExDoc sidebar when Plan 03 creates it

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 has a green target: implement `metrics/0` in `lib/oban_powertools/telemetry.ex` and run the suite to turn the two RED tests green. The tag-containment test will enforce cardinality safety automatically against the frozen `@contract`.

---
*Phase: 50-telemetry-metrics-slo-guide*
*Completed: 2026-05-30*
