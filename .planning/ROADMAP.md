# Project Roadmap

## Milestones

- ✅ **v1** — Phases 0-7 shipped 2026-05-21. Full archive: `.planning/milestones/v1-ROADMAP.md`
- 🚧 **v1.1** — Host Contract & Adoption Hardening. Active milestone aligned to `.planning/MILESTONE-ARC.md`.

## Active Phases

### Phase 8: Host Contract & Install Surface

**Goal:** Make the public host-owned install/config/supervision/route contract explicit and verifiable.
**Depends on:** v1 foundation
**Plans:** 3 plans

Plans:
- [x] `8-01-PLAN.md` — Freeze the install and boot-time supervision contract around `ObanPowertools.Application` and `ObanPowertools.Lifeline.HeartbeatWriter`
- [x] `8-02-PLAN.md` — Prove the host-owned route shell and the limited optional `oban_web` bridge mount shape
- [x] `8-03-PLAN.md` — Lock the public telemetry schema and publish the Phase 8 host contract in docs/validation

### Phase 9: Policy Boundaries & Optional Bridge Contracts

**Goal:** Freeze auth, actor attribution, redaction, formatter, and optional `oban_web` seams so host apps can adopt predictable policy hooks.
**Depends on:** Phase 8
**Plans:** 3 plans

Plans:
- [x] `9-01-PLAN.md` — Freeze the host auth and audit-principal contract and enforce it through native mutation flows
- [x] `9-02-PLAN.md` — Add the shared display-policy seam and apply it across native operator surfaces
- [x] `9-03-PLAN.md` — Add the bounded `oban_web` bridge adapter plus docs and verification proof

### Phase 10: Operator UX Coherence & Mutation Safety

**Goal:** Unify permission, read-only, preview, reason, and audit behavior across the Powertools shell and bridge surfaces.
**Depends on:** Phase 9

### Phase 11: Docs, Example App, Compatibility & Contract Proof

**Goal:** Prove the public host contract through docs, example-app flows, compatibility guidance, and automated verification.
**Depends on:** Phase 10

## Progress

| Milestone | Phases | Plans | Status | Shipped |
|-----------|--------|-------|--------|---------|
| v1 | 0-7 | 28/28 | Shipped | 2026-05-21 |
| v1.1 | 8-11 | 2/4 | Active | — |
