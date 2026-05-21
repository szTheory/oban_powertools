---
phase: 8
plan: 01
subsystem: host-contract-install-surface
tags: [installer, supervision, runtime-config, lifeline]
requires: []
provides: [PKG-01, HST-01]
affects:
  - lib/oban_powertools/application.ex
  - lib/oban_powertools/lifeline/heartbeat_writer.ex
  - lib/mix/tasks/oban_powertools.install.ex
  - test/oban_powertools/application_test.exs
  - test/mix/tasks/oban_powertools.install_test.exs
tech_stack:
  added: []
  patterns:
    - conditional child inclusion from centralized runtime config
    - installer source contract locked by ExUnit source assertions
key_files:
  created:
    - test/oban_powertools/application_test.exs
    - .planning/phases/8-host-contract-install-surface/8-01-SUMMARY.md
  modified:
    - lib/oban_powertools/application.ex
    - lib/oban_powertools/lifeline/heartbeat_writer.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/mix/tasks/oban_powertools.install_test.exs
decisions:
  - Keep supervision ownership inside ObanPowertools.Application but gate HeartbeatWriter on configured repo presence.
  - Keep direct HeartbeatWriter startup on the shared RuntimeConfig.repo!/1 fail-fast path.
  - Keep the installer contract in the existing runtime-config comment path instead of introducing a second install flow.
metrics:
  completed_date: 2026-05-21
  task_count: 2
  file_count: 5
---

# Phase 8 Plan 01: Host Contract Install Surface Summary

Boot-time supervision is now explicit and deterministic: `ObanPowertools.Application` omits `ObanPowertools.Lifeline.HeartbeatWriter` when the host has not configured `config :oban_powertools, repo: ...`, while direct heartbeat startup still fails fast through the shared runtime-config contract.

## Tasks Completed

| Task | Name | Commits | Result |
| ---- | ---- | ------- | ------ |
| 1 | Freeze the boot-time supervision contract around `ObanPowertools.Application` and `ObanPowertools.Lifeline.HeartbeatWriter` | `dcb2bdd`, `d80e24d` | Added application coverage, gated heartbeat child inclusion on `RuntimeConfig.repo/0`, and switched heartbeat init to `RuntimeConfig.repo!/1`. |
| 2 | Freeze the installer’s host-owned supervision wiring story | `8b2c211`, `0cab09f` | Tightened installer contract assertions and added explicit host-owned config/library-owned supervision copy to the generated config comment. |

## Verification

- Task 1 RED: `mix test test/oban_powertools/application_test.exs` -> failed before implementation with unconditional heartbeat startup and wrong error shape.
- Task 1 GREEN: `mix test test/oban_powertools/application_test.exs` -> passed.
- Task 2 RED: `mix test test/mix/tasks/oban_powertools.install_test.exs` -> failed before implementation because installer copy did not mention `ObanPowertools.Application`.
- Task 2 GREEN: `rg -n "setup_migration|setup_smart_engine_migrations|setup_workflow_migrations|setup_phase_4_migrations|ObanPowertools\\.Application|ObanPowertools\\.Lifeline\\.HeartbeatWriter|config :oban_powertools|repo:|auth_module:" lib/mix/tasks/oban_powertools.install.ex` -> passed.
- Task 2 GREEN: `mix test test/mix/tasks/oban_powertools.install_test.exs` -> passed.
- Plan verification: `mix test test/oban_powertools/application_test.exs test/mix/tasks/oban_powertools.install_test.exs` -> passed (`10 tests, 0 failures`).

## Deviations from Plan

None - code changes executed as written.

## Verification Notes

- The plan’s `mix test ... -x` commands are not valid on this Mix version. Equivalent plain `mix test ...` commands were used for task-level and plan-level verification.

## Changed Files

- `lib/oban_powertools/application.ex`
- `lib/oban_powertools/lifeline/heartbeat_writer.ex`
- `lib/mix/tasks/oban_powertools.install.ex`
- `test/oban_powertools/application_test.exs`
- `test/mix/tasks/oban_powertools.install_test.exs`

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- File check: found `test/oban_powertools/application_test.exs`
- File check: found `.planning/phases/8-host-contract-install-surface/8-01-PLAN.md`
- Commit check: found `dcb2bdd`
- Commit check: found `d80e24d`
- Commit check: found `8b2c211`
- Commit check: found `0cab09f`
