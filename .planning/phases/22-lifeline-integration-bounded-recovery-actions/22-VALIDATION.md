---
phase: 22
slug: lifeline-integration-bounded-recovery-actions
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-24
---

# Phase 22 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with `Phoenix.LiveViewTest` plus repo-backed `DataCase` / `LiveCase` support |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30-60 seconds quick run, ~120-240 seconds for the full suite |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** Full suite must be green, with the workflow, Lifeline, and runtime action paths exercised.
- **Max feedback latency:** 240 seconds at wave end.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | `DIA-02` / `WFS-02` | `T-22-01` / `T-22-02` | Workflow diagnosis and legal-next-action projection stay runtime-owned and reusable across workflow and Lifeline surfaces. | unit + integration | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/workflow_runtime_test.exs` | ✅ | ⬜ pending |
| 22-01-02 | 01 | 1 | `REC-03` / `VER-01` | `T-22-02` / `T-22-03` | Workflow cancel handoff preserves cooperative request-versus-outcome semantics and does not invent stronger stop behavior. | runtime + integration | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/lifeline_test.exs` | ✅ | ⬜ pending |
| 22-02-01 | 02 | 2 | `DIA-02` / `VER-01` | `T-22-03` / `T-22-04` | Lifeline can select and preview workflow-directed actions even when no active incident row exists. | integration + LiveView | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 22-02-02 | 02 | 2 | `WFS-02` / `POL-04` | `T-22-04` / `T-22-05` | Shared preview lifecycle remains `ready` / `drifted` / `expired` / `consumed`, and workflow-native preview copy does not leak repair-generic semantics. | integration + grep | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs && rg -n "ready|drifted|expired|consumed|Request cancel|repair" lib/oban_powertools/lifeline.ex lib/oban_powertools/web/lifeline_live.ex lib/oban_powertools/lifeline/repair_preview.ex` | ✅ | ⬜ pending |
| 22-03-01 | 03 | 3 | `DIA-02` / `VER-01` | `T-22-05` / `T-22-06` | Workflow detail renders a diagnosis-first handoff CTA into Lifeline without gaining inline execute controls. | LiveView | `mix test test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ | ⬜ pending |
| 22-03-02 | 03 | 3 | `VER-02` / `POL-04` | `T-22-06` / `T-22-07` | Workflow and Lifeline evidence stays explainable after execute, remount, and preview consumption, with no support-truth drift across surfaces. | integration + LiveView parity | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/workflow_runtime_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-CONTEXT.md` exists.
- [x] `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-RESEARCH.md` exists.
- [x] `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-PATTERNS.md` exists.
- [x] `lib/oban_powertools/lifeline.ex` already contains the shared preview/execute/audit seam this phase extends.
- [x] `lib/oban_powertools/workflow/runtime.ex` and `lib/oban_powertools/workflow.ex` already contain the DB-first legality seam for workflow mutations.
- [x] `lib/oban_powertools/web/workflows_live.ex` and `lib/oban_powertools/web/lifeline_live.ex` already contain the router-mounted LiveView surfaces for workflow-to-Lifeline handoff.
- [ ] `test/oban_powertools/lifeline_test.exs` needs new workflow-directed cancel and non-incident action coverage.
- [ ] `test/oban_powertools/web/live/lifeline_live_test.exs` needs param-driven workflow selection and execute-flow coverage.
- [ ] `test/oban_powertools/web/live/workflows_live_test.exs` needs legal-next-action CTA coverage without inline execute controls.
- [ ] `test/oban_powertools/workflow_runtime_test.exs` needs cross-assertions that Lifeline-issued workflow cancel writes the same command evidence shape as direct API usage.

---

## Manual-Only Verifications

- Read the workflow detail page after execution to confirm legal-next-action copy stays diagnosis-first and routes operators into Lifeline rather than adding inline execute controls.
- Read a `workflow_request_cancel` preview in Lifeline to confirm the copy says `Request cancel` and explains cooperative semantics instead of immediate stop semantics.
- Read one post-execute workflow/Lifeline pair to confirm both surfaces tell the same durable story and keep audit/provenance visible near the acted-on workflow.

---

## Validation Sign-Off

- [x] All planned task classes have an automated verification lane or an explicit manual review.
- [x] Sampling continuity: no three consecutive task classes rely on manual checks only.
- [x] Wave 0 names the existing proof seams and the missing workflow-directed coverage.
- [x] No watch-mode flags
- [x] Task-level feedback latency < 240s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
