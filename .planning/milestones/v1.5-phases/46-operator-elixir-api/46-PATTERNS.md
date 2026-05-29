# Phase 46: Operator Elixir API - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/oban_powertools/operator.ex` | context | request-response | `lib/oban_powertools/jobs.ex` | role-match |
| `lib/oban_powertools/lifeline.ex` | domain | event-driven | `lib/oban_powertools/lifeline.ex` | exact |
| `test/oban_powertools/operator_test.exs` | test | request-response | `test/oban_powertools/jobs_test.exs` | role-match |

## Pattern Assignments

### `lib/oban_powertools/operator.ex` (context, request-response)

**Analog:** `lib/oban_powertools/jobs.ex` & `lib/oban_powertools/web/jobs_live.ex`

**Context Module pattern** (`lib/oban_powertools/jobs.ex` lines 47-50):
```elixir
  # Functions take `repo` explicitly (D-02 rule)
  def list(repo, %__MODULE__{} = filter, _opts \\ []) do
```

**Bulk Iteration Pipeline** (`lib/oban_powertools/web/jobs_live.ex` lines 142-153):
```elixir
  # Iterates the list exactly as the UI does (one Lifeline call per job)
  {successes, failures} =
    Enum.reduce(socket.assigns.selected_jobs, {0, 0}, fn job_id, {succ, fail} ->
      case Lifeline.preview_repair(repo(), actor, %{incident_id: nil, action: action, target_type: "job", target_id: job_id}) do
        {:ok, preview} ->
          case Lifeline.execute_repair(repo(), actor, preview.preview_token, reason) do
            {:ok, _} -> {succ + 1, fail}
            _ -> {succ, fail + 1}
          end
        _ -> {succ, fail + 1}
      end
    end)
```
*Note*: `Operator` bulk operations should return a map `%{successes: [job_id], failures: [{job_id, error}]}` instead of just `{0, 0}` counts to fulfill the API ergonomics requirement.

**Telemetry Metdata Injection pattern** (To be applied in `do_repair` inside `Operator`):
```elixir
  # Delegate to Lifeline but append telemetry metadata explicitly
  Lifeline.preview_repair(repo, actor, attrs, Keyword.put(opts, :telemetry_metadata, %{source: "api"}))
```

---

### `lib/oban_powertools/lifeline.ex` (domain, event-driven)

**Analog:** `lib/oban_powertools/lifeline.ex` (existing)

**Existing Telemetry call to modify** (`lib/oban_powertools/lifeline.ex` lines 773-777):
```elixir
  # In apply_repair/5
  Telemetry.execute_lifeline_event(:repair_executed, %{count: 1}, %{
    action: preview.action,
    incident_class: preview.incident_class,
    target_type: preview.target_type
  })
```
*Note*: Thread the `opts[:telemetry_metadata]` through `execute_repair` -> `apply_repair` -> into the final `metadata` parameter for `Telemetry.execute_lifeline_event`.

**Options passing pattern** (`lib/oban_powertools/lifeline.ex` lines 135-136):
```elixir
  def preview_repair(repo, actor, attrs, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
```
*Note*: Read `:telemetry_metadata` from `opts` here and pass it down.

---

### `test/oban_powertools/operator_test.exs` (test, request-response)

**Analog:** `test/oban_powertools/jobs_test.exs`

**Imports and Structure pattern** (`test/oban_powertools/jobs_test.exs` lines 1-4):
```elixir
defmodule ObanPowertools.JobsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Jobs, TestRepo}
```

**Job insertion pattern for tests** (`test/oban_powertools/jobs_test.exs` lines 152-167):
```elixir
  defp insert_job!(args, opts) do
    {state, opts} = Keyword.pop(opts, :state, "available")

    job =
      args
      |> Oban.Job.new(opts)
      |> TestRepo.insert!()

    if state == "available" do
      job
    else
      job
      |> Ecto.Changeset.change(state: state)
      |> TestRepo.update!()
    end
  end
```

## Shared Patterns

### Error Handling & Authorization
**Source:** `lib/oban_powertools/lifeline.ex`
**Apply to:** `ObanPowertools.Operator` (implied by reuse)
*Note*: `Lifeline.preview_repair` already performs actor authorization internally. `Operator` handles `:ok`/`:error` tuples returned by `Lifeline`.

### Options Pattern
**Source:** Standard Context Pattern (`lib/oban_powertools/lifeline.ex` and `lib/oban_powertools/jobs.ex`)
**Apply to:** All `Operator` public functions (`retry_job`, `cancel_job`, `discard_job` and `bulk_*` equivalents) where the final argument should be `opts \\ []`.

## No Analog Found

None. All files have solid analogs for structure or logic.

## Metadata

**Analog search scope:** `lib/oban_powertools/**/*.ex`, `test/oban_powertools/**/*_test.exs`
**Files scanned:** 4
**Pattern extraction date:** 2024-05-24
