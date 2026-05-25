defmodule ObanPowertools.Workflow.Coordinator do
  @moduledoc """
  Thin PubSub-driven workflow reconciler.
  """

  use GenServer

  alias ObanPowertools.Workflow.Runtime

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    pubsub = Phoenix.PubSub

    if Code.ensure_loaded?(pubsub) and function_exported?(pubsub, :subscribe, 2) do
      apply(pubsub, :subscribe, [ObanPowertools.PubSub, ObanPowertools.Workflow.Signal.topic()])
    end

    {:ok, %{}}
  end

  @impl true
  def handle_info({:workflow_signal, %{workflow_id: workflow_id}}, state) do
    repo = Application.get_env(:oban_powertools, :repo)

    try do
      Runtime.reconcile_workflow(repo, workflow_id)
    rescue
      Ecto.StaleEntryError -> :ok
      Ecto.NoResultsError -> :ok
      DBConnection.ConnectionError -> :ok
    end

    {:noreply, state}
  end

  def handle_info(_message, state), do: {:noreply, state}
end
