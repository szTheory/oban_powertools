# Research Summary: v1.2 Workflow Semantics & Recovery

## Executive Summary

Oban Powertools v1.2 should not become a new workflow engine. The research converges on a narrower and more defensible goal: harden the existing Postgres/Ecto/Oban workflow substrate so waits, signals, callbacks, cancellation, expiry, recovery, and diagnosis are durable, explainable, and safe under crashes and operator intervention. The right implementation model is still DB-first. Persist facts first, derive workflow truth in transactions, and use PubSub only as a latency hint.

The core recommendation is to split workflow runtime behavior into explicit commands and a deterministic semantics layer. Commands capture intent such as complete, await, signal, cancel, expire, and recover. The semantics layer consumes durable rows and computes the next legal workflow and step transitions, blocker codes, callback emissions, and diagnosis states. That gives the package one authoritative lifecycle vocabulary instead of spreading it across workers, coordinator processes, UI labels, and repair flows.

The main risks are semantic drift and false promises. If PubSub becomes truth, if `pending` keeps meaning five different things, or if cancellation is presented as instant termination, support truth collapses. Planning should therefore front-load contract definition, transition rules, and persistence primitives before adding operator affordances. v1.2 should ship a smaller but reliable semantic surface now, then leave cross-product unification, richer callback policy controls, and advanced preview UX to later milestones.

## Key Findings

### Stack Recommendations

**Recommended**

- `Elixir ~> 1.19`: keep the current OTP/runtime baseline; use processes for coordination, not durable workflow truth.
- `Oban ~> 2.22`: make the declared dependency match the locked runtime and lean on current cancellation, notifier, worker-return, and scheduled-job semantics.
- `Ecto / Ecto SQL ~> 3.14`: keep all workflow mutations, recovery actions, and signal consumption inside `Ecto.Multi` transactions.
- `Postgrex ~> 0.22`: keep direct access to Postgres-native notifier and diagnosis queries.
- `PostgreSQL 16+`: remain fully Postgres-native for state, locking, sweepers, and durable evidence.
- `:telemetry ~> 1.4`: extend the low-cardinality public contract; keep rich evidence in durable tables.
- `:phoenix_pubsub ~> 2.2` only as a direct dependency if the UI still needs local rebroadcasts.
- `oban_web ~> 2.12` stays optional and unchanged as a generic job drill-down surface.

**Non-recommendations**

- Do not add Redis, RabbitMQ, Kafka, or any second coordination broker.
- Do not introduce Temporal, Cadence, Commanded, Broadway, GenStage, or EventStore for this milestone.
- Do not use Phoenix PubSub as the sole workflow signal bus.
- Do not add a generic state-machine library or a new metrics backend.
- Do not build a full native replacement for Oban Web generic screens.

### Table-Stakes Feature Set For v1.2

This milestone should treat the following as the minimum credible surface:

- Explicit terminal-state contract for workflows and steps, with durable causes for `completed`, `failed`, `cancelled`, and `expired`.
- Legal transition rules that define who may trigger complete, cancel, expire, recover, and signal-driven transitions.
- Durable await/signal semantics with persisted wait contracts, correlation/dedupe keys, and clear wake behavior.
- Timeout/expiry semantics for waits and long-running edges, including late-arrival policy.
- Cooperative cancellation with observable `cancel_requested` versus final cancellation outcome.
- Post-commit callback semantics through a durable outbox, not inline side effects.
- Recovery-safe retry/resume semantics that preserve already successful work and create new attempt evidence.
- Stuck-graph diagnosis vocabulary that explains `waiting`, `blocked`, `orphaned`, `expired`, `retry_backoff`, and `cancel_requested`.
- Causality-preserving audit evidence for operator and runtime recovery actions.

### Architecture And Build-Order Guidance

The recommended architecture is a two-layer workflow runtime:

1. `Workflow.Commands`
   Accepts explicit intents such as `complete_step`, `register_await`, `deliver_signal`, `request_cancel`, `expire_due`, `recover_workflow`, and `reconcile_workflow`.
2. `Workflow.Semantics`
   Pure planner that derives next workflow state, step state, blocker codes, callback rows, and diagnosis facts from durable rows.

Required persistence additions:

- `workflow_awaits`: durable wait contracts and deadlines.
- `workflow_signal_events`: append-only signal inbox with dedupe/replay support.
- `workflow_callbacks`: durable callback outbox.
- Workflow/step columns for terminal reason, cancellation metadata, expiry timestamps, and reconciliation timestamps.

Recommended build order:

1. **Semantics contract and vocabulary**
   Freeze workflow states, step states, blocker codes, terminal reasons, and versioning strategy for in-flight compatibility.
2. **Transactional command pipeline**
   Route all workflow mutations through command APIs plus one reconciliation path.
3. **Await/signal plus expiry**
   Add durable wait registration, signal ingestion, matching, dedupe, and deadline handling.
4. **Cancellation and recovery**
   Add cooperative cancellation propagation, scoped retry/resume, and operator-safe recovery commands.
5. **Diagnosis and operator surfaces**
   Expose the durable explanation model in workflow UI and Lifeline, with evidence and allowed next actions.
6. **Verification and telemetry hardening**
   Add race-condition fixtures, upgrade fixtures, and low-cardinality telemetry updates after semantics settle.

### Top Pitfalls And Planning Implications

1. **PubSub as truth**
   Planning implication: all phases must preserve DB-first, replayable reconciliation. Treat notifier and PubSub only as wakeup hints.

2. **State vocabulary drift across job, step, workflow, and UI layers**
   Planning implication: phase 1 must freeze a cause-oriented vocabulary before adding new mutations or screens.

3. **Callbacks tied only to worker success/failure hooks**
   Planning implication: phase 2 must introduce a durable callback outbox and cover operator-driven and expiry-driven transitions, not only normal execution.

4. **Infinite waits, duplicate signals, and unkeyed correlation**
   Planning implication: await/signal work cannot ship without deadlines, dedupe keys, late-arrival policy, and fixtures for duplicate and expired signals.

5. **Cancellation sold as immediate termination**
   Planning implication: UX and docs must separate `cancel_requested` from terminal outcome, and the runtime must tolerate late completions after a cancel request.

6. **Time-based “stuck” detection without causal evidence**
   Planning implication: diagnosis should classify by cause first, age second. Build blocker codes and evidence rows before building incident surfaces.

7. **Breaking semantic changes for in-flight workflows**
   Planning implication: persist a workflow definition or semantics version and add upgrade fixtures for workflows already waiting, retrying, or cancelling at deploy time.

## Implications For Roadmap

Suggested milestone phases: **5**

1. **Semantics Contract**
   Rationale: every later feature depends on one stable lifecycle vocabulary.
   Delivers: workflow/step states, terminal reasons, blocker codes, transition rules, and versioning rules for in-flight workflows.
   Must avoid: overloaded state labels and undocumented cause drift.

2. **Command Pipeline And Durable Callbacks**
   Rationale: all mutations need one DB-first execution path before recovery semantics broaden.
   Delivers: `Workflow.Commands`, `Workflow.Semantics`, callback outbox rows, and post-commit callback dispatch.
   Must avoid: worker-hook-only callbacks and direct row mutation from repair flows.

3. **Await, Signal, Cancellation, And Expiry**
   Rationale: this is the center of the milestone and the highest semantic-risk area.
   Delivers: durable waits, signal inbox, dedupe/correlation, timeout handling, cooperative cancellation, expiry workers, and reconcile-on-wakeup behavior.
   Must avoid: unbounded waits, late-signal ambiguity, and “cancel means instantly stopped” promises.

4. **Recovery And Diagnosis Surfaces**
   Rationale: operator actions should be layered on top of stable semantics, not invent them.
   Delivers: scoped recover/retry/resume/cancel actions, durable diagnosis classes, Lifeline integration, and richer workflow inspection.
   Must avoid: age-based stuck buckets and repair actions that bypass the command pipeline.

5. **Verification, Compatibility, And Telemetry Closure**
   Rationale: semantics work is only shippable when race paths, upgrade paths, and public evidence claims are proven.
   Delivers: duplicate/late/missing-event fixtures, pre-upgrade in-flight fixtures, telemetry updates, docs alignment, and support-truth verification.
   Must avoid: broad public guarantees without evidence.

### Research Flags

**Needs deeper phase research**

- Phase 3: await/signal, cancellation, and expiry semantics need precise contract decisions around precedence, late arrivals, and replay behavior.
- Phase 4: recovery UX and diagnosis surfaces need validation against existing Lifeline preview/reason/audit patterns.
- Phase 5: compatibility and verification need explicit deploy/upgrade strategy for in-flight workflows.

**Well-understood patterns**

- Phase 1: vocabulary freezing and DB-first state contract work are well supported by the current architecture research.
- Phase 2: `Ecto.Multi`, outbox, and command/semantics separation are standard and strongly evidenced.

## In Scope Now Vs Deferred

**In scope for v1.2 now**

- Hardening workflow semantics on the existing Postgres/Ecto/Oban substrate.
- Durable wait, signal, callback, cancellation, expiry, recovery, and diagnosis contracts.
- Workflow-local operator explanation and repair safety.
- Minimal supporting workers for reconcile, expiry, callback dispatch, and diagnosis.

**Deferred to later milestones**

- Cross-product diagnostic unification across cron, queues, limiters, Lifeline, and workflows.
- Recovery preview before mutation as a polished differentiator, once recovery semantics are stable.
- Rich callback policy matrix beyond a narrow workflow/step terminal contract.
- Generic event bus or webhook platform behavior.
- Broad control-plane redesign or native replacement of generic Oban Web screens.
- Ecosystem-facing automation/API surfaces that would freeze contracts too early.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Strong alignment across project constraints and official Oban/Ecto/Postgres primitives. |
| Features | HIGH | Table-stakes set is consistent across multiple durable-workflow systems and fits the active milestone exactly. |
| Architecture | HIGH | Recommendations extend the current DB-first design rather than replacing it, which matches shipped package principles. |
| Pitfalls | HIGH | Failure modes are concrete, repeated across the research, and directly actionable in milestone planning. |

## Gaps To Address During Planning

- Decide the exact workflow and step state enums versus auxiliary cause columns so the schema stays explicit without becoming overly granular.
- Define signal precedence rules: signal-before-await, signal-after-expiry, duplicate signal arrival, and cancel-versus-signal races.
- Decide whether recovery-safe resume is step-scoped, branch-scoped, or workflow-scoped in v1.2.
- Lock the callback contract surface tightly enough to document and test without expanding into a generic integration platform.
- Define the compatibility story for workflows created before the v1.2 semantics schema lands.

## Sources

- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- `.planning/PROJECT.md`
- `.planning/MILESTONE-ARC.md`
