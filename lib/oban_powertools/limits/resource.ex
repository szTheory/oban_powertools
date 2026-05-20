defmodule ObanPowertools.Limits.Resource do
  @moduledoc """
  Durable limiter resource definition.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_limit_resources" do
    field(:name, :string)
    field(:scope_kind, :string)
    field(:algorithm, :string)
    field(:bucket_span_ms, :integer)
    field(:bucket_capacity, :integer)
    field(:default_weight, :integer, default: 1)
    field(:partition_strategy, :string, default: "global")
    field(:partition_config, :map, default: %{})
    field(:cooldown_enabled, :boolean, default: true)
    field(:metadata, :map, default: %{})

    has_many(:states, ObanPowertools.Limits.State, foreign_key: :resource_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :scope_kind,
      :algorithm,
      :bucket_span_ms,
      :bucket_capacity,
      :default_weight,
      :partition_strategy,
      :partition_config,
      :cooldown_enabled,
      :metadata
    ])
    |> validate_required([
      :name,
      :scope_kind,
      :algorithm,
      :bucket_span_ms,
      :bucket_capacity,
      :default_weight,
      :partition_strategy
    ])
    |> validate_number(:bucket_span_ms, greater_than: 0)
    |> validate_number(:bucket_capacity, greater_than: 0)
    |> validate_number(:default_weight, greater_than: 0)
    |> unique_constraint(:name)
  end
end
