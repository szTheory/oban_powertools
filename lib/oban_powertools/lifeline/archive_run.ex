defmodule ObanPowertools.Lifeline.ArchiveRun do
  @moduledoc """
  Durable archive/prune run ledger for evidence retention.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_archive_runs" do
    field(:run_type, :string)
    field(:status, :string, default: "pending")
    field(:retention_class, :string)
    field(:actor_id, :string)
    field(:reason, :string)
    field(:batch_size, :integer, default: 100)
    field(:archived_count, :integer, default: 0)
    field(:pruned_count, :integer, default: 0)
    field(:blocked_count, :integer, default: 0)
    field(:started_at, :utc_datetime_usec)
    field(:finished_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :run_type,
      :status,
      :retention_class,
      :actor_id,
      :reason,
      :batch_size,
      :archived_count,
      :pruned_count,
      :blocked_count,
      :started_at,
      :finished_at,
      :metadata
    ])
    |> validate_required([
      :run_type,
      :status,
      :retention_class,
      :batch_size,
      :archived_count,
      :pruned_count,
      :blocked_count,
      :metadata
    ])
    |> validate_number(:batch_size, greater_than: 0)
    |> validate_number(:archived_count, greater_than_or_equal_to: 0)
    |> validate_number(:pruned_count, greater_than_or_equal_to: 0)
    |> validate_number(:blocked_count, greater_than_or_equal_to: 0)
  end
end
