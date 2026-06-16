---
phase: 59-schemas-foundation
plan: 02
subsystem: doctor
tags: [migrations, testing]
requires: ["BAT-01"]
provides: ["Installation migrations generator", "Test migrations"]
affects: ["powertools installation", "database schema"]
key-files.modified: ["lib/mix/tasks/oban_powertools.install.ex", "lib/oban_powertools/doctor/checks.ex", "test/mix/tasks/oban_powertools.install_test.exs"]
key-files.created: ["test/support/migrations/7_phase_59_tables.exs", "test/oban_powertools/batch_test.exs", "test/oban_powertools/batch_job_test.exs", "test/oban_powertools/callback_test.exs"]
key-decisions:
  - id: "rename-callback-outbox"
    decision: "Used 'rename table' instead of drop/create for migrating the callback outbox to prevent data loss."
    rationale: "Ensures operators can safely migrate existing workflow state when upgrading."
requirements-completed: ["BAT-01"]
duration: 5 min
completed: 2026-06-14T05:40:00Z
---

# Phase 59 Plan 02: Provide DB Migration Logic Summary

Created a safe migration path to generate the Batches tables and rename/generalize the Callbacks Outbox. 
Modified the `oban_powertools.install` mix task to emit a `rename table` command instead of destroying data, allowing seamless upgrades.
Updated `ObanPowertools.Doctor.Checks` to validate the correct table names and added full Unit Test scaffolding for the newly created Ecto schemas.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
