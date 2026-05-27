# Milestone v1.4: Operator Forensics & SRE Runbooks

**Status:** Ready to build
**Phases:** 32-39
**Total Plans:** 24

## Overview

Oban Powertools v1.4 deepens the now-stable native control plane into a stronger day-2 operations surface. The milestone focuses on durable forensic timelines, limiter and cron history, evidence-bundle drilldowns, runbook-guided remediation, and support-truthful host integration seams without reopening generic queue-dashboard scope or freezing machine-facing automation contracts too early.

## Phases

### Phase 32: Forensic Timeline & Evidence Bundle Foundation

**Goal**: define the shared investigative read model and evidence vocabulary before adding new history-heavy operator pages.
**Depends on**: Phase 31 / v1.3 foundation
**Plans**: 3 plans

Plans:

- [x] 32-01-PLAN.md — Freeze the forensic vocabulary, evidence bundle shape, and cross-surface timeline semantics that build directly on the v1.3 control-plane language.
- [x] 32-02-PLAN.md — Add the projection and presentation seams needed to assemble durable investigative context from existing workflow, Lifeline, limiter, cron, and audit evidence.
- [x] 32-03-PLAN.md — Prove chronology, linked-resource continuity, and honest partial-evidence fallback behavior before wider operational history work begins.

**Details:**
This phase establishes one investigative contract so later history and runbook work reuses the same vocabulary instead of inventing page-local incident language.

### Phase 33: Limiter History & Cron Missed-Fire Diagnostics

**Goal**: make the control plane explain operational history for the two most time-oriented existing surfaces: limiters and cron.
**Depends on**: Phase 32
**Plans**: 3 plans

Plans:

- [x] 33-01-PLAN.md — Project limiter history that explains block, restore, reconfiguration, and pressure transitions without exposing an unrestricted raw-event stream.
- [x] 33-02-PLAN.md — Add cron missed-fire, delayed-fire, and overlap-relevant history views that explain why scheduled work did not run when expected.
- [x] 33-03-PLAN.md — Close proof and retention-boundary behavior for limiter and cron history so operators see explicit “unknown” or partial-evidence states when data is incomplete.

**Details:**
The milestone should answer concrete operator questions about “what happened and why” rather than simply exposing more rows.

### Phase 34: Historical Attention Projection & Runbook Entry Surfaces

**Goal**: project historically important issues back into the native overview and expose the first honest runbook entry points.
**Depends on**: Phase 33
**Plans**: 3 plans

Plans:

- [x] 34-01-PLAN.md — Extend the overview and relevant drill-down surfaces with historically informed attention projections that stay diagnosis-first instead of becoming a feed.
- [x] 34-02-PLAN.md — Introduce runbook entry surfaces that pair diagnosis states with cautions, prerequisites, and the recommended next investigative or remediation path.
- [x] 34-03-PLAN.md — Align runbook entry copy, refusal wording, and overview handoffs with the shared control-plane and forensic vocabulary.

**Details:**
This phase should make the product better at saying “here is the next safe thing to do” without pretending every step is native or automatic.

### Phase 35: Runbook-Guided Remediation & Alert Hook Boundaries

**Goal**: connect supported remediation flows to durable runbook context and explicit host-owned escalation seams.
**Depends on**: Phase 34
**Plans**: 3 plans

Plans:

- [x] 35-01-PLAN.md — Preserve runbook context through supported native remediation flows so the resulting audit and evidence views explain what was attempted and why.
- [x] 35-02-PLAN.md — Add explicit host-owned alert or escalation hook seams with truthful fallback behavior and no first-party provider lock-in.
- [x] 35-03-PLAN.md — Verify that native, bridge-only, and host-owned follow-up paths stay clearly distinguished across remediation and escalation surfaces.

**Details:**
The target is better operator guidance and clearer ownership boundaries, not a built-in paging or ticketing product.

### Phase 36: Docs, Example Host, Verification & Support-Truth Closure

**Goal**: close the milestone with proof and docs that keep the new forensic and runbook surfaces honest.
**Depends on**: Phase 35
**Plans**: 3 plans

Plans:

- [ ] 36-01-PLAN.md — Update README, operator guides, and support-truth language to describe forensic timelines, evidence bundles, runbook guidance, and alert-hook ownership boundaries accurately.
- [ ] 36-02-PLAN.md — Extend hermetic, docs-contract, and example-host proof to cover timeline chronology, missed-fire diagnosis, runbook continuity, and host-owned escalation seams.
- [ ] 36-03-PLAN.md — Archive milestone learnings, requirement closure evidence, and the remaining automation or dashboard wedges for v1.5+ without reopening current scope.

**Details:**
The milestone closes only when the investigative UX, support-truth language, and proof posture all tell the same story.

### Phase 37: Verification Backfill for Forensic and Ops Baseline

**Goal**: close orphaned requirement verification by publishing phase-level verification artifacts for completed phase-32 and phase-33 work.
**Depends on**: Phase 35
**Plans**: 3 plans

Plans:

- [x] 37-01-PLAN.md — Produce a phase-level verification report for phase 32 that links implemented forensic timeline/evidence behavior to FRN-01, FRN-02, and FRN-03.
- [x] 37-02-PLAN.md — Produce a phase-level verification report for phase 33 that links limiter/cron history behavior to OPS-01 and OPS-02.
- [x] 37-03-PLAN.md — Reconcile requirement-to-verification evidence references so audit traceability for FRN/OPS requirements is no longer orphaned.

**Details:**
This phase backfills missing verification artifacts without reopening delivered runtime scope.

### Phase 38: Docs and Example-Host Forensics Journey Closure

**Goal**: satisfy docs/support-truth closure for v1.4 forensic and runbook operator flows.
**Depends on**: Phase 37
**Plans**: 3 plans

Plans:

- [x] 38-01-PLAN.md — Update README and operator guides to cover `/ops/jobs/forensics`, evidence-boundary behavior, and runbook handoffs with explicit support-truth wording.
- [x] 38-02-PLAN.md — Extend example-host documentation and walkthroughs to reflect supported operator journeys and host-owned escalation boundaries.
- [x] 38-03-PLAN.md — Verify and document docs-contract closure evidence for DOC-05 with references to published guidance artifacts.

**Details:**
This phase closes the broken docs/example-host operator flow identified by the milestone audit.

### Phase 39: CI Continuity Proof Lane Closure

**Goal**: make continuity suites auditable in CI so VER-04 closure is merge-blocking and reproducible.
**Depends on**: Phase 38
**Plans**: 3 plans

Plans:

- [x] 39-01-PLAN.md — Wire the phase 32-35 continuity suites into `.github/workflows/host-contract-proof.yml` for milestone-proof coverage.
- [ ] 39-02-PLAN.md — Publish CI evidence artifacts and pass/fail boundaries that map directly to continuity and ownership-boundary proof claims.
- [ ] 39-03-PLAN.md — Close VER-04 traceability with automated proof references and prepare re-audit inputs for milestone completion.

**Details:**
This phase turns continuity proof from phase-local evidence into CI-enforced milestone closure.

---

## Milestone Summary

**Key Decisions:**

- Activate the default arc candidate `v1.4 Operator Forensics & SRE Runbooks` without resetting phase numbering; continue at phases 32-39.
- Keep the milestone focused on investigative leverage, historical context, and runbook guidance rather than a native generic queue-dashboard rewrite.
- Treat alerting and escalation as explicit host-owned seams; Powertools may explain and hook into them but should not imply first-party ownership of downstream delivery truth.
- Reuse the v1.3 control-plane vocabulary everywhere so forensics and runbooks strengthen the existing operator contract instead of creating a parallel language.
- Require explicit partial-evidence and unknown-state handling wherever historical data can be absent, retained away, or bridge-only.
- After milestone audit gaps, add dedicated closure phases for verification backfill, docs/example-host closure, and CI continuity proof wiring.

**Requirements Coverage:**

| Phase | Goal | Requirements | Success Criteria |
|-------|------|--------------|------------------|
| 32 | Forensic timeline and evidence bundle foundation | FRN-01, FRN-02, FRN-03 | Gap closure in Phase 37 |
| 33 | Limiter history and cron missed-fire diagnostics | OPS-01, OPS-02 | Gap closure in Phase 37 |
| 34 | Historical attention projection and runbook entry surfaces | OPS-03, RNB-01, RNB-02 | Complete - 2026-05-27 |
| 35 | Runbook-guided remediation and alert hook boundaries | RNB-03, HST-05 | Complete - 2026-05-27 |
| 36 | Docs/example-host/proof closure seed phase | DOC-05, VER-04 | Gap closure split into Phases 38-39 |
| 37 | 3/3 | Complete    | 2026-05-27 |
| 38 | 3/3 | Complete    | 2026-05-27 |
| 39 | CI continuity proof lane closure | VER-04 | Planned |

### Phase Success Criteria

**Phase 32**

1. Operators can inspect one durable investigative timeline and evidence bundle shape across at least the primary Powertools-owned resource types.
2. Timeline and evidence views preserve v1.3 control-plane vocabulary and explicit partial-evidence states.
3. Linked drill-down and audit continuity survive refresh and remount without losing diagnosis context.

**Phase 33**

1. Limiter history explains pressure, blocking, and restoration events clearly enough to distinguish transient from policy-caused issues.
2. Cron history explains missed-fire, delayed-fire, or overlap-relevant cases without inventing certainty when evidence is incomplete.
3. Retention or data-availability limits surface as explicit support-truth boundaries.

**Phase 34**

1. The overview surfaces historically important issues without collapsing into an unrestricted event feed.
2. Supported diagnosis states expose runbook entry guidance with prerequisites, cautions, and recommended next steps.
3. Operators can distinguish native, bridge-only, and host-owned follow-up paths before taking action.

**Phase 35**

1. Supported remediation flows preserve the runbook context needed to explain what was attempted and why.
2. Host-owned alert or escalation hooks can be wired without obscuring delivery ownership or fallback behavior.
3. Audit, evidence, and remediation surfaces stay aligned on follow-up ownership boundaries.

**Phase 36**

1. Public docs and example-host material describe the new forensics and runbook surfaces honestly.
2. Merge-blocking proof covers chronology, history diagnosis, runbook continuity, and escalation-seam boundaries.
3. The milestone closes with archived learnings and a clean deferred wedge for v1.5 automation work.

**Phase 37**

1. Phase 32 and phase 33 both have phase-level verification artifacts with explicit FRN/OPS requirement mappings.
2. Requirement closure evidence references are no longer orphaned in milestone audits.
3. Verification backfill is documented without reopening implementation scope from earlier phases.

**Phase 38**

1. README and operator guides explicitly document `/ops/jobs/forensics` flows, evidence boundaries, and runbook handoffs.
2. Example-host material reflects supported operator journeys and host-owned escalation ownership boundaries.
3. DOC-05 closure evidence is linked from docs-contract outputs and milestone artifacts.

**Phase 39**

1. Host contract CI executes continuity suites used for milestone verification proof.
2. CI artifacts map directly to continuity proof claims and ownership-boundary behavior.
3. VER-04 can be validated from reproducible automation evidence in the proof lane.

---

_Initialized: 2026-05-26. For milestone requirements, see `.planning/REQUIREMENTS.md`._
