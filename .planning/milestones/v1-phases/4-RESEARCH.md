# Phase 4: Lifeline & Repair Center - Research

**Researched:** 2026-05-19  
**Domain:** Lifeline heartbeats, incident projection, repair execution safety, and archive-before-delete retention for Powertools-owned operational data [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this entire section: [VERIFIED: .planning/phases/4-CONTEXT.md]

### Locked Decisions

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

### Claude's Discretion
- Exact schema/module names, provided the incident model, preview durability, and archive-before-delete guarantees remain explicit.
- Exact fingerprint encoding and hashing mechanics, provided drift checks remain deterministic and operator-trustworthy.
- Exact pruning batch sizes and schedule wiring, provided hot-table health and archive-write-before-delete guarantees hold.
- Exact LiveView composition and panel layout, provided the UI remains evidence-first, preview-first, and consistent with the approved UI contract.

### Deferred Ideas (OUT OF SCOPE)
- Two-person approvals for broad or high-risk repairs.
- Branch/subtree-wide workflow mutation actions.
- Force-complete, skip-step, skip-edge, inject-result, or dependency-deletion repair tools.
- Per-worker or per-queue retention editing from the UI.
- Partitioned archive storage or more advanced retention topology unless production volume proves it necessary.
- Broad self-healing automation beyond conservative single-leader rescue posture.
</user_constraints>

<phase_requirements>
## Phase Requirements

Source for IDs and descriptions: [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| LIF-01 | Implement executor heartbeats tracking into `oban_powertools_heartbeats`. | Use one Powertools-owned hot heartbeat ledger keyed by stable `executor_id`, written by a supervised bulk-upsert writer on a 15s cadence, with state derived as `Healthy` / `Heartbeat Late` / `Executor Missing`. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/application.ex] |
| LIF-02 | Build an SRE-grade Dry-Run Repair Center for orphaned jobs and stuck workflows. | Keep incidents as derived read models, persist previews as durable records, recompute `incident_fingerprint` and `plan_hash` at execute time, and restrict first-cut mutations to `job` and `workflow_step`. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: .planning/phases/4-UI-SPEC.md] |
| LIF-03 | Audit all manual UI operations (retries, cancels) to `oban_powertools_audit_events`. | Reuse `ObanPowertools.Audit` and require preview consumption, mutation, and audit write in one DB transaction with actor, reason, preview token, fingerprint, plan hash, and affected counts. [VERIFIED: lib/oban_powertools/audit.ex] [VERIFIED: .planning/phases/4-CONTEXT.md] |
| LIF-04 | Implement a dynamic pruner with an archive-before-delete compliance feature. | Add Powertools-owned archive tables and explicit archive/prune APIs; do not rely on Oban OSS Pruner alone because it only deletes final Oban job states by age and has no archive step. [VERIFIED: .planning/phases/4-CONTEXT.md] [CITED: https://hexdocs.pm/oban/Oban.Plugins.Pruner.html] |
</phase_requirements>

## Summary

Phase 4 should add one new operational subsystem, not three separate mini-products: a DB-first lifeline layer that writes executor liveness, derives incidents from persisted state, stores repair previews durably, and archives evidence before any Powertools-owned hot records are pruned. That matches the repo’s existing pattern of explicit schemas plus `Ecto.Multi`-backed runtime APIs plus narrow LiveView screens. [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/explain.ex] [VERIFIED: lib/oban_powertools/workflow/runtime.ex] [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: lib/oban_powertools/web/workflows_live.ex]

The most important architecture boundary is `incident projection` versus `repair mutation`. Incidents should remain derived read models over `oban_powertools_heartbeats`, workflow step blocker state, and current `oban_jobs` rows; previews are the first durable mutable artifact; execution then mutates concrete `job` or `workflow_step` resources and writes immutable audit evidence. That boundary fits the locked Phase 4 decisions and avoids inventing a stale incident lifecycle store. [VERIFIED: .planning/phases/4-CONTEXT.md]

The retention boundary should also stay narrow. Oban OSS already provides final-state pruning for jobs, but it does not archive first and it applies one age rule to final job states. Phase 4 therefore should own archive-before-delete only for Powertools-owned evidence and copied snapshots of repair-touched job/workflow data, while continuing to deep-link generic job inspection to Oban Web instead of rebuilding or replacing Oban’s lifecycle management. [CITED: https://hexdocs.pm/oban/Oban.Plugins.Pruner.html] [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: .planning/phases/4-UI-SPEC.md]

**Primary recommendation:** Plan Phase 4 as four executable slices: `contracts`, `heartbeat + incident projection`, `repair preview + execute`, and `archive/prune + final operator surface`. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/web/router.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Executor heartbeat writes | API / Backend | Database / Storage | Heartbeats are supervised server work and the source of truth is persisted executor evidence, not browser state. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/application.ex] |
| Liveness classification (`Healthy`, `Late`, `Missing`) | API / Backend | Database / Storage | Health is derived from stored heartbeat timestamps and fixed thresholds, then rendered by the UI. [VERIFIED: .planning/phases/4-CONTEXT.md] |
| Dead-executor incident projection | API / Backend | Database / Storage | Incidents are read models joining heartbeat state to current job/workflow ownership snapshots. [VERIFIED: .planning/phases/4-CONTEXT.md] |
| Workflow-stuck incident projection | API / Backend | Database / Storage | Phase 3 already persists blocker codes and dependency snapshots, so “stuck” should be derived from persisted workflow causality rather than UI heuristics. [VERIFIED: lib/oban_powertools/workflow/step.ex] [VERIFIED: lib/oban_powertools/workflow/runtime.ex] [VERIFIED: .planning/phases/4-CONTEXT.md] |
| Repair preview generation | API / Backend | Database / Storage | Preview creation needs authorization, deterministic hashing, and durable server-side records. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/auth.ex] |
| Repair execution | Database / Storage | API / Backend | The safety requirement is one DB transaction for preview consumption, resource mutation, and audit write. [VERIFIED: .planning/phases/4-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Archive-before-delete | Database / Storage | API / Backend | Archive correctness depends on write-before-delete ordering, batched pruning, and explicit retention queries. [VERIFIED: .planning/phases/4-CONTEXT.md] |
| Lifeline/Repair LiveView | Frontend Server (SSR) | Browser / Client | The repo already uses LiveView inside `/ops/jobs`; the browser reflects server state and should not own preview or incident truth. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: .planning/phases/4-UI-SPEC.md] |
| Generic job inspection | Frontend Server (SSR) | Browser / Client | Oban Web remains the generic job admin surface by explicit project decision. [VERIFIED: .planning/phases/4-CONTEXT.md] [CITED: https://hexdocs.pm/oban_web/overview.html] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Oban | `2.22.1` (released 2026-04-30) | Canonical job states plus retry/cancel primitives and peer leadership | Phase 4 should reuse Oban’s job lifecycle and peer election rather than inventing a second queue engine. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban] [CITED: https://hexdocs.pm/oban/Oban.html] [CITED: https://hexdocs.pm/oban/Oban.Peer.html] |
| Ecto / Ecto SQL | locked `3.13.6` / `3.13.5`, current `3.14.0` (released 2026-05-19) | Transactional preview, execute, archive, and prune flows | The repo’s existing correctness-sensitive flows already use `Ecto.Multi` and Phase 4 has the same transaction shape. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: lib/oban_powertools/cron.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Phoenix LiveView | `1.1.30` (released 2026-05-05) | Native incident-first operator surface | Existing Powertools pages already mount under LiveView and Phase 4’s UI contract assumes the same shell. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: .planning/phases/4-UI-SPEC.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix.PubSub | `2.2.0` (released 2025-10-22) | Optional UI refresh nudges and workflow read-model refreshes | Use as an accelerator for page freshness, not as incident or repair truth. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_pubsub] [CITED: https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html] |
| Oban Web | `2.12.4` (released 2026-05-11) | Deep-link target for generic job internals | Use for job drill-down only; keep Powertools pages focused on lifeline, repair, and archive evidence. [VERIFIED: mix.lock] [VERIFIED: mix hex.info oban_web] [CITED: https://hexdocs.pm/oban_web/overview.html] |
| Igniter | `0.8.0` (released 2026-05-09) | Installer and migration generation | Use for Phase 4 schema additions because prior phases already extend the installer this way. [VERIFIED: mix.exs] [VERIFIED: mix hex.info igniter] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Derived incident queries | A persisted incident state machine | A stored incident lifecycle would create invalidation, deduplication, and cleanup work that the preview layer already handles more safely. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/explain.ex] |
| One heartbeat row per executor scope | Per-job leases | Per-job leases would amplify writes and contradict the locked “not per-job by default” decision. [VERIFIED: .planning/phases/4-CONTEXT.md] |
| Powertools-owned archive tables | Rely only on Oban OSS Pruner | OSS Pruner deletes final jobs by age and doesn’t archive first, which is insufficient for Phase 4 evidence rules. [CITED: https://hexdocs.pm/oban/Oban.Plugins.Pruner.html] [VERIFIED: .planning/phases/4-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** `mix hex.info` verified `oban 2.22.1 (2026-04-30)`, `oban_web 2.12.4 (2026-05-11)`, `ecto 3.13.6 / current 3.14.0 (2026-05-19)`, `ecto_sql 3.13.5 / current 3.14.0 (2026-05-19)`, `phoenix_live_view 1.1.30 (2026-05-05)`, `phoenix_pubsub 2.2.0 (2025-10-22)`, and `igniter 0.8.0 (2026-05-09)`. [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info oban_web] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info phoenix_pubsub] [VERIFIED: mix hex.info igniter]

## Architecture Patterns

### System Architecture Diagram

```text
Queue producers / execution owners
        |
        v
Supervised Heartbeat Writer
  bulk upsert every 15s
        |
        v
oban_powertools_heartbeats
  stable executor_id
  last_seen_at
  instance/node/queue/scope snapshot
        |
        +-----------------------------+
        |                             |
        v                             v
Dead Executor Projection       Workflow-Stuck Projection
join current oban_jobs         read Step.blocker_codes +
and executor snapshots         dependency snapshots
        |                             |
        +-------------+---------------+
                      |
                      v
Incident Query API
  active incidents only
  no direct mutation
                      |
               Preview Repair Plan
         recompute affected set + before/after rows
         store incident_fingerprint + plan_hash
                      |
                      v
oban_powertools_repair_previews
                      |
             reason + execute request
                      |
                      v
Ecto.Multi transaction
  lock preview
  re-read live incident state
  reject on drift
  mutate job/workflow_step
  write audit event
  write archive snapshot if required
  mark preview consumed
                      |
        +-------------+-------------+
        |                           |
        v                           v
Audit / archive evidence      LiveView refresh / deep links
                      |
                      v
Archive + Prune API
  archive-before-delete
  batched cleanup of previews, stale heartbeats,
  and repair-touched Powertools evidence
```

The planner should keep `heartbeat truth`, `incident projection`, `preview durability`, and `repair execution` as distinct backend responsibilities even if some modules are small. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/explain.ex] [VERIFIED: lib/oban_powertools/cron.ex]

### Recommended Project Structure
```text
lib/
├── oban_powertools/lifeline.ex                  # Public incident and repair API
├── oban_powertools/lifeline/heartbeat.ex        # Heartbeat schema + query helpers
├── oban_powertools/lifeline/writer.ex           # Supervised bulk-upsert writer
├── oban_powertools/lifeline/incidents.ex        # dead_executor / workflow_stuck projections
├── oban_powertools/lifeline/preview.ex          # Durable preview schema + drift hashing
├── oban_powertools/lifeline/repair.ex           # Ecto.Multi execute path
├── oban_powertools/lifeline/archive.ex          # Archive-before-delete and prune APIs
└── oban_powertools/web/lifeline_live.ex         # Native incident-first operator page
```
This matches the repo’s current split of public API, durable schemas, runtime modules, and one narrow LiveView per Powertools concept. [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/workflow/runtime.ex] [VERIFIED: lib/oban_powertools/web/router.ex]

### Pattern 1: Derived Incidents, Durable Previews
**What:** Compute incidents from live persisted state, but persist previews as first-class records. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**When to use:** Every repair-capable incident flow. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.run(:incident, fn repo, _ ->
  {:ok, Incidents.fetch!(repo, incident_id)}
end)
|> Ecto.Multi.insert(:preview, Preview.changeset(%Preview{}, attrs))
|> Repo.transact()
```

### Pattern 2: Leader-Gated Background Coordination, No Auto-Repair
**What:** Run background coordination that must be single-node only behind Oban peer leadership, but keep actual repair execution manual. [CITED: https://hexdocs.pm/oban/Oban.Peer.html] [VERIFIED: .planning/phases/4-CONTEXT.md]  
**When to use:** Archive/prune scheduling and any conservative backend rescuer or sweeper. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/oban/Oban.Peer.html
if Oban.Peer.leader?(Oban) do
  Archive.run_due_batches(repo)
end
```

### Pattern 3: Execute Inside One Transaction
**What:** Consume the preview, revalidate drift, mutate concrete resources, and write audit evidence in one DB transaction. [VERIFIED: .planning/phases/4-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]  
**When to use:** Any `Execute Repair Plan` or `Run Archive + Prune Now` action. [VERIFIED: .planning/phases/4-UI-SPEC.md]  
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.run(:preview, &lock_preview/2)
|> Ecto.Multi.run(:drift_check, &recompute_and_compare/2)
|> Ecto.Multi.run(:mutation, &apply_repair/2)
|> Ecto.Multi.insert(:audit, audit_changeset)
|> Ecto.Multi.update(:consume_preview, consume_changeset)
|> Repo.transact()
```

### Anti-Patterns to Avoid
- **Time-based orphan detection:** Oban OSS Lifeline rescues by `rescue_after`; Phase 4 must not copy that because the locked product rule is heartbeat-evidence-first. [CITED: https://hexdocs.pm/oban/Oban.Plugins.Lifeline.html] [VERIFIED: .planning/phases/4-CONTEXT.md]
- **Direct mutation from LiveView event handlers:** Current cron UI keeps preview state in assigns; Phase 4 must harden that into durable preview records before any mutation. [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: .planning/phases/4-CONTEXT.md]
- **Persisting incident state machines prematurely:** The preview layer already captures user-facing mutation state; storing mutable incident rows would create extra drift and cleanup problems. [VERIFIED: .planning/phases/4-CONTEXT.md]

## Minimum Executable Plan Split

| Plan | Must Deliver | Why This Is the Minimum Safe Slice |
|------|--------------|------------------------------------|
| 4-01 Contracts & Installer | Phase 4 migrations, schemas, public API stubs, installer updates, route placeholder, and test migrations for heartbeats, previews, and archive evidence. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] | Every later slice depends on stable storage contracts; without this, heartbeat and repair work would churn migrations and tests. |
| 4-02 Heartbeat & Incident Projection | Supervised heartbeat writer, executor identity contract, liveness classification, dead-executor queries, initial workflow-stuck projection, overview metrics, and telemetry hooks. [VERIFIED: lib/oban_powertools/application.ex] [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: lib/oban_powertools/web/engine_overview_live.ex] | This satisfies the diagnosis half of Phase 4 without exposing unsafe mutation controls early. |
| 4-03 Repair Preview & Execute | Durable preview records, preview authorization, drift hashing, reason validation, audited single-transaction execute path, and job/workflow-step repair actions. [VERIFIED: lib/oban_powertools/audit.ex] [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: .planning/phases/4-CONTEXT.md] | This is the smallest slice that fulfills LIF-02 and LIF-03 safely; UI should not ship execute buttons before this backend exists. |
| 4-04 Archive/Prune & Final LiveView | Archive-before-delete APIs, preview-first archive/prune flow, preview cleanup, heartbeat cleanup, final incident-first LiveView, Oban Web deep links, and end-to-end tests. [VERIFIED: .planning/phases/4-UI-SPEC.md] [VERIFIED: .planning/phases/4-CONTEXT.md] | Retention and final operator UX are tightly coupled because the page must show archive evidence and freshness alongside active incidents. |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cluster leadership | A custom leader-election table or `:global` wrapper | `Oban.Peer.leader?/1` and Oban peer config | Oban already coordinates one leader per instance for plugin-style work. [CITED: https://hexdocs.pm/oban/Oban.Peer.html] [CITED: https://hexdocs.pm/oban/clustering.html] |
| Generic job cancel/retry semantics | Ad hoc `UPDATE oban_jobs ...` scattered through UI code | Centralize around one repair module that uses Oban’s documented state transitions and engine/query path | Oban already defines valid retry/cancel transitions and ignores invalid states. [CITED: https://hexdocs.pm/oban/Oban.html] [VERIFIED: deps/oban/lib/oban/engines/basic.ex] |
| Generic jobs dashboard | A second native admin console | Deep-link to Oban Web | Phase 4 owns Powertools concepts, not generic job administration. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: .planning/phases/4-UI-SPEC.md] [CITED: https://hexdocs.pm/oban_web/overview.html] |
| Transaction orchestration | Manually nested repo calls with ad hoc rollback rules | `Ecto.Multi` or `Repo.transact/1` | Preview consumption, audit, and archive-before-delete need named transactional steps and rollback clarity. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |

**Key insight:** The repo already has the right primitives. Phase 4 is mostly about composing them with stricter safety guarantees, not inventing new infrastructure categories. [VERIFIED: lib/oban_powertools/audit.ex] [VERIFIED: lib/oban_powertools/telemetry.ex] [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/explain.ex]

## Common Pitfalls

### Pitfall 1: Treating job age as orphan evidence
**What goes wrong:** Long-running healthy jobs get previewed or retried as if they were dead. [VERIFIED: .planning/research/PITFALLS.md]  
**Why it happens:** Oban OSS Lifeline is time-based and looks tempting to mirror. [CITED: https://hexdocs.pm/oban/Oban.Plugins.Lifeline.html]  
**How to avoid:** Derive orphan candidates only from persisted executor heartbeats and the claimed `executor_id` snapshot. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Warning signs:** UI labels an orphan without showing `Last heartbeat` and `Detection basis` together. [VERIFIED: .planning/phases/4-UI-SPEC.md]

### Pitfall 2: Preview drift that isn’t actually safe drift
**What goes wrong:** Execute reuses a preview after the affected record set changed. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Why it happens:** Preview is treated as UI state instead of a durable server contract. [VERIFIED: lib/oban_powertools/web/cron_live.ex]  
**How to avoid:** Persist `incident_fingerprint` and `plan_hash`, then recompute on execute and reject on mismatch. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Warning signs:** A preview only stores action text or record ids but not the before/after evidence snapshot. [VERIFIED: .planning/phases/4-CONTEXT.md]

### Pitfall 3: Breaking the one-transaction rule with nested job APIs
**What goes wrong:** Audit says a repair happened even though the underlying job state mutation rolled back or drifted. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Why it happens:** Repair code performs mutation and audit as separate repo operations or hides nested transactional behavior. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [VERIFIED: deps/oban/lib/oban/repo.ex]  
**How to avoid:** Keep execute logic in one repair module and run preview lock, drift recheck, mutation, and audit in one transaction; avoid APIs that start their own retried transaction inside the outer transaction. [VERIFIED: deps/oban/lib/oban/repo.ex]  
**Warning signs:** Repair code calls out to multiple public mutation helpers after the transaction already committed. [VERIFIED: lib/oban_powertools/cron.ex]

### Pitfall 4: Letting retention become “archive everything”
**What goes wrong:** Hot tables stay bloated and archive tables become a second raw event store. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Why it happens:** The distinction between evidence-bearing and ordinary lifecycle data is ignored. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**How to avoid:** Archive only manual-repair evidence and repair-touched snapshots; keep heartbeat rows and disposable previews hot and short-lived. [VERIFIED: .planning/phases/4-CONTEXT.md]  
**Warning signs:** Heartbeats or every successful workflow result are being copied into archive tables by default. [VERIFIED: .planning/phases/4-CONTEXT.md]

## Code Examples

Verified patterns from official sources:

### Leader-gated background work
```elixir
# Source: https://hexdocs.pm/oban/Oban.Peer.html
if Oban.Peer.leader?(Oban) do
  run_archive_and_prune()
end
```

### Retrying a concrete job
```elixir
# Source: https://hexdocs.pm/oban/Oban.html
job
|> Oban.retry_job()
```

### Cancelling a concrete job
```elixir
# Source: https://hexdocs.pm/oban/Oban.html
Oban.cancel_job(job)
```

### Transactional repair composition
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.new()
|> Ecto.Multi.run(:mutation, fn repo, _changes ->
  {:ok, apply_job_or_step_change(repo)}
end)
|> Ecto.Multi.insert(:audit, audit_changeset)
|> Repo.transact()
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| “Job is stuck because it ran too long” | Executor-evidence-first liveness via heartbeats | Current Phase 4 product decision and current Oban docs still describe OSS Lifeline as `rescue_after` based. [VERIFIED: .planning/phases/4-CONTEXT.md] [CITED: https://hexdocs.pm/oban/Oban.Plugins.Lifeline.html] | Safer for long-running jobs and better aligned with manual repair UX. |
| Delete-only final-state job pruning | Archive-before-delete for Powertools-owned evidence, plus ordinary Oban pruning for generic jobs | Current Oban OSS Pruner behavior. [CITED: https://hexdocs.pm/oban/Oban.Plugins.Pruner.html] | Keeps generic job lifecycle simple while preserving manual intervention evidence. |
| Ephemeral preview state in LiveView assigns | Durable preview records with drift checks | Required by locked Phase 4 decisions. [VERIFIED: .planning/phases/4-CONTEXT.md] | Allows reconnect-safe, auditable, single-use execution. |

**Deprecated/outdated:**
- Treating the current cron preview pattern as sufficient for repair actions is outdated for Phase 4 because cron previews are not durable preview records. [VERIFIED: lib/oban_powertools/web/cron_live.ex] [VERIFIED: .planning/phases/4-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `plan_hash` / `incident_fingerprint` should use OTP `:crypto` hashing rather than a custom encoder-specific digest implementation. [ASSUMED] | Security Domain | Low; the planner can swap the exact hashing helper, but hand-rolled hashing should still be rejected. |

## Open Questions

1. **How broad should first-cut `workflow_stuck` detection be?** [VERIFIED: .planning/phases/4-CONTEXT.md]
   What we know: workflow repair must stay step-oriented and cannot rely on generic runtime-duration heuristics. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/workflow/runtime.ex]
   What's unclear: whether the first release should flag only dead-executor-derived workflow stalls or also blocker-only stalls with no missing executor. [VERIFIED: .planning/phases/4-CONTEXT.md]
   Recommendation: plan the first incident query around persisted blocker evidence plus missing-executor ancestry, then widen later if a clean non-time-based stalled-workflow rule emerges. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/workflow/step.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | app/runtime/tests | ✓ | `1.19.5` | — |
| Mix | dependency and test commands | ✓ | `1.19.5` | — |
| PostgreSQL client | repo-backed local verification | ✓ | `14.17` | — |

**Missing dependencies with no fallback:**
- None. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: psql --version]

**Missing dependencies with fallback:**
- None. [VERIFIED: elixir --version] [VERIFIED: mix --version] [VERIFIED: psql --version]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox and LiveView tests. [VERIFIED: test/test_helper.exs] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] |
| Config file | `test/test_helper.exs` plus `config/test.exs`. [VERIFIED: test/test_helper.exs] [VERIFIED: config/test.exs] |
| Quick run command | `mix test test/oban_powertools/workflow_coordinator_test.exs test/oban_powertools/web/live/cron_live_test.exs -x` [VERIFIED: test/oban_powertools/workflow_coordinator_test.exs] [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] |
| Full suite command | `mix test` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIF-01 | Heartbeats upsert per executor scope and classify `Healthy/Late/Missing`. | unit/integration | `mix test test/oban_powertools/lifeline/heartbeat_test.exs -x` | ❌ Wave 0 |
| LIF-02 | Preview generation shows before/after scope and execute rejects drift. | integration/LiveView | `mix test test/oban_powertools/lifeline/repair_test.exs test/oban_powertools/web/live/lifeline_live_test.exs -x` | ❌ Wave 0 |
| LIF-03 | Manual retry/cancel writes immutable audit evidence with actor and reason. | integration | `mix test test/oban_powertools/lifeline/repair_test.exs -x` | ❌ Wave 0 |
| LIF-04 | Archive writes happen before delete and prune runs in batches. | integration | `mix test test/oban_powertools/lifeline/archive_test.exs -x` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/lifeline/heartbeat_test.exs test/oban_powertools/lifeline/repair_test.exs -x` [VERIFIED: test/test_helper.exs]
- **Per wave merge:** `mix test` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green before `/gsd-verify-work`. [VERIFIED: test/test_helper.exs]

### Wave 0 Gaps
- [ ] `test/support/migrations/3_phase_4_tables.exs` — Phase 4 tables must exist in test bootstrap. [VERIFIED: test/test_helper.exs]
- [ ] `test/oban_powertools/lifeline/heartbeat_test.exs` — covers LIF-01.
- [ ] `test/oban_powertools/lifeline/repair_test.exs` — covers LIF-02 and LIF-03.
- [ ] `test/oban_powertools/lifeline/archive_test.exs` — covers LIF-04.
- [ ] `test/oban_powertools/web/live/lifeline_live_test.exs` — covers incident-first preview/execute UI contract. [VERIFIED: .planning/phases/4-UI-SPEC.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep auth host-owned through `ObanPowertools.Auth.current_actor/1`. [VERIFIED: lib/oban_powertools/auth.ex] |
| V3 Session Management | no | Session ownership stays in the host app; Powertools only consumes the resolved actor. [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| V4 Access Control | yes | Separate `:preview_repair` and `:execute_repair` authorization checks in LiveView/backend APIs. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/live_auth.ex] |
| V5 Input Validation | yes | Validate preview ids, reasons, action types, and affected target ids through changesets and explicit execute APIs. [VERIFIED: lib/oban_powertools/audit.ex] [VERIFIED: .planning/phases/4-CONTEXT.md] |
| V6 Cryptography | yes | Use OTP `:crypto` for drift hashes and fingerprints; never hand-roll hash functions. [ASSUMED] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized manual repair | Elevation of Privilege | Gate both preview and execute through `ObanPowertools.Auth` and re-check on execute. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/auth.ex] |
| Drifted preview replay | Tampering | Single-use preview tokens plus `incident_fingerprint` and `plan_hash` recomputation. [VERIFIED: .planning/phases/4-CONTEXT.md] |
| Reasonless destructive action | Repudiation | Mandatory non-trivial reason capture and immutable audit row. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/audit.ex] |
| Telemetry cardinality blow-up | Denial of Service | Keep executor ids and job ids out of metrics and only in DB evidence. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/telemetry.ex] |

## Sources

### Primary (HIGH confidence)
- [`.planning/phases/4-CONTEXT.md`](./4-CONTEXT.md) - locked decisions, safety posture, retention rules, and scope.
- [`.planning/phases/4-UI-SPEC.md`](./4-UI-SPEC.md) - incident-first UI contract and preview drift behavior.
- [`.planning/ROADMAP.md`](../ROADMAP.md) - Phase 4 goal, dependency, and success criteria.
- [`.planning/REQUIREMENTS.md`](../REQUIREMENTS.md) - LIF-01 through LIF-04 requirements.
- [`.planning/STATE.md`](../STATE.md) - current project focus and sequencing.
- [`lib/oban_powertools/application.ex`](../../lib/oban_powertools/application.ex) - current supervision extension point.
- [`lib/oban_powertools/audit.ex`](../../lib/oban_powertools/audit.ex) - normalized audit boundary.
- [`lib/oban_powertools/cron.ex`](../../lib/oban_powertools/cron.ex) - current transaction-oriented operator action pattern.
- [`lib/oban_powertools/explain.ex`](../../lib/oban_powertools/explain.ex) - snapshot-aware evidence pattern.
- [`lib/oban_powertools/telemetry.ex`](../../lib/oban_powertools/telemetry.ex) - low-cardinality telemetry boundary.
- [`lib/oban_powertools/workflow/runtime.ex`](../../lib/oban_powertools/workflow/runtime.ex) - persisted workflow causality and blocker semantics.
- [`lib/oban_powertools/web/cron_live.ex`](../../lib/oban_powertools/web/cron_live.ex) - current preview-first UI shape and its durability gap.
- [`lib/oban_powertools/web/workflows_live.ex`](../../lib/oban_powertools/web/workflows_live.ex) - step-oriented workflow inspection model.
- [`lib/oban_powertools/web/router.ex`](../../lib/oban_powertools/web/router.ex) - `/ops/jobs` shell integration point.
- [`lib/mix/tasks/oban_powertools.install.ex`](../../lib/mix/tasks/oban_powertools.install.ex) - installer/migration pattern.
- [`test/test_helper.exs`](../../test/test_helper.exs) - current test bootstrap and migration loading.
- [`deps/oban/lib/oban/engines/basic.ex`](../../deps/oban/lib/oban/engines/basic.ex) - concrete cancel/retry state update behavior.
- [`deps/oban/lib/oban/repo.ex`](../../deps/oban/lib/oban/repo.ex) - transaction retry and nested transaction warning for extensions.

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/oban/Oban.html - cancel/retry APIs and queue/job lifecycle helpers.
- https://hexdocs.pm/oban/Oban.Peer.html - peer leadership contract.
- https://hexdocs.pm/oban/clustering.html - leader-only plugin behavior and peer modes.
- https://hexdocs.pm/oban/Oban.Plugins.Pruner.html - delete-only pruning semantics.
- https://hexdocs.pm/oban/Oban.Plugins.Lifeline.html - time-based rescue behavior in OSS Lifeline.
- https://hexdocs.pm/oban_web/overview.html - native bridge boundary for generic job inspection.
- https://hexdocs.pm/ecto/Ecto.Multi.html - transaction composition pattern.
- https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html - pubsub as accelerator, not source of truth.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions were verified locally with `mix hex.info` and the architectural fit is consistent with current repo code. [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info phoenix_live_view]
- Architecture: HIGH - the dominant boundaries are directly constrained by locked Phase 4 decisions and existing module patterns. [VERIFIED: .planning/phases/4-CONTEXT.md] [VERIFIED: lib/oban_powertools/cron.ex] [VERIFIED: lib/oban_powertools/explain.ex]
- Pitfalls: HIGH - the biggest failure modes are explicitly documented by project context and current Oban docs. [VERIFIED: .planning/research/PITFALLS.md] [CITED: https://hexdocs.pm/oban/Oban.Plugins.Lifeline.html] [CITED: https://hexdocs.pm/oban/Oban.Plugins.Pruner.html]

**Research date:** 2026-05-19  
**Valid until:** 2026-06-18 for repo-structure guidance; recheck Hex package versions and Oban docs if planning slips past that date. [VERIFIED: mix hex.info oban] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info oban_web]
