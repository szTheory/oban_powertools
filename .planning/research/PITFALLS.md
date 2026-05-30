# Pitfalls Research: Worker Lifecycle & Safety

**Domain:** Adding lifecycle hooks, output recording, deadline/timeout pass-through, and at-rest
redaction to an existing Oban Powertools library (v1.7).
**Researched:** 2026-05-30
**Confidence:** HIGH (verified against Oban source in `/deps/oban`, existing Powertools
implementation, Oban Pro docs, and Elixir BEAM semantics)

---

## Worker Lifecycle Hooks

### Common Mistakes

**Hooks called from `perform/1` body, not from outside it.**
The `ObanPowertools.Worker` macro currently injects a `perform/1` that validates args and delegates
to `process/1`. The natural place to add `on_start`, `on_success`, `on_failure`, and `on_discard`
is inside this `perform/1` wrapper. This is correct. Do not define them as Oban-level telemetry
handlers instead — that couples hook dispatch to telemetry wiring, adds latency, and fires outside
the job's process.

**Hooks not crash-caught produce silent queue failures.**
If any `on_start` or `on_success` callback raises and the wrapper does not rescue it, Oban treats
the exception as a job failure and retries the job. The job appears to fail at an ambiguous state
(work was done, hook crashed). Fix: wrap each hook invocation in `try … rescue … catch` and log
without re-raising. Oban Pro's `after_process/3` documents exactly this guarantee — "any exceptions
or crashes are caught and logged, they won't cause the job to fail or the queue to crash."

**`on_discard` vs `on_cancel` conflation.**
In Oban, a job that exhausts all attempts is `discarded` (engine calls `discard_job`). A job that
returns `{:cancel, reason}` from `perform/1` is `cancelled`. These are different states. Using a
single `on_failure` or `on_discard` callback that reads `job.state` to distinguish them is fragile
— the state is set by the engine *after* `perform/1` returns, so it is not yet visible from inside
the job's process during hook execution. Distinguish by wrapping on the return value from
`process/1`, not by polling `job.state`.

**Hooks do not fire after a timeout kill.**
Oban's `timeout/1` is implemented via `:timer.exit_after/3`, which sends an `EXIT` signal to the
job's process. Because this is a raw BEAM exit (not a raised exception), it unwinds the process
before any `after`-style callback or `rescue`/`catch` clause in the surrounding `perform/1` wrapper
can execute. `on_failure` will therefore *not* fire on timeout. This matches Oban Pro's documented
behavior: `on_cancelled` fires for external cancellations (not execution-path callbacks). Design the
system to accept this gap: timeout is a process-level termination, not a graceful return from
`process/1`. Adding a telemetry handler on `[:oban, :job, :exception]` with `kind: :exit` is the
correct supplementary surface for observing timeout events.

**Hooks executed in the wrong phase relative to output recording.**
If output recording (`on_success` persisting a result) is inside the hook but the hook fires before
the changeset is valid/saved, a crash in the Repo call leaves a partial side-effect. Keep hook
invocations entirely after the `process/1` call returns; keep the result-persist path inside the
`on_success` hook body or in a separate step that runs before `on_success` is called. The ordering
in `perform/1` should be: validate → process → record output → fire hooks.

**Defining hook callbacks with `@behaviour __MODULE__`.**
The current `Worker` macro already declares `@behaviour __MODULE__` for the `process/1` callback.
Adding hook callbacks to the same module-level behaviour is clean but forces *every* worker to
implement them. Use `defoverridable` with no-op defaults so adopters can selectively override only
the hooks they care about. Not doing this makes adoption painful and will generate Elixir compiler
warnings for unimplemented callbacks in every existing worker.

**Hook arity mismatch between workflow workers and plain workers.**
The existing `Workflow.Result` schema is scoped to `workflow_id` and `step_id`. When generalizing
output recording to plain workers via an `on_success` hook, the backing record must not require
workflow foreign keys. Use `nil` for both or move to a separate non-workflow result table. A single
schema with optional FKs creates Ecto constraint ambiguity and makes UI joins awkward.

### Prevention

- Wrap each hook call in a dedicated `safe_run_hook/3` that catches all exceptions and logs them
  at `:warning` level with the hook name and job ID. Never re-raise.
- In the `perform/1` macro injection, establish a canonical ordering: validate → run → record
  output → fire lifecycle hooks. Document this ordering as a contract.
- Provide default no-op implementations of every hook via `defoverridable`. Workers override only
  what they need.
- Accept that `on_failure` will not fire on timeout. Document this explicitly. Expose timeout
  events via the existing telemetry contract instead.
- Use pattern matching on the return value from `process/1` to determine which hooks fire, not
  on `job.state`.

---

## Deadline & Timeout Pass-through

### Common Mistakes

**Conflating `deadline:` (job-level) with `timeout:` (worker-level).**
Oban's `timeout/1` callback is a worker-level constraint: it limits how long a single execution
attempt runs before the job process is killed. A `deadline:` concept (as shipped by Oban Pro's
smart engine) is a job-level constraint: the job must complete by an absolute wall-clock time or
it is cancelled. These are not the same thing. Implementing `deadline:` as a wrapper around
`timeout/1` forces a relative duration calculation at enqueue time, which is wrong when jobs are
queued and deferred. If a job enqueued with a 5-minute deadline sits in the queue for 4 minutes,
there is only 1 minute left to execute — a static `timeout: 300_000` does not model this. If
Powertools's `deadline:` is just a compile-time shorthand for `timeout/1`, document this gap
explicitly so adopters do not expect wall-clock deadline semantics.

**Passing `timeout:` through `use ObanPowertools.Worker` without validating unit.**
`Oban.Worker.timeout/1` returns a value in milliseconds. If the Powertools macro accepts
`timeout: 30` and passes it through without conversion, workers will time out after 30ms instead
of 30 seconds. Enforce an explicit unit (e.g., require `:timer.seconds(30)`) or document that the
value must be in milliseconds and add a compile-time validation guard.

**`deadline:` write-through at job creation vs execution time.**
If `deadline:` is stored as a field in `Oban.Job.meta` at enqueue time, the executor must read it
and compute `max(0, deadline - now)` to determine the remaining timeout. Failing to do this
correctly (e.g., using the raw stored millisecond value as a timeout) means jobs dequeued after
substantial wait time will run for longer than intended. This is a silent bug — the job finishes
but violated the caller's deadline constraint.

**The timeout EXIT bypasses `on_failure` (see also: Lifecycle Hooks section).**
When `timeout/1` triggers via `:timer.exit_after/3`, the job process receives a raw exit signal.
The Oban executor (`Oban.Queue.Executor`) rescues this in its outer catch, so the job is marked
as a failure and retried. But any post-`process/1` hook code inside the Powertools `perform/1`
wrapper will not execute. Do not rely on `on_failure` to fire on timeout.

**`timeout/1` is a worker-level callback, not a job-level option.**
Oban does not accept `timeout:` in `Oban.Job.new/2` options — it is defined on the worker module
via the `timeout/1` callback. If Powertools accepts a per-job `timeout:` override at enqueue time
(e.g., `MyWorker.enqueue(args, timeout: 10_000)`), this requires runtime dynamic dispatch inside
the worker's `timeout/1` callback reading from `job.meta`. This is valid but requires storing the
value in meta at insert time. Do not confuse this with compile-time worker opts.

**Integer overflow / huge timeout hiding bugs.**
If a deadline calculation produces a very large integer (e.g., deadline far in the future minus
`System.system_time(:millisecond)` produces a negative number due to clock skew), passing a
negative value or near-`:infinity` value to `:timer.exit_after` has undefined behavior. Add a
lower bound of 0 and an upper bound guard.

### Prevention

- Validate that `timeout:` values are positive integers in milliseconds at compile time (inside
  `normalize_opts!/1` in the Worker macro). Reject atoms other than `:infinity`.
- If implementing `deadline:` as wall-clock semantics, store the absolute epoch in `job.meta` at
  enqueue time. At execution time, compute `remaining = deadline_epoch - now_ms` and pass that as
  the actual timeout. Clamp to a minimum of 1ms.
- If `deadline:` is merely a compile-time alias for `timeout:`, document it clearly as "relative
  duration per attempt, not wall-clock" and rename accordingly.
- Add a test that a worker with `timeout: :timer.seconds(1)` receives a `TimeoutError` after ~1s.

---

## Output Recording

### Common Mistakes

**Generalizing `Workflow.Result` directly breaks the schema's FK constraints.**
`ObanPowertools.Workflow.Result` has `belongs_to(:workflow, ...)` and `belongs_to(:step, ...)` with
`validate_required([:workflow_id, :step_id, ...])`. Using this schema for non-workflow workers
requires making both FKs optional — but that means changing a validated schema that already has
production data. The safer path is a new `oban_powertools_job_results` table scoped to `job_id`
(an integer FK to `oban_jobs`), with the workflow result table kept as-is. The v1.8 Batches
milestone reuses whichever result infrastructure lands here. Don't generalize by making FKs
nullable — use a separate schema.

**Payload size growth unchecked in tests but catastrophic in production.**
PostgreSQL's JSONB TOAST threshold is ~2 KB. Values above ~2 KB trigger TOAST storage and can
slow read performance 2–10x. A worker recording a full paginated API response (even "accidentally"
via `Map.from_struct(job)`) will degrade query performance on every Lifeline and audit read that
joins results. Enforce a configurable `max_payload_bytes` at the recording callsite, truncating or
raising before the Repo insert.

**Recording output inside the Ecto.Multi that performs the business operation.**
If output recording shares the same `Ecto.Multi` as the worker's main transaction, a Repo error
in any other step rolls back the result record too. This means a partial success (business logic
committed, result not recorded) is indistinguishable from a total failure. Record output in a
*separate* Repo operation after the business transaction commits, or at minimum wrap only the
result insert in an independent transaction with a best-effort semantics flag.

**Double-recording on retry.**
Workers that are retried after a crash may attempt to record a result twice. The existing
`Workflow.Result` schema has a `unique_constraint([:step_id, :attempt])` — this is the right
model. A generalized `job_results` table must have a `unique_constraint([:job_id, :attempt])`.
Without it, retried workers accumulate duplicate result rows and aggregation queries on the UI
produce inflated counts.

**`on_success` hook recording arbitrary `{:ok, value}` tuples.**
Oban's `perform/1` return value `{:ok, value}` is documented as "value is ignored." If the
Powertools `on_success` hook reads the return value to persist it, it must destructure specifically
for `{:ok, value}` and treat plain `:ok` as "no output." Workers returning `:ok` with side effects
are not broken — they just produce a no-op result record. Don't silently record a `nil` payload;
distinguish "produced no output" from "produced an empty map."

**Recording results for `{:cancel, reason}` as success.**
The macro wraps `process/1` and must route to `on_success`, `on_failure`, or `on_discard`
correctly. A `{:cancel, reason}` return from `process/1` is a cancellation path, not a success
path. Recording a result row for it as "ok" status misleads the audit surface. The `status` field
on the result schema should reflect the actual terminal state.

**Leaking `redact: true` fields into the recorded payload.**
If a worker's args schema has fields marked for redaction and the output recording step naively
records `Map.from_struct(job.args)`, PII fields that were supposed to be dropped at persist will
appear in the result payload. The output recording layer must run the same redaction pass that
the `args` layer applies.

### Prevention

- Use a new `oban_powertools_job_results` table, not a modified `Workflow.Result`. Add `job_id`
  FK + `unique_constraint([:job_id, :attempt])`.
- Enforce `max_payload_bytes` (configurable, default 64 KB) with a guard before the Repo insert.
  Store `payload_bytes` on the record.
- Record output outside the business `Ecto.Multi` in a best-effort post-commit insert.
- Distinguish `:ok` (no-output success) from `{:ok, value}` (output success) and record accordingly.
- Route `{:cancel, reason}` to `on_cancel` hook path, not `on_success`, with `status: "cancelled"`.
- Pass args through the existing redaction layer before building the result payload.

---

## At-rest Redaction

### Common Mistakes

**Redacting after the idempotency fingerprint is already committed.**
The existing `Idempotency` module generates a SHA-256 fingerprint of `{worker, args}` at enqueue
time and stores it in `oban_powertools_idempotency_receipts`. If `redact:` fields are dropped
*before* fingerprinting, two jobs with different values in the redacted field produce the same
fingerprint — a false deduplication collision. The correct ordering: fingerprint first (on the
full args), then redact before persisting the `oban_jobs.args` row. Do not redact in place on the
`Args` struct before calling `generate_fingerprint/2`.

**Redacting inside `validate/2` / `changeset/2` rather than at the Oban insert boundary.**
If redaction happens in the Ecto changeset (e.g., overwriting a field with `nil` in
`Args.changeset/2`), the redacted field is absent from the casted struct that `process/1`
receives. This breaks workers that need the redacted value to do their job. Redaction is an
*at-persist* concern, not a *runtime* concern. The `redact:` option should cause the field to be
dropped from `Oban.Job.args` when the changeset is handed to `repo.insert`, but the in-memory
struct passed to `process/1` must retain the value.

**Using Ecto's `redact: true` field option thinking it drops at persistence.**
Ecto's `redact: true` only affects `Inspect` output (it prints `"**redacted**"` instead of the
value). It does not prevent the value from being written to the database. A worker author who adds
`field(:ssn, :string, redact: true)` assuming this prevents persistence will be wrong — the value
is still written to `oban_jobs.args` in plaintext. Powertools must implement its own at-persist
drop by identifying `redact:` fields and zeroing them in the JSON map before the Oban insert, not
by relying on Ecto's display-only mechanism.

**`redact: true` fields appearing in error stacktraces and `oban_jobs.errors`.**
Even if args are correctly redacted at persist time, if a worker raises an exception whose message
includes inspected args (e.g., `"invalid value #{inspect(job.args)}"`) the error string stored in
`oban_jobs.errors` will contain the plaintext PII. The `errors` column is not in scope for
`redact:` unless a post-error scrubbing pass is added. Document this boundary clearly: `redact:`
prevents args from being stored in `oban_jobs.args`, but does not sanitize error messages. This
is a compliance risk for adopters who assume blanket PII removal.

**`redact: true` fields present in idempotency receipt or limiter meta.**
The `merge_limits_meta/4` call in `Idempotency` writes `oban_powertools.limits.binding` into
`job.meta`. If the limiter's `partition_by: {:args, :user_id}` reads a redacted field, the
partition key (which may be the PII value itself) ends up in `job.meta`. Redaction must be
coordinated with the limiter resolution step — either partition keys for redacted fields must be
hashed, or the field must not be marked for redaction if it is also a partition key.

**Redact fields breaking the `process/1` function signature.**
If `Args.changeset/2` drops a redacted field to `nil` at changeset-build time (not at persist
time), the `process/1` function receives a struct with `nil` for a field the worker depends on.
This causes a runtime crash or silent bad behavior that is hard to test. As above: redaction is
not a type-level constraint — it is a persistence-level filter.

**Re-introducing redacted fields through `Workflow.Result` payload.**
A worker may redact a field from `job.args` but then record it in the output result via
`on_success`. If the result payload is not also filtered, the PII surfaces in
`oban_powertools_workflow_results.payload` (or the new `job_results` table). The output recording
layer must apply the same redacted-field exclusion list when building the result payload.

**Redaction not visible on the DisplayPolicy surface.**
The existing `DisplayPolicy` behaviour renders `workflow_result` with a `redacted?: boolean` flag.
If a job result is recorded after redaction, the `redacted: true` flag must be set on the result
row so the UI correctly signals "this result was stored with redaction" rather than "no result."
Failing to set this means the UI reports "no result recorded" instead of the accurate
"result stored, redacted fields omitted."

### Prevention

- Generate the idempotency fingerprint from the *full* args struct before any redaction pass.
- Apply the redaction drop as a final transform on the `args` map passed to `Oban.Job.new/2`,
  not inside the Ecto changeset.
- Never rely on Ecto's `redact: true` for persistence safety — it is display-only.
- Validate at compile time that no field is simultaneously declared `redact: true` and referenced
  as a `partition_by: {:args, field}` limiter key.
- Document explicitly: `redact:` drops from `oban_jobs.args`. Error messages in `oban_jobs.errors`
  are not scrubbed. Compliance requirements beyond args-at-persist need additional layers.
- When recording output, pass the same `redact: [...]` field list to the output recording step.
  Set `redacted: true` on the result row if any fields were dropped.

---

## Cross-cutting Integration Pitfalls

### Callback Interactions

**Worker hooks and Workflow callback outbox fire at different points in the same execution.**
For workflow workers, `on_success` fires inside `perform/1` (in-process, synchronous), while the
workflow callback outbox is dispatched post-commit by the `Runtime` module (deferred, at-least-once
via `CallbackHandler`). If an `on_success` hook raises and is swallowed, the outbox delivery still
fires — but the hook's side effects (e.g., writing a result record) may not have landed. Adopters
who chain hook → outbox → downstream must understand that hook execution is best-effort and outbox
delivery is durable, not that they share a transactional boundary.

**`on_discard` is not the same as a workflow `step_failed` callback.**
The workflow `CallbackHandler` fires `workflow.terminal` with `terminal_cause: "step_failed"` when
a workflow step is discarded. A plain worker's `on_discard` hook fires inside the job process.
These are two separate observation surfaces for what looks like the same event. If Powertools
generalizes `Workflow.Result` to plain workers, do not wire `on_discard` to the workflow callback
outbox for non-workflow workers — that conflates two independent contracts.

**Hook ordering when multiple features compose.**
The execution order inside `perform/1` will be: validate → process → record output → fire hooks.
If an adopter overrides `on_success` and also has a Workflow callback, the Workflow callback fires
*after* the job process exits (post-commit), meaning an `on_success` hook that writes a record
that the Workflow callback reads may not be visible in the same transaction. Use `inserted_at`
ordering, not process ordering, for downstream consumers.

**Telemetry contract must be extended for new hook events.**
The existing `@contract` in `ObanPowertools.Telemetry` is frozen at five families with strict
low-cardinality metadata keys. Adding `on_start`, `on_success`, `on_failure`, `on_discard`
lifecycle events without adding a `:worker` family to the contract means the events are not
observable via `ObanPowertools.Telemetry.metrics/0`. Adding a new family is a public API change —
it must follow the same low-cardinality constraint (no job IDs, no reasons, no args values in
metadata). Plan for this before shipping hooks.

**`on_failure` fires on retry-eligible failures AND on final-attempt exhaustion.**
Oban's executor normalizes `:failure` to `:exhausted` when `attempt >= max_attempts`, but both
states produce an error from `process/1`'s perspective. If `on_failure` fires for both states,
adopters who use it to notify PagerDuty will send N alerts for a job that retries 20 times. Add
an `on_discard` specifically for the exhausted/discarded terminal state, distinct from the
retry-eligible `on_failure`. This matches Oban Pro's distinction between `after_process/3` (all
outcomes) and `on_discarded/2` (terminal exhaustion only).

**Redacted args fields silently absent from `on_start` hook.**
If `on_start(job)` is called before the worker's business logic runs, and the `job.args` at that
point already has redacted fields dropped, the hook receives an incomplete args struct. If the
`on_start` hook uses args for logging or context propagation, PII fields will be absent without
notice. Decide definitively: hooks receive the pre-redaction in-memory struct (runtime view) or
the redacted struct (as-persisted view). The right answer is pre-redaction in-memory, since the
job is *executing* not *persisting* at that point.

**Idempotency fingerprint visible in `job.meta` after redaction.**
The `meta.oban_powertools.idempotency_fingerprint` stored at enqueue time is a SHA-256 of the
full (unredacted) args. This is correct for deduplication, but means a motivated observer with
access to `oban_jobs.meta` can brute-force the redacted field values if the field's domain is
small (e.g., a 4-digit PIN). For fields where this matters, document the risk clearly.

### Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|---|---|---|
| Hook macro injection | Hook not crash-caught; retries job on hook failure | Add `safe_run_hook/3` wrapper before any hook call |
| Timeout pass-through | `deadline:` confused with `timeout:`; wrong unit | Validate millisecond unit at compile time; document relative vs wall-clock |
| Timeout + hooks | `on_failure` not called after timeout kill | Use telemetry on `[:oban, :job, :exception]` for timeout observability |
| Output recording schema | Modifying `Workflow.Result` to support non-workflow jobs | New `job_results` table with `(job_id, attempt)` unique constraint |
| Output recording payload | Unbounded payload size degrading JSONB queries | Enforce `max_payload_bytes` with configurable cap before insert |
| Redaction ordering | Fingerprint computed after redaction → dedup collisions | Fingerprint before redact; redact only the `Job.new` args map |
| Redaction + Ecto `redact:` | Ecto's `redact: true` mistaken for at-persist protection | Custom at-persist filter; document Ecto's behavior is display-only |
| Redaction + limiter partition | Redacted field is also `partition_by` key → PII in meta | Compile-time guard against overlapping `redact:` and `partition_by:` |
| Telemetry contract | Hooks add high-cardinality metadata to frozen contract | Define a new `:worker` event family before shipping hooks |
| `on_discard` semantics | Fires on every failed attempt, not just terminal exhaustion | Separate `on_discard` (terminal) from `on_failure` (retry-eligible) |
| Result + display policy | `redacted: false` on result row despite redacted args | Set `redacted: true` on result row when any field was dropped |

---

## Sources

- Oban executor source: `/deps/oban/lib/oban/queue/executor.ex` — timeout kill via `:timer.exit_after`, hook gap confirmed
- Oban worker source: `/deps/oban/lib/oban/worker.ex` — `timeout/1` callback contract, millisecond unit
- [Oban Pro Oban.Pro.Worker docs](https://oban.pro/docs/pro/Oban.Pro.Worker.html) — `after_process/3`, `on_cancelled/2`, `on_discarded/2`, safety guarantees
- Powertools `Idempotency` source: `/lib/oban_powertools/idempotency.ex` — fingerprint before args redaction dependency
- Powertools `Workflow.Result` schema: `/lib/oban_powertools/workflow/result.ex` — FK constraints precluding generalization
- Powertools `DisplayPolicy` source: `/lib/oban_powertools/runtime_config.ex` — `redacted?: boolean` surface requirement
- [Elixir try/catch/rescue docs](https://hexdocs.pm/elixir/try-catch-and-rescue.html) — `after` does not run when a linked process exits via EXIT signal
- [PostgreSQL JSONB TOAST performance](https://pganalyze.com/blog/5mins-postgres-jsonb-toast) — ~2 KB TOAST threshold performance cliff
