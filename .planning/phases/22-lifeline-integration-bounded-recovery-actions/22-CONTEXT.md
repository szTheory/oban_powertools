# Phase 22: Lifeline Integration & Bounded Recovery Actions - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Unify diagnosis vocabulary and bounded workflow recovery actions across the native workflow and Lifeline surfaces.

This phase owns how workflow-native operator actions are surfaced, previewed, audited, and routed back through the shared DB-first workflow command pipeline. It also owns the Phase 21 to Phase 22 handoff from guidance-only allowed-next-action text to real bounded operator actions.

This phase does not broaden Powertools into a generic workflow control plane, does not add a second mutation engine, does not widen the optional `oban_web` bridge, and does not ship broad workflow-level override verbs whose semantics are not already durable and support-truthful.

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change operator trust, public semantics, support truth, or maintainer burden.
- **D-02:** Shift strong recommendations left for this project and within GSD workflows where possible. Prefer decisive defaults over re-asking except for unusually high-impact public-semantic decisions the user is likely to care about directly.
- **D-03:** Keep Postgres-backed workflow rows, command evidence, recovery evidence, and preview/audit rows as the only correctness-bearing operator truth. LiveView, PubSub, and screen-specific affordances remain projections over that truth.
- **D-04:** Preserve the repo’s host-owned Phoenix/Ecto posture:
  thin LiveViews,
  explicit context functions,
  one DB-first mutation core,
  one bounded vocabulary,
  and one least-surprise operator trust model.

### Shared Action Authority
- **D-05:** Workflow action legality is owned by shared durable workflow truth, not by the existence of an active Lifeline incident row.
- **D-06:** Bounded workflow actions may be surfaced on any Powertools-native surface that consumes the shared workflow diagnosis/action model, even when there is no active Lifeline incident for the same workflow situation.
- **D-07:** Lifeline remains the incident inbox and review center, but it is not the semantic source of truth for whether a workflow action is legal.
- **D-08:** Incident rows remain part of the legal precondition only for incident-shaped actions whose meaning depends on incident evidence, such as dead-executor rescue or other future executor-health repair paths.
- **D-09:** The workflow diagnosis projector, command refusals, and `legal_next_steps` evidence should remain the canonical input for what action is allowed next.

### Action Venue And Operator Flow
- **D-10:** Keep the workflow detail page diagnosis-first in Phase 22.
- **D-11:** Do not embed a second full inline `preview -> reason -> execute` mutation console directly into the workflow detail page in this phase.
- **D-12:** Lifeline remains the sole native execution venue for bounded workflow repairs in Phase 22.
- **D-13:** The workflow page should provide a direct handoff into Lifeline with workflow, step, diagnosis, and allowed-action context preselected when a bounded action is available.
- **D-14:** The workflow page must still answer:
  what happened,
  why the system believes it,
  and what the legal next move is,
  but execution should flow through the already-hardened Lifeline mutation posture.
- **D-15:** This keeps one high-trust mutation venue while still avoiding the operator surprise of “the workflow page knows the action is legal but gives me no direct path to do it.”
- **D-16:** Lifeline therefore evolves from “incident-only repair inbox” into the native review-and-execute center for both incident-driven and workflow-directed bounded actions, without giving up its preview/reason/audit role.

### Initial Bounded Action Set
- **D-17:** The initial Phase 22 workflow action set is intentionally narrow:
  `workflow_step_retry`,
  `workflow_step_cancel`,
  and `workflow_request_cancel`.
- **D-18:** `workflow_request_cancel` is the only workflow-level action admitted in Phase 22 because its semantics are already grounded in the DB-first command core and the locked request/evidence/outcome model.
- **D-19:** Do not expose broader workflow-level actions yet:
  no workflow-wide retry,
  no workflow-wide recover,
  no force-expire,
  no replay-signal,
  no reconcile button,
  and no terminate/abort-style override verb.
- **D-20:** Do not expose a stronger “stop now” semantic under the name `cancel`.
  The copy and UX must consistently say `Request cancel` and explain that idle work may stop immediately while in-flight work may still finish.
- **D-21:** Allowed-next-action text in the workflow page should map 1:1 to the executable action vocabulary in Lifeline.
  Do not invent extra labels that imply broader hidden capabilities.

### Shared Mutation Envelope
- **D-22:** Reuse the existing shared native mutation envelope semantics for workflow actions:
  durable preview token,
  explicit `ready` / `drifted` / `expired` / `consumed` lifecycle,
  server-side drift and expiry revalidation,
  single-use consume,
  reason policy,
  and local durable audit consequence.
- **D-23:** Do not create a second workflow-specific preview lifecycle or separate workflow-only audit model in Phase 22.
- **D-24:** Reuse the proven preview envelope seam behind the current Lifeline and cron flows, but keep workflow legality, refusal reasons, and effect planning owned by the workflow command core.
- **D-25:** Workflow preview payloads, drift reasons, action labels, and audit metadata must be workflow-native and diagnosis-native rather than repair-generic.
- **D-26:** Generalize the current `RepairPreview` seam away from repair-only naming over time so the same operator trust model can cover Lifeline, cron, and workflows without semantic distortion.
- **D-27:** Preview rows are operator-envelope state, not workflow domain truth.
  Workflow domain truth continues to live in workflow rows, command attempts, recovery sessions, recovery attempts, awaits, signals, and related command-core evidence.

### UX, DX, And Support-Truth Posture
- **D-28:** Operators should learn one mutation trust model across native surfaces:
  preview shows what will change,
  execute rechecks legality and drift,
  preview is single-use,
  and one immutable operator evidence trail is written.
- **D-29:** Workflow actions should not read like generic Lifeline “repair” copy.
  Use workflow-native verbs and workflow-native evidence, while still honoring the same preview contract.
- **D-30:** Keep provenance and audit visibility close to the acted-on workflow resource, not only in a global audit page.
- **D-31:** The workflow page should remain the best place to understand the workflow.
  Lifeline should remain the best place to confirm and execute a bounded operator intervention.
- **D-32:** Documentation and UI copy must preserve the repo’s least-surprise semantics:
  `request_cancel` is cooperative,
  not all legal actions imply immediate final outcomes,
  and successful prior work should remain preserved unless a later milestone explicitly broadens that contract.

### the agent's Discretion
- Exact extraction/refactor path to generalize the current preview envelope away from repair-only naming, provided operator-facing semantics stay stable.
- Exact deep-link or handoff mechanism from workflow detail into Lifeline, provided the selected workflow, step, and action context are preserved clearly.
- Exact struct and helper names for the shared diagnosis/action read model, provided action legality remains command-core-owned and not LiveView-owned.
- Exact preview payload shape for workflow-native consequences, provided it stays truthful, bounded, and aligned with the existing shared preview lifecycle.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator experience:
  “The workflow page explains exactly what is happening and what is legal next; Lifeline shows the concrete preview, asks for my reason, and writes the audit evidence.”
- Preferred workflow-to-Lifeline handoff:
  a direct native CTA that opens Lifeline already focused on the workflow, step, diagnosis, and recommended action rather than making the operator search manually.
- Preferred cancel wording:
  “Request cancel” with explicit copy that idle work may cancel immediately while in-flight work may still complete and preserve final evidence.
- Preferred trust-model posture:
  one preview lifecycle everywhere,
  but workflow-native wording and workflow-native evidence where the resource is a workflow rather than a repair incident.
- Preferred GSD posture:
  strong recommendations like these should be treated as project defaults and shifted left unless a later public-semantic or support-truth conflict forces reconsideration.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone framing
- `.planning/ROADMAP.md` — Phase 22 goal, dependency chain, and ownership boundary for workflow/Lifeline action unification.
- `.planning/milestones/v1.2-ROADMAP.md` — active v1.2 sequence and the Phase 21 versus Phase 22 split.
- `.planning/PROJECT.md` — active milestone posture, operator-first product DNA, and support-truth constraints.
- `.planning/REQUIREMENTS.md` — `DIA-02`, `VER-01`, `VER-02`, and support-truth rules that govern bounded workflow actions.

### Prior locked decisions
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — one native preview/reason/audit contract, page-level read-only framing, and authoritative native mutation ownership.
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md` — one DB-first legal mutation path and explicit operator/runtime parity.
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md` — recovery evidence posture and preserved successful prior work.
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md` — signal/await durability and late-arrival caution.
- `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md` — request/evidence/outcome semantics and the rule that cancel is not immediate finality.
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` — diagnosis-first workflow UI, shared vocabulary, and guidance-only allowed-next-action posture that Phase 22 now activates.

### Research and product posture
- `.planning/research/ARCHITECTURE.md` — shared command/semantics layering, Lifeline integration seam, and preview/reason/audit reuse guidance.
- `.planning/research/PITFALLS.md` — warnings about second mutation paths, cancel overpromises, and diagnosis surfaces that require tribal knowledge.
- `.planning/research/SUMMARY.md` — milestone-level recommendation for explicit workflow explanation and bounded operator actions.
- `.planning/research/operator_ux.md` — explain-then-act posture, dry-run repair center model, and operator-trust rationale.
- `prompts/oban_powertools_context.md` — product posture, domain language, personas, and support-truth framing.
- `prompts/oban-powertools-deep-research-original-prompt.md` — project-wide preference for cohesive one-shot recommendations, lessons learned, and great DX.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — native ops-console posture, bridge boundary, and the rule that Powertools-owned semantics need Powertools-owned explanation.

### Current implementation surfaces
- `lib/oban_powertools/workflow/runtime.ex` — legal workflow mutation core and durable refusal vocabulary.
- `lib/oban_powertools/workflow.ex` — stable public workflow API seam.
- `lib/oban_powertools/explain.ex` — shared diagnosis/read-model seam and latest refusal / recovery summaries.
- `lib/oban_powertools/lifeline.ex` — existing preview/execute path, workflow-step repair actions, and preview drift/consume semantics.
- `lib/oban_powertools/lifeline/repair_preview.ex` — current shared preview lifecycle implementation to generalize rather than fork.
- `lib/oban_powertools/cron.ex` — second existing consumer of the shared preview lifecycle.
- `lib/oban_powertools/web/workflows_live.ex` — workflow diagnosis surface that should remain diagnosis-first with Lifeline handoff.
- `lib/oban_powertools/web/lifeline_live.ex` — native high-trust execution venue to extend with workflow-directed actions.
- `lib/oban_powertools/web/live_auth.ex` — shared auth, permission, audit-principal, and mutation error vocabulary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Workflow.Runtime` already owns the legal DB-first mutation path and refusal vocabulary, which makes it the correct authority for workflow action legality.
- `ObanPowertools.Explain` already exposes diagnosis, latest refusal, callback posture, and recovery context, which gives Phase 22 the right shared read-model seam for actionable workflow guidance.
- `ObanPowertools.Lifeline` already implements the repo’s highest-trust operator flow:
  preview,
  drift check,
  reason capture,
  execute,
  consume preview,
  and durable audit.
- `ObanPowertools.Lifeline.RepairPreview` and cron preview flows already prove a shared preview lifecycle across multiple native surfaces, which strongly argues for reuse instead of workflow-specific reinvention.
- `LiveAuth` already centralizes page auth, action auth, missing-principal denial, and shared mutation error vocabulary.

### Established Patterns
- Repo-wide operator mutations are expected to explain first and only then act through bounded audited flows.
- Native operator pages are allowed to differ in emphasis, but they should not invent competing trust models.
- Public APIs stay context-like and explicit rather than generic command buses or hidden mutation engines.
- Durable preview/audit evidence is distinct from public telemetry and from workflow domain truth.

### Integration Points
- Phase 22 should connect the Phase 21 allowed-next-action read model to the existing Lifeline preview/execute contract without semantic drift.
- Workflow-native actions should eventually use the same shared preview envelope that cron and Lifeline already use, while keeping workflow-specific payloads and audit details.
- Phase 23 verification and support-truth work will depend on these actions having crisp semantics, stable copy, and explicit proof boundaries.

</code_context>

<deferred>
## Deferred Ideas

- Inline full `preview -> reason -> execute` workflow-page controls — defer until the product intentionally chooses the workflow page as a second or primary high-trust mutation venue.
- Workflow-wide retry/recover, force-expire, replay-signal, reconcile, or terminate-style controls — defer until each has equally explicit durable semantics, preview shape, and proof posture.
- Incident-only executor-health repair actions becoming workflow-page actions — defer unless the incident evidence itself can be represented truthfully on the workflow resource without distortion.
- A broader cross-product control-plane unification across workflows, jobs, queues, and Lifeline — later milestone ownership.

</deferred>

---

*Phase: 22-lifeline-integration-bounded-recovery-actions*
*Context gathered: 2026-05-24*
