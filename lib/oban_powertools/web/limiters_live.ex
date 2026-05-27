if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LimitersLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.{ControlPlane, Explain}
    alias ObanPowertools.Forensics.LimiterHistory
    alias ObanPowertools.Limits.{Resource, State}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth}

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
         |> assign(:read_only?, true)
         |> load_resources()}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      {:noreply,
       socket
       |> load_resources()
       |> load_selection(Map.get(params, "resource"))}
    end

    @impl true
    def handle_event("inspect", %{"resource" => name}, socket) do
      {:noreply, push_patch(socket, to: limiter_path(name))}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Limiters</h1>
          <p class="text-sm text-zinc-600">
            <%= ControlPlanePresenter.native_banner() %> Saturation and cooldown stay visible beneath the shared status layer.
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
                  <td class="px-4 py-3"><%= ControlPlanePresenter.status_label(ControlPlane.limiter_status(resource)) %></td>
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
                    <span class="rounded border px-2 py-1"><%= ControlPlanePresenter.ownership_badge(:powertools_native) %></span>
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
                      Open generic job inspection in Oban Web bridge
                    </a>
                  <% else %>
                    <p class="mt-2 text-sm text-zinc-600">No blocked-job snapshot is available for this limiter yet.</p>
                  <% end %>
                </div>

                <div :if={@history_summary}>
                  <div class="flex items-center justify-between gap-3 text-sm font-medium">
                    <span class="rounded border px-2 py-1">History Summary</span>
                    <a
                      :if={can_view_forensics?(@current_actor)}
                      href={forensics_path(@selected_resource)}
                      class="text-sm text-indigo-700 underline"
                    >
                      Open forensic timeline
                    </a>
                  </div>
                  <p class="mt-2 text-sm text-zinc-600"><%= @history_summary.detail %></p>
                  <p class="mt-1 text-xs text-zinc-500">
                    <%= ControlPlanePresenter.forensic_completeness_label(@history_summary.completeness.state) %>
                  </p>

                  <div :if={@history_summary.episodes != []} class="mt-3 space-y-2">
                    <div :for={episode <- @history_summary.episodes} class="rounded border bg-slate-50 p-3 text-sm">
                      <p class="font-medium"><%= episode.label %></p>
                      <p :if={episode.notes} class="mt-1 text-zinc-600"><%= episode.notes %></p>
                    </div>
                  </div>

                  <div class="mt-3 rounded border bg-white p-3 text-sm">
                    <h4 class="font-semibold">Open runbook entry</h4>
                    <p class="mt-1 text-zinc-600"><%= @history_summary.detail %></p>
                    <p class="mt-2 text-xs text-amber-700">
                      Caution: partial evidence and history unavailable states stay diagnostic only until retained limiter history proves what happened.
                    </p>
                    <ol class="mt-3 space-y-2">
                      <li>
                        1. Return to limiter diagnosis —
                        <span
                          data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("Powertools-native")}
                          data-runbook-variant={follow_up_variant("Powertools-native")}
                          class={follow_up_row_class("Powertools-native")}
                        >
                          <%= ControlPlanePresenter.runbook_ownership_label("Powertools-native") %>
                        </span>
                      </li>
                      <li>
                        2. Inspect audit trail —
                        <span
                          data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("Oban Web bridge")}
                          data-runbook-variant={follow_up_variant("Oban Web bridge")}
                          class={follow_up_row_class("Oban Web bridge")}
                        >
                          <%= ControlPlanePresenter.runbook_ownership_label("Oban Web bridge") %>
                        </span>
                      </li>
                      <li>
                        3. Coordinate capacity policy follow-up —
                        <span
                          data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("host-owned follow-up")}
                          data-runbook-variant={follow_up_variant("host-owned follow-up")}
                          class={follow_up_row_class("host-owned follow-up")}
                        >
                          <%= ControlPlanePresenter.runbook_ownership_label("host-owned follow-up") %>
                        </span>
                      </li>
                    </ol>
                    <a
                      :if={can_view_forensics?(@current_actor)}
                      href={forensics_path(@selected_resource)}
                      class="mt-3 inline-block text-sm text-indigo-700 underline"
                    >
                      Evidence link
                    </a>
                  </div>
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
      assign(socket, :resources, resources())
      |> assign(
        :read_only?,
        not LiveAuth.authorized?(socket.assigns.current_actor, :preview_repair, %{
          type: :job,
          id: "selection"
        })
      )
    end

    defp load_selection(socket, nil) do
      socket
      |> assign(:selected_resource, nil)
      |> assign(:detail, nil)
      |> assign(:history_summary, nil)
    end

    defp load_selection(socket, name) do
      socket
      |> assign(:selected_resource, name)
      |> assign(:detail, load_detail(name, socket.assigns.oban_dashboard_path))
      |> assign(:history_summary, LimiterHistory.summary(repo(), name))
    end

    defp resources do
      for resource <- repo().all(from(resource in Resource, order_by: [asc: resource.name])) do
        states = repo().all(from(state in State, where: state.resource_id == ^resource.id))

        cooling_down? =
          Enum.any?(states, fn state ->
            match?(%DateTime{}, state.cooldown_until) and
              DateTime.compare(state.cooldown_until, DateTime.utc_now()) == :gt
          end)

        saturation_label =
          if Enum.any?(states, &(&1.tokens_used >= resource.bucket_capacity)) do
            ControlPlanePresenter.status_label(:blocked)
          else
            ControlPlanePresenter.status_label(:runnable)
          end

        Map.merge(resource, %{cooling_down?: cooling_down?, saturation_label: saturation_label})
      end
    end

    defp load_detail(name, dashboard_path) do
      snapshot =
        repo().one(
          from(event in Explain,
            where: event.scope_id == ^name,
            order_by: [desc: event.captured_at],
            limit: 1
          )
        )

      case snapshot do
        nil ->
          %{snapshot: nil, live_now: [], oban_job_path: nil}

        snapshot ->
          explanation = Explain.explain_snapshot(snapshot, repo: repo())

          %{
            snapshot: snapshot,
            live_now: explanation.live_now,
            oban_job_path: build_job_path(dashboard_path, snapshot.job_id)
          }
      end
    end

    defp blocker_snapshot(snapshot), do: get_in(snapshot.details, ["live_now"]) || []
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
    defp build_job_path(_base, nil), do: nil
    defp build_job_path(base, job_id), do: Path.join([base, "jobs", Integer.to_string(job_id)])
    defp limiter_path(name), do: "/ops/jobs/limiters?resource=#{URI.encode_www_form(name)}"

    defp forensics_path(name),
      do: "/ops/jobs/forensics?resource_type=limiter&resource_id=#{URI.encode_www_form(name)}"

    defp follow_up_variant(path_or_venue) do
      path_or_venue
      |> ControlPlanePresenter.follow_up_render_variant()
      |> Atom.to_string()
    end

    defp follow_up_row_class(path_or_venue) do
      case ControlPlanePresenter.follow_up_render_variant(path_or_venue) do
        :native_primary -> "rounded border border-indigo-300 bg-indigo-100 px-2 py-1 font-medium"
        :bridge_guidance -> "rounded border border-slate-300 bg-white px-2 py-1"
        :host_guidance -> "rounded border border-amber-300 bg-amber-100 px-2 py-1"
      end
    end

    defp can_view_forensics?(actor),
      do: LiveAuth.authorized?(actor, :view_forensics, %{type: :page, id: "forensics"})

    defp format_dt(nil), do: "unknown"
    defp format_dt(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")
  end
end
