# Phase 4: Lifeline & Repair Center - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the first Powertools lifeline and repair layer for Day-2 operations:
executor heartbeat monitoring,
incident detection for dead executors and stuck workflows,
an auditable dry-run repair flow,
and archive-before-delete retention for evidence-bearing operational data.

This phase is about safe diagnosis and explicit manual remediation.
It is not a full self-healing system, not broad workflow mutation tooling,
and not a generic replacement for Oban Web job administration.

</domain>

<decisions>
## Implementation Decisions

### Decision-Making Default
- **D-01:** Downstream agents should treat the recommendations in this context as the default product and architecture direction and only reopen a choice when it would materially affect correctness, operator safety, durability, public API stability, or user-visible repair semantics.
- **D-02:** Shift defaults left in GSD for this project: prefer explicit best-practice recommendations over re-asking or re-litigating tradeoffs, except for unusually high-impact choices that would materially change the product vision or safety posture.
- **D-03:** Phase 4 should remain coherent with the existing Powertools DNA from earlier phases: host-owned auth, Postgres/Ecto-native truth, low-cardinality telemetry, explain-then-act operator UX, and preview-first mutation controls.

### Heartbeat and Liveness Semantics
- **D-04:** Phase 4 heartbeat semantics are executor-evidence-first: orphan detection must be based on persisted executor heartbeat state, never job runtime alone.
- **D-05:** Executor identity should be a stable logical execution owner derived from Oban instance, node, queue/producer scope, and restart-safe slot identity. Raw pid values are not part of the public identity contract.
- **D-06:** Heartbeats should be modeled per execution owner / producer scope rather than only per whole node and not per-job by default. This gives better fidelity than node-only semantics without per-job lease write amplification.
- **D-07:** Every executing Powertools-managed job must snapshot its `executor_id` at claim/start so later preview and repair logic evaluate the exact owner that held the job.
- **D-08:** Heartbeats are written by a dedicated supervised process as durable bulk upserts on a fixed cadence. Workers do not renew per-job heartbeat rows by default.
- **D-09:** Default heartbeat cadence is 15 seconds. Default warning threshold is 45 seconds. Default missing threshold is 120 seconds.
- **D-10:** Operator UX must distinguish `Healthy`, `Heartbeat Late`, and `Executor Missing`. Only missing executors may generate `Orphan Candidate` incidents.
- **D-11:** Repair actions must never execute against `Heartbeat Late` executors. Late is a warning state, not a mutation permission.
- **D-12:** Automatic rescue coordination, if any exists in backend internals, must be single-leader and conservative. Phase 4 should not introduce competing multi-node repair loops.
- **D-13:** Rescuing work from missing executors must remain conservative for non-idempotent jobs. Do not blindly retry exhausted jobs by default.

### Incident Model and Repair Scope
- **D-14:** Repair detection is incident-based, while repair mutation is resource-based.
- **D-15:** Phase 4 incident classes are only `dead_executor` and `workflow_stuck`.
- **D-16:** Executor heartbeats are the only basis for orphan detection. Job age alone is never sufficient to declare an orphan.
- **D-17:** First-cut mutable targets are `job` and `workflow_step`, not `workflow_branch`, `workflow`, or `executor`.
- **D-18:** Executor incidents may preview repairs affecting multiple orphaned jobs for one dead executor, but execution and audit evidence must remain explicit about the concrete jobs and workflow steps touched.
- **D-19:** Workflow-step repair must map explicitly to persisted workflow step and underlying job state. No hidden “workflow magic” actions are allowed.
- **D-20:** Blocked descendants are shown as affected scope and projected consequences in the preview, not as first-cut direct repair targets.
- **D-21:** Phase 4 allowed manual repair actions are narrow:
  orphaned job rescue from a dead executor,
  manual retry of a single job,
  manual cancel of a single job,
  manual retry of a single workflow step,
  and manual cancel of a single workflow step.
- **D-22:** Phase 4 must not ship force-complete, skip-step, skip-edge, inject-result, delete-dependency, generic “repair workflow”, or branch/subtree-wide retry/cancel actions.
- **D-23:** Repair previews must show before/after state rows and affected counts before raw ids or low-level payload details.

### Preview, Drift, and Safety Gates
- **D-24:** All Phase 4 repair actions must follow `preview -> reason -> execute`. No direct mutating action should exist from incident rows or detail panels.
- **D-25:** A repair preview is a durable server-side record, not only ephemeral LiveView assign state.
- **D-26:** Every preview stores both an `incident_fingerprint` and a `plan_hash`. Execute must recompute and reject on mismatch as `Preview Drifted`.
- **D-27:** Drift is defined by changes to incident-defining safety fields and affected record set, not arbitrary timestamp churn.
- **D-28:** Execute must be single-use per preview token and idempotent under retries, reconnects, or double-submits.
- **D-29:** Preview generation and execute must both be separately authorized. Auth remains host-owned through `ObanPowertools.Auth`, with distinct actions for `:preview_repair` and `:execute_repair`.
- **D-30:** Reason capture is mandatory and validated for specificity. Blank or trivial reasons should be rejected.
- **D-31:** Repair execution, preview consumption, and immutable audit write must happen in one DB transaction.
- **D-32:** Audit events for manual repair must capture preview token, incident class, incident fingerprint, plan hash, actor, reason, result, and affected counts.
- **D-33:** Two-person approval is deferred. Schema and audit design may reserve room for later approval workflows, but they are not part of Phase 4 execution semantics.

### Archive, Prune, and Evidence Retention
- **D-34:** Archive-before-delete applies only to evidence-bearing records, not to all lifecycle data.
- **D-35:** Raw heartbeat rows are ephemeral operational samples and must not be durably archived in Phase 4.
- **D-36:** Default raw heartbeat hot retention is short-lived, approximately 6 hours, with pruning in small batches.
- **D-37:** Repair previews are disposable drafts. Only executed repairs produce durable evidence by default.
- **D-38:** Default preview retention is approximately 7 days, with earlier cleanup allowed after execute or drift invalidation.
- **D-39:** Any manual repair, cancel, or retry action must persist an immutable audit event plus an evidence snapshot before related hot records become prune-eligible.
- **D-40:** Workflow/job evidence touched by manual repair inherits the audit archive policy. Untouched successful workflow history does not.
- **D-41:** Retention is class-based in Phase 4, not per-worker or per-queue configurable from the UI.
- **D-42:** Default hot retention should stay modest and operator-friendly:
  audit rows around 90 days hot,
  archived manual-intervention evidence around 400 days,
  successful workflow evidence around 14 days,
  failed/cancelled/discarded or repair-touched workflow evidence around 30 days before archive/prune policies apply.
- **D-43:** Archive and prune actions must be batched, auditable, and executed through explicit public APIs, not ad hoc SQL or manual console playbooks.
- **D-44:** Deletion of source rows may occur only after archive writes succeed for archive-required record classes.
- **D-45:** Phase 4 should prefer plain tables plus disciplined pruning and autovacuum posture. Partitioned archive storage is deferred unless production volume proves it necessary.

### Operator UX and System Boundaries
- **D-46:** Keep the hybrid shell direction: Powertools owns lifeline incidents, workflow causality, repair preview, retention posture, and audit evidence. Generic job internals remain in Oban Web.
- **D-47:** The primary page posture is incident-first. Landing state should default to active incidents, not archive history or retention configuration.
- **D-48:** Detection evidence must always be shown before mutation controls. The page should answer:
  is the executor actually missing or only late,
  what exact state will change,
  what records are affected,
  and whether the preview has drifted.
- **D-49:** `Run Archive + Prune Now` should follow the same preview-first, reason-required, drift-aware posture as repair actions.
- **D-50:** UI-driven free-form retention editing is out of scope for Phase 4. Retention policy remains code-owned or installer-owned in v1.

### Telemetry, Audit, and Non-Goals
- **D-51:** Lifeline telemetry remains low-cardinality and operator-oriented, using coarse metadata such as action, queue, incident class, and health state. Executor ids and job ids belong in durable DB evidence and audit rows, not metric labels.
- **D-52:** Repair and retention operations should extend the existing normalized telemetry/audit posture from Phases 2 and 3 rather than inventing a separate event model.
- **D-53:** Phase 4 must not become a full self-healing orchestrator, generic policy editor, or broad historical archive product.
- **D-54:** Phase 4 must not treat time-based “running too long” heuristics as the source of truth for orphaning or workflow repair safety.

### the agent's Discretion
- Exact schema/module names, provided the incident model, preview durability, and archive-before-delete guarantees remain explicit.
- Exact fingerprint encoding and hashing mechanics, provided drift checks remain deterministic and operator-trustworthy.
- Exact pruning batch sizes and schedule wiring, provided hot-table health and archive-write-before-delete guarantees hold.
- Exact LiveView composition and panel layout, provided the UI remains evidence-first, preview-first, and consistent with the approved UI contract.

</decisions>

<specifics>
## Specific Ideas

- Preferred executor identity feel:
  `my_app:oban:default:node-a:producer-2`
  not raw pid strings or opaque VM references.
- Preferred operator state ladder:
  `Healthy -> Heartbeat Late -> Executor Missing -> Orphan Candidate`.
- Preview payloads should read like:
  “Dead executor `node-a / producer-2` last heartbeated 2m 13s ago.
  Proposed changes: requeue 3 orphaned jobs, leave 1 exhausted job unchanged.
  Affected workflows: 2 workflows, 4 blocked descendants become runnable.”
- Workflow repair should stay step-oriented:
  preview one step retry/cancel,
  show descendant consequences,
  avoid magical “heal the whole graph” controls.
- Audit evidence should preserve what the operator saw:
  incident snapshot,
  proposed transition summary,
  actor,
  reason,
  and affected scope counts.
- Archive posture should feel pragmatic rather than enterprise-theater:
  keep hot tables lean,
  retain manual-intervention evidence,
  do not archive noisy heartbeat spam.
- Preference from this discussion: downstream GSD agents should assume these recommendations are the paved road and avoid reopening them unless a later implementation constraint clearly forces a revisit.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap and requirements
- `.planning/ROADMAP.md` — Phase 4 scope, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — LIF-01, LIF-02, LIF-03, and LIF-04 requirements.
- `.planning/STATE.md` — current project posture and explicit focus on Phase 4 planning.

### Prior phase context
- `.planning/phases/0-CONTEXT.md` — hybrid shell strategy, host-owned auth posture, and low-cardinality telemetry contract.
- `.planning/phases/2-CONTEXT.md` — explain-then-act operator UX, normalized audit posture, dynamic cron/operator action patterns, and explicit smart-engine semantics.
- `.planning/phases/3-CONTEXT.md` — workflow persistence/source-of-truth semantics, read-only workflow inspection posture, dependency blocker modeling, and non-goals around mutation before repair tooling exists.
- `.planning/phases/4-UI-SPEC.md` — approved Phase 4 operator UI contract, labels, page zones, and preview drift behavior.

### Project research and vision
- `.planning/research/SUMMARY.md` — project-wide architecture, pitfall posture, and Phase 4 roadmap direction.
- `.planning/research/ARCHITECTURE.md` — recommended lifeline/repair component boundary and Ecto-native operational model.
- `.planning/research/operator_ux.md` — dry-run repair center, explainability, and hybrid shell rationale.
- `.planning/research/domain_competitors.md` — competitor footguns around orphaning, workflows, and repair semantics.
- `.planning/research/PITFALLS.md` — project risk patterns and anti-footguns relevant to operational repair and retention.
- `.planning/research/STACK.md` — Phoenix/OTP/PubSub context for integrating lifeline supervision and operator pages.
- `.planning/research/tech_architecture.md` — supporting architecture guidance for DB truth, plugins, and integration posture.

### Product and prompt guidance
- `prompts/oban_powertools_context.md` — project domain language, personas, liveness/repair vocabulary, and product posture.
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` — hybrid UI strategy and native Powertools surface ownership.
- `prompts/oban-powertools-deep-research-original-prompt.md` — maintainer intent, ecosystem lessons, and “ultimate lib” quality bar.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/oban_powertools/application.ex`: existing supervision extension point for adding heartbeat/lifeline coordinators alongside PubSub and workflow coordination.
- `lib/oban_powertools/audit.ex`: normalized durable audit writer/reader that should be extended for preview and repair evidence rather than bypassed.
- `lib/oban_powertools/telemetry.ex`: existing low-cardinality telemetry boundary; lifeline/repair events should follow this shape.
- `lib/oban_powertools/explain.ex`: strongest in-repo analog for snapshot-aware “live now vs captured evidence” semantics; Phase 4 incident previews should mirror this posture.
- `lib/oban_powertools/cron.ex`: existing preview-first operator action flow, audit writes, and transaction-oriented action semantics provide the closest mutation analog.
- `lib/oban_powertools/web/cron_live.ex`: current preview UI shape is a good UX predecessor, but its preview durability and audit fidelity are not strong enough for repair.
- `lib/oban_powertools/web/workflows_live.ex`: current step-oriented, explanation-first workflow detail view is the right conceptual base for workflow-step repair preview.
- `lib/oban_powertools/web/router.ex`: existing `/ops/jobs` shell routing already establishes where lifeline and repair routes should live.
- `lib/oban_powertools/web/engine_overview_live.ex`: current overview-card posture can absorb new high-level lifeline health counts without rebuilding the shell.

### Established Patterns
- Public APIs are explicit and grep-able rather than magical.
- Ecto-backed durable state and `Ecto.Multi`-style transactional semantics are the paved road for correctness-sensitive actions.
- Telemetry is low-cardinality and durable evidence belongs in DB rows and audit artifacts.
- Native Powertools pages stay focused on Powertools-owned concepts and defer generic job internals to Oban Web.
- Preview-first operator actions already exist conceptually; Phase 4 should strengthen their trust and evidence model rather than change the UX posture.

### Integration Points
- Add heartbeat/lifeline supervision under the existing application supervisor.
- Extend the native `/ops/jobs` shell with a lifeline/repair surface and archive/prune visibility.
- Reuse auth and audit infrastructure for preview and execute gates.
- Reuse workflow blocker and dependency evidence when rendering workflow-stuck incidents.
- Reuse the normalized telemetry boundary for repair previews, executes, and archive/prune runs.

</code_context>

<deferred>
## Deferred Ideas

- Two-person approvals for broad or high-risk repairs.
- Branch/subtree-wide workflow mutation actions.
- Force-complete, skip-step, skip-edge, inject-result, or dependency-deletion repair tools.
- Per-worker or per-queue retention editing from the UI.
- Partitioned archive storage or more advanced retention topology unless production volume proves it necessary.
- Broad self-healing automation beyond conservative single-leader rescue posture.

</deferred>

---

*Phase: 4-lifeline-repair-center*
*Context gathered: 2026-05-19*
