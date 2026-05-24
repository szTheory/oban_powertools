# Phase 19 Discussion Log

**Date:** 2026-05-24
**Mode:** Discuss all + advisor-style subagent research
**Status:** Recommendations locked into `19-CONTEXT.md`

## User Direction

- Discuss all identified gray areas.
- Research each area deeply using subagents.
- Emphasize pros/cons/tradeoffs, idiomatic Elixir/Phoenix/Ecto/Plug patterns, lessons from comparable libraries and systems, DX, operator UX, least surprise, and coherent architecture.
- Use the repo’s `prompts/` artifacts where applicable.
- Shift strong recommendations left within GSD unless a decision is unusually high-impact and worth reopening.

## Areas Discussed

### 1. Signal routing contract

**Question:** How should Powertools scope signal matching so external ergonomics stay reasonable without weakening durable truth?

**Options considered**
- Correlation-first only (`signal_name + correlation_key`)
- Workflow identity required at ingress and match
- Hybrid scoped contract: correlation accepted at ingress, explicit `workflow_id` required before final wake/match

**Locked recommendation**
- Use the hybrid scoped contract.
- Preserve business/external correlation identity at ingress, but require deterministic workflow resolution before waking a wait.
- Keep ambiguous correlation-only signals as durable unmatched facts rather than guessing.

**Why**
- Best balance of Phoenix webhook/controller DX and durable truth.
- Avoids silent cross-workflow misrouting.
- Aligns with Temporal/Azure/Step Functions identity-first lessons without forcing hosts to always know workflow IDs up front.

### 2. Active wait shape

**Question:** Should a step support one active wait or multiple concurrent waits, and how much wait state belongs on the step row?

**Options considered**
- One active await per step, thin step-row mirror, await rows as truth
- One active await per step, richer denormalized summary on step row
- Multiple concurrent awaits per step with aggregate step projection

**Locked recommendation**
- Support exactly one active await per step in Phase 19.
- Keep detailed truth in `workflow_awaits`.
- Mirror only thin diagnosis-facing summary onto `workflow_steps`, optionally with an `active_await_id` pointer.

**Why**
- Narrowest support-truthful contract.
- Best fit with current schema and tests.
- Avoids dragging advanced fan-in semantics and new race classes into Phase 19.

### 3. Signal dedupe and replay posture

**Question:** How should Powertools model duplicate, replayed, late, and already-consumed signals?

**Options considered**
- Canonical signal fact row plus separate durable evidence for duplicates/replays
- Fully append-only signal ingress ledger with derived projection
- Single mutable/upserted signal row that collapses duplicates aggressively

**Locked recommendation**
- Keep one canonical signal fact row per semantic signal identity.
- Preserve duplicate/replay attempts as separate durable evidence instead of destructively rewriting the canonical signal row.
- Keep the public contract explicitly at-least-once rather than implying exactly-once.

**Why**
- Best Ecto/Postgres fit with a clear unique constraint and support-truthful operator story.
- Preserves evidence without broadening Phase 19 into a mini event bus.
- Leaves room for future diagnosis and replay tooling without forcing it now.

### 4. Expiry authority

**Question:** Where should wait expiry be decided and enforced?

**Options considered**
- Single authoritative reconcile path, with sweeper/notifier only waking it
- Dedicated sweeper owns expiry mutation directly
- Hybrid inline expiry/late marking on writes, with reconcile as fallback

**Locked recommendation**
- One authoritative DB-first reconciliation path owns legal expiry outcomes.
- Sweepers, scheduled jobs, or notifier wakeups may discover due waits and trigger reconcile, but they do not own expiry semantics independently.

**Why**
- Best fit with the locked Phase 17 “one legal mutation path” posture.
- Lowest maintainer burden and strongest operator explanation model.
- Avoids split-authority drift where different writers decide similar semantic truth differently.

## Cross-Cutting Synthesis

- Facts first, projection second.
- Postgres rows remain the only correctness-bearing truth.
- Keep the public API narrow and idiomatic for Elixir/Phoenix/Ecto.
- Prefer deterministic matching and unmatched durable evidence over clever implicit routing.
- Preserve at-least-once delivery reality; do not promise exactly-once semantics.
- Keep Phase 19 intentionally narrow so Phase 20 can own the broader race-precedence contract cleanly.

## Inputs Used

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/milestones/v1.2-ROADMAP.md`
- `.planning/phases/16-semantics-contract-cause-vocabulary-compatibility-baseline/16-CONTEXT.md`
- `.planning/phases/17-db-first-transition-engine-command-pipeline/17-CONTEXT.md`
- `.planning/phases/18-durable-callback-outbox-recovery-attempts/18-CONTEXT.md`
- `.planning/research/SUMMARY.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/FEATURES.md`
- `.planning/research/PITFALLS.md`
- `.planning/research/STACK.md`
- `prompts/oban_powertools_context.md`
- `prompts/oban-powertools-deep-research-original-prompt.md`
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md`
- current workflow runtime/schema/test files under `lib/oban_powertools/workflow/` and `test/oban_powertools/`

## Result

- Discussion completed without reopening any area for user choice.
- The recommendations above were carried into `19-CONTEXT.md` as locked defaults for downstream planning and implementation.
