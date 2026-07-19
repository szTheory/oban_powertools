if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.AuditLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{Audit, DisplayPolicy, Lifeline}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

    @filter_fields ~w[resource_type resource_id event_type]

    @impl true
    def mount(_params, _session, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_audit, %{type: :page, id: "audit"}) do
        :ok = DisplayPolicy.assert_configured!()

        {:ok,
         socket
         |> assign(:events, [])
         |> assign(:filters, %{})
         |> assign(:audit_page, empty_audit_page())
         |> assign(:selected_event_id, nil)
         |> assign(:selected_event, nil)
         |> assign(:detail_state, :empty)
         |> assign(:retention, Lifeline.retention_status(repo()))}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      filters = audit_filters(params)
      audit_page = Audit.page(filters, repo: repo(), page: positive_page(params["page"]))
      selected_event_id = blank_to_nil(params["event"])
      {detail_state, selected_event} = selected_event(filters, selected_event_id)

      {:noreply,
       socket
       |> assign(:filters, filters)
       |> assign(:events, audit_page.events)
       |> assign(:audit_page, audit_page)
       |> assign(:selected_event_id, selected_event_id)
       |> assign(:selected_event, selected_event)
       |> assign(:detail_state, detail_state)}
    end

    @impl true
    def handle_event("apply_filters", %{"filters" => submitted_filters}, socket) do
      filters = audit_filters(submitted_filters)

      {:noreply,
       push_patch(socket,
         to: audit_path(filters, 1, nil)
       )}
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
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Audit</h1>
          <p class="text-sm text-zinc-600">
            Read-only audit evidence converges here across Powertools-native surfaces while the Oban Web bridge stays Inspection only.
          </p>
        </div>

        <p class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <%= LiveAuth.page_read_only_banner(:audit) %>
        </p>

        <div :if={active_filters?(@filters)} class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Scoped Audit Filter</h2>
          <p class="mt-2 text-sm text-zinc-600"><%= filter_summary(@filters) %></p>
        </div>

        <div class="rounded-lg border bg-slate-50 p-4">
          <h2 class="text-base font-semibold">Archive Activity</h2>
          <p class="mt-2 text-sm text-zinc-600">
            Last Archive + Prune Run:
            <%= archive_summary(@retention.last_run) %>
          </p>
          <div class="mt-3 grid gap-3 sm:grid-cols-3 text-sm">
            <div class="rounded border bg-white p-3">
              <div class="text-zinc-500">Pending Repair Previews</div>
              <div class="mt-1 text-lg font-semibold"><%= @retention.pending_previews %></div>
            </div>
            <div class="rounded border bg-white p-3">
              <div class="text-zinc-500">Archived Repairs</div>
              <div class="mt-1 text-lg font-semibold"><%= @retention.archived_repairs %></div>
            </div>
            <div class="rounded border bg-white p-3">
              <div class="text-zinc-500">Heartbeat Samples</div>
              <div class="mt-1 text-lg font-semibold"><%= @retention.heartbeat_samples %></div>
            </div>
          </div>
        </div>

        <div class="overflow-hidden rounded-lg border bg-white">
          <table class="min-w-full divide-y">
            <thead class="bg-slate-50 text-left text-sm">
              <tr>
                <th class="px-4 py-3 font-medium">Event Type</th>
                <th class="px-4 py-3 font-medium">Resource Identity</th>
                <th class="px-4 py-3 font-medium">Actor</th>
                <th class="px-4 py-3 font-medium">Reason</th>
                <th class="px-4 py-3 font-medium">Event Time</th>
              </tr>
            </thead>
            <tbody class="divide-y text-sm">
              <tr :for={event <- @events}>
                <td class="px-4 py-3 font-medium"><%= ControlPlanePresenter.audit_event_label(event) %></td>
                <td class="px-4 py-3">
                  <% resource = ObanPowertools.Audit.event_resource_identity(event) %>
                  <%= if resource.type == "job" and resource.id do %>
                    <.link navigate={ObanPowertools.Web.Selectors.job_detail_path(resource.id)} class="text-indigo-600 hover:underline">
                      <%= ControlPlanePresenter.audit_resource_label(event) %>
                    </.link>
                  <% else %>
                    <%= ControlPlanePresenter.audit_resource_label(event) %>
                  <% end %>
                </td>
                <td class="px-4 py-3"><%= actor_label(event) %></td>
                <td class="px-4 py-3"><%= reason_label(event) %></td>
                <td class="px-4 py-3">
                  <div><%= relative_time(event.inserted_at) %></div>
                  <div class="text-zinc-500"><%= format_timestamp(event.inserted_at) %></div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      """
    end

    defp archive_summary(nil), do: "No archive or prune runs recorded yet."

    defp archive_summary(run) do
      "#{ObanPowertools.Web.ControlPlanePresenter.humanize(run.status)} at #{format_timestamp(run.finished_at || run.started_at)}"
    end

    defp relative_time(nil), do: "Unknown"

    defp relative_time(%NaiveDateTime{} = timestamp) do
      timestamp
      |> DateTime.from_naive!("Etc/UTC")
      |> relative_time()
    end

    defp relative_time(%DateTime{} = timestamp) do
      seconds = DateTime.diff(DateTime.utc_now(), timestamp, :second)

      cond do
        seconds < 60 -> "#{seconds}s ago"
        seconds < 3_600 -> "#{div(seconds, 60)}m ago"
        seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
        true -> "#{div(seconds, 86_400)}d ago"
      end
    end

    defp format_timestamp(nil), do: "Unknown"

    defp format_timestamp(%NaiveDateTime{} = timestamp) do
      timestamp
      |> DateTime.from_naive!("Etc/UTC")
      |> Calendar.strftime("%Y-%m-%d %H:%M:%S UTC")
    end

    defp format_timestamp(%DateTime{} = timestamp) do
      Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S UTC")
    end

    defp actor_label(event) do
      event
      |> Audit.event_principal()
      |> DisplayPolicy.actor_label(%{surface: :audit, section: :table, event: event.action})
    end

    defp reason_label(event) do
      event
      |> Audit.event_reason()
      |> DisplayPolicy.reason(%{surface: :audit, section: :table, event: event.action})
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
        events: [],
        total_count: 0,
        page: 1,
        page_size: 20,
        total_pages: 0,
        previous?: false,
        next?: false
      }
    end

    defp active_filters?(filters),
      do: Enum.any?(filters, fn {_key, value} -> value not in [nil, ""] end)

    defp filter_summary(filters) do
      [
        filters["resource_type"] && "resource_type=#{filters["resource_type"]}",
        filters["resource_id"] && "resource_id=#{filters["resource_id"]}",
        filters["event_type"] && "event_type=#{filters["event_type"]}"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(", ")
    end

    defp blank_to_nil(""), do: nil
    defp blank_to_nil(value), do: value
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
