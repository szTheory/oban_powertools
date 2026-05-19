---
phase: 4
plan: 02
subsystem: api
tags: [lifeline, heartbeat, telemetry, supervision]
requires:
  - phase: 4
    provides: durable heartbeat and incident tables
provides:
  - heartbeat refresh and health classification API
  - supervised heartbeat writer
  - dead-executor and workflow-stuck incident projection
affects: [repair-center, overview-ui]
tech-stack:
  added: []
  patterns: [durable liveness evidence, low-cardinality telemetry]
key-files:
  created:
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/lifeline/heartbeat_writer.ex
    - test/oban_powertools/lifeline_test.exs
  modified:
    - lib/oban_powertools/application.ex
    - lib/oban_powertools/telemetry.ex
key-decisions:
  - "Late heartbeats remain warning-only while missing heartbeats unlock dead-executor incidents."
patterns-established:
  - "Heartbeat state is refreshed through durable upsert, not inferred from job age alone."
requirements-completed: [LIF-01]
duration: checkpoint
completed: 2026-05-19
---

# Phase 4 Plan 02 Summary

**Durable heartbeat refresh, executor health classification, and conservative incident projection for dead executors and stuck workflow steps**

## Accomplishments
- Added heartbeat upsert and health classification APIs with `Healthy`, `Heartbeat Late`, and `Executor Missing`.
- Added a supervised heartbeat writer entry point under the application supervisor.
- Added incident projection that surfaces dead-executor and workflow-stuck evidence from persisted rows.

## Files Created/Modified
- `lib/oban_powertools/lifeline.ex` - heartbeat and incident API
- `lib/oban_powertools/lifeline/heartbeat_writer.ex` - supervised refresh worker
- `lib/oban_powertools/application.ex` - lifeline supervision hook
- `lib/oban_powertools/telemetry.ex` - lifeline telemetry wrapper
- `test/oban_powertools/lifeline_test.exs` - repo-backed liveness tests

## Decisions Made
- Executor health is derived from persisted heartbeat age thresholds, not runtime-only heuristics.

## Deviations from Plan
None.

## Next Phase Readiness
Repair preview and execute flows can now bind to durable incident evidence instead of inferring unsafe mutations directly from runtime state.
