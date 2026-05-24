---
phase: 17
plan: 01
subsystem: workflow-command-core
tags: [workflow, runtime, command-core, compatibility, migrations]
requires: [WFS-02, REC-02]
provides:
  - db-first workflow command pipeline for runtime and operator mutations
  - durable command-attempt evidence for accepted and rejected workflow mutations
  - explicit legacy semantics rejection path plus install and fixture alignment
key_files:
  created:
    - lib/oban_powertools/workflow/command_attempt.ex
    - test/support/migrations/4_phase_5_tables.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - examples/phoenix_host/priv/repo/migrations/20260522000025_oban_powertools_workflow_command_attempts.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs
    - examples/phoenix_host_upgrade_source/priv/repo/migrations/20260522000025_oban_powertools_workflow_command_attempts.exs
  modified:
    - lib/oban_powertools/workflow/runtime.ex
    - lib/oban_powertools/workflow/workflow.ex
    - lib/mix/tasks/oban_powertools.install.ex
    - test/test_helper.exs
    - test/oban_powertools/workflow_runtime_test.exs
completed_at: 2026-05-24
---

# Phase 17 Plan 01 Summary

Plan 17-01 established one DB-first workflow mutation core. `complete_step`, `await_step`, `deliver_signal`, `request_cancel`, and `recover_step` now normalize into a shared command path in `Workflow.Runtime`, and every accepted or rejected command writes durable `CommandAttempt` evidence. Legacy workflow rows with `semantics_version < 2` are explicitly rejected through that same path instead of being silently reinterpreted.

## Verification

- `mix test test/oban_powertools/workflow_runtime_test.exs`
  Result: passed

## Deviations from Plan

- Added the missing example-host semantics migration files alongside the new command-attempt migration so the supported install and upgrade fixtures stay aligned with the runtime schema surface.

## Self-Check: PASSED
