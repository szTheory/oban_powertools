defmodule ObanPowertools.Jobs.BatchCoordinator do
  @moduledoc """
  Freezes and coordinates bounded Jobs bulk work without making a LiveView the
  owner of accepted execution.

  Frozen target membership remains server-owned. Preview capabilities stay in
  the coordinator process, while observers receive only aggregate counts and
  finite, position-keyed safe results.
  """

  alias ObanPowertools.{Auth, Lifeline, RuntimeConfig}

  @max_concurrency 4
  @target_timeout_ms 30_000
  @result_page_size 50
  @maximum_retained_results 1000
  @preview_wait_timeout_ms 30 * 60 * 1000
  @telemetry_event [:oban_powertools, :jobs, :batch]
  @task_supervisor ObanPowertools.Jobs.TaskSupervisor

  @action_contract %{
    retry: %{permission: :retry_job, lifeline: "job_retry"},
    cancel: %{permission: :cancel_job, lifeline: "job_cancel"},
    discard: %{permission: :discard_job, lifeline: "job_discard"}
  }

  defmodule Scope do
    @moduledoc """
    Stable membership and observation truth for one bounded bulk operation.
    """

    @enforce_keys [:mode, :ids, :filter_identity, :selected_count, :observed_at]
    defstruct [:mode, :ids, :filter_identity, :selected_count, :observed_at]
  end

  defmodule Preview do
    @moduledoc """
    Server-only per-target capabilities plus a capability-free display model.
    """

    @enforce_keys [:ready, :excluded, :action, :scope, :created_at, :display]
    defstruct [:ready, :excluded, :action, :scope, :created_at, :display]
  end

  @doc """
  Freezes one explicit list or one already-bounded all-matching ID result.

  Duplicate list members retain the first observed position. All-matching input
  must include `overflow?: false` and an exact `selected_count`.
  """
  def freeze_scope(mode, candidates, filter_identity, observed_at) do
    limit = RuntimeConfig.jobs_bulk_target_limit()

    with {:ok, ids, selected_count} <- normalize_candidates(mode, candidates, limit),
         :ok <- validate_filter_identity(filter_identity),
         :ok <- validate_observed_at(observed_at) do
      {:ok,
       %Scope{
         mode: mode,
         ids: ids,
         filter_identity: String.trim(filter_identity),
         selected_count: selected_count,
         observed_at: observed_at
       }}
    end
  end

  @doc """
  Starts a nonlinked supervised preview and returns an opaque coordinator handle.

  The preview task authorizes page, action, and every target before calling the
  real Lifeline preview by default. The completion message contains no target
  IDs or execution capabilities.
  """
  def start_preview(owner, repo, actor, action, %Scope{} = scope, opts)
      when is_pid(owner) and is_list(opts) do
    with {:ok, action} <- normalize_action(action),
         :ok <- validate_scope(scope) do
      run_ref = make_ref()
      supervisor = Keyword.get(opts, :task_supervisor, @task_supervisor)

      case Task.Supervisor.start_child(supervisor, fn ->
             run_preview(owner, run_ref, repo, actor, action, scope, opts, supervisor)
           end) do
        {:ok, pid} -> {:ok, %{run_ref: run_ref, coordinator: pid}}
        {:error, _reason} -> {:error, :supervisor_unavailable}
      end
    end
  end

  def start_preview(_owner, _repo, _actor, _action, _scope, _opts),
    do: {:error, :invalid_preview_request}

  @doc """
  Accepts execution for an existing server-owned preview coordinator.

  Returning `{:ok, run_ref}` means the nonlinked coordinator accepted the
  request. Final truth arrives through aggregate progress/completion messages.
  """
  def start_execution(owner, repo, actor, handle, reason, opts)
      when is_pid(owner) and is_list(opts) and is_map(handle) do
    with {:ok, run_ref, coordinator} <- validate_handle(handle),
         true <- Process.alive?(coordinator) do
      send(coordinator, {:execute, run_ref, owner, repo, actor, reason, opts})
      {:ok, run_ref}
    else
      false -> {:error, :preview_unavailable}
      {:error, reason} -> {:error, reason}
    end
  end

  def start_execution(_owner, _repo, _actor, _handle, _reason, _opts),
    do: {:error, :invalid_execution_request}

  @doc """
  Returns one bounded visible page from at most 1000 retained safe outcomes.
  """
  def result_page(results, requested_page) when is_list(results) do
    if length(results) > @maximum_retained_results do
      raise ArgumentError, "batch results exceed the configured safe retention bound"
    end

    Enum.each(results, &validate_safe_result!/1)

    total_count = length(results)
    total_pages = if total_count == 0, do: 0, else: div(total_count + 49, 50)
    page = normalize_page(requested_page, total_pages)
    offset = (page - 1) * @result_page_size

    %{
      results: Enum.slice(results, offset, @result_page_size),
      total_count: total_count,
      page: page,
      page_size: @result_page_size,
      total_pages: total_pages,
      previous?: page > 1,
      next?: page < total_pages
    }
  end

  def result_page(_results, _requested_page),
    do: raise(ArgumentError, "batch results must be a list")

  defp run_preview(owner, run_ref, repo, actor, action, scope, opts, supervisor) do
    started_at = System.monotonic_time()

    with :ok <- authorize_initial(actor, action, opts),
         {:ok, preview} <-
           preview_targets(repo, actor, action, scope, opts, supervisor) do
      send(owner, {:jobs_batch_complete, run_ref, preview.display})

      emit_telemetry(
        action,
        scope.mode,
        preview_result_class(preview),
        scope.selected_count,
        started_at
      )

      await_execution(run_ref, repo, preview, opts, supervisor)
    else
      {:error, safe_reason} ->
        send(owner, {:jobs_batch_failed, run_ref, safe_batch_reason(safe_reason)})

        emit_telemetry(
          action,
          scope.mode,
          :preview_failed,
          scope.selected_count,
          started_at
        )
    end
  rescue
    _error ->
      send(owner, {:jobs_batch_failed, run_ref, :preview_unavailable})

      emit_telemetry(
        action,
        scope.mode,
        :preview_failed,
        scope.selected_count,
        System.monotonic_time()
      )
  catch
    _kind, _reason ->
      send(owner, {:jobs_batch_failed, run_ref, :preview_unavailable})

      emit_telemetry(
        action,
        scope.mode,
        :preview_failed,
        scope.selected_count,
        System.monotonic_time()
      )
  end

  defp await_execution(run_ref, original_repo, preview, preview_opts, supervisor) do
    receive do
      {:execute, ^run_ref, owner, repo, actor, reason, execution_opts} ->
        repo = repo || original_repo
        opts = Keyword.merge(preview_opts, execution_opts)
        run_execution(owner, run_ref, repo, actor, preview, reason, opts, supervisor)

      {:cancel, ^run_ref} ->
        :ok
    after
      @preview_wait_timeout_ms -> :ok
    end
  end

  defp run_execution(owner, run_ref, repo, actor, preview, reason, opts, supervisor) do
    started_at = System.monotonic_time()

    cond do
      preview.ready == [] ->
        send(owner, {:jobs_batch_failed, run_ref, :nothing_ready})

      not valid_reason?(reason) ->
        send(owner, {:jobs_batch_failed, run_ref, :invalid_confirmation})

      true ->
        with :ok <- authorize_initial(actor, preview.action, opts) do
          execute_targets(
            owner,
            run_ref,
            repo,
            actor,
            preview,
            String.trim(reason),
            opts,
            supervisor,
            started_at
          )
        else
          {:error, _reason} ->
            send(owner, {:jobs_batch_failed, run_ref, :not_authorized})

            emit_telemetry(
              preview.action,
              preview.scope.mode,
              :execution_failed,
              length(preview.ready),
              started_at
            )
        end
    end
  rescue
    _error ->
      send(owner, {:jobs_batch_failed, run_ref, :execution_unavailable})

      emit_telemetry(
        preview.action,
        preview.scope.mode,
        :execution_failed,
        length(preview.ready),
        System.monotonic_time()
      )
  catch
    _kind, _reason ->
      send(owner, {:jobs_batch_failed, run_ref, :execution_unavailable})

      emit_telemetry(
        preview.action,
        preview.scope.mode,
        :execution_failed,
        length(preview.ready),
        System.monotonic_time()
      )
  end

  defp preview_targets(repo, actor, action, scope, opts, supervisor) do
    timeout = target_timeout(opts)

    results =
      Task.Supervisor.async_stream_nolink(
        supervisor,
        Enum.with_index(scope.ids),
        fn {target_id, position} ->
          preview_target(
            repo,
            actor,
            action,
            target_id,
            position,
            opts,
            supervisor,
            timeout
          )
        end,
        ordered: false,
        max_concurrency: @max_concurrency,
        timeout: timeout + 1_000,
        on_timeout: :kill_task
      )
      |> Enum.map(fn
        {:ok, result} -> result
        {:exit, _reason} -> {:excluded, nil, nil}
      end)

    if Enum.any?(results, &match?({:excluded, nil, nil}, &1)) do
      {:error, :preview_unavailable}
    else
      sorted = Enum.sort_by(results, fn {_kind, internal, _safe} -> internal.position end)

      ready =
        for {:ready, internal, _safe} <- sorted do
          internal
        end

      excluded =
        for {:excluded, internal, _safe} <- sorted do
          internal
        end

      safe_results = Enum.map(sorted, fn {_kind, _internal, safe} -> safe end)

      receipt = %{
        stage: :preview,
        action: action,
        selected: scope.selected_count,
        ready: length(ready),
        excluded: length(excluded),
        execution_available?: ready != []
      }

      {:ok,
       %Preview{
         ready: ready,
         excluded: excluded,
         action: action,
         scope: scope,
         created_at: DateTime.utc_now(),
         display: %{receipt: receipt, results: safe_results}
       }}
    end
  end

  defp preview_target(repo, actor, action, target_id, position, opts, supervisor, timeout) do
    contract = Map.fetch!(@action_contract, action)
    resource = %{type: :job, id: target_id}

    with :ok <- authorize(opts, actor, :view_job_detail, resource),
         :ok <- authorize(opts, actor, contract.permission, resource),
         :ok <- authorize(opts, actor, :preview_repair, resource) do
      attrs = %{
        action: contract.lifeline,
        target_type: "job",
        target_id: target_id
      }

      preview_fun = preview_function(opts)

      case run_target_call(
             supervisor,
             timeout,
             fn -> preview_fun.(repo, actor, attrs, []) end
           ) do
        {:ok, {:ok, preview}} ->
          token = Map.fetch!(preview, :preview_token)

          {:ready, %{position: position, target_id: target_id, preview_token: token},
           %{
             position: position,
             outcome: :ready,
             message: "Ready for execution.",
             recovery: nil
           }}

        {:ok, {:error, reason}} ->
          excluded_preview(position, target_id, reason)

        :timeout ->
          excluded_preview(position, target_id, :preview_timeout)

        {:exit, _reason} ->
          excluded_preview(position, target_id, :preview_unavailable)

        {:ok, _unexpected} ->
          excluded_preview(position, target_id, :preview_unavailable)
      end
    else
      {:error, _reason} -> excluded_preview(position, target_id, :unauthorized)
    end
  rescue
    _error -> excluded_preview(position, target_id, :preview_unavailable)
  catch
    _kind, _reason -> excluded_preview(position, target_id, :preview_unavailable)
  end

  defp excluded_preview(position, target_id, reason) do
    safe_reason = preview_reason(reason)

    {:excluded, %{position: position, target_id: target_id, reason_class: safe_reason.class},
     %{
       position: position,
       outcome: :excluded,
       message: safe_reason.message,
       recovery: safe_reason.recovery
     }}
  end

  defp execute_targets(
         owner,
         run_ref,
         repo,
         actor,
         preview,
         reason,
         opts,
         supervisor,
         started_at
       ) do
    timeout = target_timeout(opts)

    terminal_results =
      Task.Supervisor.async_stream_nolink(
        supervisor,
        preview.ready,
        fn target ->
          execute_target(repo, actor, preview.action, target, reason, opts, supervisor, timeout)
        end,
        ordered: true,
        max_concurrency: @max_concurrency,
        timeout: timeout + 1_000,
        on_timeout: :kill_task
      )
      |> then(&Enum.zip(preview.ready, &1))
      |> Enum.map(fn
        {_target, {:ok, result}} ->
          result

        {target, {:exit, _reason}} ->
          safe_execution_result(target.position, :failed, :crashed)
      end)
      |> reconcile_execution_results(preview.ready)

    {results, aggregate} =
      Enum.reduce(
        terminal_results,
        {[], empty_aggregate(length(preview.ready))},
        fn result, {results, aggregate} ->
          aggregate = increment_aggregate(aggregate, result.outcome)
          send(owner, {:jobs_batch_progress, run_ref, aggregate})
          {[result | results], aggregate}
        end
      )

    results =
      results
      |> Enum.sort_by(& &1.position)
      |> Enum.take(RuntimeConfig.jobs_bulk_target_limit())

    receipt = %{
      stage: :execution,
      action: preview.action,
      total: aggregate.total,
      success: aggregate.success,
      skipped: aggregate.skipped,
      failed: aggregate.failed,
      all_success?: aggregate.success == aggregate.total
    }

    send(owner, {:jobs_batch_complete, run_ref, %{receipt: receipt, results: results}})

    emit_telemetry(
      preview.action,
      preview.scope.mode,
      execution_result_class(aggregate),
      aggregate.total,
      started_at
    )
  end

  defp execute_target(repo, actor, action, target, reason, opts, supervisor, timeout) do
    contract = Map.fetch!(@action_contract, action)
    resource = %{type: :job, id: target.target_id}
    execute_fun = execute_function(opts)

    result =
      run_target_call(supervisor, timeout, fn ->
        with :ok <- authorize(opts, actor, :view_job_detail, resource),
             :ok <- authorize(opts, actor, contract.permission, resource),
             :ok <- authorize(opts, actor, :execute_repair, resource) do
          execute_fun.(repo, actor, target.preview_token, reason, [])
        else
          {:error, _reason} -> {:error, :unauthorized}
        end
      end)

    execution_result(target.position, result)
  rescue
    _error -> safe_execution_result(target.position, :failed, :crashed)
  catch
    _kind, _reason -> safe_execution_result(target.position, :failed, :crashed)
  end

  defp reconcile_execution_results(results, ready_targets) do
    results_by_position =
      Enum.group_by(results, fn
        %{position: position} when is_integer(position) -> position
        _invalid -> :invalid
      end)

    Enum.map(ready_targets, fn target ->
      case Map.get(results_by_position, target.position, []) do
        [result] -> result
        _missing_or_duplicate -> safe_execution_result(target.position, :failed, :crashed)
      end
    end)
  end

  defp execution_result(position, {:ok, {:ok, _result}}),
    do: safe_execution_result(position, :success, :recorded)

  defp execution_result(position, {:ok, {:error, reason}}) do
    case reason do
      :preview_expired -> safe_execution_result(position, :skipped, :expired)
      :preview_drifted -> safe_execution_result(position, :skipped, :drifted)
      :preview_consumed -> safe_execution_result(position, :skipped, :consumed)
      :preview_not_found -> safe_execution_result(position, :skipped, :unavailable)
      :unauthorized -> safe_execution_result(position, :skipped, :unauthorized)
      _reason -> safe_execution_result(position, :failed, :failed)
    end
  end

  defp execution_result(position, :timeout),
    do: safe_execution_result(position, :failed, :timeout)

  defp execution_result(position, {:exit, _reason}),
    do: safe_execution_result(position, :failed, :crashed)

  defp execution_result(position, {:ok, _unexpected}),
    do: safe_execution_result(position, :failed, :failed)

  defp safe_execution_result(position, outcome, class) do
    {message, recovery} = execution_copy(class)

    %{
      position: position,
      outcome: outcome,
      message: message,
      recovery: recovery
    }
  end

  defp run_target_call(supervisor, timeout, function) do
    task =
      Task.Supervisor.async_nolink(supervisor, fn ->
        try do
          {:target_returned, function.()}
        rescue
          error -> {:target_exited, {:error, error}}
        catch
          kind, reason -> {:target_exited, {kind, reason}}
        end
      end)

    case Task.yield(task, timeout) do
      nil ->
        case Task.yield(task, 0) do
          nil ->
            _ = Task.shutdown(task, :brutal_kill)
            :timeout

          {:ok, {:target_returned, result}} ->
            {:ok, result}

          {:ok, {:target_exited, reason}} ->
            {:exit, reason}

          {:exit, reason} ->
            {:exit, reason}
        end

      {:ok, {:target_returned, result}} ->
        {:ok, result}

      {:ok, {:target_exited, reason}} ->
        {:exit, reason}

      {:exit, reason} ->
        {:exit, reason}
    end
  end

  defp authorize_initial(actor, action, opts) do
    contract = Map.fetch!(@action_contract, action)

    with :ok <- authorize(opts, actor, :view_jobs, %{type: :page, id: "jobs"}),
         :ok <-
           authorize(opts, actor, contract.permission, %{
             type: :jobs_bulk_action
           }) do
      :ok
    end
  end

  defp authorize(opts, actor, permission, resource) do
    authorize_fun =
      Keyword.get(opts, :authorize, fn current_actor, action, current_resource ->
        Auth.authorization_outcome(current_actor, action, current_resource)
      end)

    case authorize_fun.(actor, permission, resource) do
      :ok -> :ok
      true -> :ok
      _denied -> {:error, :unauthorized}
    end
  rescue
    _error -> {:error, :unauthorized}
  end

  defp preview_function(opts) do
    Keyword.get(opts, :preview, fn repo, actor, attrs, lifeline_opts ->
      Lifeline.preview_repair(repo, actor, attrs, lifeline_opts)
    end)
  end

  defp execute_function(opts) do
    Keyword.get(opts, :execute, fn repo, actor, token, reason, lifeline_opts ->
      Lifeline.execute_repair(repo, actor, token, reason, lifeline_opts)
    end)
  end

  defp normalize_candidates(:explicit, candidates, limit) do
    with {:ok, ids} <- normalize_id_collection(candidates) do
      enforce_limit(ids, length(ids), false, limit)
    end
  end

  defp normalize_candidates(
         :all_matching,
         %{ids: ids, overflow?: overflow?, selected_count: selected_count},
         limit
       )
       when is_boolean(overflow?) and is_integer(selected_count) and selected_count >= 0 do
    cond do
      overflow? and selected_count > limit ->
        {:error, {:too_many_targets, limit}}

      true ->
        with {:ok, normalized_ids} <- normalize_id_collection(ids),
             true <- selected_count == length(normalized_ids) do
          enforce_limit(normalized_ids, selected_count, overflow?, limit)
        else
          false -> {:error, :invalid_scope}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp normalize_candidates(_mode, _candidates, _limit), do: {:error, :invalid_scope}

  defp normalize_id_collection(%MapSet{} = ids) do
    ids
    |> MapSet.to_list()
    |> Enum.sort()
    |> normalize_id_collection()
  end

  defp normalize_id_collection(ids) when is_list(ids) do
    if Enum.all?(ids, &(is_integer(&1) and &1 > 0)) do
      {:ok, stable_uniq(ids)}
    else
      {:error, :invalid_scope}
    end
  end

  defp normalize_id_collection(_ids), do: {:error, :invalid_scope}

  defp stable_uniq(ids) do
    {reversed, _seen} =
      Enum.reduce(ids, {[], MapSet.new()}, fn id, {unique, seen} ->
        if MapSet.member?(seen, id) do
          {unique, seen}
        else
          {[id | unique], MapSet.put(seen, id)}
        end
      end)

    Enum.reverse(reversed)
  end

  defp enforce_limit(_ids, selected_count, true, limit) when selected_count > limit,
    do: {:error, {:too_many_targets, limit}}

  defp enforce_limit(ids, selected_count, false, limit)
       when selected_count <= limit and length(ids) == selected_count,
       do: {:ok, ids, selected_count}

  defp enforce_limit(_ids, selected_count, _overflow?, limit) when selected_count > limit,
    do: {:error, {:too_many_targets, limit}}

  defp enforce_limit(_ids, _selected_count, _overflow?, _limit), do: {:error, :invalid_scope}

  defp validate_filter_identity(value) when is_binary(value) do
    if String.trim(value) == "", do: {:error, :invalid_scope}, else: :ok
  end

  defp validate_filter_identity(_value), do: {:error, :invalid_scope}

  defp validate_observed_at(%DateTime{utc_offset: utc_offset, std_offset: std_offset})
       when utc_offset + std_offset == 0,
       do: :ok

  defp validate_observed_at(_value), do: {:error, :invalid_scope}

  defp validate_scope(%Scope{} = scope) do
    limit = RuntimeConfig.jobs_bulk_target_limit()

    with true <- scope.mode in [:explicit, :all_matching],
         {:ok, ids} <- normalize_id_collection(scope.ids),
         true <- ids == scope.ids,
         true <- scope.selected_count == length(ids),
         true <- scope.selected_count <= limit,
         :ok <- validate_filter_identity(scope.filter_identity),
         :ok <- validate_observed_at(scope.observed_at) do
      :ok
    else
      _invalid -> {:error, :invalid_scope}
    end
  end

  defp normalize_action(action) when is_binary(action) do
    case action do
      "retry" -> {:ok, :retry}
      "job_retry" -> {:ok, :retry}
      "cancel" -> {:ok, :cancel}
      "job_cancel" -> {:ok, :cancel}
      "discard" -> {:ok, :discard}
      "job_discard" -> {:ok, :discard}
      _unsupported -> {:error, :unsupported_action}
    end
  end

  defp normalize_action(action) when is_atom(action) do
    if Map.has_key?(@action_contract, action),
      do: {:ok, action},
      else: {:error, :unsupported_action}
  end

  defp normalize_action(_action), do: {:error, :unsupported_action}

  defp validate_handle(%{run_ref: run_ref, coordinator: coordinator})
       when is_reference(run_ref) and is_pid(coordinator),
       do: {:ok, run_ref, coordinator}

  defp validate_handle(_handle), do: {:error, :invalid_preview_handle}

  defp valid_reason?(reason) when is_binary(reason),
    do: reason |> String.trim() |> String.length() >= 8

  defp valid_reason?(_reason), do: false

  defp empty_aggregate(total),
    do: %{processed: 0, total: total, success: 0, skipped: 0, failed: 0}

  defp increment_aggregate(aggregate, outcome) do
    aggregate
    |> Map.update!(:processed, &(&1 + 1))
    |> Map.update!(outcome, &(&1 + 1))
  end

  defp preview_reason(reason) do
    case reason do
      :heartbeat_late ->
        %{
          class: :not_ready,
          message: "This job is not ready for this action.",
          recovery: "Review the current job before creating a fresh preview."
        }

      :repair_requires_missing_executor ->
        %{
          class: :not_ready,
          message: "This job is not ready for this action.",
          recovery: "Review the current job before creating a fresh preview."
        }

      :unauthorized ->
        %{
          class: :unavailable,
          message: "This job is unavailable for this action.",
          recovery: "Review the selected scope or your current access."
        }

      :preview_timeout ->
        %{
          class: :unavailable,
          message: "This job preview did not finish in time.",
          recovery: "Create a fresh preview before trying again."
        }

      _reason ->
        %{
          class: :unavailable,
          message: "This job is unavailable for this action.",
          recovery: "Review the selected scope before creating a fresh preview."
        }
    end
  end

  defp execution_copy(:recorded),
    do: {"The job action was recorded.", nil}

  defp execution_copy(:expired),
    do: {"This job preview expired.", "Create a fresh preview before trying again."}

  defp execution_copy(:drifted),
    do: {"This job changed after the preview.", "Review the job and create a fresh preview."}

  defp execution_copy(:consumed),
    do: {"This job preview was already used.", "Create a fresh preview before trying again."}

  defp execution_copy(:unavailable),
    do: {"This job is unavailable.", "Review Audit before creating a fresh preview."}

  defp execution_copy(:unauthorized),
    do: {"This job is unavailable.", "Review the selected scope or your current access."}

  defp execution_copy(:timeout),
    do:
      {"This job did not finish before the target timeout.",
       "Review Audit before creating a fresh preview."}

  defp execution_copy(:crashed),
    do: {"This job could not be processed.", "Review Audit before creating a fresh preview."}

  defp execution_copy(:failed),
    do: {"This job action was not recorded.", "Review Audit before creating a fresh preview."}

  defp safe_batch_reason(reason)
       when reason in [:not_authorized, :preview_unavailable, :execution_unavailable],
       do: reason

  defp safe_batch_reason(_reason), do: :preview_unavailable

  defp target_timeout(opts) do
    case Keyword.get(opts, :test_target_timeout_ms) do
      value when is_integer(value) and value > 0 -> min(value, @target_timeout_ms)
      _value -> @target_timeout_ms
    end
  end

  defp preview_result_class(%Preview{ready: []}), do: :preview_empty
  defp preview_result_class(%Preview{}), do: :preview_ready

  defp execution_result_class(%{success: success, total: total}) when success == total,
    do: :all_success

  defp execution_result_class(%{success: 0, failed: failed}) when failed > 0,
    do: :failed

  defp execution_result_class(_aggregate), do: :mixed

  defp emit_telemetry(action, scope, result, count, started_at) do
    duration_ms =
      System.monotonic_time()
      |> Kernel.-(started_at)
      |> System.convert_time_unit(:native, :millisecond)

    :telemetry.execute(
      @telemetry_event,
      %{count: 1},
      %{
        surface: :jobs,
        action: action,
        scope: scope,
        result: result,
        count_bucket: count_bucket(count),
        duration_bucket: duration_bucket(duration_ms)
      }
    )
  end

  defp count_bucket(0), do: :"0"
  defp count_bucket(count) when count <= 10, do: :"1_10"
  defp count_bucket(count) when count <= 100, do: :"11_100"
  defp count_bucket(_count), do: :"101_1000"

  defp duration_bucket(duration_ms) when duration_ms < 100, do: :under_100ms
  defp duration_bucket(duration_ms) when duration_ms < 1_000, do: :under_1s
  defp duration_bucket(duration_ms) when duration_ms < 10_000, do: :under_10s
  defp duration_bucket(_duration_ms), do: :ten_seconds_or_more

  defp normalize_page(_requested_page, 0), do: 1

  defp normalize_page(requested_page, total_pages)
       when is_integer(requested_page) and requested_page > 0,
       do: min(requested_page, total_pages)

  defp normalize_page(_requested_page, _total_pages), do: 1

  defp validate_safe_result!(result) when is_map(result) and not is_struct(result) do
    allowed = MapSet.new([:position, :outcome, :message, :recovery])
    keys = result |> Map.keys() |> MapSet.new()

    cond do
      not MapSet.subset?(keys, allowed) ->
        raise ArgumentError, "batch result contains unsupported fields"

      not (is_integer(Map.get(result, :position)) and Map.get(result, :position) >= 0) ->
        raise ArgumentError, "batch result position must be nonnegative"

      Map.get(result, :outcome) not in [:success, :skipped, :failed, :ready, :excluded] ->
        raise ArgumentError, "batch result outcome is unsupported"

      not is_binary(Map.get(result, :message)) ->
        raise ArgumentError, "batch result message must be text"

      not (is_nil(Map.get(result, :recovery)) or is_binary(Map.get(result, :recovery))) ->
        raise ArgumentError, "batch result recovery must be text"

      true ->
        :ok
    end
  end

  defp validate_safe_result!(_result),
    do: raise(ArgumentError, "batch result must be a plain map")
end
