if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.AuditLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{Audit, DisplayPolicy, Lifeline}
    alias ObanPowertools.Web.LiveAuth

    @impl true
    def mount(_params, _session, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_audit, %{type: :page, id: "audit"}) do
        :ok = DisplayPolicy.assert_configured!()

        {:ok,
         socket
         |> assign(:events, Audit.list_all(repo: repo()))
         |> assign(:retention, Lifeline.retention_status(repo()))}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Audit</h1>
          <p class="text-sm text-zinc-600">
            Limiter, cron, workflow, and lifeline interventions converge into one operator trail here.
          </p>
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
                <th class="px-4 py-3 font-medium">Action</th>
                <th class="px-4 py-3 font-medium">Resource</th>
                <th class="px-4 py-3 font-medium">Actor</th>
                <th class="px-4 py-3 font-medium">Reason</th>
                <th class="px-4 py-3 font-medium">Event Time</th>
              </tr>
            </thead>
            <tbody class="divide-y text-sm">
              <tr :for={event <- @events}>
                <td class="px-4 py-3 font-medium"><%= event.action %></td>
                <td class="px-4 py-3"><%= event.resource %></td>
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
      "#{Phoenix.Naming.humanize(run.status)} at #{format_timestamp(run.finished_at || run.started_at)}"
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

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
