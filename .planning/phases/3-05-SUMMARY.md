---
phase: 3
plan: 05
subsystem: web
tags: [workflow, liveview, ui, ops]
requires:
  - phase: 3
    provides: workflow runtime and blocker explanation contracts
provides:
  - native `/ops/jobs/workflows` UI
  - blocked-step and dependency inspection flows
requirements-completed: [WF-03]
retrospective-proof-added-in: Phase 5
completed: 2026-05-19
---

# Phase 3 Plan 05 Summary

## Completed

- Added native workflow routes under `/ops/jobs/workflows`.
- Extended the overview page with workflow entry points and workflow counts.
- Added read-only `ObanPowertools.Web.WorkflowsLive` for workflow index/detail inspection with blocker and dependency detail.
- Added route and LiveView coverage for auth, blocked-step inspection, and stable selected-node refresh.

## Verification

- `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs`

## Deviations

- The first workflow UI is intentionally explanation-first and table-driven rather than a richer graphical DAG renderer.
