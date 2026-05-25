---
phase: 24
slug: verification-artifact-backfill
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 24 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix plus grep-based verification-report shape checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/explain_test.exs` |
| **Full suite command** | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` |
| **Estimated runtime** | ~20-45 seconds quick run, ~180-300 seconds for the full targeted bundle with upgrade proof |

---

## Sampling Rate

- **After every task commit:** Run the task-specific command from the verification map below.
- **After every plan wave:** Run the relevant wave-end bundle plus the doc-shape grep for the files created in that wave.
- **Before `$gsd-verify-work`:** All six new `VERIFICATION.md` files, the cited current-state proof bundles, and the cross-file section-shape grep must be green.
- **Max feedback latency:** 300 seconds at wave end because `upgrade-proof` remains the slowest targeted check.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-01 | 01 | 1 | `WFS-02` / `SIG-01` / `SIG-02` / `SIG-03` / `VER-01` | `T-24-01` / `T-24-02` | `17-VERIFICATION.md` and `19-VERIFICATION.md` use fresh current-state proof, preserve command-core and signal ownership, and distinguish primary versus supporting evidence. | integration + docs grep | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "## Observable Truths|## Behavioral Spot-Checks|## Requirements Coverage|## Proof Topology Notes" .planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md` | ✅ | ⬜ pending |
| 24-01-02 | 01 | 1 | `REC-03` / `SIG-03` / `DIA-01` / `VER-01` | `T-24-02` / `T-24-03` | `20-VERIFICATION.md` proves cancel-versus-outcome, late-evidence, and diagnosis-ordering posture from the current split proof suites without re-owning Phase 19 expiry authority. | integration + docs grep | `mix test test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/explain_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "## Observable Truths|## Behavioral Spot-Checks|## Requirements Coverage|## Proof Topology Notes" .planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md` | ✅ | ⬜ pending |
| 24-02-01 | 02 | 2 | `DIA-01` / `DIA-02` / `VER-01` | `T-24-03` / `T-24-04` | `21-VERIFICATION.md` uses fresh explain and workflow-surface proof and does not treat `21-VALIDATION.md` as proof by itself. | integration + LiveView + docs grep | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs && rg -n "## Observable Truths|## Behavioral Spot-Checks|## Requirements Coverage|## Proof Topology Notes" .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md` | ✅ | ⬜ pending |
| 24-02-02 | 02 | 2 | `DIA-02` / `WFS-02` / `REC-03` / `VER-01` | `T-24-04` / `T-24-05` | `22-VERIFICATION.md` aggregates the bounded operator-action story into one phase-level artifact while preserving workflow-page read-only posture and Lifeline execute ownership. | integration + LiveView + docs grep | `mix test test/oban_powertools/explain_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/workflow_runtime_commands_test.exs && rg -n "## Observable Truths|## Behavioral Spot-Checks|## Requirements Coverage|## Proof Topology Notes" .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md` | ✅ | ⬜ pending |
| 24-03-01 | 03 | 3 | `VER-01` | `T-24-05` / `T-24-06` | `23-VERIFICATION.md` records the current proof topology for focused runtime suites, repo-local compatibility, singular supported upgrade proof, telemetry, and docs contract without flattening the support posture. | integration + docs contract + docs grep | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_signals_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_callbacks_test.exs test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/telemetry_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof && rg -n "## Observable Truths|## Behavioral Spot-Checks|## Requirements Coverage|## Proof Topology Notes" .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md` | ✅ | ⬜ pending |
| 24-03-02 | 03 | 3 | `WFS-02` / `REC-03` / `SIG-01` / `SIG-02` / `SIG-03` / `DIA-01` / `DIA-02` / `VER-01` | `T-24-06` / `T-24-07` | All six new verification files share one compact section shape, include a retrospective backfill note, and keep primary versus supporting ownership explicit so Phase 25 can repair traceability without guessing. | docs audit | `rg -n "Backfill note|## Observable Truths|## Behavioral Spot-Checks|## Requirements Coverage|## Proof Topology Notes|Primary|Supporting" .planning/phases/17-db-first-transition-engine-command-pipeline/17-VERIFICATION.md .planning/phases/19-await-registration-signal-facts-expiry-authority/19-VERIFICATION.md .planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md .planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-VERIFICATION.md .planning/phases/22-lifeline-integration-bounded-recovery-actions/22-VERIFICATION.md .planning/phases/23-verification-upgrade-proof-telemetry-support-truth-closure/23-VERIFICATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md` exists.
- [x] Source summaries exist for Phases 17, 19, 20, 21, 22, and 23.
- [x] Validation artifacts exist for Phases 19, 20, 21, 22, and 23.
- [x] Current proof seams exist in the split workflow runtime suites, explain/LiveView suites, Lifeline suites, telemetry tests, docs-contract tests, and host upgrade-proof lane.
- [x] Existing canonical verification report analogs exist in `16-VERIFICATION.md`, `18-VERIFICATION.md`, and `15-VERIFICATION.md`.

---

## Manual-Only Verifications

- Read each new backfill note to confirm the file states clearly that summaries and validation docs remain historical provenance rather than present-tense closure.
- Read each requirements section to confirm supporting evidence does not silently become canonical ownership.
- Read `23-VERIFICATION.md` to confirm supported host upgrade proof and repo-local compatibility proof remain explicitly separate.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required input artifacts
- [x] No watch-mode flags
- [x] Task-level feedback latency < 300s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

