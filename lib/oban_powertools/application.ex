defmodule ObanPowertools.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias ObanPowertools.RuntimeConfig

  @impl true
  def start(_type, _args) do
    _ = RuntimeConfig.jobs_bulk_target_limit()

    children =
      []
      |> maybe_add_pubsub()
      |> add_jobs_task_supervisor()
      |> maybe_add_workflow_coordinator()
      |> maybe_add_heartbeat_writer()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ObanPowertools.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_add_pubsub(children) do
    if Code.ensure_loaded?(Phoenix.PubSub) do
      children ++ [{Phoenix.PubSub, name: ObanPowertools.PubSub}]
    else
      children
    end
  end

  defp add_jobs_task_supervisor(children) do
    children ++ [{Task.Supervisor, name: ObanPowertools.Jobs.TaskSupervisor}]
  end

  defp maybe_add_workflow_coordinator(children) do
    if Code.ensure_loaded?(ObanPowertools.Workflow.Coordinator) do
      children ++ [ObanPowertools.Workflow.Coordinator]
    else
      children
    end
  end

  defp maybe_add_heartbeat_writer(children) do
    if Code.ensure_loaded?(ObanPowertools.Lifeline.HeartbeatWriter) && RuntimeConfig.repo() do
      children ++ [ObanPowertools.Lifeline.HeartbeatWriter]
    else
      children
    end
  end
end
