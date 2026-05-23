---
phase: 14
slug: evidence-chain-cross-phase-verification-closure
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix test plus grep-based artifact integrity checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/audit_live_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/docs_contract_test.exs` |
| **Estimated runtime** | ~25 seconds task-level smoke, ~60 seconds wave-end/full targeted proof set |

---

## Sampling Rate

- **After every task commit:** Run the task-specific automated command from the verification map. For summary-only tasks, use the artifact `rg` check immediately after the edit.
- **After every plan wave:** Run the full suite command above, because the reopened requirements share the same auth, router, native LiveView, and docs-contract surfaces.
- **Before `$gsd-verify-work`:** The combined targeted proof set and all artifact integrity checks must be green.
- **Max feedback latency:** 60 seconds at wave end, shorter for summary-only grep checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | `POL-03` / `POL-01` / `POL-02` | `T-14-01` / `T-14-02` | Phase 8 and Phase 9 summaries gain only the machine-readable closure metadata needed for the repaired requirements, while preserving execution-history sections. | docs + grep | `rg -n "requirements-completed: \\[POL-03\\]|requirements-completed: \\[POL-01\\]|requirements-completed: \\[POL-02\\]|retrospective-proof-added-in|## (Phase|Execution|Tasks Completed|Verification)" .planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-02-SUMMARY.md` | ✅ | ⬜ pending |
| 14-01-02 | 01 | 1 | `POL-03` / `POL-01` / `POL-02` | `T-14-01` / `T-14-03` | Historical summaries with later-audit narrowing expose visible retrospective notes rather than silent body rewrites. | docs + grep | `rg -n "Retrospective Traceability Note|2026-05-22|PKG-03|Phase 13|PKG-01|present-tense closure" .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-03-SUMMARY.md .planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md` | ✅ | ⬜ pending |
| 14-02-01 | 02 | 2 | `POL-01` / `POL-02` | `T-14-04` / `T-14-05` | Task-level smoke proves the auth and router seam quickly, while the longer grouped reruns for native mutation and display-policy proof remain required at wave end before closure. | integration | `mix test test/oban_powertools/auth_test.exs test/oban_powertools/web/router_test.exs` | ✅ | ⬜ pending |
| 14-02-02 | 02 | 2 | `POL-01` / `POL-02` | `T-14-04` / `T-14-06` | `9-VERIFICATION.md` becomes a phase-level REQ-ID report with fresh dated results and no reclaimed present-tense `PKG-03` closure. | docs + grep | `rg -n "POL-01|POL-02|Requirements Coverage|2026-05-23|auth_test\\.exs|cron_live_test\\.exs|lifeline_live_test\\.exs|audit_live_test\\.exs|workflows_live_test\\.exs|router_test\\.exs" .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md && ! rg -n "^plan: 03$|PKG-03.*satisfied|PKG-03.*closed" .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md` | ✅ | ⬜ pending |
| 14-03-01 | 03 | 2 | `HST-02` | `T-14-07` / `T-14-08` | Task-level smoke proves one native preview surface and one read-only support-truth surface quickly, while the full Phase 10 proof set remains required at wave end before closure. | integration | `mix test test/oban_powertools/web/live/cron_live_test.exs test/oban_powertools/web/live/audit_live_test.exs` | ✅ | ⬜ pending |
| 14-03-02 | 03 | 2 | `HST-02` | `T-14-07` / `T-14-09` | `10-VERIFICATION.md` exists as a real phase-level verification artifact that distinguishes validation input from current closure truth. | docs + grep | `rg -n "HST-02|Requirements Coverage|Behavioral Spot-Checks|2026-05-23|cron_live_test\\.exs|lifeline_live_test\\.exs|audit_live_test\\.exs|workflows_live_test\\.exs|router_test\\.exs|docs_contract_test\\.exs" .planning/phases/10-operator-ux-coherence-mutation-safety/10-VERIFICATION.md` | ✅ | ⬜ pending |
| 14-04-01 | 04 | 3 | `POL-01` / `POL-02` / `POL-03` / `HST-02` | `T-14-10` / `T-14-11` | `14-VERIFICATION.md` maps each repaired requirement back to canonical Phase 8, 9, or 10 proof and states clearly that Phase 14 is a closure memo/index. | docs + grep | `rg -n "POL-01|POL-02|POL-03|HST-02|8-VERIFICATION\\.md|9-VERIFICATION\\.md|10-VERIFICATION\\.md|closure memo|index|not the primary proof store" .planning/phases/14-evidence-chain-cross-phase-verification-closure/14-VERIFICATION.md` | ✅ | ⬜ pending |
| 14-04-02 | 04 | 3 | `POL-01` / `POL-02` / `POL-03` / `HST-02` | `T-14-10` / `T-14-12` | The governing milestone audit reflects the repaired evidence chain instead of continuing to report the four requirements as open. | docs + grep | `rg -n "POL-01|POL-02|POL-03|HST-02|Phase 8|Phase 9|Phase 10|satisfied|passed|present" .planning/milestones/v1.1-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-CONTEXT.md` exists.
- [x] `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-RESEARCH.md` exists.
- [x] `.planning/phases/14-evidence-chain-cross-phase-verification-closure/14-PATTERNS.md` exists.
- [x] The authoritative source artifacts for Phase 8, 9, and 10 summaries and verification files already exist and are readable.
- [x] The targeted proof tests for auth, router, native LiveViews, and docs contract already exist.

---

## Manual-Only Verifications

- Read the updated `9-03-SUMMARY.md` and `14-VERIFICATION.md` together after execution to confirm the retrospective note is historically honest and does not accidentally reassign proof ownership to Phase 14.
- Read the refreshed `.planning/milestones/v1.1-MILESTONE-AUDIT.md` after Plan 14-04 to confirm the audit still reflects the 2026-05-22 gap discovery while making the repaired current state explicit.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required input artifacts
- [x] No watch-mode flags
- [x] Task-level feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
