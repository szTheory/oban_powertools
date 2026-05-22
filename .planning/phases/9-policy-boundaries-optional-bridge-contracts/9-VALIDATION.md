---
phase: 9
slug: policy-boundaries-optional-bridge-contracts
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus Phoenix LiveViewTest |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 9-01-01 | 01 | 1 | POL-01 | T-9-01 / T-9-02 | Host auth contract returns explicit authorization and audit-principal outcomes; missing principal fails before durable mutation writes. | unit | `mix test test/oban_powertools/auth_test.exs` | ✅ | ⬜ pending |
| 9-01-02 | 01 | 1 | POL-01 | T-9-03 | Native auth helpers and selected mutation flows consume the new contract without reintroducing permissive fallbacks. | liveview integration | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 9-02-01 | 02 | 2 | POL-02 | T-9-04 / T-9-05 | Audit, workflow, and operator surfaces render policy-sensitive values through shared display helpers rather than page-local formatting. | liveview + unit | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 9-02-02 | 02 | 2 | POL-01, POL-02 | T-9-02 / T-9-05 | Workflow and audit persistence continue to store raw evidence while durable writes carry explicit principal data. | unit + integration | `mix test test/oban_powertools/auth_test.exs` | ✅ | ⬜ pending |
| 9-03-01 | 03 | 3 | PKG-03, POL-01, POL-02 | T-9-06 / T-9-07 | The optional `/ops/jobs/oban` bridge uses only documented hooks and adapts the same Powertools auth/display contracts as native pages. | integration | `mix test test/oban_powertools/web/router_test.exs` | ✅ | ⬜ pending |
| 9-03-02 | 03 | 3 | PKG-03 | T-9-07 / T-9-08 | README and verification artifacts document the optional-path support truth and proof commands without overstating bridge guarantees. | doc + grep | `rg -n "/ops/jobs/oban|resolver|display_policy|auth_module|optional `oban_web`|documented hooks" README.md .planning/phases/9-policy-boundaries-optional-bridge-contracts` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- All phase behaviors should remain automatable through existing unit, integration, and LiveView tests.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-21
