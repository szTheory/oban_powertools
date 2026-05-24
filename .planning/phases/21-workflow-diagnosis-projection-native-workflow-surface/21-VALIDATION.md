---
phase: 21
slug: workflow-diagnosis-projection-native-workflow-surface
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-24
---

# Phase 21 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with `Phoenix.LiveViewTest` plus repo-backed `DataCase` / `LiveCase` support |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` |
| **Estimated runtime** | ~20-45 seconds quick run, ~90-180 seconds for the full targeted proof set |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the full suite command above.
- **Before `$gsd-verify-work`:** The targeted runtime, projector, Lifeline, and LiveView proof set must all be green.
- **Max feedback latency:** 180 seconds at wave end.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | `DIA-01` / `DIA-02` | `T-21-01` / `T-21-02` | Workflow diagnosis vocabulary and evidence projection come from one shared projector backed by durable runtime truth. | unit + integration | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/workflow_runtime_test.exs` | ✅ | ⬜ pending |
| 21-01-02 | 01 | 1 | `VER-01` / `DIA-01` | `T-21-02` / `T-21-03` | Final truth outranks lingering cancel-request evidence once terminal cause is present. | runtime + projector | `mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/explain_test.exs` | ✅ | ⬜ pending |
| 21-02-01 | 02 | 2 | `DIA-01` / `VER-01` | `T-21-03` / `T-21-04` | Primary step selection follows durable evidence priority instead of display order or first blocked step. | unit + LiveView | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ | ⬜ pending |
| 21-02-02 | 02 | 2 | `DIA-02` / `VER-02` | `T-21-04` / `T-21-05` | Unsupported and unknown workflow states render explicitly without invented copy or hidden ambiguity. | projector + LiveView | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ | ⬜ pending |
| 21-03-01 | 03 | 3 | `DIA-01` / `DIA-02` | `T-21-05` / `T-21-06` | Native workflow UI renders diagnosis-first summary, compact evidence, and guidance-only allowed next action with raw facts one level lower. | LiveView | `mix test test/oban_powertools/web/live/workflows_live_test.exs` | ✅ | ⬜ pending |
| 21-03-02 | 03 | 3 | `VER-01` / `VER-02` | `T-21-06` / `T-21-07` | Workflow page and Lifeline stay on the same diagnosis vocabulary and evidence posture for the same durable facts. | integration + LiveView parity | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` exists.
- [x] `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-RESEARCH.md` exists.
- [ ] `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-PATTERNS.md` will be created before planning if pattern mapping stays enabled.
- [x] `lib/oban_powertools/explain.ex` already contains the shared explanation seam this phase expands.
- [x] `lib/oban_powertools/workflow/runtime.ex` already contains diagnosis helpers and precedence logic that Phase 21 hardens.
- [x] `lib/oban_powertools/web/workflows_live.ex` already contains the routable LiveView surface and patch-based selected-step flow to reshape.
- [x] `test/oban_powertools/explain_test.exs`, `test/oban_powertools/workflow_runtime_test.exs`, `test/oban_powertools/lifeline_test.exs`, and `test/oban_powertools/web/live/workflows_live_test.exs` already exist as the proof seams to extend.
- [ ] `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-UI-SPEC.md` is still required by the UI gate before planning can continue.

---

## Manual-Only Verifications

- Read the final workflow screen after execution to confirm the first answer is cause plus evidence plus legal next action guidance rather than raw row details.
- Read at least one terminal-after-cancel scenario in the UI to confirm final truth is presented ahead of lingering request evidence.
- Read one unsupported or unknown scenario in the UI to confirm copy stays explicit and does not smooth over missing durable facts.

---

## Validation Sign-Off

- [x] All planned task classes have an automated verification lane or an explicit manual review.
- [x] Sampling continuity: no three consecutive task classes rely on manual checks only.
- [x] Wave 0 names the existing proof seams and the missing gating artifacts.
- [x] No watch-mode flags
- [x] Task-level feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
