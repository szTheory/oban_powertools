# Phase 60: Execution Engine & Tracker Hooks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 60-Execution Engine & Tracker Hooks
**Areas discussed:** Double-increment prevention, Completion callback trigger, Callback failure recovery

---

## Double-increment prevention (Exactly-once progress)

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | Idempotency table (`batch_progress`) with `ON CONFLICT DO NOTHING` | ✓ |

**User's choice:** Synthesized Recommendation 1
**Notes:** User requested a deep one-shot synthesis prioritizing Ecto idioms and operability over an interactive Q&A loop. Adopted a lightweight tracking table to ensure exactly-once increments despite BEAM crashes.

---

## Completion callback trigger

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | `RETURNING *` inside worker hook | ✓ |

**User's choice:** Synthesized Recommendation 2
**Notes:** User requested zero-latency, push-based execution. Worker hooks will handle enqueueing transactionally via `RETURNING` constraints guarded by a `completed_at` nil-check.

---

## Callback failure recovery

| Option | Description | Selected |
|--------|-------------|----------|
| 1 | Flag as `callback_failed` and repair via Lifeline | ✓ |

**User's choice:** Synthesized Recommendation 3
**Notes:** Chose to surface callback exhaustion in the UI, requiring explicit Operator repair via the established Lifeline pipeline. Maintains Powertools' core thesis of honest boundaries and support truth.

---

## Claude's Discretion

None

## Deferred Ideas

None
