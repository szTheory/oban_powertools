---
phase: 31
slug: docs-example-host-verification-support-truth-closure
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-26
---

# Phase 31 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test` with Phoenix.LiveViewTest and copied-fixture host-contract helpers |
| **Config file** | `test/test_helper.exs`, `test/support/live_case.ex`, and `test/support/example_host_contract.ex` |
| **Quick run command** | `mix test test/oban_powertools/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the plan-specific `mix test` slice named in that task.
- **After every plan wave:** Run the wave-specific proof slice plus the docs-contract lane.
- **Before `$gsd-verify-work`:** `mix test` must be green.
- **Max feedback latency:** 180 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 31-01-01 | 01 | 1 | DOC-04 / HST-04 | T-31-01 / T-31-02 | Promise-shaping docs keep one explicit native-shell vs bridge-only story and keep host-owned seams visible. | docs + grep | `mix test test/oban_powertools/docs_contract_test.exs` | ✅ | ⬜ pending |
| 31-01-02 | 01 | 1 | DOC-04 / HST-04 | T-31-01 / T-31-02 | Example-host README and public guides repeat the same support-truth buckets and route claims without implying bridge mutation parity. | docs + grep | `mix test test/oban_powertools/docs_contract_test.exs && rg -n "Powertools-native|Inspection only|/ops/jobs/oban|host-owned|overview|audit" README.md guides/support-truth-and-ownership-boundaries.md guides/optional-oban-web-bridge.md guides/example-app-walkthrough.md guides/first-operator-session.md guides/upgrade-and-compatibility.md examples/phoenix_host/README.md` | ✅ | ⬜ pending |
| 31-02-01 | 02 | 2 | VER-03 | T-31-03 / T-31-04 | Repo-local proof continues to cover overview, audit, read-only, bridge-only, and cross-surface vocabulary truth. | live | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/audit_live_test.exs test/oban_powertools/web/live/control_plane_copy_coherence_test.exs --seed 0` | ✅ | ⬜ pending |
| 31-02-02 | 02 | 2 | VER-03 / HST-04 | T-31-03 / T-31-04 | Example-host lanes prove the same bounded host story through first-session, bridge-enabled, upgrade-proof, and the new control-plane smoke lane if added. | fixture | `mix test test/oban_powertools/example_host_contract_test.exs --only first_session --only bridge-enabled --only upgrade-proof` | ✅ | ⬜ pending |
| 31-03-01 | 03 | 3 | DOC-04 / VER-03 / HST-04 | T-31-05 / T-31-06 | `31-VERIFICATION.md` points to the exact docs and proof commands that close Phase 31 without inventing a second truth source. | docs + grep | `rg -n "DOC-04|VER-03|HST-04|docs_contract_test|example_host_contract_test|engine_overview_live_test|audit_live_test|control_plane_copy_coherence_test" .planning/phases/31-docs-example-host-verification-support-truth-closure/31-VERIFICATION.md` | ❌ W0 | ⬜ pending |
| 31-03-02 | 03 | 3 | DOC-04 / VER-03 / HST-04 | T-31-05 / T-31-06 | The milestone-close memo remains additive, points at canonical proof, and records only clearly deferred v1.4+ wedges. | docs + grep | `rg -n "v1\\.3|DOC-04|VER-03|HST-04|deferred|v1\\.4" .planning/v1.3-MILESTONE-AUDIT.md .planning/phases/31-docs-example-host-verification-support-truth-closure/31-VERIFICATION.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

None. The required behaviors should stay covered by docs-contract markers, repo-local LiveView proof, copied-fixture host proof, and closeout artifact grep checks.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all MISSING references.
- [x] No watch-mode flags.
- [x] Feedback latency < 180s.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
