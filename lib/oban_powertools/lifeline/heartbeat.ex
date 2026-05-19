defmodule ObanPowertools.Lifeline.Heartbeat do
  @moduledoc """
  Durable executor heartbeat evidence for Phase 4 liveness.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_heartbeats" do
    field(:executor_id, :string)
    field(:oban_name, :string, default: "Oban")
    field(:node, :string)
    field(:queue, :string, default: "default")
    field(:producer_scope, :string)
    field(:health_state, :string, default: "healthy")
    field(:last_heartbeat_at, :utc_datetime_usec)
    field(:warning_threshold_ms, :integer, default: 45_000)
    field(:missing_threshold_ms, :integer, default: 120_000)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :executor_id,
      :oban_name,
      :node,
      :queue,
      :producer_scope,
      :health_state,
      :last_heartbeat_at,
      :warning_threshold_ms,
      :missing_threshold_ms,
      :metadata
    ])
    |> validate_required([
      :executor_id,
      :oban_name,
      :node,
      :queue,
      :producer_scope,
      :health_state,
      :last_heartbeat_at,
      :warning_threshold_ms,
      :missing_threshold_ms,
      :metadata
    ])
    |> validate_number(:warning_threshold_ms, greater_than: 0)
    |> validate_number(:missing_threshold_ms, greater_than: 0)
    |> unique_constraint(:executor_id)
  end
end
