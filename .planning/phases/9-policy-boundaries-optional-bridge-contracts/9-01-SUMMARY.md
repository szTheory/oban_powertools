---
phase: 9-policy-boundaries-optional-bridge-contracts
plan: 01
subsystem: auth
tags: [auth, liveview, cron, lifeline, policy]
requires: []
provides:
  - explicit host auth and audit-principal contract closure for `POL-01`
  - preserved execution history for native mutation-path principal enforcement
affects: [POL-01, auth contract, cron mutations, lifeline repair flows]
tech-stack:
  added: []
  patterns:
    - host auth adapters should separate authorization from durable actor attribution
    - native mutation paths should fail before writes when no audit principal can be derived
key-files:
  created:
    - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md
  modified: []
key-decisions:
  - Keep the native LiveView boundary responsible for enforcing explicit auth outcomes and principal validation.
  - Refuse durable mutation writes when an operator is authorized but lacks a valid audit principal.
patterns-established:
  - Summary frontmatter carries the machine-readable closure hook while the body remains an execution log.
requirements-completed: [POL-01]
retrospective-proof-added-in: Phase 14
duration: unknown
completed: 2026-05-21
---

## Phase 9 Plan 01 Summary

Completed Task 1 and Task 2 within the assigned file scope.

- Evolved `ObanPowertools.Auth` to expose an explicit host auth contract with `authorize/3` and `audit_principal/1`, plus normalized `authorization_outcome/3` and strict principal validation.
- Updated the native LiveView auth adapter to consume explicit auth outcomes and added a shared principal gate for durable mutation paths.
- Refactored cron mutation handling to derive a validated principal before confirm-time writes and removed `Auth.actor_id/1` usage from `CronLive`.
- Added LiveView coverage for authorized-but-unattributable operators so cron confirm and lifeline preview/execute fail before durable writes.
- Kept Lifeline strict enforcement at the native LiveView boundary and did not widen into `lib/oban_powertools/lifeline.ex`.

## Verification

- `mix test test/oban_powertools/auth_test.exs` -> pass
- `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` -> pass
- `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` -> pass

## Notes

- No deviations from the requested plan scope.
- No blocker required widening beyond the allowed files.
