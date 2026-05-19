# Oban Powertools — Ultimate Batteries-Included Brief with Efficient Web/UI Strategy

**Status:** revised after feedback that Powertools should include the paid-tier capability categories from Oban Pro, Oban Web, Sidekiq Pro, Sidekiq Enterprise, and adjacent ecosystems, while avoiding unnecessary reimplementation of the now-open-source Oban Web where reuse gives a better velocity/quality tradeoff.

**Core decision:** build a **full batteries-included Oban paid-tier equivalent** in capability, but use a **hybrid web strategy**:

1. **Backend/features:** build Powertools-owned equivalents for the Pro/Enterprise feature categories you need: global concurrency, rate limits, partitioning/fairness, unique/dedupe, bulk inserts, structured/encrypted/recorded jobs, deadlines, signals, chains, batches, chunks, workflows, dynamic cron, dynamic queues, prioritizer, pruner, scaler, lifeline/repair, relay, decorators, testing, telemetry, audit, and SRE diagnostics.
2. **UI v1:** do **not** redo generic Oban Web job/queue tables/charts/search from scratch immediately. Oban Web is now open source and already covers the baseline dashboard layer: embedded LiveView, realtime charts, live updates, filtering, job inspection, batch actions, queue controls, multiple dashboards, access control, and action logging.
3. **Powertools Web v1:** build your own **native Powertools Ops Console** for everything Oban Web does not understand: Powertools limiters, partitions, receipts, dedupe fingerprints, custom batches, chunks, workflows, signals, dynamic cron/queues/prioritizer/pruner/scaler/lifeline, doctor findings, retention/bloat, audit, runbooks, and SRE views.
4. **Bridge:** optionally mount Oban Web under the same ops area and share auth, redaction, audit, and telemetry. This gives a cohesive operator experience without spending months rebuilding mature generic job UI.
5. **Full native UI later:** design Powertools Web so it can eventually grow into a full Oban Web equivalent if needed, but do that after Powertools backend concepts stabilize and only if the bridge becomes limiting.

That is the best-of-both-worlds plan: **ship the paid-tier functionality categories aggressively, but do not waste early effort rebuilding an OSS dashboard that already solves the generic job/queue UI well.**

---

## 1. Product intent

Oban Powertools is an MIT-licensed, Postgres-only, host-owned Elixir/Phoenix/Oban library for solo founders, indie hackers, small teams, and internal projects that need paid-tier operational power but cannot justify paid subscriptions.

The library should be honest about support:

```md
Oban Powertools is built for my own use and shared as-is. It does not include
commercial support, SLA, consulting, or compatibility promises beyond the
public API documented in this project. If your business can afford Oban Pro,
you should consider buying Oban Pro and supporting that ecosystem.
```

But the product goal is still explicit:

> Powertools should deliver the same *classes of value* that developers look for in Oban Pro, Oban Web, Sidekiq Pro, and Sidekiq Enterprise: safer execution, richer composition, dynamic runtime control, dashboard-driven operations, telemetry, repair tools, and production ergonomics.

This is **not** a timid companion library. It is a full batteries-included OSS operations layer for Oban.

---

## 2. The key UI question

You asked whether Powertools should redo all of Oban Web now that Oban Web is open source.

The best answer is:

> **No, not initially. Build Powertools Web as a native extension console plus an optional Oban Web bridge. Keep the architecture capable of becoming a full native dashboard later.**

Why:

- Oban Web is now open source and Apache-2.0 as of v2.11; previous versions were commercial/private.
- Current Oban Web already handles the baseline operational UI: embedded LiveView, realtime charts, live updates, filtering, detailed job inspection, batch actions, queue controls, multiple dashboards, access control, and action logging.
- Its public docs expose useful mount/customization surfaces: router options, resolver callbacks, access controls, user resolution, formatting/redaction callbacks, query limits, refresh defaults, on-mount hooks, CSP nonce support, and action telemetry.
- The public docs do **not** appear to expose a general plugin API for adding arbitrary custom pages inside Oban Web’s own navigation. That makes a fork-first plan expensive and brittle.
- The highest-value Powertools UI pages are not generic job lists. They are pages for Powertools-owned concepts: limiters, workflows, batches, signals, doctor checks, dynamic plugins, repair, retention, and audit.

So the right plan is a **three-layer web architecture**.

---

## 3. Recommended web architecture

### 3.1 Layer A — Powertools Web Shell

This is your own UI. It owns:

- top-level ops route structure
- Powertools dashboard overview
- navigation for Powertools features
- shared auth policy
- read-only mode
- dangerous-action confirmation UX
- audit display
- redaction policy
- runbook links
- SRE/Parapet summary views
- optional links into Oban Web

Suggested routes:

```text
/ops/jobs                         -> Powertools overview
/ops/jobs/limiters                -> global rate/concurrency/fairness
/ops/jobs/partitions              -> tenant/group/partition fairness
/ops/jobs/dedupe                  -> fingerprints and conflicts
/ops/jobs/idempotency             -> receipts and replay safety
/ops/jobs/cron                    -> Powertools dynamic cron
/ops/jobs/queues                  -> Powertools runtime queues/scaling
/ops/jobs/priorities              -> dynamic prioritizer/starvation
/ops/jobs/pruning                 -> retention, bloat, partitions
/ops/jobs/batches                 -> Powertools batches
/ops/jobs/chunks                  -> chunk processors
/ops/jobs/workflows               -> DAGs/chains/barriers/signals
/ops/jobs/lifeline                -> stuck/orphan repair
/ops/jobs/relay                   -> durable task calls/results
/ops/jobs/doctor                  -> diagnostics
/ops/jobs/audit                   -> operator actions
/ops/jobs/runbooks                -> remediation guidance
/ops/jobs/settings                -> config and safety policy
```

The shell should be the “source of truth” for Powertools concepts. Oban Web does not know your Powertools tables, state machines, receipts, leases, signals, dynamic plugin configs, or repair findings.

### 3.2 Layer B — Oban Web Bridge

This is optional but should be the **default recommended installer path** because Oban Web is free/open source and saves a large amount of work.

It owns:

- mounting Oban Web under the same ops area
- sharing current-user resolution
- sharing access-control policy
- sharing redaction/formatting policy for args/meta/recorded output
- sharing action telemetry into Powertools audit
- linking from Powertools concepts to relevant Oban Web job/queue views
- linking from Oban Web-related activity back into Powertools audit/runbooks where possible

Suggested route:

```text
/ops/jobs/oban                    -> mounted Oban Web dashboard
```

Example router shape:

```elixir
scope "/ops/jobs", MyAppWeb do
  pipe_through [:browser, :require_ops_user]

  live_session :oban_powertools,
    on_mount: [{MyAppWeb.RequireOpsUser, :jobs}] do
    live "/", ObanPowertoolsWeb.OverviewLive
    live "/limiters", ObanPowertoolsWeb.LimitersLive
    live "/workflows", ObanPowertoolsWeb.WorkflowsLive
    live "/batches", ObanPowertoolsWeb.BatchesLive
    live "/doctor", ObanPowertoolsWeb.DoctorLive
    live "/audit", ObanPowertoolsWeb.AuditLive
  end
end

# Optional bridge if oban_web is installed.
scope "/ops/jobs" do
  pipe_through [:browser, :require_ops_user]

  import Oban.Web.Router

  oban_dashboard "/oban",
    resolver: MyAppWeb.ObanPowertoolsObanWebResolver,
    on_mount: [MyAppWeb.ObanPowertoolsLiveUser],
    logo_path: "/ops/jobs"
end
```

### 3.3 Layer C — Powertools Native Job UI Fallback

Some users may not want to install `oban_web`, even though it is OSS. Powertools should not hard-fail in that case.

Ship a small fallback first:

```text
/ops/jobs/raw/jobs                -> minimal job list
/ops/jobs/raw/jobs/:id            -> minimal job detail
/ops/jobs/raw/queues              -> minimal queue list
```

The fallback should initially be simple and safe:

- read-only by default
- bounded query limits
- safe redaction
- no fancy realtime charts
- no broad bulk actions until tested

This provides independence without making “rebuild all Oban Web” a v0.1/v0.2 requirement.

### 3.4 Layer D — Full Native All-in-One Console Later

After Powertools backend features stabilize, consider a full native all-in-one console if the bridge becomes painful.

Build it when at least two of these are true:

- Powertools job state is too rich to understand from Oban Web job rows.
- Operators need one table that joins jobs + workflows + batches + limiters + receipts + audit + traces.
- Oban Web cannot support a critical custom interaction without forking.
- Crosswake/mobile operator UX becomes important.
- You want zero dependency on `oban_web` for philosophical or packaging reasons.
- Oban Web’s generic UI becomes harder to integrate than maintain your own.

Until then, a bridge gives more value per hour.

---

## 4. Why bridge-first is the efficient plan

### 4.1 Rebuilding Oban Web is deceptively large

A serious Oban Web equivalent is not just “make a LiveView table.” It includes:

- LiveView routing and lifecycle
- realtime metrics
- compact timeseries storage
- distributed node awareness
- job filtering/search
- autocomplete hints
- queue controls
- job detail pages
- args/meta/output formatting
- pagination/query limits
- access control
- bulk action limits
- action logging
- CSP handling
- multiple Oban instances
- frontend assets
- refresh behavior
- safe decoding of recorded output
- weird edge cases around large completed-job sets

That is a large amount of commodity work. Powertools should spend its first heavy engineering cycles on things Oban Web does **not** already solve.

### 4.2 Oban Web already exposes enough hooks for a good bridge

Current docs expose:

- `oban_dashboard/2` route mounting
- `resolver:` callback module
- `on_mount:` hooks
- socket path / longpoll transport configuration
- CSP nonce configuration
- custom `logo_path`
- `resolve_user/1`
- `resolve_access/1`
- `resolve_instances/1`
- `resolve_refresh/1`
- `format_job_args/1`
- `format_job_meta/1`
- `format_recorded/2`
- `jobs_query_limit/1`
- `hint_query_limit/1`
- `bulk_action_limit/1`
- telemetry for dashboard write actions

That is enough to make Oban Web feel like part of the same operator area even if it is not literally embedded inside your own LiveView navigation.

### 4.3 Powertools can unify the important policies

Even with two routed UIs, the operator experience can still be coherent if these are shared:

- auth
- role policy
- read-only mode
- redaction
- audit log
- telemetry
- runbook links
- unsafe-action confirmation philosophy
- URL/link conventions

The operator cares less whether there are two LiveView route trees and more whether:

- access is consistent
- secrets are protected
- actions are audited
- pages link to each other
- “why is this stuck?” is answerable
- repair flows are safe

---

## 5. Installer strategy

### 5.1 Default install for your own use

For your own apps, default to bridge-first:

```bash
mix igniter.install oban_powertools --with-oban-web
mix ecto.migrate
mix oban_powertools.doctor
```

This gives you:

- Oban Web for generic jobs/queues/metrics
- Powertools Web for paid-tier-equivalent Powertools features
- shared auth/redaction/audit glue

### 5.2 Public installer flags

Suggested flags:

```bash
mix oban_powertools.install --with-oban-web
mix oban_powertools.install --no-oban-web
mix oban_powertools.install --powertools-only
mix oban_powertools.install --native-job-ui
mix oban_powertools.install --read-only-dashboard
```

Recommended defaults:

| User situation | Default |
|---|---|
| Phoenix app, wants best DX | `--with-oban-web` |
| Phoenix app, refuses Oban Web dependency | `--native-job-ui` fallback |
| Non-Phoenix / Plug-only app | no LiveView UI by default; CLI + telemetry + optional endpoint recipe |
| Library author / CI | no dashboard; testing helpers + telemetry only |

### 5.3 Mix dependency strategy

Keep `oban_web` optional:

```elixir
defp deps do
  [
    {:oban, "~> 2.19"},
    {:phoenix_live_view, "~> 1.0", optional: true},
    {:oban_web, "~> 2.12", optional: true}
  ]
end
```

Runtime detection:

```elixir
if Code.ensure_loaded?(Oban.Web.Router) do
  # bridge available
else
  # render fallback install instructions or native job UI
end
```

Generated app code may add `{:oban_web, "~> 2.12"}` explicitly when the user chooses `--with-oban-web`.

---

## 6. Feature parity target: paid-tier categories remain in scope

The web strategy does **not** shrink the backend ambition. Powertools should still target all useful paid-tier categories.

### 6.1 Oban Pro-inspired capabilities

| Category | Publicly described upstream capability | Powertools target | UI strategy |
|---|---|---|---|
| Smart engine | global concurrency, rate limits, partitioning, async tracking, enhanced uniqueness, bulk inserts, accurate snooze | `Powertools.Engine` or `Powertools.Execution` with global/local concurrency, limiters, partitions, unique indexes, bulk insert batching, snooze semantics | Native Powertools limiters/partitions/queues pages; Oban Web bridge for generic queue state |
| Pro Worker | hooks, structured/encrypted args, output recording, signals, deadlines, variable weights, chains | `use ObanPowertools.Job` with hooks, typed args, encryption, output, deadline, cancellation, signal helpers | Native job extensions panel; Oban Web can still show args/meta/output through resolver formatting |
| Rate Limit API | check capacity, consume quota, reserve atomically outside job execution | `ObanPowertools.Limiter` API usable by jobs, controllers, tasks, agents | Native limiter status/reservations/saturation page |
| Decorator | background jobs from regular functions | `ObanPowertools.Decorator` | Docs and generated examples; minimal UI |
| Relay | persistent distributed tasks with result forwarding | `ObanPowertools.Relay.call/await` | Native relay calls/results page |
| Testing | supervised integration helpers and workflow assertions | `ObanPowertools.Testing` | No main UI; docs/doctor integration |
| Batch | group jobs, progress, callbacks | `ObanPowertools.Batch` | Native batch page |
| Chunk | process jobs atomically in groups by size/timeout with granular errors | `ObanPowertools.Chunk` | Native chunk page |
| Workflow | DAGs, dependencies, sub-workflows, context sharing, DB tracking | `ObanPowertools.Workflow` | Native DAG/why-blocked/repair page |
| DynamicCron | runtime cron with timezone and cluster coordination | `ObanPowertools.DynamicCron` | Native cron page; maybe Oban Web bridge for basic cron if compatible |
| DynamicLifeline | rescue orphaned jobs, retry exhausted jobs, unstick workflows | `ObanPowertools.Lifeline` | Native lifeline/repair page |
| DynamicPrioritizer | adjust priorities to prevent starvation | `ObanPowertools.Prioritizer` | Native starvation/fairness page |
| DynamicPruner | scheduled retention by queue/worker/state | `ObanPowertools.Pruner` | Native retention/bloat page |
| DynamicQueues | runtime persisted queues, node restrictions | `ObanPowertools.DynamicQueues` | Native dynamic queues page plus Oban Web queue bridge |
| DynamicScaler | horizontal scaling based on queue depth | `ObanPowertools.Scaler` | Native scaler page + Parapet metrics |

### 6.2 Oban Web-inspired capabilities

| Generic Oban Web feature | Reuse initially? | Powertools native equivalent? | Notes |
|---|---:|---:|---|
| Embedded LiveView dashboard | Yes | Yes, for Powertools shell | Mount both under `/ops/jobs` |
| Realtime charts | Yes | Later for Powertools SLIs | Start with Powertools cards + Parapet metrics |
| Live updates | Yes | Yes for Powertools pages | Use PubSub/telemetry for Powertools state |
| Job filtering/search | Yes | Fallback minimal only | Do not rebuild mature search early |
| Job inspection | Yes | Add Powertools extension panels | Link by job id |
| Batch actions on jobs | Yes | Only for Powertools-owned concepts | Dangerous actions must be audited |
| Queue controls | Yes for generic queues | Yes for dynamic queues/scaler | Native pages for Powertools config |
| Multiple dashboards/instances | Yes | Mirror in Powertools config | Respect user auth |
| Access control | Yes via resolver | Yes via Powertools Auth | Generate bridge resolver |
| Action logging | Yes via telemetry | Yes via Powertools audit | Attach handler to both event streams |
| Custom formatting/redaction | Yes via resolver | Yes via Redaction module | Single source of truth |

### 6.3 Sidekiq Pro/Enterprise-inspired capabilities

| Sidekiq category | Powertools interpretation | UI strategy |
|---|---|---|
| Reliable processing | Durable receipts, idempotency, lifeline, dead-letter repair, crash recovery | Native reliability/doctor/lifeline pages |
| Batches/callbacks | Batches with progress and callbacks | Native batch page |
| Queue pause | Dynamic queue pause/resume/drain/stop | Oban Web bridge + native dynamic queue page |
| Expiring jobs | Deadline/max-age semantics | Native job policy page and job detail extension |
| Metrics/StatsD | Telemetry + Prometheus/Parapet adapters | Native SRE overview |
| Web UI search | Use Oban Web bridge initially | Native fallback later only if needed |
| Encryption | Arg/output encryption wrappers | Native security/settings page; redacted bridge formatting |
| Rate limiting | Global, partitioned, group, API-call, and weighted limiters | Native limiter page |
| Periodic jobs | Dynamic cron with timezone/history/missed-run detection | Native cron page |
| Unique jobs | Fingerprints, TTLs, idempotency receipts | Native dedupe/idempotency page |
| Historical metrics | Retention-aware metrics and durable events | Native metrics/retention pages + Parapet |
| Multi-process / rolling restarts | graceful drain, node coordination, deployment markers | Native operations/runbook pages |
| Web authorization | Auth behaviour + bridge resolver | Shared auth across both UIs |

### 6.4 Lessons from other ecosystems

- **Mission Control — Jobs** shows that a dashboard should target routine operations *and* incident operations. 37signals explicitly described moving away from one-off scripts/runbooks toward a dashboard that can inspect, retry, discard, and bulk-operate during incidents.
- **GoodJob** shows the value of a Postgres-backed, batteries-included, Rails-native system with cron, batches, concurrency/throttling, and a built-in dashboard.
- **Flower** shows that monitoring/admin tools should include realtime status plus production integrations such as authentication and Prometheus/Grafana.
- **BullMQ Pro groups** show that group-level rate limiting is a strong mental model: one rate-limited group should not block unrelated groups.

Powertools should combine these lessons: native Phoenix UX, Postgres durability, incident-grade operations, first-class auth, telemetry, and fairness.

---

## 7. Unified operator experience despite hybrid UI

The goal is not “two random dashboards.” The goal is **one ops area with shared policies**.

### 7.1 Shared auth

Define one Powertools auth behaviour:

```elixir
defmodule ObanPowertools.Auth do
  @callback current_actor(Plug.Conn.t() | Phoenix.LiveView.Socket.t()) ::
              {:ok, actor :: map()} | :error

  @callback authorize(actor :: map(), action :: atom(), target :: term()) ::
              :ok | {:error, :forbidden}
end
```

Then generate an Oban Web resolver that delegates to it:

```elixir
defmodule MyAppWeb.ObanPowertoolsObanWebResolver do
  @behaviour Oban.Web.Resolver

  @impl true
  def resolve_user(conn) do
    case ObanPowertools.Auth.current_actor(conn) do
      {:ok, actor} -> actor
      :error -> nil
    end
  end

  @impl true
  def resolve_access(actor) do
    ObanPowertools.Web.ObanWebAccess.resolve(actor)
  end

  @impl true
  def format_job_args(job) do
    ObanPowertools.Redaction.format_job_args(job)
  end

  @impl true
  def format_job_meta(job) do
    ObanPowertools.Redaction.format_job_meta(job)
  end

  @impl true
  def format_recorded(recorded, job) do
    ObanPowertools.Redaction.format_recorded(recorded, job)
  end
end
```

### 7.2 Shared audit

Attach handlers for:

```elixir
[:oban_web, :action, :start]
[:oban_web, :action, :stop]
[:oban_web, :action, :exception]

[:oban_powertools, :operator_action, :start]
[:oban_powertools, :operator_action, :stop]
[:oban_powertools, :operator_action, :exception]
```

Normalize both into:

```elixir
%ObanPowertools.Audit.Event{
  source: :oban_web | :oban_powertools,
  actor_id: actor_id,
  action: action,
  target: target,
  reason: reason,
  before: before_snapshot,
  after: after_snapshot,
  result: :ok | :error,
  duration_native: duration,
  trace_id: trace_id,
  inserted_at: now
}
```

The audit log then shows both Oban Web actions and Powertools actions in one place.

### 7.3 Shared redaction

Create one redaction layer:

```elixir
defmodule ObanPowertools.Redaction do
  def format_job_args(%Oban.Job{} = job), do: ...
  def format_job_meta(%Oban.Job{} = job), do: ...
  def format_recorded(recorded, %Oban.Job{} = job), do: ...
  def redact_map(map, policy), do: ...
end
```

Use it in:

- Powertools native UI
- Oban Web resolver
- telemetry metadata sanitization
- logs
- audit snapshots
- test assertions

### 7.4 Shared URL conventions

Powertools pages should always expose job links:

```elixir
ObanPowertoolsWeb.Routes.job_path(job_id)
ObanPowertoolsWeb.Routes.oban_web_job_path(job_id)
ObanPowertoolsWeb.Routes.workflow_node_path(workflow_id, node_id)
ObanPowertoolsWeb.Routes.batch_member_path(batch_id, job_id)
```

Even if a link opens Oban Web instead of a Powertools page, the user should never have to manually search for the job.

---

## 8. Domain language for the web/UI layer

Add these terms to the Powertools domain language.

### Web nouns

| Term | Meaning |
|---|---|
| **Ops Console** | The overall `/ops/jobs` operator area. |
| **Powertools Shell** | Your native LiveView shell for Powertools pages. |
| **Oban Web Bridge** | Optional route/telemetry/resolver integration with OSS Oban Web. |
| **Native Page** | A Powertools-owned LiveView page for a Powertools-owned concept. |
| **Fallback Job UI** | Minimal Powertools job/queue pages used when Oban Web is absent. |
| **All-in-One Console** | Future full native dashboard that replaces the bridge if justified. |
| **Policy Adapter** | Module that maps Powertools auth roles to Oban Web resolver access. |
| **Redaction Adapter** | Module that formats args/meta/output consistently across UIs. |
| **Audit Sink** | Destination for normalized operator actions. |
| **Deep Link** | A URL from one UI area to a specific related job, batch, workflow, limiter, finding, or audit event. |
| **Dangerous Action** | A mutating operation requiring confirmation, reason, and audit. |
| **Dry Run** | Preview of a repair/bulk action before mutation. |
| **Finding** | Doctor-detected issue. |
| **Remediation** | Suggested fix attached to a finding. |
| **Runbook Link** | A link from finding/alert/action to human guidance. |

### Web verbs

| Verb | Meaning |
|---|---|
| **mount** | Register a dashboard route in the host Phoenix app. |
| **bridge** | Wire an external/open-source dashboard into the Powertools ops area. |
| **resolve** | Determine user, access, formatting, query limits, or refresh policy. |
| **redact** | Remove/mask sensitive values before display/log/audit. |
| **audit** | Record who did what, why, and with what result. |
| **link** | Create a deep link between concepts. |
| **inspect** | View details safely. |
| **explain** | Show why a job/workflow/limiter is blocked. |
| **preview** | Dry-run a mutating action. |
| **confirm** | Require intentional approval for dangerous action. |
| **repair** | Mutate state to fix a detected issue. |
| **fallback** | Use native minimal job UI when Oban Web is absent. |
| **graduate** | Promote fallback/native pages into a full all-in-one console. |

---

## 9. Decision tree: use Oban Web, bridge, fallback, or native?

```text
Need generic job table, search, filtering, job detail, realtime queue charts?
  -> Use Oban Web bridge initially.

Need UI for Powertools-owned tables or state machines?
  -> Build native Powertools page.

Need a job row enriched with workflow/batch/limiter/dedupe/receipt state?
  -> Build native Powertools page with job deep links.

Need to mutate generic Oban jobs/queues?
  -> Prefer Oban Web bridge if action exists; normalize its telemetry into Powertools audit.

Need to mutate Powertools concepts?
  -> Native Powertools action with reason + dry-run + audit.

User refuses oban_web dependency?
  -> Enable fallback job UI.

Fallback job UI is becoming large and frequently used?
  -> Graduate toward full native all-in-one console.

Need custom pages inside Oban Web navigation specifically?
  -> Avoid unless Oban Web adds a documented plugin API; otherwise route-level shell/bridge is safer.

Considering a fork?
  -> Only after backend feature set is stable and concrete bridge limitations are documented.
```

---

## 10. Native Powertools pages to build first

### 10.1 Overview

The overview should answer:

```text
Are jobs healthy?
Are queues moving?
Are any limiters saturated?
Are workflows blocked?
Did cron miss runs?
Are jobs stuck executing?
Are tables bloated?
Did a recent deploy/config/flag cause this?
What needs my attention now?
```

Cards:

- queue latency
- queue depth
- failure rate
- retry pressure
- stuck executing jobs
- blocked workflows
- limiter saturation
- cron missed runs
- retention/bloat findings
- last deploy marker

### 10.2 Limiters

Show:

- limiter name
- scope/partition/group key policy
- algorithm
- current capacity
- saturation
- reservations
- expired leases
- recent throttle events
- backoff policy
- “manual cooldown” action
- “disable limiter temporarily” action

### 10.3 Dedupe and idempotency

Show:

- fingerprints
- unique conflicts
- dedupe hit/miss rate
- idempotency receipts
- receipt outcome
- TTL/expiry
- replay safety warnings

### 10.4 Dynamic cron

Show:

- cron entries
- timezone
- next run
- last run
- missed runs
- pause/resume
- run now
- schedule history
- audit history

### 10.5 Dynamic queues/scaler

Show:

- runtime queue config
- persisted config
- local/global limits
- per-node restrictions
- pause/resume/drain/stop
- scaler recommendations
- node health

### 10.6 Batches/chunks

Show:

- progress
- success/failure/discard counts
- callbacks
- failed members
- retry failed only
- cancel remaining
- callback status
- chunk timeout/size policy

### 10.7 Workflows

This is a flagship page.

Show:

- DAG visualization
- chain/fan-out/fan-in/barrier nodes
- blocked nodes
- dependency reason
- signal waits
- context values
- failed nodes
- retry/cancel/repair actions
- “why blocked?” explanation
- dry-run repair

### 10.8 Lifeline/repair

Show:

- orphaned executing jobs
- stale heartbeats
- exhausted retries
- missing dependencies
- stuck workflow gates
- repair candidates
- risk classification
- dry-run SQL/state transition summary
- audit trail

### 10.9 Doctor

Show:

- config issues
- schema/index issues
- PgBouncer/notifier/test sandbox warnings
- bloat/retention issues
- missing telemetry handlers
- unsafe dashboard auth
- high-cardinality labels
- actionable remediation

### 10.10 Audit

Show:

- actor
- action
- target
- reason
- before/after
- result
- source (`oban_web` or `oban_powertools`)
- trace/request id
- time

---

## 11. What not to build early

Do not build these from scratch until the bridge/fallback has proven insufficient:

- a full generic job search engine
- Oban Web-equivalent realtime charts
- full generic queue table with every Oban edge case
- full generic job detail page
- multi-instance Oban dashboard switching
- standalone dashboard Docker image
- pixel-perfect Oban Web replacement
- broad generic bulk job actions

Build minimal fallback versions only where needed for independence.

---

## 12. “Full native console” graduation criteria

At some point, building your own complete Oban Web equivalent may become rational.

Graduation triggers:

1. Powertools backend is stable enough that UI joins are predictable.
2. Operators constantly switch between Oban Web and Powertools pages and lose context.
3. The bridge cannot deep-link or display the right joined state.
4. You need one unified table with columns like:
   - job id
   - queue
   - worker
   - state
   - workflow
   - batch
   - limiter
   - partition
   - fingerprint
   - idempotency receipt
   - retry/deadline
   - last audit action
   - trace id
5. You need custom bulk actions that span generic Oban jobs and Powertools concepts.
6. Your fallback job UI has already grown beyond “minimal.”

When this happens, build the full native console deliberately rather than as an accidental fork.

Suggested route:

```text
/ops/jobs/all/jobs
/ops/jobs/all/queues
/ops/jobs/all/metrics
/ops/jobs/all/search
```

At that stage, Oban Web can become optional/off by default.

---

## 13. Clean-room and OSS boundary

Feature parity as a product goal is fine. The boundary is implementation.

Do:

- use public documentation
- use public APIs
- study public OSS code respectfully
- depend on OSS Oban Web when useful
- build independent Powertools implementations
- use your own names for Powertools-specific concepts
- include a clear independence disclaimer

Do not:

- copy proprietary Oban Pro code
- copy private docs
- imply official Oban endorsement
- copy UI trade dress when building your own console
- rely on private/internal Oban APIs
- make compatibility promises you cannot keep

If you depend on Oban Web, keep it as a dependency/bridge rather than copying large chunks into your MIT project. If you ever copy OSS Apache-2.0 code, preserve licensing obligations and treat that code as Apache-licensed rather than silently relicensing it.

---

## 14. Revised roadmap

### v0.1 — Foundation + Bridge

Ship:

- installer
- migrations
- config validation
- `mix oban_powertools.doctor`
- telemetry contract
- auth behaviour
- redaction module
- audit table
- optional Oban Web bridge resolver
- optional Oban Web telemetry audit sink
- native Powertools overview shell
- minimal fallback job UI read-only

Goal: make the ops area exist and make Oban Web integration safe.

### v0.2 — Dedupe, idempotency, retention

Ship:

- fingerprint/dedupe helpers
- index-backed uniqueness strategy
- idempotency receipts
- retention/pruner
- bloat/index doctor checks
- native dedupe/idempotency/retention pages

Goal: safe enqueueing and table health.

### v0.3 — Dynamic cron and queues

Ship:

- dynamic cron
- dynamic runtime queues
- pause/resume/drain/scale
- missed-run detection
- queue config persistence
- native cron/queues pages
- audit for mutating actions

Goal: runtime control without redeploys.

### v0.4 — Limiters and fairness

Ship:

- global concurrency reservations
- rate limiters: fixed window, sliding window, token bucket
- partition/group limiters
- variable weights
- manual cooldown from 429/external API response
- limiter page
- limiter telemetry and Parapet metrics

Goal: external API protection and tenant fairness.

### v0.5 — Batches and chunks

Ship:

- atomic batch creation
- progress tracking
- callbacks
- retry/cancel failed subset
- chunk processor with size/timeout
- native batch/chunk pages

Goal: fan-out work and bulk processing.

### v0.6 — Workflows/signals

Ship:

- DAG workflow builder
- chains
- fan-out/fan-in/barriers
- sub-workflows
- context sharing
- signals/awaits
- why-blocked explainer
- workflow page

Goal: complex orchestration.

### v0.7 — Lifeline and repair

Ship:

- orphan detector
- stale heartbeat detector
- stuck workflow detector
- repair dry-run
- repair actions
- runbook links
- incident evidence

Goal: day-2 recovery.

### v0.8 — Relay, decorator, testing

Ship:

- function decorator
- relay call/await
- supervised integration test helpers
- workflow sync runner for tests
- telemetry-complete inline testing mode

Goal: developer ergonomics.

### v0.9 — Native UI hardening

Ship:

- richer fallback job UI
- joined job context panels
- custom search for Powertools concepts
- Crosswake/mobile-friendly summary API
- UI performance tests

Goal: prepare to decide whether all-in-one console is worth it.

### v1.0 — Stability

Ship:

- stable public API
- stable telemetry API
- stable migrations
- security pass
- upgrade guide
- example Phoenix app
- feature matrix vs paid-tier categories
- known limitations

Goal: dependable OSS release.

### v1.x optional — Full native all-in-one dashboard

Only after graduation criteria are met:

- full job table
- full queue table
- full metrics charts
- full job detail
- joined Powertools context
- generic bulk actions
- bridge optional/off by default

Goal: complete Oban Web-equivalent ownership if it becomes worth the cost.

---

## 15. Implementation modules

Suggested package structure:

```text
lib/oban_powertools/
  auth.ex
  audit.ex
  config.ex
  doctor.ex
  redaction.ex
  telemetry.ex

  dedupe.ex
  fingerprint.ex
  idempotency.ex
  limiter.ex
  reservation.ex
  cron.ex
  queues.ex
  prioritizer.ex
  pruner.ex
  scaler.ex
  batch.ex
  chunk.ex
  workflow.ex
  signal.ex
  lifeline.ex
  relay.ex
  decorator.ex
  testing.ex

lib/oban_powertools_web/
  router.ex
  overview_live.ex
  limiters_live.ex
  dedupe_live.ex
  idempotency_live.ex
  cron_live.ex
  queues_live.ex
  batches_live.ex
  chunks_live.ex
  workflows_live.ex
  lifeline_live.ex
  doctor_live.ex
  audit_live.ex
  settings_live.ex

  oban_web_bridge.ex
  oban_web_resolver.ex
  fallback_jobs_live.ex
  fallback_job_live.ex
  fallback_queues_live.ex
```

### Bridge modules

```elixir
defmodule ObanPowertoolsWeb.ObanWebBridge do
  def available?, do: Code.ensure_loaded?(Oban.Web.Router)
  def resolver_module(app), do: Module.concat([app, Web, ObanPowertoolsObanWebResolver])
end
```

```elixir
defmodule ObanPowertoolsWeb.ObanWebAccess do
  def resolve(actor) do
    cond do
      can?(actor, :admin_jobs) -> :all
      can?(actor, :operate_jobs) -> [
        pause_queues: true,
        retry_jobs: true,
        cancel_jobs: true,
        scale_queues: true
      ]
      can?(actor, :read_jobs) -> :read_only
      true -> {:forbidden, "/"}
    end
  end
end
```

---

## 16. Feature/UI matrix for LLM implementation

Use this as the implementation alignment table.

| Feature | Backend owner | UI owner v1 | Oban Web bridge role | Full native later? |
|---|---|---|---|---|
| Generic job list | Oban | Oban Web | Primary | Yes, fallback/generation later |
| Generic job detail | Oban | Oban Web | Primary | Yes, if joined context needed |
| Generic queue charts | Oban/Oban Met/Web | Oban Web | Primary | Maybe |
| Queue pause/resume | Oban/Powertools dynamic queues | Both | Use existing actions where possible | Yes |
| Dynamic queue config | Powertools | Powertools | Link to queue | Yes |
| Dynamic cron | Powertools | Powertools | Maybe generic jobs only | Yes |
| Limiters | Powertools | Powertools | None except related jobs | Yes |
| Partitions/groups | Powertools | Powertools | None except queue/job context | Yes |
| Dedupe/fingerprints | Powertools | Powertools | Job link only | Yes |
| Idempotency receipts | Powertools | Powertools | Job link only | Yes |
| Recorded/encrypted outputs | Powertools | Powertools + resolver formatting | Redacted display | Yes |
| Batches | Powertools | Powertools | Job links | Yes |
| Chunks | Powertools | Powertools | Job links | Yes |
| Workflows/DAGs | Powertools | Powertools | Job links | Yes |
| Signals/awaits | Powertools | Powertools | Job links | Yes |
| Lifeline/repair | Powertools | Powertools | Job links | Yes |
| Doctor | Powertools | Powertools | Link to affected jobs/queues | Yes |
| Audit | Powertools | Powertools | Ingest Oban Web telemetry | Yes |
| Parapet metrics | Powertools/Parapet | Powertools/Parapet | Web metrics are supplementary | Yes |
| Crosswake mobile summary | Powertools | Powertools API | None | Yes |

---

## 17. Operator UX principle: “explain, then act”

Powertools Web should be better than a normal dashboard because it explains operational state.

Every native page should answer:

```text
What is happening?
Why is it happening?
What is waiting on what?
What is safe to do?
What will happen if I click this?
What changed recently?
Where is the audit trail?
What runbook applies?
```

Dangerous action pattern:

```text
1. Select action
2. Show dry-run impact
3. Require reason
4. Require confirmation for broad mutations
5. Execute in transaction when possible
6. Emit telemetry
7. Record audit event
8. Show result and link to affected jobs/workflows
```

---

## 18. SRE/Parapet view

Powertools should emit SLIs and integrate with Parapet.

Metrics:

```text
queue_latency_seconds
queue_depth
job_failure_ratio
job_retry_ratio
discarded_jobs_total
stuck_executing_jobs
workflow_blocked_seconds
batch_completion_seconds
limiter_saturation_ratio
limiter_throttle_total
cron_missed_runs_total
prune_lag_seconds
repair_actions_total
operator_actions_total
```

Runbooks:

```text
queue_latency_high
limiter_saturated
workflow_blocked
batch_callback_failed
cron_missed_run
stuck_executing_jobs
orphaned_jobs_detected
postgres_bloat_high
notifier_unhealthy
dashboard_auth_unsafe
```

Bridge action telemetry from Oban Web should appear in the same incident evidence stream as native Powertools actions.

---

## 19. Final recommendation

Build Powertools as a full paid-tier-equivalent capability layer, but choose the efficient UI path:

```text
Backend ambition: full batteries-included.
UI v1 ambition: native Powertools console + optional Oban Web bridge.
UI v1 non-goal: rebuild every generic Oban Web screen from scratch.
UI future: graduate to full native all-in-one console only when the bridge becomes the bottleneck.
```

This keeps related functionality together where it matters—Powertools concepts live in Powertools Web—while avoiding a low-leverage rewrite of mature OSS dashboard functionality.

The strategic shape is:

```text
/ops/jobs
  Powertools native pages for paid-tier features
  + Oban Web bridge for generic jobs/queues/metrics
  + shared auth/redaction/audit/telemetry
  + fallback native job UI for no-Oban-Web installs
  + later all-in-one console if justified
```

That gives you day-0 adoption, day-1 developer ergonomics, and day-2 operator power without boiling the ocean before the Powertools backend features are real.

---

## 20. Sources consulted

- Oban Web overview v2.12.4: https://hexdocs.pm/oban_web/overview.html
- Oban Web router docs: https://hexdocs.pm/oban_web/Oban.Web.Router.html
- Oban Web resolver docs: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html
- Oban Web telemetry docs: https://hexdocs.pm/oban_web/Oban.Web.Telemetry.html
- Oban Web v2.11 changelog/open-source note: https://hexdocs.pm/oban_web/2.11.0/changelog.html
- Oban Pro overview v1.7.3: https://oban.pro/docs/pro/overview.html
- Oban Pro Smart Engine docs: https://oban.pro/docs/pro/Oban.Pro.Engines.Smart.html
- Oban GitHub README feature list: https://github.com/oban-bg/oban
- Sidekiq Pro product page: https://sidekiq.org/products/pro/
- Sidekiq Enterprise product page: https://sidekiq.org/products/enterprise/
- Sidekiq Enterprise rate limiting wiki: https://github.com/sidekiq/sidekiq/wiki/Ent-Rate-Limiting
- Sidekiq Enterprise unique jobs wiki: https://sidekiq.org/wiki/Ent-Unique-Jobs
- Mission Control Jobs GitHub: https://github.com/rails/mission_control-jobs
- 37signals Mission Control Jobs announcement: https://dev.37signals.com/mission-control-jobs/
- GoodJob GitHub README: https://github.com/bensheldon/good_job
- Flower docs: https://flower.readthedocs.io/en/latest/
- BullMQ Pro group rate limiting docs: https://docs.bullmq.io/bullmq-pro/groups/rate-limiting
- BullMQ Pro telemetry docs: https://docs.bullmq.io/bullmq-pro/telemetry
