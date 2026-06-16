---
phase: 59-schemas-foundation
plan: 01
subsystem: workflow
tags: [schemas, database]
requires: ["BAT-01"]
provides: ["Batches and BatchJobs schemas exist", "Callback outbox schema is generalized"]
affects: ["workflow execution", "explain blocks"]
tech-stack.added: ["ObanPowertools.Batch", "ObanPowertools.BatchJob", "ObanPowertools.Callback"]
tech-stack.patterns: ["Ecto Schema", "Durable Outbox"]
key-files.created: ["lib/oban_powertools/batch.ex", "lib/oban_powertools/batch_job.ex", "lib/oban_powertools/callback.ex"]
key-files.modified: ["lib/oban_powertools/workflow/workflow.ex", "lib/oban_powertools/workflow/runtime.ex", "lib/oban_powertools/explain.ex", "test/oban_powertools/workflow_callbacks_test.exs"]
key-decisions:
  - id: "generalized-callback-outbox"
    decision: "Generalized the workflow callback outbox into a shared callback outbox pointing to batches or workflows."
    rationale: "Required for generic callbacks that act on batch exhaustion/completion."
requirements-completed: ["BAT-01"]
duration: 5 min
completed: 2026-06-14T05:35:00Z
---

# Phase 59 Plan 01: Create Batches Core Schemas Summary

Created fundamental Ecto schemas for Oban Powertools Batch (`Batch` and `BatchJob`) to support durable and exact progression tracking. Generalized the `CallbackOutbox` into a versatile `Callback` schema capable of servicing both workflows and batches. Successfully wired workflow models, the runtime engine, and diagnostic logic (`Explain`) to use the new shared callback structure.

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
