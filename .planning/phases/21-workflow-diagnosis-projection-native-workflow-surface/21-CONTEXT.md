# Phase 21: Workflow Diagnosis Projection & Native Workflow Surface - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Explain workflow state without database spelunking by projecting durable workflow truth into the native workflow screen.

This phase owns the workflow-specific diagnosis read model and the native LiveView presentation that renders cause, evidence, and allowed next action from durable workflow, step, await, signal, callback, rejection, and recovery facts.

This phase does not add a broad interactive workflow mutation surface, does not bypass the DB-first command core, does not widen the optional `oban_web` bridge, and does not pull Phase 22 preview/reason/audit action semantics forward.

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change operator trust, support truth, public semantics, or maintainer burden.
- **D-02:** Shift recommendation defaults left for this project and within GSD where possible. Prefer decisive best-practice recommendations over re-asking, except for unusually high-impact public-semantic choices the user is likely to care about directly.
- **D-03:** Keep Postgres-backed rows as the only correctness-bearing truth source. LiveView, PubSub, and coordinator updates remain projections over durable facts rather than independent sources of meaning.
- **D-04:** Preserve the repo's host-owned Phoenix/Ecto posture: explicit read models, thin LiveViews over domain services, bounded vocabulary, support-truthful copy, and least-surprise operator UX.

### Workflow Page Emphasis
- **D-05:** Make the native workflow screen diagnosis-first at the top level rather than state/details-first.
- **D-06:** The first question the page should answer is "what is happening and why?" rather than "what fields are on this workflow row?"
- **D-07:** Raw state, counts, steps, and row-derived details remain available, but they are secondary to the projected diagnosis summary.
- **D-08:** The workflow-level diagnosis summary should render three things prominently: cause, concise evidence, and allowed next action.
- **D-09:** Unsupported or ambiguous states must be rendered explicitly as unsupported/unknown rather than guessed or smoothed over with optimistic copy.

### Evidence Presentation
- **D-10:** Use a narrative-plus-evidence presentation model:
  one short operator-facing headline,
  one compact evidence section,
  and exact durable facts underneath or behind an expandable section.
- **D-11:** Do not make operators assemble the story manually from blocker codes, state fields, timestamps, and rejection rows spread across the page.
- **D-12:** Do not make the narrative a freehand HEEx concern. The narrative must be derived from one shared read-model projector so workflow UI and Lifeline can speak the same language.
- **D-13:** The evidence section should prioritize durable facts that explain the diagnosis, such as:
  active await/deadline,
  matching or late signal facts,
  terminal cause,
  cancel request timing,
  callback posture,
  latest refusal,
  and latest recovery session where relevant.
- **D-14:** Raw codes and exact row-derived fields should still be available for support/debug depth, but they are not the default operator-facing surface.
- **D-15:** Narrative wording must never outrun durable truth. If the facts do not support a confident sentence, fall back to explicit unknown/unsupported phrasing.

### Step Detail Depth
- **D-16:** Use one primary diagnosis step as the focal detail view, while still showing the rest of the workflow graph/list as supporting context.
- **D-17:** Do not keep all steps visually and semantically equal by default; that turns the screen into a prettier database browser and slows diagnosis.
- **D-18:** The primary diagnosis step should be chosen from durable evidence priority rather than display order or first-match convenience.
- **D-19:** Default priority order for the primary diagnosis step is:
  final or terminal cause with actionable evidence,
  then expired wait / waiting on signal,
  then waiting on retryable dependency,
  then missing dependency result,
  then cancel-requested branch state.
- **D-20:** Operators may manually inspect another step, but the UI should still indicate which step is the current primary diagnosis anchor and why.
- **D-21:** The primary step pane should include the diagnosis, concise evidence, dependency chain or downstream impact where relevant, and the allowed next action guidance for that step/workflow situation.

### Allowed Next Action Framing
- **D-22:** In Phase 21, allowed next action is informational guidance only.
- **D-23:** Do not add clickable workflow mutation controls in this phase, even for a small subset of actions.
- **D-24:** Allowed next action should mean "what the system would legally accept from durable truth," not "what this screen can execute today."
- **D-25:** The workflow screen should reuse existing durable refusal and `legal_next_steps` evidence where available so the guidance is grounded in the command core rather than invented in the UI.
- **D-26:** Phase 22 owns bounded, audited, preview/reason-backed workflow actions. Phase 21 should prepare that future surface by making the guidance legible, not by partially implementing a second mutation UX early.

### Shared Projection and Vocabulary
- **D-27:** Add or expand one shared workflow diagnosis projector behind `ObanPowertools.Explain` rather than letting `WorkflowsLive` build stories ad hoc from raw assigns.
- **D-28:** The projector should produce a stable read model for both workflow-level and step-level presentation, including at least:
  `headline`,
  `diagnosis`,
  `primary_step`,
  `allowed_next_action`,
  `evidence_items`,
  `raw_facts`,
  and refusal/recovery/callback summaries where relevant.
- **D-29:** Workflow UI and Lifeline should consume the same diagnosis vocabulary and evidence posture so the operator does not have to learn two explanation systems.
- **D-30:** Final truth must outrank lingering request evidence in the projected diagnosis. For example, once a workflow is terminal, the surface must not keep presenting generic `cancel_requested` when a more specific final outcome such as `completed_after_cancel_request` or `expired_wait` is known.

### UI/UX Posture
- **D-31:** Use layered operator UX:
  diagnosis summary first,
  evidence second,
  full internals third.
- **D-32:** Keep the current native workflow screen readable for both solo operators and maintainers:
  fast answer on top,
  exact facts one click lower,
  raw internals still reachable.
- **D-33:** Do not hide the rest of the DAG; show it as context around the primary diagnosis rather than as the only way to infer what is happening.
- **D-34:** Keep the screen support-truthful and explicit about unavailable features.
  If an action is guidance-only in Phase 21, say so plainly.
- **D-35:** Stay coherent with the existing Phase 10 operator contract:
  explain first,
  keep mutation trust high,
  and avoid introducing a weaker second action path than Lifeline's preview/reason/audit model.

### the agent's Discretion
- Exact naming of the new projector structs/maps and helper functions, provided they stay thin, shared, and driven from durable facts.
- Exact layout, component decomposition, and visual emphasis in the LiveView, provided the diagnosis-first, evidence-second, raw-facts-third posture holds.
- Exact evidence-item field list per diagnosis class, provided the defaults remain compact, support-truthful, and reusable by future Lifeline/workflow surfaces.
- Exact primary-step prioritization helper implementation, provided it is deterministic, durable-fact-driven, and not just first-by-position.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator feel:
  "I can tell what is wrong, how the system knows, and what the legal next move is without reading raw tables first."
- Preferred workflow summary shape:
  `Diagnosis: waiting_on_signal`
  `Primary step: await_payment_webhook`
  `Allowed next action: wait_for_signal`
  `Evidence: active await, no matching consumed signal, deadline 2026-05-24T14:30:00Z`
- Preferred post-cancel truth wording:
  `Cancel was requested, but the in-flight step completed afterward; final truth is completed_after_cancel_request.`
- Preferred narrative posture:
  concise and truthful, not marketing copy or hand-wavy prose.
- Preferred power-user depth posture:
  exact blocker codes, timestamps, snapshots, and durable row facts remain available underneath the operator summary rather than replacing it.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 21 goal, dependency chain, and ownership boundary for workflow diagnosis and the native surface.
- `.planning/milestones/v1.2-ROADMAP.md` — active v1.2 sequence and the Phase 21 versus Phase 22 split.
- `.planning/PROJECT.md` — active milestone posture, support-truth framing, and operator-first product DNA.
- `.planning/REQUIREMENTS.md` — `DIA-01`, `DIA-02`, `VER-01`, `VER-02`, and support-truth constraints that govern this surface.

### Prior locked decisions
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — explain-then-act posture, read-only/native mutation contract, and shift-left recommendation defaults.
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md` — lifecycle vocabulary, durable terminal-cause posture, and diagnosis-from-durable-truth baseline.
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md` — one legal DB-first command path, durable rejection evidence, and operator/runtime parity.
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md` — callback posture, recovery-session evidence, and the rule that workflow truth commits before side-effect delivery.
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md` — await/signal durability, expiry authority, and late-signal evidence posture.
- `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md` — request/evidence/outcome framing, late-evidence preservation, and the rule that final truth outranks lingering request evidence.

### Research and product posture
- `.planning/research/SUMMARY.md` — milestone-level research guidance for diagnosis-first, durable-facts-first workflow semantics.
- `.planning/research/ARCHITECTURE.md` — DB-first commands/semantics layering, explainability patterns, and anti-patterns to avoid.
- `prompts/oban_powertools_context.md` — product posture, personas, operator goals, domain language, and support-truth framing.
- `prompts/oban-powertools-deep-research-original-prompt.md` — user preference for one-shot cohesive defaults, lessons learned, DX, and ecosystem-aware recommendations.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native operator surface posture, bridge boundary, and the rule that Powertools-owned concepts need Powertools-owned explanation.

### Current implementation surfaces
- `lib/oban_powertools/web/workflows_live.ex` — existing native workflow UI to reshape around diagnosis-first presentation.
- `lib/oban_powertools/explain.ex` — current workflow and step story seam to expand into the shared diagnosis projector.
- `lib/oban_powertools/workflow/runtime.ex` — authoritative diagnosis helpers and durable semantics source that the UI must reflect.
- `lib/oban_powertools/lifeline.ex` — existing workflow stuck incident projection and evidence payload shape to align with.
- `lib/oban_powertools/web/lifeline_live.ex` — future neighboring operator surface that should share diagnosis vocabulary rather than fork it.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Explain.workflow_story/3` and `step_story/2` already provide the natural read-model seam for Phase 21 and should grow into the shared projector rather than duplicating logic in LiveView.
- `Runtime.workflow_diagnosis/2` and `step_diagnosis/1` already centralize the diagnosis vocabulary, which makes runtime the correct place to fix ordering and truthfulness issues before the UI consumes them.
- `WorkflowsLive` already has selected-step routing and patch behavior, which fits the focal primary-step model without inventing a second navigation pattern.
- `Lifeline` already projects workflow-stuck incidents from diagnosis plus evidence, which gives Phase 21 a nearby consumer that can benefit from one shared explanation posture.
- `CommandAttempt` already carries latest refusal plus `legal_next_steps`, which can anchor Phase 21's informational-only allowed-next-action guidance.

### Established Patterns
- Repo-wide operator surfaces are expected to explain first and only later act through bounded audited flows.
- Read models in this codebase are thin consumers of runtime-owned truth rather than independent inference engines.
- Native operator pages prefer durable evidence and support-truthful copy over optimistic or overly generic labels.
- The project consistently favors bounded vocabularies over sprawling configuration matrices or ad hoc copy.

### Integration Points
- Phase 21's diagnosis projector should feed both the native workflow screen and future Lifeline/workflow action surfaces in Phase 22.
- The allowed-next-action guidance rendered here should map cleanly onto Phase 22 preview/reason/audit flows without renaming or semantic drift.
- Phase 23 proof and docs work will depend on this phase establishing one coherent explanation vocabulary that matches durable workflow truth.

</code_context>

<deferred>
## Deferred Ideas

- Clickable workflow actions inside the native workflow screen — Phase 22 ownership.
- A broader mutation control surface that duplicates or bypasses Lifeline's preview/reason/audit semantics — out of scope for Phase 21.
- Full DAG graph redesign or a generic workflow-debugging console beyond the diagnosis-first native surface needed for this milestone.
- Optional `oban_web` bridge expansion or plugin-like workflow pages inside the bridge — explicitly outside this phase's boundary.

</deferred>

---

*Phase: 21-workflow-diagnosis-projection-native-workflow-surface*
*Context gathered: 2026-05-24*
