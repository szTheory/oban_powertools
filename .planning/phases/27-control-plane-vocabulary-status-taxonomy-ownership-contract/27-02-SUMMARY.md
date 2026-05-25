# Plan 27-02 Summary

## Outcome

Existing native pages now render one shared control-plane vocabulary through `lib/oban_powertools/web/control_plane_presenter.ex`.

## What Landed

- Added a shared presenter seam for status labels, ownership badges, posture copy, venue wording, and audit rendering.
- Rewired `LiveAuth` permission and read-only copy to the shared ownership language.
- Reframed the overview around shared control-plane buckets instead of count-first labels.
- Updated limiters, cron, workflows, Lifeline, audit, and the Oban Web bridge wording to use the same native-versus-bridge contract.
- Switched audit tables and history views to render `event_type` and structured resource identity.
- Updated router and LiveView proof to enforce the new labels.

## Verification

- `mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/router_test.exs`

