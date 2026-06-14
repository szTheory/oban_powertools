defmodule ObanPowertools.Batch do
  @moduledoc """
  Durable batch tracking schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_batches" do
    field(:name, :string)
    field(:status, :string, default: "executing")
    field(:total_count, :integer, default: 0)
    field(:success_count, :integer, default: 0)
    field(:discard_count, :integer, default: 0)
    field(:cancelled_count, :integer, default: 0)
    field(:snooze_count, :integer, default: 0)
    field(:inserted_count, :integer, default: 0)
    field(:insert_chunk_count, :integer, default: 0)
    field(:insert_failed_chunk, :integer)
    field(:insert_failure, :map, default: %{})
    field(:insert_failed_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)

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
      :snooze_count,
      :name,
      :inserted_count,
      :insert_chunk_count,
      :insert_failed_chunk,
      :insert_failure,
      :insert_failed_at,
      :completed_at
    ])
    |> validate_required([
      :status,
      :total_count,
      :success_count,
      :discard_count,
      :cancelled_count,
      :snooze_count,
      :inserted_count,
      :insert_chunk_count,
      :insert_failure
    ])
    |> validate_number(:total_count, greater_than_or_equal_to: 0)
    |> validate_number(:success_count, greater_than_or_equal_to: 0)
    |> validate_number(:discard_count, greater_than_or_equal_to: 0)
    |> validate_number(:cancelled_count, greater_than_or_equal_to: 0)
    |> validate_number(:snooze_count, greater_than_or_equal_to: 0)
    |> validate_number(:inserted_count, greater_than_or_equal_to: 0)
    |> validate_number(:insert_chunk_count, greater_than_or_equal_to: 0)
    |> validate_number(:insert_failed_chunk, greater_than: 0)
  end
end
