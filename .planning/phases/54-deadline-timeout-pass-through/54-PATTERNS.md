# Phase 54: deadline: / timeout: Pass-through - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 13
**Analogs found:** 12 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/worker.ex` | worker macro / API | request-response, transform | `lib/oban_powertools/worker.ex` existing args/limits macro paths | exact |
| `lib/oban_powertools/worker/deadlines.ex` | utility | transform | No direct analog; use worker validation + Doctor parsing patterns | partial |
| `lib/oban_powertools/idempotency.ex` | service | CRUD, request-response | `lib/oban_powertools/idempotency.ex` existing limiter meta merge | exact |
| `lib/oban_powertools/doctor.ex` | service / orchestrator | batch, request-response | `lib/oban_powertools/doctor.ex` check composition | exact |
| `lib/oban_powertools/doctor/checks.ex` | service / diagnostic check | batch, file-I/O via DB query | `lib/oban_powertools/doctor/checks.ex` uniqueness-timeout checks | exact |
| `lib/oban_powertools/doctor/formatter.ex` | formatter | transform | `lib/oban_powertools/doctor/formatter.ex` warning/error rendering | exact |
| `lib/mix/tasks/oban_powertools.doctor.ex` | CLI task | request-response | `lib/mix/tasks/oban_powertools.doctor.ex` strict-mode docs and boot path | exact |
| `test/oban_powertools/worker_test.exs` | test | request-response | existing generated worker and hook ordering tests | exact |
| `test/oban_powertools/idempotency_test.exs` | test | CRUD | existing enqueue/conflict/fingerprint tests | exact |
| `test/oban_powertools/doctor/checks_test.exs` | test | batch, DB query | existing Doctor check tests | exact |
| `test/oban_powertools/doctor/formatter_test.exs` | test | transform | existing human/JSON formatter tests | exact |
| `test/mix/tasks/oban_powertools.doctor_test.exs` | test | request-response | existing CLI source-contract tests | exact |
| `guides/workers-and-idempotency.md` | documentation | transform | existing worker docs and support-boundary prose | exact |

## Pattern Assignments

### `lib/oban_powertools/worker.ex` (worker macro/API, request-response + transform)

**Analog:** No direct analog. Partial patterns from `lib/oban_powertools/worker.ex`, `lib/oban_powertools/worker/hooks.ex`, and `lib/oban_powertools/doctor/checks.ex`.

**Imports and option stripping pattern** (lines 8-26):
```elixir
defmacro __using__(opts) do
  args_config = Keyword.get(opts, :args, [])
  limits_config = Keyword.get(opts, :limits, [])
  oban_opts = opts |> Keyword.delete(:args) |> Keyword.delete(:limits)
  validate_args_config!(args_config)
  normalized_limits = normalize_limits_config!(limits_config, __CALLER__.module)

  quote do
    use Oban.Worker, unquote(oban_opts)
    @behaviour __MODULE__
    import Ecto.Changeset
    @powertools_limits unquote(Macro.escape(normalized_limits))
```

Copy this shape for `:timeout` and `:deadline`: read them before `oban_opts`, validate them in the outer macro, and delete both before `use Oban.Worker`.

**Generated perform ordering pattern** (lines 85-125):
```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: args} = job) when is_map(args) do
  case validate(args) do
    {:ok, casted_args} ->
      __powertools_perform__(%{job | args: casted_args})

    {:error, changeset} ->
      {:error, changeset}
  end
end

defp __powertools_perform__(%Oban.Job{} = job) do
  ObanPowertools.Worker.Hooks.on_start(__MODULE__, job)

  try do
    result = process(job)
    ObanPowertools.Worker.Hooks.after_result(__MODULE__, job, result)
    result
```

Insert deadline cancellation at the top of `__powertools_perform__/1`, before `Hooks.on_start/2`. Keep args validation before the deadline check.

**Validation helper pattern** (lines 236-304):
```elixir
defp normalize_limits_config!(limits_config, module) when is_list(limits_config) do
  name = fetch_limit!(limits_config, :name)
  scope = fetch_limit!(limits_config, :scope)
  bucket_capacity = fetch_limit!(limits_config, :bucket_capacity)
  bucket_span_ms = fetch_limit!(limits_config, :bucket_span_ms)
  default_weight = Keyword.get(limits_config, :default_weight, 1)

  validate_positive_integer!(bucket_capacity, ":limits bucket_capacity")
  validate_positive_integer!(bucket_span_ms, ":limits bucket_span_ms")
  validate_positive_integer!(default_weight, ":limits default_weight")
end

defp validate_positive_integer!(value, _label) when is_integer(value) and value > 0, do: :ok

defp validate_positive_integer!(value, label) do
  raise ArgumentError, "expected #{label} to be a positive integer, got: #{inspect(value)}"
end
```

Reuse this error style for `:timeout` and `:deadline` positive integer millisecond validation.

**External Oban timeout contract** (deps/oban lines 408-415, 482-497, 545-547):
```elixir
@doc """
Set a job's maximum execution time in milliseconds.
...
Defaults to `:infinity`.
"""
@callback timeout(job :: Job.t()) :: :infinity | pos_integer()

@impl Worker
def timeout(%Job{} = job) do
  Worker.timeout(job)
end

defoverridable Worker

def timeout(%Job{} = _job) do
  :infinity
end
```

Generate `timeout/1` only for configured `timeout:` and keep it overridable so a host-defined callback wins.

---

### `lib/oban_powertools/worker/deadlines.ex` (utility, transform)

**Analog:** `lib/oban_powertools/worker.ex`

No existing deadline utility exists. Create this only if keeping parsing/normalization in `worker.ex` would make the macro hard to read.

**Module style to copy** (from `lib/oban_powertools/worker/hooks.ex` lines 1-7):
```elixir
defmodule ObanPowertools.Worker.Hooks do
  @moduledoc false

  require Logger

  alias ObanPowertools.Telemetry
```

**Defensive parsing precedent** (from `lib/oban_powertools/doctor/checks.ex` lines 205-230):
```elixir
def oban_db_version(repo, prefix) do
  sql = """
  SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
  FROM pg_class
  ...
  """

  case repo.query(sql, [prefix], log: false) do
    {:ok, %{rows: [[v]]}} when is_binary(v) ->
      case Integer.parse(v) do
        {n, _rest} -> n
        :error -> nil
      end

    _ ->
      nil
  end
end
```

Use the same defensive style for `DateTime.from_iso8601/1`: malformed or missing `meta["__deadline_at__"]` must return "allow normal execution", not raise.

---

### `lib/oban_powertools/idempotency.ex` (service, CRUD + request-response)

**Analog:** `lib/oban_powertools/idempotency.ex`

**Imports pattern** (lines 1-8):
```elixir
defmodule ObanPowertools.Idempotency do
  @moduledoc """
  Handles durable idempotency receipts and atomic job insertion.
  """

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Explain, Limits}
  alias ObanPowertools.Idempotency.Receipt
```

**Fingerprint-before-job pattern** (lines 42-82):
```elixir
def transaction(worker_mod, args, opts \\ []) do
  case worker_mod.validate(args) do
    {:ok, casted_args} ->
      repo = opts[:repo] || infer_repo()
      fingerprint = generate_fingerprint(worker_mod, casted_args)
      do_enqueue(repo, worker_mod, casted_args, fingerprint, opts)

    {:error, changeset} ->
      {:error, changeset}
  end
end

job_changeset =
  worker_mod.new(args_map, merge_limits_meta(opts, worker_mod, args, fingerprint))
```

Add deadline meta after fingerprint generation and before `worker_mod.new/2`; never include deadline timestamp in the fingerprint payload.

**Reserved meta merge pattern** (lines 147-171):
```elixir
defp merge_limits_meta(opts, worker_mod, args, fingerprint) do
  meta = Keyword.get(opts, :meta, %{})

  limits_meta =
    case ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
      {:ok, nil} -> %{}
      {:ok, snapshot} ->
        %{
          "oban_powertools" => %{
            "idempotency_fingerprint" => fingerprint,
            "limits" => snapshot.binding
          }
        }
    end

  Keyword.put(opts, :meta, deep_merge(meta, limits_meta))
end

defp deep_merge(left, right) when is_map(left) and is_map(right) do
  Map.merge(left, right, fn _key, a, b -> deep_merge(a, b) end)
end
```

Merge caller meta first and Powertools meta second. For `__deadline_at__`, Powertools must overwrite any caller-supplied spoofed value.

---

### `lib/oban_powertools/doctor.ex` (service/orchestrator, batch)

**Analog:** `lib/oban_powertools/doctor.ex`

**Check composition pattern** (lines 6-20):
```elixir
defmodule ObanPowertools.Doctor do
  alias ObanPowertools.Doctor.Checks

  @spec run(module(), keyword()) :: [ObanPowertools.Doctor.Finding.t()]
  def run(repo, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "public")
    strict = Keyword.get(opts, :strict, false)

    []
    |> Kernel.++(Checks.index_validity(repo, prefix))
    |> Kernel.++(Checks.missing_indexes(repo, prefix))
    |> Kernel.++(Checks.oban_migration_version(repo, prefix))
    |> Kernel.++(Checks.powertools_tables(repo))
    |> Kernel.++(Checks.uniqueness_timeout_risk(repo, prefix, strict: strict))
  end
```

Append the expired deadline check here. Do not pass `strict:` to it unless the implementation deliberately ignores it; Phase 54 keeps expired deadlines as warnings.

**Exit code pattern** (lines 22-31):
```elixir
def exit_code_for(findings) do
  findings
  |> Enum.map(& &1.severity)
  |> Enum.reduce(0, fn
    :error, _acc -> 2
    :warning, acc when acc < 2 -> max(acc, 1)
    _, acc -> acc
  end)
end
```

Expired deadline findings should use `severity: :warning`, producing exit code 1 unless errors are also present.

---

### `lib/oban_powertools/doctor/checks.ex` (diagnostic service, batch + DB query)

**Analog:** `lib/oban_powertools/doctor/checks.ex`

**Imports and finding shape** (lines 1-5):
```elixir
defmodule ObanPowertools.Doctor.Checks do
  @moduledoc false

  alias ObanPowertools.Doctor.Finding
```

**Read-only query with error finding pattern** (lines 70-99):
```elixir
def index_validity(repo, prefix) do
  sql = """
  SELECT
    i.relname        AS index_name,
    ix.indisvalid    AS is_valid,
    ix.indisready    AS is_ready
  FROM pg_catalog.pg_class     c
  JOIN pg_catalog.pg_namespace n  ON n.oid = c.relnamespace
  ...
  """

  case repo.query(sql, [prefix], log: false) do
    {:ok, %{rows: rows}} ->
      findings_for_index_rows(rows, prefix)

    {:error, reason} ->
      [
        %Finding{
          check: :index_validity,
          severity: :error,
          message: "Cannot query pg_catalog (index_validity): #{inspect(reason)}",
          remediation: "Check DB connectivity and permissions."
        }
      ]
  end
end
```

Use query failures as findings; do not let Doctor crash or silently report healthy.

**Prefix-safe identifier pattern** (lines 383-449):
```elixir
defp check_eligible_job_count(repo, prefix, severity) do
  if valid_identifier?(prefix) do
    states_list = Enum.map_join(@eligible_states, ",", &"'#{&1}'")

    sql =
      "SELECT count(*) FROM #{prefix}.oban_jobs WHERE state IN (#{states_list})"

    case repo.query(sql, [], log: false) do
      {:ok, %{rows: [[count]]}} when count >= @uniqueness_backlog_threshold ->
        [%Finding{check: :uniqueness_timeout_risk, severity: severity, message: "..."}]

      {:ok, _} ->
        []

      {:error, reason} ->
        [%Finding{check: :uniqueness_timeout_risk, severity: :error, message: "... #{inspect(reason)}"}]
    end
  else
    [%Finding{check: :uniqueness_timeout_risk, severity: :error, message: "..."}]
  end
end

defp valid_identifier?(prefix) when is_binary(prefix) do
  Regex.match?(~r/^[a-z_][a-z0-9_]*$/, prefix)
end
```

Reuse this for `expired_deadline_jobs/2` because `FROM #{prefix}.oban_jobs` requires identifier validation. Bind values like `"retryable"` and `"__deadline_at__"` as parameters where possible.

---

### `lib/oban_powertools/doctor/formatter.ex` (formatter, transform)

**Analog:** `lib/oban_powertools/doctor/formatter.ex`

**Human severity grouping** (lines 81-121):
```elixir
defp human(findings, _opts) do
  errors = Enum.filter(findings, &(&1.severity == :error))
  warnings = Enum.filter(findings, &(&1.severity == :warning))

  header = colorize("Oban Powertools Doctor", IO.ANSI.bright())

  status =
    cond do
      errors != [] -> "Status: #{length(errors)} error(s), #{length(warnings)} warning(s)"
      warnings != [] -> "Status: #{length(warnings)} warning(s)"
      true -> "Status: OK"
    end
```

No new formatter branch should be needed if the expired deadline check emits a normal `%Finding{}`.

**JSON schema pattern** (lines 154-184):
```elixir
payload = %{
  schema_version: 1,
  prefix: prefix,
  oban_version_installed: oban_version_installed,
  oban_version_db: oban_version_db,
  exit_code: exit_code,
  findings: Enum.map(findings, &finding_to_map/1)
}

%{
  check: to_string(check),
  severity: to_string(severity),
  message: message,
  remediation: remediation
}
```

Keep `schema_version: 1`. The new check should appear as another finding with `check: "expired_deadline_jobs"`.

---

### `lib/mix/tasks/oban_powertools.doctor.ex` (CLI task, request-response)

**Analog:** `lib/mix/tasks/oban_powertools.doctor.ex`

**CLI docs and strict scope pattern** (lines 10-41):
```elixir
| 1    | Warnings only (e.g. uniqueness-timeout risk without `--strict`) |

--strict              Promote the warning tier (uniqueness-timeout risk) to
                      errors. Scope: uniqueness_timeout_risk check only.

| Finding                              | Default   | Under --strict |
| Uniqueness-timeout risk              | warning(1)| error (2)      |
```

Add expired deadline warning to the severity table as warning under both default and strict modes.

**Repo-only boot pattern** (lines 67-125):
```elixir
Mix.Task.run("app.config")

{opts, _args, _invalid} = OptionParser.parse(argv, strict: @switches)

result =
  Ecto.Migrator.with_repo(
    repo_module,
    fn repo ->
      prefix = resolve_prefix(opts)
      strict = Keyword.get(opts, :strict, false)

      findings = ObanPowertools.Doctor.run(repo, prefix: prefix, strict: strict)
      exit_code = ObanPowertools.Doctor.exit_code_for(findings)
      ObanPowertools.Doctor.Formatter.print(findings, ...)
      exit_code
    end,
    pool_size: 2
  )
```

Do not start Oban or queues for the new check.

---

### `test/oban_powertools/worker_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/worker_test.exs`

**Nested worker module pattern** (lines 5-18, 34-73):
```elixir
defmodule BasicWorker do
  use ObanPowertools.Worker,
    queue: :default,
    args: [
      user_id: :integer,
      email: :string
    ]

  @impl true
  def process(%Oban.Job{args: %__MODULE__.Args{user_id: user_id}}) do
    send(self(), {:processed, user_id})
    :ok
  end
end
```

Add dedicated nested workers for `timeout:` defaults, timeout override, and deadline hook-order assertions.

**Compile-time validation assertion** (lines 141-151, 362-379):
```elixir
assert_raise ArgumentError, ~r/expected :args/, fn ->
  Code.compile_string("""
  defmodule InvalidWorker do
    use ObanPowertools.Worker, args: ["user_id"]

    @impl true
    def process(_job), do: :ok
  end
  """)
end
```

Copy for invalid `timeout:` and `deadline:` values.

**Ordering / non-dispatch assertion** (lines 179-199, 255-273):
```elixir
assert {:error, %Ecto.Changeset{}} = HookedGeneratedWorker.perform(job)
refute_receive {:generated_hook, _, _}

assert {:cancel, :stop} =
         HookedGeneratedWorker.perform(worker_job(%{user_id: 123, mode: "cancel"}))

assert_receive {:generated_hook, :on_start, 123}
assert_receive {:generated_hook, :process, 123}
refute_receive {:generated_hook, :on_failure, _}
refute_receive {:generated_hook, :on_discard, _}
refute_receive {:generated_hook, :on_success, _}
```

For expired deadlines, assert `{:cancel, :deadline_expired}` and `refute_receive` for `on_start`, `process`, and post hooks.

---

### `test/oban_powertools/idempotency_test.exs` (test, CRUD)

**Analog:** `test/oban_powertools/idempotency_test.exs`

**DataCase and worker pattern** (lines 1-9):
```elixir
defmodule ObanPowertools.IdempotencyTest do
  use ObanPowertools.DataCase, async: false
  alias ObanPowertools.Idempotency

  defmodule MockWorker do
    use ObanPowertools.Worker, args: [id: :integer]
    @impl true
    def process(_), do: :ok
  end
```

Add a `deadline:` worker in this style and assert inserted `job.meta["__deadline_at__"]`.

**Conflict/fingerprint pattern** (lines 20-35):
```elixir
test "enqueue/2 returns conflict on duplicate" do
  assert {:ok, job1} = MockWorker.enqueue(%{id: 456})
  assert {:conflict, job2} = MockWorker.enqueue(%{id: 456})

  assert job1.id == job2.id
end

test "fingerprints are stable across map key ordering" do
  assert {:ok, job1} = MockWorker.enqueue(%{id: 789})
  assert {:conflict, job2} = Idempotency.transaction(MockWorker, %{id: 789})

  assert job1.id == job2.id
end
```

Use duplicate enqueue assertions to prove advancing deadline timestamps do not perturb duplicate detection.

---

### `test/oban_powertools/doctor/checks_test.exs` (test, batch + DB query)

**Analog:** `test/oban_powertools/doctor/checks_test.exs`

**DB test setup and direct SQL helper** (lines 1-18):
```elixir
defmodule ObanPowertools.Doctor.ChecksTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Doctor.Checks
  alias ObanPowertools.TestRepo

  defp direct_postgrex_query!(sql) do
    db_config =
      Application.get_env(:oban_powertools, ObanPowertools.TestRepo)
      |> Keyword.delete(:pool)
      |> Keyword.put(:pool_size, 1)
```

Use `DataCase` and `TestRepo` for inserting retryable jobs with deadline meta. Use direct Postgrex only if schema/index cleanup must escape the sandbox.

**Severity assertion pattern** (lines 117-155):
```elixir
describe "uniqueness_timeout_risk/3" do
  test "returns [] when GIN indexes are present and job count is below threshold" do
    result = Checks.uniqueness_timeout_risk(TestRepo, "public", [])
    assert result == []
  end

  test "with strict: false (default), a risk finding from missing GIN index has :warning severity" do
    result = Checks.uniqueness_timeout_risk(TestRepo, "public", strict: false)
    assert Enum.any?(result, fn f -> f.severity == :warning end)
  end
end
```

Copy for expired retryable, non-expired retryable, malformed meta, prefix handling, and strict not changing severity.

---

### `test/oban_powertools/doctor/formatter_test.exs` (test, transform)

**Analog:** `test/oban_powertools/doctor/formatter_test.exs`

**Finding fixture pattern** (lines 6-19):
```elixir
@warning_finding %Finding{
  check: :uniqueness_timeout_risk,
  severity: :warning,
  message: "Uniqueness-timeout risk: GIN index absent",
  remediation:
    "Run: CREATE INDEX CONCURRENTLY oban_jobs_args_index ON public.oban_jobs USING GIN (args)"
}
```

Add an `@expired_deadline_finding` fixture if formatter-specific tests need a concrete warning.

**JSON schema stability pattern** (lines 81-116):
```elixir
output = Formatter.format([@error_finding], format: :json)
{:ok, decoded} = Jason.decode(output)
[finding] = decoded["findings"]
assert finding["check"] == "index_validity"
assert finding["severity"] == "error"

assert decoded["schema_version"] == 1
assert decoded["prefix"] == "public"
assert decoded["exit_code"] == 2
```

Assert expired-deadline findings serialize through the existing schema without bumping `schema_version`.

---

### `test/mix/tasks/oban_powertools.doctor_test.exs` (test, request-response)

**Analog:** `test/mix/tasks/oban_powertools.doctor_test.exs`

**Source contract pattern** (lines 4-29):
```elixir
@task_path "lib/mix/tasks/oban_powertools.doctor.ex"

test "declares all five expected switches" do
  source = File.read!(@task_path)
  assert source =~ "repo:"
  assert source =~ "prefix:"
  assert source =~ "oban_name:"
  assert source =~ "format:"
  assert source =~ "strict:"
end
```

Use source assertions for updated CLI docs and severity table wording, especially strict scope.

**Boot safety pattern** (lines 17-39):
```elixir
test "does not use @requirements or Oban.start_link" do
  source = File.read!(@task_path)
  refute source =~ "@requirements"
  refute source =~ "Oban.start_link"
end

test "uses Ecto.Migrator.with_repo for repo-only boot" do
  source = File.read!(@task_path)
  assert source =~ "Ecto.Migrator.with_repo"
end
```

Deadline Doctor support must not alter the boot contract.

---

### `guides/workers-and-idempotency.md` (documentation, transform)

**Analog:** `guides/workers-and-idempotency.md`

**Worker option docs pattern** (lines 6-14):
```markdown
## What the wrapper adds

- typed `args:` declarations backed by an embedded schema
- `validate/1` for synchronous argument validation
- `enqueue/2` for idempotent inserts through the Powertools receipt table
- optional `limits:` declarations when the worker also needs durable rate control
- optional lifecycle hooks for observing start, success, retryable failure, and discard outcomes

The runtime still executes an `Oban.Worker`. Powertools just makes the builder contract stricter.
```

Add `timeout:` and `deadline:` bullets here, with the support-truth distinction.

**Support-boundary prose pattern** (lines 110-114):
```markdown
`{:cancel, reason}` and `{:snooze, _}` do not dispatch Phase 53 post hooks.
operator-initiated Lifeline discards do not fire worker execution hooks; they are audited
through the Lifeline repair pipeline. Oban timeout kills may bypass worker hooks because the
BEAM can terminate the job process outside the wrapper; use Oban `[:oban, :job, :exception]`
telemetry for timeout observability.
```

Extend this section: `timeout:` is an Oban per-attempt kill timer; `deadline:` is a Powertools soft pre-run cancellation and does not interrupt running work.

## Shared Patterns

### Oban Timeout Pass-Through

**Source:** `deps/oban/lib/oban/worker.ex` and `deps/oban/lib/oban/queue/executor.ex`
**Apply to:** `lib/oban_powertools/worker.ex`, worker tests, docs

```elixir
# deps/oban/lib/oban/queue/executor.ex lines 128-138
case exec.worker.timeout(exec.job) do
  timeout when is_integer(timeout) ->
    {:ok, timer} = :timer.exit_after(timeout, TimeoutError.exception({exec.worker, timeout}))
    %{exec | timer: timer}

  :infinity ->
    exec
end
```

Do not implement a custom timer. Generate or allow `timeout/1`; Oban enforces it.

### Cancellation Does Not Dispatch Post Hooks

**Source:** `lib/oban_powertools/worker/hooks.ex`
**Apply to:** deadline expired return path, worker tests, docs

```elixir
# lines 54-62
{:cancel, _reason} ->
  :ok

{:snooze, _seconds} ->
  :ok

_other ->
  :ok
```

Deadline expiry should return `{:cancel, :deadline_expired}` before `on_start/1`, so neither start nor post hooks fire.

### Doctor Finding Shape

**Source:** `lib/oban_powertools/doctor.ex`, `lib/oban_powertools/doctor/checks.ex`
**Apply to:** `Doctor.Checks`, formatter tests, CLI docs

```elixir
%Finding{
  check: :uniqueness_timeout_risk,
  severity: severity,
  message: "Missing GIN index ...",
  remediation: "Run `CREATE INDEX ...` ..."
}
```

Use `%Finding{check: :expired_deadline_jobs, severity: :warning, ...}` and let existing formatters handle output.

### Metadata Sideband Merge

**Source:** `lib/oban_powertools/idempotency.ex`
**Apply to:** deadline enqueue metadata

```elixir
Keyword.put(opts, :meta, deep_merge(meta, limits_meta))

defp deep_merge(left, right) when is_map(left) and is_map(right) do
  Map.merge(left, right, fn _key, a, b -> deep_merge(a, b) end)
end
```

Compute `__deadline_at__` at enqueue time and merge it as a top-level string key after caller meta, so Powertools reserved keys win.

### JSON Schema Stability

**Source:** `lib/oban_powertools/doctor/formatter.ex`
**Apply to:** Doctor formatter and tests

```elixir
payload = %{
  schema_version: 1,
  prefix: prefix,
  oban_version_installed: oban_version_installed,
  oban_version_db: oban_version_db,
  exit_code: exit_code,
  findings: Enum.map(findings, &finding_to_map/1)
}
```

Adding a new finding type should not change the JSON schema version.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/oban_powertools/worker/deadlines.ex` | utility | transform | No deadline helper exists. Use worker validation helper style and Doctor defensive parsing patterns. |

## Metadata

**Analog search scope:** `lib/`, `test/`, `guides/`, targeted vendored Oban source in `deps/oban/lib/oban/`.
**Files scanned:** 100+ via `rg --files`; 16 files read with line numbers.
**Project instructions:** No root `AGENTS.md` found. No project-local `.codex/skills/` or `.agents/skills/` skill rules found.
**Pattern extraction date:** 2026-06-12
