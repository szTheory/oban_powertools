# Phase 27: Control Plane Vocabulary, Status Taxonomy & Ownership Contract - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze one shared control-plane language before Phase 28 reshapes the overview and drill-down flow.

This phase owns:
- the shared operator status taxonomy used across overview, cron, limiters, workflows, Lifeline, audit, and Oban Web handoffs
- the explicit ownership model for Powertools-native versus bridge-only versus host-owned seams
- the shared diagnosis/next-action wording contract that later surfaces must reuse
- the durable audit/event naming contract that keeps machine keys stable while operator copy stays coherent

This phase does not:
- rebuild the generic Oban Web job or queue UI in native Powertools pages
- widen mutation scope beyond the bounded native surfaces already established
- add a new API or CLI automation contract
- collapse bridge, host, and native ownership into one fuzzy “all the same” story

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change public semantics, support truth, operator trust, or the host-owned integration contract.
- **D-02:** Shift the user’s one-shot preference left within GSD for this project. Downstream agents should prefer decisive recommendations over re-asking, except for unusually high-impact public-semantic choices that would genuinely alter the product promise.
- **D-03:** Preserve the repo’s existing DNA: Phoenix-first, Ecto-native, host-owned seams, native Powertools control plane plus bounded Oban Web bridge, explain-then-act mutation posture, durable audit evidence, and least-surprise operator UX.

### Shared Operator Status Taxonomy
- **D-04:** Freeze one layered control-plane status model rather than exposing raw engine states as the primary user-facing vocabulary.
- **D-05:** The primary shared operator-status layer is:
  `needs_review`, `blocked`, `waiting`, `runnable`, `resolved`, `bridge_only`.
- **D-06:** Meanings are strict:
  - `needs_review` means operator attention is warranted now because Powertools has meaningful native diagnosis, refusal, incident, or bounded-action guidance.
  - `blocked` means the resource cannot currently make progress, but the immediate next move may still be diagnosis or waiting rather than operator mutation.
  - `waiting` means healthy deferred state such as time, cooldown, signal, or upstream dependency wait.
  - `runnable` means the system can make progress now or accept work now without intervention.
  - `resolved` means a prior attention-worthy state is durably closed and evidence remains available.
  - `bridge_only` means the relevant next inspection exists only through the Oban Web bridge or generic job UI, not as a Powertools-native diagnosis or mutation promise.
- **D-07:** `bridge_only` is an ownership and venue status, not a runtime-failure status.
- **D-08:** `blocked` and `needs_review` must remain distinct. A limiter can be `blocked` without becoming a Lifeline-style review item, and an incident can `need_review` even when the underlying resource is no longer blocked in the narrow engine sense.
- **D-09:** Severity is separate from status. Use severity only as a secondary prioritization signal for ordering and triage, never as the primary cross-surface status language.
- **D-10:** Raw engine and domain states remain first-class truth in schemas and bridge destinations, but they live under the shared operator-status layer rather than replacing it.

### Layered Read Model Shape
- **D-11:** Every surface participating in the control plane should eventually project at least these fields from durable truth:
  `operator_status`, `diagnosis`, `raw_state`, `ownership`, `severity`, `next_action`, `venue`, and `evidence`.
- **D-12:** Diagnosis remains a richer secondary dimension than operator status. Examples include `waiting_on_signal`, `waiting_on_dependencies`, `missing_executor`, `cooling_down`, `paused`, `cancel_requested`, and refusal-specific causes.
- **D-13:** The shared operator layer must stay small and durable even if diagnosis categories grow over time.
- **D-14:** Add a shared presenter/read-model seam for this vocabulary rather than letting each LiveView invent its own badges, tense, and section ordering.

### Ownership Model And Bridge Posture
- **D-15:** Freeze a hybrid ownership model:
  explicit `native vs bridge` language in the UI,
  capability-based posture for actions,
  and support-truth plus host-owned seam language in docs/tests.
- **D-16:** Native Powertools pages are the authoritative surface for Powertools-owned diagnosis, preview, reason, refusal, and audited mutation semantics.
- **D-17:** `/ops/jobs/oban` remains the **Oban Web bridge**: a bounded inspection surface that reuses Powertools auth and display seams but does not inherit the native Powertools mutation contract.
- **D-18:** Do not make the bridge visually or semantically pretend to be just another native Powertools page. One shell can contain multiple truthfully labeled surfaces.
- **D-19:** Preferred UI vocabulary:
  - native page badge: `Powertools-native`
  - bridge page badge: `Oban Web bridge`
  - native mutation posture: `Audited action`
  - bridge posture: `Inspection only`
- **D-20:** Avoid presenting `host-owned` as repeated end-user chrome. Reserve host-owned seam wording for docs, integration guides, and tests where implementation responsibility matters.
- **D-21:** Keep route and auth seam truth explicit in docs:
  host apps own route exposure, auth policy, and display policy wiring;
  Powertools owns adapters, presenters, native page behavior, and the bridge contract.

### Shared Wording Model
- **D-22:** Use a layered diagnosis-first wording contract across overview and drill-down surfaces:
  `status -> diagnosis -> legal next action -> venue -> evidence -> audit`.
- **D-23:** `next action` means the legal/system-valid next move from durable truth, not necessarily an action executable on the current screen.
- **D-24:** `venue` is mandatory whenever wording could otherwise blur “legal next move” with “available on this page.”
- **D-25:** Overview and drill-down surfaces should converge on one shared mental model:
  what needs attention,
  why,
  where the operator goes next,
  and where durable proof lives.
- **D-26:** Audit and timeline language should trail diagnosis language, not replace it. Chronology supports the control plane; it is not the primary triage model.
- **D-27:** Do not let action-heavy wording become the dominant product language. Powertools remains an explain-first control plane, not a generic button farm.

### Surface-Specific Mapping Defaults
- **D-28:** Overview should stop leading with feature counts and instead lead with shared control-plane buckets such as `Needs Review`, `Blocked`, `Waiting`, `Runnable`, `Resolved Recently`, and `Bridge-only Follow-up`.
- **D-29:** Limiters should map current `Blocked` / `Cooling Down` / `Runnable` behavior into the shared taxonomy:
  saturation -> `blocked`,
  cooldown -> `waiting`,
  healthy capacity -> `runnable`.
- **D-30:** Cron should stop using raw row state as the primary operator story. Healthy scheduled delay is `waiting`, eligible work is `runnable`, and operator-paused entries should be rendered through the shared status/diagnosis model rather than page-local vocabulary alone.
- **D-31:** Workflows should continue diagnosis-first, but raw workflow `state` should no longer be the main operator label. Workflow and step drill-downs should lead with shared operator status plus diagnosis and then show raw workflow semantics underneath.
- **D-32:** Lifeline should keep `Needs Review` and `Resolved` as its primary row posture, because that already aligns best with the shared control-plane taxonomy.
- **D-33:** Bridge handoffs must be marked explicitly when the operator is leaving the native control plane for generic job inspection.

### Audit Naming Contract
- **D-34:** Freeze a dual-layer audit contract over an explicit event envelope.
- **D-35:** Distinguish three concepts:
  - `command_key` for operator intent and policy flow, using imperative `snake_case` names such as `pause_cron_entry`, `preview_repair`, `execute_repair`, and `request_cancel`
  - `event_type` for durable audit truth, using stable dot-separated domain event names such as `cron.paused`, `workflow.cancel_requested`, `lifeline.repair_executed`, and `limiter.blocked`
  - operator-facing labels generated from presenters, such as “Paused cron entry” or “Requested workflow cancellation”
- **D-36:** Do not store operator command keys as the only durable audit truth. Command keys are UI/policy-layer semantics, not the canonical historical event vocabulary.
- **D-37:** Audit events should describe what happened, not merely which flow or button path triggered it.
- **D-38:** Normalize audit storage toward structured resource identity:
  `resource_type`, `resource_id`, and compatible derived display/resource strings rather than one permanently overloaded `resource` field alone.
- **D-39:** Preserve durable actor identity as typed data, not just a display string. `actor_id` remains important; typed principal identity should be queryable without relying entirely on freeform metadata.
- **D-40:** Reasons should remain durable raw evidence; rendered reason wording is a presenter concern.
- **D-41:** UI copy can evolve independently from `event_type` and `command_key`. This separation is the semver-safe path and the strongest DX story for tests, docs, and future vocabulary cleanup.

### Shared Presentation And Test Discipline
- **D-42:** Shared control-plane copy should come from one presenter registry or equivalent read-model seam, not from scattered HEEx string fragments.
- **D-43:** Tests should assert the semantic contract across surfaces:
  shared status buckets,
  explicit venue/ownership wording,
  stable `event_type` keys,
  and consistent audit versus action copy.
- **D-44:** Docs should explain the control-plane mental model once and then reuse the same vocabulary in README, guides, example-host material, and docs-contract assertions.

### the agent's Discretion
- Exact module and struct names for the shared presenter/read-model seam, provided the layered contract above remains explicit and reusable.
- Exact badge/component layout, provided native versus bridge ownership stays clear and support-truthful.
- Exact schema migration sequencing for audit normalization, provided `event_type`, resource identity, and command/event separation become explicit.
- Exact choice between `cron.run_now_requested` and `cron.run_now` style event naming, provided the domain-first durable event vocabulary remains consistent.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator feel:
  “I can tell what needs attention, why, where I should go next, and whether this is Powertools-native or an Oban Web bridge handoff.”
- Preferred status stack:
  top-level shared operator badges for triage,
  diagnosis beneath for Powertools-specific truth,
  raw engine/domain state preserved underneath for support and debugging depth.
- Preferred ownership posture:
  one `/ops/jobs` shell,
  clearly labeled native Powertools pages,
  clearly labeled Oban Web bridge,
  and no pretend parity where the semantics are intentionally different.
- Preferred wording posture:
  diagnosis-first and venue-aware,
  not raw-state-first and not action-first.
- Preferred audit posture:
  stable machine-readable event keys,
  structured resource identity,
  typed durable actor data,
  and operator-facing labels generated from one shared presenter layer.
- Preferred overview future:
  cards should answer “what needs attention, why, and where do I go next?” instead of serving mainly as feature counters.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 27 scope and the ordering of later overview/action/audit cohesion work.
- `.planning/PROJECT.md` — v1.3 milestone goal, native-shell posture, and support-truth framing.
- `.planning/REQUIREMENTS.md` — `CTL-01`, `CTL-02`, and `CTL-03`, plus the v1.3 overview/action/support-truth constraints this phase must anchor.
- `.planning/STATE.md` — current milestone posture and next-action framing.

### Prior locked decisions that constrain this phase
- `.planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md` — shared auth/display seams, explicit native-versus-bridge contract, and host-owned policy posture.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — preview/reason/refusal/audit contract, read-only posture, and native mutation authority.
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` — diagnosis-first workflow surface and shared explanation posture.
- `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-CONTEXT.md` — Lifeline as native execution venue and the rule that legal next action is not always executable on the current screen.
- `.planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md` — support-truth and canonical-proof discipline for planning artifacts.

### Product posture and prior research
- `prompts/oban_powertools_context.md` — product posture, domain language, operator personas, and explainability direction.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid shell plus bounded bridge strategy and operator-console UX principles.
- `prompts/oban-powertools-deep-research-original-prompt.md` — user preference for cohesive one-shot recommendations, ecosystem lessons, and “ultimate lib” DX posture.

### Current implementation surfaces and guides
- `README.md` — current public route/support-truth story and integration posture.
- `guides/optional-oban-web-bridge.md` — current bridge framing and host guidance.
- `guides/support-truth-and-ownership-boundaries.md` — ownership and support-truth constraints.
- `lib/oban_powertools/web/router.ex` — current native route tree and bridge mount contract.
- `lib/oban_powertools/web/oban_web_bridge.ex` — bridge access and display adapter.
- `lib/oban_powertools/web/live_auth.ex` — shared read-only, permission, and audit-consequence language.
- `lib/oban_powertools/web/engine_overview_live.ex` — current overview wording and count-first posture to replace.
- `lib/oban_powertools/web/limiters_live.ex` — limiter state wording and diagnosis entrypoint.
- `lib/oban_powertools/web/cron_live.ex` — current preview/reason/audit mutation copy.
- `lib/oban_powertools/web/workflows_live.ex` — diagnosis-first workflow wording and Lifeline handoff language.
- `lib/oban_powertools/web/lifeline_live.ex` — current incident/review/preview/audit venue and terminology.
- `lib/oban_powertools/web/audit_live.ex` — audit timeline wording and current raw event rendering.
- `lib/oban_powertools/audit.ex` — current audit storage contract that needs Phase 27 normalization.
- `lib/oban_powertools/explain.ex` — existing explanation seam that should inform shared status/diagnosis presenters.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Web.LiveAuth` already centralizes read-only, permission, and audit-consequence copy, making it the natural place to align cross-surface posture language.
- `ObanPowertools.Web.ObanWebBridge` already freezes the bridge as a thin read-only adapter over shared auth and display seams.
- `ObanPowertools.Explain` already provides a natural shared explanation seam that later status/diagnosis presenters can build on instead of inventing page-local inference.
- `WorkflowsLive` and `LifelineLive` already prove the repo’s strongest diagnosis-first patterns.
- `Audit` already distinguishes durable event writing from operator-facing rendering enough to formalize a better contract instead of starting over.

### Established Patterns
- The repo prefers host-owned config seams with library-owned adapters.
- Native surfaces already trend toward explain-first and bounded audited actions.
- The bridge is intentionally narrower than the native control plane and should remain so.
- Durable evidence and audit posture matter more than flattening everything into generic dashboard semantics.

### Integration Points
- Phase 28 overview work should consume the shared status, diagnosis, venue, and ownership contract frozen here.
- Phase 29 and Phase 30 should extend the same vocabulary into preview/refusal/audit copy and into limiter/workflow/Lifeline/cron cohesion work rather than redefining terms.
- Phase 31 docs and proof should assert the same vocabulary through README, guides, docs-contract tests, and example-host material.

</code_context>

<deferred>
## Deferred Ideas

- Full native replacement of Oban Web’s generic queue/job dashboard — later milestone ownership only.
- CLI or API automation surfaces for the control plane — defer until the operator vocabulary has settled.
- Reframing severity, alert routing, or SRE escalation into a first-class public control-plane taxonomy — keep severity secondary for now.
- Any broad mutation-surface expansion beyond the bounded native venues already defined in prior phases.

</deferred>

---

*Phase: 27-control-plane-vocabulary-status-taxonomy-ownership-contract*
*Context gathered: 2026-05-25*
