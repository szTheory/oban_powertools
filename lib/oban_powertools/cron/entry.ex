defmodule ObanPowertools.Cron.Entry do
  @moduledoc """
  Durable cron entry definition.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "oban_powertools_cron_entries" do
    field(:name, :string)
    field(:source, :string)
    field(:worker, :string)
    field(:queue, :string, default: "default")
    field(:expression, :string)
    field(:timezone, :string, default: "Etc/UTC")
    field(:args, :map, default: %{})
    field(:opts, :map, default: %{})
    field(:overlap_policy, :string, default: "queue_one")
    field(:catch_up_policy, :string, default: "latest")
    field(:max_catch_up, :integer, default: 1)
    field(:paused_at, :utc_datetime_usec)
    field(:last_run_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})

    has_many(:slots, ObanPowertools.Cron.Slot, foreign_key: :entry_id)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :name,
      :source,
      :worker,
      :queue,
      :expression,
      :timezone,
      :args,
      :opts,
      :overlap_policy,
      :catch_up_policy,
      :max_catch_up,
      :paused_at,
      :last_run_at,
      :metadata
    ])
    |> validate_required([
      :name,
      :source,
      :worker,
      :queue,
      :expression,
      :timezone,
      :overlap_policy,
      :catch_up_policy,
      :max_catch_up
    ])
    |> validate_number(:max_catch_up, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
