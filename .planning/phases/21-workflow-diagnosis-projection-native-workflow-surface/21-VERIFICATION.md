---
phase: 21-workflow-diagnosis-projection-native-workflow-surface
verified: 2026-05-25T09:10:00Z
status: passed
---

# Phase 21: Workflow Diagnosis Projection & Native Workflow Surface Verification Report

**Phase Goal:** Explain workflow state without database spelunking by projecting durable workflow truth into the native workflow screen.

Backfill note: This artifact is being added after Phase 21 shipped. The Phase 21 summaries and validation file remain execution-history provenance; this report is the canonical present-tense closure surface for the current repo state.

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `DIA-01` is owned here: the workflow-specific diagnosis read model and native workflow surface explain cause, evidence, and allowed next action from durable truth. | ✓ VERIFIED | [21-01-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-01-SUMMARY.md:18) records the shared diagnosis projector, and [test/oban_powertools/explain_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/explain_test.exs:69) proves workflow stories surface callback posture, recovery context, and bounded executable guidance from that projector. |
| 2 | The native workflow surface consumes projector-owned semantics instead of inventing its own workflow story in LiveView. | ✓ VERIFIED | [21-02-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-02-SUMMARY.md:18) records the shift to projector-owned workflow detail rendering, and [test/oban_powertools/web/live/workflows_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/workflows_live_test.exs:115) and [test/oban_powertools/web/live/workflows_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/workflows_live_test.exs:143) prove refusal, callback, and recovery detail rendering through the native workflow surface. |
| 3 | `DIA-02` is primary here only for the shared diagnosis vocabulary that Workflow and Lifeline both consume; execution ownership still remains outside the workflow page. | ✓ VERIFIED | [21-03-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-03-SUMMARY.md:18) records shared wording across workflow and Lifeline surfaces, and [test/oban_powertools/web/live/lifeline_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/lifeline_live_test.exs:147) proves the neighboring Lifeline surface consumes the same diagnosis posture without turning the workflow page into an execution venue. |
| 4 | Terminal-truth-first ordering from Phase 20 is supporting evidence here, not re-owned workflow-surface semantics. | ✓ VERIFIED | [20-VERIFICATION.md](/Users/jon/projects/oban_powertools/.planning/phases/20-cancellation-late-completion-expiry-semantics/20-VERIFICATION.md:17) records the canonical request-versus-outcome posture, while Phase 21 proves that the projector and LiveView surfaces faithfully render that already-owned ordering. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Diagnosis projector and shared workflow-story proof | `mix test test/oban_powertools/explain_test.exs` | passed locally during Phase 24 Wave 2 | ✓ PASS |
| Workflow-stuck evidence parity with Lifeline | `mix test test/oban_powertools/lifeline_test.exs` | passed locally during Phase 24 Wave 2 | ✓ PASS |
| Neighboring Lifeline LiveView parity for shared diagnosis vocabulary | `mix test test/oban_powertools/web/live/lifeline_live_test.exs` | passed locally during Phase 24 Wave 2 | ✓ PASS |
| Native workflow-surface proof for refusal, callback posture, recovery identity, and read-only guidance | `mix test test/oban_powertools/web/live/workflows_live_test.exs` | passed locally during Phase 24 Wave 2 | ✓ PASS |

## Requirements Coverage

| Requirement | Ownership | Status | Evidence |
| --- | --- | --- | --- |
| `DIA-01` | Primary | ✓ SATISFIED | Phase 21 is the canonical closeout for diagnosis-first workflow explanation and native workflow-surface rendering. |
| `DIA-02` | Partial Primary | ✓ SATISFIED | Phase 21 closes the shared diagnosis vocabulary and evidence posture across workflow and Lifeline surfaces, but not the bounded action execution venue itself. |
| `VER-01` | Supporting | ✓ SUPPORTED | Focused explain and LiveView proof bundles verify the workflow-surface slice of the broader race and diagnosis proof chain. |

## Proof Topology Notes

- `21-VALIDATION.md` informed command selection and sampling strategy, but it is provenance only and does not count as proof by itself.
- Present-tense proof in this backfill comes from the current split suites: `explain_test.exs`, `lifeline_test.exs`, `web/live/lifeline_live_test.exs`, and `web/live/workflows_live_test.exs`.
- When this file references terminal-truth-first cancel or expiry posture, it cites Phase 20 as supporting evidence. Phase 21 owns workflow explanation and read-model projection, not the underlying race semantics.

