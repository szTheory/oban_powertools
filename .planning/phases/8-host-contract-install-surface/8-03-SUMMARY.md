---
phase: 8-host-contract-install-surface
plan: 03
subsystem: docs
tags: [telemetry, docs, validation, host-contract]
requires:
  - phase: 8-01
    provides: explicit host-owned install and supervision contract
  - phase: 8-02
    provides: host-owned router and nested bridge contract
provides:
  - public telemetry contract closure metadata for `POL-03`
  - preserved historical execution record for the original Phase 8 public contract slice
affects:
  - lib/oban_powertools/telemetry.ex
  - test/oban_powertools/telemetry_test.exs
  - README.md
  - .planning/phases/8-host-contract-install-surface/8-VALIDATION.md
tech-stack:
  added: []
  patterns:
    - public telemetry contract exposed as stable code surface plus executable proof
    - README and validation artifacts aligned to the same install, supervision, and route contract
key-files:
  created:
    - .planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md
  modified:
    - lib/oban_powertools/telemetry.ex
    - test/oban_powertools/telemetry_test.exs
    - README.md
    - .planning/phases/8-host-contract-install-surface/8-VALIDATION.md
key-decisions:
  - Freeze the public telemetry API around five event families, the `:count` measurement, and low-cardinality metadata keys only.
  - Publish the host-owned install, route, and supervision contract in README instead of leaving adoption guidance implicit in source.
  - Treat the Phase 8 validation artifact as completed proof metadata by promoting the real test commands and approval markers.
patterns-established:
  - Phase-local verification remains the canonical proof layer for `POL-03`.
  - Retrospective summary metadata can close an evidence gap without rewriting the historical execution body.
requirements-completed: [POL-03]
retrospective-proof-added-in: Phase 14
duration: 2min
completed: 2026-05-21
---

# Phase 8 Plan 03: Public Contract Summary

Phase 8's public contract is now visible and testable outside the implementation details: the telemetry wrapper exposes a stable contract, the README describes the exact host-owned install and mount seams, and the validation artifact points at the proof set that guards them.

## Tasks Completed

| Task | Name | Commits | Result |
| ---- | ---- | ------- | ------ |
| 1 | Freeze the telemetry public API in code and tests | `bdf5e1f`, `e5f46f5` | Added a public `contract/0` surface, documented all five event families, and extended tests to lock cron and lifeline metadata boundaries. |
| 2 | Publish the Phase 8 host contract in README and validation artifacts | `061f9d9` | Replaced placeholder installation docs with the actual host contract and updated `8-VALIDATION.md` to reflect the completed proof set. |

## Verification

- Task 1 RED/GREEN: `mix test test/oban_powertools/telemetry_test.exs` -> passed after the telemetry contract and coverage landed.
- Task 2 doc proof: `rg -n "mix oban_powertools.install|config :oban_powertools|/ops/jobs|/ops/jobs/oban|ObanPowertools.Application|ObanPowertools.Lifeline.HeartbeatWriter|migrations|audit|idempotency|workflow|lifeline" README.md` -> passed.
- Task 2 validation proof: `rg -n "test/oban_powertools/application_test.exs|test/oban_powertools/web/router_test.exs|test/oban_powertools/telemetry_test.exs|test/mix/tasks/oban_powertools.install_test.exs|nyquist_compliant: true|wave_0_complete: true|Approval: approved" .planning/phases/8-host-contract-install-surface/8-VALIDATION.md` -> passed.
- Plan verification: `mix test test/oban_powertools/application_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs test/mix/tasks/oban_powertools.install_test.exs` -> passed.

## Deviations from Plan

None - the planned code, docs, and validation changes were completed as written.

## Verification Notes

- The plan's `mix test ... -x` forms are not supported by this Mix version. Equivalent plain `mix test ...` commands were used for task-level and plan-level verification.

## Changed Files

- `lib/oban_powertools/telemetry.ex`
- `test/oban_powertools/telemetry_test.exs`
- `README.md`
- `.planning/phases/8-host-contract-install-surface/8-VALIDATION.md`

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- File check: found `lib/oban_powertools/telemetry.ex`
- File check: found `README.md`
- Commit check: found `bdf5e1f`
- Commit check: found `e5f46f5`
- Commit check: found `061f9d9`
