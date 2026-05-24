# Phase 18: Durable Callback Outbox & Recovery Attempts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `18-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-24T11:02:00Z
**Phase:** 18-durable-callback-outbox-recovery-attempts
**Areas discussed:** Callback event surface, Callback payload contract, Recovery attempt modeling, Callback failure posture

---

## Callback event surface

| Option | Description | Selected |
|--------|-------------|----------|
| `workflow.terminal` + `workflow.recovery_completed` only | Smallest workflow-scoped contract; host branches on durable payload fields instead of many event names | ✓ |
| Distinct workflow-level terminal events plus `workflow.recovery_completed` | More explicit event names, but broader public contract and more semver burden | |
| Broad callback matrix with per-step hooks and policy controls | Most flexible, but drifts toward generic event-bus design and larger support surface | |

**User's choice:** Use the strong default recommendation and shift it left in GSD.
**Notes:** Lock the narrow workflow-scoped contract for Phase 18 and defer broader callback policy expansion.

---

## Callback payload contract

| Option | Description | Selected |
|--------|-------------|----------|
| Thin versioned event envelope | Stable IDs and durable semantic fields only; richer details fetched by ID | ✓ |
| Envelope plus curated semantic snapshot | Better one-shot ergonomics, but snapshot fields become sticky public API | |
| Highly customizable or host-defined payloads | Flexible, but high semver, redaction, and support burden | |

**User's choice:** Use the strong default recommendation and shift it left in GSD.
**Notes:** Keep payloads thin, versioned, support-truthful, and safe by default. Do not embed result payloads or arbitrary host metadata.

---

## Recovery attempt modeling

| Option | Description | Selected |
|--------|-------------|----------|
| Step-scoped recovery rows only | Simple and close to current code, but weak for grouped operator UX and multi-step auditability | |
| Workflow-level grouped recovery session only | Good header UX, but too coarse for exact per-step recovery truth | |
| Recovery session header plus append-only per-step attempt rows | One grouped operator action plus exact step-level durable evidence | ✓ |

**User's choice:** Use the strong default recommendation and shift it left in GSD.
**Notes:** Keep the public API step-oriented for now, but attach attempts to a workflow-level session header internally.

---

## Callback failure posture

| Option | Description | Selected |
|--------|-------------|----------|
| Workflow truth commits first; callback delivery retries independently | DB-first, crash-safe, at-least-once, least-surprise support truth | ✓ |
| Callback success gates terminal workflow success | Stronger external-ack semantics, but violates Postgres-first truth and creates stranded workflows | |
| Two-layer outcome with separate delivery posture surfaced publicly | Helpful as a read model later, but delivery posture must stay separate from workflow truth | |
| Per-callback policy matrix with optional strict gating | Flexible, but too broad and risky for Phase 18 | |

**User's choice:** Use the strong default recommendation and shift it left in GSD.
**Notes:** Workflow outcome and callback delivery posture must stay separate. Delivery failures become durable outbox evidence, not workflow-state rollback.

---

## the agent's Discretion

- Exact callback envelope key names.
- Exact dispatcher module names and leasing helper structure.
- Exact retry backoff schedule for callback redelivery.
- Exact split between recovery session typed columns and bounded metadata.

## Deferred Ideas

- Broader callback policy matrix or per-step callback hooks.
- Rich snapshot callback payloads or host-custom payload builders.
- Generic event-sourced workflow history.
- Callback-ack-gated workflow completion semantics.
