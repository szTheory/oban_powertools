# Phase 38 Research: Docs and Example-Host Forensics Journey Closure

**Date:** 2026-05-27  
**Phase:** 38  
**Goal:** satisfy docs/support-truth closure for v1.4 forensic and runbook operator flows.  
**Boundary:** docs, example-host guidance, and docs-contract closure evidence only (no runtime scope reopen).

---

## What You Need To Know To Plan This Phase Well

1. This is a closure phase for `DOC-05`, not a feature phase: runtime behavior for forensics/runbook continuity already exists and is covered by prior phases.
2. Current public docs do not yet present a canonical `/ops/jobs/forensics` journey, evidence-boundary behavior, or runbook handoff contract in one coherent operator flow.
3. The locked phase context already chose the docs architecture: one canonical guide plus lightweight cross-links from high-traffic entry docs.
4. The wording contract is already locked: keep the ownership triad (`Powertools-native`, `Oban Web bridge`, `host-owned follow-up`) and evidence-boundary labels (`partial evidence`, `history unavailable`, `unknown`) explicit at decision points.
5. Example-host docs must describe supported operator journeys and host-owned escalation boundaries, but must not imply first-party delivery truth for external escalation.
6. `38-03` must produce auditable closure evidence for `DOC-05`: file-scoped docs-contract assertions plus a phase-level verification artifact that links claims to published docs.
7. Phase sequencing is strict: docs closure in Phase 38 is a dependency for Phase 39 CI proof closure (`VER-04`).

---

## Canonical Inputs And Dependencies

Use these as planning authority:

- `.planning/phases/38-docs-example-host-forensics-journey-closure/38-CONTEXT.md`
- `.planning/REQUIREMENTS.md` (`DOC-05` pending; support-truth and proof posture gates)
- `.planning/ROADMAP.md` (38 plan breakdown and must-haves)
- `.planning/STATE.md` (phase readiness and sequencing)
- `.planning/v1.4-MILESTONE-AUDIT.md` (broken flow `BF-01` root cause)

Carry forward locked boundaries from:

- `.planning/phases/31-docs-example-host-verification-support-truth-closure/31-CONTEXT.md`
- `.planning/phases/34-historical-attention-projection-runbook-entry-surfaces/34-CONTEXT.md`
- `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-CONTEXT.md`
- `.planning/phases/37-verification-backfill-forensic-ops-baseline/37-CONTEXT.md`

---

## Architecture And Context Dependencies For Docs Planning

### 1) Operator Journey Spine Is Already Defined

The docs should represent one canonical path:

`/ops/jobs` -> `/ops/jobs/forensics` -> legal next path (ownership explicit) -> `/ops/jobs/audit`

This matches locked decisions in `38-CONTEXT.md` and route reality in `lib/oban_powertools/web/router.ex`.

### 2) Forensics Surface Behavior Is Evidence-Grounded, Not Certainty-Theater

Forensics and runbook surfaces explicitly render:

- evidence completeness states (`partial evidence`, `history unavailable`, `unknown`)
- advisory runbook posture
- ownership-labeled follow-up paths
- continuity and audit follow-up links

Docs must mirror this exactly and avoid language that implies guaranteed chronology or universal observability.

### 3) Ownership Truth Is Triad-Based At Decision Time

Use the same ownership vocabulary consistently across docs:

- `Powertools-native` -> audited native action path
- `Oban Web bridge` -> inspection only
- `host-owned follow-up` -> outside Powertools delivery/runbook truth

This is already centralized in presenter and runbook seams (`ControlPlanePresenter`, `RunbookEntry`), so docs should align to those labels.

### 4) Host Escalation Status Claims Must Stay Narrow

Current implementation supports explicit host follow-up statuses (unconfigured/invoked/failed).  
Docs must not imply provider delivery ownership (page sent, ticket created, downstream runbook completed).

### 5) Selector And URL Truth Matters For Narrative Accuracy

The forensic route supports durable selectors (`resource_type`, `resource_id`, `workflow_id`, `step`, `incident_fingerprint`, `view`).  
Docs should describe continuity and drill-down behavior without implying prose/refusal/reason text in URL continuity state.

---

## Current Gap Topology (Why 38 Exists)

From current docs/test surfaces:

- `README.md` and guides include strong v1.3 support-truth framing, but no canonical v1.4 forensics/runbook journey guide.
- `guides/first-operator-session.md` stops at first native mutation and optional bridge boundary; it does not yet include explicit forensic continuity and audit confirmation steps.
- `guides/example-app-walkthrough.md` and `examples/phoenix_host/README.md` describe fixture provenance and first-session contract but do not yet walk operators through `/ops/jobs/forensics` handoffs and host-owned escalation boundaries.
- `test/oban_powertools/docs_contract_test.exs` currently enforces global marker presence across joined docs; it does not yet enforce file-scoped `DOC-05` closure claims tied to forensics/runbook docs.
- There is no current `guides/forensics-and-runbook-handoffs.md` canonical doc yet, even though it is the locked architecture decision for this phase.

---

## Required Docs Touchpoints (Plan Inputs)

Minimum touchpoint set for Phase 38 planning:

1. `README.md`
   - Add/support explicit pointer to canonical forensics/runbook guide.
   - Keep support-truth buckets and ownership wording aligned with v1.4 forensics language.

2. `guides/forensics-and-runbook-handoffs.md` (new canonical guide)
   - Source-of-truth narrative for the operator journey spine.
   - Explicit evidence-boundary labels and ownership/venue decision points.
   - Explicit runbook continuity and audit-follow-up handoff framing.

3. `guides/first-operator-session.md`
   - Extend first successful mutation walkthrough with post-mutation forensic continuity and audit confirmation steps.

4. `guides/example-app-walkthrough.md`
   - Show supported fixture-backed operator journey including forensics and runbook handoff boundaries.

5. `guides/support-truth-and-ownership-boundaries.md`
   - Ensure support buckets explicitly include v1.4 forensics/runbook scope and host-owned escalation truth.

6. `examples/phoenix_host/README.md`
   - Reflect supported operator journey and explicit host-owned escalation caveats in fixture language.

7. `test/oban_powertools/docs_contract_test.exs`
   - Add/extend claim checks for DOC-05 closure markers, including file-scoped assertions for high-risk claims.

---

## Acceptance Evidence Expectations (For 38-03)

Phase 38 should be planned with a hybrid evidence model (locked in context):

1. **Executable docs-contract proof**
   - Extend docs-contract tests for DOC-05 forensics/runbook closure claims.
   - Prefer file-scoped assertions over joined-doc-only checks for critical claims.
   - Recommended claim IDs pattern: `DOC05-C1...` mapped to concrete docs assertions.

2. **Published docs artifacts**
   - Canonical guide present and linked from README + key spokes.
   - Updated example-host and operator walkthrough docs published in-repo.

3. **Phase-level closure artifact**
   - Create `38-VERIFICATION.md` with:
     - roadmap must-have mapping
     - DOC-05 claim-to-evidence table
     - commands/results
     - residual-risk statement (no VER-04 overclaim)

4. **Traceability alignment**
   - Update `.planning/REQUIREMENTS.md` DOC-05 status only after evidence is present.
   - Keep `VER-04` pending for Phase 39.

Recommended command bundle for planning:

- `mix test test/oban_powertools/docs_contract_test.exs --seed 0`
- targeted host-story proof lane (at minimum):
  - `mix test test/oban_powertools/example_host_contract_test.exs --only control-plane --only first_session`
- doc marker/link sanity checks (optional but high-signal):
  - `rg -n "/ops/jobs/forensics|partial evidence|history unavailable|unknown|Powertools-native|Oban Web bridge|host-owned follow-up" README.md guides/*.md examples/phoenix_host/README.md`

---

## Risks And Anti-Patterns To Plan Around

1. **Over-claiming certainty**
   - Risk: docs imply complete chronology or guaranteed diagnosis when implementation exposes degraded evidence states.
   - Mitigation: require explicit evidence-boundary language in canonical and spoke docs.

2. **Ownership blur in escalation seams**
   - Risk: docs imply Powertools owns downstream delivery/runbook truth.
   - Mitigation: keep host-owned status language explicit; prohibit provider-delivery claims.

3. **Guide drift from canonical source**
   - Risk: duplicated prose across README/guides/example-host diverges over time.
   - Mitigation: enforce hub-and-spoke pattern with one canonical deep guide and concise spokes.

4. **Weak docs-contract closure**
   - Risk: global marker checks pass while high-risk claims regress in specific files.
   - Mitigation: file-scoped DOC-05 assertions with claim IDs.

5. **Scope drift into runtime or CI lane work**
   - Risk: Phase 38 tries to close runtime or `VER-04` CI continuity concerns.
   - Mitigation: keep runtime unchanged; reserve CI merge-blocking continuity wiring for Phase 39.

---

## Recommended Plan Decomposition (38-01 / 38-02 / 38-03)

### 38-01: README + Operator Guides Forensics/Runbook Closure

**Objective:** establish the canonical docs architecture and publish the truthful operator journey.

Plan recommendations:

- Create `guides/forensics-and-runbook-handoffs.md` as canonical source.
- Update `README.md`, `guides/first-operator-session.md`, and `guides/support-truth-and-ownership-boundaries.md` with concise cross-links and support-truth snapshots.
- Lock wording at decision points:
  - evidence boundaries
  - ownership triad
  - advisory vs merge-blocking proof boundary language

**Done when:** operator can follow one coherent forensics/runbook path from README to forensic and audit destinations without ownership ambiguity.

### 38-02: Example-Host Journey And Escalation Boundary Closure

**Objective:** align fixture-facing docs with supported operator journey and host-owned seams.

Plan recommendations:

- Update `guides/example-app-walkthrough.md` and `examples/phoenix_host/README.md`.
- Add explicit post-mutation continuity narrative: `ops-demo` -> `pause_cron_entry nightly_sync` -> forensic confirmation -> audit confirmation.
- Keep fixture prose tied to real route-level behavior and narrow supported scope.

**Done when:** example-host docs describe supported journey and clearly separate Powertools-native, bridge-only, and host-owned escalation boundaries.

### 38-03: DOC-05 Docs-Contract Evidence Closure

**Objective:** make docs closure auditable with executable proof and requirement traceability.

Plan recommendations:

- Extend `test/oban_powertools/docs_contract_test.exs` with DOC-05 claim checks, including file-scoped assertions for high-risk claims.
- Produce `38-VERIFICATION.md` with claim-to-evidence mapping and command output references.
- Reconcile `DOC-05` traceability in `.planning/REQUIREMENTS.md` only after proof artifacts exist.

**Done when:** DOC-05 has explicit, rerunnable evidence chain from docs artifacts to test assertions to phase verification and requirement traceability.

---

## Ordering And Dependency Recommendations

Recommended execution order:

1. `38-01` first (creates canonical guide + core wording anchors)
2. `38-02` second (aligns example-host docs to canonical narrative)
3. `38-03` last (locks docs-contract and traceability based on finalized docs text)

Dependency notes:

- `38-02` should consume canonical wording from `38-01`.
- `38-03` depends on both prior docs updates to avoid brittle test churn.
- Phase 39 depends on Phase 38 closure evidence being auditable and discoverable.

---

## Planner Checklist

- [ ] Plan explicitly states Phase 38 is docs/support-truth closure only (no runtime scope reopen).
- [ ] Canonical guide + spoke-link architecture is part of plan tasks.
- [ ] Ownership triad and evidence-boundary vocabulary are treated as locked terms.
- [ ] Example-host docs include explicit forensics and audit follow-up journey.
- [ ] Docs-contract plan includes file-scoped DOC-05 assertions and claim IDs.
- [ ] `38-VERIFICATION.md` is planned as closure evidence artifact.
- [ ] `.planning/REQUIREMENTS.md` update is gated on executable DOC-05 proof.
- [ ] `VER-04` remains deferred to Phase 39.

---

*Research intent: planning readiness for Phase 38; not phase execution.*
