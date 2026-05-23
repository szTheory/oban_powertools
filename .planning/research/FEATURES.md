# Feature Landscape

**Domain:** Workflow semantics and recovery for durable async DAG orchestration
**Researched:** 2026-05-23

## Table Stakes

Features users expect once a workflow engine already has persisted DAGs, signaling, inspection, and operator repair surfaces. Missing these makes the current workflow layer feel unsafe or ambiguous rather than merely incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Explicit terminal-state contract | Serious orchestration systems distinguish `completed`, `failed`, `cancelled`, and `expired/timed_out` with durable reasons. Operators need to know which terminal state happened and why. | Medium | Persist terminal cause, terminal timestamp, and actor/source (`runtime`, `callback`, `operator`, `expiry`). Do not collapse expiry into generic failure. |
| Post-commit callback semantics | Completion/failure callbacks must only fire after durable state changes commit, or operators get ghost side effects and double notifications after crashes. | High | Define exactly which transitions emit callbacks, whether they are once-per-workflow or once-per-step, and how duplicate delivery is prevented. |
| Durable await/signal contract | Robust systems let workflows wait for external input durably, wake when the signal arrives, and survive worker restarts while waiting. | High | Waiting must be explicit in persisted state: awaited signal name, correlation key if needed, started-at, deadline, and wake reason. Incoming signals should be idempotent and dedupe-friendly. |
| Timeout/expiry on waits and long-running edges | Systems that can wait must also stop waiting. Without deadlines, executions become permanently ambiguous. | Medium | Treat expiry as a first-class outcome with policy options like fail workflow, cancel downstream, or mark step expired and require operator recovery. |
| Recovery-safe retry/redrive semantics | Users expect retrying a failed workflow step or run to preserve durable truth about what already succeeded and what is being retried now. | High | Reuse prior successful results where contractually safe; record new attempts separately; never silently re-run already-completed side-effecting steps. |
| Stuck-graph diagnosis vocabulary | Once workflows persist, operators expect the system to explain `waiting`, `blocked`, `orphaned`, `cancel_requested`, `expired`, or `retry_backoff` instead of showing “not progressing.” | Medium | Diagnosis should be durable and user-facing, not inferred only from transient coordinator state. |
| Cooperative cancellation contract | Mature systems treat cancellation as a requested state transition with observable progress, not instant magic termination. | High | Distinguish `cancellation requested` from `cancellation applied`. In-flight jobs may finish; downstream release must stop; final state must remain auditable. |
| Causality-preserving audit trail for recovery actions | Once operators can resume, cancel, expire, or re-arm waits, each action needs a durable reason and before/after state. | Medium | This is table stakes here because the app already has operator repair and audit expectations elsewhere. Workflow semantics should match that bar. |

## Differentiators

Features that are not strictly required for a credible v1.2, but would make Oban Powertools notably stronger than a basic “durable DAG + manual repair” layer.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Recovery preview before mutation | Show exactly which steps will retry, remain frozen, be cancelled, or be reopened before the operator commits a recovery action. | High | Strong fit with existing Lifeline-style preview/reason/audit posture. This is the cleanest differentiator for operator trust. |
| Root-cause explanations on stuck nodes | Instead of only showing the current state, explain the exact missing prerequisite, awaited signal, expired deadline, orphaned executor, or upstream cancellation that is blocking progress. | High | Different from future “unified control plane” work. Keep it workflow-local and evidence-backed. |
| Scoped resume from failed boundary | Allow resuming from the failed or expired boundary while preserving already-satisfied branches and prior result evidence. | High | Valuable if semantics are explicit enough to guarantee what is and is not replayed. Similar in spirit to Step Functions redrive, but keep scope within workflow runtime truth. |
| Callback policy controls | Support a small, explicit callback matrix such as `on_workflow_completed`, `on_workflow_failed`, `on_step_terminal`, with deduped delivery guarantees. | Medium | Avoid a generic plugin/event bus. Keep contracts narrow and operator-visible. |

## Anti-Features

Features to explicitly NOT build in this milestone because they create semantic ambiguity, scope sprawl, or support debt.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Instant kill semantics for running work | Real systems cannot reliably stop already-running external work immediately. Pretending otherwise creates data drift and false operator confidence. | Make cancellation cooperative and explicit: request, observe, reconcile, then finalize. |
| “Retry everything” recovery button | Blind replay destroys causality, re-runs successful side effects, and makes audits useless. | Require scoped recovery with visible target set and persisted reason. |
| Hidden auto-repair heuristics | Silent orphan rescue, implicit signal synthesis, or background step reopening makes workflow truth non-inspectable. | Surface a diagnosis first, then require explicit runtime or operator action. |
| General-purpose event bus or webhook platform | That turns a semantics-hardening milestone into an integration/control-plane milestone. | Ship a narrow callback contract for workflow lifecycle transitions only. |
| Cross-product diagnostic unification | Unifying cron, limiters, Lifeline, and workflows belongs to v1.3, not this milestone. | Keep diagnosis vocabulary workflow-local, but choose names that can later generalize. |
| User-authored arbitrary repair scripting | Powerful but dangerous; it bypasses the explicit state machine this milestone is supposed to harden. | Expose a bounded set of audited recovery actions with preview and reason requirements. |

## Feature Dependencies

```text
Explicit terminal-state contract
  -> Post-commit callback semantics
  -> Cooperative cancellation contract
  -> Timeout/expiry on waits and long-running edges

Durable await/signal contract
  -> Timeout/expiry on waits and long-running edges
  -> Stuck-graph diagnosis vocabulary

Recovery-safe retry/redrive semantics
  -> Causality-preserving audit trail for recovery actions
  -> Recovery preview before mutation
  -> Scoped resume from failed boundary

Stuck-graph diagnosis vocabulary
  -> Root-cause explanations on stuck nodes

Post-commit callback semantics
  -> Callback policy controls
```

## Sequencing Notes

1. Define the durable state vocabulary first.
   Concrete output: workflow and step states, terminal reasons, wait reasons, cancellation phases, expiry reasons, and retry attempt model.

2. Lock transition rules second.
   Concrete output: which transitions are legal, who can trigger them, and what evidence must be written atomically.

3. Add await/signal and expiry behavior next.
   Concrete output: explicit wait registration, signal acceptance/deduping, timeout handling, and wake/cancel precedence rules.

4. Add recovery semantics after transition rules are stable.
   Concrete output: scoped retry/resume/cancel actions that preserve prior successful steps and create new attempt evidence.

5. Add operator-facing diagnosis and preview last.
   Concrete output: durable explanations and previews that reflect the real runtime contract instead of inventing it.

## MVP Recommendation

Prioritize:
1. Explicit terminal-state contract plus legal transition rules.
2. Durable await/signal, timeout/expiry, and cooperative cancellation semantics.
3. Recovery-safe retry/redrive with durable audit evidence.
4. Stuck-graph diagnosis that explains `waiting`, `blocked`, `orphaned`, `expired`, and `cancel_requested`.

Defer: Recovery preview before mutation.
Reason: High-value, but it should be layered onto stable recovery semantics rather than invented in parallel with them.

Defer: Rich callback policy matrix.
Reason: A narrow callback contract is enough for v1.2; broad callback configurability risks turning semantics work into integration surface design.

## Sources

- Temporal docs overview: https://docs.temporal.io/ . Temporal frames durable workflows around crash-proof execution and long-lived recovery semantics. Confidence: MEDIUM.
- AWS Step Functions callback pattern: https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html . Official guidance for durable waits, callback tokens, and heartbeat timeouts. Confidence: HIGH.
- AWS Step Functions error handling: https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html . Official retry, timeout, and terminal error vocabulary. Confidence: HIGH.
- AWS Step Functions best practices: https://docs.aws.amazon.com/step-functions/latest/dg/sfn-best-practices.html . Official guidance to avoid stuck executions with explicit timeouts and heartbeats. Confidence: HIGH.
- AWS Step Functions redrive: https://docs.aws.amazon.com/step-functions/latest/dg/redrive-executions.html . Official recovery model that preserves successful history and reruns only unsuccessful steps. Confidence: HIGH.
- AWS Step Functions parallel-state behavior: https://docs.aws.amazon.com/step-functions/latest/dg/state-parallel.html . Official note that branch failure stops the workflow state, but already-running tasks may continue and must detect stoppage cooperatively. Confidence: HIGH.
- Azure Durable external events: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-external-events . Official durable wait semantics, wake-up behavior, and at-least-once event delivery with dedupe requirements. Confidence: HIGH.
- Azure Durable error handling: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-error-handling . Official retry policy and orchestrator-managed timeout patterns. Confidence: HIGH.
- Azure Durable timers: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-timers . Official timeout semantics and explicit warning that timer cancellation does not terminate in-flight work. Confidence: HIGH.
- Azure Durable instance management: https://learn.microsoft.com/en-us/azure/durable-task/common/durable-task-instance-management . Official note that termination is queued and does not automatically propagate to in-flight activities or sub-orchestrations. Confidence: HIGH.
