# Phase 20: Cancellation, Late Completion & Expiry Semantics - Research

**Researched:** 2026-05-24
**Domain:** Cooperative cancellation, late completion/failure evidence, expiry precedence, truthful diagnosis, and terminal callback semantics for v1.2 workflows.
**Confidence:** HIGH [VERIFIED: repo-local planning artifacts, workflow runtime code, explain helpers, callback outbox behavior, and focused workflow tests]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Keep Postgres rows as the only correctness-bearing truth source. PubSub, coordinator wakeups, workers, and UI refreshes remain advisory only. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Treat `cancel_requested_at` as durable request evidence rather than an automatic final outcome. Final workflow and step outcomes must reduce from durable facts after reconciliation. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Cancellation is eager for idle work and cooperative for in-flight work. Idle or waiting steps may cancel immediately; running work must settle to its real final truth. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Preserve terminal truth once written. Late signals, late completions, late failures, and duplicate post-terminal arrivals must remain durable evidence without rewriting final meaning. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Diagnosis and callback surfaces must show final truth before lingering request evidence. Terminal workflows should not keep presenting generic `cancel_requested` when a more specific final cause is known. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Phase 20 must stay bounded: no second orchestration engine, no broad event-sourced redesign, no widened operator verb surface beyond the existing cancel contract, and no Phase 21 UI pull-forward. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]

### the agent's Discretion
- Exact durable cause strings for post-cancel failure and late-arrival evidence, provided the vocabulary remains bounded and coherent with `completed_after_cancel_request` and `expired_wait`. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Whether post-terminal evidence is stored by widening existing `CommandAttempt` / `SignalRecord` usage, by introducing a narrowly scoped evidence table, or by combining both. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Exact reducer decomposition inside `ObanPowertools.Workflow.Runtime`, provided there is one canonical implementation reused by reconcile, callback emission, and diagnosis helpers. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Separate stronger operator verbs such as `terminate` or `abort_now`. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Full event-sourced workflow history or generalized event-bus semantics. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Native workflow screen redesign, Lifeline repair UI, or other Phase 21-22 operator-surface work. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `REC-03` | Workflow cancellation is cooperative and explicit: operators can see request versus final outcome, and late step completion after a cancel request is preserved as durable evidence instead of hidden. | Phase 17 introduced the request path and `completed_after_cancel_request`, but the current runtime still sets workflow-level `terminal_cause` to `cancel_requested` at request time and eagerly cancels `retryable` steps, which is looser than the Phase 20 context. Planning should centralize cancel request evidence and final outcome reduction. [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/workflow/runtime.ex] |
| `SIG-03` | Expiry and late-arrival policy is explicit: a maintainer can tell whether an overdue wait failed, cancelled downstream work, remained recoverable, or ignored late signals by contract. | Phase 19 hardened authoritative expiry, but current late handling is mostly `SignalRecord.status == "late"` after expiry. Phase 20 must define how expiry competes with cancel requests, dependency failure, and in-flight completion, and how late-after-cancel evidence is preserved. [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/workflow/runtime.ex; test/oban_powertools/workflow_runtime_test.exs] |
| `DIA-01` | A workflow screen can explain durable cause classes such as `waiting_on_signal`, `cancel_requested`, and `expired_wait` without requiring direct database inspection. | `Runtime.workflow_diagnosis/2` currently returns `cancel_requested` before checking terminal truth whenever `cancel_requested_at` is set, which conflicts with the Phase 20 requirement to present final truth before request evidence. Phase 20 should fix diagnosis helpers without dragging full UI work forward. [VERIFIED: .planning/REQUIREMENTS.md; lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex] |
| `VER-01` | The repo proves duplicate, late, dropped, and race-path workflow events with automated fixtures covering signal replay, cancel-versus-complete races, expiry, and lost wakeup reconciliation. | The suite already proves cancel-versus-complete and late-after-expiry basics, but it does not yet prove cancel-versus-failure, cancel-versus-expiry, diagnosis ordering, terminal callback truth after cancel races, or post-terminal duplicate evidence. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs; test/oban_powertools/workflow_coordinator_test.exs] |
| `VER-02` | A maintainer can upgrade hosts with in-flight waiting, retrying, cancelling, or recovering workflows without breaking semantics or leaving support unable to explain stored state. | Phase 19 covered waiting workflows. Phase 20 likely needs to widen the archived upgrade lane to include at least one in-flight cancelling or cancel-requested workflow so maintainers can prove the new request-versus-outcome semantics survive migration supportably. [VERIFIED: .planning/REQUIREMENTS.md; test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs] |
</phase_requirements>

## Summary

Phase 20 is not a greenfield cancellation feature. The repo already has a DB-first cancel request path, authoritative wait expiry, durable signal facts, and callback outbox delivery. The planning problem is that the current implementation still blurs request evidence, final outcome, and diagnosis wording in a few critical places. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex; test/oban_powertools/workflow_runtime_test.exs]

The most important correction is to introduce one canonical `request -> evidence -> outcome` reducer for cancellation and late-arrival races. Today `run_request_cancel/2` writes workflow-level `terminal_cause: "cancel_requested"` immediately, `workflow_diagnosis/2` prefers `cancel_requested` over terminal truth, and `refresh_workflow/3` later recomputes state and cause from step rows. That creates a support-truth window where request evidence can temporarily masquerade as final truth. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

The second important gap is vocabulary. The repo already preserves some late evidence through `SignalRecord.status == "late"` and `CommandAttempt` rows, but it does not yet represent late completion after cancel, late failure after cancel, or post-terminal duplicate arrivals with the same explicitness that the context requires. Planning should keep the vocabulary bounded and reuse existing durable seams before inventing new persistence surfaces. [VERIFIED: lib/oban_powertools/workflow/signal_record.ex; lib/oban_powertools/workflow/command_attempt.ex; .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]

The third gap is diagnosis and callback truthfulness. Terminal callbacks currently emit only `state`, `terminal_cause`, `cancel_requested_at`, and `finished_at`, and diagnosis helpers currently surface `cancel_requested` ahead of final truth. Phase 20 should fix those correctness seams in the runtime-owned interpretation layer while leaving full native UI projection for Phase 21. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex]

## Current Gaps That Matter For Planning

### Gap 1: Request evidence and final outcome are still partially conflated
- `run_request_cancel/2` writes `workflow.terminal_cause` as `"cancel_requested"` immediately unless the workflow is already terminal. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `terminal_or_requested_state/1` preserves the current terminal state when already terminal, but non-terminal workflows become `cancel_requested` before reconciliation computes the real final state. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `refresh_workflow/3` later recalculates `state` and `terminal_cause` from step rows, so Phase 20 should centralize the authoritative reduction logic instead of letting pre-refresh snapshots leak into support semantics. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

### Gap 2: Diagnosis currently prefers request evidence over terminal truth
- `workflow_diagnosis/2` returns `"cancel_requested"` whenever `workflow.state == "cancel_requested"` or `cancel_requested_at` is present, even if `workflow.terminal_cause` later indicates `completed_after_cancel_request` or `expired_wait`. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `step_diagnosis/1` checks `cancel_requested` before `terminal_cause`, so any step that keeps a cancel blocker while later settling to a more specific final cause can be misreported. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- `ObanPowertools.Explain.workflow_story/3` and `step_story/2` reuse those helpers directly, so fixing the runtime diagnosis ordering is the narrowest correct seam. [VERIFIED: lib/oban_powertools/explain.ex]

### Gap 3: In-flight cancellation is still too eager for some states
- `run_request_cancel/2` immediately terminalizes steps in `pending`, `available`, `retryable`, and `awaiting_signal`, plus `cancel_requested` itself. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- The context allows immediate cancellation for queued future retry work, but only if that state truly represents idle work. The current `@retryable_states` also drives workflow state reduction, which means planning should inspect whether `retryable` is overloaded between future work and actively executing work before broad cancellation semantics harden further. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]
- `maybe_transition_step/7` also cancels awaiting or retryable steps when `workflow.cancel_requested_at` exists, so plan slices should treat eager idle cancellation and cooperative in-flight settlement as one shared semantics change, not two disconnected patches. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

### Gap 4: Late evidence exists, but only a subset of late paths are modeled explicitly
- `SignalRecord` has statuses `recorded`, `consumed`, `late`, `unmatched`, and `ambiguous`, which covers late signals after expiry but not late completion or late failure after a cancel request. [VERIFIED: lib/oban_powertools/workflow/signal_record.ex]
- `CommandAttempt` already records command evidence durably and can link to a signal, but there is no bounded phase-level plan yet for using it or a sibling evidence surface to classify post-cancel completion/failure and post-terminal duplicates supportably. [VERIFIED: lib/oban_powertools/workflow/command_attempt.ex]
- The current callback payload cannot distinguish "cancel requested, then completed" versus "cancel requested, then failed" beyond the final workflow state and terminal cause. That is narrow but may still need extra durable fields or helper wording so support can explain the race without database spelunking. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

### Gap 5: Proof coverage stops short of the new Phase 20 race matrix
- `workflow_runtime_test.exs` proves late signals after expiry and a cancel-versus-complete race, but it does not yet cover cancel-versus-failure, cancel-versus-expiry, diagnosis ordering once terminal truth is known, or terminal callback correctness for post-cancel outcomes. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs]
- The archived upgrade lane currently focuses on waiting workflow survival from Phase 19, not on cancel-requested or mid-cancellation workflows. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs]
- Phase 20 should therefore plan explicit proof and upgrade tasks instead of assuming the Phase 19 suite automatically covers the broader cancellation semantics contract. [VERIFIED: .planning/REQUIREMENTS.md]

## Architectural Responsibility Map

| Capability | Primary Module / Tier | Secondary Module / Tier | Rationale |
|------------|-----------------------|-------------------------|-----------|
| Canonical request/evidence/outcome reducer | `ObanPowertools.Workflow.Runtime` | `Workflow` and `Step` durable fields | Phase 17 already established the DB-first runtime as the only legal mutation path, so Phase 20 should keep precedence reduction there. [VERIFIED: .planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex] |
| Durable cancellation request evidence | `ObanPowertools.Workflow.Workflow` and `ObanPowertools.Workflow.Step` | `CommandAttempt` | Workflow and step rows already own request timestamps; attempts provide append-only operator evidence. [VERIFIED: lib/oban_powertools/workflow/workflow.ex; lib/oban_powertools/workflow/step.ex; lib/oban_powertools/workflow/command_attempt.ex] |
| Late signal / post-terminal evidence | `SignalRecord` plus `CommandAttempt` or a narrowly added sibling evidence surface | `Await` and callback outbox payloads | Reuse existing durable fact ledgers before introducing broader new storage. [VERIFIED: lib/oban_powertools/workflow/signal_record.ex; lib/oban_powertools/workflow/command_attempt.ex; .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md] |
| Truthful diagnosis helpers | `ObanPowertools.Workflow.Runtime` | `ObanPowertools.Explain` | Runtime already owns diagnosis interpretation; `Explain` is a thin consumer and should inherit the corrected ordering. [VERIFIED: lib/oban_powertools/workflow/runtime.ex; lib/oban_powertools/explain.ex] |
| Truthful terminal callback posture | callback outbox helpers in `ObanPowertools.Workflow.Runtime` | host callback handler docs and tests | The durable outbox contract from Phase 18 should be preserved while final outcome semantics become more precise. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-03-SUMMARY.md; lib/oban_powertools/workflow/runtime.ex] |
| Upgrade-proof for in-flight cancel semantics | installer/example/test migrations plus archived host proof lane | runtime schemas | If Phase 20 adds fields or new status vocabulary, the upgrade lane must prove a cancelling workflow remains explainable after migration. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs] |

## Recommended Plan Slices

### Slice 1: Centralize the outcome reducer and bounded cause/evidence vocabulary
**Why first:** The repo already has the request path and expiry authority. Phase 20 first needs one canonical reduction contract so later cancel propagation, callbacks, and diagnosis do not drift. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

**Likely files:** `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/workflow/workflow.ex`, `lib/oban_powertools/workflow/step.ex`, `lib/oban_powertools/workflow/signal_record.ex`, `lib/oban_powertools/workflow/command_attempt.ex`, installer and supported-host migration files if new fields or bounded statuses land.

**Expected outcome:** request evidence is durable but not final truth, final workflow and step causes reduce from durable facts in one place, and the bounded vocabulary can represent post-cancel completion/failure plus late-arrival evidence explicitly. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]

### Slice 2: Make cancellation propagation cooperative, truthful, and callback-safe
**Why second:** Once the reducer exists, Phase 20 can safely harden eager-idle versus cooperative-in-flight behavior without regressing Phase 17 or 19 semantics. [VERIFIED: lib/oban_powertools/workflow/runtime.ex]

**Likely files:** `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/workflow.ex`, `lib/oban_powertools/explain.ex`, `test/oban_powertools/workflow_runtime_test.exs`.

**Expected outcome:** idle work cancels immediately, in-flight work settles truthfully, downstream scheduling is suppressed after cancel request unless already durably entitled, and terminal callbacks plus explain helpers reflect the real final state instead of generic cancel-request wording. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]

### Slice 3: Close the race-path proof and upgrade lane without pulling Phase 21 UI scope forward
**Why third:** The semantics should be proven only after the reducer and propagation behavior settle. Then planning truth can be updated narrowly and honestly. [VERIFIED: .planning/REQUIREMENTS.md]

**Likely files:** `test/oban_powertools/workflow_runtime_test.exs`, `test/oban_powertools/workflow_coordinator_test.exs`, `test/oban_powertools/explain_test.exs`, `test/support/example_host_contract.ex`, `test/oban_powertools/example_host_contract_test.exs`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`.

**Expected outcome:** automated coverage for cancel-versus-complete, cancel-versus-failure, cancel-versus-expiry, late signals after expiry or cancellation, diagnosis ordering, terminal callback truth, and archived upgrade proof for cancel-requested workflows. [VERIFIED: .planning/REQUIREMENTS.md; test/oban_powertools/workflow_runtime_test.exs]

## Validation Architecture

Phase 20 should continue using focused ExUnit runtime and coordinator suites plus the archived host upgrade proof lane. The core risks are reducer correctness, race-path state transitions, and durable evidence interpretation, not browser-first UI behavior. [VERIFIED: test/oban_powertools/workflow_runtime_test.exs; test/oban_powertools/workflow_coordinator_test.exs; test/oban_powertools/example_host_contract_test.exs]

Recommended quick command:
`mix test test/oban_powertools/workflow_runtime_test.exs`

Recommended phase bundle:
`mix test test/oban_powertools/workflow_runtime_test.exs test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/explain_test.exs`

Recommended upgrade-proof command:
`mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`

Recommended schema / contract parity check:
`rg -n "cancel_requested_at|completed_after_cancel_request|expired_wait|late|operator_cancelled|terminal_cause" lib/mix/tasks/oban_powertools.install.ex test/support/migrations examples/phoenix_host/priv/repo/migrations examples/phoenix_host_upgrade_source/priv/repo/migrations .planning/PROJECT.md .planning/REQUIREMENTS.md`

Minimum new proof cases for Phase 20:
- diagnosis prefers terminal truth over request evidence once a workflow or step has settled, [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- cancel request followed by successful completion remains `completed_after_cancel_request`, [VERIFIED: test/oban_powertools/workflow_runtime_test.exs]
- cancel request followed by failure remains distinct from ordinary `step_failed`, [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- expiry remains authoritative once finalized even if a signal or completion arrives later, [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]
- terminal callback payloads describe the real final state after cancel races, [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
- archived upgrade proof covers at least one cancel-requested or cancelling workflow row. [VERIFIED: .planning/REQUIREMENTS.md]

## Anti-Patterns To Avoid

- Do not keep `cancel_requested` as a quasi-terminal cause that outranks final truth in diagnosis or callback code. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md; lib/oban_powertools/workflow/runtime.ex]
- Do not introduce global "failure always wins" rules that erase edge-policy-local dependency semantics already preserved by the command core. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Do not rewrite terminal workflow or step meaning when late evidence arrives; append evidence instead. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Do not broaden this phase into native UI redesign or broad operator-surface work. [VERIFIED: .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]
- Do not imply exactly-once cancellation, signal delivery, or callback delivery semantics. The repo posture remains support-truthful and at-least-once where applicable. [VERIFIED: .planning/phases/18-durable-callback-outbox-recovery-attempts/18-03-SUMMARY.md; .planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md]

## Sources

- `.planning/PROJECT.md` [VERIFIED: active milestone posture and support-truth guardrails]
- `.planning/REQUIREMENTS.md` [VERIFIED: `REC-03`, `SIG-03`, `DIA-01`, `VER-01`, `VER-02`]
- `.planning/ROADMAP.md` and `.planning/milestones/v1.2-ROADMAP.md` [VERIFIED: Phase 20 goal and sequence]
- `.planning/phases/20-cancellation-late-completion-expiry-semantics/20-CONTEXT.md` [VERIFIED: locked defaults and out-of-scope boundary]
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md` [VERIFIED: bounded lifecycle and terminal-cause vocabulary]
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md` and `17-03-SUMMARY.md` [VERIFIED: one legal DB-first mutation path plus current cancel-race proof]
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-03-SUMMARY.md` [VERIFIED: terminal callback outbox posture]
- `.planning/phases/19-await-registration-signal-facts-expiry-authority/19-CONTEXT.md`, `19-RESEARCH.md`, `19-VALIDATION.md`, and `19-PLAN-CHECK.md` [VERIFIED: expiry authority baseline and proof posture]
- `lib/oban_powertools/workflow/runtime.ex`, `lib/oban_powertools/workflow.ex`, `lib/oban_powertools/workflow/workflow.ex`, `lib/oban_powertools/workflow/step.ex`, `lib/oban_powertools/workflow/signal_record.ex`, `lib/oban_powertools/workflow/command_attempt.ex`, `lib/oban_powertools/explain.ex` [VERIFIED: current implementation seams]
- `test/oban_powertools/workflow_runtime_test.exs`, `test/oban_powertools/workflow_coordinator_test.exs`, `test/oban_powertools/explain_test.exs`, `test/support/example_host_contract.ex`, `test/oban_powertools/example_host_contract_test.exs` [VERIFIED: current proof coverage and upgrade lane]

## RESEARCH COMPLETE
