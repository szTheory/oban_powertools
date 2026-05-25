defmodule ObanPowertools.Workflow.Signal do
  @moduledoc """
  Internal workflow event vocabulary and PubSub helpers.
  """

  @events_topic "workflow:events"

  def topic, do: @events_topic

  def step_completed(workflow_id, step_name),
    do: %{event: :step_completed, workflow_id: workflow_id, step_name: to_string(step_name)}

  def step_unblocked(workflow_id, step_name),
    do: %{event: :step_unblocked, workflow_id: workflow_id, step_name: to_string(step_name)}

  def workflow_completed(workflow_id),
    do: %{event: :workflow_completed, workflow_id: workflow_id}

  def broadcast(event) do
    pubsub = Phoenix.PubSub

    if Code.ensure_loaded?(pubsub) and function_exported?(pubsub, :broadcast, 3) do
      try do
        apply(pubsub, :broadcast, [ObanPowertools.PubSub, topic(), {:workflow_signal, event}])
      rescue
        ArgumentError -> :ok
      end
    else
      :ok
    end
  end
end
