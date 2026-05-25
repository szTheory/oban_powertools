# Plan 27-01 Summary

## Outcome

Phase 27 now has a pure machine-facing control-plane contract in `lib/oban_powertools/control_plane.ex` and an additive audit envelope in `lib/oban_powertools/audit.ex`.

## What Landed

- Froze the shared operator statuses: `needs_review`, `blocked`, `waiting`, `runnable`, `resolved`, and `bridge_only`.
- Froze the explicit ownership labels: `Powertools-native`, `Oban Web bridge`, and `Host-owned`.
- Added mapping helpers for limiter, cron, workflow, Lifeline, and bridge/audit contexts.
- Extended the audit schema and installer/test migrations with `command_key`, `event_type`, `resource_type`, and `resource_id`.
- Added bootstrap compatibility in `test/test_helper.exs` so local test databases are upgraded additively.
- Added proof in `test/oban_powertools/control_plane_test.exs` plus new audit assertions in cron and Lifeline tests.

## Verification

- `mix test test/oban_powertools/control_plane_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs`

