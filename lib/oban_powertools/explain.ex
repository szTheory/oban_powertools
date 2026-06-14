defmodule ObanPowertools.Explain do
  @moduledoc """
  Structured, snapshot-aware explain contract for smart-engine blockers.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ObanPowertools.Callback
  alias ObanPowertools.Limits.{Resource, State}

  alias ObanPowertools.Workflow.{
    CommandAttempt,
    RecoverySession,
    Runtime,
    Step,
    Workflow
  }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_blocker_snapshots" do
    field(:job_id, :integer)
    field(:worker, :string)
    field(:status, :string, default: "blocked")
    field(:scope_kind, :string)
    field(:scope_id, :string)
    field(:blocker_codes, {:array, :string}, default: [])
    field(:details, :map, default: %{})
    field(:captured_at, :utc_datetime_usec)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :job_id,
      :worker,
      :status,
      :scope_kind,
      :scope_id,
      :blocker_codes,
      :details,
      :captured_at
    ])
    |> validate_required([
      :worker,
      :status,
      :scope_kind,
      :scope_id,
      :blocker_codes,
      :details,
      :captured_at
    ])
  end

  def explain(worker_mod, args, opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with {:ok, snapshot} <- ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
      live_now = live_blockers(repo, snapshot, now)

      %{
        status: if(live_now == [], do: :runnable, else: :blocked),
        blockers: live_now,
        live_now: live_now,
        snapshot_at_block_start: latest_snapshot(repo, inspect(worker_mod), snapshot)
      }
    end
  end

  def persist_snapshot(repo, limit_snapshot, blockers, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    %__MODULE__{}
    |> changeset(%{
      job_id: Keyword.get(opts, :job_id, 0),
      worker: limit_snapshot.worker,
      status: "blocked",
      scope_kind: limit_snapshot.scope_kind,
      scope_id: limit_snapshot.resource_name,
      blocker_codes: Enum.map(blockers, & &1.code) |> Enum.sort(),
      details: %{
        "partition_key" => limit_snapshot.partition_key,
        "weight" => limit_snapshot.weight,
        "live_now" => Enum.map(blockers, &normalize_blocker/1)
      },
      captured_at: now
    })
    |> repo.insert()
  end

  def explain_snapshot(%__MODULE__{} = snapshot, opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
    now = Keyword.get(opts, :now, DateTime.utc_now())

    %{
      status: snapshot.status,
      blockers: live_blockers_from_snapshot(repo, snapshot, now),
      live_now: live_blockers_from_snapshot(repo, snapshot, now),
      snapshot_at_block_start: snapshot
    }
  end

  def workflow_step(workflow_id, step_name, opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))

    step =
      repo.one!(
        from(step in Step,
          where: step.workflow_id == ^workflow_id and step.step_name == ^to_string(step_name)
        )
      )

    blockers =
      Enum.map(step.blocker_codes, fn code ->
        %{
          code: code,
          scope: %{kind: "workflow_step", id: step.step_name},
          summary: blocker_summary(code),
          retry_at: nil,
          details: step.blocker_details
        }
      end)

    %{
      status: String.to_atom(step.state),
      blockers: blockers,
      live_now: blockers,
      snapshot_at_block_start: step.dependency_snapshot
    }
  end

  def workflow_story(%Workflow{} = workflow, steps, opts \\ []) when is_list(steps) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
    latest_rejection = latest_rejection(repo, workflow.id)

    %{
      diagnosis: Runtime.workflow_diagnosis(workflow, steps),
      executable_actions: Runtime.workflow_executable_actions(workflow, steps),
      semantics: Runtime.semantics_profile(workflow),
      latest_rejection: latest_rejection,
      rejection_summary: rejection_summary(latest_rejection),
      callback_posture: callback_posture(repo, workflow.id),
      latest_recovery_session: latest_recovery_session(repo, workflow.id)
    }
  end

  def step_story(%Step{} = step, opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
    latest_rejection = latest_rejection(repo, step.workflow_id, step.id)

    %{
      diagnosis: Runtime.step_diagnosis(step),
      blocker_codes: step.blocker_codes,
      blocker_summaries: Enum.map(step.blocker_codes, &blocker_summary/1),
      executable_actions: Runtime.step_executable_actions(step),
      latest_rejection: latest_rejection,
      rejection_summary: rejection_summary(latest_rejection)
    }
  end

  def latest_rejection(repo, workflow_id, step_id \\ nil) do
    query =
      from(attempt in CommandAttempt,
        where: attempt.workflow_id == ^workflow_id and attempt.status == "rejected",
        order_by: [desc: attempt.requested_at, desc: attempt.inserted_at],
        limit: 1
      )

    query =
      if step_id do
        from(attempt in query, where: attempt.step_id == ^step_id)
      else
        query
      end

    case repo.one(query) do
      nil ->
        nil

      attempt ->
        %{
          action: attempt.action,
          reason_code: attempt.reason_code,
          message: attempt.reason_message,
          legal_next_steps: Map.get(attempt.metadata || %{}, "legal_next_steps", []),
          requested_at: attempt.requested_at,
          actor_id: attempt.actor_id,
          source: attempt.source
        }
    end
  end

  defp latest_snapshot(_repo, _worker, nil), do: nil

  defp latest_snapshot(repo, worker, snapshot) do
    repo.one(
      from(event in __MODULE__,
        where:
          event.worker == ^worker and event.scope_kind == ^snapshot.scope_kind and
            event.scope_id == ^snapshot.resource_name,
        order_by: [desc: event.captured_at],
        limit: 1
      )
    )
  end

  defp live_blockers(_repo, nil, _now), do: []

  defp live_blockers(repo, snapshot, now) do
    case repo.get_by(Resource, name: snapshot.resource_name) do
      nil ->
        []

      resource ->
        case repo.get_by(State, resource_id: resource.id, partition_key: snapshot.partition_key) do
          nil -> []
          state -> blockers_for(state, resource, snapshot, now)
        end
    end
  end

  defp live_blockers_from_snapshot(repo, snapshot, now) do
    resource_name = snapshot.scope_id
    partition_key = get_in(snapshot.details, ["partition_key"]) || "__global__"
    weight = get_in(snapshot.details, ["weight"]) || 1

    case repo.get_by(Resource, name: resource_name) do
      nil ->
        []

      resource ->
        case repo.get_by(State, resource_id: resource.id, partition_key: partition_key) do
          nil -> []
          state -> blockers_for(state, resource, %{weight: weight}, now)
        end
    end
  end

  defp blockers_for(state, resource, snapshot, now) do
    cond do
      match?(%DateTime{}, state.cooldown_until) and
          DateTime.compare(state.cooldown_until, now) == :gt ->
        [
          %{
            code: "cooldown",
            scope: %{kind: resource.scope_kind, id: resource.name},
            summary: "resource is in cooldown",
            retry_at: state.cooldown_until,
            details: %{reason: state.cooldown_reason}
          }
        ]

      state.tokens_used + snapshot.weight > resource.bucket_capacity ->
        [
          %{
            code: "limit_reached",
            scope: %{kind: resource.scope_kind, id: resource.name},
            summary: "resource bucket is saturated",
            retry_at:
              DateTime.add(state.bucket_started_at, resource.bucket_span_ms, :millisecond),
            details: %{capacity: resource.bucket_capacity, used: state.tokens_used}
          }
        ]

      true ->
        []
    end
  end

  defp normalize_blocker(blocker) do
    %{
      "code" => blocker.code,
      "summary" => blocker.summary,
      "scope" => %{"kind" => blocker.scope.kind, "id" => blocker.scope.id},
      "retry_at" => blocker.retry_at,
      "details" => blocker.details
    }
  end

  defp rejection_summary(nil), do: nil

  defp rejection_summary(rejection) do
    %{
      code: rejection.reason_code,
      message: rejection.message,
      legal_next_steps: rejection.legal_next_steps
    }
  end

  defp callback_posture(repo, workflow_id) do
    rows =
      from(callback in Callback,
        where: callback.workflow_id == ^workflow_id,
        order_by: [desc: callback.inserted_at]
      )
      |> repo.all()

    %{
      total: length(rows),
      pending: Enum.count(rows, &(&1.status == "pending")),
      claimed: Enum.count(rows, &(&1.status == "claimed")),
      failed: Enum.count(rows, &(&1.status == "failed")),
      delivered: Enum.count(rows, &(&1.status == "delivered")),
      latest_status: rows |> List.first() |> then(&(&1 && &1.status)),
      latest_error: rows |> List.first() |> then(&(&1 && &1.last_error))
    }
  end

  defp latest_recovery_session(repo, workflow_id) do
    query =
      from(session in RecoverySession,
        where: session.workflow_id == ^workflow_id,
        order_by: [desc: session.requested_at, desc: session.inserted_at],
        limit: 1
      )

    case repo.one(query) do
      nil ->
        nil

      session ->
        %{
          id: session.id,
          status: session.status,
          trigger: session.trigger,
          requested_at: session.requested_at,
          completed_at: session.completed_at
        }
    end
  end

  defp blocker_summary("waiting_on_dependencies"), do: "step is waiting on required dependencies"
  defp blocker_summary("waiting_on_signal"), do: "step is waiting on a durable signal"

  defp blocker_summary("waiting_on_retryable_dependency"),
    do: "step is waiting on retryable upstream work"

  defp blocker_summary("missing_dependency_result"),
    do: "dependency completed without a durable result"

  defp blocker_summary("cancel_requested"), do: "workflow cancellation has been requested"
  defp blocker_summary("expired_wait"), do: "step wait expired before a matching signal arrived"

  defp blocker_summary("cancelled_by_dependency"),
    do: "step was cancelled by a terminal dependency"

  defp blocker_summary(code), do: code
end
