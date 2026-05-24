# Phase 19: Await Registration, Signal Facts & Expiry Authority - Research

**Researched:** 2026-05-24
**Domain:** Durable await registration, signal fact ingestion, replay evidence, and authoritative wait expiry for v1.2 workflows.
**Confidence:** HIGH [VERIFIED: repo-local planning artifacts, workflow runtime code, migrations, and tests]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Keep Postgres rows as the only correctness-bearing truth source. PubSub, notifier wakeups, workers, and UI refreshes remain advisory only. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Use a hybrid scoped signal contract: hosts may submit business correlation data at ingress, but the runtime must resolve and persist explicit `workflow_id` authority before a signal may wake a wait. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Final matching authority is workflow-scoped, not correlation-only. Ambiguous correlation-only signals must remain durable unmatched facts rather than waking a wait speculatively. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Phase 19 supports exactly one active await per step. `workflow_awaits` is the detailed truth store and `workflow_steps` keeps only a thin diagnosis-facing mirror. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Treat one canonical signal fact row as the semantic signal identity and preserve duplicate or replay attempts as separate durable evidence instead of rewriting the canonical row or implying exactly-once delivery. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Use one authoritative DB-first reconciliation path for wait expiry. Sweepers or wakeups may discover due waits, but they must not own expiry semantics independently from the shared reconcile path. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Bias toward support truth and least surprise: a maintainer should be able to explain from rows alone what signal arrived, which wait it matched or failed to match, why a wait expired, and what duplicate or late evidence exists. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]

### the agent's Discretion
- Exact status vocabulary for unmatched, ambiguous, duplicate, replayed, and already-consumed signal evidence. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Whether duplicate or replay evidence stays in a dedicated ingress/evidence schema or leans on the existing `CommandAttempt` ledger, provided canonical signal truth is not destructively rewritten. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Exact pointer or projection shape from `workflow_steps` to the active await row, provided the step row remains a thin mirror. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Exact worker or query shape for due-wait discovery, provided expiry authority still routes through the shared reconciliation path. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Multiple concurrent awaits on one logical step, including `wait_any` and `wait_all` fan-in semantics. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- A full append-only signal ingress ledger with replay tooling and richer event-history UX. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Broader cancel-versus-signal, completion-versus-expiry, and late-arrival precedence rules. Those belong to Phase 20. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Generic event-bus or webhook-platform semantics. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `SIG-01` | A workflow step can durably register an await contract with signal name, correlation identity, dedupe behavior, and deadline so waiting survives restarts and cross-node execution. | The repo already persists await rows plus a thin step-row mirror, but the current shape has no `active_await_id` pointer, no workflow-authoritative match field on the active contract, and only a step-scoped uniqueness rule. Planning should harden the await row as the primary truth and leave the step row as a projection only. [VERIFIED: lib/oban_powertools/workflow/await.ex; lib/oban_powertools/workflow/step.ex; test/support/migrations/2_phase_3_tables.exs] |
| `SIG-02` | Incoming workflow signals are stored as durable facts and reconciled idempotently whether they arrive before, during, or after a matching wait registration. | `deliver_signal/2` already stores a `SignalRecord` before matching, and tests already prove pre-await consumption, but current matching is still by `signal_name + correlation_key` and does not require resolved `workflow_id` authority before consuming a wait. Duplicate attempts are preserved only as `CommandAttempt` rows, not as first-class signal statuses or unmatched evidence. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/signal_record.ex; test/oban_powertools/workflow_runtime_test.exs] |
| `SIG-03` | Expiry and late-arrival policy is explicit: a maintainer can tell whether an overdue wait failed, cancelled downstream work, remained recoverable, or ignored late signals by contract. | The runtime already expires waiting awaits and marks late signals, but expiry truth is currently split between `expire_waits/3`, `resolve_wait_from_signal/3`, and `mark_signal_late_if_expired/2`. Planning should collapse legal expiry outcome into one shared reconcile path and leave ingress paths to append evidence only. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/await.ex; lib/oban_powertools/workflow/signal_record.ex] |
| `VER-01` | The repo proves duplicate, late, dropped, and race-path workflow events with automated fixtures covering signal replay, cancel-versus-complete races, expiry, and lost wakeup reconciliation. | The current suite covers pre-await signal storage, expired waits, late signals, and cancel-versus-complete races, but it does not yet prove ambiguous correlation handling, duplicate or replay evidence posture, or lost-wakeup recovery around the Phase 19 contract. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs; test/oban_powertools/workflow_coordinator_test.exs] |
| `VER-02` | A maintainer can upgrade hosts with in-flight waiting, retrying, cancelling, or recovering workflows without breaking semantics or leaving support unable to explain stored state. | Any await or signal schema reshape must land together in installer migrations, repo test-support migrations, and supported-host example migrations or in-flight support truth will drift immediately. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; test/support/migrations/2_phase_3_tables.exs; examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs] |
</phase_requirements>

## Summary

Phase 19 should be planned as a contract-hardening phase over real existing runtime behavior, not as a first introduction of waits or signals. The runtime already persists `Await` rows, `SignalRecord` rows, pre-await signals, late signals, and expired waits. The planning problem is that the current contract is still looser than the locked context: signal matching is correlation-first, unmatched and ambiguous facts are not modeled distinctly enough, and expiry truth is finalized through more than one write path. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/await.ex; lib/oban_powertools/workflow/signal_record.ex; test/oban_powertools/workflow_runtime_test.exs]

The highest-value Phase 19 move is to separate three concerns that are currently blurred together: signal ingress as durable fact recording, signal-to-wait resolution as workflow-authoritative reconciliation, and expiry as one legal DB-first outcome path. That keeps Phase 19 narrow, preserves the Phase 17 command-core posture, and gives Phase 20 a stable base for the broader cancel/completion/late-arrival precedence rules that are explicitly deferred today. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md; .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

The repo already has the main persistence primitives it needs: await rows, signal rows, command-attempt evidence, step-level wait mirrors, and installer/test/example migrations carrying the same schema family. The planning work is therefore mostly about narrowing semantics and tightening authority, not inventing a second orchestration layer or a broader public API. [VERIFIED: lib/oban_powertools/workflow/await.ex; lib/oban_powertools/workflow/signal_record.ex; lib/oban_powertools/workflow/command_attempt.ex; lib/mix/tasks/oban_powertools.install.ex; test/support/migrations/2_phase_3_tables.exs]

## Current Gaps That Matter For Planning

### Gap 1: Signal matching is still correlation-first instead of workflow-authoritative
- `reconcile_signals_for_signal/4` finds waiting awaits only by `signal_name` and `correlation_key`, and `resolve_wait_from_signal/3` consumes the first pending signal with the same pair. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `SignalRecord.workflow_id` is nullable and not required before a signal can satisfy a wait, which directly conflicts with the locked requirement to persist resolved `workflow_id` authority before wakeup. [VERIFIED: lib/oban_powertools/workflow/signal_record.ex; test/support/migrations/2_phase_3_tables.exs]
- This means ambiguous correlation-only signals cannot currently remain as unmatched durable facts; they can wake whichever matching wait is encountered first. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

### Gap 2: Canonical signal truth is durable, but its evidence vocabulary is too weak
- `SignalRecord` currently exposes only `pending`, `consumed`, and late-written states in practice, while duplicates are recorded through `CommandAttempt` rows with `status: "duplicate"` and `reason_code: "duplicate_signal"`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/signal_record.ex; lib/oban_powertools/workflow/command_attempt.ex]
- There is no first-class durable status for unmatched, ambiguous, replayed, or already-consumed signal facts even though the Phase 19 context wants those cases explainable without guessing. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/signal_record.ex]
- This is the main support-truth gap for `SIG-02`: the repo preserves some evidence already, but operators still cannot read one authoritative signal-fact story from signal rows alone. [VERIFIED: lib/oban_powertools/workflow/signal_record.ex; lib/oban_powertools/workflow/command_attempt.ex]

### Gap 3: Await rows are the de facto truth today, but the projection boundary is not explicit enough
- Phase 19 context locks `workflow_awaits` as the detailed truth store and `workflow_steps` as a thin mirror, yet the current step mirror has signal name, correlation key, dedupe key, and deadline fields but no `active_await_id` pointer or resolved linkage back to the authoritative await row. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/step.ex]
- `await_step/4` updates an existing waiting row in place when one exists for the step, which is acceptable for “one active wait per step” but means planning should be explicit about what historical evidence is preserved on the await row versus the command-attempt ledger. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- The current schema supports one active wait per step via `[:step_id, :status]`, which aligns with the locked narrow contract and means Phase 19 does not need to reopen fan-in or multi-wait semantics. [VERIFIED: test/support/migrations/2_phase_3_tables.exs; .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]

### Gap 4: Expiry outcome is still finalized through more than one effective path
- `do_reconcile/4` calls `expire_waits/3` first, which updates await rows and step rows for due waits. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `resolve_wait_from_signal/3` can separately mark a pending signal `late` when it sees an expired deadline on a still-waiting await row, and `mark_signal_late_if_expired/2` can also mark a just-inserted signal `late` based on any expired wait with the same correlation. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- The signal-ingress path therefore participates in expiry semantics today instead of only recording evidence and deferring legal expiry outcome to shared reconciliation. Phase 19 should collapse that authority to one path. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]

### Gap 5: Proof coverage is real but not yet at the Phase 19 contract boundary
- The suite proves pre-await signal storage, await resolution after registration, expired waits, late signals, callback durability, recovery sessions, and cancel-versus-complete races. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs]
- The suite does not yet prove correlation ambiguity, replay evidence posture, already-consumed signal behavior, or a lost-wakeup path that reconciles entirely from rows after advisory wakeup failure. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs; test/oban_powertools/workflow_coordinator_test.exs]
- Planning should treat those missing proofs as merge-blocking scope for Phase 19 rather than as Phase 23 cleanup, because the requirements already call them out as part of the durable semantics contract. [VERIFIED: .planning/REQUIREMENTS.md]

## Architectural Responsibility Map

| Capability | Primary Module / Tier | Secondary Module / Tier | Rationale |
|------------|-----------------------|-------------------------|-----------|
| Host-facing await and signal API | `ObanPowertools.Workflow` | `ObanPowertools.Workflow.Runtime` | Keep one narrow context-like public seam while hardening semantics underneath it. [VERIFIED: lib/oban_powertools/workflow.ex; lib/oban_powertools/workflow/runtime.ex] |
| Durable await truth | `ObanPowertools.Workflow.Await` + workflow semantics migration files | `ObanPowertools.Workflow.Step` mirror fields | Await rows should own detailed registration, deadline, and resolution linkage; the step row should stay diagnosis-facing only. [VERIFIED: lib/oban_powertools/workflow/await.ex; lib/oban_powertools/workflow/step.ex; test/support/migrations/2_phase_3_tables.exs] |
| Durable signal fact truth | `ObanPowertools.Workflow.SignalRecord` | `ObanPowertools.Workflow.CommandAttempt` evidence | Canonical signal identity should live on signal rows, while duplicate or replay evidence may be attached through linked command-attempt rows if that keeps the contract narrow. [VERIFIED: lib/oban_powertools/workflow/signal_record.ex; lib/oban_powertools/workflow/command_attempt.ex; .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md] |
| Wait satisfaction and expiry legality | `ObanPowertools.Workflow.Runtime.reconcile_workflow/3` | due-wait discovery helpers or future workers | Phase 17 already established one legal DB-first mutation path. Phase 19 should route wait satisfaction and expiry through that same authority. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex] |
| Operator-facing diagnosis inputs | `workflow_steps` mirror + future workflow UI read models | `Await` and `SignalRecord` rows | Later diagnosis work should read “waiting on signal”, “signal unmatched”, “duplicate ignored”, and “late after expiry” from durable rows created here rather than inventing semantics in UI code. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/step.ex] |
| Schema parity across supported hosts | Igniter installer migration + example-host migrations + repo test migrations | runtime schemas | Phase 19 changes only stay supportable if every supported schema path carries the same await/signal contract. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; test/support/migrations/2_phase_3_tables.exs; examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs] |

## Recommended Plan Slices

### Slice 1: Narrow the durable await and signal row contract around workflow authority
**Why first:** The current runtime already has wait and signal persistence; Phase 19 needs to lock what those rows mean before it refactors matching or expiry. [VERIFIED: lib/oban_powertools/workflow/await.ex; lib/oban_powertools/workflow/signal_record.ex]

**Likely files:** `lib/oban_powertools/workflow/await.ex`, `lib/oban_powertools/workflow/signal_record.ex`, `lib/oban_powertools/workflow/step.ex`, `lib/mix/tasks/oban_powertools.install.ex`, `test/support/migrations/2_phase_3_tables.exs`, supported-host example migrations.

**Expected outcome:** explicit status vocabulary for active await and signal-fact rows, workflow-authority fields on signal facts or resolution metadata, and a clearer thin-mirror contract on `workflow_steps`. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/step.ex]

### Slice 2: Make signal ingress record facts first and reconcile waits only after deterministic workflow resolution
**Why second:** `SIG-02` is the semantic center of the phase. Current direct correlation matching is the biggest gap against the locked context. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]

**Likely files:** `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/workflow.ex`, `lib/oban_powertools/workflow/command_attempt.ex`, `test/oban_powertools/workflow_runtime_test.exs`.

**Expected outcome:** signal ingress always persists one canonical fact row, ambiguous or unmatched facts remain durable without waking a wait, duplicate or replay attempts preserve evidence, and only workflow-authoritative reconcile can mark a wait resolved. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/workflow/command_attempt.ex]

### Slice 3: Collapse expiry to one reconcile authority and close the proof lane
**Why third:** Once signal resolution is workflow-authoritative, expiry can be simplified into one legal finalize path with focused tests instead of multiple partial writers. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

**Likely files:** `lib/oban_powertools/workflow/runtime.ex`, await/signal migrations if status fields change, `test/oban_powertools/workflow_runtime_test.exs`, `test/oban_powertools/workflow_coordinator_test.exs`, possibly workflow UI or diagnosis tests only if the new statuses surface immediately.

**Expected outcome:** one shared expiry finalize path, explicit late-signal evidence behavior, and automated fixtures for duplicate, ambiguous, late, replayed, and lost-wakeup cases. [VERIFIED: .planning/REQUIREMENTS.md; test/oban_powertools/workflow_runtime_test.exs]

## Validation Architecture

Phase 19 should stay on focused ExUnit integration tests over `DataCase`. The relevant failure modes are row-state transitions, unique constraints, replay evidence, and reconcile behavior, not browser-only behavior. The existing suite already proves this is the repo’s normal workflow-runtime validation lane. [VERIFIED: test/test_helper.exs; test/support/data_case.ex; test/oban_powertools/workflow_runtime_test.exs]

Recommended quick command:
`mix test test/oban_powertools/workflow_runtime_test.exs`

Recommended phase bundle:
`mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs`

Recommended schema-parity check:
`rg -n "workflow_awaits|workflow_signals|resolved_signal_id|awaiting_signal_name|await_correlation_key|await_dedupe_key|await_deadline_at" lib/mix/tasks/oban_powertools.install.ex test/support/migrations/2_phase_3_tables.exs examples/phoenix_host/priv/repo/migrations examples/phoenix_host_upgrade_source/priv/repo/migrations`

Minimum new proof cases for Phase 19:
- ambiguous correlation-only signal stays durable unmatched and does not wake a wait, [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- duplicate or replay signal attempts preserve evidence without rewriting canonical signal truth, [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/command_attempt.ex]
- signal-after-expiry becomes explicit late evidence without reopening the expired wait, [VERIFIED: lib/oban_powertools/workflow/runtime.ex; test/oban_powertools/workflow_runtime_test.exs]
- lost-wakeup or no-wakeup paths still reconcile correctly from rows alone, [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/workflow/coordinator.ex]
- installer, repo-test, and supported-host migrations expose the same await and signal contract. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; test/support/migrations/2_phase_3_tables.exs]

## Anti-Patterns To Avoid

- Do not let `signal_name + correlation_key` alone be the final wake authority once multiple workflows can plausibly share the same business correlation. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]
- Do not collapse duplicate, replayed, unmatched, ambiguous, consumed, and late outcomes into one mutable signal row state that hides evidence. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]
- Do not move detailed wait truth onto `workflow_steps` and turn the await table into a secondary cache. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/step.ex; lib/oban_powertools/workflow/await.ex]
- Do not let signal ingress or future sweepers finalize expiry semantics independently from the shared reconcile path. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]
- Do not promise exactly-once signal delivery or exactly-once wake behavior. The locked contract is support-truthful and at-least-once. [VERIFIED: .planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md]

## Sources

- `.planning/PROJECT.md` [VERIFIED: milestone status and active requirements posture]
- `.planning/REQUIREMENTS.md` [VERIFIED: `SIG-01`, `SIG-02`, `SIG-03`, `VER-01`, `VER-02`]
- `.planning/ROADMAP.md` [VERIFIED: Phase 19 goal and dependency chain]
- `.planning/milestones/v1.2-ROADMAP.md` [VERIFIED: planned focus for Phase 19]
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md` [VERIFIED: locked defaults and out-of-scope boundary]
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md` [VERIFIED: semantics v2 baseline]
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md` [VERIFIED: one legal DB-first mutation path]
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md` [VERIFIED: adjacent phase posture]
- `.planning/research/SUMMARY.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/FEATURES.md`, `.planning/research/PITFALLS.md`, `.planning/research/STACK.md` [VERIFIED: milestone-level repo research]
- `prompts/oban_powertools_context.md`, `prompts/oban-powertools-deep-research-original-prompt.md`, `prompts/oban_powertools_ultimate_ui_strategy_brief.md` [VERIFIED: product posture and support-truth framing]
- `lib/oban_powertools/workflow.ex`, `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/workflow/await.ex`, `lib/oban_powertools/workflow/signal_record.ex`, `lib/oban_powertools/workflow/step.ex` [VERIFIED: current implementation]
- `lib/mix/tasks/oban_powertools.install.ex`, `test/support/migrations/2_phase_3_tables.exs`, `examples/phoenix_host/priv/repo/migrations/20260522000024_oban_powertools_workflow_semantics.exs` [VERIFIED: schema parity]
- `test/oban_powertools/workflow_runtime_test.exs`, `test/oban_powertools/workflow_coordinator_test.exs` [VERIFIED: proof coverage]

## RESEARCH COMPLETE
