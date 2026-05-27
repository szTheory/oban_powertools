---
phase: 35
slug: runbook-guided-remediation-alert-hook-boundaries
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix LiveViewTest and Ecto SQL/Postgres test support |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/forensics_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/forensics_test.exs`
- **After every plan wave:** Run `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/forensics_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 35-01-01 | 01 | 1 | RNB-03 | T-35-01 / T-35-02 | Preview creation stores structured runbook context without URL/session leakage | integration | `mix test test/oban_powertools/lifeline_test.exs` | yes | pending |
| 35-01-02 | 01 | 1 | RNB-03 | T-35-03 | Execution audit includes runbook context explaining selected path, action, reason, plan hash, target, and result | integration | `mix test test/oban_powertools/lifeline_test.exs` | yes | pending |
| 35-01-03 | 01 | 1 | RNB-03 | T-35-03 | Forensic bundle exposes remediation attempt context after native repair | integration | `mix test test/oban_powertools/forensics_test.exs` | yes | pending |
| 35-02-01 | 02 | 2 | HST-05 | T-35-04 / T-35-05 | Missing host hook returns and records explicit host-owned unavailable fallback | unit | `mix test test/oban_powertools/host_escalation_test.exs` | yes | complete |
| 35-02-02 | 02 | 2 | HST-05 | T-35-05 | Fake configured host hook receives bounded event facts and no provider-specific delivery contract | unit | `mix test test/oban_powertools/host_escalation_test.exs` | yes | complete |
| 35-03-01 | 03 | 3 | RNB-03 / HST-05 | T-35-02 / T-35-06 | Native, bridge-only, and host-owned paths stay visually and semantically distinct | LiveView | `mix test test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/forensics_live_test.exs` | yes | pending |

---

## Wave 0 Requirements

- [x] `test/oban_powertools/host_escalation_test.exs` — covers HST-05 unconfigured, configured, and failure seam if the planner introduces a new host escalation module.
- [x] Extend `test/oban_powertools/lifeline_test.exs` — covers RNB-03 preview and execution metadata continuity.
- [x] Extend `test/oban_powertools/forensics_test.exs` — covers forensic evidence projection for remediation attempt context.
- [x] Extend `test/oban_powertools/web/live/forensics_live_test.exs` and `test/oban_powertools/web/live/lifeline_live_test.exs` — covers visible ownership distinction across native, bridge-only, and host-owned follow-up paths.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | RNB-03 / HST-05 | All phase behaviors have automated verification targets | N/A |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** completed 2026-05-27
