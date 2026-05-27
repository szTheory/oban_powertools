# Phase 37: Verification Backfill for Forensic and Ops Baseline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 37-verification-backfill-forensic-ops-baseline
**Areas discussed:** Evidence freshness bar, Verification report shape, Traceability reconciliation scope, Residual-risk posture

---

## Evidence freshness bar for backfill reports

| Option | Description | Selected |
|--------|-------------|----------|
| Historical-only | Use prior summaries/validation artifacts without rerunning tests now. | |
| Targeted reruns | Rerun only phase-relevant test slices and use as fresh closure evidence. | |
| Full-suite required | Require full repo `mix test` rerun to close FRN/OPS backfill. | |
| Hybrid two-tier | Use targeted reruns for phase closure and track full-suite continuity separately. | ✓ |

**User's choice:** Hybrid two-tier (recommendation accepted).
**Notes:** Selected to maximize support-truth and auditability while keeping closure scoped to Phase 37. Historical artifacts remain provenance only.

---

## Verification report shape for 32/33 artifacts

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal ledger | Requirement checkboxes and short command list only. | |
| Rich narrative | Full must-have matrix + broad narrative similar to largest verification reports. | |
| Hybrid concise-auditable | Must-have table, requirement mapping, command evidence, and residual-risk section without report bloat. | ✓ |

**User's choice:** Hybrid concise-auditable structure (recommendation accepted).
**Notes:** Balances maintainability with closure clarity; avoids both underspecified ledger and oversized narrative.

---

## Traceability reconciliation scope

| Option | Description | Selected |
|--------|-------------|----------|
| Phase-local only | Create `32-VERIFICATION.md` and `33-VERIFICATION.md` only. | |
| Scoped reconciliation | Create missing phase verification files and update FRN/OPS traceability rows in `.planning/REQUIREMENTS.md`. | ✓ |
| Broad normalization sweep | Rewrite broader milestone/roadmap/historical docs for consistency in one pass. | |

**User's choice:** Scoped reconciliation (recommendation accepted).
**Notes:** Keeps repair additive and auditable while fully satisfying Phase 37 intent (backfill + orphan reconciliation).

---

## Residual-risk posture and closure language

| Option | Description | Selected |
|--------|-------------|----------|
| No residual-risk callout | Close phase from targeted tests without explicit broader risk language. | |
| Targeted + residual note | Close phase from targeted tests with explicit note about broader run status. | |
| Full-suite hard gate | Require full repo suite before any FRN/OPS closure claim. | |
| Two-tier confidence model | Phase closure by targeted evidence; milestone/release confidence requires broader continuity lane. | ✓ |

**User's choice:** Two-tier confidence model (recommendation accepted).
**Notes:** Enforces least-surprise confidence signaling and aligns with existing milestone split where CI continuity closure is a later dedicated phase.

---

## Claude's Discretion

- Exact targeted command grouping per requirement map in `32-VERIFICATION.md` and `33-VERIFICATION.md`.
- Exact residual-risk wording template so long as support-truth boundaries remain explicit.

## Deferred Ideas

- None beyond already-scoped future closures: DOC-05 in Phase 38 and VER-04 in Phase 39.
