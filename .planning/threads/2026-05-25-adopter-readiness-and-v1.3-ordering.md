# Adopter Readiness And v1.3 Ordering

Date: 2026-05-25
Status: Updated 2026-05-27 — v1.3 and v1.4 shipped; new assessment at bottom

## Question

How close is Oban Powertools to "done enough" for its current scope, and what wedge should follow `v1.2 Workflow Semantics & Recovery`?

## Repo-grounded answer

The library is already strong for a narrower and more honest scope than the original "full paid-tier equivalent" vision: a host-owned Phoenix operations layer for Oban with typed workers, durable idempotency, explicit limiter and cron controls, durable workflow semantics, Lifeline repair flows, and native operator pages with a bounded read-only Oban Web bridge.

The code, guides, example host, and proof lanes show that install, first-session, workflow diagnosis, and repair flows are real. The next meaningful gap is not another backend capability family. It is product cohesion for operators.

## Recommended next wedge

Open `v1.3 Unified Control Plane & Explainability` next.

Done enough for that milestone means:

- one consistent operator vocabulary across cron, limits, workflows, Lifeline, and audit
- one coherent diagnosis-first overview and drill-down model in the native shell
- bounded action policy and reason-preview language that feels the same across surfaces
- better support-truth around what native pages own versus what remains bridge-only or host-owned

## Concrete first win

The first concrete win for `v1.3` is not “more metrics” or “more pages.” It is making `/ops/jobs` answer three operator questions cleanly from one starting point:

1. What needs attention right now?
2. Why does it need attention?
3. Which native page or Oban Web destination should I open next?

Repo-local evidence that shapes that scope:

- `EngineOverviewLive` currently exposes counts and links, but not a diagnosis-first triage model.
- `LimitersLive`, `WorkflowsLive`, `CronLive`, and `LifelineLive` each already have useful local vocabulary, but they still present different status and next-action language.
- `LiveAuth` already centralizes some permission and mutation wording, which means v1.3 can tighten coherence by extending an existing seam rather than inventing a new abstraction family.
- The bounded Oban Web bridge is already the honest answer for generic job and queue inspection, so v1.3 should improve handoffs into that bridge rather than quietly rebuilding it.

## Activated planning shape

The milestone is now scoped as:

1. shared control-plane vocabulary and ownership contract
2. diagnosis-first overview and drill-down handoffs
3. shared preview, reason, refusal, and audit posture
4. surface cohesion across limiters, workflows, Lifeline, cron, and audit
5. docs, example-host, and proof closure for the narrower native-control-plane promise

## Suggested ordering after v1.3

1. `v1.3 Unified Control Plane & Explainability`
2. `v1.4 Operator Forensics & SRE Runbooks`
3. `v1.5 Automation Surfaces & Ecosystem Hooks`

## Explicit non-priorities

- rebuilding all generic Oban Web job/queue UI immediately
- broadening workflows into a general orchestration platform
- adding more capability families just because the original vision listed them

## Trigger to revisit

Re-check this ordering at the end of `v1.3` or earlier if planning discovers that the operator-cohesion wedge is thinner than expected.

---

## Updated Assessment — 2026-05-27 (post v1.4)

v1.3 (control plane cohesion) and v1.4 (forensics + runbooks) both shipped as predicted. Assessed again at v1.5 boundary.

### Revised done-% estimate: ~83% (80-89 band)

Backend capability is now stronger than the UI story. The main asymmetry: workflows, forensics, runbooks, lifeline, limits, and cron are all solid; but an adopter still cannot browse, filter, or inspect individual jobs natively without the Oban Web bridge.

### Revised ordering for v1.5+

1. **v1.5: Native Job Surface & Automation API** — jobs list/filter/detail/bulk-actions (QRY-01) + public mutation API + Powertools testing helpers (API-02). Closes the biggest practical adopter gap.
2. **v1.6: Batches & Composition Completion** — Batch group-of-N-jobs-→-callback (very common SaaS pattern), chains, compose helpers.
3. **v1.7: Worker Lifecycle Completion** — hooks, deadlines, output recording, field-level redaction.
4. **After v1.7:** likely at diminishing returns for target persona. Don't build prioritizer/scaler until adoption proves need.

### Why QRY-01 moved above "Automation Surfaces"

The thread suggested v1.5 = Automation Surfaces at v1.2 time when control-plane cohesion was the bottleneck. With v1.3 and v1.4 shipped, the control plane is now rich and cohesive. The bottleneck has shifted: a new adopter sees impressive forensics/runbooks but can't browse jobs without a second package. That asymmetry is more urgent than automation hooks.

### Still-explicit non-priorities

- Full generic job dashboard that replaces Oban Web entirely (overbuilding; Oban Web OSS covers it)
- Prioritizer/scaler until adoption proves demand
- Encryption until an adopter specifically requests it
