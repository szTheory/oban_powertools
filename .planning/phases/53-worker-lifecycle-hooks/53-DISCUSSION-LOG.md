# Phase 53: Worker Lifecycle Hooks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-12
**Phase:** 53-Worker Lifecycle Hooks
**Areas discussed:** Terminal failure routing, Callback payload shape, Worker hook telemetry public API shape, Dispatch mechanism conflict

---

## Terminal Failure Routing

| Option | Description | Selected |
|--------|-------------|----------|
| Oban-state-aligned terminal hooks | Retry-eligible failures fire `on_failure/2`; final-attempt failures and explicit discards fire `on_discard/2`; explicit cancel remains cancelled and does not fire discard. | ✓ |
| Dual-fire terminal failure | Final-attempt failures fire both `on_failure/2` and `on_discard/2`; cancel may be treated as discard. | |
| Failure-first plus auxiliary discard | Every failure fires `on_failure/2`; final-attempt failure also fires `on_discard/2`; cancel remains separate. | |

**User's choice:** User asked for all areas to be researched with subagents and for a cohesive recommendation set.
**Notes:** Subagent synthesis favored Oban-state-aligned terminal hooks. This avoids duplicate alerts and side effects, matches Oban executor normalization, and follows terminal-only lessons from Sidekiq death handling and Rails discard callbacks. The main correction to prior research is that `{:cancel, reason}` should not be overloaded into `on_discard/2`.

---

## Callback Payload Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Raw process return/reason | Pass `:ok`, `{:ok, value}`, `{:error, reason}`, or discard tuples directly as the second callback arg. | |
| Normalized reason only | Pass small reason values and omit large success payloads. | |
| Oban-style state tuple | Pass tagged tuples such as `{:success, result}` or `{:discard, reason}`. | |
| Hook outcome envelope | Pass a narrow event map with `state`, `result`, `reason`, and crash metadata where relevant. | ✓ |

**User's choice:** User delegated to research-backed recommendation.
**Notes:** The envelope shape preserves future compatibility for output recording and batches while keeping callback arity stable. It must stay narrow and should not be confused with telemetry metadata.

---

## Worker Hook Telemetry Public API Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal emitted telemetry now | Add `worker_hook: [:hook, :outcome]`, emit `[:oban_powertools, :worker_hook, :invoked]`, and add one counter metric. | ✓ |
| Contract-only now, emit later | Add contract entries but do not emit hook telemetry in Phase 53. | |
| Defer all worker-hook telemetry | Rely only on Oban core job telemetry for now. | |
| Span-style hook telemetry | Emit start/stop/exception spans with duration/error metadata. | |

**User's choice:** User delegated to research-backed recommendation.
**Notes:** HOOK-05 explicitly requires hook invocations to emit telemetry. Minimal counter-style telemetry satisfies the requirement without duplicating Oban job lifecycle or risking high-cardinality labels.

---

## Dispatch Mechanism Conflict

| Option | Description | Selected |
|--------|-------------|----------|
| Inline dispatch in generated wrapper | Put all hook dispatch logic inside the quoted `perform/1` macro body. | |
| Per-worker Oban telemetry handlers | Register `:telemetry.attach` handlers for Oban job lifecycle events and dispatch hooks from those handlers. | |
| Internal dispatcher called by generated wrapper | Let the wrapper own ordering and call `ObanPowertools.Worker.Hooks` for safe dispatch. | ✓ |
| Hybrid wrapper plus telemetry observer | Dispatch primary hooks from wrapper and use Oban telemetry observers for executor-only facts. | |

**User's choice:** User delegated to research-backed recommendation.
**Notes:** The selected architecture avoids macro bloat and runtime handler lifecycle issues, while preserving typed args and deterministic composition for deadline, recording, and redaction phases. Oban telemetry remains important for timeout observability but should not dispatch user hooks in Phase 53.

---

## the agent's Discretion

- The user explicitly asked for subagent-backed research, tradeoff analysis, and one cohesive recommendation set so they would not need to manually pick every option.
- Subagents researched all four gray areas. The final context resolves conflicts across their recommendations, especially explicit cancel semantics.

## Deferred Ideas

- Add `on_cancel/2` only if a later phase needs first-class cancellation/deadline callbacks.
- Defer global hook registries, hook latency spans, Lifeline discard hooks, output recording, deadline enforcement, and redaction to their scoped phases.
