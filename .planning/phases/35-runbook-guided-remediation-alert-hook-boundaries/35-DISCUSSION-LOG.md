# Phase 35: Runbook-Guided Remediation & Alert Hook Boundaries - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 35-runbook-guided-remediation-alert-hook-boundaries
**Areas discussed:** Recommendation-first scope, native remediation continuity, alert/escalation hook boundaries, ownership and proof

---

## Recommendation-First Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Accept cohesive default | Preserve runbook context in native remediation audit/evidence, add narrow host-owned escalation hook seam, and verify ownership boundaries. | yes |
| Reopen broad runbook design | Reconsider checklist/session product, automation API, or provider-owned escalation. | |
| Ask user for per-area choices | Run a broad decision interview despite prior repo defaults. | |

**Choice:** Accepted cohesive default through workflow fallback because interactive selection was unavailable in Default mode and repo-local context leaves no unresolved high-impact breakpoint.
**Notes:** Prior project/profile decisions require recommendation-first narrowing and user escalation only for public semantics, support truth, architecture boundaries, operator trust, or maintainer burden.

---

## Native Remediation Continuity

| Option | Description | Selected |
|--------|-------------|----------|
| Structured context on existing evidence | Attach stable runbook/action context to preview, execute, audit, and forensic evidence using existing Lifeline/audit seams. | yes |
| New persisted runbook session | Add a generic runbook checklist/session model. | |
| UI-only continuity | Render explanatory copy without durable evidence. | |

**Choice:** Structured context on existing evidence.
**Notes:** Phase 34 explicitly deferred persisted attempted-step context to Phase 35 but did not authorize a generic runbook execution product.

---

## Alert/Escalation Hook Boundaries

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow host-owned seam | Provide structured host hook points and truthful fallback, with host-owned delivery and downstream runbook truth. | yes |
| First-party provider adapters | Ship Slack/PagerDuty/ticketing delivery in core. | |
| No seam | Leave escalation entirely as prose with no integration point. | |

**Choice:** Narrow host-owned seam.
**Notes:** Requirements classify alert/escalation integration seams as companion/host-owned and explicitly defer first-party delivery adapters.

---

## Ownership and Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve ownership triad | Keep Powertools-native, Oban Web bridge, and host-owned follow-up distinct at every decision point and in tests. | yes |
| Flatten follow-up paths | Present all next paths as visually equivalent controls. | |
| Defer boundary proof | Rely on later docs without Phase 35 behavioral proof. | |

**Choice:** Preserve ownership triad with Phase 35 proof.
**Notes:** Existing tests already prove Phase 34 advisory labels; Phase 35 should extend those assertions through remediation and escalation boundaries.

## the agent's Discretion

- Exact naming and placement for runbook attempt metadata.
- Exact host hook API shape, provided fallback and ownership semantics are explicit.
- Exact UI layout, provided continuity stays evidence-centered and support-truthful.

## Deferred Ideas

- First-party Slack, PagerDuty, ticketing, or incident-management adapters.
- Generic runbook checklist/session product.
- CLI/API automation contracts for remediation.
- Native generic queue/job dashboard parity.
