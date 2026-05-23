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
**Plans:** 3

Plans:
- [x] `10-01-PLAN.md` — Generalize the durable preview contract so cron and lifeline share one native mutation-safety model
- [x] `10-02-PLAN.md` — Apply one operator vocabulary and read-only/audit posture across native Powertools pages
- [x] `10-03-PLAN.md` — Lock the optional bridge to explicit read-only support-truth and shared policy semantics

### Phase 11: Docs, Example App, Compatibility & Contract Proof

**Goal:** Prove the public host contract through docs, example-app flows, compatibility guidance, and automated verification.
**Depends on:** Phase 10
**Plans:** 4 plans

Plans:
- [x] `11-01-PLAN.md` — Publish the concise README, ExDoc guide wiring, and exact day-0 guides that make `display_policy` and first-session setup honest
- [x] `11-02-PLAN.md` — Commit the canonical generated Phoenix host fixture with real auth, display policy, router ownership, and seeded operator data
- [x] `11-03-PLAN.md` — Document one honest upgrade lane, the tested compatibility matrix, and the day-2 hardening/bridge/troubleshooting/support guides
- [x] `11-04-PLAN.md` — Add docs contract tests plus native-only, bridge-enabled, and upgrade-proof host-contract verification lanes

### Phase 12: Fresh Host Install Path & Example Fixture Repair

**Goal:** Restore the documented day-0 install path so a fresh Phoenix host and the canonical example fixture both prove the public host-owned setup contract end to end.
**Depends on:** Phase 11
**Requirements:** `PKG-01`, `DOC-01`
**Gap Closure:** Closes audit gaps from `v1.1-MILESTONE-AUDIT.md`
**Plans:** 4/4 plans complete

Plans:
- [x] `12-01-PLAN.md` — Repair the fresh-host installer so it emits repo/auth/display-policy wiring, route scope, and Powertools migrations without crashing
- [x] `12-02-PLAN.md` — Make the canonical fixture migration-complete and provenance-honest with narrow first-session seed data
- [x] `12-03-PLAN.md` — Add one deterministic native first-session proof lane that writes durable audit evidence
- [x] `12-04-PLAN.md` — Align public docs, docs contract tests, and CI lanes to the repaired install and first-session truth

### Phase 13: Native-Only Optional Dependency Contract Proof

**Goal:** Make the native-only host path compile and verify cleanly without `oban_web`, while preserving the bounded bridge contract when the dependency is present.
**Depends on:** Phase 12
**Requirements:** `PKG-03`, `DOC-03`
**Gap Closure:** Closes audit gaps from `v1.1-MILESTONE-AUDIT.md`
**Plans:** 3/3 plans complete

Plans:
- [x] `13-01-PLAN.md` — Make the temp-fixture proof harness honest for native-only dependency absence and add one real bridge render smoke
- [x] `13-02-PLAN.md` — Rewrite README and guides around a native-first support story with an optional read-only bridge annex
- [x] `13-03-PLAN.md` — Lock the native-first wording into docs-contract assertions and rename workflow jobs without collapsing `fresh-host`

### Phase 14: Evidence Chain & Cross-Phase Verification Closure

**Goal:** Repair the requirements-to-verification-to-summary evidence chain across Phases 8-10 so the host contract seams that already exist are audit-closeable.
**Depends on:** Phase 13
**Requirements:** `POL-01`, `POL-02`, `POL-03`, `HST-02`
**Gap Closure:** Closes audit gaps from `v1.1-MILESTONE-AUDIT.md`
**Plans:** 2/4 plans executed

### Phase 15: Upgrade Lane, Support Truth & Public Docs Integrity

**Goal:** Replace the synthetic upgrade proof with a real supported-host lane and align public support-truth docs with what the fixture, guides, and regression suite actually prove.
**Depends on:** Phase 14
**Requirements:** `PKG-02`, `HST-03`, `DOC-02`
**Gap Closure:** Closes audit gaps from `v1.1-MILESTONE-AUDIT.md`
**Plans:** 0 plans

## Progress

| Milestone | Phases | Plans | Status | Shipped |
|-----------|--------|-------|--------|---------|
| v1 | 0-7 | 28/28 | Shipped | 2026-05-21 |
| v1.1 | 8-15 | 4/8 | Active | — |
