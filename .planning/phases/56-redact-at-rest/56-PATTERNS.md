# Phase 56: redact-at-rest - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 8 (6 modified, 1 new module, 1 guide update)
**Analogs found:** 7 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/worker.ex` | macro/config | compile-time transform | self (existing `__using__` opts pipeline) | exact |
| `lib/oban_powertools/worker/redaction.ex` | utility (NEW) | transform | `lib/oban_powertools/worker/deadlines.ex` | role-match |
| `lib/oban_powertools/idempotency.ex` | service | request-response | self (existing `merge_powertools_meta`) | exact |
| `lib/oban_powertools/cron.ex` | service | event-driven | self (`maybe_insert_job` at line 421) | exact |
| `lib/oban_powertools/runtime_config.ex` | config/policy | request-response | self (`render_job_field/3` at line 206) | exact |
| `lib/oban_powertools/web/jobs_live.ex` | LiveView | request-response | self (`load_job_detail` at line 712, recorded-output card) | exact |
| `guides/workers-and-idempotency.md` | documentation | — | `guides/workers-and-idempotency.md` §"Output recording" | exact |
| `test/oban_powertools/worker_test.exs` | test | — | `test/oban_powertools/worker_test.exs` compile-time raise tests | exact |

---

## Pattern Assignments

---

### `lib/oban_powertools/worker.ex` (macro, compile-time transform)

**Analog:** self — the existing `__using__/1` opts pipeline

**Imports/opts stripping pattern** (lines 8–26):
```elixir
defmacro __using__(opts) do
  args_config = Keyword.get(opts, :args, [])
  limits_config = Keyword.get(opts, :limits, [])
  timeout_config = Keyword.get(opts, :timeout)
  deadline_config = Keyword.get(opts, :deadline)
  record_output_config = Keyword.get(opts, :record_output, false)
  output_limit_config = Keyword.get(opts, :output_limit, 65_536)
  output_retention_config = Keyword.get(opts, :output_retention, :standard)

  oban_opts =
    opts
    |> Keyword.delete(:args)
    |> Keyword.delete(:limits)
    |> Keyword.delete(:timeout)
    |> Keyword.delete(:deadline)
    |> Keyword.delete(:record_output)
    |> Keyword.delete(:output_limit)
    |> Keyword.delete(:output_retention)
    # ADD: |> Keyword.delete(:redact)
```

**Compile-time validator chain pattern** (lines 27–38):
```elixir
  validate_args_config!(args_config)
  normalized_limits = normalize_limits_config!(limits_config, __CALLER__.module)
  normalized_timeout = normalize_timeout_config!(timeout_config, __CALLER__)
  normalized_deadline = normalize_deadline_config!(deadline_config, __CALLER__)
  # ADD after normalized_deadline:
  # validate_redact_config!(redact_config, args_config, normalized_limits)
```

**`validate_args_config!` raise pattern** (lines 276–309) — exact form to copy for `validate_redact_config!`:
```elixir
defp validate_args_config!(args_config) when is_list(args_config) do
  Enum.each(args_config, fn
    {name, type} ->
      validate_arg_field!(name, type)
    invalid_entry ->
      raise ArgumentError,
            "expected :args to be a keyword list of {field, type} entries, got: #{inspect(invalid_entry)}"
  end)
end

defp validate_args_config!(args_config) do
  raise ArgumentError,
        "expected :args to be a keyword list, got: #{inspect(args_config)}"
end
```

**`normalize_limits_config!` conditional raise pattern** (lines 337–339) — copy for D-09 partition-key guard:
```elixir
if scope == :partitioned and is_nil(partition_by) do
  raise ArgumentError, "expected partitioned :limits to declare :partition_by"
end
```

**Module attribute + generated accessor pattern** (lines 61–84):
```elixir
@powertools_limits unquote(Macro.escape(normalized_limits))
@powertools_deadline_ms unquote(normalized_deadline)
@powertools_output_recording unquote(Macro.escape(normalized_output_recording))
# ADD:
# @powertools_redact unquote(redact_config)

def __powertools_limits__, do: @powertools_limits
def __powertools_deadline_ms__, do: @powertools_deadline_ms
def __powertools_output_recording__, do: @powertools_output_recording
# ADD:
# def __powertools_redact__, do: @powertools_redact
```

**`defoverridable` wrap pattern for hook callbacks** (lines 117–124) — exact model for new `new/1,2` override:
```elixir
@powertools_defining_default_hook true
def on_start(_job), do: :ok
def on_success(_job, _event), do: :ok
def on_failure(_job, _event), do: :ok
def on_discard(_job, _event), do: :ok
@powertools_defining_default_hook false

defoverridable on_start: 1, on_success: 2, on_failure: 2, on_discard: 2
```

**`perform/1` wrap pattern using private helper** (lines 126–140) — model for `new/2` delegating to helper module:
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
  if ObanPowertools.Worker.Deadlines.expired?(job.meta) do
    {:cancel, :deadline_expired}
  else
    ObanPowertools.Worker.Hooks.on_start(__MODULE__, job)
    # ... delegation to helper module
```

**`Args` embedded schema + `validate_required` pattern** (lines 88–103) — source of the D-06 required-field exemption change:
```elixir
defmodule Args do
  use Ecto.Schema
  @primary_key false

  embedded_schema do
    unquote(fields)
  end

  def changeset(struct, params) do
    fields = unquote(Keyword.keys(args_config))

    struct
    |> cast(params, fields)
    |> validate_required(fields)   # <-- change to: validate_required(required_fields)
    # where required_fields = Keyword.keys(args_config) -- redact_config (computed at macro time)
  end
end
```

**`__powertools_record_output__` private helper delegating to module** (lines 189–209) — model for keeping quoted macro code small, all logic in external module:
```elixir
defp __powertools_record_output__(%Oban.Job{} = job, result) do
  case result do
    {:ok, payload} ->
      settings = __powertools_output_recording__()
      if settings.record_output do
        ObanPowertools.JobRecord.record(nil, __MODULE__, job, payload, Map.to_list(settings))
      end
      :ok
    _other ->
      :ok
  end
end
```

---

### `lib/oban_powertools/worker/redaction.ex` (utility, NEW)

**Analog:** `lib/oban_powertools/worker/deadlines.ex`

**Module structure pattern** (deadlines.ex lines 1–44):
```elixir
defmodule ObanPowertools.Worker.Deadlines do
  @moduledoc false

  @meta_key "__deadline_at__"

  def meta_key, do: @meta_key

  def normalize_duration!(value, _label) when is_integer(value) and value > 0, do: value
  def normalize_duration!(value, label) do
    raise ArgumentError, "expected #{label} to be a positive integer, got: #{inspect(value)}"
  end

  def build_meta(nil, _now), do: %{}
  def build_meta(duration_ms, now) when is_integer(duration_ms) and duration_ms > 0 do
    # ...
  end
end
```

Copy this exact `@moduledoc false` + public API + private helpers structure. The `Redaction` module follows the identical shape:
- `@moduledoc false`
- No struct, no schema
- Public functions: `apply/4` (no-op clause when `redact_keys == []`, work clause when non-empty)
- Private helpers: `normalize_to_atom_keys/2`, `inject_meta/2`, `deep_merge/2`

**`deep_merge/2` pattern** (idempotency.ex lines 178–182):
```elixir
defp deep_merge(left, right) when is_map(left) and is_map(right) do
  Map.merge(left, right, fn _key, a, b -> deep_merge(a, b) end)
end

defp deep_merge(_left, right), do: right
```

Duplicate this verbatim into `Redaction` as a private function. It is already the authoritative merge used by `merge_powertools_meta`; the `Redaction` module must use the same two-clause version for `inject_meta/2`.

**`function_exported?` sentinel pattern** (worker.ex lines 239–244):
```elixir
def limit_snapshot(worker_mod, args) do
  limits =
    if function_exported?(worker_mod, :__powertools_limits__, 0) do
      worker_mod.__powertools_limits__()
    else
      []
    end
```

Use `function_exported?(worker_mod, :__powertools_limits__, 0)` in `cron.ex` (not in `Redaction`) to detect whether `entry.worker` is an `ObanPowertools.Worker`.

---

### `lib/oban_powertools/idempotency.ex` (service, request-response)

**Analog:** self — `merge_powertools_meta/4` and `deep_merge/2`

**`merge_powertools_meta` full pattern** (lines 147–176) — D-04 context: `new/2` is called at line 81 with opts already containing merged powertools meta:
```elixir
defp merge_powertools_meta(opts, worker_mod, args, fingerprint) do
  meta = Keyword.get(opts, :meta, %{})
  now = Keyword.get(opts, :now, DateTime.utc_now())
  opts_for_job = Keyword.delete(opts, :now)

  limits_meta =
    case ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
      {:ok, nil} -> %{}
      {:ok, snapshot} ->
        %{"oban_powertools" => %{
            "idempotency_fingerprint" => fingerprint,
            "limits" => snapshot.binding
          }}
    end

  deadline_ms =
    if function_exported?(worker_mod, :__powertools_deadline_ms__, 0) do
      worker_mod.__powertools_deadline_ms__()
    end

  deadline_meta = ObanPowertools.Worker.Deadlines.build_meta(deadline_ms, now)
  powertools_meta = deep_merge(limits_meta, deadline_meta)
  merged_meta = deep_merge(meta, powertools_meta)

  Keyword.put(opts_for_job, :meta, merged_meta)
end
```

**Fingerprint-before-`new` ordering** (lines 42–81) — D-03 invariant proof; do NOT change this ordering:
```elixir
def transaction(worker_mod, args, opts \\ []) do
  case worker_mod.validate(args) do
    {:ok, casted_args} ->
      repo = opts[:repo] || infer_repo()
      fingerprint = generate_fingerprint(worker_mod, casted_args)   # line 46 — FIRST
      do_enqueue(repo, worker_mod, casted_args, fingerprint, opts)
    {:error, changeset} ->
      {:error, changeset}
  end
end

# ... inside do_enqueue:
  job_changeset =
    worker_mod.new(args_map, merge_powertools_meta(opts, worker_mod, args, fingerprint))
    # line 81 — new/2 fires HERE, after fingerprint already computed
```

**No change required** to `idempotency.ex` for meta injection: `transaction/3` calls `merge_powertools_meta` (builds existing meta), then calls `worker_mod.new(args_map, merged_opts)`. The `new/2` override in `worker.ex` merges `__redacted_fields__` into the `opts[:meta]` it receives, which already contains the fingerprint/limits/deadline meta. This is D-04 single-injection by construction.

---

### `lib/oban_powertools/cron.ex` (service, event-driven)

**Analog:** self — `maybe_insert_job/4` at line 421

**Current implementation to replace** (lines 421–423):
```elixir
defp maybe_insert_job(repo, entry, args, _decision) do
  repo.insert(Oban.Job.new(args, worker: entry.worker, queue: String.to_atom(entry.queue)))
end
```

**`function_exported?` pattern for Powertools detection** — copy from `worker.ex:239–244` (shown above). The sentinel is `function_exported?(worker_module, :__powertools_limits__, 0)` because `__powertools_limits__/0` is always generated for every `ObanPowertools.Worker`, even with `limits: []` (worker.ex line 82).

**Rescue/fallback degradation pattern** — copy from `idempotency.ex:123–133`:
```elixir
defp infer_repo do
  try do
    Oban.Config.node_name()
  rescue
    _ -> nil
  end
  Application.get_env(:oban_powertools, :repo)
end
```

The `rescue ArgumentError` fallback for the `String.to_existing_atom` safety path follows the same shape: wrap atom lookup in `rescue`, fall back to the plain `Oban.Job.new` path.

---

### `lib/oban_powertools/runtime_config.ex` (config/policy, request-response)

**Analog:** self — `render_job_field/3` at lines 206–215 and `job_recorded/2` at lines 149–200

**`render_job_field/3` current pattern** (lines 206–215) — D-14 extension point:
```elixir
def render_job_field(kind, value, context) do
  case apply_policy(kind, value, context) do
    nil -> {:raw_json, Jason.encode!(value || %{}, pretty: true)}
    text when is_binary(text) -> {:string, text}
    %{} = redacted_map -> {:raw_json, Jason.encode!(redacted_map, pretty: true)}
    other -> raise ArgumentError, invalid_return_message(kind, other)
  end
rescue
  _ -> {:fallback, "[redacted]"}
end
```

**`render_job_field(:job_recorded, ...)` dispatch pattern** (lines 202–204) — model for adding a `:job_args`-specific clause above the generic one:
```elixir
def render_job_field(:job_recorded, value, context) do
  job_recorded(value, context)
end

def render_job_field(kind, value, context) do   # <-- generic fallthrough
```

Add a new `def render_job_field(:job_args, value, context)` clause BEFORE the generic one. It extracts `__redacted_fields__` from `context[:job].meta`, and when non-empty, merges `%{field => "Redacted at enqueue"}` entries into the args map via `build_redacted_args_map`. When the host policy returns `nil` (default path), the overlay is applied. When the host policy returns a custom `%{}`, it is returned as-is (host responsibility — D-14 / open question 3).

**`read_key/2` atom-or-string pattern** (lines 337–345) — use this for extracting `__redacted_fields__` from context safely:
```elixir
defp read_key(map, key) when is_map(map) do
  if Map.has_key?(map, key) do
    Map.get(map, key)
  else
    Map.get(map, Atom.to_string(key))
  end
end

defp read_key(_value, _key), do: nil
```

**`rescue` fallback is load-bearing** — the existing `rescue _ -> {:fallback, "[redacted]"}` on `render_job_field/3` must be preserved on the new `:job_args` clause. This is the D-14 bounded fallback contract. Do not remove it.

**Context access pattern for `job.meta`** — already established at jobs_live.ex line 724:
```elixir
args_display = DisplayPolicy.render_job_field(:job_args, job.args, %{job: job})
```
The `context` map always has `%{job: %Oban.Job{}}`. In `render_job_field(:job_args, ...)`, use:
```elixir
defp get_redacted_fields(%{job: %Oban.Job{meta: meta}}) do
  Map.get(meta || %{}, "__redacted_fields__", [])
end
defp get_redacted_fields(_), do: []
```

---

### `lib/oban_powertools/web/jobs_live.ex` (LiveView, request-response)

**Analog:** self — `load_job_detail/2` at lines 712–748, recorded-output card template at lines 391–440

**`load_job_detail/2` assign chain pattern** (lines 723–738):
```elixir
%Oban.Job{} = job ->
  args_display = DisplayPolicy.render_job_field(:job_args, job.args, %{job: job})
  meta_display = DisplayPolicy.render_job_field(:job_meta, job.meta, %{job: job})
  recorded_output = recorded_output_display(job)

  socket
  |> assign(:job, job)
  |> assign(:job_not_found?, false)
  |> assign(:args_display, args_display)
  |> assign(:meta_display, meta_display)
  |> assign(:recorded_output, recorded_output)
  |> assign(:preview, nil)
  |> assign(:reason, "")
  |> assign(:error_message, nil)
  |> assign(:success_message, nil)
  |> assign(:back_path, back_path_from_session(socket))
```

Add `|> assign(:redacted_fields, ...)` to this chain after `recorded_output`. Extract from `job.meta["__redacted_fields__"]`:
```elixir
redacted_fields = get_in(job.meta || %{}, ["__redacted_fields__"]) || []
```

Also add `|> assign(:redacted_fields, [])` to the nil branch (lines 717–721) and to `assign_defaults/1` (lines 780–791).

**Recorded-output conditional card pattern** (lines 391–440) — model for the redaction disclosure near the Meta card. The pattern for a conditional block that only renders when data is present:
```elixir
<%= if @recorded_output.available? do %>
  <div class="rounded-lg border bg-white p-4">
    <h2 class="text-base font-semibold">Recorded Output</h2>
    ...
  </div>
<% else %>
  <p class="mt-3 text-sm text-zinc-600">No recorded output found for this job.</p>
<% end %>
```

**Redaction disclosure block** — insert after the Meta card `</div>` (line 388) and before `<%!-- Recorded output panel --%>` (line 391), following the UI-SPEC D-13 "near Meta card, no new top-level card" placement:
```heex
<%= if @redacted_fields != [] do %>
  <div class="rounded-lg border bg-white p-4">
    <p class="text-xs font-semibold text-zinc-500">
      Fields redacted at enqueue:
      <%= Enum.map(@redacted_fields, &":#{&1}") |> Enum.join(", ") %>
    </p>
  </div>
<% end %>
```

Colors: `text-zinc-500` (`#71717A`) — matches the existing card label style (see `dt` elements at line 354: `class="w-36 text-zinc-500"`). No red; this is neutral disclosure per UI-SPEC.

**`redacted?` field pattern** (line 430) — existing precedent for rendering stored metadata presence vs. absence:
```elixir
<dd><%= if @recorded_output.redacted?, do: "Stored redaction metadata present", else: "None" %></dd>
```

---

### `guides/workers-and-idempotency.md` (documentation)

**Analog:** §"Output recording" (lines 148–193 in the guide)

**Feature section pattern** to copy — each optional feature follows this structure:
1. One-line description of what the option does
2. Code block showing declaration in `use ObanPowertools.Worker`
3. Bulleted boundary notes: what it does, what it does NOT do, caveats

**Existing output recording section opener** (guide line 148–170):
```markdown
## Output recording

Workers may opt in to recording successful output with `record_output: true`:

```elixir
defmodule MyApp.Billing.ProcessInvoiceWorker do
  use ObanPowertools.Worker,
    queue: :billing,
    args: [account_id: :integer, amount_cents: :integer],
    record_output: true,
    output_limit: 65_536,
    output_retention: :standard
  ...
end
```

New `## At-rest argument redaction` section follows this exact pattern. D-11 copy requirement: include the sentence "`redact:` removes fields from args at enqueue; it does NOT scrub recorded outputs. Workers must not return redacted/sensitive data from `process/1`."

---

### `test/oban_powertools/worker_test.exs` (test)

**Analog:** self — compile-time raise tests at lines 260–271 and worker definition patterns at lines 24–100

**Compile-time raise test pattern** (lines 260–271):
```elixir
test "invalid args definitions fail at compile time" do
  assert_raise ArgumentError, ~r/expected :args/, fn ->
    defmodule InvalidWorker do
      use ObanPowertools.Worker, args: ["user_id"]
    end
  end
end
```

D-07 typo guard and D-09 partition-key guard tests follow this exact shape:
```elixir
test "redact: with undeclared field raises at compile time" do
  assert_raise ArgumentError, ~r/redact: key :typo_field is not declared/, fn ->
    defmodule TyPoRedactWorker do
      use ObanPowertools.Worker,
        args: [user_id: :integer],
        redact: [:typo_field]
    end
  end
end

test "redact: overlapping partition_by raises at compile time" do
  assert_raise ArgumentError, ~r/partition key/, fn ->
    defmodule PartitionRedactWorker do
      use ObanPowertools.Worker,
        args: [user_id: :integer],
        limits: [name: "r", scope: :partitioned, partition_by: {:args, :user_id},
                 bucket_capacity: 10, bucket_span_ms: 60_000],
        redact: [:user_id]
    end
  end
end
```

**Worker definition pattern** (lines 24–37) — model for defining in-test worker modules for integration tests:
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

**`setup` / Sandbox checkout pattern** (lines 7–22) — required for integration tests that touch the DB:
```elixir
setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)

  original_repo = Application.get_env(:oban_powertools, :repo)
  Application.put_env(:oban_powertools, :repo, TestRepo)

  on_exit(fn ->
    if is_nil(original_repo) do
      Application.delete_env(:oban_powertools, :repo)
    else
      Application.put_env(:oban_powertools, :repo, original_repo)
    end
  end)

  :ok
end
```

---

### `test/oban_powertools/idempotency_test.exs` (test)

**Analog:** self — existing deadline meta tests at lines 52–79

**Deadline meta preservation pattern** (lines 59–68):
```elixir
test "deadline meta preserves caller meta while reserved key wins" do
  assert {:ok, job} =
           DeadlineWorker.enqueue(%{id: 101},
             now: ~U[2026-06-12 12:00:00Z],
             meta: %{"source" => "host", "__deadline_at__" => "1999-01-01T00:00:00Z"}
           )

  assert job.meta["source"] == "host"
  assert job.meta["__deadline_at__"] == "2026-06-13T12:00:00Z"
end
```

D-02/D-17 tests follow this exact pattern — assert field is absent (key-absent, not nil) and `__redacted_fields__` is present as a sorted string list:
```elixir
test "redact: worker has field absent from stored args (key-absent, not nil)" do
  assert {:ok, job} = RedactWorker.enqueue(%{ssn: "123", user_id: 1})
  refute Map.has_key?(job.args, "ssn")
  refute Map.has_key?(job.args, :ssn)
  assert job.meta["__redacted_fields__"] == ["ssn"]
end

test "__redacted_fields__ is not clobbered by fingerprint meta" do
  assert {:ok, job} = RedactWorker.enqueue(%{ssn: "123", user_id: 1})
  assert is_list(job.meta["__redacted_fields__"])   # flat list, not list-of-lists
  assert is_binary(get_in(job.meta, ["oban_powertools", "idempotency_fingerprint"]))
end
```

---

### `test/oban_powertools/web/live/jobs_live_test.exs` (test)

**Analog:** self — "Detail page" describe block at lines 283–691, display policy module definitions at lines 1–47

**Display policy module pattern** (lines 1–47) — for redaction tests, add a new top-level policy module:
```elixir
defmodule ObanPowertools.Web.JobsLiveRedactedMetaPolicy do
  # Returns nil → Powertools default rendering fires, shows "Redacted at enqueue"
  def display(:job_args, _value, _context), do: nil
  def display(:job_meta, _value, _context), do: nil
  def display(_kind, _value, _context), do: nil
end
```

**Detail page `insert_job!` with meta pattern** (lines 323–341) — for redaction disclosure test, insert a job with `meta: %{"__redacted_fields__" => ["ssn"]}`:
```elixir
job =
  insert_job!(
    worker: "MyApp.Worker",
    queue: :default,
    args: %{"id" => 42, "action" => "ingest"}
  )
```

**LiveView test assertion pattern** (lines 335–341):
```elixir
{:ok, _view, html} = live(conn, "/ops/jobs/jobs/#{job.id}")
assert html =~ "&quot;id&quot;" or html =~ "\"id\""
assert html =~ "<pre"
```

REDACT-03 test asserts `html =~ "Fields redacted at enqueue"` and `html =~ ":ssn"`. REDACT-04 test asserts `html =~ "Redacted at enqueue"` in the args panel.

---

## Shared Patterns

### Compile-time `raise ArgumentError` Guard Style
**Source:** `lib/oban_powertools/worker.ex` lines 276–309, 337–339
**Apply to:** `validate_redact_config!` (new private function in `worker.ex`)
```elixir
defp normalize_limits_config!(limits_config, _module) do
  raise ArgumentError,
        "expected :limits to be a keyword list, got: #{inspect(limits_config)}"
end
# ...
if scope == :partitioned and is_nil(partition_by) do
  raise ArgumentError, "expected partitioned :limits to declare :partition_by"
end
```
The redact guards must use the same `raise ArgumentError, "..."` form. No custom exception types. Message starts with the opt name (`:redact:`).

### `@moduledoc false` Internal Helper Module Style
**Source:** `lib/oban_powertools/worker/deadlines.ex` line 3; `lib/oban_powertools/worker/hooks.ex` line 2
**Apply to:** `lib/oban_powertools/worker/redaction.ex`
```elixir
defmodule ObanPowertools.Worker.Deadlines do
  @moduledoc false
  # No struct, no schema, pure functions
```
`Redaction` follows the same `@moduledoc false` pattern — it is an internal implementation module, not public API.

### `deep_merge/2` Two-Clause Pattern
**Source:** `lib/oban_powertools/idempotency.ex` lines 178–182
**Apply to:** `lib/oban_powertools/worker/redaction.ex` (private copy) and any site that merges `__redacted_fields__` into existing meta
```elixir
defp deep_merge(left, right) when is_map(left) and is_map(right) do
  Map.merge(left, right, fn _key, a, b -> deep_merge(a, b) end)
end
defp deep_merge(_left, right), do: right
```

### `render_job_field/3` Tagged Return Shape + `rescue` Fallback
**Source:** `lib/oban_powertools/runtime_config.ex` lines 206–215
**Apply to:** new `:job_args` clause of `render_job_field/3`
```elixir
{:raw_json, json_string}   # pretty-printed JSON
{:string, text}            # host policy returned binary
{:fallback, "[redacted]"}  # rescue path — never expose raw data
```
The `rescue _ -> {:fallback, "[redacted]"}` must be preserved on the new clause. UI-SPEC: `[redacted]` remains the bounded fallback; do not change this string.

### LiveView `assign` Chain + `assign_defaults` Coverage
**Source:** `lib/oban_powertools/web/jobs_live.ex` lines 780–791
**Apply to:** every new assign added in `load_job_detail/2` must also appear in `assign_defaults/1`
```elixir
defp assign_defaults(socket) do
  socket
  |> assign(:jobs, [])
  |> assign(:filter, %Jobs{})
  |> assign(:job, nil)
  |> assign(:job_not_found?, false)
  |> assign(:args_display, nil)
  |> assign(:meta_display, nil)
  # ADD: |> assign(:redacted_fields, [])
```

### `test/oban_powertools/data_case.ex` + `use ObanPowertools.DataCase` Pattern
**Source:** `test/oban_powertools/idempotency_test.exs` line 2
**Apply to:** `test/oban_powertools/cron_test.exs` redaction additions — they are already `use ObanPowertools.DataCase, async: false` (cron_test.exs line 1), no change needed.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/oban_powertools/worker/redaction.ex` | utility | transform | No prior Powertools module performs Map key normalization + meta injection at the `new/2` boundary; `deadlines.ex` is the closest structural analog but does not handle key normalization |

---

## Metadata

**Analog search scope:** `lib/oban_powertools/`, `lib/oban_powertools/worker/`, `lib/oban_powertools/web/`, `test/oban_powertools/`, `test/oban_powertools/web/live/`, `guides/`
**Files scanned:** 14 source + 6 test files
**Pattern extraction date:** 2026-06-13
