if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.AuditLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{Audit, DisplayPolicy, Lifeline}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

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
      <section id="audit-page" class="space-y-6 p-6">
        <header>
          <h1 class="text-2xl font-semibold">Audit</h1>
          <p class="text-sm text-zinc-600">
            Review recorded operator actions and the evidence available for each record.
          </p>
        </header>

        <div class="rounded-lg border bg-white px-4 py-3 text-sm text-zinc-700">
          <p><%= LiveAuth.page_read_only_banner(:audit) %></p>
          <p class="mt-2">
            Powertools-native pages keep preview, reason, and local audit evidence close to the acted-on resource. The Oban Web bridge remains Inspection only and read-only.
          </p>
        </div>

        <section id="audit-retention" class="rounded-lg border bg-slate-50 p-4">
          <h2 class="text-base font-semibold"><%= @retention_summary.title %></h2>
          <p class="mt-2 text-sm text-zinc-600"><%= @retention_summary.description %></p>
          <p class="mt-2 text-sm text-zinc-600"><%= @retention_summary.last_run %></p>
        </section>

        <section id="audit-filters" class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Filter audit records</h2>
          <.form for={@filter_form} phx-submit="apply_filters" class="mt-3 space-y-3">
            <div class="grid gap-3 sm:grid-cols-3">
              <label>
                <span>Resource type</span>
                <input name="filters[resource_type]" value={@filter_form[:resource_type].value} />
              </label>
              <label>
                <span>Resource ID</span>
                <input name="filters[resource_id]" value={@filter_form[:resource_id].value} />
              </label>
              <label>
                <span>Event type</span>
                <input name="filters[event_type]" value={@filter_form[:event_type].value} />
              </label>
            </div>
            <button type="submit">Apply filters</button>
          </.form>

          <div :if={@active_filters != []} class="mt-3">
            <span :for={filter <- @active_filters} id={filter.id} class="mr-3">
              <span><%= filter.label %>: <%= filter.value %></span>
              <.link patch={filter.remove_href} aria-label={filter.remove_label}>Remove</.link>
            </span>
            <.link patch={Selectors.audit_path([])}>Clear filters</.link>
          </div>

          <p class="mt-3 text-sm text-zinc-600"><%= @result_summary %></p>
        </section>

        <div class="overflow-hidden rounded-lg border bg-white">
          <table id="audit-records" class="obpt-data-table min-w-full divide-y">
            <caption>Audit records</caption>
            <thead>
              <tr>
                <th>Event</th>
                <th>Target</th>
                <th>Actor</th>
                <th>Reason</th>
                <th>Recorded at</th>
                <th><span class="sr-only">Evidence</span></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={row <- @event_rows} id={"audit-record-#{row.id}"}>
                <td><%= row.event_label %></td>
                <td>
                  <.link :if={row.target_href} navigate={row.target_href}><%= row.target_label %></.link>
                  <span :if={!row.target_href}><%= row.target_label %></span>
                </td>
                <td><%= row.actor %></td>
                <td><%= row.reason_summary %></td>
                <td><time datetime={row.recorded_datetime}><%= row.recorded_at %></time></td>
                <td>
                  <button
                    type="button"
                    phx-click="select_event"
                    phx-value-event={row.id}
                    aria-label={row.evidence_label}
                  >
                    View evidence
                  </button>
                </td>
              </tr>
            </tbody>
          </table>

          <div :if={@event_rows == []} class="p-4">
            <h2><%= empty_title(@active_filters) %></h2>
            <p><%= empty_description(@active_filters) %></p>
          </div>
        </div>

        <nav aria-label="Audit pagination" class="flex items-center justify-between">
          <.link :if={@audit_page.previous_href} patch={@audit_page.previous_href}>Previous</.link>
          <span :if={!@audit_page.previous_href}>Previous</span>
          <.link :if={@audit_page.next_href} patch={@audit_page.next_href}>Next</.link>
          <span :if={!@audit_page.next_href}>Next</span>
        </nav>

        <aside
          :if={@detail_state != :empty}
          id="audit-detail"
          data-obpt-detail-state={@detail_state}
          class="rounded-lg border bg-white p-4"
        >
          <button type="button" phx-click="close_detail">Close evidence</button>

          <article :if={@detail_state == :ready} id={"audit-entry-#{@selected_event_id}"}>
            <h2>Audit evidence</h2>
            <p><%= @selected_detail.sentence %></p>
            <dl>
              <dt>Outcome</dt><dd><%= @selected_detail.outcome %></dd>
              <dt>Actor</dt><dd><%= @selected_detail.actor %></dd>
              <dt>Action</dt><dd><%= @selected_detail.action %></dd>
              <dt>Target</dt>
              <dd>
                <.link :if={@selected_detail.target_href} navigate={@selected_detail.target_href}>
                  <%= @selected_detail.target %>
                </.link>
                <span :if={!@selected_detail.target_href}><%= @selected_detail.target %></span>
              </dd>
              <dt>Reason</dt><dd><%= @selected_detail.reason %></dd>
              <dt>Source</dt><dd><%= @selected_detail.source %></dd>
              <dt>Correlation</dt><dd><%= @selected_detail.correlation %></dd>
              <dt><%= @selected_detail.recorded_at_label %></dt>
              <dd>
                <time datetime={@selected_detail.occurred_datetime}>
                  <%= @selected_detail.occurred_at %>
                </time>
              </dd>
            </dl>
            <pre :if={@selected_detail.changes}><%= inspect(@selected_detail.changes) %></pre>
            <pre :if={@selected_detail.evidence}><%= inspect(@selected_detail.evidence) %></pre>
          </article>

          <div :if={@detail_state == :unavailable}>
            <h2>Audit evidence is unavailable</h2>
            <p>The selected evidence could not be loaded for this review scope.</p>
          </div>
        </aside>
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
      do: "Recorded operator actions will appear here when evidence is available."

    defp empty_description(_filters),
      do: "Remove a filter or clear all filters to widen the review."

    defp blank_to_nil(""), do: nil
    defp blank_to_nil(value), do: value
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
