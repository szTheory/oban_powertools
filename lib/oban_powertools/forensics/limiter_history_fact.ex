defmodule ObanPowertools.Forensics.LimiterHistoryFact do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_limiter_history_facts" do
    field(:resource_name, :string)
    field(:partition_key, :string, default: "__global__")
    field(:event_type, :string)
    field(:cause_kind, :string)
    field(:occurred_at, :utc_datetime_usec)
    field(:eligible_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :resource_name,
      :partition_key,
      :event_type,
      :cause_kind,
      :occurred_at,
      :eligible_at,
      :metadata
    ])
    |> validate_required([:resource_name, :partition_key, :event_type, :occurred_at])
  end
end
