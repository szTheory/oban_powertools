# Phase 34: Historical Attention Projection & Runbook Entry Surfaces - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 34-historical-attention-projection-runbook-entry-surfaces
**Areas discussed:** Historical attention projection, Runbook entry surface shape, Ownership boundary and copy alignment

---

## Historical Attention Projection

| Option | Description | Selected |
|--------|-------------|----------|
| Integrated attention scoring inside existing overview buckets | Reuses the existing diagnosis-first buckets and lets history affect exemplar priority and reasons without adding a new feed. | yes |
| Separate Historical Attention secondary band | Makes historical projection visually explicit but risks dashboard sprawl and duplicated urgency semantics. | |
| Runbook-entry cards generated from top diagnosis states | Pairs history with safe next paths, but hides unsupported historical issues unless combined with the overview model. | partial |
| Drilldown-first projection with overview badges/counts only | Conservatively keeps rich interpretation on drilldowns, but under-serves first-screen triage. | |

**Selected direction:** Integrated attention scoring inside the existing overview buckets, with runbook-entry cards only for states that have honest guidance.
**Notes:** Advisor research converged on preserving Phase 28's bounded diagnosis-first overview. Historical facts should change ordering, exemplar reasons, and next-path selection only when they affect the next safe operator path.

---

## Runbook Entry Surface Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Inline runbook entry cards on overview and native drilldowns | Keeps guidance near diagnosis but risks making the overview feel like a task feed. | |
| Canonical runbook section inside `/ops/jobs/forensics` bundles | Keeps deeper guidance evidence-grounded, but makes the overview mostly a pointer. | partial |
| Lightweight hybrid | Shows compact summaries on overview/drilldowns while `/ops/jobs/forensics` owns the deeper runbook entry. | yes |
| Host-owned runbook link registry attached to diagnosis states | Honest for external systems, but too dependent on host config for first product value. | |
| Persisted checklist/runbook session model | Strong remediation continuity, but premature before Phase 35 and risks false automation claims. | |

**Selected direction:** Lightweight hybrid: compact runbook-entry summaries on overview and relevant drilldowns, with `/ops/jobs/forensics` as the canonical deeper evidence-grounded entry.
**Notes:** Phase 34 stays advisory. Persisted checklist/session state, attempted-step continuity, and remediation execution remain deferred to Phase 35.

---

## Ownership Boundary and Copy Alignment

| Option | Description | Selected |
|--------|-------------|----------|
| Presenter-owned ownership triad | Uses `Powertools-native`, `Oban Web bridge`, and `host-owned follow-up` as structured venue metadata through shared presenter/read-model seams. | yes |
| Action-intent labels first | Operator-friendly verbs such as Investigate, Remediate, and Escalate, but risks hiding ownership. | partial |
| Explicit ownership badge on every step | Maximally unambiguous but noisy and heavier than prior UI posture. | |
| Capability-matrix runbook contract | Scales into Phase 35 but may over-structure Phase 34. | partial |
| Minimal copy patch | Fast but likely creates Phase 35 cleanup debt and copy drift. | |

**Selected direction:** Presenter-owned ownership triad, with optional small internal runbook-entry structure if needed for Phase 35 reuse.
**Notes:** Action-intent labels are acceptable only when ownership and venue remain equally visible at the operator's decision point.

---

## the agent's Discretion

- Exact module, struct, and helper names for historical-attention and runbook-entry read models.
- Exact scoring weights and exemplar ordering, provided they are deterministic, bounded, and explanation-backed.
- Exact compact versus deep runbook layout split, provided `/ops/jobs/forensics` remains the canonical evidence-grounded entry.
- Exact wording polish for prerequisites, cautions, and host-owned follow-up, provided support-truth boundaries remain explicit.

## Deferred Ideas

- Persisted runbook sessions, checklists, attempted-step state, and remediation continuity.
- First-party alert delivery or escalation integrations.
- Host-configured external runbook registries as a required first-value path.
- Generic historical event feed, raw audit/history console, or table-first operator inbox.
- Machine-facing CLI/API automation contracts for runbook or remediation flows.
