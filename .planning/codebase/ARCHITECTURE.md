<!-- refreshed: 2024-05-24 -->
# Architecture

**Analysis Date:** 2024-05-24

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                      Operator Console UI                     │
├──────────────────┬──────────────────┬───────────────────────┤
│   LifelineLive   │   BatchesLive    │    WorkflowsLive      │
│ `web/lifeline*`  │ `web/batches*`   │   `web/workflows*`    │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                    │
         ▼                  ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                      Core Domains                            │
│  `lib/oban_powertools/batch.ex`, `chain.ex`, `workflow.ex`   │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                 Plugin & Callback System                     │
│ `lib/oban_powertools/plugin/callback_dispatcher.ex`          │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                 Data Store (Ecto & Oban)                     │
│    `oban_powertools_batches`, `callbacks`, `batch_jobs`      │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| `Batch` | Durable batch tracking schema and enqueueing logic | `lib/oban_powertools/batch.ex` |
| `Batch.Tracker` | Exactly-once batch progress tracking | `lib/oban_powertools/batch/tracker.ex` |
| `Chain` | Public builder API for strictly linear job chains | `lib/oban_powertools/chain.ex` |
| `Plugin.CallbackDispatcher`| Periodically polls callbacks table to dispatch system events safely | `lib/oban_powertools/plugin/callback_dispatcher.ex` |
| `Web.Router` | Mounts native Powertools route tree in host-owned browser scope | `lib/oban_powertools/web/router.ex` |
| `Lifeline` | Audited UI mutations for bulk actions and repairs | `lib/oban_powertools/lifeline.ex` |
| `ObanWebBridge` | Optional bridge connecting to Oban Pro dashboard | `lib/oban_powertools/web/oban_web_bridge.ex` |

## Pattern Overview

**Overall:** Event-Driven Generalized Callback Outbox

**Key Characteristics:**
- **Decoupled Orchestration**: Avoids bloating the Oban jobs table by handling batch and chain states in native Ecto tables (`oban_powertools_batches`, `oban_powertools_callbacks`).
- **Exactly-Once Accounting**: Uses row locks and tracking schemas to ensure callbacks are only fired once a deterministic state is reached.
- **Audited UI Mutations**: Routes UI-driven lifecycle repairs (e.g., retries) through `Lifeline`.

## Layers

**UI Layer:**
- Purpose: Operator dashboard for managing batches, crons, limitations, jobs, and workflows.
- Location: `lib/oban_powertools/web/`
- Contains: LiveViews, Route macros, and Read-Model structures.
- Depends on: Core domain logic (Batch, Chain, Lifeline).
- Used by: Host application's router scope.

**Core Domains Layer:**
- Purpose: Logic defining system primitives such as `Batch` streams, `Chain` builders, and `Lifeline` repairs.
- Location: `lib/oban_powertools/`
- Contains: Ecto Schemas, Context models, business logic.
- Depends on: Ecto.Multi, Callback mechanisms, Oban.

**Plugin Layer:**
- Purpose: Deterministic background polling to orchestrate long-running asynchronous workflows.
- Location: `lib/oban_powertools/plugin/`
- Contains: Oban plugin implementations (e.g., `CallbackDispatcher`).
- Depends on: Callbacks database schema and domain dispatchers.

## Data Flow

### Primary Request Path (Batch Progression)

1. Worker handles job completion. (`Oban.Worker` execution)
2. Tracker records progress transactionally. (`lib/oban_powertools/batch/tracker.ex`)
3. Increments `batch.success_count` and checks completion logic. (`lib/oban_powertools/batch/tracker.ex`)
4. Upon meeting total threshold, inserts a `batch.completed` or `batch.exhausted` callback. (`lib/oban_powertools/batch/tracker.ex`)
5. Plugin polls, claims the callback, and dispatches it. (`lib/oban_powertools/plugin/callback_dispatcher.ex`)

### Chain Execution Flow

1. Initial job in chain successfully finishes. (`Oban.Worker`)
2. Tracker sees chain meta, inserts `chain.step_succeeded` callback. (`lib/oban_powertools/batch/tracker.ex`)
3. Callback dispatcher polls and routes it to `Chain.Progression`. (`lib/oban_powertools/plugin/callback_dispatcher.ex`)
4. Next chain step is assembled with builder arguments and pushed to Oban. (`lib/oban_powertools/chain/progression.ex`)

**State Management:**
- Relies heavily on DB-level counters and `Ecto.Multi` for transactional atomic state updates to guard against concurrent worker executions.

## Key Abstractions

**Callback Outbox:**
- Purpose: A generalized outbox that safely isolates workflow completion events from individual Oban job transaction lines.
- Examples: `lib/oban_powertools/plugin/callback_dispatcher.ex`
- Pattern: Transactional Outbox.

**Exactly-Once Tracking:**
- Purpose: Avoid double-counting job resolutions by enforcing uniqueness through intermediate `BatchJob` structures before tallying `Batch` totals.
- Examples: `lib/oban_powertools/batch/tracker.ex`
- Pattern: Concurrency Guard / Idempotency Key.

## Entry Points

**Web Router:**
- Location: `lib/oban_powertools/web/router.ex`
- Triggers: HTTP/Websocket requests to `/ops/jobs`
- Responsibilities: Mounts nested read-only and Native UI mutation points.

**CallbackDispatcher Plugin:**
- Location: `lib/oban_powertools/plugin/callback_dispatcher.ex`
- Triggers: Periodically triggered by GenServer `:poll` timeout
- Responsibilities: Collects DB-level workflow events and routes to domains safely.

## Architectural Constraints

- **Threading:** Uses `GenServer` for background plugin operations; standard BEAM processes for Phoenix requests.
- **Global state:** Driven purely via database tables; minimal process state to support easy scaling of nodes.
- **Host Boundaries:** The Web UI strictly honors the separation between native powertools pages (mutations) and the optional Oban Pro bridge (read-only views).

## Anti-Patterns

### Modifying Base Oban Tables Heavily
**What happens:** Attaching deeply nested chain structures into a single Oban job's `meta` or using DAGs directly on Oban.
**Why it's wrong:** Bloats job rows, destroys searchability, and introduces significant serialization overhead.
**Do this instead:** Use `ObanPowertools.Chain` and `ObanPowertools.Batch` to abstract orchestration relationships into isolated, optimized tables.

### Non-Audited Operations in UI
**What happens:** Bypassing `Lifeline` to call Oban direct cancellation/retry from standard Web components.
**Why it's wrong:** Bypasses authorization, audit logs, and dry-run expectations required by the system.
**Do this instead:** Route all operator actions through `ObanPowertools.Lifeline` execution and auditing channels.

## Error Handling

**Strategy:** Eventual consistency via retries on callbacks.

**Patterns:**
- Unhandled callback dispatch errors update the database `status` to `"failed"` and set `available_at` in the future for a safe retry loop.

## Cross-Cutting Concerns

**Logging:** Integrated via `telemetry.span` in plugins and operations.
**Validation:** Leverages strict `Ecto.Changeset` validation on inputs.
**Authentication:** Delegated to the Host application's pipeline via shared `LiveAuth` mapping.

---

*Architecture analysis: 2024-05-24*