# Phase 30: Surface Cohesion Across Limiters, Workflows, Lifeline & Cron - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Align the native pages around one shared diagnosis and next-action mental model.

This phase owns:
- limiter posture cohesion inside the shared control-plane contract
- one shared opening-story contract across workflow, Lifeline, and cron detail surfaces
- tighter router-backed continuity so audit and bridge follow-up remain obvious after refresh, remount, and read-only access
- cross-surface copy and follow-up rules that make the native pages feel like one product

This phase does not:
- add new mutation families or a generic queue/job dashboard rewrite
- make limiters a native mutation surface
- serialize preview, reason, or other mutation internals into the URL
- blur the native Powertools surfaces with the Oban Web bridge

</domain>

<decisions>
## Implementation Decisions

### Project-Level Defaults To Carry Forward
- **D-01:** For this repo, discuss-phase and downstream agents must research repo-local artifacts, nearby phase context, relevant prompts, and adjacent implementation surfaces before asking the user to resolve a gray area.
- **D-02:** Prefer one-shot, research-backed recommendations over interactive option shopping. Narrow aggressively unless multiple options remain genuinely viable after local research.
- **D-03:** Do not escalate choices that can be settled by existing repo decisions, Phoenix/LiveView/Ecto/Postgres norms, ecosystem best practice, or direct inspection of the current implementation.
- **D-04:** Only ask the user about forks that materially change public product semantics, support truth, architectural boundaries, operator trust, or long-term maintainer burden.
- **D-05:** Treat prior `CONTEXT.md` decisions as locked defaults. Reopen them only when the current phase would otherwise create a real contract conflict.
- **D-06:** When escalation is necessary, present a recommended path first and ask the narrowest possible question rather than a broad design interview.

### Shared Control-Plane Opening Story
- **D-07:** Workflow, Lifeline, cron, and limiter detail surfaces should converge on one shared opening stack:
  `status badge -> diagnosis sentence -> next action -> venue -> evidence`.
- **D-08:** The shared operator status remains the compact scan layer only. It must not be the first full explanatory sentence on detail views.
- **D-09:** The first sentence on each selected resource must answer “what is happening and why?” in control-plane language derived from durable facts rather than page-local prose.
- **D-10:** Shared presenter and read-model seams own this opening story. Do not hand-author the resource-opening sentence independently in each LiveView.
- **D-11:** Cross-surface tests should assert opening-story order and continuity language, not only the existence of preview/reason/audit copy.

### Limiter Posture Cohesion
- **D-12:** Limiters remain a **Powertools-native diagnosis surface**, not a native mutation venue.
- **D-13:** The limiter page should adopt the shared control-plane reading order:
  `operator status -> diagnosis -> legal next action -> venue -> evidence`.
- **D-14:** `Live Now` and `Snapshot at Block Start` remain, but as supporting evidence beneath the diagnosis layer rather than as the page’s primary mental model.
- **D-15:** The limiter list CTA should be framed as review/open diagnosis, not as an `Action`; do not imply audited mutation where none exists.
- **D-16:** Limiters continue mapping into `blocked`, `waiting`, and `runnable`. Do not force `needs_review` onto ordinary saturation/cooldown states unless a distinct operator-intervention contract is introduced later.
- **D-17:** Limiter next-action guidance may legitimately stay read-only, such as review native diagnosis, inspect the blocked job in the Oban Web bridge, or wait for cooldown. It does not need to be executable on the current page.
- **D-18:** Venue must stay explicit whenever the next useful inspection leaves the native limiter page, especially for generic job drilldowns into the Oban Web bridge.

### Workflow, Lifeline, and Cron Wording Cohesion
- **D-19:** Workflow keeps its diagnosis-first posture, but cron and Lifeline must be brought up to the same opening-story contract rather than pulling workflow back toward status-first wording.
- **D-20:** Lifeline must stop leading selected-resource detail with health/detection/repair framing alone; those remain supporting evidence after the diagnosis sentence.
- **D-21:** Cron must stop leading selected-resource detail with operator status alone; paused/ready/run-now semantics should be expressed first as diagnosis copy, with status retained as the badge.
- **D-22:** Legal next move and venue should follow immediately after diagnosis whenever the operator may otherwise confuse “what should happen next” with “what can be done on this page right now.”
- **D-23:** Keep machine-facing status, refusal codes, and raw state visible as support/debug depth, but secondary to the shared operator story.

### Router-Backed Continuity and Follow-Up
- **D-24:** URL and router params own durable continuity selectors, not just bare selection, when a destination needs more than one stable key to reopen the same follow-up slice.
- **D-25:** Allowed continuity params are stable identifiers and scoped view/filter keys such as `resource`, `entry`, `id`, `step`, `view`, `row-id`, `incident_fingerprint`, `workflow_id`, `action`, `resource_type`, `resource_id`, `event_type`, and later `command_key` where warranted.
- **D-26:** Rendered diagnosis, refusal, venue, next-step copy, audit prose, reason text, preview token, preview lifecycle state, and any other mutation internals stay off the URL.
- **D-27:** Cross-surface navigation must reconstruct operator framing from the destination read model using router-backed selectors, not by trusting source-surface prose serialized into params.
- **D-28:** Refresh, remount, reconnect, and read-only access should reopen the same scoped continuity slice where the destination supports it, but must always show current durable truth rather than a frozen historical narrative.
- **D-29:** Audit continuity is canonicalized through URL-backed filters on `/ops/jobs/audit`; local pages should deep-link into those scoped filters rather than inventing separate history-state schemes.
- **D-30:** Bridge continuity should remain venue-honest: params may preserve the inspection target, but must not make bridge pages appear equivalent to Powertools-native diagnosis or audited-action surfaces.
- **D-31:** The canonical selection contract for limiters remains `resource=` in the URL; no preview or mutation state belongs on that page.

### Ecosystem-Learned Guardrails
- **D-32:** Keep generic inspection and product-specific diagnosis separate. The native Powertools shell should own Powertools-specific explanation and bounded action posture, while generic queue/job inspection remains an explicit bridge responsibility.
- **D-33:** Dangerous or policy-bearing actions should remain explicit, preview-first where applicable, and audit-backed rather than hidden behind ambiguous single-click shortcuts or overloaded drilldown links.
- **D-34:** URL-backed drilldowns and query-backed scoped filters are the preferred continuity model for operator surfaces; avoid ephemeral local-only state for durable follow-up flows.
- **D-35:** Avoid turning the control plane into a generic dashboard theater layer. Cohesion should come from shared language and follow-up rules, not from flattening every surface into the same chrome regardless of domain.

### the agent's Discretion
- Exact module, component, and helper names for any shared opening-story presenter or read-model seam, provided wording ownership stays centralized and testable.
- Exact badge/component layout and spacing, provided the shared opening stack and venue honesty remain intact.
- Exact continuity-param helper structure, provided params stay stable, documented, and limited to durable selectors.
- Exact evidence-card density and wording polish, provided diagnosis remains the first sentence and evidence stays grounded in durable truth.

</decisions>

<specifics>
## Specific Ideas

- Preferred operator feel:
  “Every native page should open with the same mental model: what is happening, why, what I should do next, and where that happens.”
- Preferred limiter feel:
  a diagnosis surface that still preserves the strong `Live Now` versus `Snapshot at Block Start` evidence comparison, but no longer feels like a one-off page outside the control plane.
- Preferred continuity posture:
  bookmarkable and refresh-safe through durable selectors and scoped filters,
  but never by leaking mutation internals or freezing stale prose into the URL.
- Preferred bridge posture:
  explicit and honest generic inspection handoff,
  not fake native parity.
- Ecosystem lesson to preserve:
  the best operator consoles separate generic inspection from product-owned diagnosis, keep dangerous actions explicit and auditable, and make drilldowns/restoration URL-safe rather than ephemeral.
- Anti-patterns to avoid:
  page-local opening prose drift,
  `Action` labels on read-only diagnosis pages,
  shareable URLs that embed preview or refusal internals,
  and generic-dashboard flattening that hides why a page exists.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 30 scope, plan breakdown, and dependency on the Phase 29 control-plane contract.
- `.planning/PROJECT.md` — v1.3 product posture plus the repo-level research-first decision posture for downstream agents.
- `.planning/REQUIREMENTS.md` — `CTL-02`, `OVR-03`, `ACT-02`, and `ACT-03`, plus the surrounding native-versus-bridge and support-truth constraints.
- `.planning/STATE.md` — current milestone sequencing.

### Prior locked decisions that constrain this phase
- `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md` — diagnosis-first workflow posture, narrative-plus-evidence layering, and URL-backed detail expectations.
- `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-CONTEXT.md` — Lifeline as the trusted native execution venue and venue-aware next-step guidance.
- `.planning/phases/27-control-plane-vocabulary-status-taxonomy-ownership-contract/27-CONTEXT.md` — shared status taxonomy, ownership model, layered wording contract, and bridge-only meaning.
- `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md` — diagnosis-first overview, native handoff model, and URL-owned continuity posture.
- `.planning/phases/29-shared-preview-reason-refusal-audit-contract/29-CONTEXT.md` — shared preview/reason/refusal contract, audit follow-up model, and rule that mutation internals stay off the URL.
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md` — read-only, preview, reason, and audit trust posture across native surfaces.

### Product posture and research prompts
- `prompts/oban_powertools_context.md` — product posture, domain language, and repo-level research/decision posture for future GSD work.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid shell-plus-bridge strategy and why native Powertools pages should own Powertools-specific explanation.
- `prompts/oban-powertools-deep-research-original-prompt.md` — lessons-learned posture, batteries-included goals, DX emphasis, and the user’s preference for coherent one-shot recommendations.

### Current implementation surfaces
- `lib/oban_powertools/control_plane.ex` — shared machine-facing status taxonomy across native surfaces.
- `lib/oban_powertools/web/control_plane_presenter.ex` — shared status labels, ownership badges, venue wording, and audit follow-up paths to extend rather than bypass.
- `lib/oban_powertools/web/engine_overview_live.ex` — current overview handoff shape that Phase 30 should keep compatible with.
- `lib/oban_powertools/web/overview_read_model.ex` — current bucket, exemplar, and handoff read model whose continuity decisions should stay aligned with the phase outcome.
- `lib/oban_powertools/web/limiters_live.ex` — current limiter posture and URL-backed selection contract to reframe.
- `lib/oban_powertools/web/cron_live.ex` — current status-first detail posture and preview/audit surface to align with the shared opening-story contract.
- `lib/oban_powertools/web/workflows_live.ex` — strongest existing diagnosis-first native surface and Lifeline handoff pattern to preserve.
- `lib/oban_powertools/web/lifeline_live.ex` — native review and execution venue whose selected-resource framing and continuity selectors must be aligned to the shared control-plane story.
- `lib/oban_powertools/web/audit_live.ex` — canonical read-only audit destination and scoped filter surface.
- `lib/oban_powertools/web/router.ex` — route ownership and native-versus-bridge mount contract.
- `lib/oban_powertools/web/live_auth.ex` — shared read-only, permission, and audit-consequence vocabulary.
- `lib/oban_powertools/web/oban_web_bridge.ex` — bridge adapter and inspection-only seam.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.ControlPlane` already freezes the shared machine-facing taxonomy, so Phase 30 should apply it more coherently rather than inventing new statuses.
- `ObanPowertools.Web.ControlPlanePresenter` already owns shared operator labels, venue wording, and audit follow-up paths; it is the natural home for a shared opening-story seam.
- `WorkflowsLive` already demonstrates the strongest diagnosis-first surface and a clear native-to-Lifeline handoff pattern.
- `LifelineLive` already demonstrates richer continuity selectors and URL-backed destination state.
- `AuditLive` already proves the query-backed scoped filter model that should remain canonical for cross-surface audit follow-up.

### Established Patterns
- The repo prefers thin LiveViews with presenter/read-model-owned wording instead of scattered HEEx prose.
- URL state is already used for durable selection and filters, not for transient mutation internals.
- Native Powertools pages are explain-first and venue-aware, while the bridge is intentionally narrower and inspection-only.
- The milestone’s cohesion work is additive: align existing surfaces and language instead of broadening scope into a new dashboard family.

### Integration Points
- Phase 30 should extend the Phase 28 overview read model and Phase 29 follow-up contract rather than create a competing continuity model.
- Any new shared opening-story helpers should become reusable across limiters, cron, workflows, Lifeline, and audit-linked follow-up surfaces.
- Test updates should likely touch the existing cross-surface copy coherence lane plus surface-specific LiveView tests for remount and URL-state continuity.

</code_context>

<deferred>
## Deferred Ideas

- Full native replacement of generic Oban Web job or queue inspection.
- New limiter mutation or repair controls.
- Persisting rendered diagnosis, refusal, or preview wording into shareable URLs.
- A broader operator inbox, analytics, or reporting dashboard beyond the current control-plane cohesion scope.

</deferred>

---

*Phase: 30-surface-cohesion-across-limiters-workflows-lifeline-cron*
*Context gathered: 2026-05-25*
