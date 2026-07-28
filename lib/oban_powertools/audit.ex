defmodule ObanPowertools.Audit do
  @moduledoc """
  Normalized audit writer and reader for smart-engine events.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias ObanPowertools.Forensics.Scope
  alias ObanPowertools.RuntimeConfig

  @primary_key {:id, :id, autogenerate: true}
  @page_size 20
  @forensic_event_limit 50
  @forensic_event_types ~w(
    lifeline.host_follow_up
    lifeline.repair_executed
    workflow.cancel_requested
    workflow.recovery_completed
    workflow.step_completed
    workflow.step_unblocked
  )

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
        order_by: [desc: event.inserted_at, desc: event.id]
      )
    )
  end

  def list_all(opts \\ []) do
    repo = RuntimeConfig.repo(opts)

    repo.all(
      from(event in __MODULE__,
        order_by: [desc: event.inserted_at, desc: event.id]
      )
    )
  end

  def list_all(filters, opts) when is_map(filters) and is_list(opts) do
    repo = RuntimeConfig.repo(opts)

    __MODULE__
    |> filter_query(filters)
    |> order_by([event], desc: event.inserted_at, desc: event.id)
    |> repo.all()
  end

  @doc """
  Returns one stable, bounded page of audit events for the existing exact filters.

  Pages contain at most #{@page_size} events ordered by `inserted_at DESC, id DESC`.
  Invalid pages normalize to the first page, excessive pages clamp to the last
  reachable page, and an empty scope remains on page 1.
  """
  def page(filters, opts \\ []) when is_map(filters) and is_list(opts) do
    repo = RuntimeConfig.repo(opts)
    query = filter_query(__MODULE__, filters)
    total_count = repo.aggregate(query, :count, :id)
    total_pages = total_pages(total_count)
    page = opts |> Keyword.get(:page, 1) |> normalize_page(total_pages)
    offset = (page - 1) * @page_size

    events =
      query
      |> order_by([event], desc: event.inserted_at, desc: event.id)
      |> limit(^@page_size)
      |> offset(^offset)
      |> repo.all()

    %{
      events: events,
      total_count: total_count,
      page: page,
      page_size: @page_size,
      total_pages: total_pages,
      previous?: page > 1,
      next?: page < total_pages
    }
  end

  @doc """
  Fetches one audit event by ID inside the supplied exact filter scope.

  The ID and every active filter are combined in one bounded query. Invalid IDs,
  absent rows, and rows outside the active scope all return the same `:error`
  result so callers cannot use the lookup to enumerate records across scopes.
  """
  def fetch_in_scope(filters, id, opts \\ []) when is_map(filters) and is_list(opts) do
    with {:ok, id} <- normalize_event_id(id) do
      repo = RuntimeConfig.repo(opts)

      event =
        __MODULE__
        |> filter_query(filters)
        |> where([event], event.id == ^id)
        |> repo.one()

      if event, do: {:ok, event}, else: :error
    else
      :error -> :error
    end
  end

  @doc """
  Returns one stable, database-bounded Audit window for a typed forensic scope.

  Workflow scopes use their authoritative relational resource identity and
  include an exact total. Incident scopes use the retained Audit metadata
  fingerprint and probe one extra row, so their total remains deliberately
  unknown while `has_more?` remains truthful.

  A repository must be supplied explicitly. Optional `:event_types` are
  validated against the finite forensic allowlist before any query runs.
  """
  @spec forensic_window(Scope.t(), keyword()) :: %{
          events: [%__MODULE__{}],
          shown_count: non_neg_integer(),
          total_count: non_neg_integer() | nil,
          has_more?: boolean()
        }
  def forensic_window(%Scope{} = supplied_scope, opts) when is_list(opts) do
    scope = validate_forensic_scope!(supplied_scope)
    repo = Keyword.fetch!(opts, :repo)

    scope
    |> forensic_query()
    |> restrict_forensic_event_types(opts)
    |> load_forensic_window(scope.kind, repo)
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

  def event_runbook_context(%__MODULE__{} = event) do
    case get_in(event.metadata || %{}, ["runbook_context"]) do
      %{} = context -> context
      _missing -> nil
    end
  end

  def event_attempt_state(%__MODULE__{} = event) do
    event
    |> event_runbook_context()
    |> case do
      %{} = context -> get_in(context, ["attempt", "state"])
      _missing -> nil
    end
  end

  def event_selected_path(%__MODULE__{} = event) do
    event
    |> event_runbook_context()
    |> case do
      %{} = context ->
        case get_in(context, ["selected_path"]) do
          %{} = selected_path -> selected_path
          _missing -> nil
        end

      _missing ->
        nil
    end
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

  defp total_pages(0), do: 0
  defp total_pages(total_count), do: div(total_count + @page_size - 1, @page_size)

  defp normalize_page(_page, 0), do: 1

  defp normalize_page(page, total_pages) when is_integer(page) and page > 0,
    do: min(page, total_pages)

  defp normalize_page(_page, _total_pages), do: 1

  defp normalize_event_id(id) when is_integer(id) and id > 0, do: {:ok, id}

  defp normalize_event_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _invalid -> :error
    end
  end

  defp normalize_event_id(_id), do: :error

  defp validate_forensic_scope!(%Scope{} = scope) do
    scope
    |> Scope.canonical_params()
    |> Scope.parse()
    |> case do
      {:ok, ^scope, _params} ->
        scope

      _invalid ->
        raise ArgumentError, "forensic_window/2 requires a valid parsed forensic scope"
    end
  end

  defp forensic_query(%Scope{kind: :workflow} = scope) do
    {resource_type, resource_id} = forensic_workflow_identity(scope)

    from(event in __MODULE__,
      where:
        event.resource_type == ^resource_type and
          event.resource_id == ^resource_id
    )
  end

  defp forensic_query(%Scope{kind: :incident, incident_fingerprint: fingerprint}) do
    from(event in __MODULE__,
      where: fragment("?->>'incident_fingerprint' = ?", event.metadata, ^fingerprint)
    )
  end

  defp forensic_query(%Scope{kind: kind}) do
    raise ArgumentError, "Audit evidence is unavailable for #{kind} forensic scopes"
  end

  defp forensic_workflow_identity(%Scope{
         resource_type: resource_type,
         resource_id: resource_id
       })
       when resource_type in ["workflow", "workflow_step"] and is_binary(resource_id) do
    {resource_type, resource_id}
  end

  defp forensic_workflow_identity(%Scope{workflow_id: workflow_id}) do
    {"workflow", workflow_id}
  end

  defp restrict_forensic_event_types(query, opts) do
    case Keyword.fetch(opts, :event_types) do
      :error ->
        query

      {:ok, event_types} when is_list(event_types) ->
        if Enum.all?(event_types, &(&1 in @forensic_event_types)) do
          where(query, [event], event.event_type in ^event_types)
        else
          raise ArgumentError, "event_types contains a value outside the forensic allowlist"
        end

      {:ok, _invalid} ->
        raise ArgumentError, "event_types must be a list of forensic event type strings"
    end
  end

  defp load_forensic_window(query, :workflow, repo) do
    total_count = repo.aggregate(query, :count, :id)

    events =
      query
      |> order_by([event], desc: event.inserted_at, desc: event.id)
      |> limit(^@forensic_event_limit)
      |> repo.all()

    shown_count = length(events)

    %{
      events: events,
      shown_count: shown_count,
      total_count: total_count,
      has_more?: total_count > shown_count
    }
  end

  defp load_forensic_window(query, :incident, repo) do
    probe_limit = @forensic_event_limit + 1

    probed_events =
      query
      |> order_by([event], desc: event.inserted_at, desc: event.id)
      |> limit(^probe_limit)
      |> repo.all()

    events = Enum.take(probed_events, @forensic_event_limit)

    %{
      events: events,
      shown_count: length(events),
      total_count: nil,
      has_more?: length(probed_events) > @forensic_event_limit
    }
  end

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
