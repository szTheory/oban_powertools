if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LimitersLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.Explain
    alias ObanPowertools.Limits.{Resource, State}
    alias ObanPowertools.Web.LiveAuth

    @impl true
    def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(
               socket,
               :view_limiters,
               %{type: :page, id: "limiters"}
             ) do
        {:ok,
         socket
         |> assign(:oban_dashboard_path, dashboard_path)
         |> assign(:selected_resource, nil)
         |> assign(:detail, nil)
         |> load_resources()}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_event("inspect", %{"resource" => name}, socket) do
      snapshot =
        repo().one(
          from(event in Explain,
            where: event.scope_id == ^name,
            order_by: [desc: event.captured_at],
            limit: 1
          )
        )

      detail =
        case snapshot do
          nil ->
            %{snapshot: nil, live_now: [], oban_job_path: nil}

          snapshot ->
            explanation = Explain.explain_snapshot(snapshot, repo: repo())

            %{
              snapshot: snapshot,
              live_now: explanation.live_now,
              oban_job_path: build_job_path(socket.assigns.oban_dashboard_path, snapshot.job_id)
            }
        end

      {:noreply,
       socket
       |> assign(:selected_resource, name)
       |> assign(:detail, detail)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Limiters</h1>
          <p class="text-sm text-zinc-600">
            Saturation and cooldown stay visible in the table. Blocker evidence stays explanation-first.
          </p>
        </div>

        <div :if={@resources == []} class="rounded-lg border bg-white p-6">
          <h2 class="text-base font-semibold">No smart engine resources yet</h2>
          <p class="mt-2 text-sm text-zinc-600">
            Sync a code-managed cron entry or add a limiter binding to see live engine state here.
          </p>
        </div>

        <div :if={@resources != []} class="grid gap-6 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
          <div class="overflow-hidden rounded-lg border bg-white">
            <table class="min-w-full divide-y">
              <thead class="bg-slate-50 text-left text-sm">
                <tr>
                  <th class="px-4 py-3 font-medium">Limiter</th>
                  <th class="px-4 py-3 font-medium">Scope</th>
                  <th class="px-4 py-3 font-medium">State</th>
                  <th class="px-4 py-3 font-medium">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y text-sm">
                <tr :for={resource <- @resources}>
                  <td class="px-4 py-3 font-medium"><%= resource.name %></td>
                  <td class="px-4 py-3"><%= resource.scope_kind %></td>
                  <td class="px-4 py-3">
                    <%= if resource.cooling_down? do %>
                      Cooling Down
                    <% else %>
                      <%= resource.saturation_label %>
                    <% end %>
                  </td>
                  <td class="px-4 py-3">
                    <button
                      type="button"
                      phx-click="inspect"
                      phx-value-resource={resource.name}
                      class="rounded bg-indigo-600 px-3 py-2 text-white"
                    >
                      Inspect Job Blockers
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="rounded-lg border bg-white p-4">
            <%= if @detail do %>
              <h2 class="text-base font-semibold"><%= @selected_resource %></h2>

              <div class="mt-4 space-y-4">
                <div>
                  <div class="flex gap-2 text-sm font-medium">
                    <span class="rounded bg-indigo-600 px-2 py-1 text-white">Live Now</span>
                  </div>
                  <%= if @detail.live_now == [] do %>
                    <p class="mt-2 text-sm text-zinc-600">Runnable</p>
                  <% else %>
                    <ul class="mt-2 space-y-2 text-sm">
                      <li :for={blocker <- @detail.live_now}>
                        <strong><%= blocker.code %></strong>: <%= blocker.summary %>
                      </li>
                    </ul>
                  <% end %>
                </div>

                <div>
                  <div class="flex gap-2 text-sm font-medium">
                    <span class="rounded border px-2 py-1">Snapshot at Block Start</span>
                  </div>
                  <%= if @detail.snapshot do %>
                    <ul class="mt-2 space-y-2 text-sm">
                      <li :for={blocker <- blocker_snapshot(@detail.snapshot)}>
                        <strong><%= blocker["code"] %></strong>: <%= blocker["summary"] %>
                      </li>
                    </ul>
                    <p class="mt-3 text-xs text-zinc-500">
                      Captured <%= format_dt(@detail.snapshot.captured_at) %>
                    </p>
                    <a :if={@detail.oban_job_path} href={@detail.oban_job_path} class="mt-3 inline-block text-sm text-indigo-700 underline">
                      Open generic job inspection in Oban Web
                    </a>
                  <% else %>
                    <p class="mt-2 text-sm text-zinc-600">No blocked-job snapshot is available for this limiter yet.</p>
                  <% end %>
                </div>
              </div>
            <% else %>
              <p class="text-sm text-zinc-600">
                Select a limiter row to compare Live Now against Snapshot at Block Start.
              </p>
            <% end %>
          </div>
        </div>
      </div>
      """
    end

    defp load_resources(socket) do
      resources =
        for resource <- repo().all(from(resource in Resource, order_by: [asc: resource.name])) do
          states = repo().all(from(state in State, where: state.resource_id == ^resource.id))

          cooling_down? =
            Enum.any?(states, fn state ->
              match?(%DateTime{}, state.cooldown_until) and
                DateTime.compare(state.cooldown_until, DateTime.utc_now()) == :gt
            end)

          saturation_label =
            if Enum.any?(states, &(&1.tokens_used >= resource.bucket_capacity)) do
              "Blocked"
            else
              "Runnable"
            end

          Map.merge(resource, %{cooling_down?: cooling_down?, saturation_label: saturation_label})
        end

      assign(socket, :resources, resources)
    end

    defp blocker_snapshot(snapshot), do: get_in(snapshot.details, ["live_now"]) || []
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
    defp build_job_path(_base, nil), do: nil
    defp build_job_path(base, job_id), do: Path.join([base, "jobs", Integer.to_string(job_id)])
    defp format_dt(nil), do: "unknown"
    defp format_dt(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")
  end
end
