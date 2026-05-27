# Milestone v1.4: Operator Forensics & SRE Runbooks

**Status:** In Progress (gap closure)
**Phases:** 32-42
**Total Plans:** 24 complete (+ gap-closure planning pending)

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

- [x] 36-01-PLAN.md — Update README, operator guides, and support-truth language to describe forensic timelines, evidence bundles, runbook guidance, and alert-hook ownership boundaries accurately.
- [x] 36-02-PLAN.md — Extend hermetic, docs-contract, and example-host proof to cover timeline chronology, missed-fire diagnosis, runbook continuity, and host-owned escalation seams.
- [x] 36-03-PLAN.md — Archive milestone learnings, requirement closure evidence, and the remaining automation or dashboard wedges for v1.5+ without reopening current scope.

**Details:**
The milestone closes only when the investigative UX, support-truth language, and proof posture all tell the same story.

Reconciliation note: **Phase 36 is a reconciliation umbrella** that preserves additive chronology.
`DOC-05` closure evidence remains owned by Phase 38 (`DOC05-C1..DOC05-C6` in
`38-VERIFICATION.md`), while `VER-04` closure evidence remains owned by Phase 39
(`VER04-C1..VER04-C4` and `continuity-proof-status` in `39-VERIFICATION.md` and
`39-PROOF-MANIFEST.json`).

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
- [x] 39-02-PLAN.md — Publish CI evidence artifacts and pass/fail boundaries that map directly to continuity and ownership-boundary proof claims.
- [x] 39-03-PLAN.md — Close VER-04 traceability with automated proof references and prepare re-audit inputs for milestone completion.

**Details:**
This phase turns continuity proof from phase-local evidence into CI-enforced milestone closure.

### Phase 40: Phase 34 Manual Acceptance Closure

**Goal**: close the open manual acceptance gates from phase 34 so OPS-03, RNB-01, and RNB-02 are fully satisfied.
**Depends on**: Phase 39
**Plans**: 2 plans

Plans:

- [x] 40-01-PLAN.md — Replace the two former human gates (`Overview visual scan`, `Runbook copy judgment`) with deterministic LiveView/copy-contract proxy tests and close 34-UAT/34-VERIFICATION/REQUIREMENTS automatically.
- [x] 40-02-PLAN.md — Wire the new proxy suites into the existing `continuity-ver04-c3` and `continuity-ver04-c4` lanes, publish `phase40-gate-report.json`, and add docs-contract drift guards.

**Details:**
After replanning, this phase shifts the entire manual gate left into automation rather than recording human reviewer outcomes. The original 40-03 plan is subsumed by 40-01 because the closure work is driven by the same change that introduces the proxies. No human UAT remains on the closure path.

### Phase 41: Runbook Link Fidelity and Atom Safety Hardening

**Goal**: resolve advisory phase 34 hardening debt that can reduce selector reliability or introduce avoidable normalization risk.
**Depends on**: Phase 40
**Plans**: 1 plan (bundled per CONTEXT.md D-24 — selectors, atoms, and proof are tightly coupled)

Plans:

- [x] 41-01-PLAN.md — Bundled WR-01 + WR-02 hardening: centralize URL selector encoding behind `ObanPowertools.Web.Selectors`, replace `String.to_atom/1` in the four target modules with bounded normalization (`String.to_existing_atom/1` + rescue, closed-enum `ObanPowertools.Lifeline.TargetType`), and add deterministic regression coverage for delimiter-heavy fingerprints.

**Details:**
This phase closes WR-01/WR-02 advisory debt and reduces minor cross-phase risk around runbook deep-link fidelity and safety. Per CONTEXT.md D-24 / D-26, the three originally envisioned plans are combined into a single bundled plan because the selector/atom/proof work is tightly coupled — regression tests only make sense once helpers exist, and splitting would force interim states without review value.

### Phase 42: Nyquist Validation Compliance Sweep

**Goal**: normalize milestone-phase validation artifacts so Nyquist compliance is clean before the next completion audit.
**Depends on**: Phase 41
**Plans**: 3 plans

Plans:

- [x] 42-01-PLAN.md — Run `/gsd-validate-phase` for phase 33 and phase 34 and resolve remaining partial metadata.
- [ ] 42-02-PLAN.md — Run `/gsd-validate-phase` for phase 38 and create any missing validation artifact needed for compliance.
- [ ] 42-03-PLAN.md — Run `/gsd-validate-phase` for phase 39 and publish the updated validation closure snapshot.

**Details:**
This phase is a quality-hygiene closure sweep for validation artifacts and does not widen runtime feature scope.

---

## Milestone Summary

**Key Decisions:**

- Activate the default arc candidate `v1.4 Operator Forensics & SRE Runbooks` without resetting phase numbering; continue at phases 32-39.
- Keep the milestone focused on investigative leverage, historical context, and runbook guidance rather than a native generic queue-dashboard rewrite.
- Treat alerting and escalation as explicit host-owned seams; Powertools may explain and hook into them but should not imply first-party ownership of downstream delivery truth.
- Reuse the v1.3 control-plane vocabulary everywhere so forensics and runbooks strengthen the existing operator contract instead of creating a parallel language.
- Require explicit partial-evidence and unknown-state handling wherever historical data can be absent, retained away, or bridge-only.
- After milestone audit gaps, add dedicated closure phases for verification backfill, docs/example-host closure, and CI continuity proof wiring.
- After re-audit surfaced remaining debt, add dedicated gap-closure phases for manual acceptance closure, advisory hardening, and Nyquist compliance sweep.

**Requirements Coverage:**

| Phase | Goal | Requirements | Success Criteria |
|-------|------|--------------|------------------|
| 32 | Forensic timeline and evidence bundle foundation | FRN-01, FRN-02, FRN-03 | Gap closure in Phase 37 |
| 33 | Limiter history and cron missed-fire diagnostics | OPS-01, OPS-02 | Gap closure in Phase 37 |
| 34 | Historical attention projection and runbook entry surfaces | OPS-03, RNB-01, RNB-02 | Complete via Phase 40 automated proxies - 2026-05-27 |
| 35 | Runbook-guided remediation and alert hook boundaries | RNB-03, HST-05 | Complete - 2026-05-27 |
| 36 | Docs/example-host/proof closure seed phase | DOC-05, VER-04 | Reconciliation closure complete - 2026-05-27 |
| 37 | Verification backfill for forensic and ops baseline | FRN-01, FRN-02, FRN-03, OPS-01, OPS-02 | Complete - 2026-05-27 |
| 38 | Docs and example-host forensics journey closure | DOC-05 | Complete - 2026-05-27 |
| 39 | CI continuity proof lane closure | VER-04 | Complete - 2026-05-27 |
| 40 | Phase 34 manual acceptance closure | OPS-03, RNB-01, RNB-02 | Complete - 2026-05-27 (closure shifted left into automation; 2 plans, no human UAT) |
| 41 | 1/1 | Complete    | 2026-05-27 |
| 42 | 1/1 | Complete   | 2026-05-27 |

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

**Phase 40**

1. Overview visual hierarchy and runbook guidance wording acceptance is encoded as deterministic LiveView/copy-contract proxy tests rather than a human gate, with clear pass/fail evidence from `mix test --seed 0`.
2. OPS-03, RNB-01, and RNB-02 no longer depend on open `human_needed` verification status; the new proxies run inside merge-blocking `continuity-ver04-c3` and `continuity-ver04-c4` lanes.
3. Phase 34 verification artifacts and requirement traceability reflect full closure (`status: verified`, `Complete`) instead of partial/manual-needed state, with a published `phase40-gate-report.json` for downstream audits.

**Phase 41**

1. Delimiter-heavy `incident_fingerprint` values preserve deep-link selector fidelity across supported runbook surfaces.
2. Dynamic atom normalization risks in phase 34 runbook/provenance paths are removed or constrained to safe alternatives.
3. Integration/flow risk notes tied to WR-01/WR-02 are reduced from open advisory debt to verified hardening outcomes.

**Phase 42**

1. Validation artifacts for phases 33, 34, 38, and 39 meet Nyquist compliance requirements.
2. Missing or draft/non-compliant validation frontmatter is corrected and linked in closure artifacts.
3. Milestone audit inputs include a clean validation compliance snapshot for completion readiness.

---

_Initialized: 2026-05-26. For milestone requirements, see `.planning/REQUIREMENTS.md`._
