# Phase 36: Docs, Example Host, Verification & Support-Truth Closure - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the milestone with one coherent, support-truthful closure story for docs, example-host guidance, and merge-blocking verification posture.

For this repo state, Phase 36 now serves as the authoritative reconciliation boundary: it captures intent and closure mapping after the original closure work was split and completed in Phases 38 and 39.

This phase does not reopen runtime capability scope, does not relitigate v1.4 delivery semantics, and does not rewrite historical phase numbering.

</domain>

<decisions>
## Implementation Decisions

### Closure Posture and Milestone Integrity
- **D-01:** Phase 36 is locked as a **reconciliation umbrella**, not an executable implementation phase.
- **D-02:** Phase 36 closure claims are satisfied only through executed closure artifacts in Phase 38 (`DOC-05`) and Phase 39 (`VER-04`).
- **D-03:** Preserve Phase 36 numbering and intent history; no renumber/delete history rewrite is allowed.
- **D-04:** Any future runtime or CI behavior change must open a new phase rather than reusing Phase 36.
- **D-05:** Closure mapping is explicit and stable: `36-01 -> 38-*` (docs/example-host support-truth closure), `36-02 -> 39-*` (continuity-proof CI closure), `36-03 -> milestone archival/reconciliation outputs`.

### Proof and Traceability Contract
- **D-06:** Use a hybrid proof model: claim-based explicit merge-blocking proof is canonical; narrative verification prose is explanatory and non-canonical.
- **D-07:** Claim identifiers are stable contract surfaces once published (for example `DOC05-Cx`, `VER04-Cx`) and are never silently repurposed.
- **D-08:** Every merge-blocking claim maps to one deterministic command/lane and one evidence artifact entry.
- **D-09:** Aggregate gate jobs remain explicit and `always()`-run, and fail when any required claim lane fails or required evidence is missing.
- **D-10:** Keep claim scope intentionally bounded to avoid CI noise and traceability sprawl.
- **D-11:** Prefer file-scoped docs-contract assertions for critical support-truth claims over broad joined-text marker checks.
- **D-12:** Required check names and claim-lane names are treated as public contract surfaces and changed only through explicit migration.

### Recommendation-First Planning Behavior
- **D-13:** Downstream planning/research agents should default to this closure mapping without re-asking unless product semantics, support-truth boundaries, or ownership model materially change.
- **D-14:** Repo-local prompts in `prompts/` are canonical decision posture inputs for this phase and should be read before proposing alternatives.

### Claude's Discretion
- Exact reconciliation wording and formatting across closure artifacts, as long as support-truth and ownership semantics remain explicit and unchanged.
- Exact placement of claim-to-evidence references in docs and verification notes, as long as deterministic mapping remains intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and Milestone Authority
- `.planning/ROADMAP.md` — Phase 36 intent, plus split closure execution in Phases 38 and 39.
- `.planning/PROJECT.md` — recommendation-first posture, support-truth boundaries, and current milestone framing.
- `.planning/REQUIREMENTS.md` — canonical requirement traceability for `DOC-05` and `VER-04`.
- `.planning/STATE.md` — current sequencing and continuity context.

### Executed Closure Artifacts (Authoritative Proof Owners)
- `.planning/phases/38-docs-example-host-forensics-journey-closure/38-CONTEXT.md` — docs/example-host closure decisions.
- `.planning/phases/39-ci-continuity-proof-lane-closure/39-CONTEXT.md` — CI continuity claim-lane closure decisions.
- `.planning/phases/38-docs-example-host-forensics-journey-closure/38-VERIFICATION.md` — phase-level docs closure evidence.
- `.planning/phases/39-ci-continuity-proof-lane-closure/39-VERIFICATION.md` — phase-level CI continuity closure evidence.
- `.planning/phases/39-ci-continuity-proof-lane-closure/39-PROOF-MANIFEST.json` — deterministic `VER-04` claim-to-proof mapping.

### Docs and Support-Truth Contract Surfaces
- `README.md` — top-level support-truth and ownership contract.
- `guides/forensics-and-runbook-handoffs.md` — canonical operator journey and `DOC05-C*` claim language.
- `guides/support-truth-and-ownership-boundaries.md` — ownership-bucket vocabulary and escalation-boundary truth.
- `examples/phoenix_host/README.md` — canonical fixture-level forensics/runbook continuity story.

### Executable Proof Surfaces
- `test/oban_powertools/docs_contract_test.exs` — docs-contract claim assertions and over-claim guardrails.
- `.github/workflows/host-contract-proof.yml` — continuity claim lanes, aggregate gate, and proof packet enforcement.

### Product Posture and Deep Research Inputs
- `prompts/oban_powertools_context.md` — domain language, support-truth, recommendation-first architecture posture.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — UI/ops architecture strategy and least-surprise operator model.
- `prompts/oban-powertools-deep-research-original-prompt.md` — lessons-learned, tradeoff-driven, DX-first product posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/oban_powertools/docs_contract_test.exs`: already enforces `DOC05-C*` claims plus over-claim guardrails and workflow check topology.
- `.github/workflows/host-contract-proof.yml`: already provides deterministic `VER04-C1..C4` claim lanes, artifact emission, redaction scan, and aggregate gate semantics.
- `guides/forensics-and-runbook-handoffs.md`: canonical deep support-truth contract for forensics and runbook continuity.
- `README.md` and `guides/support-truth-and-ownership-boundaries.md`: stable ownership vocabulary and support-bucket language.

### Established Patterns
- Additive traceability over history rewriting.
- Claim-based executable closure for merge-blocking guarantees.
- Explicit ownership boundaries (`Powertools-native`, `Oban Web bridge`, `host-owned follow-up`) at decision points.
- Recommendation-first planning posture with repo-context-first narrowing.

### Integration Points
- Phase 36 context should act as the reconciliation index tying roadmap intent to Phase 38/39 executable closure artifacts.
- Future re-audits and milestone archival should resolve through this phase context first, then follow claim links into 38/39 artifacts.
- Any future docs/proof deltas should preserve stable claim IDs and aggregate gate semantics to avoid branch-protection drift.

</code_context>

<specifics>
## Specific Ideas

- User intent for this phase is explicit delegation: one-shot, coherent recommendation package with subagent-backed tradeoff analysis.
- Recommendations prioritize idiomatic Elixir/Phoenix/Ecto posture, least surprise, strong DX, and support-truthful operator UX.
- `prompts/` guidance is treated as first-class product strategy input, not optional background reading.

</specifics>

<deferred>
## Deferred Ideas

- Rebalancing docs architecture from hub-and-spoke toward flatter duplicated narratives (if future usability data justifies it).
- Detailed v1.5+ wedge decomposition for broader automation/API or dashboard-surface expansion beyond current closure scope.

</deferred>

---

*Phase: 36-docs-example-host-verification-support-truth-closure*
*Context gathered: 2026-05-27*
