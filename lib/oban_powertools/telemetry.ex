defmodule ObanPowertools.Telemetry do
  @moduledoc """
  Public telemetry contract for Oban Powertools.

  Phase 8 freezes five event families under the `[:oban_powertools, family, event_suffix]`
  prefix:

  - `:operator_action`
  - `:limiter`
  - `:cron`
  - `:workflow`
  - `:lifeline`

  The public measurement key is `:count`.

  Allowed low-cardinality metadata keys per family:

  - `:operator_action` -> `[:action, :source]`
  - `:limiter` -> `[:action, :blocker_code, :resource, :scope]`
  - `:cron` -> `[:action, :source, :overlap_policy, :catch_up_policy]`
  - `:workflow` -> `[:status, :state]`
  - `:lifeline` -> `[:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]`

  IDs, job args, preview tokens, and free-form reasons are intentionally excluded from this
  public API.
  """

  @contract %{
    measurement_keys: [:count],
    families: %{
      operator_action: [:action, :source],
      limiter: [:action, :blocker_code, :resource, :scope],
      cron: [:action, :source, :overlap_policy, :catch_up_policy],
      workflow: [:status, :state],
      lifeline: [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]
    }
  }

  @doc """
  Returns the public telemetry contract for event families, measurements, and metadata keys.
  """
  def contract, do: @contract

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
