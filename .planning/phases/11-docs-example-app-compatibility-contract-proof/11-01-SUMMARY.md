---
phase: 11
plan: 01
subsystem: docs
tags: [readme, exdoc, guides, installation]
requires: [DOC-01, HST-03]
provides: [day-0-docs-surface, exdoc-guide-wiring, honest-display-policy-contract]
key_files:
  created:
    - guides/installation.md
    - guides/first-operator-session.md
    - guides/example-app-walkthrough.md
  modified:
    - README.md
    - mix.exs
    - mix.lock
completed_at: 2026-05-22
---

# Phase 11 Plan 01 Summary

Phase 11 now has a real docs surface: the README is reduced to the honest entry contract, ExDoc publishes grouped day-0/day-2 guides, and the first three guides walk a host through installation, first operator session, and the canonical example host.

## Verification

- `mix docs`
  Result: passed
- `rg -n "groups_for_extras|Path\\.wildcard\\(\"guides/\\*\\.md\"\\)|display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy|examples/phoenix_host|read-only|Native Powertools pages own audited mutations" mix.exs README.md`
  Result: passed
- `rg -n "display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy|oban_powertools_routes\\(\"/oban\"\\)|/ops/jobs/oban|audited mutation|mix phx.new|mix oban_powertools.install" guides/installation.md guides/first-operator-session.md guides/example-app-walkthrough.md`
  Result: passed

## Deviations from Plan

None. The hidden-module warning from `ObanPowertools.Web.Router` was pre-existing and did not block docs generation.

## Self-Check: PASSED
