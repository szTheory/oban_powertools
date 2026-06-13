# Workers And Idempotency

`ObanPowertools.Worker` is the default builder-facing entry point when you want app code to
enqueue typed jobs without pushing validation and duplicate suppression into every caller.

## What the wrapper adds

- typed `args:` declarations backed by an embedded schema
- `validate/1` for synchronous argument validation
- `enqueue/2` for idempotent inserts through the Powertools receipt table
- optional `limits:` declarations when the worker also needs durable rate control
- optional lifecycle hooks for observing start, success, retryable failure, and discard outcomes
- optional `timeout:` and `deadline:` safety declarations for runtime attempt limits and stale-work prevention
- optional output recording for successful `{:ok, payload}` results

The runtime still executes an `Oban.Worker`. Powertools just makes the builder contract stricter.

## Minimal worker

```elixir
defmodule MyApp.Billing.ProcessInvoiceWorker do
  use ObanPowertools.Worker,
    queue: :billing,
    args: [
      account_id: :integer,
      invoice_id: :integer,
      reason: :string
    ]

  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{} = args}) do
    MyApp.Billing.process_invoice(args.account_id, args.invoice_id, args.reason)
    :ok
  end
end
```

## What callers do

```elixir
case MyApp.Billing.ProcessInvoiceWorker.enqueue(%{
       account_id: 42,
       invoice_id: 9001,
       reason: "manual_retry"
     }) do
  {:ok, job} ->
    {:ok, job.id}

  {:conflict, job} ->
    {:ok, job.id}

  {:error, %Ecto.Changeset{} = changeset} ->
    {:error, changeset}
end
```

Important behavior:

- invalid args fail before the job is inserted
- the worker receives a casted `%__MODULE__.Args{}` struct
- duplicate enqueue attempts return `{:conflict, job}` for the original durable insert

That gives callers one stable API instead of ad hoc validation and “did we already queue this?”
checks spread across controllers, LiveViews, and services.

## Lifecycle hooks

Workers may override `on_start/1`, `on_success/2`, `on_failure/2`, and `on_discard/2`
when they need worker-local observation around `process/1`.

- `on_start/1` runs after Powertools validates and casts args, and before `process/1`.
- `on_success/2` runs when `process/1` returns `:ok` or `{:ok, value}`.
- `on_failure/2` runs for retry-eligible `{:error, reason}` returns and for process
  raises, throws, or exits when the wrapper can catch them.
- `on_discard/2` runs for explicit `:discard` / `{:discard, reason}` returns and final
  retry exhaustion.

The hook support boundary is intentionally narrow:

- hooks run in the job process
- hooks run outside any Powertools transaction
- hook failure does not fail the job
- hook failure does not crash the queue
- hook execution is not retried independently

Hook return values are ignored. Use hooks for best-effort local observation, cleanup, or
host-owned notifications, not for durable audit or execution control. The original Oban job
outcome still comes from `process/1`.

```elixir
defmodule MyApp.Billing.ProcessInvoiceWorker do
  use ObanPowertools.Worker,
    queue: :billing,
    args: [
      invoice_id: :integer
    ]

  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{invoice_id: invoice_id}}) do
    MyApp.Billing.process_invoice(invoice_id)
    :ok
  end

  @impl true
  def on_success(%Oban.Job{args: %__MODULE__.Args{invoice_id: invoice_id}}, event) do
    MyApp.WorkerEvents.invoice_processed(invoice_id, event.result)
    :ok
  end
end
```

`{:cancel, reason}` and `{:snooze, _}` do not dispatch Phase 53 post hooks.
operator-initiated Lifeline discards do not fire worker execution hooks; they are audited
through the Lifeline repair pipeline. Oban timeout kills may bypass worker hooks because the
BEAM can terminate the job process outside the wrapper; use Oban `[:oban, :job, :exception]`
telemetry for timeout observability.

## Timeout and deadline safety

Workers may declare `timeout:` and `deadline:` when they need bounded attempts and stale-work
protection:

```elixir
defmodule MyApp.Billing.ProcessInvoiceWorker do
  use ObanPowertools.Worker,
    queue: :billing,
    args: [invoice_id: :integer],
    timeout: 30_000,
    deadline: :timer.hours(24)

  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{invoice_id: invoice_id}}) do
    MyApp.Billing.process_invoice(invoice_id)
  end
end
```

Support truth:

- `timeout:` is a positive integer milliseconds value.
- `timeout:` delegates to Oban's per-attempt `timeout/1` kill timer.
- Oban timeout kills may bypass Powertools worker hooks.
- `deadline:` is a soft pre-run wall-clock expiry stored as `meta["__deadline_at__"]`.
- When expired, `deadline:` returns `{:cancel, :deadline_expired}` before `on_start/1` and `process/1`.
- `deadline:` does not interrupt already-running work.
- No Powertools-specific telemetry is emitted for deadlines in this phase.

## Output recording

Workers may opt in to recording successful output with `record_output: true`:

```elixir
defmodule MyApp.Reports.GenerateExportWorker do
  use ObanPowertools.Worker,
    queue: :reports,
    args: [account_id: :integer],
    record_output: true,
    output_limit: 65_536,
    output_retention: :standard

  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{account_id: account_id}}) do
    export = MyApp.Reports.generate_export(account_id)

    {:ok, %{export_id: export.id, status: "ready"}}
  end
end
```

Support truth:

- `record_output: true` records only `{:ok, payload}` results.
- Plain `:ok` remains a successful no-output result and does not create a record.
- Failed, cancelled, snoozed, discarded, raised, thrown, or exited attempts do not record output.
- Recording is best-effort operational evidence; recording failure logs a warning and does not fail or retry the job.
- Output recording runs before `on_success/2`, so success hooks can look up accepted records.
- `output_limit` is a positive integer byte cap; the default is `65_536` bytes (64 KiB).
- Payloads over `output_limit` are rejected with a warning rather than stored or truncated.
- `output_retention` accepts `:ephemeral`, `:standard`, or `:extended`.
- Retention is library-owned: `:ephemeral` is 6 hours, `:standard` is 7 days, and `:extended` is 30 days.
- Recorded output is operational context for recent job inspection, not business storage, not a transaction guarantee, and not immutable audit evidence.

Store large artifacts, rich domain data, or anything that must be durable in host-owned
storage. Return a small JSON-compatible reference instead:

```elixir
{:ok, %{file_id: export.id, storage_key: export.storage_key}}
```

That pattern keeps `JobRecord` useful for operators without turning the job table into a data
warehouse. Host domain tables, object storage, and audit logs remain the source of truth for
business data.

## At-rest argument redaction

Workers may declare `redact:` to drop sensitive fields from `oban_jobs.args` at enqueue time.
Declaring `redact: [:ssn, :token]` removes those keys from the stored JSONB column before the
job is written — the field is absent from the row, not nulled or replaced with a placeholder.

```elixir
defmodule MyApp.Accounts.CreateUserWorker do
  use ObanPowertools.Worker,
    queue: :accounts,
    args: [user_id: :integer, ssn: :string],
    redact: [:ssn]

  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{user_id: user_id}}) do
    MyApp.Accounts.provision(user_id)
    :ok
  end
end
```

Support truth:

- `redact:` removes fields from args at enqueue; it does NOT scrub recorded outputs. Workers must not return redacted/sensitive data from `process/1`.
- Redacted keys are dropped (key-absent in the JSONB, never nil or `"[REDACTED]"`).
- The idempotency fingerprint is computed from the full unredacted args before redaction. Two jobs with the same `user_id` but different `ssn` values produce different fingerprints.
- `redact:` applies only to top-level declared `args:` fields in v1.7.
- Redacted typed fields are automatically exempt from `validate_required` so jobs run and retry cleanly with the field absent from stored args.
- A typo'd `redact:` key (one not declared in `args:`) raises at compile time.
- A `redact:` key that is also a `partition_by: {:args, field}` limiter key raises at compile time — the partition key would land in meta and defeat redaction.
- Redaction applies to both the direct-insert path (`MyWorker.new(args) |> Oban.insert()`) and the cron-scheduled path.
- `meta`, `errors`, and stacktraces are not scrubbed. Operational evidence stays intact for diagnosis.
- `JobRecord.redacted` remains its honest `false` default. Output recording does not auto-scrub recorded payloads. Do not rely on `redact:` to clean the output a worker returns from `process/1`.

## Validation without enqueue

Use `validate/1` when you want to fail fast before presenting or persisting a user-facing action:

```elixir
MyApp.Billing.ProcessInvoiceWorker.validate(%{
  account_id: 42,
  invoice_id: 9001,
  reason: "manual_retry"
})
```

## When to stay on the wrapper

Use `ObanPowertools.Worker` when your job benefits from:

- a stable typed argument shape
- duplicate suppression at enqueue time
- a durable limiter binding

Use plain `Oban.Worker` only when you explicitly do not want those guarantees.
