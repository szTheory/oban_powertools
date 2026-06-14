defmodule ObanPowertools.BatchJob do
  @moduledoc """
  Durable batch job tracking schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_batch_jobs" do
    field(:job_id, :integer)
    field(:state, :string, default: "available")

    belongs_to(:batch, ObanPowertools.Batch, type: :binary_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :batch_id,
      :job_id,
      :state
    ])
    |> validate_required([
      :batch_id,
      :job_id,
      :state
    ])
    |> unique_constraint([:batch_id, :job_id])
  end
end
