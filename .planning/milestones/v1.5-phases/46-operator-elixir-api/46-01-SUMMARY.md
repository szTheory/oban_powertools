---
phase: 46-operator-elixir-api
plan: 01
subsystem: operator
tags:
  - api
  - mutations
  - telemetry
depends_on: []
provides:
  - ObanPowertools.Operator
affects:
  - ObanPowertools.Lifeline
tech_stack_added: []
tech_stack_patterns:
  - "Telemetry metadata threading via opts"
  - "Operator API facade wrapping Lifeline previews"
key_files_created:
  - lib/oban_powertools/operator.ex
  - test/oban_powertools/operator_test.exs
key_files_modified:
  - lib/oban_powertools/lifeline.ex
  - test/oban_powertools/lifeline_test.exs
key_decisions:
  - "Operator API explicitly requires an actor map for all actions, maintaining strict authorization boundaries."
  - "Programmatic actions always route through the Lifeline preview and execute flows rather than directly mutating the job database, ensuring full auditability and host callbacks."
  - "Telemetry metadata is threaded down through opts and merged into the final telemetry event, allowing the Operator module to identify itself via `source: \"api\"`."
---

# Phase 46 Plan 01: Operator API Single-Job Actions Summary

Implement programmatic single-job API actions that route through Lifeline for secure, auditable mutations.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None.
