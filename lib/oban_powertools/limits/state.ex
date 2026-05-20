defmodule ObanPowertools.Limits.State do
  @moduledoc """
  Mutable limiter runtime state for a resource partition.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_limit_states" do
    field(:partition_key, :string, default: "__global__")
    field(:tokens_used, :integer, default: 0)
    field(:bucket_started_at, :utc_datetime_usec)
    field(:last_reserved_at, :utc_datetime_usec)
    field(:cooldown_until, :utc_datetime_usec)
    field(:cooldown_reason, :string)
    field(:reservation_snapshot, :map, default: %{})

    belongs_to(:resource, ObanPowertools.Limits.Resource, type: :binary_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :resource_id,
      :partition_key,
      :tokens_used,
      :bucket_started_at,
      :last_reserved_at,
      :cooldown_until,
      :cooldown_reason,
      :reservation_snapshot
    ])
    |> validate_required([:resource_id, :partition_key, :tokens_used, :bucket_started_at])
    |> validate_number(:tokens_used, greater_than_or_equal_to: 0)
    |> unique_constraint([:resource_id, :partition_key])
  end
end
