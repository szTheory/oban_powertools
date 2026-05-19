Oban Powertools: Research Context, Domain Language, and Product Spec

0. Executive Summary

Oban Powertools is a Phoenix-first, Ecto-native, Postgres-only, MIT-licensed OSS extension layer for Oban. Its goal is to give solo developers and small teams a batteries-included operational toolkit for background jobs: dashboard, queue controls, dynamic scheduling, rate limits, workflow composition, typed workers, job search, repair tools, telemetry, testing helpers, and SRE-friendly diagnostics.

The guiding idea is clear: build the same category of operational capabilities that developers look for in Oban Pro, Oban Web, Sidekiq Pro, and Sidekiq Enterprise, but as a clean-room, host-owned OSS library for people who are not going to buy commercial subscriptions. Oban Pro’s public docs describe capabilities such as global concurrency, rate limiting, queue partitioning, async tracking, enhanced unique jobs, bulk inserts, typed/structured workers, recorded jobs, encrypted jobs, deadlines, worker hooks, batches, chunks, workflows, dynamic cron, dynamic queues, lifeline repair, prioritization, pruning, and autoscaling. Oban Web’s public docs describe an embedded LiveView dashboard with charts, filtering, inspection, batch actions, queue controls, access control, and action logging. Sidekiq Pro and Enterprise expose a similar commercial pattern: batches, reliability, queue pausing, job search, metrics, rate limiting, cron, unique jobs, encryption, historical metrics, and Web UI auth.  ￼

This document treats those capabilities as product requirements and design inspiration, not as source material to copy. The implementation should be clean-room: use public docs, observable behavior, community feedback, and first-principles design; do not copy proprietary code, private APIs, UI assets, docs, naming, or exact implementation details. The library should depend on OSS Oban, support Postgres only, and prioritize Phoenix/LiveView integration while remaining usable from plain Elixir/Plug apps where reasonable.

⸻

1. Product Posture

1.1 What This Is

oban_powertools is:

* A Phoenix-native operational layer for Oban.
* A Postgres-only job operations toolkit.
* A host-owned library: migrations, schemas, telemetry, and UI live inside the user’s app.
* A developer-experience accelerator for typed workers, workflows, cron, limits, tests, and admin UX.
* A day-2 operations layer for queue health, retries, stuck jobs, orphan repair, SLOs, and diagnostics.
* A solo/small-team affordability layer: useful when the developer cannot or will not pay for commercial job tooling.

1.2 What This Is Not

oban_powertools is not:

* A replacement for Oban itself.
* A hosted SaaS.
* A support-backed enterprise product.
* A MySQL or SQLite compatibility project.
* A promise of exactly-once execution.
* A clone of proprietary source code.
* A project that should market itself as “Oban Pro but free” in package docs or README language.

The right positioning is closer to:

“A Phoenix-first, OSS, Postgres-only power toolkit for Oban: dashboard, typed workers, workflows, dynamic cron, limits, repair tools, telemetry, and testing helpers.”

1.3 The Important Clarification

Yes: the feature set should intentionally cover the same class of batteries-included capabilities developers look for in Oban Pro/Web and Sidekiq Pro/Enterprise.

No: the implementation should not copy their proprietary internals, private code, assets, exact docs, or branding. Build from public behavior, public docs, community feedback, and clean-room architecture.

⸻

2. Primary Personas and Jobs-to-Be-Done

2.1 Solo Phoenix SaaS Operator

Situation: I run a small Phoenix SaaS by myself. Jobs power billing, emails, syncs, imports, media processing, support automation, and AI workflows.

JTBD: Help me see what is happening, safely retry or cancel work, find stuck jobs, manage cron, understand failures, and ship without wiring five separate tools.

Needs:

* Embedded dashboard.
* Safe bulk actions.
* Cron/schedule management.
* Job search and filtering.
* “Why is this job not running?” explainability.
* Repair tools for stuck/orphaned jobs.
* Minimal setup.
* No external SaaS requirement.

2.2 Application Developer

Situation: I am writing job modules, workflows, and retry logic.

JTBD: Help me define reliable, typed, testable, idempotent jobs with good defaults and clear failure semantics.

Needs:

* Typed/validated job args.
* Idempotency guidance.
* Unique job helpers.
* Retry/backoff/deadline ergonomics.
* Worker hooks.
* Recorded outputs.
* Testing helpers.
* Good compiler/docs feedback.

2.3 SRE / DevOps / On-Call Engineer

Situation: Jobs are part of production reliability. Queue lag, retries, stuck jobs, third-party API limits, and deploy regressions matter.

JTBD: Give me SLO-ready telemetry, dashboards, runbooks, alerts, audit trails, and safe remediation controls.

Needs:

* Queue latency/lag metrics.
* Failure and retry storm detection.
* Orphan detection and repair.
* Cron missed-fire detection.
* Rate-limit visibility.
* Action audit logs.
* Prometheus/OpenTelemetry-friendly instrumentation.
* Safe cardinality policy.

Oban’s core telemetry already exposes job lifecycle, engine, plugin, queue shutdown, and orphan-related events, which makes telemetry-first design natural for this library.  ￼

2.4 Product / Support / Admin User

Situation: A customer’s invoice email, import, export, webhook sync, or AI task failed.

JTBD: Let me inspect the job, understand whether it is safe to retry, and trigger safe remediation without needing database access.

Needs:

* Role-scoped dashboard.
* Job detail page.
* Retry/cancel/requeue buttons.
* Human-readable args and metadata.
* Redacted/encrypted sensitive fields.
* Audit trail for manual actions.

2.5 AI-Assisted Library Maintainer

Situation: The maintainer is using LLM-assisted development to move quickly.

JTBD: Give the model clear domain language, contracts, modules, events, and test expectations so generated code converges instead of sprawling.

Needs:

* Strong noun/verb/event vocabulary.
* Explicit invariants.
* Public telemetry contract.
* Feature slices.
* Architecture boundaries.
* Test matrix and fixtures.

⸻

3. Domain Language

This section is the most important context for future AI-assisted development. Use these nouns, verbs, states, and events consistently.

3.1 Core Nouns

Job

A durable unit of background work persisted in Oban’s jobs table.

Important properties:

* id
* queue
* worker
* args
* meta
* state
* attempt
* max_attempts
* priority
* scheduled_at
* attempted_at
* completed_at
* discarded_at
* cancelled_at
* errors

Worker Module / Job Class

The Elixir module that defines how a job is performed.

Prefer Worker Module in Elixir docs, but keep Job Class in comparison docs for Sidekiq/Rails readers. Sidekiq itself recommends precise terminology because “worker” can ambiguously mean process, thread, or job class.  ￼

Job Instance

A specific persisted job row.

Queue

A named lane of work. Queues have local limits, global limits, rate limits, pause/resume state, node restrictions, and scaling rules.

Producer

The Oban process responsible for dispatching jobs from a queue to executors.

Executor

The runtime process executing a job.

Attempt

One execution try for a job.

Retry

A future attempt after failure.

Backoff

The delay calculation before retry.

Snooze

A deliberate deferral returned by the worker.

Deadline

A latest acceptable execution time or maximum runtime boundary.

Oban Pro’s public worker docs expose deadline behavior, including cancellation of running jobs when a deadline passes, which is a useful product pattern to reproduce cleanly.  ￼

Expiration

A point after which queued work is no longer useful and should be discarded or marked expired.

Sidekiq Pro exposes expiring jobs as a commercial feature; this maps naturally to deadline or expires_at semantics in a Postgres-backed Oban toolkit.  ￼

Partition

A subdivision of queue capacity by worker, args, metadata, tenant, account, API key, or custom key.

Oban Pro documents partitioning by worker, args, and meta, and warns that partition key cardinality should be minimized.  ￼

Limit

A concurrency or throughput boundary.

Types:

* Local concurrency limit.
* Global concurrency limit.
* Partition concurrency limit.
* Rate limit.
* Weighted rate limit.
* External/manual quota limit.

Weight

The cost assigned to a job for rate-limit accounting. Useful for APIs where one job may consume more quota than another. Oban Pro documents rate-limit weights; Sidekiq Enterprise also documents points-based limiting for variable-cost work such as GraphQL request complexity.  ￼

Token / Quota

The unit consumed by a rate limiter.

Lease

A time-bounded claim to execute work.

Heartbeat

A periodic liveness signal from a producer, executor, node, or process.

Orphan

A job marked executing but no longer owned by a live executor or producer.

Oban’s core Lifeline docs warn that naive rescue can duplicate still-executing jobs, while Oban Pro’s DynamicLifeline describes more advanced repair for orphaned jobs, exhausted available jobs, stuck workflows/chains, missing partition keys, and missing chunk IDs.  ￼

Cron Entry

A persisted recurring schedule definition.

Firing

A specific cron occurrence.

Missed Firing

A schedule occurrence that should have inserted a job but did not.

Catch-Up

Insertion of jobs for missed schedule slots.

Oban Pro DynamicCron documents persisted runtime cron configuration, per-entry time zones, dynamic scheduled jobs, and guaranteed scheduling.  ￼

Batch

A group of related jobs with lifecycle callbacks.

Oban Pro and Sidekiq Pro both expose batches with callbacks after grouped work completes.  ￼

Batch Callback

A job triggered by a batch lifecycle event.

Possible callback events:

* attempted
* completed
* cancelled
* discarded
* exhausted
* retryable

Chunk

A bounded group of queued jobs processed together by size, timeout, or partition.

Oban Pro chunks run jobs together by size or timeout, can process multiple chunks in parallel, and support partitioning by worker, args, or meta.  ￼

Workflow

A directed acyclic graph of jobs with dependencies.

Step

A named node in a workflow.

Dependency

An edge requiring one job or step to complete before another is released.

Chain

A simple sequential workflow where jobs run one after another.

Oban Pro’s composition docs identify batches, chains, chunks, and workflows as distinct composition concepts.  ￼

Signal

A durable or transient event that can unblock work.

Oban Pro Worker exposes awaiting signals as a worker feature; oban_powertools should support a clean version of this concept for human approvals, external callbacks, and distributed coordination.  ￼

Relay

A persisted distributed task with awaitable result semantics.

Oban Pro Relay publicly describes persistent distributed tasks, awaiting results across nodes through PubSub, and test-time caveats around awaited jobs.  ￼

Recording

A stored job output, return value, summary, or artifact pointer.

Secret / Encrypted Payload

Sensitive job input encrypted at rest.

Encryption must be documented as an observability tradeoff. Oban Pro’s public docs note that only job args are encrypted, while metadata, errors, and stacktraces are not; encrypted args are not searchable in the Web UI; and uniqueness over encrypted args is problematic because encryption is nondeterministic.  ￼

Dashboard Action

A user-initiated operation from the admin UI.

Examples:

* retry job
* cancel job
* discard job
* snooze job
* pause queue
* resume queue
* change limit
* add cron entry
* disable cron entry
* repair orphan
* prune jobs

Audit Event

A durable record of a dashboard or API action.

Oban Web publicly documents action logging as part of the dashboard feature set; oban_powertools should treat auditability as a first-class domain concept.  ￼

⸻

3.2 Core Verbs

Use these verbs consistently in code, docs, UI copy, and telemetry.

Job Verbs

* enqueue
* insert
* insert_all
* reserve
* dispatch
* start
* execute
* ack
* complete
* fail
* retry
* discard
* cancel
* snooze
* reschedule
* expire
* record
* replay

Queue Verbs

* start_queue
* stop_queue
* pause
* resume
* drain
* scale
* throttle
* unthrottle
* partition
* rebalance

Limit Verbs

* reserve_token
* release_token
* consume
* refund
* exhaust
* reset
* refill
* reject
* defer

Cron Verbs

* register
* enable
* disable
* fire
* catch_up
* skip
* miss
* reschedule

Workflow Verbs

* compose
* append
* link
* depend_on
* fan_out
* fan_in
* unblock
* complete_step
* cancel_graph
* repair_graph

Operations Verbs

* inspect
* filter
* search
* explain
* diagnose
* repair
* prune
* archive
* audit
* authorize

⸻

3.3 Job States

Mirror Oban’s states where possible, and add derived states only in the Powertools domain layer.

Canonical / Oban-aligned states:

* available
* scheduled
* executing
* retryable
* completed
* discarded
* cancelled

Powertools-derived operational states:

* orphaned
* expired
* blocked
* waiting_for_signal
* waiting_for_limit
* waiting_for_dependency
* suspended
* archived

Use derived states for UI and diagnostics, but avoid mutating Oban’s state model unless necessary.

⸻

3.4 Public Telemetry Event Vocabulary

Telemetry is a public API. Breaking event names, measurement keys, or metadata keys should be semver-major.

Recommended namespace:

[:oban_powertools, ...]

Job Events

[:oban_powertools, :job, :reserved]
[:oban_powertools, :job, :started]
[:oban_powertools, :job, :completed]
[:oban_powertools, :job, :failed]
[:oban_powertools, :job, :retried]
[:oban_powertools, :job, :discarded]
[:oban_powertools, :job, :cancelled]
[:oban_powertools, :job, :snoozed]
[:oban_powertools, :job, :expired]

Queue Events

[:oban_powertools, :queue, :paused]
[:oban_powertools, :queue, :resumed]
[:oban_powertools, :queue, :scaled]
[:oban_powertools, :queue, :limit_changed]
[:oban_powertools, :queue, :drained]

Limiter Events

[:oban_powertools, :limit, :reserved]
[:oban_powertools, :limit, :rejected]
[:oban_powertools, :limit, :exhausted]
[:oban_powertools, :limit, :refilled]
[:oban_powertools, :limit, :reset]

Cron Events

[:oban_powertools, :cron, :registered]
[:oban_powertools, :cron, :enabled]
[:oban_powertools, :cron, :disabled]
[:oban_powertools, :cron, :fired]
[:oban_powertools, :cron, :missed]
[:oban_powertools, :cron, :caught_up]

Workflow Events

[:oban_powertools, :workflow, :inserted]
[:oban_powertools, :workflow, :step_started]
[:oban_powertools, :workflow, :step_completed]
[:oban_powertools, :workflow, :step_blocked]
[:oban_powertools, :workflow, :step_unblocked]
[:oban_powertools, :workflow, :completed]
[:oban_powertools, :workflow, :cancelled]
[:oban_powertools, :workflow, :stuck]
[:oban_powertools, :workflow, :repaired]

Batch Events

[:oban_powertools, :batch, :inserted]
[:oban_powertools, :batch, :progressed]
[:oban_powertools, :batch, :completed]
[:oban_powertools, :batch, :exhausted]
[:oban_powertools, :batch, :callback_started]
[:oban_powertools, :batch, :callback_completed]

Ops Events

[:oban_powertools, :lifeline, :orphan_detected]
[:oban_powertools, :lifeline, :orphan_rescued]
[:oban_powertools, :pruner, :pruned]
[:oban_powertools, :doctor, :check_started]
[:oban_powertools, :doctor, :check_failed]
[:oban_powertools, :doctor, :check_passed]
[:oban_powertools, :ui, :action]

Telemetry labels must be cardinality-safe. Put high-cardinality values such as job IDs, user IDs, account IDs, raw args, and raw paths into metadata or durable evidence, not metric labels.

⸻

4. Feature Benchmark: What to Build

4.1 Dashboard / Admin UI

Build an embedded LiveView dashboard that is useful on day 0 and serious on day 2.

Oban Web’s public docs list the relevant baseline: embedded Phoenix LiveView, realtime charts, live updates, filtering, job inspection, batch actions, queue controls, multi-dashboard support, access control, and action logging. Oban Web v2.11 also became Apache 2.0 licensed, and its public release notes describe rebuilt queue pages, richer filtering, status sidebars, sorting, and bulk operations over filtered jobs.  ￼

Required Pages

1. Overview
    * queue health
    * throughput
    * failure rate
    * retry rate
    * queue lag
    * executing count
    * scheduled count
    * orphan count
    * missed cron firings
    * rate-limit saturation
2. Queues
    * pause/resume
    * local/global limits
    * partition limits
    * live throughput
    * queue lag
    * node placement
    * scaling recommendations
3. Jobs
    * filter by state, queue, worker, args, meta, tag, tenant, attempt, time
    * saved filters
    * job search
    * bulk retry/cancel/discard/snooze
    * dry-run preview before bulk action
4. Job Detail
    * args and meta
    * redacted sensitive fields
    * attempts and errors
    * timeline
    * logs/trace links
    * related workflow/batch/chunk
    * retry safety hint
    * idempotency hint
    * action audit history
5. Cron / Schedules
    * create/edit/enable/disable entries
    * next fire preview
    * missed fire history
    * catch-up controls
    * timezone display
    * overlap policy
6. Batches / Workflows / Chains / Chunks
    * graph visualization
    * blocked steps
    * failed steps
    * progress
    * callback jobs
    * repair actions
7. Limits
    * rate-limit definitions
    * token usage
    * partition keys
    * saturation
    * rejected/deferred jobs
    * manual reset/refill controls
8. Repair Center
    * orphaned jobs
    * stuck workflows
    * missing partition keys
    * missing chunk IDs
    * exhausted-but-available jobs
    * index/config warnings
9. Pruning / Retention
    * retention policies by state, worker, queue
    * estimated rows to prune
    * safety preview
    * uniqueness/audit implications
10. Audit Log
    * who did what
    * before/after
    * reason
    * source IP/session when available
    * job/queue/workflow affected
11. Doctor
    * schema version
    * migration status
    * index health
    * queue config drift
    * plugin status
    * telemetry handlers
    * dangerous settings
    * clock skew
    * stuck producer detection

Important UI Lesson

A public forum thread shows a user wanting to embed Oban Web inside an existing LiveView shell, while the maintainer suggested iframe embedding as the easier path. oban_powertools should design for host-app shell integration from the start: router macro, LiveView layout support, slots, theme hooks, and component-level extensibility.  ￼

⸻

4.2 Smart Queueing, Concurrency, and Rate Limits

This is the hardest correctness area. Treat it as a first-class subsystem, not a few config options.

Oban Pro Smart Engine publicly lists global concurrency, rate limiting, queue partitioning, async tracking, enhanced uniqueness, bulk inserts, and accurate snooze as major features. Its rate-limit docs describe fixed-window, sliding-window, and token-bucket algorithms; its queue partitioning docs describe partitioning by worker, args, and meta.  ￼

Required Concepts

* local concurrency
* global concurrency
* partition concurrency
* fixed-window rate limit
* sliding-window rate limit
* token-bucket rate limit
* leaky-bucket / points-style rate limit
* weighted jobs
* dynamic limit changes
* explicit limiter state
* limiter telemetry
* limiter simulation / explanation

Recommended API Shape

config :my_app, Oban,
  queues: [
    api: [
      local_limit: 20,
      global_limit: [
        allowed: 100,
        partition: [args: :tenant_id]
      ],
      rate_limit: [
        allowed: 5_000,
        period: {1, :hour},
        algorithm: :token_bucket,
        partition: [args: :api_key],
        weight: {MyApp.RateWeights, :for_job, []}
      ]
    ]
  ]

Product Requirement: Explainability

Every rate-limited or blocked job should be able to answer:

“Why am I not running?”

Possible explanations:

* queue paused
* local queue limit reached
* global queue limit reached
* partition limit reached
* rate limit exhausted
* workflow dependency incomplete
* scheduled for future
* max attempts exhausted
* job cancelled/discarded
* cron disabled
* node restriction mismatch

Footgun: Rate Limit Semantics

Users routinely misunderstand whether a rate limit counts job starts, running jobs, completions, API calls, tenants, workers, or queue throughput. In one ElixirForum thread, a user hit third-party API limits while trying to combine rate limits, global limits, and partitioning; the maintainer clarified that rate limiting counted jobs started in a window, while concurrency limiting controlled simultaneous execution.  ￼

Celery has a similar trap: its task rate limit is per worker instance, not global, and its docs say a global rate limit requires routing to a restricted queue. This reinforces that oban_powertools should make “local vs global” painfully explicit.  ￼

Design Rule

Never expose a limiter without:

* docs explaining what is counted
* telemetry for accepted/rejected/deferred work
* UI showing current saturation
* tests for concurrency races
* a simulator or dry-run explanation
* examples for third-party API limits

⸻

4.3 Unique Jobs and Idempotency

Unique jobs are necessary, but they are not a substitute for idempotency or concurrency control.

Oban’s uniqueness guide explicitly warns that uniqueness is complex, that unique jobs are not the same as concurrent execution control, and that core uniqueness relies on locks/queries that can race; the guide contrasts this with Pro’s index-backed unique behavior.  ￼

Required Features

* unique key generation
* uniqueness by worker/queue/args/meta
* uniqueness by selected args/meta keys
* uniqueness across selected states
* uniqueness for incomplete jobs
* uniqueness for full job lifetime
* conflict detection
* conflict replacement policies
* conflict telemetry
* unique index health checks

Recommended API Shape

use ObanPowertools.Worker,
  queue: :billing,
  unique: [
    keys: [:account_id, :invoice_id],
    states: :incomplete,
    period: {24, :hours},
    on_conflict: :return_existing
  ]

Footgun: Uniqueness vs Enqueue Reliability

Sidekiq Enterprise’s unique jobs documentation notes that uniqueness requires an extra Redis call and is not protected by reliable push, so uniqueness can shift failure to enqueue time. In a Postgres/Oban design, the equivalent lesson is: uniqueness must be transactionally integrated with insertion, and conflict results must be explicit.  ￼

Design Rule

Every unique insert should return one of:

{:ok, job}
{:conflict, existing_job}
{:error, changeset_or_reason}

Avoid boolean “inserted or not” APIs.

⸻

4.4 Typed Workers / Structured Args

Oban Pro Worker publicly exposes structured jobs that validate args before execution and on insert/cast. It also includes recorded jobs, chained jobs, encrypted jobs, deadlines, worker aliases, hooks, awaiting signals, and rate-limit weights.  ￼

oban_powertools should provide an ergonomic wrapper around Oban.Worker, not a surprising replacement.

Recommended API Shape

defmodule MyApp.Workers.SyncAccount do
  use ObanPowertools.Worker,
    queue: :sync,
    max_attempts: 5,
    args: [
      account_id: :binary_id,
      provider: {:enum, [:stripe, :github]},
      force: {:boolean, default: false}
    ],
    unique: [
      keys: [:account_id, :provider],
      states: :incomplete
    ],
    deadline: [in: {10, :minutes}],
    record: [max_bytes: 1_000_000],
    encrypt: [fields: [:access_token]]
  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{} = args}) do
    # perform work
  end
end

Required Worker Features

* typed args
* changeset validation
* compile-time docs generation
* safe defaults for retries
* deadline / expiration
* custom backoff
* hooks
* result recording
* sensitive field redaction
* optional encryption
* aliases for renamed worker modules
* rate-limit weights
* signal waiting
* test helpers

Hook Semantics

Oban Pro’s hook docs distinguish execution hooks from external state hooks and note that post-process hooks are safe for side effects because crashes are caught and logged rather than failing the job or queue. oban_powertools should document hook failure semantics just as clearly.  ￼

Design Rule

Worker hooks must answer:

* Does this hook run inside or outside the job transaction?
* Does hook failure fail the job?
* Does hook failure crash the queue?
* Is the hook retried?
* Is telemetry emitted?
* Is the hook safe for side effects?

⸻

4.5 Encryption and Redaction

Encryption is attractive, but it damages searchability, uniqueness, and debugging.

Oban Pro’s public docs call out exactly this tradeoff: encrypted args are not searchable in the Web UI, uniqueness over encrypted args does not work normally due to nondeterministic encryption, and metadata/errors/stacktraces are not encrypted.  ￼

Required Features

* field-level redaction
* optional field-level encryption
* UI redaction markers
* explicit “not searchable” warnings
* metadata leak warnings
* stacktrace leak warnings
* unique-key alternatives using safe metadata hashes
* key rotation story
* test helpers for encrypted args

Recommended Rule

Do not make encrypt: true a magical blanket. Prefer:

encrypt: [fields: [:access_token, :refresh_token]],
redact: [fields: [:email, :phone]]

UI Requirement

The job detail page should show:

access_token: [encrypted]
email: [redacted]

not blank fields that confuse operators.

⸻

4.6 Scheduling and Dynamic Cron

Oban’s core periodic docs cover cron-like jobs and warn about time zones, dual-purpose workers, overlapping executions, cluster leadership, and one-minute resolution. Oban Pro DynamicCron adds runtime configuration, cluster-wide persistence, per-entry time zones, dynamic jobs, and guaranteed scheduling. Temporal’s schedule docs also emphasize schedules as independent entities with identity, interval/calendar specs, and actions.  ￼

Required Features

* persisted cron entries
* runtime add/edit/delete
* enable/disable
* per-entry timezone
* next-fire preview
* missed-fire tracking
* catch-up policy
* overlap policy
* singleton firing across cluster
* schedule audit history
* validation for untrusted cron input

DynamicCron’s docs explicitly warn that cron input from untrusted sources should be validated, which should become a doctor check and UI validation rule.  ￼

Recommended Schema Concepts

* schedules
* schedule_firings
* schedule_locks
* schedule_audits

Overlap Policies

:allow
:skip_if_running
:cancel_previous
:queue_after_previous

Catch-Up Policies

:none
:last_only
:all_missed
:max_n

UI Requirement

Every schedule page should show:

* next 5 firings
* last 5 firings
* missed firings
* overlap policy
* catch-up policy
* last inserted job
* disabled reason

⸻

4.7 Batches, Chains, Chunks, and Workflows

This is a major differentiator and should be built as a coherent composition layer.

Oban Pro’s composition docs describe batches for grouped jobs with callbacks, chains for sequential execution, chunks for grouped processing by size/timeout, and workflows for dependency graphs. Sidekiq Pro and Hangfire also expose batches/continuations as higher-level job composition features.  ￼

Batch

Use when many jobs belong to one logical operation and the user wants progress/callbacks.

Examples:

* import 10,000 rows
* send campaign emails
* fan out webhooks
* process all files in a folder

Chain

Use when jobs must run sequentially.

Examples:

* fetch remote file
* parse file
* transform rows
* write results
* notify user

Chunk

Use when many small jobs should be processed together.

Examples:

* bulk API calls
* batched database writes
* grouped email sends
* batch analytics updates

Workflow

Use when there is a DAG with fan-out/fan-in.

Examples:

* import pipeline
* media pipeline
* customer sync pipeline
* AI evaluation pipeline

Recommended Workflow API

ObanPowertools.Workflow.new("sync_customer")
|> ObanPowertools.Workflow.add(:fetch, FetchCustomer.new(%{id: id}))
|> ObanPowertools.Workflow.add(:sync_billing, SyncBilling.new(%{id: id}), deps: [:fetch])
|> ObanPowertools.Workflow.add(:sync_support, SyncSupport.new(%{id: id}), deps: [:fetch])
|> ObanPowertools.Workflow.add(:notify, NotifyDone.new(%{id: id}), deps: [:sync_billing, :sync_support])
|> ObanPowertools.Workflow.insert()

Callback Footgun

Callbacks must be explicit. Oban Pro’s batch docs warn that hybrid batches need an explicit callback worker to avoid unpredictable callback selection. Community questions around workflow callbacks also show that developers can confuse per-job hooks with whole-workflow completion callbacks.  ￼

Design Rule

Never overload a worker hook to mean “the whole workflow is complete.”

Use explicit events:

on_step_completed
on_workflow_completed
on_workflow_cancelled
on_workflow_stuck

⸻

4.8 Dynamic Queues

Oban Pro DynamicQueues publicly documents persisted runtime queue changes, global updates across the cluster, manual/automatic sync, and node restrictions by node or environment.  ￼

Required Features

* pause/resume queue
* start/stop queue
* change local limit
* change global limit
* change rate limit
* persist changes
* sync across nodes
* restrict queues to nodes/environments
* audit all changes

Recommended UI Flow

For every queue change:

1. Show current config.
2. Show proposed config.
3. Show affected nodes.
4. Ask for optional reason.
5. Apply change.
6. Emit telemetry.
7. Record audit event.

⸻

4.9 Lifeline, Repair, and Stuck Job Recovery

This is core day-2 value.

Oban’s core Lifeline warns that naive time-based rescue may duplicate still-executing jobs. Oban Pro DynamicLifeline expands repair to orphaned jobs, exhausted available jobs, stuck workflows/chains, missing partition keys, and missing chunk IDs. A public GitHub issue also shows how painful “stuck executing/orphaned jobs with no logs” can be in production.  ￼

Required Features

* orphan detection
* orphan rescue
* producer heartbeat view
* executor heartbeat view
* stuck workflow detection
* stuck chain detection
* stuck chunk detection
* exhausted available-job repair
* missing partition-key repair
* repair dry-run
* repair audit log

Safety Rule

Repair actions should have modes:

:dry_run
:mark_retryable
:mark_cancelled
:force_unlock
:manual_only

Never silently repair ambiguous state without telemetry and audit logging.

⸻

4.10 Pruning and Retention

Oban core pruning is intentionally simple, while Oban Pro DynamicPruner publicly exposes flexible cron schedules and retention by queue, worker, and state.  ￼

Required Features

* retention by state
* retention by worker
* retention by queue
* retention by age
* retention by row count
* archive-before-delete option
* dry-run estimate
* UI controls
* audit log
* warning when pruning affects uniqueness/history/search

Recommended API

config :oban_powertools, ObanPowertools.Pruner,
  policies: [
    completed: [max_age: {7, :days}],
    discarded: [max_age: {90, :days}],
    cancelled: [max_age: {30, :days}],
    by_worker: [
      {"MyApp.Workers.AuditJob", max_age: {365, :days}}
    ]
  ]

⸻

4.11 Prioritization and Starvation Prevention

Oban Pro DynamicPrioritizer publicly describes boosting long-waiting job priorities to prevent starvation.  ￼

Required Features

* priority aging
* starvation detection
* queue lag thresholds
* max priority cap
* telemetry
* UI visibility
* dry-run mode

Design Rule

Priority changes should be explainable:

“This job’s priority was boosted because it waited 2h 10m in queue exports and crossed the starvation threshold.”

⸻

4.12 Autoscaling and Capacity Hints

Oban Pro DynamicScaler publicly describes queue-throughput-based horizontal cloud scaling, predictive scaling, queue filtering, multiple scalers, step size, and cooldown to prevent thrashing.  ￼

For an OSS solo-dev library, do not overfit to cloud APIs at first. Build a generic scaling signal layer.

Required Features

* queue lag measurement
* throughput measurement
* saturation measurement
* desired capacity calculation
* cooldown
* scale recommendation telemetry
* adapter behavior for actual cloud scaling

Recommended Boundary

defmodule ObanPowertools.Scaler.Adapter do
  @callback current_capacity(context) :: {:ok, non_neg_integer()} | {:error, term()}
  @callback scale_to(non_neg_integer(), context) :: :ok | {:error, term()}
end

Integrations Later

* Fly.io Machines
* Kubernetes HPA custom metrics
* ECS service desired count
* Gigalixir/Heroku process scaling
* local no-op recommendation mode

⸻

4.13 Observability and Tracing

Oban core emits rich telemetry for jobs, engine operations, plugins, queue shutdown, and orphan events. BullMQ’s telemetry docs also highlight OpenTelemetry-based job tracing as a useful way to track lifecycle and bottlenecks across distributed work.  ￼

Required Metrics

* jobs inserted
* jobs started
* jobs completed
* jobs failed
* jobs discarded
* jobs cancelled
* retries
* queue lag
* runtime
* wait time
* execution time
* error rate
* retry storm rate
* orphan count
* cron missed count
* limiter saturation
* workflow stuck count
* batch progress
* prune count

Required Traces

* enqueue span
* wait span
* execution span
* external API span
* retry span
* workflow step span
* batch callback span
* cron firing span

SRE Rule

Metrics are lossy and aggregated. Audit/evidence records are durable. Keep them separate.

⸻

4.14 Testing Helpers

Oban Pro exposes a Testing extension in its public overview. This category is essential because background jobs are easy to test poorly.  ￼

Required Helpers

assert_enqueued(worker: MyWorker, args: %{...})
refute_enqueued(worker: MyWorker)
perform_job(MyWorker, args)
drain_queue(:default)
drain_workflow(workflow_id)
assert_job_completed(job)
assert_job_discarded(job)
assert_batch_completed(batch_id)
assert_cron_fired(name)
with_frozen_time(fn -> ... end)

Required Test Modes

* inline mode
* manual mode
* sandbox-safe DB mode
* deterministic clock
* fake limiter
* fake scheduler
* fake signal bus
* LiveView dashboard test helpers

Design Rule

Testing helpers should validate the same typed args and uniqueness behavior as production inserts.

⸻

5. Lessons Learned and Footguns

5.1 Never Promise Exactly-Once Execution

Sidekiq’s best-practices docs state that jobs should be idempotent and transactional because Sidekiq will execute a job at least once, not exactly once. BullMQ similarly says it aims for exactly-once behavior but falls back to at-least-once in worst cases. Hangfire also describes at-least-once guarantees.  ￼

Product Rule

Say:

“At-least-once execution with tools for idempotency, uniqueness, retries, and repair.”

Do not say:

“Exactly-once jobs.”

Documentation Requirement

Create a first-class guide:

Guides
└── Reliability
    ├── At-Least-Once Execution
    ├── Idempotent Workers
    ├── Transactional Job Insertion
    ├── Uniqueness vs Idempotency
    └── Retrying External API Calls

⸻

5.2 Small, Stable, Serializable Args Win

Sidekiq recommends small and simple JSON-native job arguments, avoiding complex Ruby objects and symbols, because args are serialized and later deserialized. The same lesson applies to Oban jobs even though the storage is Postgres rather than Redis.  ￼

Product Rule

Typed args should still serialize to simple JSON-compatible data.

Prefer:

%{account_id: account.id}

Avoid:

%{account: %Account{}}

⸻

5.3 Rate Limits Need a Glossary and Simulator

Rate limit bugs are often conceptual bugs. Is the limit per node? Per cluster? Per tenant? Per API key? Per job start? Per completed job? Per second? Per rolling window? Per partition?

Oban Pro exposes several algorithms, Sidekiq Enterprise exposes limiter concepts including points-based limiting, and Celery’s per-worker rate limit warning shows how quickly semantics become surprising across distributed systems.  ￼

Product Requirement

Add:

mix oban_powertools.limiter.explain QUEUE JOB_ID
mix oban_powertools.limiter.simulate config/limits.exs

⸻

5.4 Indexes Are a Product Feature

A public Oban issue shows a user with roughly 2 million jobs experiencing timeout problems around uniqueness checks and indexes. Oban Pro’s v1.7 upgrade docs also emphasize new and rebuilt indexes for performance across chains, chunks, workflows, and general queries.  ￼

Product Rule

Ship index health as part of doctor.

Checks:

* missing indexes
* invalid indexes
* bloated indexes
* old index versions
* non-concurrent migration warnings
* slow uniqueness query explain plans
* missing workflow/chunk indexes
* missing partial indexes for hot states

⸻

5.5 Cron Is More Than Cron Syntax

Cron looks simple until time zones, leadership, overlap, missed runs, deploys, and clock skew enter the picture. Oban’s periodic docs list caveats around time zones, overlapping executions, cluster leadership, and one-minute resolution; DynamicCron adds persisted dynamic entries and guaranteed scheduling.  ￼

Product Rule

Every schedule needs:

* identity
* timezone
* overlap policy
* catch-up policy
* audit log
* next-fire preview
* missed-fire handling
* safe validation

⸻

5.6 Workflow Completion Is Not Job Completion

Workflow systems need their own lifecycle events. A job’s after_process hook does not imply the entire workflow is complete. Batch docs already show the need for explicit callbacks, and community discussion shows that developers naturally ask for final workflow callbacks.  ￼

Product Rule

Expose explicit lifecycle hooks:

on_workflow_started
on_workflow_step_completed
on_workflow_completed
on_workflow_failed
on_workflow_cancelled
on_workflow_stuck

⸻

5.7 UI Actions Must Be Scriptable

Sidekiq’s API docs say the Web UI uses the API exclusively and that anything available in the UI can be scripted. This is an excellent design principle for oban_powertools.  ￼

Product Rule

Every UI operation calls a public Elixir API.

Bad:

# LiveView directly updates DB rows.

Good:

ObanPowertools.Jobs.retry(job_id, actor: actor, reason: reason)

⸻

6. Architecture Recommendation

6.1 Package and Namespace

Hex package:

:oban_powertools

Main namespace:

ObanPowertools

Avoid namespaces that imply official affiliation, such as:

Oban.Pro.*
Oban.Web.*

6.2 Top-Level Modules

ObanPowertools
ObanPowertools.Config
ObanPowertools.Install
ObanPowertools.Telemetry
ObanPowertools.Auth
ObanPowertools.Audit
ObanPowertools.Worker
ObanPowertools.Args
ObanPowertools.Unique
ObanPowertools.Limits
ObanPowertools.Scheduler
ObanPowertools.Cron
ObanPowertools.Queues
ObanPowertools.Batches
ObanPowertools.Chains
ObanPowertools.Chunks
ObanPowertools.Workflows
ObanPowertools.Signals
ObanPowertools.Relay
ObanPowertools.Recorder
ObanPowertools.Lifeline
ObanPowertools.Pruner
ObanPowertools.Prioritizer
ObanPowertools.Scaler
ObanPowertools.Doctor
ObanPowertools.Testing
ObanPowertoolsWeb

6.3 Layering

Layer 1: Foundation

Responsibilities:

* config parsing
* repo discovery
* migration helpers
* telemetry helpers
* audit behavior
* auth behavior
* install generator
* version checks
* doctor checks

Layer 2: Worker Ergonomics

Responsibilities:

* typed args
* validation
* hooks
* deadlines
* recording
* encryption/redaction
* aliases
* test helpers

Layer 3: Operations Plugins

Responsibilities:

* dynamic queues
* cron/schedules
* lifeline repair
* pruning
* prioritization
* scaling hints

Layer 4: Composition

Responsibilities:

* batch
* chain
* chunk
* workflow
* signal
* relay
* graph repair

Layer 5: Smart Engine / Limits

Responsibilities:

* global concurrency
* partition concurrency
* rate limits
* weighted limits
* enhanced uniqueness
* async tracking
* bulk insert behavior
* accurate snooze

This should be developed carefully after the foundation, worker ergonomics, UI, and simpler plugins are stable. It is the highest-risk correctness area.

Layer 6: Web UI

Responsibilities:

* LiveView dashboard
* components
* filters
* charts
* bulk actions
* job detail
* workflow graph
* cron editor
* repair center
* audit log
* doctor UI

⸻

7. Suggested Data Model

Use separate Powertools tables rather than modifying Oban’s schema beyond supported Oban mechanisms.

Suggested tables:

oban_powertools_audit_events
oban_powertools_cron_entries
oban_powertools_cron_firings
oban_powertools_queue_configs
oban_powertools_limiters
oban_powertools_limiter_events
oban_powertools_batches
oban_powertools_batch_jobs
oban_powertools_batch_callbacks
oban_powertools_workflows
oban_powertools_workflow_steps
oban_powertools_workflow_edges
oban_powertools_chunks
oban_powertools_chunk_jobs
oban_powertools_recordings
oban_powertools_signals
oban_powertools_relays
oban_powertools_repairs
oban_powertools_doctor_runs

7.1 Migration Principles

* Use concurrent indexes for large tables where possible.
* Use partial indexes for hot job states.
* Use generated columns or expression indexes only with explicit Postgres version checks.
* Support table prefixes.
* Support multi-tenant app repos only if the host app config is explicit.
* Never run destructive migrations without clear release notes.
* Add doctor checks for migration drift.

⸻

8. API Design Principles

8.1 Behaviours Over Magical DSLs

Prefer explicit behaviours for advanced customization:

ObanPowertools.Auth
ObanPowertools.Audit.Sink
ObanPowertools.Scaler.Adapter
ObanPowertools.Limits.WeightProvider
ObanPowertools.Cron.Validator
ObanPowertools.Redactor

Use DSLs only where they dramatically improve day-0 ergonomics.

8.2 Public API Before UI

Every dashboard action should map to a public API function.

Example:

ObanPowertools.Jobs.retry(job_id, actor: actor, reason: reason)
ObanPowertools.Queues.pause(:default, actor: actor, reason: reason)
ObanPowertools.Cron.disable("nightly_sync", actor: actor, reason: reason)

8.3 Explicit Results

Prefer tagged tuples over hidden side effects.

{:ok, job}
{:conflict, existing_job}
{:deferred, reason}
{:blocked, explanation}
{:error, reason}

8.4 Explainability Everywhere

For jobs, queues, schedules, workflows, and limits, support:

ObanPowertools.explain(term)

Example output:

{:blocked,
 [
   {:queue_paused, :exports},
   {:rate_limit_exhausted, limiter: :github_api, resets_at: ~U[2026-05-18 13:00:00Z]},
   {:workflow_dependency_incomplete, step: :fetch_user}
 ]}

⸻

9. Dashboard UX Principles

9.1 Default Screens Should Answer Real Questions

The UI should answer:

* What is broken?
* What is slow?
* What is stuck?
* What changed?
* What can I safely do?
* What should I not touch?
* Why is this job not running?
* Why did this job retry?
* Is this retry safe?
* Which customer/account is affected?
* Did cron fire?
* Are we hitting a third-party API limit?

9.2 Bulk Actions Need Guardrails

Bulk actions should include:

* preview count
* affected states
* affected queues
* affected workers
* estimated blast radius
* dry run
* reason field
* confirmation
* audit event

9.3 Filters Are a Product Feature

Required filter dimensions:

* state
* queue
* worker
* args key/value
* meta key/value
* tag
* attempt count
* time range
* workflow ID
* batch ID
* tenant/account
* error kind
* node
* scheduled before/after
* runtime over threshold

9.4 The Best Page: “Why Isn’t My Job Running?”

This should be a flagship feature.

Possible diagnosis:

Job #12345 is not running because:
1. It is in queue :api.
2. Queue :api is active.
3. Local concurrency is available.
4. Global partition limit for tenant_id=acme is full.
5. Rate limiter github_api is exhausted until 13:00 UTC.
6. The job is also scheduled for 12:55 UTC.

This turns confusing queue behavior into operator-grade UX.

⸻

10. Integration Opportunities With szTheory Ecosystem

Keep these as optional adapters, not hard dependencies.

10.1 Parapet

Parapet should consume Powertools telemetry for:

* queue lag SLOs
* job failure burn rates
* retry storm alerts
* cron missed-fire alerts
* orphan rate alerts
* workflow stuck alerts
* limiter saturation alerts

10.2 Threadline

Threadline should receive durable audit records for:

* manual retry
* manual cancel
* queue pause/resume
* cron edit
* repair action
* pruning action
* workflow cancellation

10.3 Sigra

Sigra can provide:

* dashboard auth
* role checks
* actor identity
* tenant scoping

10.4 Chimeway / Mailglass

Use for notifications:

* queue stuck
* cron missed
* retry storm
* workflow failed
* import completed
* operator action required

10.5 Scoria

Scoria can trace AI-related jobs:

* LLM eval jobs
* RAG refresh jobs
* tool execution jobs
* prompt replay jobs
* async agent workflows

Powertools should emit enough job/workflow metadata for Scoria to link traces to background work.

10.6 Cairnloop

Cairnloop can use Powertools for:

* support email processing
* AI triage jobs
* KB refresh workflows
* escalation notification jobs
* customer context syncs

10.7 Crosswake

Crosswake can expose a mobile operator surface:

* queue health
* failed jobs
* retry/cancel actions
* incident push notifications
* cron missed alerts

⸻

11. Documentation Plan

11.1 Required Guides

Getting Started
├── Installation
├── First Dashboard
├── First Typed Worker
├── First Cron Entry
├── First Workflow
└── First Rate Limit
Core Concepts
├── Jobs, Workers, Queues
├── Attempts, Retries, Snoozes
├── At-Least-Once Execution
├── Idempotency
├── Uniqueness
├── Concurrency vs Rate Limits
├── Cron and Scheduling
├── Batches, Chains, Chunks, Workflows
└── Telemetry and Metrics
Operations
├── Dashboard
├── Job Search
├── Bulk Actions
├── Queue Controls
├── Cron Management
├── Repair Center
├── Pruning and Retention
├── Audit Log
├── Doctor
└── Runbooks
Security
├── Dashboard Auth
├── Action Authorization
├── Redaction
├── Encryption
├── Metadata Leaks
├── Stacktrace Leaks
└── Audit Events
Testing
├── Testing Workers
├── Testing Cron
├── Testing Workflows
├── Testing Rate Limits
├── Sandbox Mode
└── Deterministic Time
Advanced
├── Partitioned Limits
├── Weighted Rate Limits
├── Dynamic Queues
├── Autoscaling Adapters
├── Multi-Node Deployments
├── Postgres Index Health
└── Migration Strategy

11.2 Documentation Style

* Every concept gets a “when to use / when not to use” section.
* Every complex feature gets failure examples.
* Every operational feature gets a runbook.
* Every telemetry event is documented.
* Every migration has rollback notes.
* Every UI action maps to a public API function.

⸻

12. CI/CD and Quality Bar

12.1 Test Matrix

Run CI against:

* latest stable Elixir
* previous supported Elixir
* latest stable OTP
* previous supported OTP
* supported Postgres versions
* Phoenix app integration test
* plain Elixir app integration test

12.2 Test Categories

* unit tests
* Ecto changeset tests
* migration up/down tests
* concurrent insert tests
* uniqueness race tests
* limiter race tests
* cron missed-fire tests
* workflow graph tests
* stuck workflow repair tests
* orphan rescue tests
* pruning dry-run tests
* telemetry contract tests
* LiveView dashboard tests
* security/redaction tests
* property tests for limiter math
* chaos tests for node/process shutdown

12.3 Release Automation

Recommended:

* mix format
* Credo
* Dialyzer
* ExUnit
* property tests
* generated Phoenix test app
* Postgres service in CI
* docs generation
* changelog automation
* Release Please
* Hex publish workflow
* semantic versioning
* telemetry contract tests before release

⸻

13. Roadmap

Phase 0: Foundation

* package skeleton
* install generator
* migrations
* config
* telemetry namespace
* auth behavior
* audit behavior
* doctor command
* basic docs

Phase 1: Dashboard and Operations on Existing Oban

* embedded LiveView dashboard
* jobs page
* queues page
* job detail page
* retry/cancel/discard/snooze actions
* audit log
* basic charts
* saved filters
* public API for all UI actions

This phase gives immediate value without solving the hardest engine problems.

Phase 2: Typed Worker Ergonomics

* typed args
* changeset validation
* worker docs
* hooks
* deadlines
* redaction
* recording
* aliases
* test helpers

Phase 3: Dynamic Cron and Queues

* persisted cron entries
* missed-fire tracking
* catch-up policy
* dynamic queue config
* pause/resume
* node restrictions
* audit trail

Phase 4: Composition

* batches
* chains
* chunks
* workflows
* workflow graph UI
* callbacks
* stuck graph detection
* repair tools

Phase 5: Limits and Smart Engine Features

* global concurrency
* partition concurrency
* rate limits
* weighted limits
* limiter UI
* enhanced uniqueness
* bulk insert helpers
* async tracking
* accurate snooze

This is the phase that most closely maps to commercial “smart engine” functionality, so it needs the strongest correctness tests.

Phase 6: Advanced Operations

* lifeline repair center
* dynamic pruner
* prioritizer
* scaler adapter behavior
* OpenTelemetry spans
* Parapet integration
* Threadline integration
* notification adapters

⸻

14. “Ultimate Lib” Acceptance Criteria

oban_powertools becomes excellent when a Phoenix developer can say:

1. I installed it in minutes.
2. I got a useful dashboard immediately.
3. I can find failed jobs without SQL.
4. I can safely retry/cancel jobs.
5. I can see why jobs are blocked.
6. I can define typed workers with validation.
7. I can build workflows without inventing my own DAG tables.
8. I can manage cron from code or UI.
9. I can avoid third-party API limit violations.
10. I can detect stuck/orphaned jobs.
11. I can audit every operator action.
12. I can test workers and workflows easily.
13. I can expose metrics to SRE tooling.
14. I can understand the docs without reading source.
15. I can use it without paying for a commercial subscription.
16. I can trust it because it is honest about at-least-once execution, idempotency, and failure modes.

⸻

15. Final Product Principle

The core promise should be:

Oban Powertools makes background jobs inspectable, controllable, testable, and operable inside Phoenix.

The implementation should be:

* idiomatic Elixir
* Ecto-native
* Postgres-first
* Phoenix/LiveView-first
* telemetry-rich
* audit-friendly
* clean-room
* operator-grade
* honest about distributed-systems tradeoffs

The highest-leverage differentiator is not merely recreating paid feature checklists. It is combining those capabilities into a cohesive OSS developer and operator experience: typed workers, workflows, dynamic schedules, rate limits, repair tools, and a dashboard that explains what is happening.