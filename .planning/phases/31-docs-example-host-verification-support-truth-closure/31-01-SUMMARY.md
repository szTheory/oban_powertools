---
phase: 31
plan: 01
subsystem: docs
tags: [docs, support-truth, bridge, host-contract]
requires: [DOC-04, HST-04]
provides: [native-control-plane-story, bridge-boundary-language, docs-contract-markers]
key_files:
  modified:
    - README.md
    - guides/support-truth-and-ownership-boundaries.md
    - guides/optional-oban-web-bridge.md
    - guides/example-app-walkthrough.md
    - guides/first-operator-session.md
    - guides/upgrade-and-compatibility.md
    - examples/phoenix_host/README.md
    - test/oban_powertools/docs_contract_test.exs
completed_at: 2026-05-26
---

# Phase 31 Plan 01 Summary

Phase 31 plan 01 aligned the promise-shaping docs around one explicit contract: the unified native `/ops/jobs` control plane is the supported Powertools operator surface, while `/ops/jobs/oban` remains a narrower read-only Oban Web bridge for generic inspection only. The touched guides and example-host README now repeat the same native-versus-bridge boundary, name overview and audit as part of the same native control-plane story, and keep host-owned seams visible instead of implying hidden library ownership.

## Verification

- `mix test test/oban_powertools/docs_contract_test.exs`
  Result: passed
- `rg -n 'unified native `/ops/jobs` control plane|Inspection only|host-owned|/ops/jobs/oban|read-only' README.md guides/support-truth-and-ownership-boundaries.md guides/optional-oban-web-bridge.md guides/example-app-walkthrough.md guides/first-operator-session.md guides/upgrade-and-compatibility.md examples/phoenix_host/README.md`
  Result: passed

## Deviations from Plan

None. The docs pass stayed inside the promise-shaping set and tightened existing language rather than expanding into a repo-wide editorial sweep.

## Self-Check: PASSED
