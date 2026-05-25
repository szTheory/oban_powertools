# Project Roadmap

## Milestones

- ✅ **v1** — Phases 0-7 shipped 2026-05-21. Full archive: `.planning/milestones/v1-ROADMAP.md`
- ✅ **v1.1** — Host Contract & Adoption Hardening. Phases 8-15 shipped 2026-05-23. Full archive: `.planning/milestones/v1.1-ROADMAP.md`
- ✅ **v1.2** — Workflow Semantics & Recovery. Phases 16-26 shipped 2026-05-25. Full archive: `.planning/milestones/v1.2-ROADMAP.md`

## Active Phases

### v1.3 Unified Control Plane & Explainability

Current roadmap phases: 27-31

### Phase 27: Control Plane Vocabulary, Status Taxonomy & Ownership Contract

**Goal**: define one durable operator language and explicit native-versus-bridge ownership before reshaping page flows.
**Depends on**: v1.2 foundation
**Plans**: 3 plans

Plans:

- [x] 27-01-PLAN.md — Freeze the shared operator vocabulary, state taxonomy, and page-ownership matrix across cron, limiters, workflows, Lifeline, audit, and Oban Web handoffs.
- [x] 27-02-PLAN.md — Extract the shared presentation and permission helpers needed to render one coherent control-plane language across the existing native surfaces.
- [x] 27-03-PLAN.md — Align baseline docs, tests, and support-truth markers to the new vocabulary before broader overview work begins.

**Details:**
Use the current LiveAuth and diagnosis seams as the base, but replace surface-local wording drift with one explicit control-plane contract.

### Phase 28: Diagnosis-First Overview & Context-Preserving Drilldowns

**Goal**: make `/ops/jobs` the real operator starting point instead of a metrics-only landing page.
**Depends on**: Phase 27
**Plans**: 3 plans

Plans:

- [x] 28-01-PLAN.md — Replace the current count-heavy overview with triage-first cards, severity buckets, and next-action guidance grounded in durable evidence.
- [x] 28-02-PLAN.md — Add context-preserving handoffs from the overview into native pages and Oban Web destinations so operators do not lose diagnosis context between surfaces.
- [x] 28-03-PLAN.md — Prove the overview and drill-down model under read-only and bridge-enabled host configurations.

**Details:**
The overview should answer “what needs attention, why, and where do I go next?” across the existing native pages and bridge.

### Phase 29: Shared Preview, Reason, Refusal & Audit Contract

**Goal**: make bounded native mutations feel like one policy surface instead of per-page conventions.
**Depends on**: Phase 28
**Plans**: 3 plans

Plans:

- [x] 29-01-PLAN.md — Normalize preview status, reason handling, refusal vocabulary, and audit consequence copy across cron and Lifeline.
- [x] 29-02-PLAN.md — Extend the same contract to workflow-directed handoffs and any other bounded native action entrypoints without widening scope into a new queue UI.
- [x] 29-03-PLAN.md — Normalize cross-surface audit metadata and resource linking so acted-on resources tell one consistent story after execution.

**Details:**
This phase should strengthen the already-good mutation posture instead of inventing new mutation families.

### Phase 30: Surface Cohesion Across Limiters, Workflows, Lifeline & Cron

**Goal**: align the native pages around one shared diagnosis and next-action mental model.
**Depends on**: Phase 29
**Plans**: 3 plans

Plans:

- [ ] 30-01-PLAN.md — Reframe limiters around shared “needs review / blocked / runnable” operator language and explicit handoffs.
- [ ] 30-02-PLAN.md — Align workflow, Lifeline, and cron copy so diagnosis, refusal, and next-action wording feel like one control plane.
- [ ] 30-03-PLAN.md — Tighten the audit destination and bridge links so cross-surface follow-up remains obvious after refresh, remount, and read-only access.

**Details:**
The target is product cohesion for operators, not a broader backend feature grab-bag.

### Phase 31: Docs, Example Host, Verification & Support-Truth Closure

**Goal**: close the milestone with docs and proof that match the narrower native-control-plane promise.
**Depends on**: Phase 30
**Plans**: 3 plans

Plans:

- [ ] 31-01-PLAN.md — Update README, guides, and support-truth language to describe the unified native control plane and explicit bridge boundaries honestly.
- [ ] 31-02-PLAN.md — Extend native LiveView, docs-contract, and example-host proof to cover cross-surface overview, handoff, and audit expectations.
- [ ] 31-03-PLAN.md — Archive milestone learnings, requirement closure evidence, and remaining follow-on wedges for v1.4+ without reopening generic dashboard scope.

**Details:**
Close the milestone only when the public story and repo-local proof agree on what operators can rely on.

## Progress

| Milestone | Phases | Plans | Status | Shipped |
|-----------|--------|-------|--------|---------|
| v1 | 0-7 | 28/28 | Shipped | 2026-05-21 |
| v1.1 | 8-15 | 27/27 | Shipped | 2026-05-23 |
| v1.2 | 16-26 | 31/31 | Shipped | 2026-05-25 |
| v1.3 | 27-31 | 9/15 | In Progress | - |
