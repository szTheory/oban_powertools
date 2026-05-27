# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

---

## Milestone: v1.4 — Operator Forensics & SRE Runbooks

**Shipped:** 2026-05-27
**Phases:** 11 (32-42) | **Plans:** 28

### What Was Built

- Forensic timeline and evidence bundle foundation with shared v1.3 vocabulary, provenance model, and `/ops/jobs/forensics` investigative destination.
- Limiter history projection and cron missed-fire/delayed-fire diagnostics with explicit retention-boundary support truth.
- Diagnosis-first historical attention projection in the native overview and advisory runbook entry surfaces distinguishing native/bridge-only/host-owned follow-up.
- Runbook-guided remediation continuity persisted through preview→execute→audit, and host-owned escalation hook seams with truthful fallback statuses.
- Canonical phase-level verification backfills (Phase 37) that closed the FRN/OPS orphaned-traceability gap from the original audit.
- Docs-contract and docs/example-host closure (Phase 38) locking the forensics/runbook operator journey as verifiable claims.
- Four merge-blocking CI continuity lanes (Phase 39) turning milestone-proof from phase-local evidence into reproducible CI enforcement.
- Automated acceptance proxies (Phase 40) replacing the last human UAT gates; advisory hardening (Phase 41) centralizing selector encoding and atom normalization; Nyquist compliance sweep (Phase 42).

### What Worked

- **Iterative audit-driven gap closure:** Running the milestone audit mid-stream (after Phase 36) and building dedicated closure phases for each gap (37-42) worked cleanly. Each gap got a scoped, self-contained phase with clear success criteria rather than diffuse rework across existing phases.
- **Additive reconciliation pattern:** Treating Phase 36 as a "reconciliation umbrella" with additive chronology — rather than reopening or amending earlier phases — kept audit traceability clean and prevented circular ownership drift.
- **Automated gate replacement:** Shifting Phase 34 manual acceptance gates left into deterministic proxy tests (Phase 40) was more durable than recording human reviewer outcomes, and the proxies double as regression tests.
- **Bundled plan execution:** Phases 41 and 42 used single bundled plans that covered tightly coupled work (selectors+atoms+proof, all four VALIDATION.md sweeps) without splitting into interim states with no review value.

### What Was Inefficient

- **Phase 36 scope confusion:** Phase 36 was originally planned as the docs/proof closure phase but was overtaken by the audit gap findings. The reconciliation pivot was correct but required additional reconciliation work to document the canonical ownership boundaries for DOC-05 and VER-04.
- **Audit found 7 gaps after Phase 36:** The original audit showed `status: gaps_found` across requirements, phases, integration, and flows. This drove phases 37-42. Better upfront proof harness design (wiring continuity CI lanes earlier, writing verification artifacts closer to implementation) would have avoided the gap-closure tail.
- **ROADMAP.md Phase 42 checkbox inconsistency:** Phase 42 was planned with 3 plans but completed with 1 bundled plan. The ROADMAP.md unchecked plans for 42-02 and 42-03 diverged from actual completion state. Bundling decisions should update ROADMAP.md checkboxes immediately.

### Patterns Established

- **Milestone-audit-driven gap phases:** When an audit finds gaps, add scoped closure phases rather than amending existing ones. Name them after the gap they close (e.g., `37-verification-backfill`, `38-docs-closure`, `39-ci-proof-closure`).
- **Reconciliation umbrella pattern:** A phase that reconciles additive closure (pointing to canonical owners) is legitimate and should be documented as such — not reopened or stripped — in the ROADMAP.md notes.
- **Automated acceptance proxy pattern:** Replace human gates with deterministic LiveView/copy-contract proxies wired into existing CI lanes. Reduces closure ambiguity and doubles as regression protection.
- **Bundled plan pattern:** When sub-plans for a phase are tightly coupled, bundle into one plan and document the rationale in ROADMAP.md. Update checkboxes to reflect the bundled shape, not the original plan breakdown.

### Key Lessons

1. **Wire CI lanes early.** VER-04 required a dedicated closure phase because continuity suites existed only as local evidence. Wiring them to named CI check IDs during Phase 35 (when the seams were implemented) would have closed VER-04 without a follow-up phase.
2. **Publish phase verification artifacts before closing the phase.** FRN-01/02/03 and OPS-01/02 required Phase 37 backfill because Phase 32/33 had no VERIFICATION.md at close. The fix: treat VERIFICATION.md as a phase exit criterion, not an optional artifact.
3. **Docs-contract tests are cheapest at implementation time.** DOC-05 required a dedicated Phase 38 because docs-contract coverage was thin at Phase 36. Adding docs-contract markers during Phase 32-35 implementation would have closed DOC-05 in-band.
4. **Proof bundled with code is sticky; deferred proof accumulates as tech debt.** Phases that shipped code without verification or docs-contract coverage systematically became audit gaps. The gap-closure tail (Phases 37-42) is the cost of that deferral.

### Cost Observations

- Model mix: primarily Sonnet for execution phases, Opus-class reasoning for discuss/plan/audit phases.
- Notable: gap-closure phases (37-42) added ~40% more phase count than the core milestone arc (32-36). Upfront proof discipline would reduce this ratio.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1        | 8      | 28    | Initial GSD process — establish patterns |
| v1.1      | 8      | 27    | Host contract hardening; more structured audit posture |
| v1.2      | 11     | 31    | Verification backfill pattern introduced |
| v1.3      | 5      | 15    | Tighter scoping; control-plane convergence |
| v1.4      | 11     | 28    | Audit-driven gap-closure phases; CI proof enforcement; automated acceptance proxies |

### Top Lessons (Verified Across Milestones)

1. **Proof artifacts at phase close prevent gap-closure tails.** Every milestone that skipped phase-level verification produced a backfill obligation in a later phase.
2. **Bounded scope + explicit support-truth beats broad capability claims.** Narrowing each milestone to one coherent operator story produces more useful audit and docs outcomes than broad feature sprawl.
3. **Reconciliation phases are legitimate work.** Additive reconciliation (adjusting ownership, traceability, and canonical references) has appeared in v1.2 (Phase 24/25), v1.3, and v1.4. It should be planned for, not treated as scope failure.
