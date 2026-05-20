defmodule ObanPowertools.Cron.Slot do
  @moduledoc """
  Durable cron slot claim ledger.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_cron_slots" do
    field(:slot_at, :utc_datetime_usec)
    field(:state, :string, default: "pending")
    field(:job_id, :integer)
    field(:claim_token, Ecto.UUID)
    field(:claimed_at, :utc_datetime_usec)
    field(:finished_at, :utc_datetime_usec)
    field(:attempt_count, :integer, default: 0)
    field(:policy_snapshot, :map, default: %{})
    field(:metadata, :map, default: %{})

    belongs_to(:entry, ObanPowertools.Cron.Entry, type: :binary_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :entry_id,
      :slot_at,
      :state,
      :job_id,
      :claim_token,
      :claimed_at,
      :finished_at,
      :attempt_count,
      :policy_snapshot,
      :metadata
    ])
    |> validate_required([:entry_id, :slot_at, :state, :attempt_count])
    |> validate_number(:attempt_count, greater_than_or_equal_to: 0)
    |> unique_constraint([:entry_id, :slot_at])
  end
end
