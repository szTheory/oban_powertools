---
phase: 30
slug: surface-cohesion-across-limiters-workflows-lifeline-cron
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-25
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` with Phoenix.LiveViewTest |
| **Config file** | `test/test_helper.exs` and `test/support/live_case.ex` |
| **Quick run command** | `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-specific `mix test` slice named in that task.
- **After every plan wave:** Run `mix test test/oban_powertools/web/live/*.exs --seed 0`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-01 | 01 | 1 | OVR-03 | T-30-01 / T-30-02 | Limiter and shared opening-story selectors survive patch/remount while keeping rendered diagnosis and venue prose off the URL. | live | `mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` | ✅ | ⬜ pending |
| 30-01-02 | 01 | 1 | OVR-03 / ACT-02 | T-30-02 / T-30-03 | Shared presenter copy keeps limiters read-only, venue-honest, and aligned with the control-plane opening order. | live + grep | `mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0 && rg -n "resource=|Powertools-native|Oban Web bridge|Inspection only" lib/oban_powertools/web/limiters_live.ex lib/oban_powertools/web/control_plane_presenter.ex` | ✅ | ⬜ pending |
| 30-02-01 | 02 | 2 | ACT-02 | T-30-03 / T-30-04 | Cron, workflows, and Lifeline open with one diagnosis-first policy story while preserving bounded action ownership and refusal semantics. | live | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` | ✅ | ⬜ pending |
| 30-02-02 | 02 | 2 | OVR-03 / ACT-02 | T-30-01 / T-30-03 | Shared copy and continuity behavior remain coherent after patch/remount/read-only access across the native detail surfaces. | live | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` | ✅ | ⬜ pending |
| 30-03-01 | 03 | 3 | ACT-03 | T-30-04 / T-30-05 | Audit links and filters stay resource-identity-driven, router-backed, and vocabulary-aligned with native pages. | live | `mix test test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` | ✅ | ⬜ pending |
| 30-03-02 | 03 | 3 | OVR-03 / ACT-03 | T-30-01 / T-30-05 | Cross-surface follow-up restores the same scoped slice after refresh/remount without serializing preview, refusal, or diagnosis text into params. | live + grep | `mix test test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0 && ! rg -n "preview_token=.*\\?|reason=.*\\?|diagnosis=.*\\?|refusal=.*\\?" lib/oban_powertools/web` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

None. Existing LiveView and coherence tests cover the required continuity and wording behaviors for this phase.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency < 20s.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
