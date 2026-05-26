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
    field(:command_key, :string)
    field(:event_type, :string)
    field(:resource, :string)
    field(:resource_type, :string)
    field(:resource_id, :string)
    field(:metadata, :map, default: %{})

    timestamps(updated_at: false)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :actor_id,
      :action,
      :command_key,
      :event_type,
      :resource,
      :resource_type,
      :resource_id,
      :metadata
    ])
    |> validate_required([:action, :resource])
  end

  def record(action, resource, metadata \\ %{}, opts \\ []) do
    repo = RuntimeConfig.repo(opts)
    principal = Keyword.get(opts, :principal)
    actor_id = Keyword.get(opts, :actor_id) || principal_id(principal)

    resource_parts = normalize_resource_parts(resource)
    metadata = attach_principal(metadata, principal)
    event_type = metadata["event_type"] || metadata[:event_type] || action

    command_key =
      metadata["command_key"] || metadata[:command_key] || infer_command_key(event_type)

    %__MODULE__{}
    |> changeset(%{
      actor_id: actor_id,
      action: action,
      command_key: command_key,
      event_type: event_type,
      resource: resource_parts.resource,
      resource_type: resource_parts.resource_type,
      resource_id: resource_parts.resource_id,
      metadata: metadata
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

  def list_all(filters, opts) when is_map(filters) and is_list(opts) do
    repo = RuntimeConfig.repo(opts)

    __MODULE__
    |> filter_query(filters)
    |> order_by([event], desc: event.inserted_at)
    |> repo.all()
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

  def event_label(%__MODULE__{} = event) do
    event.event_type || event.action
  end

  def event_resource_identity(%__MODULE__{} = event) do
    %{
      type: event.resource_type || legacy_resource_type(event.resource),
      id: event.resource_id || legacy_resource_id(event.resource),
      label: event.resource
    }
  end

  def system_principal(name, opts \\ []) do
    %{id: "system:#{name}", type: :system, label: Keyword.get(opts, :label)}
  end

  defp normalize_resource(%{type: type, id: id}), do: "#{type}:#{id}"
  defp normalize_resource(resource) when is_binary(resource), do: resource

  defp normalize_resource_parts(resource) do
    normalized = normalize_resource(resource)

    %{
      resource: normalized,
      resource_type: resource_type(resource, normalized),
      resource_id: resource_id(resource, normalized)
    }
  end

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

  defp infer_command_key("cron.paused"), do: "pause_cron_entry"
  defp infer_command_key("cron.resumed"), do: "resume_cron_entry"
  defp infer_command_key("cron.run_now"), do: "run_cron_entry"
  defp infer_command_key("cron.run_now_previewed"), do: "run_cron_entry"
  defp infer_command_key("lifeline.repair_executed"), do: "execute_repair"
  defp infer_command_key("workflow.cancel_requested"), do: "request_cancel"
  defp infer_command_key("workflow.recovery_completed"), do: "recover_step"
  defp infer_command_key("workflow.step_completed"), do: "complete_step"
  defp infer_command_key(_event_type), do: nil

  defp filter_query(query, filters) do
    Enum.reduce(filters, query, fn
      {_key, value}, query when value in [nil, ""] ->
        query

      {"resource_type", value}, query ->
        where(query, [event], event.resource_type == ^value)

      {"resource_id", value}, query ->
        where(query, [event], event.resource_id == ^value)

      {"event_type", value}, query ->
        where(query, [event], event.event_type == ^value)

      {:resource_type, value}, query ->
        where(query, [event], event.resource_type == ^value)

      {:resource_id, value}, query ->
        where(query, [event], event.resource_id == ^value)

      {:event_type, value}, query ->
        where(query, [event], event.event_type == ^value)

      _, query ->
        query
    end)
  end

  defp resource_type(%{type: type}, _normalized), do: to_string(type)

  defp resource_type(resource, normalized) when is_binary(resource),
    do: legacy_resource_type(normalized)

  defp resource_id(%{id: id}, _normalized), do: to_string(id)

  defp resource_id(resource, normalized) when is_binary(resource),
    do: legacy_resource_id(normalized)

  defp legacy_resource_type(resource) do
    case String.split(resource || "", ":", parts: 2) do
      [type, _id] -> type
      _ -> nil
    end
  end

  defp legacy_resource_id(resource) do
    case String.split(resource || "", ":", parts: 2) do
      [_type, id] -> id
      _ -> nil
    end
  end

  defp read_key(map, key) when is_map(map) do
    if Map.has_key?(map, key) do
      Map.get(map, key)
    else
      Map.get(map, Atom.to_string(key))
    end
  end
end
