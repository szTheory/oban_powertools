defmodule ObanPowertools.Workflow.Runtime do
  @moduledoc """
  Durable workflow runtime transitions, cancellation, awaits, signals, recovery, and callbacks.

  Semantics version `2` is the v1.2 lifecycle contract. New rows default to that
  contract, while pre-v1.2 rows remain on an explicit compatibility path until a
  v2 runtime transition writes the newer durable cause fields. Historical rows are
  never silently reinterpreted as if they were created under the v1.2 contract.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias ObanPowertools.{Audit, Callback, RuntimeConfig, Telemetry}

  alias ObanPowertools.Workflow.{
    Await,
    CommandAttempt,
    Edge,
    RecoveryAttempt,
    RecoverySession,
    Result,
    SignalRecord,
    Step,
    Workflow
  }

  @success_states ["completed", "ok", "success"]
  @retryable_states ["retryable", "executing", "running"]
  @terminal_failure_states ["cancelled", "discarded", "deleted", "failed", "error", "expired"]
  @terminal_states @success_states ++ @terminal_failure_states
  @workflow_states [
    "available",
    "pending",
    "running",
    "cancel_requested",
    "completed",
    "failed",
    "cancelled",
    "expired"
  ]
  @step_states [
    "pending",
    "available",
    "retryable",
    "executing",
    "running",
    "awaiting_signal",
    "completed",
    "ok",
    "success",
    "cancelled",
    "discarded",
    "deleted",
    "failed",
    "error",
    "expired"
  ]
  @workflow_terminal_causes [
    "completed",
    "completed_after_cancel_request",
    "step_failed",
    "operator_cancelled",
    "expired_wait"
  ]
  @step_terminal_causes [
    "completed",
    "completed_after_cancel_request",
    "cancelled",
    "operator_cancelled",
    "cancelled_by_dependency",
    "expired_wait",
    "step_failed"
  ]
  @current_semantics_version 2
  @callback_envelope_version 1
  @host_callback_events ["workflow.terminal", "workflow.recovery_completed", "batch.completed", "batch.exhausted"]
  @legacy_semantics_version 1
  @runtime_principal Audit.system_principal("workflow_runtime", label: "system workflow runtime")

  def semantics_version, do: @current_semantics_version

  def lifecycle_contract do
    %{
      current_semantics_version: @current_semantics_version,
      workflow_states: @workflow_states,
      step_states: @step_states,
      workflow_terminal_causes: @workflow_terminal_causes,
      step_terminal_causes: @step_terminal_causes,
      truth_source: "postgres_rows",
      compatibility: compatibility_policy()
    }
  end

  def compatibility_policy do
    %{
      current_version: @current_semantics_version,
      legacy_version: @legacy_semantics_version,
      legacy_mode: "compatibility_path",
      new_rows: "default_to_v2",
      historical_rows: "retain_stored_meaning_until_v2_transition",
      unsupported_behavior: "do_not_silently_reclassify_historical_rows"
    }
  end

  def semantics_profile(%Workflow{} = workflow) do
    version = semantics_version_of(workflow)

    if version < @current_semantics_version do
      %{
        version: version,
        mode: "compatibility_path",
        label: "legacy_v#{version}",
        truth_source: "stored_row_fields",
        note:
          "Historical rows keep their stored state and terminal cause fields until a semantics v2 transition rewrites durable meaning."
      }
    else
      %{
        version: version,
        mode: "current_contract",
        label: "v#{version}",
        truth_source: "stored_row_fields",
        note: "Workflow uses the v1.2 lifecycle and terminal-cause contract."
      }
    end
  end

  defp execute_command(repo, command) do
    with {:ok, normalized} <- normalize_command(command),
         {:ok, loaded} <- load_command_context(repo, normalized),
         :ok <- validate_command(loaded) do
      dispatch_command(repo, loaded)
    else
      {:error, %{status: :rejected} = rejection} ->
        reject_command(repo, Map.get(rejection, :command, command), rejection)
    end
  end

  defp normalize_command(command) do
    attrs = Map.get(command, :attrs, %{})

    {:ok,
     command
     |> Map.put(:attrs, attrs)
     |> Map.put(:requested_at, command_timestamp(command, attrs))
     |> Map.put(:source, Map.get(command, :source, "runtime"))
     |> Map.put(:actor_id, blank_to_nil(read_value(attrs, :actor_id)))
     |> Map.put(:step_name, Map.get(command, :step_name))
     |> Map.put(:workflow_id, Map.get(command, :workflow_id))}
  end

  defp load_command_context(repo, command) do
    workflow =
      case Map.get(command, :workflow_id) do
        nil -> nil
        workflow_id -> repo.get(Workflow, workflow_id)
      end

    step =
      case {workflow, Map.get(command, :step_name)} do
        {%Workflow{id: workflow_id}, step_name} when is_binary(step_name) ->
          repo.one(
            from(step in Step,
              where: step.workflow_id == ^workflow_id and step.step_name == ^step_name,
              limit: 1
            )
          )

        _ ->
          nil
      end

    {:ok, Map.merge(command, %{workflow: workflow, step: step})}
  end

  defp validate_command(%{action: action, workflow: nil} = command)
       when action in ["complete_step", "await_step", "request_cancel", "recover_step"] do
    {:error,
     rejection(command, "workflow_not_found",
       message: "workflow mutation target was not found",
       legal_next_steps: ["verify_workflow_id"]
     )}
  end

  defp validate_command(%{scope: "step", step: nil} = command) do
    {:error,
     rejection(command, "step_not_found",
       message: "workflow step mutation target was not found",
       legal_next_steps: ["verify_step_name"]
     )}
  end

  defp validate_command(%{workflow: %Workflow{} = workflow} = command)
       when workflow.semantics_version < @current_semantics_version do
    {:error,
     rejection(command, "unsupported_legacy_semantics",
       message:
         "workflow rows with semantics_version < 2 require an explicit compatibility adapter and are not mutated through the Phase 17 command core",
       legal_next_steps: ["migrate_via_compatibility_path"]
     )}
  end

  defp validate_command(%{action: "recover_step", recovery_action: action} = command)
       when action not in ["retry", "cancel"] do
    {:error,
     rejection(command, "unsupported_recovery_action",
       message: "recovery action is not supported by the workflow command core",
       legal_next_steps: ["retry", "cancel"]
     )}
  end

  defp validate_command(_command), do: :ok

  defp dispatch_command(repo, %{action: "complete_step"} = command),
    do: run_complete_step(repo, command)

  defp dispatch_command(repo, %{action: "await_step"} = command),
    do: run_await_step(repo, command)

  defp dispatch_command(repo, %{action: "deliver_signal"} = command),
    do: run_deliver_signal(repo, command)

  defp dispatch_command(repo, %{action: "request_cancel"} = command),
    do: run_request_cancel(repo, command)

  defp dispatch_command(repo, %{action: "recover_step"} = command),
    do: run_recover_step(repo, command)

  defp reject_command(repo, command, rejection) do
    _ =
      %CommandAttempt{}
      |> CommandAttempt.changeset(
        command_attempt_attrs(command, "rejected",
          reason_code: rejection.reason_code,
          reason_message: rejection.message,
          after_snapshot: %{},
          metadata: %{"legal_next_steps" => rejection.legal_next_steps}
        )
      )
      |> repo.insert()

    {:error,
     %{
       status: :rejected,
       action: command.action,
       scope: command.scope,
       reason_code: rejection.reason_code,
       message: rejection.message,
       legal_next_steps: rejection.legal_next_steps,
       requested_at: command.requested_at
     }}
  end

  defp rejection(command, reason_code, opts) do
    %{
      status: :rejected,
      command: command,
      reason_code: reason_code,
      message: Keyword.fetch!(opts, :message),
      legal_next_steps: Keyword.get(opts, :legal_next_steps, [])
    }
  end

  def complete_step(repo, workflow_id, step_name, attrs \\ %{}) do
    execute_command(repo, %{
      action: "complete_step",
      scope: "step",
      workflow_id: workflow_id,
      step_name: to_string(step_name),
      attrs: attrs,
      source: "runtime"
    })
  end

  defp run_complete_step(repo, %{attrs: attrs, workflow: workflow, step: step} = command) do
    status = normalize_status(read_value(attrs, :status, "completed"))
    payload = read_value(attrs, :payload, %{})
    summary = read_value(attrs, :summary)
    now = command.requested_at

    result_attrs = %{
      workflow_id: workflow.id,
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

    step_attrs = %{
      state: status,
      attempt: step.attempt + 1,
      blocker_codes: [],
      blocker_details: %{},
      terminal_cause: terminal_cause_for_status(status, workflow.cancel_requested_at),
      active_await_id: nil,
      awaiting_signal_name: nil,
      await_correlation_key: nil,
      await_dedupe_key: nil,
      await_deadline_at: nil,
      cancel_requested_at: step.cancel_requested_at || workflow.cancel_requested_at,
      started_at: step.started_at || now,
      finished_at: if(status in @terminal_states, do: now, else: nil),
      cancelled_at: if(status == "cancelled", do: now, else: step.cancelled_at),
      last_transition_at: now
    }

    Multi.new()
    |> Multi.insert(
      :command_attempt,
      CommandAttempt.changeset(
        %CommandAttempt{},
        command_attempt_attrs(command, "completed",
          reason_code: terminal_cause_for_status(status, workflow.cancel_requested_at),
          after_snapshot: Map.merge(step_snapshot(step), step_attrs_to_snapshot(step_attrs))
        )
      )
    )
    |> Multi.insert(:result, Result.changeset(%Result{}, result_attrs))
    |> Multi.update(:step, Step.changeset(step, step_attrs))
    |> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow.id, now) end)
    |> Multi.run(:workflow, fn repo, _changes ->
      {:ok, refresh_workflow(repo, workflow.id, now)}
    end)
    |> Multi.run(:callback, fn repo, %{workflow: updated_workflow} ->
      maybe_enqueue_terminal_callback(repo, workflow, updated_workflow, now)
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{step: updated_step, workflow: updated_workflow}} ->
        Audit.record(
          "workflow.step_completed",
          %{type: :workflow_step, id: updated_step.id},
          %{
            "workflow_id" => workflow.id,
            "status" => status,
            "terminal_cause" => updated_step.terminal_cause
          },
          repo: repo,
          principal: @runtime_principal
        )

        Telemetry.execute_workflow_event(:step_completed, %{count: 1}, %{
          outcome: status,
          terminal_cause: updated_step.terminal_cause,
          semantics_version: updated_workflow.semantics_version
        })

        emit_workflow_terminal_event(workflow, updated_workflow)
        {:ok, updated_step}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  def await_step(repo, workflow_id, step_name, attrs \\ %{}) do
    execute_command(repo, %{
      action: "await_step",
      scope: "step",
      workflow_id: workflow_id,
      step_name: to_string(step_name),
      attrs: attrs,
      source: "runtime"
    })
  end

  defp run_await_step(repo, %{attrs: attrs, workflow: workflow, step: step} = command) do
    now = command.requested_at
    signal_name = read_value!(attrs, :signal_name)
    correlation_key = to_string(read_value!(attrs, :correlation_key))
    dedupe_key = to_string(read_value(attrs, :dedupe_key, correlation_key))
    deadline_at = read_value(attrs, :deadline_at)

    Multi.new()
    |> Multi.run(:await, fn repo, _changes ->
      existing =
        repo.one(
          from(await in Await,
            where: await.step_id == ^step.id and await.status == "waiting",
            limit: 1
          )
        )

      await_attrs = %{
        workflow_id: workflow.id,
        step_id: step.id,
        signal_name: signal_name,
        correlation_key: correlation_key,
        dedupe_key: dedupe_key,
        status: "waiting",
        resolution_policy: "ignore_late",
        deadline_at: deadline_at
      }

      if existing do
        existing
        |> Await.changeset(await_attrs)
        |> repo.update()
      else
        %Await{}
        |> Await.changeset(await_attrs)
        |> repo.insert()
      end
    end)
    |> Multi.insert(
      :command_attempt,
      CommandAttempt.changeset(
        %CommandAttempt{},
        command_attempt_attrs(command, "completed",
          after_snapshot:
            Map.merge(step_snapshot(step), %{
              "state" => "awaiting_signal",
              "blocker_codes" => ["waiting_on_signal"],
              "terminal_cause" => nil
            }),
          metadata: %{
            "signal_name" => signal_name,
            "correlation_key" => correlation_key,
            "dedupe_key" => dedupe_key
          }
        )
      )
    )
    |> Multi.run(:step, fn repo, %{await: await_row} ->
      step
      |> Step.changeset(%{
        state: "awaiting_signal",
        blocker_codes: ["waiting_on_signal"],
        blocker_details: %{
          "active_await_id" => await_row.id,
          "signal_name" => await_row.signal_name,
          "correlation_key" => await_row.correlation_key,
          "deadline_at" => deadline_iso8601(await_row.deadline_at),
          "dedupe_key" => await_row.dedupe_key
        },
        active_await_id: await_row.id,
        awaiting_signal_name: signal_name,
        await_correlation_key: correlation_key,
        await_dedupe_key: dedupe_key,
        await_deadline_at: deadline_at,
        last_transition_at: now
      })
      |> repo.update()
    end)
    |> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow.id, now) end)
    |> Multi.run(:workflow, fn repo, _changes ->
      {:ok, refresh_workflow(repo, workflow.id, now)}
    end)
    |> repo.transaction()
  end

  def deliver_signal(repo, attrs) do
    execute_command(repo, %{
      action: "deliver_signal",
      scope: "signal",
      attrs: attrs,
      source: "signal_ingress"
    })
  end

  defp run_deliver_signal(repo, %{attrs: attrs} = command) do
    now = command.requested_at
    signal_name = read_value!(attrs, :signal_name)
    correlation_key = to_string(read_value!(attrs, :correlation_key))
    dedupe_key = to_string(read_value(attrs, :dedupe_key, correlation_key))
    payload = normalize_payload(read_value(attrs, :payload, %{}))

    signal_attrs =
      canonical_signal_attrs(repo, signal_name, correlation_key, dedupe_key, payload, now)

    case repo.insert(SignalRecord.changeset(%SignalRecord{}, signal_attrs), returning: true) do
      {:ok, signal_record} ->
        persist_signal_attempt(repo, command, signal_record, "completed")
        {:ok, reconcile_signal_record(repo, signal_record, now)}

      {:error, reason} ->
        existing =
          repo.get_by(SignalRecord,
            signal_name: signal_name,
            correlation_key: correlation_key,
            dedupe_key: dedupe_key
          )

        if existing do
          {attempt_status, reason_code, reason_message} =
            if existing.status == "consumed" do
              {"already_consumed", "already_consumed_signal",
               "signal dedupe key was already consumed by a workflow await"}
            else
              {"duplicate", "duplicate_signal", "signal dedupe key already exists"}
            end

          persist_signal_attempt(repo, command, existing, attempt_status,
            reason_code: reason_code,
            reason_message: reason_message
          )

          {:ok, existing}
        else
          {:error, reason}
        end
    end
  end

  def request_cancel(repo, workflow_id, attrs \\ %{}) do
    execute_command(repo, %{
      action: "request_cancel",
      scope: "workflow",
      workflow_id: workflow_id,
      attrs: attrs,
      source: command_source(attrs, "operator")
    })
  end

  defp run_request_cancel(repo, %{attrs: attrs, workflow: workflow} = command) do
    now = command.requested_at
    actor_id = read_value(attrs, :actor_id)
    reason = blank_to_nil(read_value(attrs, :reason))

    Multi.new()
    |> Multi.insert(
      :command_attempt,
      CommandAttempt.changeset(
        %CommandAttempt{},
        command_attempt_attrs(command, "completed",
          reason_code: "cancel_requested",
          reason_message: reason,
          after_snapshot: %{
            "workflow_state" => terminal_or_requested_state(workflow),
            "terminal_cause" => workflow.terminal_cause || "cancel_requested",
            "cancel_requested_at" => datetime_or_nil(workflow.cancel_requested_at || now)
          }
        )
      )
    )
    |> Multi.update(
      :workflow,
      Workflow.changeset(workflow, %{
        state: terminal_or_requested_state(workflow),
        cancel_requested_at: workflow.cancel_requested_at || now,
        terminal_cause: workflow.terminal_cause || "cancel_requested",
        last_transition_at: now
      })
    )
    |> Multi.run(:steps, fn repo, _changes ->
      repo.all(from(step in Step, where: step.workflow_id == ^workflow.id))
      |> Enum.each(fn step ->
        if step.state in [
             "pending",
             "available",
             "retryable",
             "awaiting_signal",
             "cancel_requested"
           ] do
          repo.update!(
            Step.changeset(step, %{
              state: "cancelled",
              blocker_codes: ["cancel_requested"],
              blocker_details: %{"requested_at" => DateTime.to_iso8601(now)},
              terminal_cause: "operator_cancelled",
              cancel_requested_at: workflow.cancel_requested_at || now,
              cancelled_at: now,
              finished_at: now,
              last_transition_at: now
            })
          )
        else
          repo.update!(
            Step.changeset(step, %{
              cancel_requested_at: step.cancel_requested_at || now,
              blocker_codes: Enum.uniq(["cancel_requested" | step.blocker_codes]),
              last_transition_at: now
            })
          )
        end
      end)

      {:ok, :updated}
    end)
    |> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow.id, now) end)
    |> Multi.run(:workflow_refresh, fn repo, _changes ->
      {:ok, refresh_workflow(repo, workflow.id, now)}
    end)
    |> Multi.run(:callback, fn repo, %{workflow: old_workflow, workflow_refresh: new_workflow} ->
      maybe_enqueue_terminal_callback(repo, old_workflow, new_workflow, now)
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{workflow_refresh: updated_workflow}} ->
        Audit.record(
          "workflow.cancel_requested",
          %{type: :workflow, id: workflow.id},
          %{"reason" => reason, "actor_id" => actor_id},
          repo: repo,
          principal: @runtime_principal
        )

        emit_workflow_terminal_event(workflow, updated_workflow)
        {:ok, updated_workflow}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  def recover_step(repo, workflow_id, step_name, action, attrs \\ %{}) do
    execute_command(repo, %{
      action: "recover_step",
      recovery_action: normalize_status(action),
      scope: "step",
      workflow_id: workflow_id,
      step_name: to_string(step_name),
      attrs: attrs,
      source: command_source(attrs, "operator")
    })
  end

  defp run_recover_step(
         repo,
         %{attrs: attrs, workflow: workflow, step: step, recovery_action: action} = command
       ) do
    now = command.requested_at
    reason = blank_to_nil(read_value(attrs, :reason))
    actor_id = read_value(attrs, :actor_id)

    if step.state in @success_states do
      reject_command(
        repo,
        command,
        rejection(command, "illegal_transition",
          message: "completed workflow steps cannot be recovered",
          legal_next_steps: ["inspect_step_result"]
        )
      )
    else
      before_snapshot = step_snapshot(step)
      step_attrs = recovery_step_attrs(step, action, now)

      Multi.new()
      |> Multi.insert(
        :command_attempt,
        CommandAttempt.changeset(
          %CommandAttempt{},
          command_attempt_attrs(command, "completed",
            reason_code: action,
            reason_message: reason,
            after_snapshot: Map.merge(before_snapshot, step_attrs_to_snapshot(step_attrs))
          )
        )
      )
      |> Multi.insert(
        :recovery_session,
        RecoverySession.changeset(%RecoverySession{}, %{
          workflow_id: workflow.id,
          status: "completed",
          trigger: "recover_step",
          reason: reason,
          actor_id: actor_id,
          requested_at: now,
          completed_at: now,
          metadata: %{"action" => action, "step_name" => step.step_name}
        })
      )
      |> Multi.insert(
        :recovery_attempt,
        RecoveryAttempt.changeset(%RecoveryAttempt{}, %{
          workflow_id: workflow.id,
          step_id: step.id,
          recovery_session_id: nil,
          scope: "step",
          action: action,
          status: "completed",
          reason: reason,
          actor_id: actor_id,
          requested_at: now,
          completed_at: now,
          before_snapshot: before_snapshot,
          after_snapshot: Map.merge(before_snapshot, step_attrs_to_snapshot(step_attrs)),
          metadata: %{}
        })
      )
      |> Multi.run(:recovery_attempt_linked, fn repo,
                                                %{
                                                  recovery_session: session,
                                                  recovery_attempt: attempt
                                                } ->
        attempt
        |> RecoveryAttempt.changeset(%{recovery_session_id: session.id})
        |> repo.update()
      end)
      |> Multi.update(:step, Step.changeset(step, step_attrs))
      |> Multi.run(:reconcile, fn repo, _changes -> reconcile_workflow(repo, workflow.id, now) end)
      |> Multi.run(:workflow, fn repo, _changes ->
        {:ok, refresh_workflow(repo, workflow.id, now)}
      end)
      |> Multi.run(:callback, fn repo,
                                 %{recovery_attempt_linked: attempt, recovery_session: session} ->
        enqueue_callback(repo, workflow, "workflow.recovery_completed", attempt.id, %{
          "recovery_session_id" => session.id,
          "step_id" => step.id,
          "step_name" => step.step_name,
          "action" => action,
          "reason" => reason
        })
      end)
      |> repo.transaction()
      |> case do
        {:ok, %{step: updated_step}} ->
          Audit.record(
            "workflow.recovery_completed",
            %{type: :workflow_step, id: updated_step.id},
            %{"workflow_id" => workflow.id, "action" => action},
            repo: repo,
            principal: @runtime_principal
          )

          {:ok, updated_step}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  def recover_step_by_id(repo, step_id, action, attrs \\ %{}) do
    step = repo.get!(Step, step_id)
    recover_step(repo, step.workflow_id, step.step_name, action, attrs)
  end

  def dispatch_callbacks(repo, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    limit = Keyword.get(opts, :limit, 25)
    lease_seconds = Keyword.get(opts, :lease_seconds, 30)

    handler =
      Keyword.get(opts, :handler) || RuntimeConfig.workflow_callback_handler!(required: true)

    dispatcher_id =
      Keyword.get(opts, :dispatcher_id) ||
        "runtime:#{node()}:#{System.get_env("USER") || "unknown"}"

    rows = claim_callbacks(repo, now, dispatcher_id, lease_seconds, limit)

    Enum.reduce(rows, %{delivered: 0, failed: 0}, fn row, acc ->
      case handler.handle_workflow_callback(row.payload) do
        :ok ->
          repo.update!(
            Callback.changeset(row, %{
              status: "delivered",
              attempts: row.attempts + 1,
              delivered_at: now,
              lease_expires_at: nil,
              last_error: nil
            })
          )

          %{acc | delivered: acc.delivered + 1}

        {:error, reason} ->
          repo.update!(
            Callback.changeset(row, %{
              status: "failed",
              attempts: row.attempts + 1,
              available_at: DateTime.add(now, 30, :second),
              lease_expires_at: nil,
              last_error: inspect(reason)
            })
          )

          %{acc | failed: acc.failed + 1}
      end
    end)
  end

  def reconcile_workflow(repo, workflow_id, now \\ DateTime.utc_now()) do
    do_reconcile(repo, workflow_id, now, 0)
  end

  def workflow_diagnosis(%Workflow{} = workflow, steps) do
    cond do
      workflow.state == "cancel_requested" or not is_nil(workflow.cancel_requested_at) ->
        "cancel_requested"

      workflow.state == "expired" ->
        "expired_wait"

      workflow.terminal_cause ->
        workflow.terminal_cause

      step = Enum.find(steps, &(step_diagnosis(&1) != nil)) ->
        step_diagnosis(step)

      true ->
        workflow.state
    end
  end

  def workflow_executable_actions(%Workflow{} = workflow, steps) do
    step_actions =
      steps
      |> Enum.flat_map(&step_executable_actions/1)
      |> Enum.uniq_by(& &1.id)

    step_actions ++ workflow_level_actions(workflow)
  end

  def step_executable_actions(%Step{} = step) do
    if step_terminal?(step) do
      []
    else
      []
      |> maybe_add_step_retry(step)
      |> maybe_add_step_cancel(step)
    end
  end

  def step_diagnosis(%Step{} = step) do
    cond do
      step.state == "awaiting_signal" ->
        "waiting_on_signal"

      step.state == "expired" or step.terminal_cause == "expired_wait" ->
        "expired_wait"

      "waiting_on_retryable_dependency" in step.blocker_codes ->
        "waiting_on_retryable_dependency"

      "missing_dependency_result" in step.blocker_codes ->
        "missing_dependency_result"

      "cancel_requested" in step.blocker_codes or not is_nil(step.cancel_requested_at) ->
        "cancel_requested"

      step.terminal_cause ->
        step.terminal_cause

      step.blocker_codes != [] ->
        List.first(step.blocker_codes)

      true ->
        nil
    end
  end

  defp do_reconcile(repo, workflow_id, _now, passes) when passes >= 10 do
    {:ok, repo.all(from(step in Step, where: step.workflow_id == ^workflow_id))}
  end

  defp do_reconcile(repo, workflow_id, now, passes) do
    claim_workflow_signals(repo, workflow_id)
    expire_waits(repo, workflow_id, now)
    reconcile_signals_for_workflow(repo, workflow_id, now)
    mark_late_signals_for_workflow(repo, workflow_id)

    workflow = repo.get!(Workflow, workflow_id)

    steps =
      repo.all(
        from(step in Step,
          where: step.workflow_id == ^workflow_id,
          order_by: [asc: step.position]
        )
      )

    edges = repo.all(from(edge in Edge, where: edge.workflow_id == ^workflow_id))

    results =
      repo.all(
        from(result in Result,
          where: result.workflow_id == ^workflow_id,
          order_by: [asc: result.inserted_at]
        )
      )

    by_name = Map.new(steps, &{&1.step_name, &1})

    results_by_step =
      Enum.reduce(results, %{}, fn result, acc -> Map.put(acc, result.step_id, result) end)

    changed? =
      Enum.reduce(steps, false, fn step, acc ->
        case maybe_transition_step(repo, workflow, step, by_name, edges, results_by_step, now) do
          :unchanged -> acc
          :changed -> true
        end
      end)

    if changed?, do: do_reconcile(repo, workflow_id, now, passes + 1), else: {:ok, steps}
  end

  defp maybe_transition_step(
         _repo,
         _workflow,
         %Step{state: state},
         _by_name,
         _edges,
         _results,
         _now
       )
       when state in @terminal_states do
    :unchanged
  end

  defp maybe_transition_step(
         _repo,
         _workflow,
         %Step{state: state},
         _by_name,
         _edges,
         _results,
         _now
       )
       when state in @retryable_states do
    :unchanged
  end

  defp maybe_transition_step(repo, workflow, %Step{} = step, by_name, edges, results_by_step, now) do
    active_wait =
      repo.one(
        from(await in Await,
          where: await.step_id == ^step.id and await.status == "waiting",
          order_by: [asc: await.inserted_at],
          limit: 1
        )
      )

    cond do
      not is_nil(workflow.cancel_requested_at) and
          step.state in [
            "pending",
            "available",
            "retryable",
            "awaiting_signal",
            "cancel_requested"
          ] ->
        repo.update!(
          Step.changeset(step, %{
            state: "cancelled",
            blocker_codes: ["cancel_requested"],
            blocker_details: %{
              "requested_at" => DateTime.to_iso8601(workflow.cancel_requested_at)
            },
            terminal_cause: "operator_cancelled",
            cancel_requested_at: workflow.cancel_requested_at,
            cancelled_at: now,
            finished_at: now,
            last_transition_at: now
          })
        )

        :changed

      active_wait ->
        attrs = %{
          state: "awaiting_signal",
          blocker_codes: ["waiting_on_signal"],
          blocker_details: %{
            "active_await_id" => active_wait.id,
            "signal_name" => active_wait.signal_name,
            "correlation_key" => active_wait.correlation_key,
            "deadline_at" => deadline_iso8601(active_wait.deadline_at),
            "dedupe_key" => active_wait.dedupe_key
          },
          active_await_id: active_wait.id,
          awaiting_signal_name: active_wait.signal_name,
          await_correlation_key: active_wait.correlation_key,
          await_dedupe_key: active_wait.dedupe_key,
          await_deadline_at: active_wait.deadline_at,
          terminal_cause: nil,
          last_transition_at: step.last_transition_at || now
        }

        if step.state == "awaiting_signal" and step.blocker_codes == attrs.blocker_codes do
          :unchanged
        else
          repo.update!(Step.changeset(step, attrs))
          :changed
        end

      true ->
        dependencies =
          edges
          |> Enum.filter(&(&1.to_step_id == step.id))
          |> Enum.map(fn edge ->
            parent =
              Enum.find_value(by_name, fn {_name, candidate} ->
                if candidate.id == edge.from_step_id, do: candidate
              end)

            result = if parent, do: Map.get(results_by_step, parent.id)
            %{edge: edge, parent: parent, result: result}
          end)

        case dependency_outcome(dependencies) do
          {:available, _details} when step.state == "available" ->
            :unchanged

          {:available, _details} ->
            repo.update!(
              Step.changeset(step, %{
                state: "available",
                blocker_codes: [],
                blocker_details: %{},
                terminal_cause: nil,
                last_transition_at: now
              })
            )

            Audit.record(
              "workflow.step_unblocked",
              %{type: :workflow_step, id: step.id},
              %{"workflow_id" => step.workflow_id},
              repo: repo,
              principal: @runtime_principal
            )

            Telemetry.execute_workflow_event(:step_unblocked, %{count: 1}, %{
              scope: "dependency",
              state: "available",
              semantics_version: workflow.semantics_version
            })

            :changed

          {:blocked, codes, details} ->
            if step.state == "pending" and step.blocker_codes == codes and
                 step.blocker_details == details do
              :unchanged
            else
              repo.update!(
                Step.changeset(step, %{
                  state: "pending",
                  blocker_codes: codes,
                  blocker_details: details,
                  dependency_snapshot: details,
                  terminal_cause: nil,
                  last_transition_at: now
                })
              )

              :changed
            end

          {:cancelled, details} ->
            repo.update!(
              Step.changeset(step, %{
                state: "cancelled",
                blocker_codes: ["cancelled_by_dependency"],
                blocker_details: details,
                dependency_snapshot: details,
                terminal_cause: "cancelled_by_dependency",
                cancelled_at: now,
                finished_at: now,
                last_transition_at: now
              })
            )

            Telemetry.execute_workflow_event(:cascade_cancelled, %{count: 1}, %{
              scope: "dependency",
              outcome: "cancelled",
              terminal_cause: "cancelled_by_dependency",
              semantics_version: workflow.semantics_version
            })

            :changed
        end
    end
  end

  defp dependency_outcome([]), do: {:available, %{}}

  defp dependency_outcome(dependencies) do
    cancelled =
      Enum.find(dependencies, fn %{edge: edge, parent: parent} ->
        (parent && parent.state in @terminal_failure_states) and edge.policy == "cancel"
      end)

    cond do
      cancelled ->
        {:cancelled, snapshot_for(dependencies)}

      Enum.any?(dependencies, fn %{parent: parent} ->
        parent && parent.state in @retryable_states
      end) ->
        {:blocked, ["waiting_on_retryable_dependency"], snapshot_for(dependencies)}

      Enum.any?(dependencies, fn %{parent: parent} ->
        parent && parent.state in ["pending", "available", "awaiting_signal"]
      end) ->
        {:blocked, ["waiting_on_dependencies"], snapshot_for(dependencies)}

      Enum.any?(dependencies, fn %{parent: parent, result: result, edge: edge} ->
        (parent && parent.state in @success_states) and is_nil(result) and edge.policy == "cancel"
      end) ->
        {:blocked, ["missing_dependency_result"], snapshot_for(dependencies)}

      true ->
        {:available, snapshot_for(dependencies)}
    end
  end

  defp expire_waits(repo, workflow_id, now) do
    repo.all(
      from(await in Await,
        where:
          await.workflow_id == ^workflow_id and await.status == "waiting" and
            not is_nil(await.deadline_at) and await.deadline_at < ^now
      )
    )
    |> Enum.each(fn await_row ->
      repo.update!(
        Await.changeset(await_row, %{
          status: "expired",
          resolved_at: now
        })
      )

      step = repo.get!(Step, await_row.step_id)

      repo.update!(
        Step.changeset(step, %{
          state: "expired",
          blocker_codes: ["expired_wait"],
          blocker_details: %{
            "active_await_id" => await_row.id,
            "signal_name" => await_row.signal_name,
            "correlation_key" => await_row.correlation_key,
            "deadline_at" => deadline_iso8601(await_row.deadline_at),
            "dedupe_key" => await_row.dedupe_key
          },
          active_await_id: nil,
          terminal_cause: "expired_wait",
          finished_at: now,
          last_transition_at: now
        })
      )
    end)
  end

  defp reconcile_signals_for_workflow(repo, workflow_id, now) do
    repo.all(
      from(await in Await,
        where: await.workflow_id == ^workflow_id and await.status == "waiting",
        order_by: [asc: await.inserted_at]
      )
    )
    |> Enum.each(&resolve_wait_from_signal(repo, &1, now))
  end

  defp claim_workflow_signals(repo, workflow_id) do
    repo.all(
      from(await in Await,
        where: await.workflow_id == ^workflow_id and await.status == "waiting",
        order_by: [asc: await.inserted_at]
      )
    )
    |> Enum.each(fn await_row ->
      repo.all(
        from(signal in SignalRecord,
          where:
            signal.signal_name == ^await_row.signal_name and
              signal.correlation_key == ^await_row.correlation_key and
              signal.status in ^["unmatched", "ambiguous"] and is_nil(signal.workflow_id),
          order_by: [asc: signal.inserted_at]
        )
      )
      |> Enum.each(fn signal_record ->
        if signal_authority_workflow_id(
             repo,
             signal_record.signal_name,
             signal_record.correlation_key
           ) ==
             {:ok, workflow_id} do
          repo.update!(
            SignalRecord.changeset(signal_record, %{
              workflow_id: workflow_id,
              status: "recorded"
            })
          )
        end
      end)
    end)
  end

  defp resolve_wait_from_signal(repo, %Await{} = await_row, now) do
    signal_record =
      repo.one(
        from(signal in SignalRecord,
          where:
            signal.workflow_id == ^await_row.workflow_id and
              signal.signal_name == ^await_row.signal_name and
              signal.correlation_key == ^await_row.correlation_key and
              signal.status == "recorded",
          order_by: [asc: signal.inserted_at],
          limit: 1
        )
      )

    cond do
      is_nil(signal_record) ->
        :ok

      not is_nil(await_row.deadline_at) and await_row.deadline_at < now ->
        repo.update!(SignalRecord.changeset(signal_record, %{status: "late"}))

      true ->
        repo.update!(
          Await.changeset(await_row, %{
            status: "resolved",
            resolved_at: now,
            resolved_signal_id: signal_record.id
          })
        )

        repo.update!(
          SignalRecord.changeset(signal_record, %{
            status: "consumed",
            workflow_id: await_row.workflow_id,
            matched_step_id: await_row.step_id,
            await_id: await_row.id
          })
        )

        step = repo.get!(Step, await_row.step_id)

        repo.update!(
          Step.changeset(step, %{
            state: "available",
            blocker_codes: [],
            blocker_details: %{},
            active_await_id: nil,
            awaiting_signal_name: nil,
            await_correlation_key: nil,
            await_dedupe_key: nil,
            await_deadline_at: nil,
            terminal_cause: nil,
            last_transition_at: now
          })
        )
    end
  end

  defp mark_late_signals_for_workflow(repo, workflow_id) do
    expired_pairs =
      repo.all(
        from(await in Await,
          where: await.workflow_id == ^workflow_id and await.status == "expired",
          select: {await.signal_name, await.correlation_key}
        )
      )
      |> MapSet.new()

    repo.all(
      from(signal in SignalRecord,
        where: signal.workflow_id == ^workflow_id and signal.status == "recorded",
        order_by: [asc: signal.inserted_at]
      )
    )
    |> Enum.each(fn signal_record ->
      if MapSet.member?(expired_pairs, {signal_record.signal_name, signal_record.correlation_key}) do
        repo.update!(SignalRecord.changeset(signal_record, %{status: "late"}))
      end
    end)
  end

  defp refresh_workflow(repo, workflow_id, now) do
    steps = repo.all(from(step in Step, where: step.workflow_id == ^workflow_id))
    workflow = repo.get!(Workflow, workflow_id)

    state = workflow_state(steps, workflow.cancel_requested_at)

    attrs = %{
      runnable_step_count: Enum.count(steps, &(&1.state == "available")),
      completed_step_count: Enum.count(steps, &(&1.state in @success_states)),
      cancelled_step_count: Enum.count(steps, &(&1.state == "cancelled")),
      failed_step_count:
        Enum.count(steps, &(&1.state in ["failed", "error", "discarded", "deleted", "expired"])),
      state: state,
      terminal_cause: workflow_terminal_cause(steps, workflow.cancel_requested_at),
      started_at: workflow.started_at || workflow_started_at(steps, now),
      finished_at: workflow_finished_at(steps, now),
      cancelled_at:
        if(state == "cancelled", do: workflow.cancelled_at || now, else: workflow.cancelled_at),
      last_transition_at: now
    }

    repo.update!(Workflow.changeset(workflow, attrs))
  end

  defp workflow_state(steps, cancel_requested_at) do
    cond do
      not is_nil(cancel_requested_at) and Enum.any?(steps, &(&1.state in @retryable_states)) ->
        "cancel_requested"

      Enum.any?(steps, &(&1.state == "available")) ->
        "available"

      Enum.any?(steps, &(&1.state in @retryable_states)) ->
        "running"

      Enum.any?(steps, &(&1.state == "awaiting_signal")) ->
        "pending"

      Enum.all?(steps, &(&1.state in @success_states)) ->
        "completed"

      Enum.all?(steps, &(&1.state in @terminal_states)) and
          Enum.any?(steps, &(&1.state == "expired")) ->
        "expired"

      Enum.all?(steps, &(&1.state in @terminal_states)) and
          Enum.any?(steps, &(&1.state in ["failed", "error", "discarded", "deleted"])) ->
        "failed"

      Enum.all?(steps, &(&1.state in @terminal_states)) ->
        "cancelled"

      true ->
        "pending"
    end
  end

  defp workflow_terminal_cause(steps, cancel_requested_at) do
    cond do
      Enum.all?(steps, &(&1.state in @success_states)) and not is_nil(cancel_requested_at) ->
        "completed_after_cancel_request"

      Enum.any?(steps, &(&1.terminal_cause == "expired_wait" or &1.state == "expired")) ->
        "expired_wait"

      Enum.any?(steps, &(&1.state in ["failed", "error", "discarded", "deleted"])) ->
        "step_failed"

      Enum.all?(steps, &(&1.state in @terminal_states)) and not is_nil(cancel_requested_at) ->
        "operator_cancelled"

      Enum.all?(steps, &(&1.state in @success_states)) ->
        "completed"

      true ->
        nil
    end
  end

  defp workflow_started_at(steps, now) do
    if Enum.any?(
         steps,
         &(&1.state in (@success_states ++
                          @retryable_states ++ @terminal_failure_states ++ ["awaiting_signal"]))
       ),
       do: now,
       else: nil
  end

  defp workflow_finished_at(steps, now) do
    if Enum.all?(steps, &(&1.state in @terminal_states)), do: now, else: nil
  end

  defp terminal_cause_for_status(status, cancel_requested_at)
       when status in @success_states and not is_nil(cancel_requested_at),
       do: "completed_after_cancel_request"

  defp terminal_cause_for_status(status, _cancel_requested_at) when status in @success_states,
    do: "completed"

  defp terminal_cause_for_status("cancelled", _cancel_requested_at), do: "cancelled"
  defp terminal_cause_for_status("expired", _cancel_requested_at), do: "expired_wait"

  defp terminal_cause_for_status(status, _cancel_requested_at)
       when status in ["failed", "error", "discarded", "deleted"], do: "step_failed"

  defp terminal_cause_for_status(_status, _cancel_requested_at), do: nil

  defp recovery_step_attrs(step, "retry", now) do
    %{
      state: "available",
      blocker_codes: [],
      blocker_details: %{},
      terminal_cause: nil,
      active_await_id: nil,
      awaiting_signal_name: nil,
      await_correlation_key: nil,
      await_dedupe_key: nil,
      await_deadline_at: nil,
      finished_at: nil,
      cancelled_at: nil,
      last_transition_at: now,
      dependency_snapshot: step.dependency_snapshot
    }
  end

  defp recovery_step_attrs(step, "cancel", now) do
    %{
      state: "cancelled",
      blocker_codes: ["cancel_requested"],
      blocker_details: step.blocker_details,
      terminal_cause: "operator_cancelled",
      cancel_requested_at: step.cancel_requested_at || now,
      cancelled_at: now,
      finished_at: now,
      last_transition_at: now
    }
  end

  defp recovery_step_attrs(_step, action, _now),
    do: raise(ArgumentError, "unsupported recovery action: #{inspect(action)}")

  defp maybe_enqueue_terminal_callback(
         repo,
         %Workflow{} = old_workflow,
         %Workflow{} = new_workflow,
         now
       ) do
    if new_workflow.state in ["completed", "cancelled", "expired", "failed"] and
         (old_workflow.state != new_workflow.state or
            old_workflow.terminal_cause != new_workflow.terminal_cause) do
      enqueue_callback(
        repo,
        new_workflow,
        "workflow.terminal",
        "#{new_workflow.state}:#{new_workflow.terminal_cause}",
        %{
          "state" => new_workflow.state,
          "terminal_cause" => new_workflow.terminal_cause,
          "cancel_requested_at" => datetime_or_nil(new_workflow.cancel_requested_at),
          "finished_at" => datetime_or_nil(new_workflow.finished_at)
        },
        now
      )
    else
      {:ok, :noop}
    end
  end

  defp emit_workflow_terminal_event(%Workflow{} = old_workflow, %Workflow{} = new_workflow) do
    if new_workflow.state in ["completed", "cancelled", "expired", "failed"] and
         (old_workflow.state != new_workflow.state or
            old_workflow.terminal_cause != new_workflow.terminal_cause) do
      Telemetry.execute_workflow_event(:workflow_terminal, %{count: 1}, %{
        state: new_workflow.state,
        outcome: "terminal",
        terminal_cause: new_workflow.terminal_cause,
        semantics_version: new_workflow.semantics_version
      })
    end
  end

  defp enqueue_callback(repo, workflow, event, dedupe_suffix, payload, now \\ DateTime.utc_now()) do
    callback_id = Ecto.UUID.generate()

    %Callback{id: callback_id}
    |> Callback.changeset(%{
      workflow_id: workflow.id,
      event: event,
      dedupe_key: "#{workflow.id}:#{event}:#{dedupe_suffix}",
      status: "pending",
      payload:
        Map.merge(
          %{
            "callback_id" => callback_id,
            "event" => event,
            "workflow_id" => workflow.id,
            "semantics_version" => workflow.semantics_version,
            "envelope_version" => @callback_envelope_version,
            "occurred_at" => datetime_or_nil(now)
          },
          payload
        ),
      attempts: 0,
      available_at: now
    })
    |> repo.insert(
      on_conflict: :nothing,
      conflict_target: [:dedupe_key]
    )
  end

  defp terminal_or_requested_state(%Workflow{} = workflow) do
    if workflow.state in ["completed", "cancelled", "failed", "expired"],
      do: workflow.state,
      else: "cancel_requested"
  end

  defp snapshot_for(dependencies) do
    %{
      "dependencies" =>
        Enum.map(dependencies, fn %{edge: edge, parent: parent, result: result} ->
          %{
            "step_name" => parent && parent.step_name,
            "state" => parent && parent.state,
            "policy" => edge.policy,
            "result_status" => if(result, do: result.status, else: nil)
          }
        end)
    }
  end

  defp step_snapshot(nil), do: nil

  defp step_snapshot(step) do
    %{
      "step_id" => step.id,
      "step_name" => step.step_name,
      "state" => step.state,
      "blocker_codes" => step.blocker_codes,
      "terminal_cause" => step.terminal_cause
    }
  end

  defp step_attrs_to_snapshot(attrs) do
    %{
      "state" => Map.get(attrs, :state),
      "blocker_codes" => Map.get(attrs, :blocker_codes, []),
      "terminal_cause" => Map.get(attrs, :terminal_cause)
    }
  end

  defp command_attempt_attrs(command, status, opts) do
    workflow = Map.get(command, :workflow)
    step = Map.get(command, :step)
    signal_record = Keyword.get(opts, :signal_record)

    %{
      workflow_id: workflow && workflow.id,
      step_id: step && step.id,
      signal_record_id: signal_record && signal_record.id,
      scope: command.scope,
      action: command_action_name(command),
      status: status,
      reason_code: Keyword.get(opts, :reason_code),
      reason_message: Keyword.get(opts, :reason_message),
      actor_id: command.actor_id,
      source: command.source,
      requested_at: command.requested_at,
      completed_at: Keyword.get(opts, :completed_at, command.requested_at),
      before_snapshot: command_before_snapshot(command),
      after_snapshot: Keyword.get(opts, :after_snapshot, %{}),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  defp command_before_snapshot(%{scope: "signal"}), do: %{}

  defp command_before_snapshot(command) do
    %{}
    |> maybe_put("workflow", workflow_snapshot(Map.get(command, :workflow)))
    |> maybe_put("step", step_snapshot(Map.get(command, :step)))
  end

  defp workflow_snapshot(nil), do: nil

  defp workflow_snapshot(%Workflow{} = workflow) do
    %{
      "workflow_id" => workflow.id,
      "workflow_state" => workflow.state,
      "semantics_version" => workflow.semantics_version,
      "terminal_cause" => workflow.terminal_cause
    }
  end

  defp command_action_name(%{action: "recover_step", recovery_action: action}),
    do: "recover_step:#{action}"

  defp command_action_name(%{action: action}), do: action

  defp canonical_signal_attrs(repo, signal_name, correlation_key, dedupe_key, payload, now) do
    case signal_authority_workflow_id(repo, signal_name, correlation_key) do
      {:ok, workflow_id} ->
        %{
          workflow_id: workflow_id,
          signal_name: signal_name,
          correlation_key: correlation_key,
          dedupe_key: dedupe_key,
          payload: payload,
          status: "recorded",
          received_at: now
        }

      :ambiguous ->
        %{
          signal_name: signal_name,
          correlation_key: correlation_key,
          dedupe_key: dedupe_key,
          payload: payload,
          status: "ambiguous",
          received_at: now
        }

      :unmatched ->
        %{
          signal_name: signal_name,
          correlation_key: correlation_key,
          dedupe_key: dedupe_key,
          payload: payload,
          status: "unmatched",
          received_at: now
        }
    end
  end

  defp reconcile_signal_record(_repo, %SignalRecord{workflow_id: nil} = signal_record, _now),
    do: signal_record

  defp reconcile_signal_record(repo, %SignalRecord{workflow_id: workflow_id, id: signal_id}, now) do
    _ = reconcile_workflow(repo, workflow_id, now)
    repo.get!(SignalRecord, signal_id)
  end

  defp signal_authority_workflow_id(repo, signal_name, correlation_key) do
    workflow_ids =
      repo.all(
        from(await in Await,
          where:
            await.signal_name == ^signal_name and await.correlation_key == ^correlation_key and
              await.status in ^["waiting", "expired"],
          select: await.workflow_id,
          distinct: true
        )
      )

    case workflow_ids do
      [workflow_id] -> {:ok, workflow_id}
      [] -> :unmatched
      _ -> :ambiguous
    end
  end

  defp persist_signal_attempt(repo, command, signal_record, status, opts \\ []) do
    %CommandAttempt{}
    |> CommandAttempt.changeset(
      command_attempt_attrs(command, status,
        signal_record: signal_record,
        reason_code: Keyword.get(opts, :reason_code),
        reason_message: Keyword.get(opts, :reason_message),
        metadata: %{
          "signal_name" => signal_record.signal_name,
          "correlation_key" => signal_record.correlation_key,
          "dedupe_key" => signal_record.dedupe_key
        }
      )
    )
    |> repo.insert()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp deadline_iso8601(nil), do: nil
  defp deadline_iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp datetime_or_nil(nil), do: nil
  defp datetime_or_nil(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp semantics_version_of(%Workflow{semantics_version: nil}), do: @legacy_semantics_version

  defp semantics_version_of(%Workflow{semantics_version: version}) when is_integer(version),
    do: version

  defp command_timestamp(%{action: "complete_step"}, attrs),
    do: read_value(attrs, :recorded_at, DateTime.utc_now())

  defp command_timestamp(%{action: "await_step"}, attrs),
    do: read_value(attrs, :registered_at, DateTime.utc_now())

  defp command_timestamp(%{action: "deliver_signal"}, attrs),
    do: read_value(attrs, :received_at, DateTime.utc_now())

  defp command_timestamp(%{action: "request_cancel"}, attrs),
    do: read_value(attrs, :requested_at, DateTime.utc_now())

  defp command_timestamp(%{action: "recover_step"}, attrs),
    do: read_value(attrs, :requested_at, DateTime.utc_now())

  defp claim_callbacks(repo, now, dispatcher_id, lease_seconds, limit) do
    repo.transaction(fn ->
      lease_expires_at = DateTime.add(now, lease_seconds, :second)

      rows =
        repo.all(
          from(callback in Callback,
            where:
              callback.event in ^@host_callback_events and
                callback.status in ["pending", "failed", "claimed"] and
                (is_nil(callback.available_at) or callback.available_at <= ^now) and
                (is_nil(callback.lease_expires_at) or callback.lease_expires_at <= ^now),
            order_by: [asc: callback.available_at, asc: callback.inserted_at],
            limit: ^limit,
            lock: "FOR UPDATE SKIP LOCKED"
          )
        )

      Enum.map(rows, fn row ->
        {:ok, claimed} =
          row
          |> Callback.changeset(%{
            status: "claimed",
            claimed_at: now,
            claimed_by: dispatcher_id,
            lease_expires_at: lease_expires_at
          })
          |> repo.update()

        claimed
      end)
    end)
    |> case do
      {:ok, rows} -> rows
      {:error, _reason} -> []
    end
  end

  defp command_source(attrs, fallback) do
    cond do
      source = blank_to_nil(read_value(attrs, :source)) -> source
      blank_to_nil(read_value(attrs, :actor_id)) -> "operator"
      true -> fallback
    end
  end

  defp workflow_level_actions(%Workflow{} = workflow) do
    if workflow_cancel_legal?(workflow) do
      [
        %{
          id: "workflow_request_cancel",
          label: "Request cancel",
          target_type: "workflow",
          target_id: workflow.id
        }
      ]
    else
      []
    end
  end

  defp maybe_add_step_retry(actions, %Step{} = step) do
    if step_retry_legal?(step) do
      [
        %{
          id: "workflow_step_retry",
          label: "Retry step",
          target_type: "workflow_step",
          target_id: step.id,
          step_name: step.step_name
        }
        | actions
      ]
    else
      actions
    end
  end

  defp maybe_add_step_cancel(actions, %Step{} = step) do
    if step_cancel_legal?(step) do
      actions ++
        [
          %{
            id: "workflow_step_cancel",
            label: "Cancel step",
            target_type: "workflow_step",
            target_id: step.id,
            step_name: step.step_name
          }
        ]
    else
      actions
    end
  end

  defp workflow_cancel_legal?(%Workflow{} = workflow) do
    workflow.state in ["available", "pending", "running"] and
      is_nil(workflow.cancel_requested_at) and is_nil(workflow.terminal_cause)
  end

  defp step_retry_legal?(%Step{} = step) do
    diagnosis = step_diagnosis(step)

    diagnosis in [
      "waiting_on_dependencies",
      "waiting_on_retryable_dependency",
      "waiting_on_signal",
      "cancel_requested"
    ] or step.state in ["retryable", "pending", "available", "awaiting_signal"]
  end

  defp step_cancel_legal?(%Step{} = step) do
    step.state in ["pending", "available", "retryable", "executing", "running", "awaiting_signal"] and
      is_nil(step.cancelled_at)
  end

  defp step_terminal?(%Step{} = step),
    do: step.state in @terminal_states or step.state in @success_states

  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status

  defp read_value(container, key, default \\ nil)

  defp read_value(list, key, default) when is_list(list) do
    Enum.find_value(list, default, fn
      {^key, value} ->
        value

      {entry_key, value} ->
        if is_atom(entry_key) and is_binary(key) and Atom.to_string(entry_key) == key do
          value
        else
          nil
        end

      _entry ->
        nil
    end)
  end

  defp read_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, Atom.to_string(key)) -> Map.get(map, Atom.to_string(key))
      true -> default
    end
  end

  defp read_value!(map, key) do
    case read_value(map, key) do
      nil -> raise ArgumentError, "missing workflow runtime attribute #{inspect(key)}"
      value -> value
    end
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) do
    case value |> to_string() |> String.trim() do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_payload(%_{} = struct), do: struct |> Map.from_struct() |> normalize_payload()

  defp normalize_payload(map) when is_map(map),
    do: Map.new(map, fn {key, value} -> {to_string(key), normalize_payload(value)} end)

  defp normalize_payload(list) when is_list(list), do: Enum.map(list, &normalize_payload/1)
  defp normalize_payload(value), do: value

  defp payload_size(payload), do: payload |> normalize_payload() |> Jason.encode!() |> byte_size()
end
