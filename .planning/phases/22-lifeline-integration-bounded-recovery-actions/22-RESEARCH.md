# Phase 22: Lifeline Integration & Bounded Recovery Actions - Research

**Researched:** 2026-05-24
**Domain:** Workflow action integration between `ObanPowertools.Workflow.Runtime`, `ObanPowertools.Lifeline`, and Phoenix LiveView operator surfaces [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- Inline full `preview -> reason -> execute` workflow-page controls — defer until the product intentionally chooses the workflow page as a second or primary high-trust mutation venue.
- Workflow-wide retry/recover, force-expire, replay-signal, reconcile, or terminate-style controls — defer until each has equally explicit durable semantics, preview shape, and proof posture.
- Incident-only executor-health repair actions becoming workflow-page actions — defer unless the incident evidence itself can be represented truthfully on the workflow resource without distortion.
- A broader cross-product control-plane unification across workflows, jobs, queues, and Lifeline — later milestone ownership.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `DIA-02` | Lifeline and workflow inspection surfaces consume the same workflow diagnosis vocabulary and expose only bounded, audited recovery actions that re-enter the workflow command pipeline. | Use `Explain` + `Runtime` as the action-legality source and route all executes through `Lifeline` into `Workflow.Runtime` or `Workflow.request_cancel/3`. [VERIFIED: codebase grep] |
| `WFS-02` | Runtime and operator mutations can only move workflows through documented legal transitions recomputed from Postgres-backed truth. | Keep `Workflow.Runtime` as the sole legality engine; do not let LiveViews or Lifeline incident rows decide legality. [VERIFIED: codebase grep] |
| `REC-03` | Workflow cancellation is cooperative and explicit: operators can see request versus final outcome, and late step completion after a cancel request is preserved as durable evidence. | The only workflow-level Phase 22 action should be `workflow_request_cancel`, with copy that preserves Phase 20 request/evidence/outcome semantics. [VERIFIED: codebase grep] |
| `VER-01` | The repo proves duplicate, late, dropped, and race-path workflow events with automated fixtures. | Add targeted tests for workflow-directed Lifeline previews, non-incident actions, drifted previews, and cancel handoff behavior. Existing lifeline/live tests already prove the current preview contract. [VERIFIED: codebase grep] |
| `VER-02` | A maintainer can upgrade hosts with in-flight waiting, retrying, cancelling, or recovering workflows without breaking semantics or leaving support unable to explain stored state. | Preserve existing command attempt, recovery session, and preview evidence shapes; avoid schema semantics that hide request-cancel nuance or split mutation truth across surfaces. [VERIFIED: codebase grep] |
| `POL-04` | Public telemetry and support-truth docs describe semantics with low-cardinality events and no unproven guarantees. | Keep preview tokens, reasons, and detailed workflow evidence in durable preview/audit rows, not public telemetry dimensions. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 22 should be planned as an integration/refactor phase, not a greenfield control-plane phase: the repo already has the two hard pieces it needs, namely a DB-first workflow legality core in `ObanPowertools.Workflow.Runtime` and a durable preview/reason/execute/audit envelope in `ObanPowertools.Lifeline`. The planning target is to connect those two seams without creating a second mutation engine, a second preview lifecycle, or a second execution venue. [VERIFIED: codebase grep]

The main architectural gap is that current Lifeline row expansion is still incident-shaped and only emits `workflow_step_retry` for `workflow_stuck` incidents, while current workflow UI stops at guidance-only `legal_next_steps`. Phase 22 therefore needs a shared workflow-action read model that can be consumed by both `WorkflowsLive` and `LifelineLive`, plus a Lifeline selection/handoff mechanism that works even when no active incident row exists for an otherwise legal workflow action. [VERIFIED: codebase grep]

The safest plan is: keep the workflow page diagnosis-first, add a direct Lifeline handoff driven by URL params and `handle_params/3`, generalize the current preview schema/service naming without changing its lifecycle semantics, and add only three executable workflow actions in this phase: `workflow_step_retry`, `workflow_step_cancel`, and `workflow_request_cancel`. The first two should keep using step-scoped runtime recovery; the third should execute through `Workflow.request_cancel/3` so the Phase 20 cooperative-cancel contract remains intact. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

**Primary recommendation:** Extend the existing Lifeline preview envelope into a workflow-native action adapter and drive all Phase 22 execution back through `Workflow.Runtime`/`Workflow.request_cancel`, with LiveView deep-linking as the only new surface behavior. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Workflow action legality (`retry`, `cancel`, `request_cancel`) | API / Backend | Database / Storage | `Workflow.Runtime` already validates commands, persists rejection evidence, and recomputes legal transitions from DB state. [VERIFIED: codebase grep] |
| Durable preview token lifecycle (`ready`, `drifted`, `expired`, `consumed`) | API / Backend | Database / Storage | `Lifeline` + `RepairPreview` already own token issuance, drift checks, expiry, and single-use consume. [VERIFIED: codebase grep] |
| Operator handoff from workflow page to Lifeline | Frontend Server (SSR) | API / Backend | The handoff should be URL/params-driven in LiveView, while the selected action still resolves against backend truth. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Workflow diagnosis and allowed-next-action projection | API / Backend | Frontend Server (SSR) | `Explain` and `Runtime` already centralize diagnosis vocabulary; LiveView should render it, not infer it. [VERIFIED: codebase grep] |
| Audit and operator evidence | Database / Storage | API / Backend | The repo records durable audit rows and command/recovery evidence in Postgres; telemetry is explicitly not the audit contract. [VERIFIED: codebase grep] |
| Read-only/permission framing | Frontend Server (SSR) | API / Backend | `LiveAuth` centralizes page/action authorization and operator-facing mutation error vocabulary. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` | Runtime, ExUnit, Mix, Phoenix/Ecto host language | This is the installed toolchain on the target machine and the repo declares `~> 1.19`. [VERIFIED: codebase grep] [VERIFIED: local command] |
| Phoenix | `1.8.7` | LiveView host/router layer for native operator surfaces | The lockfile resolves Phoenix `1.8.7`, and Hex shows `1.8.7` as the current stable package version on 2026-05-24. [VERIFIED: codebase grep] [VERIFIED: hex.pm] |
| Phoenix LiveView | `1.1.30` | Router-mounted native ops pages, `handle_params/3`, patch/navigate handoff | The lockfile resolves `1.1.30`, and the official docs cover URL-driven live navigation and router-mounted param handling. [VERIFIED: codebase grep] [VERIFIED: hex.pm] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Ecto SQL | `3.13.5` | `Ecto.Multi` transaction boundary for preview consume + mutation + audit | The repo is locked to `3.13.5`; Hex shows `3.14.0` is newer, so Phase 22 should plan on the repo-locked version unless a separate upgrade phase is created. [VERIFIED: codebase grep] [VERIFIED: hex.pm] |
| Oban | `2.22.1` | Durable job/workflow integration surface and current job semantics context | The lockfile resolves `2.22.1`, and Hex shows `2.22.1` is current as of 2026-05-24. [VERIFIED: codebase grep] [VERIFIED: hex.pm] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban_web` | `2.12.4` | Optional embedded generic inspection bridge | Keep it out of Phase 22 mutation ownership; use only for generic job inspection deep-links. [VERIFIED: codebase grep] [VERIFIED: hex.pm] |
| PostgreSQL | `14.17` local CLI | Required backing store for test repo and durable workflow truth | Required for local execution and the existing ExUnit/Ecto sandbox harness. [VERIFIED: local command] [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending `Lifeline.RepairPreview` semantics | A new workflow-only preview schema/service | Reject this in Phase 22 because it would fork lifecycle semantics and duplicate drift/consume logic. [VERIFIED: codebase grep] |
| LiveView handoff via query params | Custom PubSub or session-only selection state | Query-param handoff is easier to test, preserves refreshability, and fits router-mounted `handle_params/3`. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Runtime-owned action legality | LiveView-owned button logic or incident-owned legality | Reject this because D-05/D-09 and Phase 17 already lock legality to durable workflow truth. [VERIFIED: codebase grep] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** The repo currently resolves Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, Oban `2.22.1`, `oban_web` `2.12.4`, and `ecto_sql` `3.13.5` in `mix.lock`; Hex confirms all except `ecto_sql` match the latest stable package version, while `ecto_sql` has a newer `3.14.0` available. [VERIFIED: codebase grep] [VERIFIED: hex.pm]

## Architecture Patterns

### System Architecture Diagram

```text
Workflow detail page
  -> Explain.workflow_story / step_story
  -> shared allowed-next-action projection
  -> CTA with workflow_id + step/action context
  -> Lifeline route params
  -> LifelineLive.handle_params / selection resolver
  -> Lifeline.preview_* adapter
  -> shared preview row (ready/drifted/expired/consumed)
  -> Lifeline.execute_* adapter
  -> Workflow.Runtime / Workflow.request_cancel
  -> Ecto.Multi transaction
  -> command attempt / recovery evidence / audit row
  -> LiveView reload of workflow + Lifeline state
```

The important planning boundary is that URL state selects the action, but only the backend decides whether the action is still legal and what the preview/effect should be. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Recommended Project Structure
```text
lib/
├── oban_powertools/explain.ex                 # shared workflow diagnosis + action projection
├── oban_powertools/lifeline.ex                # preview/execute adapters, shared envelope reuse
├── oban_powertools/lifeline/repair_preview.ex # existing preview schema to generalize, not fork
├── oban_powertools/workflow.ex                # stable public API seam for request_cancel
├── oban_powertools/workflow/runtime.ex        # legal mutation authority
├── oban_powertools/web/workflows_live.ex      # diagnosis-first UI + Lifeline handoff CTA
└── oban_powertools/web/lifeline_live.ex       # sole native execute venue with param-driven selection
```

### Pattern 1: Shared Action Projection
**What:** Add one workflow action projection under `Explain` that returns action ids, labels, target scope, supporting evidence, and any incident dependency requirement from durable workflow facts. [VERIFIED: codebase grep]

**When to use:** For every Phase 22 action surfaced on the workflow page or Lifeline page. [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: local pattern based on lib/oban_powertools/explain.ex + workflow/runtime.ex
%{
  diagnosis: story.diagnosis,
  legal_next_steps: story.rejection_summary && story.rejection_summary.legal_next_steps || [],
  executable_actions: [
    %{id: "workflow_step_retry", target_type: "workflow_step", target_id: step.id},
    %{id: "workflow_request_cancel", target_type: "workflow", target_id: workflow.id}
  ]
}
```

### Pattern 2: Lifeline Adapter Over One Mutation Core
**What:** Keep `Lifeline` as a thin adapter that builds previews, recomputes drift, and then delegates the real mutation to `Workflow.Runtime` or `Workflow.request_cancel/3`. [VERIFIED: codebase grep]

**When to use:** For any bounded workflow action that needs preview/audit posture but whose legality belongs to workflow truth. [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: local pattern based on lib/oban_powertools/lifeline.ex
case {preview.target_type, preview.action} do
  {"workflow_step", "workflow_step_retry"} ->
    Runtime.recover_step_by_id(repo, preview.target_id, :retry, source: "lifeline", ...)

  {"workflow", "workflow_request_cancel"} ->
    Workflow.request_cancel(repo, preview.target_id, source: "lifeline", ...)
end
```

### Pattern 3: URL-Driven Handoff
**What:** Use router-mounted LiveView params for workflow-to-Lifeline handoff so the selected workflow/step/action survives refresh, copy/paste, and test automation. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [VERIFIED: codebase grep]

**When to use:** Whenever the workflow page needs to send the operator into Lifeline with a specific action already selected. [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: local pattern based on lib/oban_powertools/web/workflows_live.ex
<.link navigate={~p"/ops/jobs/lifeline?workflow_id=#{workflow.id}&step=#{step.step_name}&action=workflow_step_retry"}>
  Review in Lifeline
</.link>
```

### Anti-Patterns to Avoid
- **Incident-shaped legality:** Do not require an active `Incident` row before a workflow action can be previewed if durable workflow truth says the action is legal. [VERIFIED: codebase grep]
- **Second execution surface:** Do not add inline execute controls to `WorkflowsLive` in Phase 22. [VERIFIED: codebase grep]
- **Preview-state fork:** Do not create `WorkflowPreview` with a new lifecycle when `RepairPreview` already proves `ready`/`drifted`/`expired`/`consumed`. [VERIFIED: codebase grep]
- **Cancel overpromise:** Do not label `workflow_request_cancel` as immediate termination; the existing runtime preserves cooperative cancel semantics and late completion evidence. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Preview lifecycle | A new workflow-only preview token model | `Lifeline.RepairPreview` semantics generalized behind a neutral seam | Drift/expiry/consume logic, dedupe, and tests already exist. [VERIFIED: codebase grep] |
| Workflow legality | Button-state heuristics in LiveView | `Workflow.Runtime` + `Workflow.request_cancel/3` + rejection evidence | Only the runtime already persists legal/refused mutations with `legal_next_steps`. [VERIFIED: codebase grep] |
| Handoff state | Hidden socket/session state | LiveView params + `handle_params/3` | Router-mounted params are refreshable and explicitly supported by official LiveView navigation. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Audit trail | Telemetry-only mutation evidence | Existing audit rows + command/recovery evidence | The repo explicitly keeps rich mutation evidence out of telemetry. [VERIFIED: codebase grep] |

**Key insight:** Phase 22 is mostly about reusing proven contracts at a new workflow-native boundary; any plan that starts by inventing new mutation primitives is planning the wrong phase. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Modeling Workflow Actions As Lifeline Incidents
**What goes wrong:** Legal workflow actions become unavailable whenever there is no matching active incident row. [VERIFIED: codebase grep]
**Why it happens:** Current `LifelineLive` row expansion and preview lookup are keyed to incident rows. [VERIFIED: codebase grep]
**How to avoid:** Split “selection row” from “incident row”; allow Lifeline to render workflow-directed rows synthesized from workflow diagnosis plus optional incident context. [VERIFIED: codebase grep]
**Warning signs:** The workflow page says an action is legal, but Lifeline cannot preview it unless `project_incidents/1` created a row first. [VERIFIED: codebase grep]

### Pitfall 2: Breaking The Cooperative Cancel Contract
**What goes wrong:** `workflow_request_cancel` gets preview copy or audit wording that implies immediate stop/finality. [VERIFIED: codebase grep]
**Why it happens:** Lifeline currently uses repair-oriented language and “Execute Repair Plan” copy. [VERIFIED: codebase grep]
**How to avoid:** Make preview payloads and button labels action-native; for workflow cancel, say `Request cancel` and describe request/evidence/outcome semantics. [VERIFIED: codebase grep]
**Warning signs:** UI or docs use “cancel workflow now”, “stop immediately”, or generic repair wording for workflow requests. [VERIFIED: codebase grep]

### Pitfall 3: Status Drift From Legacy `pending`
**What goes wrong:** `LifelineLive` still queries for preview statuses `["pending", "drifted"]` and disables execute unless `preview.status == "pending"`, while `RepairPreview` canonical status is `ready`. [VERIFIED: codebase grep]
**Why it happens:** Lifeline UI contains old naming that no longer matches `RepairPreview` lifecycle values. [VERIFIED: codebase grep]
**How to avoid:** Normalize Lifeline UI onto `ready`/`drifted`/`expired`/`consumed` before adding more workflow actions. [VERIFIED: codebase grep]
**Warning signs:** Fresh previews render but execute remains disabled or preview lookup misses ready rows after remount. [VERIFIED: codebase grep]

### Pitfall 4: Duplicating Action Mapping In Two Surfaces
**What goes wrong:** Workflows page and Lifeline page each grow their own mapping from diagnosis/refusal to buttons. [VERIFIED: codebase grep]
**Why it happens:** Phase 21 stopped at guidance-only text, and current Lifeline action rows are incident-specific. [VERIFIED: codebase grep]
**How to avoid:** Introduce one shared action projection and reuse it in both LiveViews. [VERIFIED: codebase grep]
**Warning signs:** Different labels for the same action, or one surface offers `retry` while the other says `recover`. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from current code and official docs:

### Router-Mounted LiveView Param Handling
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
@impl true
def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :selected, params["id"])}
end
```

This is the right mechanism for a workflow-to-Lifeline deep-link because both current pages are router-mounted LiveViews already using URL navigation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [VERIFIED: codebase grep]

### Runtime-Owned Cancel Entry Point
```elixir
# Source: lib/oban_powertools/workflow.ex
def request_cancel(repo, workflow_id, attrs \\ []),
  do: ObanPowertools.Workflow.Runtime.request_cancel(repo, workflow_id, Enum.into(attrs, %{}))
```

This is the correct execute seam for `workflow_request_cancel`; planners should not route cancel through ad hoc step recovery helpers. [VERIFIED: codebase grep]

### Existing Preview Drift And Consume Contract
```elixir
# Source: lib/oban_powertools/lifeline/repair_preview.ex
@statuses ~w(ready drifted expired consumed)
```

Phase 22 should reuse this lifecycle instead of creating workflow-specific statuses. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Guidance-only allowed-next-action text in workflow UI | Shared diagnosis vocabulary with executable handoff expected in Phase 22 | Phase 21, 2026-05-24 context | Phase 22 should activate, not redesign, that action vocabulary. [VERIFIED: codebase grep] |
| Incident-only Lifeline workflow actions | Workflow-directed bounded actions, even without active incident ownership of legality | Locked by Phase 22 context on 2026-05-24 | Requires Lifeline row-selection refactor away from incident-only assumptions. [VERIFIED: codebase grep] |
| Repair-only preview naming | Shared native mutation envelope across Lifeline, cron, and workflows | Locked by Phase 10 and Phase 22 contexts | Plan should prefer internal seam generalization over schema/UI forking. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- `pending` preview status handling inside `LifelineLive`: outdated relative to `RepairPreview` canonical statuses and should be normalized as part of this phase. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The preview schema can be generalized by naming/seam refactor without requiring a breaking storage migration. `[ASSUMED]` | Architecture Patterns | If wrong, Phase 22 needs explicit migration work and compatibility handling for existing preview rows. |

## Open Questions (RESOLVED)

1. **Should Lifeline show workflow-directed rows when there is no incident at all?**
   - Decision: yes, but Phase 22 required scope is the workflow-driven handoff and review path, not a new generic browse-first discovery surface. Lifeline must be able to materialize a workflow-directed review row from durable workflow truth plus URL-selected context even when there is no active incident row. Generic browsing of such rows may reuse the same row model later, but it is discretionary follow-on rather than merge-blocking Phase 22 scope. [VERIFIED: codebase grep]
   - Why: this satisfies D-05 to D-09 and D-12 to D-16 by keeping legality workflow-owned while still making Lifeline the sole native execute venue. [VERIFIED: codebase grep]

2. **How far should preview copy be renamed away from “repair”?**
   - Decision: Phase 22 must make workflow-directed visible copy workflow-native now, while broader cross-surface copy harmonization remains additive follow-on work. Internal seam or helper renaming may be generalized in this phase where it reduces distortion, but existing non-workflow surfaces do not need a full copy rewrite to ship Phase 22. [VERIFIED: codebase grep]
   - Why: this satisfies D-25 and D-29 without turning the phase into a repo-wide copy sweep, and it preserves support-truthful `Request cancel` wording for workflow-level cancel semantics. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix test`, compilation, ExUnit | ✓ | `1.19.5` | — |
| Mix | build and test commands | ✓ | `1.19.5` | — |
| PostgreSQL CLI / server-compatible stack | Ecto sandbox tests and durable repo operations | ✓ | `psql 14.17` | none for the existing test harness |
| Node.js | ancillary tooling only; not required for core Phase 22 code | ✓ | `v22.14.0` | — |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: local command]

**Missing dependencies with fallback:**
- None found. [VERIFIED: local command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5` with Ecto SQL sandbox and Phoenix LiveView test helpers. [VERIFIED: codebase grep] [VERIFIED: local command] |
| Config file | `none` for a dedicated test runner config; the harness is bootstrapped in `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` [VERIFIED: local command] |
| Full suite command | `mix test` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `DIA-02` | Workflow and Lifeline consume the same actionable diagnosis vocabulary | live + integration | `mix test test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs` | ✅ |
| `WFS-02` | Workflow-directed executes re-enter the DB-first command core | integration | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/workflow_runtime_test.exs` | ✅ |
| `REC-03` | `workflow_request_cancel` preserves request-vs-outcome semantics | integration | `mix test test/oban_powertools/workflow_runtime_test.exs` | ✅ |
| `VER-01` | Workflow-directed Lifeline actions cover drift, non-incident selection, and preview consume behavior | live + integration | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ❌ Wave 0 for the new non-incident/cancel cases |
| `VER-02` | Existing evidence remains explainable after action execution and remount | live + integration | `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs` | ✅ partial; needs new workflow-directed assertions |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/lifeline_live_test.exs test/oban_powertools/web/live/workflows_live_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/oban_powertools/lifeline_test.exs` — add `workflow_request_cancel` preview/execute coverage and non-incident workflow action coverage. [VERIFIED: codebase grep]
- [ ] `test/oban_powertools/web/live/lifeline_live_test.exs` — add deep-link/param selection tests from workflow context into Lifeline. [VERIFIED: codebase grep]
- [ ] `test/oban_powertools/web/live/workflows_live_test.exs` — add CTA rendering/assertions for legal-next-action handoff without inline execute controls. [VERIFIED: codebase grep]
- [ ] `test/oban_powertools/workflow_runtime_test.exs` — add cross-assertions that Lifeline-issued cancel writes the same command/evidence shape as direct workflow API usage. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host-owned `Auth.current_actor/1` + page authorization gates in `LiveAuth.on_mount/4`. [VERIFIED: codebase grep] |
| V3 Session Management | no | Host app owns session semantics; this phase only consumes current actor session data. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Separate `preview_repair` and `execute_repair` authorization with server-side rechecks. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Reason validation, target/action allowlists, and runtime command validation/refusal vocabulary. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Preview tokens are UUIDs and drift tokens are hashed plan payloads via `:crypto.hash(:sha256, ...)`; do not hand-roll alternate token logic. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replaying a preview token | Elevation of privilege | Single-use preview consume + status recheck + expiry recheck before execute. [VERIFIED: codebase grep] |
| Executing a stale workflow action after state changed | Tampering | Recompute plan hash from durable workflow/step state and mark preview `drifted` on mismatch. [VERIFIED: codebase grep] |
| Unauthorized preview or execute | Spoofing / Elevation of privilege | `LiveAuth.authorize_action/4` and backend `authorize/3` both gate preview and execute separately. [VERIFIED: codebase grep] |
| Leaking operator reasons into public telemetry | Information disclosure | Keep reasons in preview/audit metadata only; telemetry events use low-cardinality action/incident/target metadata. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `mix.exs`, `mix.lock`, `lib/oban_powertools/workflow.ex`, `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/explain.ex`, `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/lifeline/repair_preview.ex`, `lib/oban_powertools/web/workflows_live.ex`, `lib/oban_powertools/web/lifeline_live.ex`, `lib/oban_powertools/web/live_auth.ex` — implementation seams, action vocabulary, preview lifecycle, and auth/audit contract. [VERIFIED: codebase grep]
- `test/oban_powertools/lifeline_test.exs`, `test/oban_powertools/web/live/lifeline_live_test.exs`, `test/oban_powertools/web/live/workflows_live_test.exs`, `test/oban_powertools/workflow_runtime_test.exs`, `test/test_helper.exs` — existing proof lanes and test harness. [VERIFIED: codebase grep]
- `.planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md`, `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md`, `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md`, `.planning/phases/21-workflow-diagnosis-projection-native-workflow-surface/21-CONTEXT.md`, `.planning/phases/22-lifeline-integration-bounded-recovery-actions/22-CONTEXT.md` — locked constraints and phase continuity. [VERIFIED: codebase grep]
- Phoenix LiveView official docs — live navigation and router-mounted `handle_params/3`. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Hex package pages for Phoenix, Phoenix LiveView, Oban, `oban_web`, and `ecto_sql`. [VERIFIED: hex.pm]

### Secondary (MEDIUM confidence)
- None. Most material claims were verified directly in the codebase or official package/docs sources. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were checked in `mix.lock`, local toolchain commands, and Hex package pages. [VERIFIED: codebase grep] [VERIFIED: local command] [VERIFIED: hex.pm]
- Architecture: HIGH - the integration points are explicit in current modules and locked contexts. [VERIFIED: codebase grep]
- Pitfalls: HIGH - each listed pitfall is visible from current code shape or inherited locked phase constraints. [VERIFIED: codebase grep]

**Research date:** 2026-05-24
**Valid until:** 2026-06-23
