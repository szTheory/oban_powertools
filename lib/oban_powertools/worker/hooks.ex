defmodule ObanPowertools.Worker.Hooks do
  @moduledoc false

  require Logger

  alias ObanPowertools.Telemetry

  @ok_outcome "ok"
  @crash_caught_outcome "crash_caught"

  def on_start(worker_mod, %Oban.Job{} = job) do
    safe_invoke(worker_mod, :on_start, [job])
  end

  def after_result(worker_mod, %Oban.Job{} = job, result) do
    case result do
      :ok ->
        safe_invoke(worker_mod, :on_success, [
          job,
          %{state: :success, result: :ok, value: nil}
        ])

      {:ok, value} = success_result ->
        safe_invoke(worker_mod, :on_success, [
          job,
          %{state: :success, result: success_result, value: value}
        ])

      {:error, reason} = error_result ->
        if terminal_attempt?(job) do
          safe_invoke(worker_mod, :on_discard, [
            job,
            discard_event(reason, error_result, nil, nil)
          ])
        else
          safe_invoke(worker_mod, :on_failure, [
            job,
            failure_event(reason, error_result, nil, nil)
          ])
        end

      :discard ->
        safe_invoke(worker_mod, :on_discard, [
          job,
          discard_event(:discard, :discard, nil, nil)
        ])

      {:discard, reason} = discard_result ->
        safe_invoke(worker_mod, :on_discard, [
          job,
          discard_event(reason, discard_result, nil, nil)
        ])

      {:cancel, _reason} ->
        :ok

      {:snooze, _seconds} ->
        :ok

      _other ->
        :ok
    end
  end

  def after_exception(worker_mod, %Oban.Job{} = job, kind, reason, stacktrace) do
    if terminal_attempt?(job) do
      safe_invoke(worker_mod, :on_discard, [
        job,
        discard_event(reason, nil, kind, stacktrace)
      ])
    else
      safe_invoke(worker_mod, :on_failure, [
        job,
        failure_event(reason, nil, kind, stacktrace)
      ])
    end
  end

  defp safe_invoke(worker_mod, hook, args) do
    arity = length(args)

    if hook_overridden?(worker_mod, hook) and function_exported?(worker_mod, hook, arity) do
      outcome =
        try do
          apply(worker_mod, hook, args)
          @ok_outcome
        rescue
          error ->
            Logger.warning(fn ->
              "ObanPowertools worker hook #{hook} crashed: #{Exception.message(error)}"
            end)

            @crash_caught_outcome
        catch
          kind, reason ->
            Logger.warning(fn ->
              "ObanPowertools worker hook #{hook} crashed via #{kind}: #{inspect(reason)}"
            end)

            @crash_caught_outcome
        end

      Telemetry.execute_worker_hook_event(:invoked, %{count: 1}, %{
        hook: Atom.to_string(hook),
        outcome: outcome
      })
    end

    :ok
  end

  defp hook_overridden?(worker_mod, hook) do
    function_exported?(worker_mod, :__powertools_hook_overridden?, 1) and
      worker_mod.__powertools_hook_overridden?(hook)
  end

  defp failure_event(reason, result, kind, stacktrace) do
    %{
      state: :failure,
      reason: reason,
      result: result,
      kind: kind,
      stacktrace: stacktrace,
      terminal?: false
    }
  end

  defp discard_event(reason, result, kind, stacktrace) do
    %{
      state: :discard,
      reason: reason,
      result: result,
      kind: kind,
      stacktrace: stacktrace,
      terminal?: true
    }
  end

  defp terminal_attempt?(%Oban.Job{attempt: attempt, max_attempts: max_attempts})
       when is_integer(attempt) and is_integer(max_attempts) do
    attempt >= max_attempts
  end

  defp terminal_attempt?(_job), do: false
end
