defmodule ObanPowertools.Forensics.CronCoverage do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias ObanPowertools.Cron.Entry

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_cron_coverages" do
    field(:slot_at, :utc_datetime_usec)
    field(:status, :string, default: "healthy")
    field(:metadata, :map, default: %{})

    belongs_to(:entry, Entry, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:entry_id, :slot_at, :status, :metadata])
    |> validate_required([:entry_id, :slot_at, :status])
    |> unique_constraint([:entry_id, :slot_at])
  end
end
