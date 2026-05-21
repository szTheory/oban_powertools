defmodule ObanPowertools.Workflow.Runtime do
  @moduledoc """
  Durable workflow runtime transitions and dependency reconciliation.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Telemetry}
  alias ObanPowertools.Workflow.{Edge, Result, Step, Workflow}

  @success_states ["completed", "ok", "success"]
  @retryable_states ["retryable", "executing", "running"]
  @terminal_failure_states ["cancelled", "discarded", "deleted", "failed", "error"]
  @runtime_principal Audit.system_principal("workflow_runtime", label: "system workflow runtime")

  def complete_step(repo, workflow_id, step_name, attrs \\ %{}) do
    status = normalize_status(Map.get(attrs, :status) || Map.get(attrs, "status") || "completed")
    payload = Map.get(attrs, :payload) || Map.get(attrs, "payload") || %{}
    summary = Map.get(attrs, :summary) || Map.get(attrs, "summary")
    now = Map.get(attrs, :recorded_at) || Map.get(attrs, "recorded_at") || DateTime.utc_now()

    step =
      repo.one!(
        from(step in Step,
          where: step.workflow_id == ^workflow_id and step.step_name == ^to_string(step_name)
        )
      )

    result_attrs = %{
      workflow_id: workflow_id,
      step_id: step.id,
      attempt: step.attempt + 1,
      status: status,
      payload: normalize_payload(payload),
      payload_bytes: payload_size(payload),
      retention: "standard",
      redacted: false,
      summary: summary,
      recorded_at: now
    }

    Multi.new()
    |> Multi.insert(:result, Result.changeset(%Result{}, result_attrs))
    |> Multi.update(:step, Step.changeset(step, %{state: status, attempt: step.attempt + 1, finished_at: now}))
    |> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow_id, now) end)
    |> Multi.run(:workflow, fn repo, _changes -> refresh_workflow(repo, workflow_id, now) end)
    |> repo.transaction()
    |> case do
      {:ok, %{step: updated_step, workflow: workflow}} ->
        Audit.record(
          "workflow.step_completed",
          %{type: :workflow_step, id: updated_step.id},
          %{"workflow_id" => workflow_id, "status" => status},
          repo: repo,
          principal: @runtime_principal
        )

        Telemetry.execute_workflow_event(:step_completed, %{count: 1}, %{status: status})
        ObanPowertools.Workflow.Signal.broadcast(ObanPowertools.Workflow.Signal.step_completed(workflow_id, step_name))
        maybe_broadcast_workflow_completed(workflow)
        {:ok, updated_step}

      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  def reconcile_workflow(repo, workflow_id, now \\ DateTime.utc_now()) do
    do_reconcile(repo, workflow_id, now, 0)
  end

  defp do_reconcile(repo, workflow_id, _now, passes) when passes >= 10 do
    {:ok, repo.all(from(step in Step, where: step.workflow_id == ^workflow_id))}
  end

  defp do_reconcile(repo, workflow_id, now, passes) do
    steps =
      repo.all(
        from(step in Step,
          where: step.workflow_id == ^workflow_id,
          order_by: [asc: step.position]
        )
      )

    edges = repo.all(from(edge in Edge, where: edge.workflow_id == ^workflow_id))
    results = repo.all(from(result in Result, where: result.workflow_id == ^workflow_id))

    by_name = Map.new(steps, &{&1.step_name, &1})
    results_by_step = Map.new(results, &{&1.step_id, &1})

    changed? =
      Enum.reduce(steps, false, fn step, acc ->
        case maybe_transition_step(repo, step, by_name, edges, results_by_step, now) do
          :unchanged -> acc
          :changed -> true
        end
      end)

    if changed?, do: do_reconcile(repo, workflow_id, now, passes + 1), else: {:ok, steps}
  end

  defp maybe_transition_step(_repo, %Step{state: state}, _by_name, _edges, _results, _now)
       when state in ["completed", "cancelled", "discarded", "deleted", "failed", "error", "retryable"] do
    :unchanged
  end

  defp maybe_transition_step(repo, %Step{} = step, by_name, edges, results_by_step, now) do
    dependencies =
      edges
      |> Enum.filter(&(&1.to_step_id == step.id))
      |> Enum.map(fn edge ->
        parent = Enum.find_value(by_name, fn {_name, candidate} -> if candidate.id == edge.from_step_id, do: candidate end)
        result = if parent, do: Map.get(results_by_step, parent.id)
        %{edge: edge, parent: parent, result: result}
      end)

    case dependency_outcome(dependencies) do
      {:available, _details} when step.state == "available" ->
        :unchanged

      {:available, _details} ->
        updated =
          repo.update!(
            Step.changeset(step, %{state: "available", blocker_codes: [], blocker_details: %{}})
          )

        Audit.record(
          "workflow.step_unblocked",
          %{type: :workflow_step, id: updated.id},
          %{"workflow_id" => updated.workflow_id},
          repo: repo,
          principal: @runtime_principal
        )

        Telemetry.execute_workflow_event(:step_unblocked, %{count: 1}, %{status: "available"})
        ObanPowertools.Workflow.Signal.broadcast(
          ObanPowertools.Workflow.Signal.step_unblocked(updated.workflow_id, updated.step_name)
        )

        :changed

      {:blocked, codes, details} ->
        attrs = %{
          state: "pending",
          blocker_codes: codes,
          blocker_details: details,
          dependency_snapshot: details
        }

        if step.state == "pending" and step.blocker_codes == codes and step.blocker_details == details do
          :unchanged
        else
          repo.update!(Step.changeset(step, attrs))
          :changed
        end

      {:cancelled, details} ->
        updated =
          repo.update!(
          Step.changeset(step, %{
            state: "cancelled",
            blocker_codes: ["cancelled_by_dependency"],
            blocker_details: details,
            dependency_snapshot: details,
            cancelled_at: now,
            finished_at: now
          })
        )

        Audit.record(
          "workflow.step_cancelled",
          %{type: :workflow_step, id: updated.id},
          %{"workflow_id" => updated.workflow_id},
          repo: repo,
          principal: @runtime_principal
        )

        Telemetry.execute_workflow_event(:cascade_cancelled, %{count: 1}, %{status: "cancelled"})
        :changed
    end
  end

  defp dependency_outcome([]), do: {:available, %{}}

  defp dependency_outcome(dependencies) do
    cancelled =
      Enum.find(dependencies, fn %{edge: edge, parent: parent} ->
        parent.state in @terminal_failure_states and edge.policy == "cancel"
      end)

    cond do
      cancelled ->
        {:cancelled, snapshot_for(dependencies)}

      Enum.any?(dependencies, fn %{parent: parent} -> parent.state in @retryable_states end) ->
        {:blocked, ["waiting_on_retryable_dependency"], snapshot_for(dependencies)}

      Enum.any?(dependencies, fn %{parent: parent} -> parent.state in ["pending", "available"] end) ->
        {:blocked, ["waiting_on_dependencies"], snapshot_for(dependencies)}

      Enum.any?(dependencies, fn %{parent: parent, result: result, edge: edge} ->
        parent.state in @success_states and is_nil(result) and edge.policy == "cancel"
      end) ->
        {:blocked, ["missing_dependency_result"], snapshot_for(dependencies)}

      true ->
        {:available, snapshot_for(dependencies)}
    end
  end

  defp snapshot_for(dependencies) do
    %{
      "dependencies" =>
        Enum.map(dependencies, fn %{edge: edge, parent: parent, result: result} ->
          %{
            "step_name" => parent.step_name,
            "state" => parent.state,
            "policy" => edge.policy,
            "result_status" => if(result, do: result.status, else: nil)
          }
        end)
    }
  end

  defp refresh_workflow(repo, workflow_id, now) do
    steps = repo.all(from(step in Step, where: step.workflow_id == ^workflow_id))

    attrs = %{
      runnable_step_count: Enum.count(steps, &(&1.state == "available")),
      completed_step_count: Enum.count(steps, &(&1.state in @success_states)),
      cancelled_step_count: Enum.count(steps, &(&1.state == "cancelled")),
      failed_step_count: Enum.count(steps, &(&1.state in ["failed", "error", "discarded", "deleted"])),
      state: workflow_state(steps),
      started_at: workflow_started_at(steps),
      finished_at: workflow_finished_at(steps, now)
    }

    workflow = repo.get!(Workflow, workflow_id)
    repo.update(Workflow.changeset(workflow, attrs))
  end

  defp workflow_state(steps) do
    cond do
      Enum.any?(steps, &(&1.state == "available")) -> "available"
      Enum.any?(steps, &(&1.state in @retryable_states)) -> "running"
      Enum.all?(steps, &(&1.state in @success_states)) -> "completed"
      Enum.all?(steps, &(&1.state in @success_states ++ @terminal_failure_states)) -> "cancelled"
      true -> "pending"
    end
  end

  defp workflow_started_at(steps) do
    case Enum.find(steps, &(&1.state in @success_states ++ @retryable_states ++ @terminal_failure_states)) do
      nil -> nil
      _step -> DateTime.utc_now()
    end
  end

  defp workflow_finished_at(steps, now) do
    if Enum.all?(steps, &(&1.state in @success_states ++ @terminal_failure_states)), do: now, else: nil
  end

  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status

  defp normalize_payload(%_{} = struct), do: struct |> Map.from_struct() |> normalize_payload()
  defp normalize_payload(map) when is_map(map), do: Map.new(map, fn {key, value} -> {to_string(key), normalize_payload(value)} end)
  defp normalize_payload(list) when is_list(list), do: Enum.map(list, &normalize_payload/1)
  defp normalize_payload(value), do: value

  defp payload_size(payload), do: payload |> normalize_payload() |> Jason.encode!() |> byte_size()

  defp maybe_broadcast_workflow_completed(%Workflow{id: workflow_id, state: state})
       when state in ["completed", "cancelled"] do
    Telemetry.execute_workflow_event(:workflow_completed, %{count: 1}, %{state: state})
    ObanPowertools.Workflow.Signal.broadcast(ObanPowertools.Workflow.Signal.workflow_completed(workflow_id))
  end

  defp maybe_broadcast_workflow_completed(_workflow), do: :ok
end
