# Phase 55: Output Recording (JobRecord) - Pattern Map

**Mapped:** 2026-06-12
**Files analyzed:** 8
**Analogs found:** 5 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/job_record.ex` | schema | CRUD | `lib/oban_powertools/workflow/result.ex` | exact |
| `lib/oban_powertools/worker.ex` | macro | request-response | `lib/oban_powertools/worker.ex` | exact |
| `lib/oban_powertools/runtime_config.ex` | config | transform | `lib/oban_powertools/runtime_config.ex` | exact |
| `lib/oban_powertools/web/jobs_live.ex` | component | request-response | `lib/oban_powertools/web/jobs_live.ex` | exact |
| `lib/oban_powertools/lifeline.ex` | service | batch | `lib/oban_powertools/lifeline.ex` | exact |
| `lib/oban_powertools/jobs.ex` | context | CRUD | (none required) | none |
| `lib/mix/tasks/oban_powertools.install.ex` | migration | code-generation | (test migrations) | role-match |

## Pattern Assignments

### `lib/oban_powertools/job_record.ex` (schema, CRUD)

**Analog:** `lib/oban_powertools/workflow/result.ex`

**Schema Pattern** (lines 5-21):
```elixir
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_workflow_results" do
    field(:attempt, :integer, default: 1)
    field(:status, :string, default: "ok")
    field(:payload, :map, default: %{})
    field(:payload_bytes, :integer, default: 0)
    field(:retention, :string, default: "standard")
    field(:redacted, :boolean, default: false)
    field(:summary, :string)
    field(:recorded_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)

    belongs_to(:workflow, ObanPowertools.Workflow.Workflow, type: :binary_id)
    belongs_to(:step, ObanPowertools.Workflow.Step, type: :binary_id)

    timestamps(updated_at: false)
  end
```

**Changeset Pattern** (lines 23-45):
```elixir
  def changeset(struct, params) do
    struct
    |> cast(params, [
      :workflow_id,
      :step_id,
      :attempt,
      :status,
      :payload,
      :payload_bytes,
      :retention,
      :redacted,
      :summary,
      :recorded_at,
      :expires_at
    ])
    |> validate_required([
      :workflow_id,
      :step_id,
      :attempt,
      :status,
      :payload,
      :payload_bytes,
      :retention,
      :redacted,
      :recorded_at
    ])
    |> validate_number(:attempt, greater_than: 0)
    |> validate_number(:payload_bytes, greater_than_or_equal_to: 0)
    |> unique_constraint([:step_id, :attempt])
  end
```

### `lib/oban_powertools/worker.ex` (macro, request-response)

**Analog:** `lib/oban_powertools/worker.ex`

**Option Normalization Pattern** (lines 10-18):
```elixir
    args_config = Keyword.get(opts, :args, [])
    limits_config = Keyword.get(opts, :limits, [])
    timeout_config = Keyword.get(opts, :timeout)
    deadline_config = Keyword.get(opts, :deadline)

    oban_opts =
      opts
      |> Keyword.delete(:args)
      |> Keyword.delete(:limits)
      |> Keyword.delete(:timeout)
      |> Keyword.delete(:deadline)
```

**Core Wrapper Pattern** (lines 101-133):
```elixir
      defp __powertools_perform__(%Oban.Job{} = job) do
        if ObanPowertools.Worker.Deadlines.expired?(job.meta) do
          {:cancel, :deadline_expired}
        else
          ObanPowertools.Worker.Hooks.on_start(__MODULE__, job)

          try do
            result = process(job)
            ObanPowertools.Worker.Hooks.after_result(__MODULE__, job, result)
            result
          rescue
            error ->
              stacktrace = __STACKTRACE__

              ObanPowertools.Worker.Hooks.after_exception(
                __MODULE__,
                job,
                :error,
                error,
                stacktrace
              )

              reraise error, stacktrace
          catch
            kind, reason ->
              stacktrace = __STACKTRACE__

              ObanPowertools.Worker.Hooks.after_exception(
                __MODULE__,
                job,
                kind,
                reason,
                stacktrace
              )

              :erlang.raise(kind, reason, stacktrace)
          end
        end
      end
```
*(Recorder should be injected immediately after `result = process(job)` and before `Hooks.after_result/3`)*

### `lib/oban_powertools/runtime_config.ex` (config, transform)

**Analog:** `lib/oban_powertools/runtime_config.ex`

**DisplayPolicy Fallback Pattern** (lines 102-111):
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

### `lib/oban_powertools/web/jobs_live.ex` (component, request-response)

**Analog:** `lib/oban_powertools/web/jobs_live.ex`

**Load and Render Pattern** (lines 582-613):
```elixir
    defp load_job_detail(socket, job_id) do
      case Jobs.get(repo(), job_id) do
        nil ->
          socket
          |> assign(:job, nil)
          |> assign(:job_not_found?, true)
          |> assign(:args_display, nil)
          |> assign(:meta_display, nil)
          |> assign(:back_path, Selectors.jobs_path([]))

        %Oban.Job{} = job ->
          args_display = DisplayPolicy.render_job_field(:job_args, job.args, %{job: job})
          meta_display = DisplayPolicy.render_job_field(:job_meta, job.meta, %{job: job})

          socket
          |> assign(:job, job)
          |> assign(:job_not_found?, false)
          |> assign(:args_display, args_display)
          |> assign(:meta_display, meta_display)
          |> assign(:preview, nil)
          |> assign(:reason, "")
          |> assign(:error_message, nil)
          |> assign(:success_message, nil)
          |> assign(:back_path, back_path_from_session(socket))
          |> assign(
            :read_only?,
            not LiveAuth.authorized?(
              Map.get(socket.assigns, :current_actor),
              :retry_job,
              %{type: :job, id: to_string(job.id)}
            )
          )
      end
    end
```

### `lib/oban_powertools/lifeline.ex` (service, batch)

**Analog:** `lib/oban_powertools/lifeline.ex`

**Prune Transaction Pattern** (lines 182-192):
```elixir
        {pruned_previews, _} =
          repo.delete_all(
            from(preview in ObanPowertools.Lifeline.RepairPreview,
              where:
                not is_nil(preview.consumed_at) and
                  preview.inserted_at < ^DateTime.to_naive(preview_cutoff)
            )
          )

        {pruned_heartbeats, _} =
          repo.delete_all(
            from(heartbeat in Heartbeat, where: heartbeat.last_heartbeat_at < ^heartbeat_cutoff)
          )
```

## Shared Patterns

### Error Fallback & Rescuing
**Source:** `lib/oban_powertools/runtime_config.ex`
When applying display policy or best-effort logic, utilize `rescue` to ensure Oban's outcome isn't tainted by peripheral errors.

### Bounded Struct JSON Encoding
**Source:** `lib/oban_powertools/runtime_config.ex`
Recursively stringify maps and safely drop Elixir atoms to bypass atomic exhaustion when encoding payloads for JobRecord using `Jason.encode!`.

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/oban_powertools/jobs.ex` | context | CRUD | Only requires a simple read query for `fetch_result/1` directly through explicitly bound Ecto Repo schema. |

## Metadata

**Analog search scope:** `lib/oban_powertools/**/*.ex`
**Files scanned:** 5
**Pattern extraction date:** 2026-06-12