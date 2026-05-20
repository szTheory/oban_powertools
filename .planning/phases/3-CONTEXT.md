# Phase 3: Workflows (DAGs) & Signaling - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the first persisted workflow orchestration layer for Oban Powertools:
explicit DAG definitions backed by normalized workflow/node/edge records,
PubSub-accelerated step progression,
and a native operator view that makes blocked workflow state obvious.

This phase is about making workflow execution durable, explainable, and ergonomic.
It is not yet the full repair center, approval/wait orchestration system, or a full native replacement for generic Oban job inspection.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream agents should treat the recommendations in this context as the default architecture and product direction, and only surface follow-up questions when a choice would materially affect correctness, durability, operator safety, public API stability, or user-visible workflow semantics.
- **D-02:** Preference should shift left toward explicit best-practice defaults. Do not re-open tradeoffs that are already resolved here unless a later implementation constraint proves them untenable.

### Workflow Authoring Surface
- **D-03:** The primary public API should be an explicit builder pipeline, not a macro DSL and not raw maps as the headline surface.
- **D-04:** Preferred shape is `ObanPowertools.Workflow.new/1 |> add/3 |> add_many/3 |> connect/3 |> insert/2`, with stable step names and explicit dependency declarations.
- **D-05:** Persisted normalized workflow/node/edge records are the source of truth. Builder ergonomics are a facade over normalized persisted state, not an alternate execution model.
- **D-06:** Raw `%Workflow{}` / `%Node{}` / `%Edge{}` structs may exist as advanced escape hatches for generators, imports, and tests, but they must validate through the same normalization path as the builder API.
- **D-07:** Do not ship a high-level macro DSL in Phase 3. Macro sugar may be added later only after workflow semantics, signaling, and operator UX have stabilized.
- **D-08:** Workflow steps should remain normal Powertools/Oban workers with typed args and explicit metadata, not a separate hidden “workflow-only worker” abstraction.

### Signals and Progression Semantics
- **D-09:** Phase 3 public signaling scope is dependency-unblock signaling only: parent/required step completion persists state, and a coordinator uses PubSub to accelerate release of newly-runnable children.
- **D-10:** PubSub is an accelerator, never the source of truth. Workflow truth lives in Postgres rows and durable workflow state transitions.
- **D-11:** Introduce an internal workflow event/signal vocabulary now so the engine can persist and publish structured workflow events such as `step_completed`, `step_unblocked`, and `workflow_completed`.
- **D-12:** Do not expose first-class public `wait_for_signal` / approval / webhook-await workflow nodes in Phase 3.
- **D-13:** External signal waits are deferred until a later phase that also defines timeout semantics, delivery idempotency, audit behavior, UI treatment, and repair flows.

### Workflow Data Flow
- **D-14:** Named step-result references are the default workflow dataflow model between steps.
- **D-15:** Step outputs should be persisted explicitly and resolved by stable step name, e.g. `result(:fetch_user)`, rather than by implicit ambient state or recursive payload composition.
- **D-16:** Support a small immutable `workflow_context` for stable workflow-scope metadata such as actor ID, tenant/account ID, correlation IDs, labels, and user-visible annotations.
- **D-17:** `workflow_context` is not a mutable shared scratchpad. Do not use it as the primary mechanism for passing step outputs or cross-step write coordination.
- **D-18:** Result persistence must enforce size, redaction, and retention limits so the workflow layer does not become an unbounded document store.
- **D-19:** Missing, failed, cancelled, or unrecorded dependency results must map to explicit blocker codes and operator-visible explanations rather than collapsing to `nil` or implicit app-level lookups.

### Failure and Cancellation Semantics
- **D-20:** While an upstream dependency is still non-terminal but unresolved (for example retryable), dependents remain blocked.
- **D-21:** When an upstream dependency reaches a terminal non-success outcome (`cancelled`, `discarded`, `deleted`, or other normalized terminal failure state), dependent queued descendants should default to cascade-cancel rather than indefinite blocked limbo.
- **D-22:** Phase 3 should support narrow explicit per-edge override policies for terminal dependency outcomes, limited to `:cancel` or `:continue`.
- **D-23:** Per-edge continuation is an explicit sharp tool intended for cleanup/reporting/finalizer steps, not the default behavior.
- **D-24:** Do not make indefinite terminal blocking the default semantics. Explicit human-gate or signal-wait semantics belong in a later phase with proper repair/operator support.
- **D-25:** Persist dependency outcome snapshots onto affected child steps so `explain/1`, audit trails, and the workflow UI can show exact causality for cancellation or continued execution decisions.
- **D-26:** Phase 3 should start by propagating terminal dependency effects to queued/available descendants. Do not default to mutating already-running descendants as part of the initial semantics.

### Operator UX Scope for Phase 3
- **D-27:** Keep the hybrid shell direction from Phase 0 and Phase 2: native Powertools pages own Powertools concepts, while Oban Web remains the generic job inspection surface.
- **D-28:** Add a native workflow index page and a richer workflow detail page inside the existing `/ops/jobs` shell.
- **D-29:** The workflow detail page should be read-only in Phase 3, but rich enough to satisfy WF-03: DAG visualization, blocked node/edge highlighting, selected-node detail, dependency reasons, and nested/subworkflow drill-down.
- **D-30:** Deep-link node jobs to Oban Web for generic args/meta/error/retry history instead of rebuilding a full native job-detail/admin surface here.
- **D-31:** Reuse the structured explainability posture from Phase 2 so workflow details answer:
  what is blocked,
  why it is blocked,
  what dependency or result is responsible,
  and what could run next.
- **D-32:** Do not add workflow mutation actions such as retry-step, skip-edge, cancel-subtree, or repair-subgraph in Phase 3. Those belong with Phase 4 dry-run repair, audit reason capture, and explicit operator safety controls.
- **D-33:** Preserve stable graph layout, node naming, and operator selection state across live PubSub updates. Realtime updates must not make the page feel visually unstable.

### API, Persistence, and State Model
- **D-34:** Workflow insertion, step completion, dependency release, and terminal propagation must be modeled as explicit Ecto-backed state transitions, following the same transactional posture as idempotency and cron.
- **D-35:** Validate graph correctness before insertion: no cycles, no missing dependencies, no orphan edges, and no duplicate step names within a workflow definition.
- **D-36:** Stable step names are part of the public workflow contract because they drive result lookup, explainability, deep-linking, and future repair tooling.
- **D-37:** Do not persist arbitrary closures/functions in workflow definitions. Persist only explicit worker/module references and serializable inputs/metadata.
- **D-38:** Separate authoring-time graph definition from runtime execution state. Runtime attempts, statuses, timestamps, and result snapshots should not mutate the original logical graph definition in-place.

### Telemetry and Audit Defaults
- **D-39:** Add workflow lifecycle telemetry events using low-cardinality labels only, following the project prompt guidance for `[:oban_powertools, :workflow, ...]`.
- **D-40:** High-cardinality workflow evidence belongs in durable workflow tables, result records, blocker snapshots, and audit events, not in metric labels.
- **D-41:** Workflow state transitions that materially affect operator understanding or future repair flows should be auditable and explainable using the same normalized posture established in Phase 2.

### Non-Goals for Phase 3
- **D-42:** Do not ship full approval/webhook/external signal wait semantics in this phase.
- **D-43:** Do not ship workflow repair, subtree mutation, or dry-run remediation actions in this phase.
- **D-44:** Do not rebuild a native generic jobs dashboard or generic job details inside workflow pages.
- **D-45:** Do not use recursive nested payload composition or opaque in-memory DAG state as the source of truth.
- **D-46:** Do not make workflow context a mutable shared bag of arbitrary step-written state.

### the agent's Discretion
- Exact schema/module names, as long as the persisted graph and runtime state boundaries remain explicit.
- Exact result-record encoding and retention mechanics, provided result references stay explicit and operator-visible.
- Exact GenServer/coordinator process topology, provided Postgres remains the source of truth and PubSub remains an accelerator.
- Exact LiveView component composition and visual style, provided the workflow UI stays explanation-first, read-only, and consistent with the existing native shell direction.

</decisions>

<specifics>
## Specific Ideas

- Preferred authoring feel:
  `Workflow.new(name: "sync_customer")`
  `|> Workflow.add(:fetch, FetchCustomer.new(%{id: id}))`
  `|> Workflow.add(:sync_billing, SyncBilling.new(%{id: id}), deps: [:fetch])`
  `|> Workflow.add(:sync_support, SyncSupport.new(%{id: id}), deps: [:fetch])`
  `|> Workflow.add(:notify, NotifyDone.new(%{id: id}), deps: [:sync_billing, :sync_support])`
  `|> Workflow.insert(repo)`
- Result passing should look explicit and grep-able, e.g. `input: %{user: result(:fetch_user)}` or `Workflow.result(job, :fetch_user)`.
- Small immutable workflow context should be used for actor/account/correlation metadata and human-facing labels, not mutable business state.
- Internal workflow event vocabulary should reserve room for future public signal waits without exposing them yet.
- Blocked workflow UX should make the exact node and dependency edge obvious, especially for fan-out/fan-in and nested workflow cases.
- Workflow detail pages should show dependency reason badges, step status, result availability, and deep links to the underlying Oban job.
- Phase 3 should feel like “diagnose in Powertools, inspect generic job internals in Oban Web, mutate only when the repair system exists.”
- Preference from this discussion: downstream GSD agents should assume these recommendations are the paved road and avoid re-litigating them unless a later implementation reality clearly forces a revisit.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and phase requirements
- `.planning/ROADMAP.md` — Phase 3 scope, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — WF-01, WF-02, and WF-03 requirements.
- `.planning/STATE.md` — current project posture and the explicit “workflows next” project focus.

### Prior phase context
- `.planning/phases/0-CONTEXT.md` — hybrid shell/bridge direction, host-owned auth posture, and low-cardinality telemetry rules.
- `.planning/phases/2-CONTEXT.md` — explainability, audit posture, narrow native UI strategy, and “PubSub accelerates but persisted state explains” smart-engine philosophy.

### Project research and vision
- `.planning/research/ARCHITECTURE.md` — recommended Workflow Coordinator pattern and Ecto-native/Postgres-only system boundaries.
- `.planning/research/domain_competitors.md` — workflow/DAG footguns from Sidekiq, BullMQ, Celery, and GoodJob.
- `.planning/research/operator_ux.md` — explain-then-act operator UX and hybrid UI rationale.
- `.planning/research/STACK.md` — Phoenix.PubSub role in workflow signaling.
- `prompts/oban_powertools_context.md` — domain language, workflow/signal vocabulary, API design principles, and telemetry guidance.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — workflow page expectations, native shell boundaries, and operator UX posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/worker.ex`: existing typed worker API and explicit ergonomic surface should remain the model for workflow-facing APIs.
- `lib/oban_powertools/idempotency.ex`: strong pattern for public API -> validation -> `Ecto.Multi` transaction -> explicit tagged results.
- `lib/oban_powertools/cron.ex`: strongest in-repo analog for durable orchestration semantics, state snapshots, policy handling, and operator-safe actions.
- `lib/oban_powertools/explain.ex`: existing structured blocker contract should be extended or mirrored for workflow dependency blockers and node-detail explanations.
- `lib/oban_powertools/audit.ex`: normalized durable audit writer for workflow transitions and later operator actions.
- `lib/oban_powertools/telemetry.ex`: pattern for low-cardinality telemetry helpers; workflow lifecycle helpers should follow this shape.
- `lib/oban_powertools/web/router.ex`: existing shell routing pattern for native Powertools pages plus Oban Web bridge should grow with workflow routes.
- `lib/oban_powertools/web/engine_overview_live.ex`: current native page posture is narrow summary cards + deep links, which should inform workflow index/detail scope.
- `lib/oban_powertools/application.ex`: clear extension point for adding workflow coordinator supervision.

### Established Patterns
- Public API surfaces are explicit and grep-able rather than magical.
- Durable Postgres-backed state is preferred over hidden in-memory coordination.
- `Ecto.Multi` transactional semantics are the paved road for correctness-sensitive state changes.
- Explainability and operator safety matter as much as raw functionality.
- Native Powertools pages stay focused on Powertools-owned concepts and deep-link to Oban Web for generic job admin concerns.

### Integration Points
- Add workflow coordinator/runtime supervision under the existing application supervisor.
- Extend native router shell with workflow index/detail pages under `/ops/jobs`.
- Reuse audit and telemetry boundaries for workflow lifecycle events.
- Reuse explain-style structured blocker payloads for workflow dependency and result-resolution blockers.
- Preserve typed workers and explicit args as the unit of execution for workflow nodes.

</code_context>

<deferred>
## Deferred Ideas

- Public first-class `wait_for_signal` / approval / webhook-await workflow steps.
- Workflow repair actions, subtree mutation, and dry-run remediation UX.
- Full native node/job mutation controls inside workflow pages.
- Macro DSL authoring sugar for workflows.
- Richer workflow mutation hooks beyond narrow dependency policies once the base DAG semantics are proven.

</deferred>

---

*Phase: 3-workflows-dags-signaling*
*Context gathered: 2026-05-19*
