---
phase: 9
plan: 03
subsystem: policy-boundaries-optional-bridge-contracts
tags: [router, oban-web, docs, verification]
requires: ["9-01", "9-02"]
provides: [PKG-03, POL-01, POL-02]
affects:
  - lib/oban_powertools/web/router.ex
  - lib/oban_powertools/web/oban_web_bridge.ex
  - test/oban_powertools/web/router_test.exs
  - README.md
  - .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md
metrics:
  completed_date: 2026-05-21
  task_count: 2
  file_count: 5
---

# Phase 9 Plan 03 Summary

## Execution

- Added `ObanPowertools.Web.ObanWebBridge` as the Powertools-owned adapter over documented `Oban.Web.Resolver` hooks for actor handoff, access mapping, and shared bridge formatting.
- Updated `ObanPowertools.Web.Router` so the optional bridge remains nested at `/ops/jobs/oban`, keeps `ObanPowertools.Web.LiveAuth`, and now passes the bounded resolver adapter instead of widening the route surface.
- Replaced the old negative `resolver:` source assertion with a positive router contract test that proves the nested bridge path, shared mount hooks, and Powertools-owned resolver metadata.
- Updated README and added `9-VERIFICATION.md` so the optional `oban_web` path is documented as host-optional, nested, and limited to the shared Powertools auth and display seams.

## Verification Evidence

- `mix test test/oban_powertools/web/router_test.exs`
  - Result: passed
  - Evidence: `4 tests, 0 failures`
- `rg -n '/ops/jobs/oban|optional \`oban_web\`|documented hooks|auth_module|display_policy|shadow dashboard|plugin' README.md .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md`
  - Result: passed
  - Evidence: matched the required optional-path and seam markers
- `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
  - Result: passed
  - Evidence: `28 tests, 0 failures`

## Deviations

- No scope deviations.
- Verification note: the plan’s grep pattern includes literal backticks around `` `oban_web` ``, so the command was run with single-quoted shell wrapping to avoid zsh command substitution while preserving the same grep pattern.
