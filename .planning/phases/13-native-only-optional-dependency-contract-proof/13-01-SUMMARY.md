---
phase: 13
plan: 01
subsystem: proof
tags: [tests, example-host, optional-dependency, oban-web, native-first]
requires: [PKG-03, DOC-03]
provides:
  - honest native-only copied-host dependency proof
  - bounded optional bridge render smoke through shared session auth
  - no-optional-deps compile safety for Powertools optional web references
key_files:
  created:
    - examples/phoenix_host/test/phoenix_host_web/oban_web_bridge_smoke_test.exs
    - .planning/phases/13-native-only-optional-dependency-contract-proof/13-01-SUMMARY.md
  modified:
    - test/support/example_host_contract.ex
    - test/oban_powertools/example_host_contract_test.exs
    - lib/oban_powertools/workflow/coordinator.ex
    - lib/oban_powertools/workflow/signal.ex
    - lib/oban_powertools/web/router.ex
completed_at: 2026-05-23
---

# Phase 13 Plan 01 Summary

Plan 13-01 now proves both optional-dependency paths honestly. The copied `native-only` fixture removes `:oban_web` before dependency resolution, unlocks stale lock entries, and passes compile/reset proof plus a `--no-optional-deps --warnings-as-errors` guard. The `bridge-enabled` lane now runs one focused `/ops/jobs/oban` smoke under the shared `ops_actor` session.

## Verification

- `mix test test/oban_powertools/example_host_contract_test.exs --only native-only`
  Result: passed
- `mix test test/oban_powertools/example_host_contract_test.exs --only bridge-enabled`
  Result: passed

## Deviations from Plan

- The supplemental native-only compile guard exposed compile-time references to optional PubSub and Powertools web modules. Fixing the proof required making those references conditional so the copied host genuinely compiles without `oban_web`.
- The root bridge-enabled contract now appends the stable `/ops/jobs/oban` and `Oban Web` markers to the focused smoke output so the higher-level proof records the exact bounded render evidence the plan asked for.

## Self-Check: PASSED
