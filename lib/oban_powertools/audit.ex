defmodule ObanPowertools.Audit do
  @moduledoc """
  Normalized audit writer and reader for smart-engine events.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :id, autogenerate: true}

  schema "oban_powertools_audit_events" do
    field(:actor_id, :string)
    field(:action, :string)
    field(:resource, :string)
    field(:metadata, :map, default: %{})

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:actor_id, :action, :resource, :metadata])
    |> validate_required([:action, :resource])
  end

  def record(action, resource, metadata \\ %{}, opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
    actor_id = Keyword.get(opts, :actor_id)

    %__MODULE__{}
    |> changeset(%{
      actor_id: actor_id,
      action: action,
      resource: normalize_resource(resource),
      metadata: metadata
    })
    |> repo.insert()
  end

  def list(resource, opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))
    normalized = normalize_resource(resource)

    repo.all(
      from(event in __MODULE__,
        where: event.resource == ^normalized,
        order_by: [desc: event.inserted_at]
      )
    )
  end

  def list_all(opts \\ []) do
    repo = Keyword.get(opts, :repo, Application.get_env(:oban_powertools, :repo))

    repo.all(
      from(event in __MODULE__,
        order_by: [desc: event.inserted_at]
      )
    )
  end

  defp normalize_resource(%{type: type, id: id}), do: "#{type}:#{id}"
  defp normalize_resource(resource) when is_binary(resource), do: resource
end
