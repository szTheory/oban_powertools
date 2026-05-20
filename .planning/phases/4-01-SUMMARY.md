---
phase: 4
plan: 01
subsystem: database
tags: [ecto, postgres, lifeline, repair, archive]
requires:
  - phase: 3
    provides: workflow persistence and runtime records used by Phase 4
provides:
  - durable Phase 4 tables for heartbeats, incidents, repair previews, archive runs, and repair archives
  - repo-backed Phase 4 migration wiring for tests
affects: [lifeline, repair-center, retention]
tech-stack:
  added: []
  patterns: [explicit Ecto schema contracts, repo-backed migration parity]
key-files:
  created:
    - test/support/migrations/3_phase_4_tables.exs
    - lib/oban_powertools/lifeline/heartbeat.ex
    - lib/oban_powertools/lifeline/incident.ex
    - lib/oban_powertools/lifeline/repair_preview.ex
    - lib/oban_powertools/lifeline/archive_run.ex
  modified:
    - lib/mix/tasks/oban_powertools.install.ex
    - test/mix/tasks/oban_powertools.install_test.exs
    - test/test_helper.exs
key-decisions:
  - "Phase 4 storage stays explicit and Postgres-native before any runtime or UI behavior lands."
patterns-established:
  - "Installer migration contract and repo-backed test migration stay in lockstep."
requirements-completed: []
duration: checkpoint
completed: 2026-05-19
---

# Phase 4 Plan 01 Summary

**Durable Phase 4 persistence contracts for heartbeats, incidents, repair previews, archive runs, and archived repair evidence**

## Accomplishments
- Added Phase 4 installer migrations for all lifeline and retention tables.
- Added repo-backed Phase 4 migration support so tests can boot the same schema contract locally.
- Added Ecto schemas for heartbeat, incident, repair preview, and archive run records.

## Files Created/Modified
- `lib/mix/tasks/oban_powertools.install.ex` - Phase 4 installer migrations
- `test/support/migrations/3_phase_4_tables.exs` - repo-backed Phase 4 test migration
- `test/test_helper.exs` - bootstraps Phase 4 tables in the test repo
- `lib/oban_powertools/lifeline/*.ex` - durable Phase 4 schema modules

## Decisions Made
- Used explicit columns for health state, fingerprints, plan hashes, counts, and archive evidence instead of opaque blobs.

## Deviations from Plan
None.

## Next Phase Readiness
The backend can now build liveness, repair, and retention behavior on top of durable Phase 4 tables.
