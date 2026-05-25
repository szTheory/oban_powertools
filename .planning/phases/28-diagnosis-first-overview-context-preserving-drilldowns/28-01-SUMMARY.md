# Plan 28-01 Summary

## Outcome

`/ops/jobs` now renders a diagnosis-first overview backed by one bounded read-model seam instead of a metric wall.

## What Landed

- Added `lib/oban_powertools/web/overview_read_model.ex` to own bucket counts, diagnosis text, exemplars, venue labels, and next-step paths for `Needs Review`, `Blocked`, `Waiting`, `Runnable`, `Resolved Recently`, and `Bridge-only Follow-up`.
- Rebuilt `lib/oban_powertools/web/engine_overview_live.ex` around triage cards with bounded exemplar evidence and venue-aware CTAs.
- Extended `lib/oban_powertools/web/control_plane_presenter.ex` with continuity posture wording for the quieter resolved block.
- Added `test/oban_powertools/web/live/engine_overview_live_test.exs` to prove diagnosis-first rendering plus bridge/native ownership labels.

## Verification

- `mix test test/oban_powertools/web/live/engine_overview_live_test.exs`
