---
phase: 37
slug: verification-backfill-forensic-ops-baseline
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) + `rg` assertions |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds (targeted), ~300 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run requirement-scoped targeted command bundle for the task
- **After every plan wave:** Run combined targeted FRN/OPS bundle
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds for targeted checks

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | FRN-01, FRN-02 | — | N/A (docs-only closure) | integration | `mix test test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/forensics_live_test.exs test/oban_powertools/web/live/audit_live_test.exs --seed 0` | ✅ | ✅ green |
| 37-01-02 | 01 | 1 | FRN-03 | — | N/A (docs-only closure) | hybrid (`mix test` + `rg`) | `mix test test/oban_powertools/web/live/control_plane_copy_coherence_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0 && rg -n "/ops/jobs/forensics|supporting evidence|Inspection only|Powertools-native" lib/oban_powertools/web/forensics_live.ex lib/oban_powertools/web/workflows_live.ex lib/oban_powertools/web/lifeline_live.ex && ! rg -n "preview_token=.*\\?|reason=.*\\?|diagnosis=.*\\?|refusal=.*\\?" lib/oban_powertools/web/forensics_live.ex lib/oban_powertools/web/workflows_live.ex lib/oban_powertools/web/lifeline_live.ex` | ✅ | ✅ green |
| 37-02-01 | 02 | 1 | OPS-01, OPS-02 | — | N/A (docs-only closure) | integration | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs --seed 0` | ✅ | ✅ green |
| 37-03-01 | 03 | 2 | FRN-01, FRN-02, FRN-03, OPS-01, OPS-02 | — | N/A (traceability reconciliation) | docs verification | `rg -n "FRN-01|FRN-02|FRN-03|OPS-01|OPS-02" .planning/REQUIREMENTS.md && rg -n "FRN-01|FRN-02|FRN-03" .planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VERIFICATION.md && rg -n "OPS-01|OPS-02" .planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VERIFICATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Residual risk wording preserves two-tier confidence boundaries | FRN-01, FRN-02, FRN-03, OPS-01, OPS-02 | Semantic review of wording cannot be fully automated | Read new `32-VERIFICATION.md` and `33-VERIFICATION.md`; confirm they explicitly state targeted reruns prove phase closure only and do not claim repo-wide continuity |
| Audit-traceability chain is understandable end-to-end | FRN-01, FRN-02, FRN-03, OPS-01, OPS-02 | Human auditability/readability check | Verify each requirement row in `.planning/REQUIREMENTS.md` references the correct verification artifact and matches evidence commands/results |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (2026-05-27)
