---
phase: 19-await-registration-signal-facts-expiry-authority
verified: 2026-05-25T08:45:00Z
status: passed
---

# Phase 19: Await Registration, Signal Facts & Expiry Authority Verification Report

**Phase Goal:** Persist durable await and signal truth so waits survive restarts, signals reconcile idempotently from Postgres-backed facts, and wait expiry finalizes through one authoritative DB-first path.

Backfill note: This artifact is being added after Phase 19 shipped. The Phase 19 summaries and validation file remain execution-history provenance; this report is the canonical present-tense closure surface for the current repo state.

## Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `SIG-01` is owned here: a workflow step can durably register one authoritative await contract with explicit signal, correlation, dedupe, and deadline fields. | ✓ VERIFIED | [test/oban_powertools/workflow_runtime_signals_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_signals_test.exs:45) proves the thin step mirror plus active await pointer, and [19-01-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/19-await-registration-signal-facts-expiry-authority/19-01-SUMMARY.md:18) records one active await per step as the shipped contract. |
| 2 | `SIG-02` is owned here: incoming signals are stored as durable facts first and reconciled idempotently whether they arrive before, during, or after wait registration. | ✓ VERIFIED | [test/oban_powertools/workflow_runtime_signals_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_signals_test.exs:8) proves pre-await durable storage and later consumption, while [test/oban_powertools/workflow_runtime_signals_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_signals_test.exs:69) and [19-02-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/19-await-registration-signal-facts-expiry-authority/19-02-SUMMARY.md:18) prove ambiguous, duplicate, and already-consumed paths remain durable evidence. |
| 3 | `SIG-03` is owned here: expiry finalizes through one DB-first reconcile authority and late signals remain evidence instead of reopening expired waits. | ✓ VERIFIED | [test/oban_powertools/workflow_runtime_signals_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_runtime_signals_test.exs:174) proves expired waits and late-signal marking, and [19-03-SUMMARY.md](/Users/jon/projects/oban_powertools/.planning/phases/19-await-registration-signal-facts-expiry-authority/19-03-SUMMARY.md:18) records reconcile-owned expiry plus late-signal evidence. |
| 4 | `VER-01` is a primary proof bundle here for await, signal, and expiry semantics, while upgrade continuity remains supporting `VER-02` evidence only. | ✓ VERIFIED | [test/oban_powertools/workflow_coordinator_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/workflow_coordinator_test.exs:93) proves row-only reconcile without advisory wakeups, and [test/oban_powertools/example_host_contract_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/example_host_contract_test.exs:38) provides the upgrade-proof lane as supporting continuity evidence rather than primary semantics ownership. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Await registration, pre-await signal storage, duplicate evidence, and expiry proof | `mix test test/oban_powertools/workflow_runtime_signals_test.exs` | passed locally during Phase 24 Wave 1 | ✓ PASS |
| Lost-wakeup and row-only reconcile proof for durable signal authority | `mix test test/oban_powertools/workflow_coordinator_test.exs` | passed locally during Phase 24 Wave 1 | ✓ PASS |
| Upgrade continuity supporting the shipped wait/signal contract | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` | passed locally during Phase 24 Wave 1 | ✓ PASS |

## Requirements Coverage

| Requirement | Ownership | Status | Evidence |
| --- | --- | --- | --- |
| `SIG-01` | Primary | ✓ SATISFIED | Phase 19 is the canonical closeout for durable await registration, one active await per step, and diagnosis-facing wait mirrors. |
| `SIG-02` | Primary | ✓ SATISFIED | Phase 19 is the canonical closeout for durable signal facts, workflow-authoritative matching, and idempotent replay handling. |
| `SIG-03` | Primary | ✓ SATISFIED | Phase 19 is the canonical closeout for expiry authority and late-arrival posture. |
| `VER-01` | Primary | ✓ SATISFIED | Focused signal and coordinator proof bundles now provide current rerunnable closure for the await/signal/expiry story. |
| `VER-02` | Supporting | ✓ SUPPORTED | The archived upgrade lane proves continuity for shipped semantics, but Phase 23 remains the canonical public-proof and support-truth closure layer. |

## Proof Topology Notes

- Historical Phase 19 summaries and `19-VALIDATION.md` remain provenance. They explain what shipped, but the present-tense closure claim now rests on the current split test modules and upgrade-proof lane.
- This backfill records the current proof seams directly: `workflow_runtime_signals_test.exs`, `workflow_coordinator_test.exs`, and `example_host_contract_test.exs --only upgrade-proof`.
- Upgrade continuity is supporting evidence only. The canonical ownership in this file stays on await registration, durable signal facts, and expiry authority rather than broad host-lane support truth.
