defmodule ObanPowertools.Audit do
  @moduledoc """
  Normalized audit writer and reader for smart-engine events.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ObanPowertools.RuntimeConfig

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
    repo = RuntimeConfig.repo(opts)
    principal = Keyword.get(opts, :principal)
    actor_id = Keyword.get(opts, :actor_id) || principal_id(principal)

    %__MODULE__{}
    |> changeset(%{
      actor_id: actor_id,
      action: action,
      resource: normalize_resource(resource),
      metadata: attach_principal(metadata, principal)
    })
    |> repo.insert()
  end

  def list(resource, opts \\ []) do
    repo = RuntimeConfig.repo(opts)
    normalized = normalize_resource(resource)

    repo.all(
      from(event in __MODULE__,
        where: event.resource == ^normalized,
        order_by: [desc: event.inserted_at]
      )
    )
  end

  def list_all(opts \\ []) do
    repo = RuntimeConfig.repo(opts)

    repo.all(
      from(event in __MODULE__,
        order_by: [desc: event.inserted_at]
      )
    )
  end

  def event_principal(%__MODULE__{} = event) do
    metadata_principal = get_in(event.metadata || %{}, ["principal"])

    cond do
      is_map(metadata_principal) ->
        %{
          id: read_key(metadata_principal, :id) || event.actor_id || "system",
          type: read_key(metadata_principal, :type) || inferred_type(event.actor_id),
          label: read_key(metadata_principal, :label)
        }

      is_binary(event.actor_id) and event.actor_id != "" ->
        %{id: event.actor_id, type: :user, label: nil}

      true ->
        %{id: "system", type: :system, label: nil}
    end
  end

  def event_reason(%__MODULE__{} = event) do
    get_in(event.metadata || %{}, ["reason"])
  end

  def system_principal(name, opts \\ []) do
    %{id: "system:#{name}", type: :system, label: Keyword.get(opts, :label)}
  end

  defp normalize_resource(%{type: type, id: id}), do: "#{type}:#{id}"
  defp normalize_resource(resource) when is_binary(resource), do: resource

  defp attach_principal(metadata, nil), do: metadata

  defp attach_principal(metadata, principal) when is_map(metadata) do
    Map.put(metadata, "principal", principal_metadata(principal))
  end

  defp principal_metadata(principal) do
    %{
      "id" => read_key(principal, :id),
      "type" => normalize_type(read_key(principal, :type))
    }
    |> maybe_put_label(read_key(principal, :label))
  end

  defp maybe_put_label(metadata, nil), do: metadata
  defp maybe_put_label(metadata, label), do: Map.put(metadata, "label", label)

  defp normalize_type(type) when is_atom(type), do: Atom.to_string(type)
  defp normalize_type(type), do: type

  defp principal_id(nil), do: nil
  defp principal_id(principal), do: read_key(principal, :id)

  defp inferred_type(nil), do: :system
  defp inferred_type(_actor_id), do: :user

  defp read_key(map, key) when is_map(map) do
    if Map.has_key?(map, key) do
      Map.get(map, key)
    else
      Map.get(map, Atom.to_string(key))
    end
  end
end
