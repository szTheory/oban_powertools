if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.EngineOverviewLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.Cron.{Entry, Slot}
    alias ObanPowertools.Lifeline
    alias ObanPowertools.Limits.Resource
    alias ObanPowertools.Workflow.Workflow
    alias ObanPowertools.Web.LiveAuth

    @impl true
    def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(
               socket,
               :view_overview,
               %{type: :page, id: "overview"}
             ) do
        {:ok, assign_metrics(socket, dashboard_path)}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Smart Engine Overview</h1>
          <p class="text-sm text-zinc-600">
            Native Powertools surfaces stay narrow here. Generic job inspection lives in Oban Web.
          </p>
        </div>

        <div class="grid gap-4 md:grid-cols-3 xl:grid-cols-4">
          <.metric_card label="Limiter Resources" value={@metrics.resources} />
          <.metric_card label="Blocked Jobs" value={@metrics.blocked_jobs} />
          <.metric_card label="Paused Cron Entries" value={@metrics.paused_entries} />
          <.metric_card label="Missed Slots" value={@metrics.missed_slots} />
          <.metric_card label="Workflows" value={@metrics.workflows} />
          <.metric_card label="Lifeline Incidents" value={@metrics.lifeline_incidents} />
          <.metric_card label="Pending Repair Previews" value={@metrics.pending_previews} />
          <.metric_card label="Archived Repairs" value={@metrics.archived_repairs} />
        </div>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Next Steps</h2>
          <div class="mt-3 flex flex-wrap gap-3 text-sm">
            <.link navigate="/ops/jobs/lifeline" class="rounded bg-indigo-600 px-3 py-2 text-white">
              Review Lifeline Incidents
            </.link>
            <.link navigate="/ops/jobs/limiters" class="rounded bg-indigo-600 px-3 py-2 text-white">
              Inspect Job Blockers
            </.link>
            <.link navigate="/ops/jobs/cron" class="rounded border px-3 py-2">
              Review Cron State
            </.link>
            <.link navigate="/ops/jobs/audit" class="rounded border px-3 py-2">
              Review Audit Trail
            </.link>
            <.link navigate="/ops/jobs/workflows" class="rounded border px-3 py-2">
              Inspect Workflows
            </.link>
            <a href={@oban_jobs_path} class="rounded border px-3 py-2">Open Oban Web Jobs</a>
          </div>
        </div>
      </div>
      """
    end

    attr(:label, :string, required: true)
    attr(:value, :any, required: true)

    defp metric_card(assigns) do
      ~H"""
      <div class="rounded-lg border bg-white p-4">
        <p class="text-sm text-zinc-500"><%= @label %></p>
        <p class="mt-2 text-3xl font-semibold"><%= @value %></p>
      </div>
      """
    end

    defp assign_metrics(socket, dashboard_path) do
      repo = repo()

      metrics = %{
        resources: repo.aggregate(Resource, :count, :id),
        blocked_jobs: repo.aggregate(ObanPowertools.Explain, :count, :id),
        paused_entries:
          repo.aggregate(from(entry in Entry, where: not is_nil(entry.paused_at)), :count, :id),
        missed_slots:
          repo.aggregate(from(slot in Slot, where: slot.state == "skipped"), :count, :id),
        workflows: repo.aggregate(Workflow, :count, :id),
        lifeline_incidents: repo.aggregate(ObanPowertools.Lifeline.Incident, :count, :id),
        pending_previews: Lifeline.retention_status(repo).pending_previews,
        archived_repairs: Lifeline.retention_status(repo).archived_repairs
      }

      socket
      |> assign(:metrics, metrics)
      |> assign(:oban_jobs_path, build_dashboard_path(dashboard_path, "jobs"))
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)

    defp build_dashboard_path(base, page), do: Path.join([base, page])
  end
end
