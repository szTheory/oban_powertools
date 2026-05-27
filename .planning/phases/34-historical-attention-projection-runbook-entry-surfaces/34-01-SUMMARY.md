---
phase: 34-historical-attention-projection-runbook-entry-surfaces
plan: 01
subsystem: ui
tags: [phoenix-liveview, read-model, forensics, overview, tdd]

requires:
  - phase: 32-forensic-timeline-evidence-bundle-foundation
    provides: forensic evidence bundle and provenance vocabulary
  - phase: 33-limiter-history-cron-missed-fire-diagnostics
    provides: limiter and cron retained-history summaries
provides:
  - Bounded historical attention projection helper
  - Overview bucket exemplars backed by limiter and cron history summaries
  - Evidence-honest overview rendering with forensic timeline links
affects: [overview, forensics, runbook-entry-surfaces, example-host-contract]

tech-stack:
  added: []
  patterns:
    - Pure projection helper fed by read-model candidates
    - Existing diagnosis-first LiveView cards with optional exemplar metadata

key-files:
  created:
    - lib/oban_powertools/forensics/attention_projection.ex
    - examples/phoenix_host/priv/repo/migrations/20260522000015_oban_powertools_limiter_history_facts.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000016_oban_powertools_cron_coverages.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000015_oban_powertools_limiter_history_facts.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000016_oban_powertools_cron_coverages.exs
  modified:
    - lib/oban_powertools/web/overview_read_model.ex
    - lib/oban_powertools/web/engine_overview_live.ex
    - test/oban_powertools/forensics_test.exs
    - test/oban_powertools/web/live/engine_overview_live_test.exs

key-decisions:
  - "Historical attention remains inside the existing diagnosis-first overview buckets instead of becoming a new feed."
  - "Projection is pure and bounded; history summaries are assembled by the overview read model."
  - "Overview links use stable selectors only and keep reason, copy, and preview token data out of URLs."

patterns-established:
  - "AttentionProjection: normalize candidate completeness, rank by diagnosis impact, then cap each bucket at three."
  - "Overview exemplars: render evidence completeness only for partial evidence, history unavailable, or unknown states."

requirements-completed: [OPS-03, RNB-01]

duration: 21m 16s
completed: 2026-05-27
---

# Phase 34 Plan 01: Historical Attention Projection Summary

**Bounded historical attention projection for the `/ops/jobs` overview, with evidence-honest exemplar rendering and stable forensic links**

## Performance

- **Duration:** 21m 16s
- **Started:** 2026-05-27T06:18:42Z
- **Completed:** 2026-05-27T06:39:58Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added `ObanPowertools.Forensics.AttentionProjection` as a pure helper that ranks diagnosis-impacting history, normalizes evidence completeness, and caps each bucket at three exemplars.
- Wired overview bucket exemplars through limiter and cron history summaries without adding a new bucket, feed, or dashboard band.
- Rendered attention reasons, venue/ownership, degraded evidence labels, forensic timeline links, and quiet-bucket guidance inside the existing LiveView cards.
- Updated example host migration fixtures so contract hosts include the history tables used by the new overview path.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED:** `7d735b9` test(34-01): add failing tests for attention projection
2. **Task 1 GREEN:** `a12a585` feat(34-01): implement bounded attention projection
3. **Task 2 RED:** `9c1551b` test(34-01): add failing overview attention tests
4. **Task 2 GREEN:** `7eb4614` feat(34-01): wire attention projection into overview buckets
5. **Task 3 RED:** `c5c1eed` test(34-01): add failing overview attention rendering tests
6. **Task 3 GREEN:** `7168f5c` feat(34-01): render overview attention details
7. **Verification Fix:** `265be6c` fix(34-01): add example host history migrations

## Files Created/Modified

- `lib/oban_powertools/forensics/attention_projection.ex` - Pure bounded projection helper for attention candidate maps.
- `lib/oban_powertools/web/overview_read_model.ex` - Builds attention candidates from Lifeline, limiter, cron, and audit sources, then projects them into existing buckets.
- `lib/oban_powertools/web/engine_overview_live.ex` - Renders exemplar metadata, evidence links, runbook labels, and quiet-bucket empty state copy.
- `test/oban_powertools/forensics_test.exs` - Covers projection cap, deterministic ordering, degraded evidence, and path exclusion.
- `test/oban_powertools/web/live/engine_overview_live_test.exs` - Covers existing bucket preservation, attention rendering, empty state, and URL hygiene.
- `examples/phoenix_host/priv/repo/migrations/20260522000015_oban_powertools_limiter_history_facts.exs` - Adds limiter history table to the current example host.
- `examples/phoenix_host/priv/repo/migrations/20260522000016_oban_powertools_cron_coverages.exs` - Adds cron coverage table to the current example host.
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000015_oban_powertools_limiter_history_facts.exs` - Adds limiter history table to the upgrade source host.
- `examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000016_oban_powertools_cron_coverages.exs` - Adds cron coverage table to the upgrade source host.

## Decisions Made

- Historical attention projection stays inside existing overview buckets because OPS-03 requires a diagnosis-first scan model, not a feed.
- The projection helper does not query; the read model remains responsible for assembling source-aware candidates from existing history summaries.
- Evidence completeness is visible only when it changes operator certainty: `partial evidence`, `history unavailable`, or `unknown`.
- Forensic links use durable selectors (`resource_id`, `resource_type`, `incident_fingerprint`) and do not serialize rendered copy or preview tokens.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing example host history migrations**
- **Found during:** Overall verification after Task 3
- **Issue:** `mix test` failed in example host contract tests because the checked-in host fixtures lacked `oban_powertools_cron_coverages`, while the new overview path calls `CronHistory.summary/2`.
- **Fix:** Added limiter history and cron coverage migrations to both checked-in example host fixtures, matching the installer-generated migration set.
- **Files modified:** `examples/phoenix_host/priv/repo/migrations/*history*`, `examples/phoenix_host/priv/repo/migrations/*cron_coverages*`, `examples/phoenix_host_upgrade_source/priv/repo/migrations/*history*`, `examples/phoenix_host_upgrade_source/priv/repo/migrations/*cron_coverages*`
- **Verification:** `mix test test/oban_powertools/example_host_contract_test.exs` passed with 5 tests, then full `mix test` passed with 178 tests.
- **Committed in:** `265be6c`

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Required for verification and example-host correctness; no architecture or behavior change beyond aligning fixture migrations with installer output.

## Issues Encountered

- Task 2 acceptance referenced LiveView proof strings that were introduced by Task 3. The strings were verified after Task 3, where the relevant UI copy and tests exist.
- Full-suite verification initially failed before the example host fixture migrations were added; the rerun after `265be6c` passed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. Stub scan found only legitimate empty-list checks and blank-string filtering.

## Threat Flags

None. The plan introduced no new network endpoints, auth paths, file access patterns, or schema changes at runtime trust boundaries. The example-host migration additions align fixture databases with existing installer-generated tables.

## Verification

- `mix test test/oban_powertools/forensics_test.exs`
- `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/forensics_test.exs`
- `mix test test/oban_powertools/example_host_contract_test.exs`
- `mix test` -> 178 tests, 0 failures
- `rg -n "Historical Attention|raw event|event feed" lib/oban_powertools/web/overview_read_model.ex lib/oban_powertools/web/engine_overview_live.ex test/oban_powertools/web/live/engine_overview_live_test.exs` -> no matches

## Next Phase Readiness

Plan 34-02 can consume the projected overview entry points and stable selector URLs to build fuller runbook entry surfaces on drilldowns and forensics without revisiting overview bucket composition.

## Self-Check

PASSED. Verified all created/modified files exist and all task/deviation commits are present in git history.

---
*Phase: 34-historical-attention-projection-runbook-entry-surfaces*
*Completed: 2026-05-27*
