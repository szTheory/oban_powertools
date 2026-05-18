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
end