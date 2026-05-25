# Phase 28: Diagnosis-First Overview & Context-Preserving Drilldowns - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `/ops/jobs` the real operator starting point instead of a metrics-only landing page.

This phase owns:
- the overview triage model for what needs attention, why, and where to go next
- the bounded handoff contract from overview cards into native Powertools pages and the Oban Web bridge
- context-preserving drilldown behavior across refresh, remount, and read-only access
- a support-truthful treatment of bridge-only and recently-resolved follow-up on the overview

This phase does not:
- rebuild the generic Oban Web jobs or queues UI in native Powertools pages
- add a new mutation surface on the overview itself
- widen bridge ownership beyond inspection-only generic job follow-up
- turn the overview into a full history, analytics, or reporting dashboard

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change operator trust, public semantics, support truth, or the native-versus-bridge product promise.
- **D-02:** Shift the user's one-shot preference left within this phase and downstream GSD work. Prefer decisive recommendations over re-asking except for unusually high-impact choices that would genuinely alter the public product story.
- **D-03:** Preserve the repo's existing DNA:
  Phoenix-first,
  host-owned seams,
  Ecto/Postgres-native durable truth,
  diagnosis-first operator UX,
  preview/reason/audit trust on native mutation surfaces,
  and explicit Oban Web bridge boundaries.

### Overview Triage Shape
- **D-04:** The `/ops/jobs` landing page should use a **hybrid triage shape**, not pure count cards and not a dense inbox/table-first dashboard.
- **D-05:** The overview should lead with shared operator-status buckets for orientation, then immediately show bounded exemplar evidence and next-step guidance inside those buckets.
- **D-06:** The top-level scan should answer, in order:
  what needs attention,
  why it needs attention,
  where the operator should go next,
  and whether that next venue is Powertools-native or bridge-only.
- **D-07:** Do not make the overview behave like a generic jobs table. Generic job and queue browsing remains the bridge's job for now.
- **D-08:** The primary attention posture remains current-state-first:
  `Needs Review`,
  `Blocked`,
  `Waiting`,
  `Runnable`,
  with `Resolved Recently` treated as secondary continuity evidence and `Bridge-only Follow-up` treated as an ownership/venue bucket rather than an error bucket.

### Card Depth And Evidence Posture
- **D-09:** Overview cards must not stop at counts. Each primary card should include:
  a shared status label,
  the count,
  one concise diagnosis sentence derived from durable truth,
  one to three exemplar rows or evidence items,
  and explicit venue-aware next-step copy.
- **D-10:** Exemplar evidence must be bounded, deterministic, and support-truthful. Do not show an arbitrary feed of noisy recent rows.
- **D-11:** Card evidence is representative, not exhaustive. The UI should imply or state that the exemplars are sampled priority items, not the whole bucket.
- **D-12:** Keep action execution off the overview cards. Overview cards may guide and link, but preview/reason/audit execution remains on the destination surfaces.
- **D-13:** The overview should follow the same layered wording model locked in Phase 27:
  `status -> diagnosis -> next action -> venue -> evidence -> audit`.
- **D-14:** Do not let card summaries become vague marketing copy. Every diagnosis sentence must be grounded in durable facts or shared presenter/read-model output.

### Handoff Model And URL-Owned Context
- **D-15:** The default handoff from overview into a Powertools-native page is:
  land on the destination page with the relevant resource already selected in a URL-backed detail or focus state.
- **D-16:** Native handoffs should preserve the operator's mental model without encoding ephemeral execution state. URL params may own selected resource, selected step, active tab, or durable review context, but not preview tokens, pending mutation state, or other action-execution internals.
- **D-17:** Bridge-only or broad aggregate destinations should usually land on a filtered list or filtered bridge page, not on fake native-style exact state that Powertools does not own.
- **D-18:** Exact deep-link jumps are allowed only as scoped exceptions for durable, review-oriented states such as a workflow step, incident, or audit-linked resource when the identifier is stable and the destination owns that read model.
- **D-19:** The cross-surface URL contract should be explicit and reusable:
  native pages own stable param-based selection contracts,
  in-page selection changes should be patch-friendly,
  and cross-LiveView transitions should preserve only durable context.
- **D-20:** Refresh, remount, reconnect, and read-only access must preserve the same selected diagnosis context wherever the destination surface supports it.

### Bridge-Only Ownership And Support Truth
- **D-21:** Bridge-only handoffs must be explained **before** click, not only after navigation.
- **D-22:** The overview should use compact explicitness for bridge-only items:
  a short ownership label such as `Oban Web bridge`
  plus a posture cue such as `Inspection only` or equivalent read-only wording.
- **D-23:** Do not visually or semantically present bridge destinations as if they were just another native Powertools page with equal mutation semantics.
- **D-24:** Repeat the fuller native-versus-bridge explanation once on the destination, but keep overview-level bridge copy terse enough that it remains scannable.
- **D-25:** `bridge_only` remains an ownership and venue signal, not a failure severity or degraded-health status.

### Resolved-Recently Treatment
- **D-26:** Keep a resolved-recently signal on the overview, but make it secondary to active attention.
- **D-27:** Resolved-recently content exists to build operator trust and continuity, not to compete with active triage.
- **D-28:** The resolved signal must state an explicit window and honest source. Avoid soft wording such as bare `Resolved Recently` if the underlying data is actually archived repair actions rather than unique resolved incidents.
- **D-29:** The resolved signal should deep-link into resolved Lifeline or audit/archive destinations where the durable evidence lives.
- **D-30:** Do not give resolved items equal visual urgency with `Needs Review` or other active attention buckets.

### Overview Read-Model Architecture
- **D-31:** Phase 28 should add one shared overview read-model or presenter seam rather than composing bucket math, exemplar selection, and next-step copy ad hoc inside HEEx.
- **D-32:** Bucket counts, diagnosis sentences, exemplar evidence, venue labels, and next-step guidance must all come from one coherent read-model contract so the overview cannot drift internally.
- **D-33:** Exemplar selection should prefer durable, user-meaningful priority rules over recency theater. Favor items that best explain why the bucket matters now.
- **D-34:** Keep overview queries bounded and cheap enough for LiveView refresh. Do not over-fetch full drilldown state just to render card exemplars.
- **D-35:** Severity may influence ordering inside a bucket, but it must remain secondary to shared operator status rather than replacing it.

### the agent's Discretion
- Exact module and struct names for the shared overview read-model/presenter seam, provided the selection, diagnosis, venue, and evidence contract stays explicit and reusable.
- Exact card layout, spacing, and component decomposition, provided active triage stays primary and bridge/native ownership remains unmistakable.
- Exact exemplar count per card, provided it stays tightly bounded and support-truthful.
- Exact resolved-history window and label wording, provided the source semantics are honest and the signal remains visually secondary.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator feel:
  “I can open `/ops/jobs` and immediately tell what needs attention, why it matters, and where I should go next without guessing.”
- Preferred overview structure:
  shared status buckets on top,
  each with one diagnosis sentence,
  one to three exemplar items,
  and one explicit venue-aware CTA or next-step hint.
- Preferred native handoff posture:
  click into a destination that already has the relevant item selected and survives refresh/remount through URL-backed state.
- Preferred bridge posture:
  “This follow-up lives in the Oban Web bridge. It is inspection-only and intentionally distinct from Powertools-native audited action surfaces.”
- Preferred resolved posture:
  continuity evidence visible enough to reassure the operator that fixes landed,
  but visually and semantically secondary to active attention.
- Preferred anti-patterns to avoid:
  feature-counter vanity cards,
  table-heavy inbox sprawl on the landing page,
  fake bridge/native parity,
  and URL state that restores mutation internals or preview tokens.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 28 scope, plans, and dependency on the Phase 27 vocabulary contract.
- `.planning/PROJECT.md` — v1.3 milestone goal, operator-cohesion posture, and native-shell product story.
- `.planning/REQUIREMENTS.md` — `OVR-01`, `OVR-02`, and `OVR-03`, plus the milestone-wide native-versus-bridge and support-truth constraints.
- `.planning/STATE.md` — current milestone posture and sequencing.

### Prior locked decisions that constrain this phase
- `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` — shared status taxonomy, venue wording, bridge-only meaning, and the layered `status -> diagnosis -> next action -> venue -> evidence -> audit` contract.
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` — diagnosis-first read-model posture, narrative-plus-evidence layering, and URL-backed detail emphasis.
- `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-CONTEXT.md` — Lifeline as the trusted execution venue and native handoff expectations.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — shared read-only/preview/reason/audit posture and the native-versus-bridge mutation boundary.

### Product posture and research prompts
- `prompts/oban_powertools_context.md` — product posture, personas, domain language, and operator expectations.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid shell-plus-bridge strategy and why native Powertools pages should own Powertools-specific explanation.
- `prompts/oban-powertools-deep-research-original-prompt.md` — lessons-learned posture, batteries-included goals, and the user's preference for cohesive one-shot recommendations.

### Current implementation surfaces
- `lib/oban_powertools/web/engine_overview_live.ex` — current count-heavy overview to replace with diagnosis-first triage.
- `lib/oban_powertools/web/control_plane_presenter.ex` — shared status labels, ownership badges, and venue wording to extend rather than bypass.
- `lib/oban_powertools/web/workflows_live.ex` — existing URL-backed detail selection and diagnosis-first native surface pattern.
- `lib/oban_powertools/web/lifeline_live.ex` — existing selected-row/read-only/preview destination patterns.
- `lib/oban_powertools/web/limiters_live.ex` — current native inspection surface that can accept overview-selected context.
- `lib/oban_powertools/web/cron_live.ex` — current native action surface and shared trust-model copy.
- `lib/oban_powertools/web/audit_live.ex` — read-only audit destination that should remain part of the same control-plane story.
- `lib/oban_powertools/web/router.ex` — route ownership and native-versus-bridge mount contract.
- `lib/oban_powertools/web/live_auth.ex` — shared page/action auth and read-only vocabulary.
- `lib/oban_powertools/web/oban_web_bridge.ex` — bridge adapter and inspection-only seam.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.ControlPlanePresenter` already owns shared status and ownership wording, making it the natural home for overview-level venue and bridge labels.
- `WorkflowsLive` already demonstrates URL-backed detail selection through `handle_params/3`, which is the right model for context-preserving native drilldowns.
- `LifelineLive` already models selected-resource continuity, current-view switching, and trusted destination posture.
- `LiveAuth` already centralizes read-only, permission, and audit-consequence wording, which overview cards should reuse rather than paraphrase.

### Established Patterns
- Native Powertools pages already trend toward explain-first and venue-aware UX.
- The bridge is intentionally narrower and read-only; overview work should reinforce that instead of smoothing it over.
- This repo prefers durable read models and explicit context functions over ad hoc LiveView-local inference.

### Integration Points
- Phase 28 should create a shared overview read-model seam that later Phases 29 and 30 can reuse when tightening cross-surface action and drilldown cohesion.
- Native handoff params established here should become the canonical cross-surface context contract for later overview, action, and audit follow-up work.
- Resolved-history labeling decided here should stay compatible with future audit and Lifeline chronology tightening rather than inventing a second history vocabulary.

</code_context>

<deferred>
## Deferred Ideas

- Turning `/ops/jobs` into a full table-first operator inbox or generic queue dashboard.
- Executing preview/reason/audit actions directly from overview cards.
- Native replacement of the generic Oban Web jobs and queues inspection experience.
- Rich historical analytics, trend dashboards, or shift-handoff reporting on the overview surface.

</deferred>

---

*Phase: 28-diagnosis-first-overview-context-preserving-drilldowns*
*Context gathered: 2026-05-25*
