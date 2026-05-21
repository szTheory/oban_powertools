---
phase: 7
slug: lifeline-incident-closure-integrity
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus Phoenix LiveViewTest |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/lifeline_test.exs -x` |
| **Full suite command** | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` |
| **Estimated runtime** | ~20 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/lifeline_test.exs -x`
- **After every plan wave:** Run `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 7-01-01 | 01 | 1 | LIF-02 | T-7-01 / T-7-04 | `project_incidents/2` reconciles stale active rows and only keeps incidents active when current stranded evidence still qualifies. | integration | `mix test test/oban_powertools/lifeline_test.exs -x` | ✅ | ⬜ pending |
| 7-01-02 | 01 | 1 | LIF-02 | T-7-02 / T-7-03 | `execute_repair/5` retires incidents atomically with target mutation, preview consumption, and audit write; failed paths do not retire incidents. | integration | `mix test test/oban_powertools/lifeline_test.exs -x` | ✅ | ⬜ pending |
| 7-02-01 | 02 | 2 | LIF-02 | T-7-05 / T-7-06 | Lifeline defaults to active incidents while preserving a resolved destination for the acted-on fingerprint after execute. | liveview integration | `mix test test/oban_powertools/web/live/lifeline_live_test.exs -x` | ✅ | ⬜ pending |
| 7-02-02 | 02 | 2 | LIF-02 | T-7-05 / T-7-07 | Fresh mounts keep repaired incidents out of `Needs Review` and preserve resolved-state audit evidence. | liveview integration | `mix test test/oban_powertools/web/live/lifeline_live_test.exs -x` | ✅ | ⬜ pending |
| 7-03-01 | 03 | 3 | LIF-02 | T-7-08 | Verification artifact records the exact closure command and explicitly maps all four D-23 proof points. | artifact verification | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 7-03-02 | 03 | 3 | LIF-02 | T-7-09 / T-7-10 | `REQUIREMENTS.md` closes the `LIF-02` proof gap only after Phase 7 verification exists. | artifact verification | `rg -n "LIF-02|7-VERIFICATION.md|open_gap|closed" .planning/REQUIREMENTS.md .planning/phases/7-lifeline-incident-closure-integrity/7-VERIFICATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

- All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-20
