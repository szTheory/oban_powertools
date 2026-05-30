# Features Research: Worker Lifecycle & Safety

**Domain:** Worker-level observability and safety for an Oban-backed Elixir job processing library
**Researched:** 2026-05-30
**Confidence:** HIGH (all claims verified against Oban OSS docs, Oban Pro docs, and direct codebase inspection)

---

## Context: What This Milestone Is Adding

v1.7 equips every `ObanPowertools.Worker` with four features that currently exist only in Oban Pro or not at all in the Oban ecosystem:

- **Worker hooks** (`on_start`, `on_success`, `on_failure`, `on_discard`) — observe-only callbacks, crash-caught
- **Soft `deadline:` + `timeout:` pass-through** to `Oban.Worker`
- **Output recording** — generalize the existing `Workflow.Result` schema/contract to all workers, not just workflow steps
- **`redact:` at-rest** — drop named args fields at persist time, never store them in the DB

The existing seams these features integrate with: `ObanPowertools.Worker` (`use` macro), `Workflow.Result` schema (already has `redacted` bool + `payload`), `DisplayPolicy` host behaviour, `Telemetry` frozen contract, `Idempotency.transaction/3` enqueue path.

---

## Worker Lifecycle Hooks

### What the Ecosystem Shows

**Oban OSS (free tier)** provides three telemetry events for job execution:
- `[:oban, :job, :start]` — fired when the job is fetched and about to execute
- `[:oban, :job, :stop]` — fires after success; `:state` is one of `:success`, `:cancelled`, `:snoozed`, `:failure`, `:discard`
- `[:oban, :job, :exception]` — fires after exception/crash; includes `:kind`, `:reason`, `:stacktrace`

These are telemetry events, not worker-level callbacks. Workers must attach global handlers; there is no per-worker hook system in OSS Oban.

**Oban Pro** ships a full hook system on `Oban.Pro.Worker`:
- `before_process/1` — runs before `process/1`; can short-circuit via `{:cancel, reason}` or `{:error, reason}`
- `after_process/3` — runs after the job completes with state (`:complete`, `:cancel`, `:discard`, `:error`, `:snooze`); observe-only, exceptions caught and logged
- `on_cancelled/2` — external state hook; fires for manual cancellation, deadline expiry, dependency failure; does NOT fire for `{:cancel, reason}` returns from `process/1` (that triggers `after_process/3` with `:cancel`)
- `on_discarded/2` — fires when `DynamicLifeline` or Oban exhausts retries; receives reason `:exhausted`

Key Oban Pro design decisions relevant here:
- Hooks are synchronous, run within the job process, and are crash-caught — they cannot cause job failure or queue crash
- `after_process/3` does NOT fire for bulk DB-level cancellations (`Oban.cancel_job/1`) — only for jobs that actually executed through `process/1`
- Hooks can be defined on the worker module or attached globally via `attach_hook/1` for cross-cutting concerns

**Sidekiq** uses a middleware model: server middleware wraps `yield` (job execution), enabling before/after-success/after-failure patterns via try/yield/ensure. No named `on_start`/`on_success`/`on_failure` callbacks in core — it is a convention, not a built-in API.

**The Powertools design** for v1.7 maps the Oban Pro concept onto the existing `ObanPowertools.Worker` macro:
- `on_start/1` — called at the start of `perform/1`, after args validation
- `on_success/2` — called when `process/1` returns `:ok` or `{:ok, _}`
- `on_failure/2` — called when `process/1` returns `{:error, _}` or raises
- `on_discard/2` — called when Oban discards the job (all attempts exhausted)

All are observe-only: return values ignored, exceptions caught and logged, no effect on job outcome.

### Table Stakes

| Feature | Why Expected | Complexity | Existing Seam |
|---------|--------------|------------|---------------|
| `on_start/1` — called before `process/1` with the job struct | Any observability system (Datadog APM, custom metrics) needs a start hook to open a span, record start time, or add logger metadata. Without this, workers cannot self-instrument. Oban Pro has `before_process/1`; this is the expected equivalent. | LOW | `ObanPowertools.Worker` `perform/1` wraps `process/1` already — insert before-call |
| `on_success/2` — called with `{job, result}` when process returns `:ok` / `{:ok, _}` | The most common hook use case: increment a counter, emit a custom event, or record an output after a job completes successfully. No Oban OSS equivalent. | LOW | Same `perform/1` wrapper |
| `on_failure/2` — called with `{job, error}` when process returns `{:error, _}` or raises | Failure hooks drive alerting, error reporting (Sentry/AppSignal), and custom retry logic. Without this, workers must pattern-match on `:exception` telemetry globally. | LOW | Same wrapper; exception catch block already exists implicitly |
| `on_discard/2` — called when job is discarded after exhausting retries | Discard events are often the right place to trigger compensating actions (refund a charge, notify a customer). Oban Pro has `on_discarded/2`; this is the expected equivalent. | MEDIUM | Requires Oban's discard telemetry event or a Lifeline-level hook; slightly harder than the execution hooks |
| All hooks are optional with no-op defaults | Workers that do not declare a hook should not be required to implement it. Standard `defoverridable` + default no-op pattern. | LOW | Standard Elixir `defoverridable` |
| All hooks are crash-caught — exceptions inside hooks do not fail the job | This is the universal expectation across Oban Pro, Sidekiq, and any serious hook system. A hook that crashes the worker is worse than no hook. | LOW | `try/rescue` wrapping each hook call |
| Hook return values are ignored | Hooks are observe-only. Allowing hooks to affect job outcome creates hidden control flow. Oban Pro's `after_process/3` is explicitly side-effects only. | LOW | Design constraint, not an implementation complexity |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Hook telemetry: emit `[:oban_powertools, :worker_hook, :invoked]` within the frozen contract | Lets operators measure hook invocation rate and failure rate (hook exceptions caught-and-logged) as a counter. Oban Pro does not emit telemetry for hook invocations. | LOW-MEDIUM | Requires adding `worker_hook` to the frozen telemetry contract — this is a contract extension, needs a test update. Low-cardinality keys: `hook` (`:on_start` / `:on_success` / `:on_failure` / `:on_discard`), `outcome` (`:ok` / `:error_caught`). |
| `on_discard` fires from the Lifeline discard path in addition to Oban's own discard detection | Powertools' Lifeline already owns orphan detection and repair. Hooking `on_discard` from the Lifeline path gives Powertools-managed discards the same observability as Oban-native discards. | MEDIUM | Requires Lifeline repair path to call the hook after a discard repair |

### Anti-Features / Scope Risks

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| `before_process` hook that can short-circuit execution (return `{:cancel, reason}`) | Oban Pro supports this for structured pre-execution guards, but it creates a hidden control flow path that bypasses the normal job outcome machinery. For Powertools, which routes all mutations through Lifeline, pre-execution cancellation from a worker hook is a footgun. | If a job should not execute, cancel it through the Operator API or during enqueue validation. Hooks are observe-only. |
| Per-hook error escalation (hook exception causes job failure) | Tempting to make `on_failure` hook failures "count" as failures. But if the hook itself crashes, the failure reason in the DB will be the hook exception, not the original job error — catastrophic for debugging. | Catch-and-log all hook exceptions. Emit a telemetry event if the hook itself crashes so operators can see it. |
| Global `attach_hook/1` registry across all workers | Oban Pro supports this for DRY cross-cutting concerns. It requires a runtime registry (GenServer or ETS), which adds supervision surface and a new failure mode. | Keep hooks per-worker in the `use ObanPowertools.Worker` macro for v1.7. Global hooks belong in a future milestone if adoption shows demand. |
| `on_success` hook receiving the full return value including large data structures | If `process/1` returns `{:ok, large_dataset}`, passing the full value to `on_success/2` risks copying large binaries between processes. | Pass `{job, result}` where `result` is the raw return value — callers should be aware they may need to slim their return values, or the hook should not hold references to large binaries. Document this. |

---

## Deadline & Timeout Pass-through

### What the Ecosystem Shows

**Oban OSS (free tier)** supports `timeout/1` as a worker callback:
- `def timeout(_job), do: :timer.seconds(30)` — sets maximum execution milliseconds
- Default is `:infinity`
- If the job exceeds the limit, it fails with `Oban.TimeoutError` and is retried like any other failure
- Configured at the worker level via a callback, not via `use Oban.Worker` options

**Oban Pro** adds `deadline:` on top of `timeout:`:
- `deadline: {1, :hour}` — a wall-clock absolute time limit from when the job was inserted
- With `force: true`, a job running past its deadline cancels itself mid-execution, triggering `on_cancelled/2` with reason `:deadline`
- Without `force: true`, deadline prevents scheduling but does not interrupt an already-running job
- This is a distinct concept from `timeout:` (execution duration) — deadline is wall-clock expiry, timeout is per-attempt execution limit

**The Powertools design** for v1.7:
- `timeout:` in `use ObanPowertools.Worker` → pass-through to `use Oban.Worker` as a compile-time default for the `timeout/1` callback
- `deadline:` → a "soft deadline" implemented as Powertools metadata: record the `deadline_at` timestamp on the job, check it at `on_start` time, cancel the job cleanly if the deadline has passed. This is "soft" because it does not interrupt a running job mid-execution; it prevents the job from starting if the deadline has already expired.

The "soft" framing is correct for a free-tier Oban approach because hard mid-execution cancellation requires Oban Pro's `DynamicLifeline` worker or a custom GenServer supervision mechanism.

### Table Stakes

| Feature | Why Expected | Complexity | Existing Seam |
|---------|--------------|------------|---------------|
| `timeout:` in `use ObanPowertools.Worker` options → `timeout/1` callback default | Oban OSS already supports `timeout/1`, but workers must implement it themselves. Providing it as a declarative option in `use ObanPowertools.Worker` is the DX improvement. Every serious job system (Sidekiq, ActiveJob, Celery) offers a per-worker timeout. | LOW | `ObanPowertools.Worker` macro already strips/passes through non-Oban opts; add `timeout:` to the pass-through list and generate a `timeout/1` override |
| `deadline:` enforced at `on_start` time (soft deadline — prevents execution, does not interrupt) | Wall-clock expiry is a common requirement: a job that sits in the queue for 2 hours because of backpressure should not execute if its business window has passed. Sidekiq Enterprise has this; Oban Pro has it. The soft variant (don't start if expired) is safe and implementable without Oban Pro. | MEDIUM | Requires storing `deadline_at` in job meta at enqueue time, checking it in the `perform/1` wrapper before calling `process/1`, returning `{:cancel, :deadline_expired}` if past |
| Deadline expiry cancels the job cleanly with a durable reason | When a job is cancelled due to deadline, the cancel reason must be inspectable. Oban records the cancel reason in `errors` field as JSON. | LOW | `{:cancel, :deadline_expired}` from `perform/1` is already supported by Oban's job state machine |
| Deadline expiry triggers `on_discard`-adjacent notification | If a job expires without ever running, operators and host apps should be notified. At minimum, emit a telemetry event. | LOW | Telemetry emit at deadline cancellation point |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Deadline stored in job meta (inspectable via `/ops/jobs` detail view) | The existing `/ops/jobs` job detail view renders `meta`. Storing `deadline_at` in meta means operators can see the deadline in the UI without any new code. | LOW | Store as ISO8601 string in `meta["__deadline_at__"]` at enqueue time via `Idempotency.transaction/3` |
| Doctor check: jobs with `__deadline_at__` that expired while still retryable | If a job is stuck in `retryable` state past its deadline, the doctor can surface this as a warning. These are jobs that will be cancelled on next attempt — operators should know. | LOW-MEDIUM | Doctor reads `oban_jobs` where `meta @> '{"__deadline_at__":...}'` and `state = 'retryable'` and deadline < now() |

### Anti-Features / Scope Risks

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Hard deadline: interrupt a running job mid-execution | This requires either Oban Pro's `DynamicLifeline` supervision mechanism or a custom GenServer that monitors the job process and kills it. It is a significant supervision complexity increase and a new failure mode (partially-completed work). | Ship soft deadline (don't start if expired) for v1.7. Document that hard deadline is a Pro feature. If demand arises, add it with the Batches milestone where DynamicLifeline patterns are already being considered. |
| `timeout:` as a runtime per-enqueue option | Allowing `MyWorker.enqueue(args, timeout: 5_000)` would require passing `timeout` through the job meta and reading it back in `timeout/1`. Increases complexity significantly vs a per-worker compile-time default. | Keep `timeout:` as a compile-time `use ObanPowertools.Worker` default. Per-job dynamic timeout is an advanced use case; workers can implement `timeout/1` themselves for that. |
| Combining `deadline:` with idempotency receipt keys in ways that cause silent no-ops | If a job with a deadline is already in the idempotency window, the receipt prevents re-enqueue — but the deadline on the live job may have already passed. This is a subtle interaction. | Document the interaction: deadline at-rest does not invalidate idempotency receipts. If a job's deadline passes while its receipt is active, the receipt will expire naturally and a re-enqueue will create a new job with a fresh deadline. |

---

## Output Recording

### What the Ecosystem Shows

**Oban OSS (free tier)**: `perform/1` can return `{:ok, value}` — the value is included as `:result` in the `[:oban, :job, :stop]` telemetry event metadata. It is NOT persisted to the database. There is no built-in output recording.

**Oban Pro**: `recorded: true` on a worker persists the `{:ok, value}` return value to the database (compressed, encoded). `fetch_recorded/1` retrieves it as `{:ok, result}` or `{:error, :missing}`. Default limit: 64MB compressed. Primarily used for workflow step result passing (consumer steps read from producer steps).

**Powertools existing art**: `ObanPowertools.Workflow.Result` is already a full durable output recording schema:
- `oban_powertools_workflow_results` table
- Fields: `attempt`, `status`, `payload`, `payload_bytes`, `retention`, `redacted`, `summary`, `recorded_at`, `expires_at`
- `belongs_to :workflow` and `belongs_to :step` — currently tied to workflow steps only
- `DisplayPolicy.workflow_result/2` already renders these results with host-policy redaction

The v1.7 task is to generalize this to all workers, not just workflow steps. A standalone job should be able to record its output to a `oban_powertools_job_results` table (or by generalizing `Workflow.Result` with nullable foreign keys).

### Table Stakes

| Feature | Why Expected | Complexity | Existing Seam |
|---------|--------------|------------|---------------|
| `record_output/2` callable from within `process/1` to persist the job's return value | Without this, job outputs are ephemeral (telemetry-only). Any system that needs to read a job's output — another job, a LiveView page, an API response — has no standard way to do so. Oban Pro's `recorded: true` sets this expectation. | MEDIUM | Generalize `Workflow.Result` schema: make `workflow_id` / `step_id` nullable, add `job_id` (oban job integer ID). Or create a parallel `ObanPowertools.JobResult` schema. |
| Recorded output persists the `{:ok, payload}` return value | Standard contract: if `process/1` returns `{:ok, %{field: value}}`, that map is the payload. Non-ok returns are not recorded (failure state is already in the job errors field). | LOW | Extract payload from `perform/1` return value; persist before returning to Oban |
| `fetch_result/1` — retrieve the latest recorded output for a job | Consumers (other workers, host app code) need to read the output. Return `{:ok, result}` or `{:error, :not_found}`. | LOW | Query `job_results` by job_id, order by `recorded_at` desc, limit 1 |
| Output visible in the `/ops/jobs` job detail view | If output is recorded but not surfaced in the operator UI, it has no operational value. The existing `DisplayPolicy.workflow_result/2` already handles rendering with redaction. Reuse it. | LOW | `DisplayPolicy.workflow_result/2` already exists; wire job detail view to load result row |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `output_limit:` compile-time option on the worker | Workers with large outputs can set a byte cap. If the payload exceeds the limit, recording fails gracefully (logs warning, does not fail the job). Matches Oban Pro's `recorded: [limit: N]` pattern. | LOW | Check `byte_size(Jason.encode!(payload))` against limit before insert |
| `output_retention:` as a declarative policy (`:standard`, `:extended`, `:ephemeral`) | `Workflow.Result` already has a `retention` field. Generalizing it to standalone jobs means retention-based pruning (via Lifeline) can apply uniformly. | LOW | Re-use existing `retention` field; wire Lifeline's archive prune cycle to include job results |
| Result visible in workflow step context when the job is a workflow step | If a workflow step job records its output, that output should propagate to the workflow's step result view. The existing `Workflow.Result` row for that step should be the same row — no duplication. | MEDIUM | When a job has a `workflow_id` and `step_name` in its meta, write to `Workflow.Result` via the existing path; otherwise write to a standalone `JobResult`. |

### Anti-Features / Scope Risks

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Auto-recording every worker's output by default | Storing every `{:ok, value}` for every job in the DB, even if the value is not needed, creates an unbounded storage growth problem. Oban Pro requires `recorded: true` as explicit opt-in for exactly this reason. | Require `record_output: true` in `use ObanPowertools.Worker` to opt into recording. Workers that do not declare it never have their output persisted. |
| Recording failure details as output | `{:error, reason}` results are already stored in the Oban job's `errors` JSONB field. Duplicating them into a results table creates inconsistency (two sources of truth for failure details). | Only record `{:ok, payload}` returns. Failure details live in the Oban jobs table exclusively. |
| Schema proliferation: creating a separate `oban_powertools_job_results` table | A new table means a new migration, a new schema module, a new query surface. The `Workflow.Result` schema already has all needed fields. | Generalize `Workflow.Result` with nullable `workflow_id`/`step_id` and a new `job_id` integer foreign key. Guard the existing workflow-step query path behind a non-null `workflow_id` check. This avoids a new table while keeping the existing schema intact. |
| Streaming large outputs (chunked or incremental recording) | For jobs producing very large outputs (100MB+), streaming would be needed. This is a fundamentally different storage pattern requiring either separate blob storage or a chunked table design. | Cap output size at a configurable limit (default 1MB). Document that jobs producing larger outputs should write to application storage and record a reference (S3 key, Postgres `id`) as the output. |

---

## At-rest Redaction (redact:)

### What the Ecosystem Shows

**Oban OSS**: No at-rest redaction. Args are stored as JSONB in the jobs table. Operators with DB access see all args.

**Oban Pro**: Supports `encrypted: true` on a worker — args are encrypted at rest (not just redacted). Only args are encrypted; meta, errors, and stacktraces remain plaintext. Encryption requires a 32-byte Base64 key. Args are decrypted when the job runs. This is encryption, not deletion.

**Powertools existing art**: `DisplayPolicy` already provides display-time redaction — the `render_job_field/3` function applies host policy before rendering args/meta in the UI. The `Workflow.Result` schema has a `redacted` boolean field. This is display-time masking, not at-rest deletion.

**The v1.7 `redact:` feature** is different from both: it drops specified fields from args at persist time. The data is never written to the DB. This is:
- Not encryption (data is gone, not scrambled)
- Not display-time masking (data is gone before storage)
- Not field nulling (the field key is dropped from the JSONB map entirely)

Use case: PII in args (email addresses, SSNs, credit card numbers) that must not be stored in the job queue table for compliance or data minimization reasons. The job still runs, but those specific args fields are absent from the DB record.

**The idempotency fingerprint interaction** (noted in PROJECT.md as the blocker for `encrypt:`): fingerprinting hashes the args for uniqueness. If `redact:` drops fields after fingerprint calculation, the fingerprint still captures the full args including the redacted values — correct behavior (uniqueness is based on what was submitted, not what was stored). But this must happen in the right order: `fingerprint(original_args)` → then `strip_redacted_fields(args)` → then `insert(stripped_args)`.

### Table Stakes

| Feature | Why Expected | Complexity | Existing Seam |
|---------|--------------|------------|---------------|
| `redact: [:field_name]` in `use ObanPowertools.Worker` options | Declarative field-level opt-out from at-rest storage. The most common compliance requirement: "don't store the raw token / email / SSN in the job queue." Without this, the only option is to not pass sensitive values as args at all — which breaks typed worker contracts. | LOW-MEDIUM | `ObanPowertools.Worker` macro: strip listed fields from args map after fingerprint calculation, before `Oban.Job` changeset insert |
| Redaction happens at enqueue time, in `Idempotency.transaction/3` | The redaction must happen before the args hit `oban_jobs`. The `Idempotency.transaction/3` already controls the enqueue path — this is the correct intercept point. | LOW | `Idempotency.transaction/3` already wraps `Oban.insert/2`; strip redacted fields from the args map before the changeset is built |
| Redacted fields are listed in worker metadata so operators know they are expected to be absent | Without documentation of which fields are redacted, an operator seeing `{}` in the args panel has no context. Store `__redacted_fields__: ["email", "token"]` in job meta at enqueue time (the meta field is not subject to redaction by this feature). | LOW | Add to job meta in `Idempotency.transaction/3` |
| `__redacted_fields__` visible in the `/ops/jobs` job detail view | The detail view should show "Fields redacted at enqueue: [:email, :token]" so operators know the args are intentionally incomplete. | LOW | Read `meta["__redacted_fields__"]` in the jobs detail LiveView |
| Redaction does not affect idempotency fingerprint calculation | The fingerprint must be calculated from the full original args before redaction. If it were calculated from the redacted args, two jobs with different tokens but same other fields would be considered identical — wrong. | LOW | Order constraint: calculate fingerprint first, then strip fields |
| `process/1` receives args without the redacted fields | The worker's typed args schema must declare redacted fields as optional (not `validate_required`). The job runs without those fields — this is intentional. The worker code must handle their absence. | LOW (design) | Document this constraint; redacted fields cannot be `validate_required` in the typed args schema |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `redact:` fields show as absent (key missing from JSONB), not null or placeholder | Null or `"[REDACTED]"` placeholders still store something in the DB. Key-absent means the field does not exist in the JSONB at all — cleaner for compliance audits ("does this column store PII?"). | LOW | Use `Map.drop(args, redacted_fields)` before changeset, not `Map.put(args, field, nil)` |
| Doctor advisory: worker has `redact:` fields but meta does not record `__redacted_fields__` | If a job was enqueued without the meta tracking (e.g., directly via `Oban.insert/2` bypassing the Powertools path), the operator has no signal that fields are expected to be absent. Doctor can check for jobs where the worker has `redact:` configured but `meta["__redacted_fields__"]` is absent. | MEDIUM | Requires introspecting worker modules at doctor time — complex; may not be worth it for v1.7 |
| `DisplayPolicy` respects `__redacted_fields__` meta for display | If a field is listed in `__redacted_fields__`, the display policy can render it as "Redacted at enqueue" in the args panel, rather than just showing the absent key. This is a display-policy enhancement, not a new policy requirement. | LOW | Update `DisplayPolicy.render_job_field/3` default rendering to check meta for `__redacted_fields__` |

### Anti-Features / Scope Risks

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| `encrypt:` (encryption at-rest) | PROJECT.md explicitly defers this: "collides with args-hashing idempotency fingerprint, blinds the v1.5 job filter (encrypted args aren't searchable), and leaks via meta/errors/stacktraces." Ship `redact:` (drop) instead. | `redact:` for fields that must not be stored. For fields that must be stored encrypted, the host app should encrypt the value before passing it as an arg. |
| Redacting fields from meta or errors | Meta is the operational sideband (used by limiters, idempotency, deadline tracking, `__redacted_fields__` itself). Errors are the failure evidence. Redacting from either breaks operational observability. | Restrict `redact:` to the `args` JSONB only. Never redact from meta or errors. |
| Allowing `redact:` on non-optional fields in the typed args schema | If a field is required (`validate_required`) in the typed args schema AND listed in `redact:`, the job will fail validation on the next retry (the DB has no value for that field). | Compile-time or enqueue-time validation: raise if a field appears in both `validate_required` (enforced by the Ecto changeset) and `redact:`. |
| Redaction as a display-only feature (not actual DB deletion) | Providing `redact:` semantics via `DisplayPolicy` rendering (showing `[REDACTED]` while the data exists in DB) is NOT what this feature delivers. That is already done by `DisplayPolicy`. | Make clear in docs and implementation: `redact:` means the data is never written to the DB. Display-time masking is `DisplayPolicy`'s domain. These are different features with different guarantees. |
| Retroactive redaction (scrub already-stored jobs) | A command like `ObanPowertools.Redactor.scrub_past_jobs/2` sounds useful for compliance remediation, but it modifies production job history, potentially invalidating forensic evidence and idempotency receipts. | Out of scope for v1.7. If demanded by an adopter, it belongs in a dedicated `Redactor` module with the full Lifeline preview/reason/audit pipeline wrapping each mutation. |

---

## Feature Interaction Notes

### Hook + Output Recording

`on_success/2` fires after `process/1` returns `{:ok, value}`. If output recording is enabled, the recording happens in the same `perform/1` wrapper, after the hook fires. Order: `process/1` returns → `record_output` persists → `on_success` fires. This order means `on_success` can assume the output is already in the DB if it needs to reference it (e.g., trigger a follow-up job that reads the output).

Alternative ordering: fire `on_success` first, then record. This would mean the hook fires before persistence, which could cause a race if the hook enqueues a consumer job. **Recommendation:** record first, then fire `on_success`. This matches the Oban Pro `after_process` design where the hook fires after the job state is already recorded.

### Hook + Deadline

`on_start/1` is the natural intercept point for soft deadline checking. The wrapper calls `on_start(job)`, then checks `meta["__deadline_at__"]`. If expired: return `{:cancel, :deadline_expired}` without calling `process/1` or other hooks. `on_failure/2` does NOT fire for deadline cancellation — it fires only for `process/1` errors. This matches the Oban Pro distinction between execution hooks and external state hooks.

### Redaction + Idempotency Fingerprint

Fingerprint calculation in `Idempotency.transaction/3` must operate on the original (pre-redaction) args. Redaction happens after `fingerprint = hash(original_args)` and before `changeset = Oban.Job.new(stripped_args)`. The idempotency receipt stores the fingerprint (hash), not the args themselves — so the receipt is correct regardless of redaction.

### Redaction + Output Recording

`record_output/2` persists the `{:ok, value}` returned by `process/1`. The return value is whatever the worker constructed inside `process/1`. If `process/1` referenced a redacted field (loaded from an external source, not from job args), the return value may contain that sensitive data. The host is responsible for not including sensitive data in recorded outputs. **Recommend documenting this explicitly:** "redact: removes fields from args at enqueue; it does not automatically redact fields from recorded outputs. Workers must not include redacted data in their process/1 return values."

### Hook + Telemetry Contract

`on_start`, `on_success`, `on_failure`, `on_discard` are implementation-level callbacks. If hook invocations emit telemetry, the events belong under a new `worker_hook` family in the frozen contract. This requires a contract extension (a new family added to `@contract` in `ObanPowertools.Telemetry`). The family should be: `worker_hook: [:hook, :outcome]` where `hook` is one of `:on_start`/`:on_success`/`:on_failure`/`:on_discard` and `outcome` is `:ok`/`:error_caught`. This is a low-cardinality expansion.

The alternative is to NOT emit Powertools telemetry for hooks and rely on Oban's own `[:oban, :job, :stop]` events for observability. This avoids the contract extension but loses per-hook granularity. **Recommendation:** Defer hook telemetry to a follow-on; ship the hooks as pure callbacks first. Adding telemetry in a later patch is always possible; removing it is a breaking change.

### Deadline + Workflow Steps

Workflow steps already track `await_deadline_at` on the `Step` schema. The new per-worker `deadline:` is a separate concept (execution deadline vs await signal deadline). The `meta["__deadline_at__"]` approach keeps them decoupled: workflow await deadlines live in the step row; execution deadlines live in job meta. No interaction conflict.

### Output Recording + Workflow Steps

Workflow steps that call `record_output/2` from within `process/1` should write to the `oban_powertools_workflow_results` table via the existing `Workflow.Result` path (keyed by `step_id`), not to a new standalone results table. The generalization is: detect whether the job has a workflow step context (check for `workflow_id` + `step_name` in meta) and route accordingly. This reuses existing infrastructure and avoids a second results table.

---

## MVP for v1.7

### Must Ship

- `on_start`, `on_success`, `on_failure`, `on_discard` hooks in `ObanPowertools.Worker` macro — observe-only, crash-caught, optional with no-op defaults
- `timeout:` pass-through in `use ObanPowertools.Worker` options
- Soft `deadline:` via `meta["__deadline_at__"]` — check at `on_start` time, cancel cleanly with `:deadline_expired`
- `__redacted_fields__` in meta + `Map.drop` on args before DB persist; correct fingerprint ordering
- `record_output: true` opt-in + `record_output/2` function + `fetch_result/1` query
- Generalized `Workflow.Result` (nullable `workflow_id`/`step_id`, new `job_id` key) OR a minimal `ObanPowertools.JobResult` schema — pick based on migration blast radius
- Output visible in `/ops/jobs` job detail view via existing `DisplayPolicy.workflow_result/2`

### Defer

- Global `attach_hook/1` registry — need adoption signal first
- Hard deadline (interrupt running job) — requires Oban Pro-level supervision; out of scope
- `encrypt:` — explicitly deferred by PROJECT.md decision
- Retroactive redaction (`Redactor.scrub_past_jobs/2`) — requires full audit pipeline
- Hook telemetry events — add after hooks are proven useful; avoids premature contract extension
- Doctor advisory for `redact:` without meta tracking — low value for v1.7 complexity cost

---

## Sources

- Oban Worker docs (official): https://oban.hexdocs.pm/Oban.Worker.html — HIGH confidence
- Oban Telemetry docs (official): https://oban.hexdocs.pm/Oban.Telemetry.html — HIGH confidence
- Oban Pro Worker docs (official): https://oban.pro/docs/pro/Oban.Pro.Worker.html — HIGH confidence
- `ObanPowertools.Worker` source: `/Users/jon/projects/oban_powertools/lib/oban_powertools/worker.ex` — HIGH confidence (direct source read)
- `ObanPowertools.Workflow.Result` schema: `/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/result.ex` — HIGH confidence
- `ObanPowertools.DisplayPolicy` module: `/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex` — HIGH confidence
- `ObanPowertools.Telemetry` module (frozen contract): `/Users/jon/projects/oban_powertools/lib/oban_powertools/telemetry.ex` — HIGH confidence
- `ObanPowertools.Workflow.Step` schema (deadline fields): `/Users/jon/projects/oban_powertools/lib/oban_powertools/workflow/step.ex` — HIGH confidence
- PROJECT.md defer decisions (encrypt:, redact:): `/Users/jon/projects/oban_powertools/.planning/PROJECT.md` — HIGH confidence
- Sidekiq middleware pattern: https://github.com/sidekiq/sidekiq/wiki/Middleware — MEDIUM confidence

---

*Feature research for: Oban Powertools v1.7 Worker Lifecycle & Safety*
*Researched: 2026-05-30*
