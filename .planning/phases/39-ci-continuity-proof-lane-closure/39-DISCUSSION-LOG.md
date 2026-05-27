# Phase 39: ci-continuity-proof-lane-closure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `39-CONTEXT.md` — this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 39-ci-continuity-proof-lane-closure
**Areas discussed:** continuity lane topology, claim-to-command mapping, failure and artifact boundaries, traceability closure shape

---

## Continuity lane topology

| Option | Description | Selected |
|--------|-------------|----------|
| A. Monolithic lane | One continuity command and one gate. Lowest complexity, weakest failure localization. | |
| B. Single job with split steps | One lane with internal claim steps. Better logs than monolith, still coarse reruns. | |
| C. Static matrix by claim area | 3-4 claim shards with explicit boundaries and final aggregator gate. Best observability and auditability. | ✓ |
| D. Reusable workflow composition | `workflow_call` indirection and shared CI abstraction. Strong at org scale, heavier local complexity. | |

**User's choice:** Discussed all options and locked a one-shot recommendation for Option C.  
**Notes:** Keep stable check names and a final merge-blocking continuity status gate.

---

## Claim-to-command mapping strategy

| Option | Description | Selected |
|--------|-------------|----------|
| A. One umbrella command | Broad continuity command proving all claims together. | |
| B. Explicit claim slices (`VER04-C1..C4`) | Deterministic claim-to-command mapping per continuity claim area. | ✓ |
| C. Smoke + deep split | Fast smoke in PR, deep continuity out-of-band/nightly. | |
| D. Rotating risk subsets | Dynamic subset execution based on risk weighting. | |

**User's choice:** Discussed all options and locked a one-shot recommendation for Option B.  
**Notes:** Use deterministic commands (`--seed 0`) with direct claim mapping to keep closure auditable.

---

## Failure and artifact boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| A. Fail-fast minimal artifacts | Lowest CI cost, weakest post-failure diagnostics. | |
| B. Always upload full artifacts | Maximum diagnostics, higher cost/noise and redaction burden. | |
| C. Layered summary + selective raw logs | Claim summary and JSON always, failing claim logs sanitized and uploaded. | ✓ |
| D. JUnit-first normalization | Rich report UX, but incomplete alone for non-test/setup failures. | |

**User's choice:** Discussed all options and locked a one-shot recommendation for Option C.  
**Notes:** Required proof packet must publish on `always()`, with strict artifact presence and redaction checks.

---

## Traceability closure shape

| Option | Description | Selected |
|--------|-------------|----------|
| A. Verification doc only | Human-readable closure report with manual mappings. | |
| B. Verification + requirements update | Additive repo pattern with improved ledger closure. | |
| C. Manifest + verification + requirements | Deterministic machine mapping plus human report plus ledger reconciliation. | ✓ |
| D. Topology contract tests only | Strong drift prevention, incomplete as sole closure evidence. | |

**User's choice:** Discussed all options and locked a one-shot recommendation for Option C (plus topology contract guards).  
**Notes:** Publish deterministic proof manifest, phase verification report, and reconcile `VER-04` traceability after proof publication.

---

## Claude's Discretion

- Exact shard names, artifact file names, and workflow step ordering can be refined during plan/execution.
- Final implementation should preserve locked claim boundaries, deterministic proof commands, and merge-blocking continuity semantics.

## Deferred Ideas

- Reusable cross-repo continuity workflows via `workflow_call`.
- Nightly-only deep continuity lanes.
- CI reporting expansion beyond phase-39 closure scope.
