# Phase 28: Diagnosis-First Overview & Context-Preserving Drilldowns - Research

**Researched:** 2026-05-25
**Domain:** Phoenix LiveView overview triage, cross-surface drilldowns, URL-owned selection state, and native-versus-bridge operator continuity
**Confidence:** HIGH [VERIFIED: repo-local source review, test inventory, local runtime check, Phoenix LiveView docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied verbatim from `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md`. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]

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
- **D-21:** Bridge-only handoffs must be explained **before** click, not only after navigation.
- **D-22:** The overview should use compact explicitness for bridge-only items:
  a short ownership label such as `Oban Web bridge`
  plus a posture cue such as `Inspection only` or equivalent read-only wording.
- **D-23:** Do not visually or semantically present bridge destinations as if they were just another native Powertools page with equal mutation semantics.
- **D-24:** Repeat the fuller native-versus-bridge explanation once on the destination, but keep overview-level bridge copy terse enough that it remains scannable.
- **D-25:** `bridge_only` remains an ownership and venue signal, not a failure severity or degraded-health status.
- **D-26:** Keep a resolved-recently signal on the overview, but make it secondary to active attention.
- **D-27:** Resolved-recently content exists to build operator trust and continuity, not to compete with active triage.
- **D-28:** The resolved signal must state an explicit window and honest source. Avoid soft wording such as bare `Resolved Recently` if the underlying data is actually archived repair actions rather than unique resolved incidents.
- **D-29:** The resolved signal should deep-link into resolved Lifeline or audit/archive destinations where the durable evidence lives.
- **D-30:** Do not give resolved items equal visual urgency with `Needs Review` or other active attention buckets.
- **D-31:** Phase 28 should add one shared overview read-model or presenter seam rather than composing bucket math, exemplar selection, and next-step copy ad hoc inside HEEx.
- **D-32:** Bucket counts, diagnosis sentences, exemplar evidence, venue labels, and next-step guidance must all come from one coherent read-model contract so the overview cannot drift internally.
- **D-33:** Exemplar selection should prefer durable, user-meaningful priority rules over recency theater. Favor items that best explain why the bucket matters now.
- **D-34:** Keep overview queries bounded and cheap enough for LiveView refresh. Do not over-fetch full drilldown state just to render card exemplars.
- **D-35:** Severity may influence ordering inside a bucket, but it must remain secondary to shared operator status rather than replacing it.

### Claude's Discretion
Copied verbatim from `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md`. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]

- Exact module and struct names for the shared overview read-model/presenter seam, provided the selection, diagnosis, venue, and evidence contract stays explicit and reusable.
- Exact card layout, spacing, and component decomposition, provided active triage stays primary and bridge/native ownership remains unmistakable.
- Exact exemplar count per card, provided it stays tightly bounded and support-truthful.
- Exact resolved-history window and label wording, provided the source semantics are honest and the signal remains visually secondary.

### Deferred Ideas (OUT OF SCOPE)
Copied verbatim from `.planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md`. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]

- Turning `/ops/jobs` into a full table-first operator inbox or generic queue dashboard.
- Executing preview/reason/audit actions directly from overview cards.
- Native replacement of the generic Oban Web jobs and queues inspection experience.
- Rich historical analytics, trend dashboards, or shift-handoff reporting on the overview surface.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement descriptions are copied from `.planning/REQUIREMENTS.md`. [CITED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| OVR-01 | `/ops/jobs` becomes the operator’s real starting point by surfacing durable attention buckets and next steps instead of mostly raw feature counts. | Use one overview read model that emits bucket count, diagnosis sentence, bounded exemplars, venue label, and next-step CTA per bucket. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] [CITED: lib/oban_powertools/web/engine_overview_live.ex] |
| OVR-02 | Operators can move from overview to the right native page or Oban Web destination without losing the context that explained why attention was required. | Reuse existing router-backed LiveView navigation, keep exact selection only on native pages that own it, and never invent unsupported bridge deep links. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: lib/oban_powertools/web/router.ex] [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex] |
| OVR-03 | Native pages converge on one shared drill-down mental model so selected resource, diagnosis, and follow-up action state survive refresh, remount, and read-only access coherently. | Standardize page params around durable selectors only, patch URL on in-page selection changes, and keep preview/reason state out of params. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: lib/oban_powertools/web/live_auth.ex] |
</phase_requirements>

## Summary

Phase 28 is a read-model-and-navigation phase, not a new capability phase. The repo already has the right product boundaries after Phase 27: the native `/ops/jobs` shell owns diagnosis and audited action entry, while `/ops/jobs/oban` stays a read-only Oban Web bridge. The missing piece is that the overview still renders as six metric cards plus static venue links, so it cannot yet explain what needs attention, why it matters, or how to land on the right destination with context intact. [CITED: lib/oban_powertools/web/engine_overview_live.ex] [CITED: lib/oban_powertools/web/router.ex] [CITED: lib/oban_powertools/web/oban_web_bridge.ex]

The repo already proves two useful continuity patterns. `WorkflowsLive` is the strongest existing exemplar: it is router-mounted, derives detail state from params in `handle_params/3`, and uses `patch` links for step-level drilldown inside the same LiveView. `LifelineLive` can restore selection from URL params, including workflow-directed handoffs, but most operator clicks still mutate assigns without patching the URL, so ad hoc in-page selection is not yet refresh-safe. `LimitersLive` has no param contract at all, so selection is lost on remount today. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: lib/oban_powertools/web/limiters_live.ex] [CITED: test/oban_powertools/web/live/workflows_live_test.exs] [CITED: test/oban_powertools/web/live/lifeline_live_test.exs]

The safest plan split is:
1. replace overview-local counting with one bounded overview read model and a new overview proof lane;
2. make native drilldowns URL-owned where they are not already, especially Lifeline click/toggle flows and limiter selection;
3. prove bridge labeling, read-only continuity, and remount behavior without widening the bridge into a native queue UI. [VERIFIED: repo-local source review] [CITED: .planning/ROADMAP.md] [CITED: .planning/REQUIREMENTS.md]

**Primary recommendation:** implement one repo-local overview read model that emits triage buckets plus bounded exemplars, then standardize native drilldowns on durable query/path params using `navigate` across LiveViews and `patch` inside a LiveView, with bridge destinations staying explicitly labeled `Oban Web bridge` and `Inspection only`. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: lib/oban_powertools/web/control_plane_presenter.ex]

## Repo Reality

- `EngineOverviewLive` currently mounts successfully under `:view_overview`, queries raw counts for resources, blocked explain rows, paused cron entries, workflows, incidents, pending previews, and archived repairs, and renders those values as six metric cards plus six unscoped links. It does not currently render exemplar evidence, diagnosis sentences, or param-preserving destination links. [CITED: lib/oban_powertools/web/engine_overview_live.ex]
- `WorkflowsLive` already uses `handle_params/3` with router `:id` and query `step`, chooses a selected step deterministically, and uses `patch={selected_step_path(...)}` for in-view drilldown. That is the canonical Phase 28 model for native detail continuity. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
- `LifelineLive` already accepts durable selection params such as `view`, `row-id`, `incident_fingerprint`, `workflow_id`, `step`, and `action`, and the workflow handoff from `WorkflowsLive` is already URL-based. However, `select_incident` and `toggle_view` still call `load_data/2` directly instead of patching the URL, so manual in-page selection is not preserved by refresh/remount unless the user arrived through an already-parameterized URL. [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: test/oban_powertools/web/live/lifeline_live_test.exs]
- `LimitersLive` still uses only `phx-click="inspect"` and socket assigns for `selected_resource` and `detail`. It has no `handle_params/3`, no query param contract, and no remount continuity. Phase 28 has to add that if limiter drilldowns are part of overview handoffs. [CITED: lib/oban_powertools/web/limiters_live.ex]
- There is no existing `engine_overview_live_test.exs` in `test/oban_powertools/web/live/`, so the starting page for OVR-01 and OVR-02 currently has no dedicated LiveView proof lane. [VERIFIED: rg --files test/oban_powertools/web/live]
- The current test harness is already correct for this phase: `ObanPowertools.LiveCase` imports `Phoenix.LiveViewTest`, uses the sandboxed `TestRepo`, and the existing web tests already exercise direct LiveView mounts and parameterized paths. Phase 28 should extend that harness rather than adding browser automation. [CITED: test/support/live_case.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Overview bucket aggregation and exemplar selection | API / Backend read model inside the LiveView process | Browser / Client render only | The durable truth lives in repo queries and presenter logic, not in client-side derivation. The browser should only render already-computed triage data. [CITED: lib/oban_powertools/web/engine_overview_live.ex] [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] |
| Bucket labels, venue labels, and ownership wording | API / Backend presenter seam | Browser / Client display only | Phase 27 already centralized status and ownership copy in `ControlPlanePresenter`; Phase 28 should extend that seam, not move semantics into HEEx literals. [CITED: lib/oban_powertools/web/control_plane_presenter.ex] |
| Cross-LiveView handoff routing | Frontend Server (router-mounted LiveViews) | Browser / Client link activation | The router-mounted LiveViews own path/query params and `handle_params/3`; links only trigger those transitions. [CITED: lib/oban_powertools/web/router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3] |
| In-page selection continuity | Frontend Server (current LiveView) | Browser / Client pushState | `patch` and `push_patch` are the correct tier for changing params without remounting the LiveView. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: lib/oban_powertools/web/workflows_live.ex] |
| Bridge follow-up | Oban Web bridge surface | Native overview label/copy | Powertools owns the label and handoff honesty, but the bridge remains the actual inspection venue. [CITED: lib/oban_powertools/web/oban_web_bridge.ex] [CITED: lib/oban_powertools/web/router.ex] |
| Read-only posture and action disablement | Frontend Server auth seam | Browser / Client button state | `LiveAuth` already owns page/action authorization messages; selected context should survive read-only access while mutation controls stay disabled. [CITED: lib/oban_powertools/web/live_auth.ex] |

## Standard Stack

No new external dependency is required for Phase 28. The existing Phoenix LiveView stack and repo-local control-plane seams are sufficient. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

### Core

| Library / Artifact | Version | Purpose | Why Standard |
|--------------------|---------|---------|--------------|
| Phoenix | 1.8.7 | router-mounted LiveViews and route ownership | Already provides the mounted `/ops/jobs` shell contract used by every destination in scope. [VERIFIED: mix.lock] [CITED: lib/oban_powertools/web/router.ex] |
| Phoenix LiveView | 1.1.30 | `handle_params/3`, `patch`, `navigate`, and LiveView state continuity | Official docs explicitly define `patch` for current-LiveView param updates and `navigate` for cross-LiveView transitions, which matches the Phase 28 handoff model. [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3] |
| Ecto SQL | 3.13.5 | bounded bucket queries and exemplar selection | Phase 28 needs cheap, deterministic read-model queries, not client-side aggregation. [VERIFIED: mix.lock] [CITED: lib/oban_powertools/web/engine_overview_live.ex] |
| `ObanPowertools.ControlPlane` | repo-local | shared operator status mapping | Phase 27 already froze the shared status taxonomy here; the overview read model should consume it rather than re-encode statuses. [CITED: lib/oban_powertools/control_plane.ex] |
| `ObanPowertools.Web.ControlPlanePresenter` | repo-local | shared status, ownership, venue, and audit labels | The overview and destination pages should share one wording seam. [CITED: lib/oban_powertools/web/control_plane_presenter.ex] |
| `ObanPowertools.Web.LiveAuth` | repo-local | read-only, permission, and audit-consequence copy | Read-only continuity in Phase 28 must preserve selection while keeping mutation posture honest. [CITED: lib/oban_powertools/web/live_auth.ex] |

### Supporting

| Library / Artifact | Version | Purpose | When to Use |
|--------------------|---------|---------|-------------|
| Oban Web | 2.12.4 | bridge destination for generic job and queue inspection | Use only when follow-up is explicitly bridge-owned or generic-job-oriented. [VERIFIED: mix.lock] [CITED: lib/oban_powertools/web/oban_web_bridge.ex] |
| `ObanPowertools.Explain` | repo-local | diagnosis-rich limiter and workflow evidence | Reuse existing explanation output when selecting bounded exemplars and diagnosis sentences. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/limiters_live.ex] |
| `Phoenix.LiveViewTest` via `ObanPowertools.LiveCase` | repo-local | hermetic proof of overview, handoff, and remount behavior | Existing web tests already use this stack; Phase 28 should add new coverage here. [CITED: test/support/live_case.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| repo-local LiveView tests | browser automation or screenshot testing | Unnecessary here because the phase is about routing, assigns, and rendered HTML continuity already well-covered by `Phoenix.LiveViewTest`. [CITED: test/support/live_case.ex] |
| URL-owned durable selectors | client-only JS state or local storage | That would not survive remount or server-side authorization changes as cleanly, and it would break the router-owned LiveView model already used by workflows. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| native bridge parity | a broader native jobs/queues rebuild | Explicitly out of scope for v1.3 and contradicts the locked bridge-only posture. [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] |

## Recommended Execution Split

### Plan 28-01: Overview Read Model And Triage Cards

- Add one repo-local overview read model or presenter seam that returns bucket structs with `status`, `count`, `diagnosis`, `ownership`, `venue`, `next_step`, and `exemplars`. Keep the query set bounded and cheap. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] [CITED: lib/oban_powertools/web/engine_overview_live.ex]
- Replace the current count-heavy card wall in `EngineOverviewLive` with triage cards ordered by active urgency first, then a quieter resolved continuity block. [CITED: lib/oban_powertools/web/engine_overview_live.ex] [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-UI-SPEC.md]
- Create `test/oban_powertools/web/live/engine_overview_live_test.exs` as the canonical OVR-01 proof file. It should assert bucket labels, diagnosis text, exemplar rendering, and venue-aware CTA text. [VERIFIED: rg --files test/oban_powertools/web/live] [CITED: .planning/REQUIREMENTS.md]

### Plan 28-02: Context-Preserving Native And Bridge Handoffs

- Keep `WorkflowsLive` as the canonical native pattern and add a matching param contract to `LimitersLive`, preferably `?resource=<limiter_name>`. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/limiters_live.ex]
- Update `LifelineLive` so row selection and view changes patch the URL instead of mutating socket state only. Preserve the existing `workflow_id`/`step`/`action` handoff contract and add stable `view`, `row-id`, and `incident_fingerprint` patch behavior for in-page clicks. [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
- Generate overview CTAs from durable destination params only. Use exact native selection when the destination owns the read model; otherwise land on the honest bridge venue without fake param semantics. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] [CITED: lib/oban_powertools/web/oban_web_bridge.ex]

### Plan 28-03: Read-Only, Bridge, And Remount Proof

- Extend web tests so the same selected diagnosis context survives refresh/remount for workflows, Lifeline, and limiters, including read-only sessions. [CITED: test/oban_powertools/web/live/workflows_live_test.exs] [CITED: test/oban_powertools/web/live/lifeline_live_test.exs] [CITED: test/oban_powertools/web/live/limiters_live_test.exs]
- Add overview tests that assert bridge-only cards show `Oban Web bridge` and `Inspection only` before click, not only after navigation. [CITED: lib/oban_powertools/web/control_plane_presenter.ex] [CITED: lib/oban_powertools/web/oban_web_bridge.ex]
- Keep router proof limited to existing native and bridge ownership guarantees. Phase 28 should not widen route scope or add a generic native jobs UI. [CITED: test/oban_powertools/web/router_test.exs] [CITED: .planning/REQUIREMENTS.md]

## Architecture Patterns

### System Architecture Diagram

```text
Operator opens /ops/jobs
  -> EngineOverviewLive mount
  -> Overview read model queries bounded durable truth
  -> Buckets emitted:
     status + diagnosis + exemplars + venue + next step
  -> Operator chooses a card CTA
     -> native destination?
        -> navigate to router-owned LiveView with durable params
        -> destination handle_params/3 selects focused resource
        -> in-page selection changes patch URL only
     -> bridge destination?
        -> open Oban Web bridge with explicit "Inspection only" posture
  -> refresh / remount / read-only revisit
     -> params reloaded
     -> selected diagnosis restored
     -> mutation controls still gated by LiveAuth
```

### Recommended Project Structure

```text
lib/oban_powertools/web/
├── engine_overview_live.ex          # overview rendering
├── overview_read_model.ex           # new bounded bucket/query seam
├── control_plane_presenter.ex       # shared labels, venue copy, bridge posture
├── lifeline_live.ex                 # patchable selected-row continuity
└── limiters_live.ex                 # new param-backed limiter selection

test/oban_powertools/web/live/
├── engine_overview_live_test.exs    # new overview proof lane
├── lifeline_live_test.exs           # extend param/remount/read-only coverage
└── limiters_live_test.exs           # extend param/remount coverage
```

### Pattern 1: Overview Read Model, Not HEEx Math

**What:** compute bucket counts, exemplar rows, diagnosis copy, and destination metadata in one read-model seam rather than mixing queries and string building into the template. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]

**When to use:** for every overview card and any follow-up section such as resolved continuity. [CITED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: repo-local pattern + Phoenix LiveView docs
def handle_params(_params, _uri, socket) do
  {:noreply, assign(socket, :buckets, OverviewReadModel.build(repo()))}
end
```

[CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3] [ASSUMED]

### Pattern 2: Durable URL Params For Selection, Socket Assigns For Preview State

**What:** keep selected resource, selected step, selected view, and stable review context in params; keep preview tokens, reason inputs, and action-execution internals in assigns only. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]

**When to use:** for workflow steps, limiter focus, Lifeline row/view state, and any overview link that promises exact drilldown continuity. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/lifeline_live.ex]

**Example:**

```elixir
# Source: Phoenix LiveView live navigation docs
<.link patch={selected_step_path(@workflow.id, step.step_name)}>Detail</.link>
```

[CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

### Pattern 3: Explicit Bridge Ownership Before Navigation

**What:** render bridge-only cards and exemplar rows with venue labels before click and keep destination copy terse but unmistakable. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]

**When to use:** any overview bucket or exemplar whose next inspection lives only in Oban Web. [CITED: lib/oban_powertools/web/oban_web_bridge.ex]

### Anti-Patterns to Avoid

- Building the overview from six unrelated ad hoc queries and six hard-coded link labels. That is the current drift Phase 28 exists to replace. [CITED: lib/oban_powertools/web/engine_overview_live.ex]
- Encoding preview tokens, reason text, or execute-ready mutation state in query params. The locked phase scope forbids ephemeral execution state in the URL. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]
- Treating bridge destinations like native audited-action pages by reusing the same visual emphasis or copy. [CITED: lib/oban_powertools/web/control_plane_presenter.ex] [CITED: lib/oban_powertools/web/oban_web_bridge.ex]
- Adding an overview-level jobs table or native queue browser to “solve” missing drilldown context. That widens scope into explicitly deferred work. [CITED: .planning/REQUIREMENTS.md]

## Concrete Implementation Guidance

### Bounded Exemplars

- Emit `1..3` exemplars per active bucket and keep them deterministic by bucket-specific ordering, not generic recency. `Lifeline` rows should sort by severity then recency, workflow exemplars should prefer blocked or refused stories, and limiter exemplars should prefer currently blocked or cooling-down resources with snapshot evidence. [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: lib/oban_powertools/web/limiters_live.ex] [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]
- Exemplar payload should stay minimal: durable subject label, one supporting fact, venue label, and destination params. Do not preload full detail panes or preview state just to render the overview. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]
- Resolved continuity should use an explicit source label such as archived repairs or resolved incidents, plus a visible window. Avoid pretending the bucket is a general historical feed. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] [CITED: lib/oban_powertools/web/lifeline_live.ex] [CITED: lib/oban_powertools/web/audit_live.ex]

### URL-Owned Selection State

- Keep the existing workflow contract unchanged: `/ops/jobs/workflows/:id?step=<step_name>`. It already satisfies the durable-selector rule and already survives refresh. [CITED: lib/oban_powertools/web/workflows_live.ex] [CITED: test/oban_powertools/web/live/workflows_live_test.exs]
- Add a limiter contract: `/ops/jobs/limiters?resource=<resource_name>`. Implement `handle_params/3`, resolve the selected resource from params, and patch that param on click. [CITED: lib/oban_powertools/web/limiters_live.ex] [ASSUMED]
- Normalize Lifeline around `/ops/jobs/lifeline?view=<active|resolved>&row-id=<stable_row_id>` for direct row selection, keeping `incident_fingerprint` as the fallback for resolved continuity and preserving the existing workflow handoff params for action-directed entry. [CITED: lib/oban_powertools/web/lifeline_live.ex]
- Use `navigate` when moving from overview to a different LiveView and `patch` when changing selection inside a LiveView. That distinction is the official Phoenix LiveView model and matches the current workflow implementation. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: lib/oban_powertools/web/workflows_live.ex]

### Bridge-Only Labels

- Render bridge-owned cards with both the ownership badge and posture cue: `Oban Web bridge` plus `Inspection only`. Reuse `ControlPlanePresenter` for both labels so overview and destinations cannot drift. [CITED: lib/oban_powertools/web/control_plane_presenter.ex]
- Keep bridge CTA styling visually secondary to native audited-action guidance. The bridge is a venue change, not the primary mutation surface. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-UI-SPEC.md] [CITED: lib/oban_powertools/web/oban_web_bridge.ex]
- Do not invent unsupported bridge query contracts. Use stable bridge paths already in local code, such as job detail links, unless official bridge filtering behavior is explicitly verified later. [CITED: lib/oban_powertools/web/engine_overview_live.ex] [CITED: lib/oban_powertools/web/limiters_live.ex] [ASSUMED]

### Refresh / Remount / Read-Only Continuity

- Every selection that the UI promises to preserve must round-trip through params and `handle_params/3`. If a click only mutates assigns, it is not Phase-28-grade continuity. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3] [CITED: lib/oban_powertools/web/lifeline_live.ex]
- Read-only sessions must preserve the same selected row or detail context as writable sessions, but keep action buttons disabled and reuse the existing `LiveAuth` banners and disabled-copy contract. [CITED: lib/oban_powertools/web/live_auth.ex] [CITED: test/oban_powertools/web/live/cron_live_test.exs] [CITED: test/oban_powertools/web/live/lifeline_live_test.exs]
- Refresh/remount continuity must be proven separately from in-session patch continuity. `WorkflowsLive` already proves the pattern; Lifeline and limiters need explicit remount assertions after params are introduced or patched. [CITED: test/oban_powertools/web/live/workflows_live_test.exs] [CITED: test/oban_powertools/web/live/lifeline_live_test.exs] [CITED: test/oban_powertools/web/live/limiters_live_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| same-LiveView selection continuity | custom client-side state store | router params + `handle_params/3` + `patch` | LiveView already defines the exact contract and the repo already uses it successfully in workflows. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: lib/oban_powertools/web/workflows_live.ex] |
| cross-surface ownership wording | per-template string fragments | `ControlPlanePresenter` and `LiveAuth` | Phase 27 already centralized the vocabulary; scattering strings would immediately reintroduce drift. [CITED: lib/oban_powertools/web/control_plane_presenter.ex] [CITED: lib/oban_powertools/web/live_auth.ex] |
| overview sampling logic | generic recent-events feed | bounded overview read model with bucket-specific selection rules | The phase explicitly wants representative exemplars, not noisy recency theater. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] |

**Key insight:** the complex part of this phase is not rendering cards; it is choosing the smallest durable context that survives navigation honestly. LiveView already solves the navigation mechanics, so Phase 28 should spend its effort on the read model and on param discipline. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [VERIFIED: repo-local source review]

## Common Pitfalls

### Pitfall 1: Treating Overview As A KPI Wall

**What goes wrong:** the landing page stays count-heavy and operators still have to guess which number matters. [CITED: lib/oban_powertools/web/engine_overview_live.ex]
**Why it happens:** counts are cheaper to add than durable diagnosis and exemplar selection. [VERIFIED: repo-local source review]
**How to avoid:** require every bucket to carry diagnosis, exemplars, and venue-aware next-step copy from the same read-model contract. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]
**Warning signs:** cards render only numbers and a generic “Open” link. [CITED: lib/oban_powertools/web/engine_overview_live.ex]

### Pitfall 2: URL Contracts That Smuggle Execution State

**What goes wrong:** params start carrying preview tokens, reasons, or execute-ready action state that should expire with the session. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]
**Why it happens:** implementers try to solve all continuity with params instead of only durable read-model selectors. [VERIFIED: repo-local reasoning grounded in locked phase decisions]
**How to avoid:** restrict params to durable selectors only and rebuild preview state from durable server truth when needed. [CITED: lib/oban_powertools/web/lifeline_live.ex]
**Warning signs:** URLs contain `preview_token`, freeform reason text, or action outcome assumptions. [VERIFIED: phase-scope rule derived from context]

### Pitfall 3: Fake Native Parity For Bridge Destinations

**What goes wrong:** the overview implies that bridge follow-up has the same mutation semantics as native Powertools pages. [CITED: lib/oban_powertools/web/oban_web_bridge.ex]
**Why it happens:** a generic “Inspect” CTA or reused primary styling hides ownership boundaries. [VERIFIED: repo-local UI review]
**How to avoid:** show `Oban Web bridge` and `Inspection only` before click and keep bridge CTAs semantically secondary. [CITED: lib/oban_powertools/web/control_plane_presenter.ex] [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]
**Warning signs:** bridge cards use the same wording as native audited-action destinations. [VERIFIED: phase-scope rule derived from context]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `LimitersLive` should use `?resource=<resource_name>` as its canonical param contract. | Concrete Implementation Guidance | Low; the param key can change, but Phase 28 still needs some durable limiter-selection param. |
| A2 | Stable bridge filtering beyond the currently used job-detail and jobs landing paths is not yet verified locally and should not be assumed. | Bridge-Only Labels | Medium; assuming unsupported filters would create broken or misleading overview CTAs. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | LiveView implementation and test execution | ✓ | 1.19.5 | — [VERIFIED: local runtime check] |
| Mix | Phase proof commands | ✓ | 1.19.5 | — [VERIFIED: local runtime check] |
| Node.js | Phoenix asset/runtime support in this repo environment | ✓ | 22.14.0 | — [VERIFIED: local runtime check] |

**Missing dependencies with no fallback:** None discovered during research. [VERIFIED: local runtime check]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + `Phoenix.LiveViewTest` via `ObanPowertools.LiveCase` [CITED: test/support/live_case.ex] |
| Config file | none dedicated; shared LiveView test harness lives in `test/support/live_case.ex` [CITED: test/support/live_case.ex] |
| Quick run command | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/router_test.exs` [ASSUMED] |
| Full suite command | `mix test` [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OVR-01 | overview renders triage buckets with bounded exemplars and next-step copy instead of metric-only cards | LiveView | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs` | ❌ Wave 0 [VERIFIED: rg --files test/oban_powertools/web/live] |
| OVR-02 | overview CTAs preserve diagnosis context into native pages or explicit bridge destinations | LiveView + router | `mix test test/oban_powertools/web/live/engine_overview_live_test.exs test/oban_powertools/web/router_test.exs` | ❌ / ✅ [VERIFIED: rg --files test/oban_powertools/web/live] [CITED: test/oban_powertools/web/router_test.exs] |
| OVR-03 | selected resource/step/view survives patch, refresh, remount, and read-only access on native pages | LiveView | `mix test test/oban_powertools/web/live/workflows_live_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/limiters_live_test.exs` | ✅ / ✅ / ✅ [CITED: test/oban_powertools/web/live/workflows_live_test.exs] [CITED: test/oban_powertools/web/live/lifeline_live_test.exs] [CITED: test/oban_powertools/web/live/limiters_live_test.exs] |

### Sampling Rate

- **Per task commit:** run the targeted file for the touched surface, plus `router_test.exs` if handoff or bridge routing text changed. [VERIFIED: repo-local test inventory]
- **Per wave merge:** run all web LiveView tests in `test/oban_powertools/web/live/` plus `test/oban_powertools/web/router_test.exs`. [VERIFIED: repo-local test inventory]
- **Phase gate:** all Phase 28 web LiveView tests green, including the new overview proof lane and remount/read-only continuity assertions. [CITED: .planning/REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] `test/oban_powertools/web/live/engine_overview_live_test.exs` — new proof lane for OVR-01 and OVR-02. [VERIFIED: rg --files test/oban_powertools/web/live]
- [ ] `test/oban_powertools/web/live/limiters_live_test.exs` — add URL-param selection and remount continuity coverage. [CITED: test/oban_powertools/web/live/limiters_live_test.exs]
- [ ] `test/oban_powertools/web/live/lifeline_live_test.exs` — add patch-on-select and patch-on-view-toggle assertions, then prove remount/read-only continuity from those params. [CITED: test/oban_powertools/web/live/lifeline_live_test.exs]
- [ ] `test/oban_powertools/web/live/engine_overview_live_test.exs` — include explicit bridge-only labeling assertions and read-only overview session coverage in the new proof lane. [VERIFIED: rg --files test/oban_powertools/web/live]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | keep route/page gating on `LiveAuth.authorize_page/3`; Phase 28 should not bypass it for overview or destination handoffs. [CITED: lib/oban_powertools/web/live_auth.ex] |
| V3 Session Management | no major new surface | host-owned session behavior remains unchanged in this phase. [CITED: lib/oban_powertools/web/router.ex] |
| V4 Access Control | yes | preserve selected diagnosis context in read-only mode, but keep mutation controls disabled through existing `LiveAuth` checks and messages. [CITED: lib/oban_powertools/web/live_auth.ex] |
| V5 Input Validation | yes | treat all params as operator-controlled selectors, resolve them against durable repo data, and keep not-found or unauthorized cases explicit. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3] [CITED: lib/oban_powertools/web/lifeline_live.ex] |
| V6 Cryptography | no | no new crypto or secret-handling path is introduced by this phase. [VERIFIED: phase scope review] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| query-param tampering for selection state | Tampering | selectors only in params, server-side repo lookup, and existing page authorization before render. [CITED: lib/oban_powertools/web/live_auth.ex] [CITED: lib/oban_powertools/web/workflows_live.ex] |
| bridge/native confused-deputy semantics | Spoofing | explicit `Oban Web bridge` and `Inspection only` labeling before and after navigation. [CITED: lib/oban_powertools/web/control_plane_presenter.ex] [CITED: lib/oban_powertools/web/oban_web_bridge.ex] |
| leaking mutation internals through URLs | Information Disclosure | never place preview tokens or operator reasons in query params. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `lib/oban_powertools/web/engine_overview_live.ex` - current `/ops/jobs` metrics-only implementation and static venue links.
- `lib/oban_powertools/web/workflows_live.ex` - existing router-param and patch-based drilldown model.
- `lib/oban_powertools/web/lifeline_live.ex` - existing selection-from-params behavior and current non-patched click/toggle flows.
- `lib/oban_powertools/web/limiters_live.ex` - current socket-only limiter detail selection.
- `lib/oban_powertools/web/control_plane_presenter.ex` - shared status, ownership, and venue labels.
- `lib/oban_powertools/web/live_auth.ex` - read-only and permission wording contract.
- `lib/oban_powertools/web/router.ex` - mounted `/ops/jobs` route contract.
- `lib/oban_powertools/web/oban_web_bridge.ex` - bridge ownership and inspection-only posture.
- `test/support/live_case.ex` - current LiveView test harness.
- `test/oban_powertools/web/live/workflows_live_test.exs`, `lifeline_live_test.exs`, `limiters_live_test.exs`, `cron_live_test.exs`, `audit_live_test.exs`, `router_test.exs` - existing proof lanes and gaps.
- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` - official `patch` vs `navigate` contract.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_params/3` - official router-mounted param lifecycle contract.

### Secondary (MEDIUM confidence)

- None. [VERIFIED: research session source audit]

### Tertiary (LOW confidence)

- None beyond the explicit assumptions listed in `## Assumptions Log`. [VERIFIED: research session source audit]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended pieces are already in the repo or official Phoenix LiveView docs. [VERIFIED: mix.exs] [VERIFIED: mix.lock]
- Architecture: HIGH - the phase scope is tightly constrained by repo-local code and Phase 28 context decisions. [CITED: .planning/phases/28-diagnosis-first-overview-context-preserving-drilldowns/28-CONTEXT.md]
- Pitfalls: HIGH - each pitfall is directly grounded in current implementation gaps or locked out-of-scope rules. [VERIFIED: repo-local source review]

**Research date:** 2026-05-25
**Valid until:** 2026-06-24
