---
phase: 10
slug: operator-ux-coherence-mutation-safety
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus Phoenix LiveViewTest |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick-run command above.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 45 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | HST-02 | T-10-01 / T-10-02 | Durable preview state exists for cron and lifeline-native mutation flows, with explicit `ready` / `drifted` / `expired` / `consumed` lifecycle semantics. | unit + integration | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs` | ✅ | ⬜ pending |
| 10-01-02 | 01 | 1 | HST-02 | T-10-03 | Native preview and execute paths reject invalid/expired/drifted/consumed states before durable mutation writes. | liveview integration | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 10-02-01 | 02 | 2 | HST-02 | T-10-04 / T-10-05 | Read-only framing, disabled reasons, preview vocabulary, and inline audit/provenance copy are consistent across native pages. | liveview integration | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ | ⬜ pending |
| 10-02-02 | 02 | 2 | HST-02 | T-10-05 | Shared display-policy rendering still keeps native audit/workflow views evidence-first while using the converged operator vocabulary. | liveview integration | `mix test test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ | ⬜ pending |
| 10-03-01 | 03 | 3 | HST-02 | T-10-06 / T-10-07 | The optional `/ops/jobs/oban` bridge stays read-only and support-truthful while reusing shared auth/display seams. | integration | `mix test test/oban_powertools/web/router_test.exs` | ✅ | ⬜ pending |
| 10-03-02 | 03 | 3 | HST-02 | T-10-07 | README and phase-local verification guidance describe the bridge as read-only and point audited mutations back to native Powertools pages. | doc + grep | `rg -n "/ops/jobs/oban|read-only|audited mutations|display_policy|auth_module|native pages" README.md .planning/phases/10-operator-ux-coherence-mutation-safety` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- No browser E2E is required for this phase.
- If execution adds a new phase-local verification doc, its exact command set should be spot-checked against the quick-run command above.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 45s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-21
