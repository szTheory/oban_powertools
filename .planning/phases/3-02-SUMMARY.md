---
phase: 3
plan: 02
subsystem: builder
tags: [workflow, builder, dag, validation]
requires:
  - phase: 3
    provides: durable workflow persistence contracts
provides:
  - public workflow builder API
  - normalized insert path for builder and raw definitions
requirements-completed: [WF-01]
retrospective-proof-added-in: Phase 5
completed: 2026-05-19
---

# Phase 3 Plan 02 Summary

## Completed

- Added the public `ObanPowertools.Workflow` builder API with `new/1`, `add/4`, `add_many/3`, `connect/4`, `result/1`, and `insert/2`.
- Normalized builder-authored and raw workflow definitions through one validation and persistence path.
- Enforced duplicate-name, missing-dependency, self-loop, and cycle checks before any workflow rows are inserted.
- Added workflow fixtures plus repo-backed tests for builder insertion and graph validation.

## Verification

- `mix test test/oban_powertools/workflow_test.exs`

## Deviations

- No commits were created because the repository already contained unrelated in-progress changes.
