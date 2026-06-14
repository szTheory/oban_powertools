defmodule ObanPowertools.Batch do
  @moduledoc """
  Durable batch tracking schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_batches" do
    field(:status, :string, default: "executing")
    field(:total_count, :integer, default: 0)
    field(:success_count, :integer, default: 0)
    field(:discard_count, :integer, default: 0)
    field(:cancelled_count, :integer, default: 0)
    field(:snooze_count, :integer, default: 0)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :status,
      :total_count,
      :success_count,
      :discard_count,
      :cancelled_count,
      :snooze_count
    ])
    |> validate_required([
      :status,
      :total_count,
      :success_count,
      :discard_count,
      :cancelled_count,
      :snooze_count
    ])
    |> validate_number(:total_count, greater_than_or_equal_to: 0)
    |> validate_number(:success_count, greater_than_or_equal_to: 0)
    |> validate_number(:discard_count, greater_than_or_equal_to: 0)
    |> validate_number(:cancelled_count, greater_than_or_equal_to: 0)
    |> validate_number(:snooze_count, greater_than_or_equal_to: 0)
  end
end
