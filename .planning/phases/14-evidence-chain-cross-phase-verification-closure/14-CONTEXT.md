# Phase 14: Evidence Chain & Cross-Phase Verification Closure - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the requirements-to-verification-to-summary evidence chain across Phases 8-10 so the
host-contract seams that already exist are audit-closeable.

This phase is about restoring trustworthy closure artifacts for already-built work:
requirement ownership, phase-local verification, summary closure metadata, and fresh proof
for the repaired chain.

This phase is not a new runtime capability phase,
not a repo-wide planning-doc schema migration,
and not a justification for silently rewriting historical artifacts into cleaner present-tense
stories.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Shift recommendations left by default for this project and within GSD. Downstream agents should treat the recommendations here as locked defaults unless a later choice would materially change public support truth, provenance, or maintainer burden.
- **D-02:** Optimize for least surprise, durable provenance, support-truth honesty, and audit-closeable evidence over aesthetic normalization or cleaner retroactive storytelling.

### Retrospective Repair Posture
- **D-03:** Use conservative, audit-targeted additive repair as the default posture for Phase 14.
- **D-04:** Only repair artifacts explicitly needed to restore `requirements -> verification -> summary` closure for Phases 8-10.
- **D-05:** Do not turn Phase 14 into a broad historical artifact normalization or schema-migration phase.
- **D-06:** Allow narrow normalization only when it is the minimum change required for the audited phase to become machine- and human-closeable.

### Verification Shape
- **D-07:** Canonical proof should live with the original requirement-owning phases, not be silently reassigned to Phase 14.
- **D-08:** Retrofit missing phase-local verification closure for Phases 8, 9, and 10:
  Phase 8 keeps its phase verification as canonical and only repairs missing summary/closure metadata;
  Phase 9 must gain a true phase-level requirements coverage artifact rather than relying on the narrow existing plan-03 verification shape;
  Phase 10 must gain a real `10-VERIFICATION.md` because validation and summaries are not sufficient closure.
- **D-09:** Phase 14 should produce a cross-phase closure/index artifact that explains what was repaired, points to the canonical phase-local proof, and confirms that requirement ownership was not reassigned.
- **D-10:** Phase 14 is an auditor’s closure memo and index, not the primary proof store for `POL-01`, `POL-02`, `POL-03`, or `HST-02`.

### Summary Truth Posture
- **D-11:** Preserve historical summaries as execution-history artifacts by default.
- **D-12:** Do not silently rewrite older summaries to make them read as if today’s proof posture existed at original plan-close time.
- **D-13:** When a historical summary needs repair, prefer explicit correction metadata and a visible historical note over narrative replacement.
- **D-14:** If an old summary contains materially misleading present-tense closure language, amend it only with an explicit correction posture that preserves the fact of later audit-based reevaluation.
- **D-15:** Summary files touched by Phase 14 should distinguish:
  what the plan concluded at completion time,
  what later audit evidence narrowed or downgraded,
  and which newer artifact now governs present-tense closure truth.

### Proof Strictness
- **D-16:** Re-run targeted proof commands and anchor repaired closure claims to fresh dated results.
- **D-17:** Documentary-only closure is not credible as the primary strategy for this phase because the milestone audit already proved that older green artifacts could coexist with broken end-to-end support truth.
- **D-18:** Use targeted proof strictness, not minimal, broad, or full-suite by default.
- **D-19:** Targeted reruns should mirror the exact commands and proof lanes that map to the repaired closure claim and any immediately adjacent host-contract seam.
- **D-20:** Grep/doc checks may supplement executable proof for wording or support-truth alignment, but must not replace executable proof where the requirement is operational.

### Scope Guardrails
- **D-21:** Do not reopen runtime design decisions from Phases 8-10 unless fresh proof reveals an actual product or contract mismatch.
- **D-22:** Do not use Phase 14 to broaden the public bridge contract, add new host capabilities, or redesign operator UX beyond what is needed to close the evidence chain honestly.
- **D-23:** Treat validation docs as setup/strategy artifacts, not substitutes for verification closure.

### the agent's Discretion
- Exact frontmatter field names and correction-block wording, provided the historical-vs-current truth distinction is explicit and consistent.
- Exact split of evidence between retrofitted phase artifacts and the new Phase 14 closure/index artifact, provided phase-local verification remains canonical.
- Exact targeted proof command set for each repaired requirement, provided it is fresh, dated, and traceable to the repaired closure claim.

</decisions>

<specifics>
## Specific Ideas

- Preferred Phase 14 outcome:
  an auditor or future maintainer should be able to start at the milestone audit,
  follow requirement ownership back to Phases 8-10,
  see repaired phase-local verification and summary closure,
  and then use one Phase 14 closure artifact as the final map that explains the repaired chain.
- Preferred support-truth posture:
  “historical summary preserved; present-tense closure claims come from the repaired verification chain.”
- Preferred GSD default to carry forward:
  for evidence-repair phases, use audit-targeted additive repair by default and escalate to broader normalization only if legacy schema drift blocks automation across multiple unaffected phases.
- Preferred proof posture:
  “closed” should mean recently exercised for the exact seam being claimed, not merely once-tested in the past.
- Repo-local product posture to preserve:
  host-owned over magical,
  explicit over implicit,
  evidence over narrative polish,
  and bridge-first/operator-trustful support truth.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone authority
- `.planning/ROADMAP.md` — Phase 14 goal, dependency on Phase 13, and ownership of evidence-chain closure work.
- `.planning/REQUIREMENTS.md` — `POL-01`, `POL-02`, `POL-03`, and `HST-02` ownership remains rooted in Phases 8-10 even though Phase 14 closes the chain.
- `.planning/STATE.md` — current milestone posture and explicit focus on Phase 14.
- `.planning/MILESTONE-ARC.md` — shift-left, host-owned, support-truth, bridge-first, and least-surprise principles that constrain this phase.
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md` — authoritative description of the evidence-chain gaps that Phase 14 exists to close.

### Prior phase decisions that constrain Phase 14
- `.planning/phases/8-host-contract-install-surface/8-VERIFICATION.md` — canonical Phase 8 verification shape and requirements coverage baseline.
- `.planning/phases/8-host-contract-install-surface/8-01-SUMMARY.md` — current Phase 8 summary metadata shape.
- `.planning/phases/8-host-contract-install-surface/8-02-SUMMARY.md` — current Phase 8 summary metadata shape and `requirements-completed` precedent.
- `.planning/phases/8-host-contract-install-surface/8-03-SUMMARY.md` — current Phase 8 summary metadata and `POL-03` closure claim.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md` — locked Phase 9 policy/auth/display/bridge decisions that Phase 14 should not reopen.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-01-SUMMARY.md` — current non-normalized summary shape for `POL-01`.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-02-SUMMARY.md` — current non-normalized summary shape for `POL-02`.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-03-SUMMARY.md` — current normalized summary and narrow bridge-proof coverage.
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-VERIFICATION.md` — current plan-scoped verification artifact that must not be mistaken for full phase closure.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — locked operator-UX and read-only/preview/audit decisions that Phase 14 should preserve.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-01-SUMMARY.md` — summary evidence for shared preview contract under `HST-02`.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-02-SUMMARY.md` — summary evidence for shared operator vocabulary under `HST-02`.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-03-SUMMARY.md` — summary evidence for bridge read-only support truth under `HST-02`.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-VALIDATION.md` — validation strategy only; useful input, not closure evidence.

### Current implementation and proof targets
- `.github/workflows/host-contract-proof.yml` — current named proof lanes that should inform targeted rerun scope.
- `test/oban_powertools/auth_test.exs` — proof surface for host auth and actor-attribution seams relevant to `POL-01`.
- `test/oban_powertools/web/router_test.exs` — proof surface for bridge/read-only route and resolver seams relevant to `POL-01`, `POL-02`, and `HST-02`.
- `test/oban_powertools/web/live/cron_live_test.exs` — proof surface for native operator permission/read-only/preview behavior.
- `test/oban_powertools/web/live/lifeline_live_test.exs` — proof surface for native operator permission/read-only/preview/audit behavior.
- `test/oban_powertools/web/live/audit_live_test.exs` — proof surface for display-policy and read-only support truth.
- `test/oban_powertools/web/live/workflows_live_test.exs` — proof surface for read-only and shared vocabulary support truth.
- `test/oban_powertools/docs_contract_test.exs` — support-truth wording guardrail where docs alignment is part of closure.

### Product posture and research context
- `prompts/oban_powertools_context.md` — product posture, operator personas, support-truth stance, and explicit domain language.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — bridge-first UI strategy, native mutation ownership, and support-truth framing.
- `prompts/oban-powertools-deep-research-original-prompt.md` — cross-ecosystem research posture, DX emphasis, and lessons-learned intent for this project family.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `8-VERIFICATION.md` already shows the desired phase-level verification shape for requirements coverage, key-link verification, and proof commands; it is the best local pattern for retrofitting Phase 9 and Phase 10 closure.
- `10-03-SUMMARY.md` already demonstrates the normalized `requirements-completed` frontmatter shape that later automation and audits can consume.
- `.github/workflows/host-contract-proof.yml` already splits host-contract proof into named lanes, which makes targeted reruns practical instead of ad hoc.
- The auth, router, and native LiveView test files already align closely to the Phase 14 reopened requirements, so fresh proof can stay narrow and executable.

### Established Patterns
- This repo treats telemetry, route ownership, auth seams, preview-first mutations, and support-truth wording as explicit public contracts.
- Phase-local verification is the canonical closure layer when it exists; milestone audits aggregate and challenge those artifacts rather than replacing them.
- Summary frontmatter is part of the evidence chain, not just decoration.
- Validation and verification are separate concepts and should remain separate in Phase 14.

### Integration Points
- Phase 8 repair should connect `8-VERIFICATION.md` to summary closure metadata so `POL-03` becomes fully traceable without rewriting the underlying proof model.
- Phase 9 repair should connect policy/auth/display/bridge evidence across `9-01`, `9-02`, and `9-03` into one phase-level verification artifact with explicit REQ-ID mapping.
- Phase 10 repair should connect the three existing plan summaries and scoped test surfaces into one missing `10-VERIFICATION.md` for `HST-02`.
- Phase 14’s own artifact should connect the milestone audit, retrofitted phase artifacts, and fresh targeted proof results into one maintainer-facing closure map.

</code_context>

<deferred>
## Deferred Ideas

- Full historical artifact normalization across older phases — defer unless schema drift blocks automation across multiple unaffected phases.
- Repo-wide summary/frontmatter modernization beyond Phases 8-10 — separate maintenance work, not Phase 14.
- Reopening runtime/product semantics from Phases 8-10 without fresh evidence of an actual contract problem.
- Converting Phase 14 into a broader docs/governance revamp phase.

</deferred>

---

*Phase: 14-evidence-chain-cross-phase-verification-closure*
*Context gathered: 2026-05-23*
