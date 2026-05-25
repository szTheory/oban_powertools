---
phase: 29
slug: shared-preview-reason-refusal-audit-contract
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-25
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` |
| **Config file** | `.formatter.exs` and default Mix test config |
| **Quick run command** | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/audit_live_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-specific `mix test` slice named in that task.
- **After every plan wave:** Run `mix test`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 29-01-01 | 01 | 1 | ACT-01 | T-29-01 / T-29-02 | Shared preview states and reason-policy metadata stay server-authoritative and surface-consistent. | unit + integration | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs` | ✅ | ⬜ pending |
| 29-01-02 | 01 | 1 | ACT-01 | T-29-03 | Cron and Lifeline render one refusal/audit-consequence contract without leaking preview internals into URL state. | live | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 29-02-01 | 02 | 2 | ACT-02 | T-29-04 | Workflow-directed actions present human-first refusal and venue-aware next moves while Lifeline remains the execution venue. | live | `mix test test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 29-02-02 | 02 | 2 | ACT-02 | T-29-05 | Shared reason/refusal helpers cover every bounded native entrypoint touched by Phase 29 without widening mutation scope. | grep + focused test | `rg -n "preview_drifted|preview_expired|reason_required|request_cancel|recover_step|execute_repair" lib/oban_powertools/web lib/oban_powertools && mix test test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/cron_live_test.exs` | ✅ | ⬜ pending |
| 29-03-01 | 03 | 3 | ACT-03 | T-29-06 | Audit filters and follow-up links are URL-backed, query-backed, and resource-identity-driven. | live + integration | `mix test test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/cron_test.exs test/oban_powertools/lifeline_test.exs` | ✅ | ⬜ pending |
| 29-03-02 | 03 | 3 | ACT-03 | T-29-07 | Local continuity panels and global audit rows tell the same event/resource story and prefer native destinations when owned. | live + grep | `mix test test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs && ! rg -n "preview_token=.*\\?|reason=.*\\?" lib/oban_powertools/web` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cross-surface copy coherence for refusal and audit follow-up | ACT-01 / ACT-02 / ACT-03 | Final wording quality is partly editorial even when semantics are tested. | Read cron, Lifeline, workflow, and audit screens side by side and confirm the sequence `outcome -> concise reason -> legal next move -> venue` stays intact. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 20s.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
