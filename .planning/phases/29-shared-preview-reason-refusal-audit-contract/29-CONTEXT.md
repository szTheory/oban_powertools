# Phase 29: Shared Preview, Reason, Refusal & Audit Contract - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Make bounded native mutations feel like one policy surface instead of per-page conventions.

This phase owns:
- the shared preview contract across cron, Lifeline, and workflow-directed actions
- the shared reason-policy contract for native audited actions
- the shared refusal wording model across disabled controls, preview lifecycle states, and workflow handoffs
- the cross-surface audit follow-up contract so local evidence and the global audit destination tell one coherent story

This phase does not:
- add new mutation families or a new queue/job mutation surface
- move workflow execution out of Lifeline into a second native execution console
- turn audit into a broad analytics, history-search, or event-sourcing product
- widen the Oban Web bridge beyond its existing inspection-only role

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** Treat the recommendations in this context as locked defaults for downstream GSD planning and implementation. Do not reopen them unless a later choice would materially change public semantics, support truth, operator trust, architectural boundaries, or maintainer burden.
- **D-02:** Shift the user’s research-first, one-shot recommendation preference left within GSD for this repo. Downstream agents should read repo-local context and prompt material, narrow options aggressively, and ask only unusually high-impact unresolved questions.
- **D-03:** Preserve the repo’s current DNA:
  Phoenix-first,
  Ecto/Postgres-native durable truth,
  host-owned seams,
  one explain-then-act mutation posture,
  one bounded native control plane plus explicit bridge boundary,
  and strong operator/DX coherence.

### Shared Preview Contract
- **D-04:** Keep one canonical durable preview lifecycle across cron, Lifeline, and workflow-directed actions rather than splitting preview models by surface family.
- **D-05:** Generalize the current preview primitive away from repair-only semantics over time so the same operator trust model can cover cron, Lifeline, and workflow-directed actions without naming distortion.
- **D-06:** The canonical preview lifecycle remains:
  `ready`,
  `drifted`,
  `expired`,
  `consumed`.
- **D-07:** Preview storage, drift checks, single-use consume, and audit coupling stay shared and server-authoritative.
- **D-08:** Preview presentation may be risk-shaped, not surface-fragmented:
  cron may stay concise,
  Lifeline may remain richer and receipt-like,
  workflow-directed actions should use workflow-native wording,
  but all three must expose the same underlying contract and lifecycle.
- **D-09:** Do not force every preview into the full Lifeline “danger receipt” shape. That would add noise and friction to routine cron controls without adding real safety.
- **D-10:** Do not preserve page-local preview drift as a long-term design posture. Shared storage with divergent UX contracts would lock in inconsistency and weaken future docs/tests.
- **D-11:** Preview state remains off the URL. URL params may preserve selected resource or audit scope, but not preview tokens or in-progress mutation state.

### Shared Reason Policy
- **D-12:** Reason policy is action-owned, not page-owned.
- **D-13:** Every native preview keeps a visible reason field, even when the reason is optional.
- **D-14:** Shared default requirement levels are:
  - `pause_cron_entry`, `resume_cron_entry`, `run_cron_entry`: optional
  - Lifeline repair actions and workflow-directed operator interventions: required with minimum specificity
- **D-15:** Workflow-directed actions inherit Lifeline-grade requiredness because they are operator interventions, but their labels, hints, and preview wording must remain workflow-native rather than repair-generic.
- **D-16:** Keep the locked Phase 10 rule against filler reasons for low-risk actions. Do not require prose for routine cron controls merely for consistency theater.
- **D-17:** Requiredness and specificity validation must run in shared server-side action code, never only in LiveView.
- **D-18:** Durable audit/event rows store raw reason text as evidence. Rendered “no reason provided” or operator-facing wording remains a presenter concern.
- **D-19:** Prefer a compact shared helper such as `reason_policy_for(action)` or equivalent explicit preview metadata over a broad policy DSL or host-facing mini-framework.

### Shared Refusal Wording Contract
- **D-20:** Keep machine refusal keys stable and testable, but do not use them as the primary operator copy.
- **D-21:** Introduce one shared refusal/readiness normalization seam for outcomes coming from permission checks, preview lifecycle states, reason validation, and workflow rejection evidence.
- **D-22:** Shared refusal copy should follow one shape:
  `outcome -> concise reason -> legal next move -> venue`.
- **D-23:** Distinguish these operator-facing classes clearly:
  permission/read-only denial,
  state-based refusal,
  stale preview (`drifted`, `expired`, `consumed`),
  invalid reason,
  and workflow handoff guidance when the next move is legal but belongs in Lifeline.
- **D-24:** Workflow pages should not lead with raw refusal codes such as backend atoms or transition names. Show a human summary first and keep exact codes as support/debug depth.
- **D-25:** Preview lifecycle wording must differentiate `drifted`, `expired`, and `consumed` explicitly because they imply different next steps.
- **D-26:** `LiveAuth` remains the enforcement seam for page/action authorization and shared error categories, but final operator wording ownership should move toward a shared presenter/read-model seam rather than accreting string maps indefinitely inside `LiveAuth`.
- **D-27:** Do not introduce a full Gettext/i18n or host-owned copy platform in this phase. The goal is one coherent operator language, not a broad text system.

### Shared Audit Follow-Up Contract
- **D-28:** Audit remains a read-only continuity evidence surface, not a mutation venue and not a generic history/search product.
- **D-29:** Model audit as one evidence substrate with two views of the same truth:
  local scoped continuity panels on native pages,
  and `/ops/jobs/audit` as the canonical global destination.
- **D-30:** The same normalized audit event must support both local rendering and global rendering through one shared read-model/presenter seam.
- **D-31:** `resource_type + resource_id` is the primary cross-surface drilldown contract for audit follow-up.
- **D-32:** `incident_fingerprint` stays secondary correlation metadata for Lifeline/workflow continuity stories. It must not replace resource identity as the primary global drilldown key.
- **D-33:** Local pages must keep recent post-action evidence close to the selected resource or incident, but those panels should stay bounded and recent rather than becoming full history feeds.
- **D-34:** `/ops/jobs/audit` should accept explicit preapplied URL filters and serve as the expanded follow-up destination from local pages.
- **D-35:** Canonical audit filter vocabulary should include:
  `resource_type`,
  `resource_id`,
  `event_type`,
  optional `command_key`,
  and optional incident/workflow correlation metadata where warranted.
- **D-36:** Audit filters should be URL-owned and router-backed, not ephemeral assigns only.
- **D-37:** Audit filtering must execute in Ecto queries, not through `list_all |> Enum.filter` style in-memory filtering.
- **D-38:** Operator-facing event labels, resource labels, and follow-up links should come from one shared presenter/read-model seam rather than per-LiveView string assembly.
- **D-39:** Audit follow-up links should prefer Powertools-native destinations when Powertools owns the diagnosis surface, and only hand off to the Oban Web bridge when the next inspection is truly `bridge_only`.
- **D-40:** If the acted-on resource is gone, audit rows must remain readable and explicit rather than emitting blind or broken links.

### Architectural Posture
- **D-41:** Stay idiomatic and boring:
  context functions own durable truth,
  `Ecto.Multi` owns correctness-bearing mutation plus audit boundaries,
  LiveViews stay thin,
  `handle_params` / URL state own durable selection and filter context,
  and presenters/read models own operator copy.
- **D-42:** Do not move operator copy generation down into domain services or runtime semantics modules. Domain layers should emit machine truth and structured facts, not venue-specific UI prose.
- **D-43:** Do not introduce a second audit projection store unless actual query scale proves the normalized audit table insufficient.

### the agent's Discretion
- Exact module and schema names for the generalized preview seam, provided the operator-visible lifecycle and audit coupling remain shared.
- Exact helper names for reason policy and refusal normalization, provided they stay explicit, small, and testable.
- Exact presenter/read-model decomposition across control-plane and audit seams, provided wording ownership and query ownership are not muddled.
- Exact local panel layout and card density, provided active resource continuity stays close to the acted-on surface and global audit remains the canonical expanded destination.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator feel:
  “The same audited mutation trust model applies everywhere, even when the page depth changes.”
- Preferred preview posture:
  one lifecycle and one audit envelope,
  but cron can stay concise while Lifeline remains deeper and workflow actions remain workflow-native.
- Preferred reason posture:
  reasons are always visible,
  required only when the action is a true intervention,
  and never forced for low-risk routine controls just to look uniform.
- Preferred refusal posture:
  human wording first,
  machine code second,
  venue-aware next step always explicit.
- Preferred audit posture:
  the acted-on page shows a bounded continuity slice,
  and the audit page shows the same truth with deeper scoped follow-up.
- Preferred maintainer DX:
  one shared presenter/read-model contract per concern,
  one action-owned reason policy,
  one query-backed audit filter vocabulary,
  and no extra product theater.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 29 scope, plan breakdown, and dependency on the Phase 28 control-plane work.
- `.planning/PROJECT.md` — v1.3 product posture plus the repo-level decision posture for research-backed recommendations and least-surprise operator UX.
- `.planning/REQUIREMENTS.md` — `ACT-01`, `ACT-02`, and `ACT-03`, plus the surrounding native-versus-bridge and support-truth constraints.
- `.planning/STATE.md` — current milestone sequencing.

### Prior locked decisions that constrain this phase
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — one native `preview -> reason -> execute` contract, risk-based reasons, disabled-with-explanation controls, and the native-versus-bridge mutation boundary.
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` — diagnosis-first workflow wording and the rule that legal next action guidance should stay grounded in durable truth.
- `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-CONTEXT.md` — Lifeline as the sole native execution venue for bounded workflow actions and the shared preview-envelope direction.
- `.planning/phases/25-traceability-audit-consistency-repair/25-CONTEXT.md` — additive audit/proof posture, explicit provenance, and maintainer-facing clarity expectations.
- `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` — shared operator vocabulary, venue wording, audit naming contract, and structured resource identity direction.
- `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md` — URL-owned context, native-versus-bridge handoff contract, and continuity-evidence posture.

### Product posture and research prompts
- `prompts/oban_powertools_context.md` — product posture, personas, domain language, and operator expectations.
- `prompts/oban-powertools-deep-research-original-prompt.md` — one-shot recommendation posture, ecosystem lessons emphasis, DX expectations, and maintainer intent.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid shell-plus-bridge strategy, support-truth posture, and operator-console UX guidance.

### Current implementation surfaces
- `lib/oban_powertools/web/cron_live.ex` — current concise preview/reason/audit mutation surface for cron.
- `lib/oban_powertools/cron.ex` — cron preview generation and action execution path.
- `lib/oban_powertools/web/lifeline_live.ex` — current richer preview/reason/audit execution venue and local history posture.
- `lib/oban_powertools/lifeline.ex` — durable preview/execute path and reason validation for higher-trust actions.
- `lib/oban_powertools/web/workflows_live.ex` — workflow diagnosis surface, refusal display, and Lifeline handoff language.
- `lib/oban_powertools/workflow/runtime.ex` — workflow command legality, refusal evidence, and durable operator reason storage.
- `lib/oban_powertools/web/live_auth.ex` — shared auth, permission, preview-error, and audit-consequence vocabulary.
- `lib/oban_powertools/web/control_plane_presenter.ex` — shared status, ownership, and audit label presentation seam to extend rather than bypass.
- `lib/oban_powertools/audit.ex` — normalized audit storage contract and current reader helpers.
- `lib/oban_powertools/web/audit_live.ex` — current raw-ish audit destination and filter behavior to normalize.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repo already has one durable preview envelope and one `preview -> reason -> execute` posture; the main gap is naming, presentation depth, and cross-surface consistency rather than missing primitives.
- `LiveAuth` already centralizes permission/refusal categories, making it the natural enforcement seam even if final wording ownership moves outward into presenters.
- `ControlPlanePresenter` already owns shared status and ownership copy, making it the natural home for shared refusal/audit presentation growth.
- `Audit` already stores `event_type`, `command_key`, `resource_type`, and `resource_id`, so Phase 29 should improve the read side rather than rethinking storage from scratch.
- `WorkflowsLive` plus `LifelineLive` already prove the venue-aware handoff model this phase should refine rather than replace.

### Established Patterns
- The repo prefers context-owned durable truth with thin LiveViews layered on top.
- Native surfaces are expected to explain first and act through bounded audited flows.
- URL state is for durable selection/filter context, not mutation internals.
- Operator-facing wording is converging toward one control-plane vocabulary rather than surface-local jargon.

### Integration Points
- Phase 29 should produce shared seams that Phase 30 can reuse when harmonizing limiters, workflows, Lifeline, and cron around one mental model.
- The audit filter and resource-link contract decided here should feed directly into later docs/proof work in Phase 31.
- The generalized preview, reason-policy, and refusal seams should reduce future copy drift across any new bounded native action entrypoint without creating a second policy system.

</code_context>

<deferred>
## Deferred Ideas

- Full native generic job/queue mutation surfaces or a broader dashboard rewrite.
- A broad host-facing copy/i18n DSL or product-wide localization platform.
- A separate event projection/history subsystem for audit beyond the normalized table plus query-backed read models.
- Free-text audit search, analytics-style history reporting, or a generalized chronology product.
- Any second native execution venue for workflow actions outside Lifeline.

</deferred>

---

*Phase: 29-shared-preview-reason-refusal-audit-contract*
*Context gathered: 2026-05-25*
