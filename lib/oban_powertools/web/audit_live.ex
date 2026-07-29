if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.AuditLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{Audit, DisplayPolicy, Lifeline}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}
    alias ObanPowertools.Web.Components.{DataDisplay, Forms, OperatorPatterns, Primitives}

    @filter_fields ~w[resource_type resource_id event_type]
    @filter_labels %{
      "resource_type" => "Resource type",
      "resource_id" => "Resource ID",
      "event_type" => "Event type"
    }
    @audit_text_fields ~w[reason source outcome result decision correlation correlation_id request_id]
    @audit_data_fields ~w[field before after label value items]
    @audit_data_limit 50
    @row_reason_limit 120

    @impl true
    def mount(_params, _session, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_audit, %{type: :page, id: "audit"}) do
        :ok = DisplayPolicy.assert_configured!()

        {:ok,
         socket
         |> assign(:filters, empty_filters())
         |> assign(:audit_page, empty_audit_page())
         |> assign(:event_rows, [])
         |> assign(:filter_form, filter_form(empty_filters()))
         |> assign(:active_filters, [])
         |> assign(:result_summary, "0 records · Page 1 of 1")
         |> assign(:selected_event_id, nil)
         |> assign(:selected_detail, nil)
         |> assign(:detail_state, :empty)
         |> assign(:retention_summary, retention_summary())}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      {:noreply, assign(socket, load_audit_state(params))}
    end

    @impl true
    def handle_event("apply_filters", %{"filters" => submitted_filters}, socket) do
      filters = audit_filters(submitted_filters)

      {:noreply, push_patch(socket, to: audit_path(filters, 1, nil))}
    end

    def handle_event("select_event", %{"event" => event_id}, socket) do
      replace? = not is_nil(socket.assigns.selected_event_id)

      {:noreply,
       push_patch(socket,
         to: audit_path(socket.assigns.filters, socket.assigns.audit_page.page, event_id),
         replace: replace?
       )}
    end

    def handle_event("close_detail", _params, socket) do
      {:noreply,
       push_patch(socket,
         to: audit_path(socket.assigns.filters, socket.assigns.audit_page.page, nil),
         replace: true
       )}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.page_content
        audit_page={@audit_page}
        event_rows={@event_rows}
        filter_form={@filter_form}
        active_filters={@active_filters}
        result_summary={@result_summary}
        selected_event_id={@selected_event_id}
        selected_detail={@selected_detail}
        detail_state={@detail_state}
        retention_summary={@retention_summary}
      />
      """
    end

    attr(:audit_page, :map, required: true)
    attr(:event_rows, :list, required: true)
    attr(:filter_form, :any, required: true)
    attr(:active_filters, :list, default: [])
    attr(:result_summary, :string, required: true)
    attr(:selected_event_id, :any, default: nil)
    attr(:selected_detail, :map, default: nil)
    attr(:detail_state, :atom, default: :empty, values: [:empty, :ready, :unavailable])
    attr(:retention_summary, :map, required: true)
    attr(:load_state, :atom, default: :ready, values: [:ready, :error])
    attr(:clear_filters_href, :string, default: "/ops/jobs/audit")

    attr(
      :read_only_copy,
      :string,
      default:
        "Permission: read-only. This page is the cross-surface audit destination. Powertools-native pages keep preview, reason, and local audit evidence close to the acted-on resource."
    )

    @doc """
    Renders the bounded read-only Audit scan and selected immutable evidence.

    The component consumes normalized presentation assigns only. It performs no
    authorization, repository work, URL parsing, time lookup, or mutation.
    """
    def page_content(assigns) do
      assigns =
        assign(
          assigns,
          :detail_fallback_id,
          detail_fallback_id(assigns.selected_event_id, assigns.event_rows)
        )

      ~H"""
      <section id="audit-page" class="obpt-audit-page" aria-labelledby="audit-page-title">
        <header class="obpt-audit-page__header">
          <h1 id="audit-page-title">Audit</h1>
          <p>Review recorded operator actions and the evidence available for each record.</p>
        </header>

        <Primitives.surface variant={:inset}>
          <p>{@read_only_copy}</p>
          <p>
            The Oban Web bridge remains Inspection only and read-only. Historical records show what was recorded; they do not claim current state or causality.
          </p>
        </Primitives.surface>

        <section id="audit-retention" aria-labelledby="audit-retention-title">
          <Primitives.surface variant={:inset}>
            <h2 id="audit-retention-title">{@retention_summary.title}</h2>
            <p>{@retention_summary.description}</p>
            <p>{@retention_summary.last_run}</p>
          </Primitives.surface>
        </section>

        <OperatorPatterns.filter_bar
          id="audit-filters"
          form={@filter_form}
          mode={:submit}
          result_summary={@result_summary}
          results_target_id="audit-records"
          active_filters={@active_filters}
          submit_event="apply_filters"
          clear_href={@clear_filters_href}
          filters_expanded={true}
        >
          <:fields>
            <Forms.input
              field={@filter_form[:resource_type]}
              label="Resource type"
              variant={:filter}
            />
            <Forms.input
              field={@filter_form[:resource_id]}
              label="Resource ID"
              variant={:filter}
            />
            <Forms.input
              field={@filter_form[:event_type]}
              label="Event type"
              variant={:filter}
            />
          </:fields>
        </OperatorPatterns.filter_bar>

        <Primitives.surface :if={@load_state == :error} variant={:inset} role="alert">
          <h2>Audit records did not load</h2>
          <p>Retry the request. If the problem continues, check the host logs.</p>
        </Primitives.surface>

        <DataDisplay.data_table
          :if={@load_state == :ready}
          id="audit-records"
          caption="Audit records"
          rows={@event_rows}
          row_id={& &1.id}
          state={:ready}
          resource="audit records"
          row_count={@audit_page.total_count}
          pagination_summary={@result_summary}
        >
          <:col :let={row} label="Event">
            <span id={"audit-record-#{row.id}"}>{row.event_label}</span>
          </:col>
          <:col :let={row} label="Target">
            <Primitives.link :if={row.target_href} navigate={row.target_href}>
              {row.target_label}
            </Primitives.link>
            <span :if={!row.target_href}>{row.target_label}</span>
          </:col>
          <:col :let={row} label="Actor">
            <span>{row.actor}</span>
          </:col>
          <:col :let={row} label="Reason">
            <span>{row.reason_summary}</span>
          </:col>
          <:col :let={row} label="Recorded at">
            <time datetime={row.recorded_datetime}>{row.recorded_at}</time>
          </:col>
          <:action :let={row}>
            <Primitives.button
              id={evidence_trigger_id(row.id)}
              variant={:ghost}
              phx-click="select_event"
              phx-value-event={row.id}
              aria-label={row.evidence_label}
              aria-expanded={to_string(selected_row?(@selected_event_id, row.id))}
              aria-controls="audit-detail"
            >
              View evidence
            </Primitives.button>
          </:action>
        </DataDisplay.data_table>

        <DataDisplay.empty_state
          :if={@load_state == :ready && @event_rows == []}
          id="audit-records-empty"
          heading={empty_title(@active_filters)}
          body={empty_description(@active_filters)}
        />

        <nav
          :if={@load_state == :ready}
          class="obpt-audit-page__pagination"
          aria-label="Audit pagination"
        >
          <Primitives.link :if={@audit_page.previous_href} patch={@audit_page.previous_href}>
            Previous
          </Primitives.link>
          <span :if={!@audit_page.previous_href} aria-disabled="true">Previous</span>
          <Primitives.link :if={@audit_page.next_href} patch={@audit_page.next_href}>
            Next
          </Primitives.link>
          <span :if={!@audit_page.next_href} aria-disabled="true">Next</span>
        </nav>

        <OperatorPatterns.detail_surface
          :if={@detail_state != :empty}
          id="audit-detail"
          title="Audit evidence"
          close_label="Close audit evidence"
          open={true}
          variant={:adaptive}
          state={@detail_state}
          resource="audit evidence"
          logical_fallback_id={@detail_fallback_id}
          close_event="close_detail"
          full_details_href={detail_target_href(@detail_state, @selected_detail)}
        >
          <:body>
            <OperatorPatterns.audit_entry
              :if={@detail_state == :ready}
              id={"audit-entry-#{@selected_event_id}"}
              entry={@selected_detail}
            />
          </:body>
          <:evidence :if={@detail_state == :unavailable}>
            <h3>Audit evidence is unavailable</h3>
            <p>
              The selected audit evidence is unavailable in the current filter scope. Close this evidence view, then select a listed record.
            </p>
          </:evidence>
        </OperatorPatterns.detail_surface>
      </section>
      """
    end

    defp load_audit_state(params) do
      filters = audit_filters(params)
      raw_page = Audit.page(filters, repo: repo(), page: positive_page(params["page"]))
      selected_event_id = blank_to_nil(params["event"])
      {detail_state, selected_event} = selected_event(filters, selected_event_id)
      page = page_metadata(raw_page, filters)

      %{
        filters: filters,
        audit_page: page,
        event_rows: Enum.map(raw_page.events, &present_audit_row(&1, filters, page.page)),
        filter_form: filter_form(filters),
        active_filters: active_filters(filters),
        result_summary: result_summary(page),
        selected_event_id: selected_event_id,
        selected_detail: present_selected_detail(selected_event),
        detail_state: detail_state
      }
    end

    defp present_audit_row(event, filters, page) do
      event
      |> safe_audit_event()
      |> ControlPlanePresenter.present_audit_row(%{surface: :audit, section: :table})
      |> Map.update!(:reason_summary, &abbreviate(&1, @row_reason_limit))
      |> Map.put(:evidence_href, audit_path(filters, page, event.id))
    end

    defp present_selected_detail(nil), do: nil

    defp present_selected_detail(event) do
      safe_event = safe_audit_event(event)

      detail =
        ControlPlanePresenter.present_audit_detail(safe_event, %{
          surface: :audit,
          section: :selected_evidence
        })

      row =
        ControlPlanePresenter.present_audit_row(safe_event, %{
          surface: :audit,
          section: :selected_evidence
        })

      Map.put(detail, :target_href, row.target_href)
    end

    defp safe_audit_event(%Audit{} = event) do
      %{event | metadata: safe_audit_metadata(event.metadata)}
    end

    defp safe_audit_metadata(source) when is_map(source) and not is_struct(source) do
      safe =
        Enum.reduce(@audit_text_fields, %{}, fn field, safe ->
          case safe_text(metadata_value(source, field)) do
            nil -> safe
            value -> Map.put(safe, field, value)
          end
        end)

      safe
      |> maybe_put_outcome_state(metadata_value(source, "outcome_state"))
      |> maybe_put_principal(metadata_value(source, "principal"))
      |> maybe_put_audit_data("changes", metadata_value(source, "changes"))
      |> maybe_put_audit_data("evidence", metadata_value(source, "evidence"))
    end

    defp safe_audit_metadata(_metadata), do: %{}

    defp maybe_put_outcome_state(safe, value) do
      case safe_text(value) do
        value when value in ["success", "failed", "skipped", "unknown"] ->
          Map.put(safe, "outcome_state", value)

        _other ->
          safe
      end
    end

    defp maybe_put_principal(safe, principal)
         when is_map(principal) and not is_struct(principal) do
      projected =
        Enum.reduce(~w[id type label], %{}, fn field, projected ->
          case safe_text(metadata_value(principal, field)) do
            nil -> projected
            value -> Map.put(projected, field, value)
          end
        end)

      if projected == %{}, do: safe, else: Map.put(safe, "principal", projected)
    end

    defp maybe_put_principal(safe, _principal), do: safe

    defp maybe_put_audit_data(safe, field, value) do
      case safe_audit_data(value) do
        nil -> safe
        projected -> Map.put(safe, field, projected)
      end
    end

    defp safe_audit_data(nil), do: nil

    defp safe_audit_data(value)
         when is_binary(value) or is_number(value) or is_boolean(value) or is_atom(value),
         do: value

    defp safe_audit_data(values) when is_list(values) do
      values
      |> Enum.take(@audit_data_limit)
      |> Enum.map(&safe_audit_data/1)
      |> Enum.reject(&is_nil/1)
    end

    defp safe_audit_data(value) when is_map(value) and not is_struct(value) do
      Enum.reduce(@audit_data_fields, %{}, fn field, projected ->
        case metadata_value(value, field) |> safe_audit_data() do
          nil -> projected
          nested -> Map.put(projected, field, nested)
        end
      end)
    end

    defp safe_audit_data(_value), do: nil

    defp safe_text(nil), do: nil
    defp safe_text(value) when is_atom(value), do: Atom.to_string(value)
    defp safe_text(value) when is_binary(value), do: value
    defp safe_text(_value), do: nil

    defp metadata_value(map, field) do
      case Map.fetch(map, field) do
        {:ok, value} ->
          value

        :error ->
          Enum.reduce_while(map, nil, fn
            {key, value}, _missing when is_atom(key) ->
              if Atom.to_string(key) == field,
                do: {:halt, value},
                else: {:cont, nil}

            _entry, _missing ->
              {:cont, nil}
          end)
      end
    end

    defp page_metadata(page, filters) do
      %{
        total_count: page.total_count,
        page: page.page,
        page_size: page.page_size,
        total_pages: page.total_pages,
        previous?: page.previous?,
        next?: page.next?,
        previous_href: if(page.previous?, do: audit_path(filters, page.page - 1, nil), else: nil),
        next_href: if(page.next?, do: audit_path(filters, page.page + 1, nil), else: nil)
      }
    end

    defp result_summary(%{total_count: 0}), do: "0 records · Page 1 of 1"

    defp result_summary(page) do
      first = (page.page - 1) * page.page_size + 1
      last = min(page.page * page.page_size, page.total_count)

      "Records #{first}–#{last} of #{page.total_count} · Page #{page.page} of #{max(page.total_pages, 1)}"
    end

    defp filter_form(filters) do
      values = Map.new(@filter_fields, &{&1, filters[&1] || ""})
      Phoenix.Component.to_form(values, as: :filters, id: "audit-filters-form")
    end

    defp active_filters(filters) do
      @filter_fields
      |> Enum.flat_map(fn field ->
        case filters[field] do
          value when value in [nil, ""] ->
            []

          value ->
            [
              %{
                id: "audit-filter-#{String.replace(field, "_", "-")}",
                label: Map.fetch!(@filter_labels, field),
                value: value,
                remove_href: audit_path(Map.put(filters, field, nil), 1, nil),
                remove_label: "Remove #{Map.fetch!(@filter_labels, field)} filter"
              }
            ]
        end
      end)
      |> ControlPlanePresenter.normalize_active_filters()
    end

    defp retention_summary do
      retention = Lifeline.retention_status(repo())
      archived_count = retention.archived_repairs

      %{
        title: "Repair evidence retention",
        description:
          "Archived repair evidence is stored separately from the live Audit rows shown here. The repair archive ledger contains #{archived_count} archived #{pluralize(archived_count, "repair record")}.",
        last_run: archive_run_summary(retention.last_run)
      }
    end

    defp archive_run_summary(nil), do: "No repair archive run has been recorded."

    defp archive_run_summary(run) do
      status =
        case run.status do
          "completed" -> "completed"
          "failed" -> "failed"
          "running" -> "started"
          _other -> "was recorded"
        end

      case absolute_utc(run.finished_at || run.started_at) do
        nil -> "The latest repair archive run #{status}."
        recorded_at -> "The latest repair archive run #{status} at #{recorded_at}."
      end
    end

    defp absolute_utc(nil), do: nil

    defp absolute_utc(%NaiveDateTime{} = value) do
      value |> DateTime.from_naive!("Etc/UTC") |> absolute_utc()
    end

    defp absolute_utc(%DateTime{} = value) do
      value
      |> DateTime.shift_zone!("Etc/UTC")
      |> Calendar.strftime("%Y-%m-%d %H:%M:%S UTC")
    end

    defp pluralize(1, singular), do: singular
    defp pluralize(_count, singular), do: singular <> "s"

    defp abbreviate(text, limit) when is_binary(text) do
      if String.length(text) > limit,
        do: String.slice(text, 0, limit - 1) <> "…",
        else: text
    end

    defp selected_event(_filters, nil), do: {:empty, nil}

    defp selected_event(filters, event_id) do
      case Audit.fetch_in_scope(filters, event_id, repo: repo()) do
        {:ok, event} -> {:ready, event}
        :error -> {:unavailable, nil}
      end
    end

    defp audit_filters(params) do
      Map.new(@filter_fields, fn field -> {field, blank_to_nil(params[field])} end)
    end

    defp empty_filters, do: Map.new(@filter_fields, &{&1, nil})

    defp audit_path(filters, page, event_id) do
      Selectors.audit_path([
        {"resource_type", filters["resource_type"]},
        {"resource_id", filters["resource_id"]},
        {"event_type", filters["event_type"]},
        {"page", if(page == 1, do: nil, else: page)},
        {"event", event_id}
      ])
    end

    defp positive_page(page) when is_integer(page) and page > 0, do: page

    defp positive_page(page) when is_binary(page) do
      case Integer.parse(page) do
        {parsed, ""} when parsed > 0 -> parsed
        _invalid -> 1
      end
    end

    defp positive_page(_page), do: 1

    defp empty_audit_page do
      %{
        total_count: 0,
        page: 1,
        page_size: 20,
        total_pages: 0,
        previous?: false,
        next?: false,
        previous_href: nil,
        next_href: nil
      }
    end

    defp empty_title([]), do: "No audit records recorded"
    defp empty_title(_filters), do: "No audit records match these filters"

    defp empty_description([]),
      do:
        "Recorded operator actions will appear here when evidence is available. Review another operator page, then return after an action is recorded."

    defp empty_description(_filters),
      do: "Remove a filter or clear all filters to widen the review."

    defp evidence_trigger_id(event_id), do: "audit-evidence-#{event_id}"

    defp selected_row?(nil, _row_id), do: false
    defp selected_row?(selected_id, row_id), do: to_string(selected_id) == to_string(row_id)

    defp detail_fallback_id(selected_id, rows) do
      if Enum.any?(rows, &selected_row?(selected_id, &1.id)),
        do: evidence_trigger_id(selected_id),
        else: "audit-records"
    end

    defp detail_target_href(:ready, %{target_href: target_href}), do: target_href
    defp detail_target_href(_state, _detail), do: nil

    defp blank_to_nil(""), do: nil
    defp blank_to_nil(value), do: value
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
