---
phase: 32
slug: forensic-timeline-evidence-bundle-foundation
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 32 - Validation Strategy

> Per-phase validation contract for forensic timeline and evidence-bundle work.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` with Phoenix.LiveViewTest |
| **Config file** | `test/test_helper.exs` and `test/support/live_case.ex` |
| **Quick run command** | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~25 seconds |

---

## Sampling Rate

- After every task commit: run the plan-specific `mix test` slice named in that task.
- After every plan wave: run all forensic and related LiveView slices with `--seed 0`.
- Before `$gsd-verify-work`: full suite must be green.
- Max feedback latency: 25 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | FRN-02 / FRN-03 | T-32-01 / T-32-02 | Shared bundle assembly preserves diagnosis-first ordering, provenance, and completeness metadata. | unit | `mix test test/oban_powertools/forensics_test.exs --seed 0` | ✅ | ⬜ pending |
| 32-01-02 | 01 | 1 | FRN-02 / FRN-03 | T-32-02 / T-32-03 | Presenter and bundle helpers label `durable`, `supporting`, `bridge-only`, and `partial evidence` consistently. | unit + grep | `mix test test/oban_powertools/forensics_test.exs --seed 0 && rg -n "partial evidence|history unavailable|unknown|supporting evidence|bridge-only" lib/oban_powertools/forensics* lib/oban_powertools/web/control_plane_presenter.ex` | ✅ | ⬜ pending |
| 32-02-01 | 02 | 2 | FRN-01 / FRN-02 | T-32-01 / T-32-04 | The native forensic destination restores bundle scope from stable selectors and keeps transient state off the URL. | live | `mix test test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs --seed 0` | ✅ | ⬜ pending |
| 32-02-02 | 02 | 2 | FRN-01 / FRN-03 | T-32-03 / T-32-04 | Workflow and Lifeline entry links remain venue-honest and distinguish forensic entry surfaces from supporting limiter/cron evidence. | live + grep | `mix test test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0 && rg -n "/ops/jobs/forensics|supporting evidence|Inspection only|Powertools-native" lib/oban_powertools/web/forensics_live.ex lib/oban_powertools/web/workflows_live.ex lib/oban_powertools/web/lifeline_live.ex` | ✅ | ⬜ pending |
| 32-03-01 | 03 | 3 | FRN-01 / FRN-02 | T-32-01 / T-32-05 | Chronology ordering and audit/resource continuity remain stable under refresh, remount, and scoped audit follow-up. | unit + live | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0` | ✅ | ⬜ pending |
| 32-03-02 | 03 | 3 | FRN-03 | T-32-02 / T-32-04 / T-32-05 | Shared control-plane vocabulary and partial-evidence wording stay coherent across workflow, Lifeline, forensic, and audit surfaces. | live + grep | `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0 && ! rg -n "preview_token=.*\\?|reason=.*\\?|diagnosis=.*\\?|refusal=.*\\?" lib/oban_powertools/web/forensics_live.ex lib/oban_powertools/web/workflows_live.ex lib/oban_powertools/web/lifeline_live.ex` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- Existing LiveView and audit infrastructure covers routing, mounted-page auth, scoped filters, and continuity patterns needed for the phase.

---

## Manual-Only Verifications

None. Phase 32 should be closed through unit and LiveView proof, not manual browser review.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all existing infrastructure dependencies.
- [x] No watch-mode flags.
- [x] Feedback latency < 30s.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
