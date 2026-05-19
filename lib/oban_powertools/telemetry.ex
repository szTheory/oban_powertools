defmodule ObanPowertools.Telemetry do
  @moduledoc """
  Provides safe, low-cardinality telemetry execution for Oban Powertools operator actions.
  """

  @doc """
  Executes a telemetry event for an operator action.
  """
  def execute_operator_action(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :operator_action, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_limiter_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :limiter, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_cron_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :cron, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_workflow_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :workflow, event_suffix],
      measurements,
      metadata
    )
  end

  def execute_lifeline_event(event_suffix, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:oban_powertools, :lifeline, event_suffix],
      measurements,
      metadata
    )
  end
end
