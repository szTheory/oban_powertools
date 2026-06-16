defmodule ObanPowertools.Worker.BatchCallback do
  @moduledoc """
  An internal Oban worker for executing untrusted host callback logic safely.

  This worker prevents bugs, exceptions, or timeouts in the host application's
  callback functions from crashing Powertools' internal `CallbackDispatcher` plugin.
  If the host logic fails, this worker automatically retries it using Oban's
  built-in backoff mechanisms.
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 10,
    tags: ["powertools", "batch", "callback"]

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{"module" => module_str, "function" => function_str, "payload" => payload} = args

    with {:ok, module} <- safe_module(module_str),
         {:ok, function} <- safe_function(function_str) do
      if function_exported?(module, function, 1) do
        apply(module, function, [payload])
      else
        {:error, {:undefined_function, module, function, 1}}
      end
    end
  end

  defp safe_module(module_str) when is_binary(module_str) do
    {:ok, String.to_existing_atom(module_str)}
  rescue
    ArgumentError -> {:error, {:invalid_module, module_str}}
  end

  defp safe_function(function_str) when is_binary(function_str) do
    {:ok, String.to_existing_atom(function_str)}
  rescue
    ArgumentError -> {:error, {:invalid_function, function_str}}
  end
end
