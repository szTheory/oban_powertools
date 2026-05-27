---
phase: 33-limiter-history-cron-missed-fire-diagnostics
plan: 01
subsystem: limiters
requirements-completed: [OPS-01]
completed: 2026-05-27
implementation_commit: 1b36404
---

# 33-01 Summary: Limiter History Projection

Limiter history is now persisted as bounded diagnostic facts and projected through the shared forensic contract.

## Accomplishments

- Added `oban_powertools_limiter_history_facts` and `LimiterHistoryFact`.
- Added `ObanPowertools.Forensics.LimiterHistory`.
- Recorded limiter blocked, released, cooled-down, and reconfigured facts from existing limiter write paths.
- Added limiter history summaries and forensic deep links to the limiter detail surface.

## Verification

Covered by the targeted Phase 33 suite: `35 tests, 0 failures`.

