---
phase: 17-db-first-transition-engine-command-pipeline
verified: 2026-05-25T08:45:00Z
status: passed
---

# Phase 17: DB-First Transition Engine & Command Pipeline Verification Report

**Phase Goal:** Route workflow mutations through one legal DB-first command path backed by Postgres truth, then prove runtime and operator callers re-enter that same legality engine.

Backfill note: This artifact is being added after Phase 17 shipped. The Phase 17 summaries and plan-check files remain execution-history provenance; this report is the canonical present-tense closure surface for the current repo state.

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Phase 17 owns the legal DB-first mutation core for workflow commands, with `WFS-02` as the primary requirement anchor. | ✓ VERIFIED | [test/oban_powertools/workflow_runtime_commands_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_commands_test.exs:121) proves legacy mutations are refused through the command core, and [17-01-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/17-db-first-transition-engine-command-pipeline/17-01-SUMMARY.md:18) records the shared command path plus durable command-attempt evidence. |
| 2 | Runtime and operator entrypoints both re-enter the same legality engine instead of mutating workflow truth through separate paths. | ✓ VERIFIED | [test/oban_powertools/lifeline_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/lifeline_test.exs:409) proves `workflow_request_cancel` flows through the shared cancel path, and [17-02-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/17-db-first-transition-engine-command-pipeline/17-02-SUMMARY.md:18) records workflow-step repair re-entry through the command core. |
| 3 | Later diagnosis and operator parity evidence depends on the Phase 17 command core but does not transfer primary ownership of `DIA-01` or `DIA-02` into this phase. | ✓ VERIFIED | [test/oban_powertools/web/live/workflows_live_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/live/workflows_live_test.exs:115) and [test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs:12) show the current workflow surface and native routing, while [17-03-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/17-db-first-transition-engine-command-pipeline/17-03-SUMMARY.md:20) treats those surfaces as proof that the command contract is consumable, not that Phase 17 owns all later diagnosis semantics. |
| 4 | Phase 17 provides adjacent support for `REC-03` and `VER-01` by preserving cancel-request evidence, durable rejections, duplicate-advisory safety, and compatibility posture at the command boundary. | ✓ VERIFIED | [test/oban_powertools/workflow_runtime_commands_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_commands_test.exs:9) proves cancel requests remain visible after completion, [test/oban_powertools/workflow_coordinator_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_coordinator_test.exs:35) proves duplicate PubSub delivery does not duplicate outcomes, and [test/oban_powertools/workflow_compatibility_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_compatibility_test.exs:9) proves legacy rows stay explainable on the compatibility path. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| DB-first transition, command rejection, and workflow-state proof | `mix test test/oban_powertools/workflow_runtime_transitions_test.exs test/oban_powertools/workflow_runtime_commands_test.exs test/oban_powertools/workflow_coordinator_test.exs` | passed locally during Phase 24 Wave 1 | ✓ PASS |
| Operator parity and workflow-surface proof that still re-enters the shared command core | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs` | passed locally during Phase 24 Wave 1 | ✓ PASS |
| Compatibility and upgrade-adjacent proof supporting present-tense closure without re-owning later host semantics | `mix test test/oban_powertools/workflow_compatibility_test.exs test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` | passed locally during Phase 24 Wave 1 | ✓ PASS |

## Requirements Coverage

| Requirement | Ownership | Status | Evidence |
| --- | --- | --- | --- |
| `WFS-02` | Primary | ✓ SATISFIED | Phase 17 is the canonical closure surface for legal DB-first workflow transitions, durable rejections, and caller parity through one command core. |
| `REC-03` | Supporting | ✓ SUPPORTED | Cancel-request durability and command-boundary outcome posture are proven here, but Phase 20 remains the canonical closeout for request-versus-final-outcome semantics. |
| `DIA-01` | Adjacent | ✓ SUPPORTED | Workflow-surface diagnosis consumes the Phase 17 legality core, but the canonical diagnosis closure remains Phase 21. |
| `DIA-02` | Adjacent | ✓ SUPPORTED | Lifeline and workflow inspection already re-enter the same command pipeline, but Phase 22 owns the bounded operator parity closeout. |
| `VER-01` | Supporting | ✓ SUPPORTED | Phase 17 proves command rejection, duplicate-advisory safety, and compatibility posture as part of the broader race-path proof chain later completed across Phases 19-23. |

## Proof Topology Notes

- Historical Phase 17 summaries and `17-PLAN-CHECK.md` remain provenance for what shipped and in what order; this file translates that history into the current split proof topology.
- Present-tense proof uses the focused split suites such as `workflow_runtime_transitions_test.exs`, `workflow_runtime_commands_test.exs`, `workflow_coordinator_test.exs`, `lifeline_test.exs`, `workflows_live_test.exs`, `router_test.exs`, and `workflow_compatibility_test.exs` instead of the deleted omnibus `workflow_runtime_test.exs`.
- Phase 17 intentionally does not claim canonical ownership of callback durability, await/signal authority, or late-arrival precedence. Those obligations stay with Phases 18, 19, and 20 even when this command-core proof appears in their supporting evidence chain.

