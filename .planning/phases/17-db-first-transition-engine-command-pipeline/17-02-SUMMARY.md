---
phase: 17
plan: 02
subsystem: workflow-diagnosis
tags: [workflow, lifeline, liveview, explain, diagnosis]
requires: [WFS-02, REC-02, DIA-01, DIA-02]
provides:
  - shared workflow and step diagnosis read-model helpers
  - lifeline incidents and previews backed by the same rejection vocabulary as workflow inspection
  - workflow-step repair execution that re-enters the command core with operator identity and reason intact
key_files:
  created:
    - .planning/phases/17-db-first-transition-engine-command-pipeline/17-02-SUMMARY.md
  modified:
    - lib/oban_powertools/explain.ex
    - lib/oban_powertools/lifeline.ex
    - lib/oban_powertools/web/workflows_live.ex
    - lib/oban_powertools/web/router.ex
    - test/oban_powertools/lifeline_test.exs
    - test/oban_powertools/web/live/workflows_live_test.exs
    - test/oban_powertools/web/router_test.exs
completed_at: 2026-05-24
---

# Phase 17 Plan 02 Summary

Plan 17-02 converged workflow diagnosis and rejection vocabulary across runtime, Lifeline, and the native workflow screen. `ObanPowertools.Explain` now projects workflow and step stories, including latest rejected command evidence and bounded blocker summaries; Lifeline incidents and previews consume that projection; and `WorkflowsLive` renders the same durable diagnosis, semantics, and refusal hints. Workflow-step repairs also preserve the human actor and reason when they re-enter the shared runtime command core.

## Verification

- `mix test test/oban_powertools/lifeline_test.exs`
  Result: passed
- `mix test test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
  Result: passed

## Deviations from Plan

- Tightened `ObanPowertools.Web.Router.oban_powertools_routes/1` so native routes no longer disappear based on module compile order. That issue blocked the workflow UI proof and would have made support behavior nondeterministic in tests.

## Self-Check: PASSED
