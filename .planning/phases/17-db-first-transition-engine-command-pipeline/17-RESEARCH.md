# Phase 17: DB-First Transition Engine & Command Pipeline - Research

**Researched:** 2026-05-23
**Domain:** Legal workflow mutation routing, durable rejection evidence, operator/runtime command parity, and compatibility-safe transition enforcement.
**Confidence:** HIGH [VERIFIED: repo-local code, tests, roadmap, and prior phase artifacts]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Keep `ObanPowertools.Workflow.*` as the stable public API while introducing one internal DB-first legality engine under it. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]
- Runtime and operator paths must share the same legal mutation core, but operator-only auth, preview, reason, and audit concerns stay outside that core. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]
- Unsupported or ambiguous mutations must return structured errors immediately and also persist durable rejection evidence in Postgres-backed truth. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]
- Legacy rows with `semantics_version < 2` must not be silently upgraded or reinterpreted during ordinary mutations; only a short explicit compatibility adapter set is allowed if truly necessary. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]
- Callback/signal/late-arrival/richer recovery semantics remain deferred unless this phase needs thin reserved seams to keep the mutation core coherent. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]

### the agent's Discretion
- Exact internal module split between command intake, legality evaluation, transition planning, and mutation-attempt persistence, provided callers still hit one DB-first path.
- Exact schema shape for durable rejection evidence, provided it is queryable, bounded, and separate from human audit-only evidence.
- Exact reason-code vocabulary, provided it stays low-cardinality and actionable for operators and maintainers.

### Deferred Ideas (OUT OF SCOPE)
- Public generic command DSL or exported `Ecto.Multi` builders.
- Full callback-outbox ownership for all workflow events.
- Full signal/await precedence expansion beyond making late and expired paths explicit.
- Silent automatic upgrade-through-mutation for legacy rows.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `WFS-02` | Runtime and operator mutations can only move workflows through documented legal transitions that are recomputed from Postgres-backed truth rather than transient PubSub state. | `Workflow.Runtime` already recomputes step/workflow state from rows, but every caller still reaches that logic through ad hoc function-specific code instead of one explicit legality engine. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; test/oban_powertools/workflow_coordinator_test.exs] |
| `REC-02` | An operator or runtime can request scoped workflow recovery without silently re-running already successful side-effecting steps, and the new attempt evidence remains durable and auditable. | Current recovery is step-scoped only via `recover_step/5`, persists `RecoveryAttempt`, and is reused by Lifeline repairs; Phase 17 needs to widen the legal mutation path without losing that durable-attempt posture. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/lifeline.ex; test/oban_powertools/workflow_runtime_test.exs] |
| `REC-03` | Workflow cancellation is cooperative and explicit: operators can see request versus final outcome, and late step completion after a cancel request is preserved as durable evidence instead of hidden. | The current runtime already preserves `cancel_requested_at` and `completed_after_cancel_request`, but the legality and rejection contract around cancel-adjacent mutations is still implicit. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; test/oban_powertools/workflow_runtime_test.exs] |
| `SIG-03` | Expiry and late-arrival policy is explicit: a maintainer can tell whether an overdue wait failed, cancelled downstream work, remained recoverable, or ignored late signals by contract. | `Await` and `SignalRecord` already persist waiting, resolved, expired, consumed, and late states; Phase 17 should formalize when those transitions are legal versus rejected or deferred. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/await.ex; lib/oban_powertools/workflow/signal_record.ex; test/oban_powertools/workflow_runtime_test.exs] |
| `DIA-01` | A workflow screen can explain durable cause classes such as `waiting_on_signal`, `waiting_on_retryable_dependency`, `missing_dependency_result`, `orphaned_executor`, `cancel_requested`, and `expired_wait` without requiring direct database inspection. | `workflow_diagnosis/2` and `step_diagnosis/1` already expose part of this vocabulary, and `WorkflowsLive` renders it, but Lifeline and workflow mutations do not yet share one explicit rejection/diagnosis contract. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/web/workflows_live.ex; test/oban_powertools/web/live/workflows_live_test.exs] |
| `DIA-02` | Lifeline and workflow inspection surfaces consume the same workflow diagnosis vocabulary and expose only bounded, audited recovery actions that re-enter the workflow command pipeline. | Lifeline currently repairs jobs and workflow steps through previewed actions, but workflow-level mutation actions and rejection evidence are not yet projected through the same command vocabulary. [VERIFIED: lib/oban_powertools/lifeline.ex; lib/oban_powertools/web/workflows_live.ex; test/oban_powertools/lifeline_test.exs] |
| `VER-01` | The repo proves duplicate, late, dropped, and race-path workflow events with automated fixtures covering signal replay, cancel-versus-complete races, expiry, and lost wakeup reconciliation. | The current test suite already covers duplicate PubSub hints, pre-await signals, expired waits, and cancel-versus-complete races; Phase 17 needs to extend that proof to illegal or rejected command attempts and caller parity. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs; test/oban_powertools/workflow_coordinator_test.exs] |
| `VER-02` | A maintainer can upgrade hosts with in-flight waiting, retrying, cancelling, or recovering workflows without breaking semantics or leaving support unable to explain stored state. | Phase 16 locked semantics versioning and compatibility posture; Phase 17 must carry that through new transition-entry artifacts, installer migrations, and compatibility tests so hosts can adopt the new legal path without rewriting old rows in place. [VERIFIED: .planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md; lib/mix/tasks/oban_powertools.install.ex; examples/phoenix_host/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs] |
</phase_requirements>

## Summary

Phase 17 should be planned as a caller-unification and truth-hardening phase, not as a brand new workflow subsystem. The repo already has most of the durable pieces: persisted workflow/step rows, `Await`, `SignalRecord`, `RecoveryAttempt`, `CallbackOutbox`, DB-first reconciliation, diagnosis helpers, and step-level Lifeline repair hooks. The missing layer is an explicit internal command pipeline that all mutation callers must pass through, with one legality matrix and one durable rejection record instead of mutating rows from several specialized entrypoints. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/lifeline.ex; test/oban_powertools/workflow_runtime_test.exs]

The highest-value architectural move is to split current `Workflow.Runtime` responsibilities into four bounded concerns:
1. caller-facing intent wrappers that keep `Workflow.*` stable,
2. a legality evaluator / transition planner for workflow and step mutations,
3. one transaction shell that writes durable mutation facts plus row updates,
4. shared diagnosis and rejection vocabulary consumed by both Lifeline and `WorkflowsLive`.

That sequencing preserves the current DB-first design while making unsupported or ambiguous mutations explicit instead of accidental. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

The other planning constraint is migration truth. Existing host fixtures and the installer currently generate workflow tables that stop at workflow, step, edge, result, await, signal, callback, and recovery tables. If Phase 17 adds a durable mutation-attempt ledger or new compatibility metadata, the phase has to update the installer, example-host migrations, and test-support migrations in the same slice as the runtime core so supported hosts and repo fixtures do not drift. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; test/support/migrations/3_phase_4_tables.exs; examples/phoenix_host/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs]

## Current Gaps That Matter For Planning

### Gap 1: There is no single explicit legality intake path
- `Workflow.complete_step/4`, `await_step/4`, `deliver_signal/2`, `request_cancel/3`, and `recover_step/5` all jump into specialized runtime functions. [VERIFIED: lib/oban_powertools/workflow.ex; lib/oban_powertools/workflow/runtime.ex]
- Those functions each mix legality assumptions, row mutation, and reconciliation inline, so unsupported paths are shaped by code branches rather than one named contract. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- The context explicitly requires one shared legal path for runtime and operator mutations. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]

### Gap 2: Durable rejection evidence does not exist yet
- Audit events exist, but there is no repo-local workflow mutation-attempt or rejection ledger that captures refused commands as durable truth. [VERIFIED: lib/oban_powertools/audit.ex; lib/oban_powertools/workflow/runtime.ex]
- Current runtime functions mostly succeed or return an error without persisting refusal context, except for positive-path `RecoveryAttempt` and callback rows. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- The context locks a hybrid model: structured error plus durable rejection evidence, with audit as additive human-action trace. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]

### Gap 3: Lifeline still repairs workflow steps directly instead of workflows through a bounded workflow command surface
- `Lifeline.mutate_target/3` calls `Runtime.recover_step_by_id/4` for `workflow_step_retry` and `workflow_step_cancel`. [VERIFIED: lib/oban_powertools/lifeline.ex]
- That is already better than raw row edits, but it leaves Lifeline action vocabulary step-centric and does not yet express workflow-level reconcile, expire, or cancel semantics through one operator wrapper. [VERIFIED: lib/oban_powertools/lifeline.ex; .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]
- Phase 17 should widen the shared command core without widening operator policy itself. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]

### Gap 4: Diagnosis vocabulary is only partially unified
- `Runtime.workflow_diagnosis/2` and `step_diagnosis/1` already expose `waiting_on_signal`, `expired_wait`, `waiting_on_retryable_dependency`, `missing_dependency_result`, and `cancel_requested`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `WorkflowsLive` renders those diagnoses, but Lifeline incident projection still classifies most workflow issues under a broad `workflow_stuck` bucket. [VERIFIED: lib/oban_powertools/web/workflows_live.ex; lib/oban_powertools/lifeline.ex]
- Phase 17 should at least converge on the legal mutation and rejection vocabulary before later phases expand richer signal/callback incident classes. [VERIFIED: .planning/research/ARCHITECTURE.md; .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md]

### Gap 5: Compatibility-safe adoption needs schema and fixture coordination
- The installer and example-host migrations are part of the public contract and must stay aligned with workflow runtime truth. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; examples/phoenix_host/priv/repo/migrations/20260522000020_oban_powertools_workflows.exs]
- Test-support migrations are still phase-batched, so a new workflow mutation ledger or transition metadata must land in that harness too. [VERIFIED: test/support/migrations/3_phase_4_tables.exs]
- Phase 16 already froze `semantics_version` and compatibility posture; Phase 17 has to preserve that for upgrade-proof and test fixtures instead of hand-waving it in code comments only. [VERIFIED: .planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public mutation verbs | `ObanPowertools.Workflow` wrappers | thin operator/runtime adapters | Preserve the paved road while hiding internal legality mechanics. [VERIFIED: lib/oban_powertools/workflow.ex; .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md] |
| Legal transition matrix and rejection taxonomy | internal workflow command core | runtime helpers | One place should decide whether a command is legal, deferred, unsupported, or blocked by missing evidence. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; .planning/milestones/v1.2-ROADMAP.md] |
| Durable mutation/rejection evidence | new workflow mutation-attempt ledger | audit events | Audit is human-facing, not the sole domain truth for refused transitions. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md] |
| Shared diagnosis vocabulary | runtime / explain helpers | Lifeline projection and `WorkflowsLive` | Operators and maintainers need one support-truth story across mutation, repair, and inspection surfaces. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/web/workflows_live.ex; lib/oban_powertools/lifeline.ex] |
| Compatibility-safe adoption | installer migrations, example-host migrations, test-support migrations | runtime comments and contract helpers | Supported hosts and repo fixtures must generate the same schema and semantics surfaces the runtime expects. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; test/support/migrations/3_phase_4_tables.exs] |

## Recommended Plan Slices

### Slice 1: Introduce one internal transition-command core and durable mutation-attempt ledger
**Why first:** Every later caller and diagnosis surface depends on one legal intake path and durable rejection evidence.  
**Likely files:** `lib/oban_powertools/workflow.ex`, `lib/oban_powertools/workflow/runtime.ex`, workflow schema modules, new internal command/ledger modules, installer/example/test-support migrations, targeted runtime tests.  
**Expected outcome:** one bounded internal command vocabulary, explicit legal-transition evaluation, structured rejection reasons, and a Postgres-backed mutation-attempt record for both accepted and refused commands.

### Slice 2: Re-route runtime and operator callers through that command core
**Why second:** Once the legality path exists, Lifeline and workflow inspection can share it without inventing more entrypoints.  
**Likely files:** `lib/oban_powertools/lifeline.ex`, `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/web/workflows_live.ex`, possibly `lib/oban_powertools/explain.ex`, plus Lifeline and LiveView tests.  
**Expected outcome:** runtime and operator flows share one mutation pipeline, workflow-level recovery/reconcile/cancel wrappers are explicit, and workflow/Lifeline diagnosis vocabulary converges.

### Slice 3: Lock verification, legacy gating, and upgrade-safe schema adoption
**Why third:** The phase only closes cleanly if illegal/rejected/racy paths are proven and supported hosts can adopt the new truth surfaces safely.  
**Likely files:** workflow runtime/coordinator/Lifeline tests, new compatibility-focused tests, installer/test/example-host migration artifacts, possibly phase-local docs or contract comments.  
**Expected outcome:** automated proof for race, expiry, late, duplicate, and rejected mutation paths plus explicit compatibility coverage for pre-v2 rows and supported schema adoption.

## Validation Architecture

Focused ExUnit remains the right proof posture for this phase. The existing suite already proves DB-first behavior without relying on PubSub follow-up, so planning should extend that same targeted test shape rather than introducing browser E2E or opaque integration harnesses. [VERIFIED: test/oban_powertools/workflow_coordinator_test.exs; test/oban_powertools/workflow_runtime_test.exs]

Recommended verification bundle after execution:
`mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/lifeline_test.exs test/oban_powertools/web/live/workflows_live_test.exs`

The minimum Phase 17 proof bar should cover:
- accepted and rejected workflow mutations both leave durable evidence,
- cancel-versus-complete and late-signal paths remain explainable,
- Lifeline repair actions re-enter the same command core instead of bypassing it,
- workflow inspection shows the converged diagnosis and rejection vocabulary,
- compatibility-safe migration/install fixtures generate the schema required by the new command path.

## Anti-Patterns To Avoid

- Do not publish a generic command DSL or public `Ecto.Multi` builder surface in this phase.
- Do not let Lifeline or future workflow UI actions mutate workflow rows outside the command core.
- Do not rely on audit rows alone to explain refused transitions.
- Do not silently reinterpret `semantics_version < 2` rows during cancel/recover/reconcile flows.
- Do not let signal/await/callback follow-on work leak into Phase 17 as accidental partial implementations without explicit deferred semantics.

## RESEARCH COMPLETE
