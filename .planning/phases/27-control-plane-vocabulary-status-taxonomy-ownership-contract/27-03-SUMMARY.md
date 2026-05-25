# Plan 27-03 Summary

## Outcome

The public docs, support-truth guides, and merge-blocking proof now use the same Phase 27 vocabulary as the code.

## What Landed

- Updated `README.md` to describe the unified `/ops/jobs` control plane, `Powertools-native` surfaces, and the bounded `Oban Web bridge`.
- Updated the bridge and support-truth guides to mark the bridge as `Inspection only` and native flows as `Audited action`.
- Refreshed limits, workflows, and Lifeline guides to use diagnosis-first, venue-aware language.
- Extended `test/oban_powertools/docs_contract_test.exs` with exact vocabulary markers.

## Verification

- `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs`

