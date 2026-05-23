# Architecture Patterns

**Domain:** Oban Powertools v1.2 workflow semantics and recovery
**Researched:** 2026-05-23
**Confidence:** HIGH

## Recommended Architecture

Keep the existing architecture shape: Postgres is the source of truth, Ecto transactions own state transitions, PubSub remains only a hint, LiveView reads durable state, and Lifeline projects incidents from durable evidence. Do **not** introduce a second orchestrator, in-memory wait registry, or external coordination plane.

The right change is to split the current workflow runtime into two layers:

1. **Workflow command layer** for explicit operator/runtime intents such as complete, signal, await, cancel, expire, and recover.
2. **Workflow semantics layer** for deterministic reconciliation that derives the next durable state for workflows and steps from rows already stored in Postgres.

That preserves the current DB-first model while making new semantics composable and repair-safe.

### Recommended Structure

```text
Host code / workers / operator actions
        |
        v
Workflow Commands
  - complete_step
  - register_await
  - deliver_signal
  - request_cancel
  - expire_due_workflows
  - recover_workflow
        |
        v
Ecto.Multi transaction
  - append durable facts
  - mutate target rows
  - append callback/outbox rows
  - reconcile workflow
        |
        v
Workflow Semantics Engine
  - derive step/workflow states
  - derive blocker codes
  - derive callback emissions
  - derive stuck/orphan/expired diagnoses
        |
        +--> PubSub hint to coordinator + LiveView
        +--> Lifeline incident projection
        +--> Callback dispatcher worker
```

## Existing Baseline To Preserve

These current properties should remain unchanged:

| Existing Component | Keep | Why |
|-----------|------|-----|
| `ObanPowertools.Workflow.Runtime` DB-first reconciliation | Yes | Current tests already prove correctness without PubSub follow-up. |
| `ObanPowertools.Workflow.Coordinator` PubSub hint model | Yes | Good for latency, but must stay non-authoritative. |
| Persisted `workflows`, `steps`, `edges`, `results` tables | Yes | They already hold durable DAG truth and operator evidence. |
| `ObanPowertools.Explain.workflow_step/3` | Yes, extend | Existing blocker vocabulary is the right read model seam. |
| `ObanPowertools.Lifeline` preview/reason/audit repair flow | Yes, extend | New workflow semantics should plug into the same preview/drift/audit contract. |
| LiveView workflow inspection | Yes, extend | Operators need the new states and diagnoses surfaced natively. |

## New Vs Modified Components

### Modified Components

| Component | Change |
|-----------|--------|
| `ObanPowertools.Workflow` | Builder/API grows explicit contracts for callbacks, await definitions, cancellation policy, and expiry policy. |
| `ObanPowertools.Workflow.Runtime` | Stop being only `complete_step`; become the transaction shell that calls a pure semantics planner and persists the resulting transitions. |
| `ObanPowertools.Workflow.Signal` | Expand from simple PubSub events into a typed internal event vocabulary for `signal_received`, `await_registered`, `workflow_cancel_requested`, `workflow_expired`, `workflow_recovered`, and callback dispatch events. |
| `ObanPowertools.Explain` | Add diagnosis categories for signal waits, missing signals, expired waits, cancellation propagation, missing backing jobs, and orphaned execution. |
| `ObanPowertools.Lifeline` | Project workflow-specific incidents from semantics evidence rather than only `pending + blocker_codes != []`; repair previews must understand workflow recover/reconcile/cancel actions. |
| `ObanPowertools.Web.WorkflowsLive` | Show wait contracts, signal history, terminal reasons, cancellation source, expiry status, recovery actions, and callback delivery status. |
| `ObanPowertools.Application` | Add only minimal new supervised processes: callback dispatcher and optional expiry/recovery sweeper. |

### New Components

| Component | Responsibility | Why It Should Exist |
|-----------|----------------|---------------------|
| `ObanPowertools.Workflow.Commands` | Public intent API: `complete_step`, `await_step`, `signal_workflow`, `cancel_workflow`, `expire_due`, `recover_workflow`, `reconcile_workflow`. | Separates caller intent from state derivation. |
| `ObanPowertools.Workflow.Semantics` | Pure transition planner from persisted rows to next states, blocker codes, and emitted workflow events. | Keeps the rules testable and deterministic. |
| `ObanPowertools.Workflow.Callback` schema + dispatcher | Durable callback/outbox rows and retriable delivery. | Callbacks must survive crashes and avoid inline host-code execution in DB transactions. |
| `ObanPowertools.Workflow.Await` schema | Durable wait contracts keyed by workflow/step/signal name/correlation. | Signal delivery must work whether the signal arrives before or after the step begins waiting. |
| `ObanPowertools.Workflow.SignalEvent` schema | Append-only durable signal inbox. | External signals are facts, not transient PubSub messages. |
| `ObanPowertools.Workflow.Recovery` | Recovery planning for dead/stuck/orphaned graph situations. | Keeps Lifeline repair mutations separate from diagnosis logic. |

## Persistence / Model Changes

The milestone needs new durable facts, not just more string states.

### Modify Existing Tables

| Table | Recommended Additions | Purpose |
|-------|------------------------|---------|
| `oban_powertools_workflows` | `terminal_reason`, `terminal_details`, `cancel_requested_at`, `cancelled_by`, `expires_at`, `expired_at`, `recovered_at`, `last_reconciled_at`, `diagnosis_status` | Workflow-level contracts and operator-visible terminal truth. |
| `oban_powertools_workflow_steps` | `await_state`, `await_key`, `await_expires_at`, `wait_started_at`, `terminal_reason`, `terminal_details`, `last_job_state`, `last_job_checked_at` | Separate dependency waiting from signal waiting and from job/runtime drift. |
| `oban_powertools_workflow_edges` | `policy_details` or richer edge policy metadata | Supports future policy growth without a second migration for every new rule. |
| `oban_powertools_workflow_results` | `result_kind`, `source`, `signal_event_id`, `expires_reason` | Distinguishes worker results from signal-derived resumptions or expiry outcomes. |

### Add New Tables

| Table | Core Fields | Purpose |
|-------|-------------|---------|
| `oban_powertools_workflow_awaits` | `workflow_id`, `step_id`, `signal_name`, `correlation_key`, `status`, `registered_at`, `satisfied_at`, `expires_at`, `payload_contract`, `diagnosis_snapshot` | Durable wait registration and timeout basis. |
| `oban_powertools_workflow_signal_events` | `workflow_id`, `signal_name`, `correlation_key`, `payload`, `payload_bytes`, `recorded_at`, `consumed_at`, `status` | Append-only signal inbox with replay/recovery support. |
| `oban_powertools_workflow_callbacks` | `workflow_id`, `step_id`, `event_kind`, `payload`, `status`, `attempt`, `scheduled_at`, `delivered_at`, `last_error` | Durable callback outbox and recovery queue. |

### State Model Recommendation

Do not overload current `pending` to mean every kind of waiting.

Recommended workflow states:

`pending | available | running | waiting | cancelling | cancelled | completed | failed | expired | recovering`

Recommended step states:

`pending | available | executing | waiting_signal | waiting_retry | cancelled | completed | failed | expired`

Use blocker codes and terminal reasons to explain the state, not ad hoc UI strings:

- `waiting_on_dependencies`
- `waiting_on_retryable_dependency`
- `waiting_on_signal`
- `signal_expired`
- `cancel_requested`
- `cancelled_by_dependency`
- `expired_by_contract`
- `job_missing_for_executing_step`
- `job_state_mismatch`
- `orphaned_executor`

## Data Flow

### 1. Step Completion / Retry / Failure

1. Worker or runtime calls `Workflow.Commands.complete_step/4`.
2. Command transaction writes result evidence and step terminal/update facts.
3. `Workflow.Semantics` recomputes descendant readiness, cancellation propagation, callback emissions, and workflow summary state.
4. Transaction persists those changes atomically.
5. PubSub broadcasts a hint for LiveView and the coordinator.
6. Callback dispatcher picks up any newly ready callback rows.

Recommendation: callback emission should be derived from transition edges such as `step -> completed`, `workflow -> failed`, not from ad hoc code branches.

### 2. Signal / Await

1. A step enters a wait contract by writing a row to `workflow_awaits` and moving to `waiting_signal`.
2. Any external signal is inserted into `workflow_signal_events`, even if no await exists yet.
3. Reconciliation matches pending awaits to stored signals by `workflow_id + signal_name + correlation_key`.
4. Matching a signal marks the await satisfied, persists a signal-derived result or state update, and transitions the step back into `available` or `completed`, depending on the contract.
5. Timeout processing moves expired awaits to `expired` or `cancelled`, based on the declared expiry policy.

Recommendation: signals should be durable facts first, PubSub notifications second.

### 3. Cancellation / Expiry

1. Operator/runtime issues `cancel_workflow` or a sweeper finds `expires_at <= now`.
2. Command writes workflow-level cancellation or expiry intent first.
3. Semantics propagates intent to runnable/waiting/executing steps.
4. If a step has a backing Oban job in a cancellable state, use Oban cancellation APIs; otherwise durable step state still advances so workflow truth is explicit.
5. Reconciliation appends callback rows for `workflow_cancelled` or `workflow_expired`.
6. Lifeline can still repair or explain any residual drift between step truth and job truth.

This matches current Oban behavior: cancellable jobs are `executing`, `available`, `scheduled`, or `retryable`, and worker-returned `{:cancel, reason}` lands in `cancelled` while `{:error, reason}` becomes `retryable` or `discarded` depending on attempts. Sources: Oban `Oban` and `Oban.Worker` docs, v2.22.1.

### 4. Recovery / Stuck Graph Diagnosis

1. `Workflow.Semantics` derives diagnosis facts from durable rows: dependency waits, signal waits, expired waits, missing jobs, executor loss, callback delivery failure.
2. `ObanPowertools.Explain` exposes the same diagnosis vocabulary to UI and programmatic callers.
3. `ObanPowertools.Lifeline.project_incidents/2` consumes those facts and opens incidents with explicit classes:
   - `workflow_waiting_signal`
   - `workflow_signal_expired`
   - `workflow_orphaned_execution`
   - `workflow_callback_failed`
   - `workflow_cancel_stalled`
4. Repair preview uses the same existing preview/reason/drift/audit model.
5. Recovery actions should be explicit commands such as `reconcile_workflow`, `requeue_callback`, `replay_signal`, `cancel_workflow`, `force_expire_workflow`, not raw row edits.

Recommendation: diagnosis should move from “blocked means stuck” to “derive a precise incident class from durable evidence”.

## Patterns To Follow

### Pattern 1: Facts First, Projection Second

**What:** Write immutable facts such as signal arrival, callback intent, cancel request, and await registration before mutating summary state.

**When:** Any action that must survive crashes, duplicate delivery, or operator retries.

**Why:** Recovery becomes replaying facts through reconciliation rather than guessing prior intent from current rows.

### Pattern 2: Pure Semantics Planner

**What:** Put state derivation in a pure module that accepts workflow rows, await rows, signal rows, and job snapshots and returns desired mutations.

**When:** Workflow state depends on multiple durable sources and new rules will keep arriving.

**Why:** This prevents `Runtime`, `Lifeline`, and LiveView from each re-implementing the same rules.

### Pattern 3: Durable Callback Outbox

**What:** Model callbacks as rows plus a dispatcher worker, not inline host callbacks inside transactions.

**When:** Workflow completion, failure, expiry, recovery, and signal satisfaction need host-visible hooks.

**Why:** Inline callbacks are not runtime-safe, not replayable, and not auditable enough for this package.

### Pattern 4: Explainability Shares The Same Vocabulary As Recovery

**What:** The blocker codes shown in UI should be the same codes Lifeline uses for incident classification and repair previews.

**When:** Any new wait or terminal mode is added.

**Why:** Prevents the current split where UI says “blocked” while repair logic guesses why.

## Anti-Patterns To Avoid

### Anti-Pattern 1: Using PubSub As Signal Storage

**What:** Treating PubSub events as the only carrier for workflow signals or callback delivery.

**Why bad:** Missed messages become lost workflow facts.

**Instead:** Persist signal and callback rows first, then broadcast hints.

### Anti-Pattern 2: Overloading `pending`

**What:** Reusing one state for dependency waits, external signal waits, expiry hold, and cancellation stall.

**Why bad:** Diagnosis, repair, and UI all become ambiguous.

**Instead:** Keep state coarse but use dedicated wait/terminal columns plus blocker codes.

### Anti-Pattern 3: Direct Row Mutation From Lifeline

**What:** Letting repair code update step/workflow rows without going through workflow commands.

**Why bad:** Recovery bypasses callback emission, audit consistency, and semantic recomputation.

**Instead:** Lifeline should call command APIs that re-enter the same transaction + semantics pipeline.

### Anti-Pattern 4: Callback Execution Inside State Transaction

**What:** Calling host code while holding DB transaction state for workflow completion.

**Why bad:** Increases lock time, couples host failures to core workflow truth, and makes recovery unclear.

**Instead:** Commit workflow truth first, then dispatch callbacks from durable outbox rows.

## Scalability Considerations

| Concern | At 100 workflows | At 10K workflows | At 1M workflows |
|---------|------------------|------------------|-----------------|
| Reconciliation cost | Full-graph reload is acceptable | Reconcile only affected workflow and changed await/signal rows | Need targeted queries, batched sweeps, and possibly per-workflow versioning to avoid repeated full scans |
| Signal volume | Append-only inbox is cheap | Need indexes on `workflow_id`, `signal_name`, `correlation_key`, `status` | Add retention/pruning and partitioning strategy for signal/callback history |
| Callback retries | Simple worker polling is enough | Need backoff and dedupe guards | Need explicit retention and dead-letter visibility |
| Diagnosis sweeps | Inline checks acceptable | Add periodic sweeper for expiry/callback failures | Make diagnosis incremental and driven by due rows instead of global scans |

## Sensible Build Order

1. **Semantics foundation**
   - Add `Workflow.Commands` and `Workflow.Semantics`.
   - Refactor `Workflow.Runtime` to use them without changing public behavior yet.
   - Goal: one place to compute transitions before new contracts arrive.

2. **Persistence contract expansion**
   - Add workflow/step columns for terminal reason, cancellation, expiry, and reconciliation timestamps.
   - Add `workflow_awaits`, `workflow_signal_events`, and `workflow_callbacks`.
   - Goal: durable facts exist before any new feature depends on them.

3. **Signal/await semantics**
   - Implement await registration, signal delivery, and matcher reconciliation.
   - Extend explainability with `waiting_on_signal` and timeout diagnosis.
   - Goal: external coordination works even across crashes and reorderings.

4. **Cancellation and expiry**
   - Add command APIs, propagation rules, and optional due-work sweeper.
   - Integrate with Oban cancellation where backing jobs exist.
   - Goal: explicit terminal contracts and predictable operator behavior.

5. **Callback outbox and recovery**
   - Emit callback rows from state transitions.
   - Add dispatcher worker and retry/requeue semantics.
   - Goal: host-visible completion/recovery hooks without unsafe inline execution.

6. **Stuck-graph diagnosis and Lifeline integration**
   - Upgrade incident projection from generic blocked-state checks to precise workflow incident classes.
   - Route repair previews through command APIs.
   - Goal: recovery actions stay runtime-safe and semantically complete.

7. **Operator surfaces**
   - Extend `WorkflowsLive` and Lifeline UI with wait/signal/cancel/expiry/callback visibility and audited actions.
   - Goal: explain, then act.

## Sources

- Local code:
  - `lib/oban_powertools/workflow.ex`
  - `lib/oban_powertools/workflow/runtime.ex`
  - `lib/oban_powertools/workflow/coordinator.ex`
  - `lib/oban_powertools/workflow/signal.ex`
  - `lib/oban_powertools/explain.ex`
  - `lib/oban_powertools/lifeline.ex`
  - `lib/oban_powertools/web/workflows_live.ex`
  - `guides/workflows.md`
  - `.planning/PROJECT.md`
  - `.planning/MILESTONE-ARC.md`
- Official docs:
  - Oban v2.22.1 `Oban.Worker`: https://hexdocs.pm/oban/Oban.Worker.html
  - Oban v2.22.1 `Oban`: https://hexdocs.pm/oban/Oban.html
  - Oban v2.22.1 Job Lifecycle: https://hexdocs.pm/oban/job_lifecycle.html
