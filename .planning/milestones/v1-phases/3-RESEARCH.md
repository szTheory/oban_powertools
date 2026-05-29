# Phase 3: Workflows (DAGs) & Signaling - Research

**Researched:** 2026-05-19  
**Domain:** Persisted workflow orchestration, dependency signaling, and native operator workflow UX [VERIFIED: .planning/ROADMAP.md]  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this entire section: [VERIFIED: .planning/phases/3-CONTEXT.md]

### Locked Decisions

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

### Claude's Discretion
- Exact schema/module names, as long as the persisted graph and runtime state boundaries remain explicit.
- Exact result-record encoding and retention mechanics, provided result references stay explicit and operator-visible.
- Exact GenServer/coordinator process topology, provided Postgres remains the source of truth and PubSub remains an accelerator.
- Exact LiveView component composition and visual style, provided the workflow UI stays explanation-first, read-only, and consistent with the existing native shell direction.

### Deferred Ideas (OUT OF SCOPE)
- Public first-class `wait_for_signal` / approval / webhook-await workflow steps.
- Workflow repair actions, subtree mutation, and dry-run remediation UX.
- Full native node/job mutation controls inside workflow pages.
- Macro DSL authoring sugar for workflows.
- Richer workflow mutation hooks beyond narrow dependency policies once the base DAG semantics are proven.
</user_constraints>

<phase_requirements>
## Phase Requirements

Source for IDs and descriptions: [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| WF-01 | Model explicit DAG workflows using `oban_powertools_workflows` and `edges` tables. | Use a normalized `workflow -> node -> edge -> result` persistence model, validate no cycles/duplicate names before insert, and snapshot stable worker/input metadata at insertion time. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED] |
| WF-02 | Build GenServer coordinators and Phoenix PubSub signaling for rapid step progression. | Use DB-first completion/release transactions plus PubSub fan-out as an accelerator, with idempotent child-release queries and one supervised coordinator per node. [VERIFIED: .planning/phases/3-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED] |
| WF-03 | Create a visual UI representation for DAG states, highlighting blocked steps. | Add native workflow index/detail LiveViews under `/ops/jobs`, preserve stable layout on updates, and deep-link generic job inspection into Oban Web. [VERIFIED: .planning/phases/3-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/router.ex] [CITED: https://hexdocs.pm/oban_web/overview.html] |
</phase_requirements>

## Summary

Phase 3 should be implemented as four subsystems in strict order: `definition + persistence`, `runtime transitions`, `signaling`, and `native read-only workflow UX`. That order matches how Phase 1 and Phase 2 already work in this repo: explicit public API, normalized Postgres tables, `Ecto.Multi` transactions, then narrow native operator pages layered on top. [VERIFIED: lib/oban_powertools/idempotency.ex] [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/web/router.ex]

The most defensible split is: `ObanPowertools.Workflow` as the public builder/insert API, `ObanPowertools.Workflow.{Definition,Node,Edge,Result}` as persisted contracts, `ObanPowertools.Workflow.Runtime` as DB-backed transition functions, `ObanPowertools.Workflow.Coordinator` as the supervised PubSub subscriber that accelerates release, and `ObanPowertools.Web.{WorkflowsLive,WorkflowLive}` as the native operator surface. That preserves the Phase 2 pattern of durable state plus a small OTP boundary instead of inventing a second in-memory orchestration system. [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED]

The main durability risks are not algorithmic DAG theory; they are operational footguns: double-unblocking children, publishing before commit, treating missing results as `nil`, overloading `workflow_context` into a mutable document store, and flattening nested workflows into one enormous live graph. The research recommendation is to keep Postgres as truth, treat PubSub as a nudge, store step outputs explicitly with limits, and model nested workflows as linked workflow runs instead of cross-graph arbitrary edges. [VERIFIED: .planning/phases/3-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED]

**Primary recommendation:** Implement Phase 3 around idempotent DB state transitions first, then add PubSub acceleration and a read-only LiveView DAG explorer on top. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Workflow definition normalization | API / Backend | Database / Storage | Builder validation, cycle checks, duplicate-name rejection, and worker/input snapshots belong in backend code before any rows are inserted. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED] |
| Workflow graph persistence | Database / Storage | API / Backend | The persisted graph is the source of truth, so normalized rows and constraints own correctness after validation. [VERIFIED: .planning/phases/3-CONTEXT.md] |
| Step completion and child release | API / Backend | Database / Storage | Completion semantics must run as explicit transitions, while Postgres enforces idempotency and conflict handling. [VERIFIED: .planning/phases/3-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| PubSub acceleration | API / Backend | — | Coordinators subscribe and react, but they do not own truth; they only trigger re-checks and rapid release. [VERIFIED: .planning/phases/3-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |
| Result persistence and lookup | Database / Storage | API / Backend | Result references are durable workflow data, not transient process state or mutable context. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED] |
| Workflow index/detail UI | Frontend Server (SSR) | Browser / Client | The repo already uses server-rendered LiveView pages inside the native shell, with the browser only reflecting server state. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/web/engine_overview_live.ex] |
| Generic job inspection | Frontend Server (SSR) | Browser / Client | Generic job internals should remain in Oban Web via deep links instead of being rebuilt natively in Phase 3. [VERIFIED: .planning/phases/3-CONTEXT.md] [CITED: https://hexdocs.pm/oban_web/overview.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Oban | `2.22.1` (released 2026-04-30) | Job state machine, enqueueing, and execution | Phase 3 builds on canonical Oban job states and worker return semantics instead of replacing them. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban] [CITED: https://hexdocs.pm/oban/job_lifecycle.html] [CITED: https://hexdocs.pm/oban/Oban.Worker.html] |
| Ecto + Ecto SQL | locked `3.13.6` / `3.13.5`; current `3.14.0` released 2026-05-19 | Transactional state transitions and constraints | Existing repo code already uses `Ecto.Multi` for correctness-sensitive operations, and workflow release logic should follow that pattern. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: lib/oban_powertools/cron.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Phoenix.PubSub | `2.2.0` (released 2025-10-22) | Cross-node workflow release signaling | Official PubSub supports clustered topic broadcast and explicit pool sizing; it is the right accelerator while Postgres remains truth. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_pubsub] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |
| Phoenix LiveView | `1.1.30` (released 2026-05-05) | Native workflow index/detail UI | The repo already ships LiveView-backed native operator pages, making it the established UI tier for workflow read models. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: lib/oban_powertools/web/router.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban Web | `2.12.4` (released 2026-05-11) | Generic job drill-down and shared dashboard shell | Use as the destination for node-level job inspection from workflow pages rather than rebuilding a full generic job console. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban_web] [CITED: https://hexdocs.pm/oban_web/overview.html] |
| Igniter | `0.8.0` (released 2026-05-09) | Migrations and installer updates for new workflow tables/routes | Use when Phase 3 adds schema and route generation to host apps, consistent with existing package setup. [VERIFIED: mix.exs] [VERIFIED: mix hex.info igniter] |
| PostgreSQL | local `14.17` available | Durable source of truth for DAG state, results, and blocker evidence | The phase explicitly rejects Redis and in-memory truth; Postgres is the required consistency boundary. [VERIFIED: psql --version] [VERIFIED: .planning/phases/3-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One coordinator per node + DB idempotency | One process per workflow | Per-workflow processes create unnecessary lifecycle complexity and tempt in-memory ownership of workflow state. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED] |
| Separate workflow results table | Store outputs in `jobs.meta` or `workflow_context` | Reusing job/meta/context hides retention and size policy, and makes dependency explanations less explicit. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED] |
| Nested workflows as linked child workflow runs | Flatten all nested steps into one graph | Flattening makes validation, UI drill-down, and later repair semantics harder to reason about. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** `mix hex.info` verified `oban 2.22.1 (2026-04-30)`, `oban_web 2.12.4 (2026-05-11)`, `phoenix_pubsub 2.2.0 (2025-10-22)`, `phoenix_live_view 1.1.30 (2026-05-05)`, `ecto 3.13.6 / current 3.14.0 (2026-05-19)`, `ecto_sql 3.13.5 / current 3.14.0 (2026-05-19)`, and `igniter 0.8.0 (2026-05-09)`. [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info oban_web] [VERIFIED: mix hex.info phoenix_pubsub] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info igniter]

## Architecture Patterns

### System Architecture Diagram

```text
Builder API
  Workflow.new/add/connect/insert
        |
        v
Normalize + Validate
  - unique step names
  - dependency existence
  - acyclic graph
  - serializable worker/input snapshots
        |
        v
Ecto.Multi Insert Transaction
  workflows row
  -> workflow_nodes rows
  -> workflow_edges rows
  -> initial runnable node claims
        |
        v
Oban Jobs + Workflow Runtime Rows
  node state tracks queued/executing/completed/cancelled/blocker snapshots
        |
step completes / fails / cancels
        |
        v
Runtime Transition Transaction
  record result / outcome snapshot
  -> update node + workflow aggregate state
  -> release eligible children or cascade-cancel descendants
        |
        +--> durable event row or revision bump [ASSUMED]
        |
        v
Phoenix.PubSub Broadcast
  workflow:<id>
  workflows:index
        |
        +--> Workflow.Coordinator re-checks runnable children
        +--> LiveView pages refresh read models
```

All arrows above are one-way hints layered on top of persisted state; if a PubSub message is dropped, the next DB-driven reconciliation must still converge correctly. [VERIFIED: .planning/phases/3-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED]

### Recommended Project Structure
```text
lib/
├── oban_powertools/workflow.ex                    # Public builder/insert API
├── oban_powertools/workflow/definition.ex         # Persisted workflow run schema
├── oban_powertools/workflow/node.ex               # Persisted node definition + runtime state
├── oban_powertools/workflow/edge.ex               # Dependency edges + terminal policy
├── oban_powertools/workflow/result.ex             # Explicit persisted step outputs
├── oban_powertools/workflow/runtime.ex            # Completion/release/cascade transactions
├── oban_powertools/workflow/coordinator.ex        # PubSub subscriber and release accelerator
├── oban_powertools/workflow/explain.ex            # Workflow-specific blocker/read-model helpers
├── oban_powertools/web/workflows_live.ex          # Native workflow index
└── oban_powertools/web/workflow_live.ex           # Native workflow detail / DAG explorer
```
This mirrors the Phase 2 split between durable contracts, explicit runtime functions, and narrow native LiveView pages. [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/cron/entry.ex] [VERIFIED: lib/oban_powertools/web/router.ex] [ASSUMED]

### Pattern 1: Definition First, Runtime Second
**What:** Store a workflow run, its nodes, and its edges as normalized rows before any step progression logic exists. [VERIFIED: .planning/phases/3-CONTEXT.md]  
**When to use:** WF-01 implementation and every workflow insertion path. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.insert(:workflow, workflow_changeset)
|> Ecto.Multi.insert_all(:nodes, WorkflowNode, node_rows)
|> Ecto.Multi.insert_all(:edges, WorkflowEdge, edge_rows)
|> Repo.transact()
```
Use this pattern so the public builder remains a facade over one transactional normalization path, the same way `Idempotency` and `Cron` already route public calls into explicit transactions. [VERIFIED: lib/oban_powertools/idempotency.ex] [VERIFIED: lib/oban_powertools/cron.ex] [ASSUMED]

### Pattern 2: Completion Event After Commit, Not Before
**What:** Persist node/result/workflow state first, then broadcast a workflow event after the transaction succeeds. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED]  
**When to use:** WF-02 step completion, cascade cancellation, and workflow completion events. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html
case Repo.transact(multi) do
  {:ok, %{workflow: workflow, node: node}} ->
    Phoenix.PubSub.broadcast(MyApp.PubSub, "workflow:#{workflow.id}", {:step_completed, node.name})
    {:ok, workflow}

  error ->
    error
end
```
Publishing before commit risks subscribers reading stale dependency state and double-releasing children. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED]

### Pattern 3: Explicit Result Rows With Overflow States
**What:** Resolve `result(:step_name)` from a dedicated persisted result record instead of recursive job payloads, ambient context, or ad-hoc app queries. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED]  
**When to use:** WF-01 dataflow, WF-03 blocked-step explanations, and nested workflow drill-down. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**
```elixir
# Source inspiration: https://oban.pro/docs/pro/Oban.Pro.Workflow.html
%WorkflowResult{
  workflow_id: workflow.id,
  node_id: node.id,
  step_name: node.name,
  status: "present",
  value: %{external_id: "cus_123"},
  byte_size: 27
}
```
Official Oban Pro docs show that unrecorded dependencies surface as `nil`; Phase 3 should improve on that by storing explicit result status so missing, oversized, redacted, and absent results remain operator-visible. [CITED: https://oban.pro/docs/pro/Oban.Pro.Workflow.html] [ASSUMED]

### Anti-Patterns to Avoid
- **PubSub-owned truth:** Never treat message delivery as proof that a child step is runnable; only the DB release query decides that. [VERIFIED: .planning/phases/3-CONTEXT.md]
- **Mutable shared context:** Do not let steps overwrite `workflow_context`; keep it immutable and use results for cross-step dataflow. [VERIFIED: .planning/phases/3-CONTEXT.md]
- **Cross-graph arbitrary edges for nested workflows:** Parent workflow to child workflow should be modeled as explicit parent/child workflow linkage, not as edges that bypass workflow boundaries. [ASSUMED]
- **UI-driven repair semantics:** Do not sneak retry/cancel/skip/repair controls into the DAG page; that is explicitly Phase 4 scope. [VERIFIED: .planning/phases/3-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cluster message bus | Custom ETS/in-memory workflow dispatcher | Phoenix.PubSub | Official PubSub already provides clustered topic broadcast and documented sizing semantics. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |
| Multi-step atomic transitions | Ad-hoc nested `Repo` calls | `Ecto.Multi` / `Repo.transact` | The repo already uses this for correctness-sensitive operations, and Ecto documents it as the grouped-operations abstraction. [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/idempotency.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Generic job detail/admin screen | A second native jobs console | Oban Web deep links | Oban Web already provides dashboard activity logging and generic inspection surfaces. [CITED: https://hexdocs.pm/oban_web/overview.html] [VERIFIED: .planning/phases/3-CONTEXT.md] |
| Implicit result passing | Recursive payload composition | Named persisted result references | Explicit step-name lookup keeps DAG causality grep-able and operator-visible. [VERIFIED: .planning/phases/3-CONTEXT.md] |

**Key insight:** The hard part of Phase 3 is not drawing lines between nodes; it is making unblock and cancellation semantics survive retries, crashes, and cross-node races without drifting from Postgres truth. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED]

## Common Pitfalls

### Pitfall 1: Double Release on Concurrent Completion Handling
**What goes wrong:** The same child step is released twice when two nodes process the same completion or replay the same PubSub event. [ASSUMED]  
**Why it happens:** Release logic relies on process-local bookkeeping or assumes PubSub delivery is exactly once. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED]  
**How to avoid:** Make child release an idempotent SQL transition keyed by workflow/node state and dependency counts, with conflict-safe enqueueing. [VERIFIED: lib/oban_powertools/cron.ex] [ASSUMED]  
**Warning signs:** Duplicate child jobs, two audit rows for one unblock, or node state flipping from `queued` to `queued` again with new job ids. [ASSUMED]

### Pitfall 2: Publish-Before-Commit Races
**What goes wrong:** A coordinator or LiveView reacts to `step_completed` while the transaction that recorded the completion has not committed yet. [ASSUMED]  
**Why it happens:** Broadcast is performed inside or before the DB transaction boundary. [ASSUMED]  
**How to avoid:** Commit first, then broadcast, and always re-query durable state on the consumer side. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED]  
**Warning signs:** Subscribers cannot find the just-completed node, or they see parent status updated without result rows present. [ASSUMED]

### Pitfall 3: `nil` as a Result Semantics Dumpster
**What goes wrong:** Missing, failed, redacted, and oversized dependency outputs all collapse to `nil`, so operators cannot tell whether a child is blocked by data absence or by business failure. [VERIFIED: .planning/phases/3-CONTEXT.md] [CITED: https://oban.pro/docs/pro/Oban.Pro.Workflow.html]  
**Why it happens:** Result persistence is treated as optional sugar instead of a first-class workflow read model. [ASSUMED]  
**How to avoid:** Persist `result_status` (`present`, `absent`, `redacted`, `too_large`, `error`) and map each to an explicit blocker code. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED]  
**Warning signs:** UI shows “blocked” without naming which dependency result is missing, or app code reaches into external tables to infer workflow state. [ASSUMED]

### Pitfall 4: Oversized Result Storage
**What goes wrong:** Step outputs turn workflow tables into a document store, causing row bloat and expensive workflow detail queries. [VERIFIED: .planning/phases/3-CONTEXT.md] [VERIFIED: .planning/research/domain_competitors.md] [ASSUMED]  
**Why it happens:** Large payloads are persisted by default instead of being summarized or externalized. [ASSUMED]  
**How to avoid:** Cap persisted result payload size, store summary metadata plus external pointers when needed, and retain explicit overflow evidence. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED]  
**Warning signs:** Workflow detail queries pull megabytes of JSON, or LiveView updates become visibly slow on nested workflows. [ASSUMED]

### Pitfall 5: Unstable Realtime DAG Layout
**What goes wrong:** Every PubSub update reshuffles nodes, losing operator orientation while they are diagnosing a blocked workflow. [VERIFIED: .planning/phases/3-CONTEXT.md]  
**Why it happens:** Graph layout is recomputed from scratch on each render with no stable order key. [ASSUMED]  
**How to avoid:** Persist or derive a deterministic node order from insertion order and stable step names, and preserve selected node state across updates. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED]  
**Warning signs:** The selected node disappears on refresh, or a fan-out branch changes position after unrelated sibling updates. [ASSUMED]

## Code Examples

Verified patterns from official sources:

### PubSub Broadcast After Durable Transition
```elixir
# Source: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html
{:ok, _workflow} = Repo.transact(multi)
Phoenix.PubSub.broadcast(MyApp.PubSub, "workflow:123", {:workflow_event, "step_completed"})
```
Use the official topic broadcast primitive, but keep the consumer idempotent because PubSub is transport, not truth. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED]

### Ecto.Multi as the Transition Envelope
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.update(:node, node_changeset)
|> Ecto.Multi.insert(:result, result_changeset)
|> Ecto.Multi.run(:release, fn repo, changes -> release_children(repo, changes) end)
|> Repo.transact()
```
This is the same shape already used by `ObanPowertools.Cron` and `ObanPowertools.Idempotency`, which makes it the least surprising implementation posture for Phase 3. [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/idempotency.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Recursive task payload composition | Explicit persisted workflow rows and step-name result lookup | Current Phase 3 decision set, gathered 2026-05-19 | Better explainability, bounded result policy, and easier nested workflow drill-down. [VERIFIED: .planning/phases/3-CONTEXT.md] |
| In-memory orchestration truth | Postgres source of truth plus PubSub acceleration | Locked in project state before Phase 3 planning | Safer cross-node semantics and consistent operator evidence. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/phases/3-CONTEXT.md] |
| Full native job console ambition per feature | Hybrid shell with native Powertools pages plus Oban Web bridge | Established by Phase 0/2 direction | Phase 3 should invest in workflow-specific UX, not generic job admin duplication. [VERIFIED: .planning/STATE.md] [VERIFIED: lib/oban_powertools/web/router.ex] [CITED: https://hexdocs.pm/oban_web/overview.html] |

**Deprecated/outdated:**
- Macro-first workflow authoring in Phase 3: explicitly deferred in favor of builder APIs. [VERIFIED: .planning/phases/3-CONTEXT.md]
- Treating terminal dependency failure as indefinite blocked limbo: replaced by default cascade-cancel with narrow per-edge `:continue` overrides. [VERIFIED: .planning/phases/3-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Use a dedicated `workflow_results` table rather than reusing `jobs.meta` or only `workflow_context`. | Standard Stack / Architecture Patterns | Retention, redaction, and blocker explanations may need redesign late in implementation. |
| A2 | One supervised coordinator per node is the right initial topology for WF-02. | Summary / Standard Stack | A different topology could change supervision, PubSub topics, and testing strategy. |
| A3 | Nested workflows should be represented as child workflow runs linked by parent workflow id and parent step name, not flattened into one graph. | Summary / Common Pitfalls | UI and cancellation semantics could become more complex if the product later requires fully flattened graphs. |
| A4 | A bounded inline result policy with explicit overflow status is sufficient for Phase 3 without adding external blob storage. | Common Pitfalls / Open Questions | Large real-world workflow outputs may require an earlier storage abstraction. |

## Open Questions (RESOLVED)

Resolved on 2026-05-19 for planning purposes. These defaults are now part of the Phase 3 execution baseline unless implementation evidence forces a revisit.

1. **What is the default inline result size cap?**
   - Resolution: Use one package-level default cap with explicit overflow status in Phase 3, and defer per-step overrides.
   - Planning default: Treat the cap as a package-level workflow setting enforced uniformly across result rows so the storage model stays bounded and explainable. [ASSUMED]

2. **Should workflow events be persisted as a first-class table in Phase 3 or inferred from node/result/audit rows?**
   - Resolution: Do not add a dedicated `workflow_events` table in Phase 3.
   - Planning default: Use workflow/node revision fields plus normalized audit rows and durable result/snapshot records as the persisted event evidence, with PubSub carrying only transient acceleration signals. [ASSUMED]

3. **Should nested workflows be one-level only in UI for Phase 3?**
   - Resolution: Support recursive linkage in the data model, but keep the initial UI to one selected drill-down path at a time.
   - Planning default: The detail page should preserve stable selection and layout by expanding only the active subworkflow branch rather than rendering an unbounded recursive tree. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Workflow runtime, LiveView, tests | ✓ | 1.19.5 | — [VERIFIED: elixir --version] |
| Erlang/OTP | Oban/PubSub runtime | ✓ | 28 | — [VERIFIED: erl system_info otp_release] |
| PostgreSQL server | Postgres source-of-truth workflow tables | ✓ | 14.17 and accepting connections | None; blocking if absent. [VERIFIED: postgres --version] [VERIFIED: pg_isready] |
| `psql` CLI | Schema/debug verification during execution | ✓ | 14.17 | Use Ecto SQL queries if needed. [VERIFIED: psql --version] |
| Phoenix/LiveView deps | Native workflow UI | ✓ | Phoenix 1.8.7, LiveView 1.1.30 | None for WF-03. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: current shell probes]

**Missing dependencies with fallback:**
- None. [VERIFIED: current shell probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5. [VERIFIED: test/test_helper.exs] [VERIFIED: mix --version] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/oban_powertools/cron_test.exs test/oban_powertools/explain_test.exs`. [VERIFIED: test/oban_powertools/cron_test.exs] [VERIFIED: test/oban_powertools/explain_test.exs] |
| Full suite command | `mix test`. [VERIFIED: repo test layout] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WF-01 | Valid workflow insertion rejects cycles/duplicate names and persists normalized workflow/node/edge rows. | unit + integration | `mix test test/oban_powertools/workflow_test.exs -x` | ❌ Wave 0 [ASSUMED] |
| WF-02 | Completing a node releases eligible children once and only once, with PubSub acceleration but DB-safe fallback. | integration | `mix test test/oban_powertools/workflow_runtime_test.exs -x` | ❌ Wave 0 [ASSUMED] |
| WF-03 | Workflow detail/index pages highlight blocked nodes, preserve selection state, and deep-link to Oban Web. | LiveView | `mix test test/oban_powertools/web/live/workflows_live_test.exs -x` | ❌ Wave 0 [ASSUMED] |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/workflow_test.exs test/oban_powertools/workflow_runtime_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/oban_powertools/workflow_test.exs` — builder normalization, insertion, and graph validation for WF-01. [ASSUMED]
- [ ] `test/oban_powertools/workflow_runtime_test.exs` — completion, release, cascade-cancel, and nested workflow semantics for WF-02. [ASSUMED]
- [ ] `test/oban_powertools/web/live/workflows_live_test.exs` — blocked-step highlighting and stable LiveView updates for WF-03. [ASSUMED]
- [ ] Shared workflow fixtures under `test/support/` — canonical DAG factories and helper assertions. [ASSUMED]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse the host-owned `ObanPowertools.Auth` page/action gate already used by native pages. [VERIFIED: .planning/STATE.md] [VERIFIED: lib/oban_powertools/web/engine_overview_live.ex] |
| V3 Session Management | yes | Inherit Phoenix/host app session handling; do not introduce parallel workflow session state. [VERIFIED: lib/oban_powertools/web/router.ex] [ASSUMED] |
| V4 Access Control | yes | Keep workflow pages read-only in Phase 3 and deep-link mutating generic actions into existing guarded surfaces. [VERIFIED: .planning/phases/3-CONTEXT.md] |
| V5 Input Validation | yes | Validate workflow definitions with changesets plus graph checks before insert, and validate step-result lookups by stable step name. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [ASSUMED] |
| V6 Cryptography | no | No new cryptographic primitive is required for DAG/signaling logic; do not hand-roll payload encryption here. [ASSUMED] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged or accidental operator access to workflow detail pages | Elevation of Privilege | Route and action authorization through the existing auth behavior on every native page. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/web/engine_overview_live.ex] |
| Oversized or sensitive step outputs exposed in UI | Information Disclosure / DoS | Enforce size/redaction limits in persisted result rows and render summaries by default. [VERIFIED: .planning/phases/3-CONTEXT.md] [ASSUMED] |
| Race-driven duplicate child enqueue | Tampering / DoS | Make release transitions idempotent in SQL and keep PubSub as a post-commit hint only. [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] [ASSUMED] |
| Mutable shared workflow context abused as hidden state channel | Tampering | Keep `workflow_context` immutable and pass cross-step data only through persisted results. [VERIFIED: .planning/phases/3-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html` - broadcast semantics, pool sizing, and safe migration guidance.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transaction grouping semantics for multi-step DB transitions.
- `https://hexdocs.pm/oban/job_lifecycle.html` - canonical Oban job states and terminal transitions.
- `https://hexdocs.pm/oban/Oban.Worker.html` - worker return values for `:ok`, `{:cancel, reason}`, `{:error, reason}`, and `{:snooze, period}`.
- `https://hexdocs.pm/oban_web/overview.html` - Oban Web action logging and dashboard role.
- `.planning/phases/3-CONTEXT.md` - locked Phase 3 architecture and non-goals.
- `lib/oban_powertools/cron.ex`, `lib/oban_powertools/idempotency.ex`, `lib/oban_powertools/web/router.ex` - established repo patterns for durable state transitions and native shell routing.

### Secondary (MEDIUM confidence)
- `https://oban.pro/docs/pro/Oban.Pro.Workflow.html` - current public workflow API concepts, recorded-output semantics, and nested workflow examples used as product-shape reference only.
- `https://oban.pro/docs/pro/Oban.Pro.Relay.html` - PubSub-backed distributed result delivery used to confirm the project’s “PubSub as accelerator, not truth” direction.
- `.planning/research/domain_competitors.md` - competitor footguns already synthesized for this project.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and APIs were verified against `mix.lock`, `mix hex.info`, and official docs.
- Architecture: MEDIUM - subsystem boundaries fit locked project decisions and repo patterns, but some schema/runtime details remain design recommendations.
- Pitfalls: MEDIUM - main failure modes are strongly supported by project context and official docs, but some exact failure signatures are inferred from distributed-systems behavior.

**Research date:** 2026-05-19  
**Valid until:** 2026-06-18 for repo-local planning; re-check package/doc versions if implementation starts after that date.
