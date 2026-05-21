---
phase: 9
plan: 03
verified: 2026-05-21
status: passed
---

# Phase 9 Plan 03 Verification

Plan 03 proves the optional `/ops/jobs/oban` path stays bounded to documented hooks while reusing
the same `auth_module` and `display_policy` seams as native Powertools pages. The proof target is
policy parity for the optional `oban_web` bridge, not full generic Oban Web UX replacement.

## Proof Commands

### Task 1: Router bridge contract

```bash
mix test test/oban_powertools/web/router_test.exs
```

### Task 2: Docs and support-truth proof

```bash
rg -n "/ops/jobs/oban|optional `oban_web`|documented hooks|auth_module|display_policy|shadow dashboard|plugin" README.md .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md
```

### Phase 9 contract proof set

```bash
mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs
```

## Latest Result

- `mix test test/oban_powertools/web/router_test.exs`
  - Result: passed
  - Evidence: `4 tests, 0 failures`
- `rg -n '/ops/jobs/oban|optional \`oban_web\`|documented hooks|auth_module|display_policy|shadow dashboard|plugin' README.md .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md`
  - Result: passed
  - Evidence: matched the optional path, documented hooks, `auth_module`, and `display_policy` markers without adding broader bridge promises to README prose
- `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
  - Result: passed
  - Evidence: `28 tests, 0 failures`
