# Phase 37: Verification Backfill for Forensic and Ops Baseline - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Backfill missing verification closure artifacts for completed Phase 32 and Phase 33 work, then reconcile FRN/OPS requirement traceability so milestone audits no longer report those requirements as orphaned.

This phase is verification/documentation closure work. It does not reopen runtime implementation scope from phases 32-35.

</domain>

<decisions>
## Implementation Decisions

### Evidence Freshness Bar
- **D-01:** Use a hybrid freshness model: run fresh targeted phase-relevant test slices for closure claims, and treat broader full-suite confidence as a separate lane.
- **D-02:** Historical summaries and validation files are provenance inputs only; they cannot by themselves close FRN/OPS requirements.
- **D-03:** Every closure claim in `32-VERIFICATION.md` and `33-VERIFICATION.md` must include rerunnable command evidence tied to current commit state.

### Verification Report Shape
- **D-04:** Use a concise-but-auditable report structure for both `32-VERIFICATION.md` and `33-VERIFICATION.md`:
  phase goal, must-have achievement table, requirement mapping, command-based automated proof, and explicit residual-risk section.
- **D-05:** Avoid both extremes: no bare checkbox ledger and no oversized narrative inventory unless required by new scope.
- **D-06:** Keep ownership explicit by mapping primary requirement closure separately from supporting context.

### Traceability Reconciliation Scope
- **D-07:** Phase 37 scope includes both missing phase verification files and top-level FRN/OPS traceability reconciliation in `.planning/REQUIREMENTS.md`.
- **D-08:** Reconciliation must be additive and scoped: fix FRN-01/02/03 and OPS-01/02 orphaning without rewriting unrelated historical artifacts.
- **D-09:** Do not pull DOC-05 or VER-04 closure into this phase; those remain owned by phases 38 and 39.

### Residual Risk and Confidence Signaling
- **D-10:** Use two-tier confidence language: phase-level closure is based on targeted suites; milestone/release-level confidence remains gated by broader CI continuity/full-suite posture.
- **D-11:** Verification docs must explicitly state what is proven now and what remains broader continuity risk, using consistent support-truth wording.
- **D-12:** Do not claim repository-wide health from phase-targeted reruns alone.

### Claude's Discretion
- Exact command bundle composition for targeted reruns, as long as each requirement claim is directly evidenced and reproducible.
- Exact phrasing polish for residual-risk sections, as long as two-tier confidence boundaries remain explicit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` - Phase 37 goal, plan breakdown, and boundaries.
- `.planning/REQUIREMENTS.md` - FRN/OPS traceability rows and closure status source of truth.
- `.planning/PROJECT.md` - support-truth posture, recommendation-first planning posture, and milestone intent.
- `.planning/STATE.md` - current sequencing and continuity metadata.
- `.planning/v1.4-MILESTONE-AUDIT.md` - orphaned FRN/OPS findings and closure rationale for Phase 37.

### Prior closure posture that constrains this phase
- `.planning/phases/24-verification-artifact-backfill/24-CONTEXT.md` - locked backfill posture: fresh targeted proof, additive repair, explicit ownership.
- `.planning/phases/32-forensic-timeline-evidence-bundle-foundation/32-VALIDATION.md` - canonical test map and requirement-linked proof slices for FRN requirements.
- `.planning/phases/33-limiter-history-cron-missed-fire-diagnostics/33-VALIDATION.md` - canonical test map and requirement-linked proof slices for OPS requirements.
- `.planning/phases/35-runbook-guided-remediation-alert-hook-boundaries/35-VERIFICATION.md` - current report structure precedent for auditable verification closure.

### Product and architecture strategy prompts
- `prompts/oban_powertools_context.md` - domain language, support-truth posture, and research-first recommendation guidance.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` - least-surprise operator UX and ownership-boundary strategy.
- `prompts/oban-powertools-deep-research-original-prompt.md` - one-shot recommendation, DX-first, and ecosystem-lessons posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `32-VALIDATION.md` and `33-VALIDATION.md` already define focused command bundles that can be rerun for requirement-scoped closure.
- `35-VERIFICATION.md` provides a high-signal verification-report skeleton that can be adapted into concise backfill reports.
- Existing summary frontmatter in phases 32/33 already records requirement intent and can be used as provenance anchors.

### Established Patterns
- This repo treats verification artifacts as present-tense closure evidence, with historical summaries kept as provenance.
- Support-truth and ownership clarity are explicit product-level constraints; docs must not overstate certainty.
- Additive repair is preferred over historical rewrites.

### Integration Points
- Phase 37 planning should connect: (a) targeted proof reruns, (b) new 32/33 verification artifacts, and (c) FRN/OPS traceability row reconciliation.
- Outputs from this phase should reduce milestone-audit orphan detection without modifying runtime features.

</code_context>

<specifics>
## Specific Ideas

- Use subagent-backed, tradeoff-first analysis to lock decisions in one pass instead of open-ended option shopping.
- Prioritize idiomatic Elixir/Phoenix/Ecto verification behavior: executable proof, explicit boundaries, low ceremony, and auditable clarity.
- Keep developer ergonomics high by making closure artifacts easy to rerun and easy to scan.

</specifics>

<deferred>
## Deferred Ideas

- Broad docs/example-host closure (`DOC-05`) remains Phase 38 scope.
- CI continuity lane closure (`VER-04`) remains Phase 39 scope.

</deferred>

---

*Phase: 37-verification-backfill-forensic-ops-baseline*
*Context gathered: 2026-05-27*
