if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.EngineOverviewLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, OverviewReadModel}

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
          <h1 class="text-2xl font-semibold">Unified /ops/jobs Control Plane</h1>
          <p class="text-sm text-zinc-600">
            <%= ControlPlanePresenter.native_banner() %> <%= ControlPlanePresenter.bridge_banner() %>
          </p>
        </div>

        <div class="rounded-lg border bg-slate-50 p-4">
          <h2 class="text-base font-semibold">Diagnosis-first overview</h2>
          <p class="mt-2 text-sm text-zinc-600">
            Each card answers what needs attention, why it matters, where to go next, and whether the next venue is Powertools-native or bridge-only.
          </p>
        </div>

        <div class="grid gap-4 xl:grid-cols-2">
          <div :for={bucket <- active_buckets(@overview_buckets)} class="rounded-lg border bg-white p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <h2 class="text-base font-semibold"><%= bucket.status %></h2>
                <p class="mt-1 text-2xl font-semibold"><%= bucket.count %></p>
              </div>
              <div class="space-y-1 text-right text-xs">
                <div class="rounded border px-2 py-1"><%= bucket.venue %></div>
                <div class="rounded border px-2 py-1"><%= bucket.posture %></div>
              </div>
            </div>

            <p class="mt-3 text-sm text-zinc-700"><%= bucket.diagnosis %></p>

            <div class="mt-4 space-y-3">
              <div :for={exemplar <- bucket.exemplars} class="rounded border bg-slate-50 p-3 text-sm">
                <div class="font-medium"><%= exemplar.label %></div>
                <div class="mt-1 text-zinc-600"><%= exemplar.fact %></div>
                <.link navigate={exemplar.path} class="mt-2 inline-block text-indigo-700 underline">
                  Review exemplar
                </.link>
              </div>
            </div>

            <div class="mt-4">
              <.link navigate={bucket.next_step_path} class={cta_class(bucket)}>
                <%= bucket.next_step_label %>
              </.link>
            </div>
          </div>

          <div :for={bucket <- resolved_buckets(@overview_buckets)} class="rounded-lg border bg-emerald-50 p-4">
            <div class="flex items-start justify-between gap-3">
              <div>
                <h2 class="text-base font-semibold"><%= bucket.status %></h2>
                <p class="mt-1 text-2xl font-semibold"><%= bucket.count %></p>
              </div>
              <div class="space-y-1 text-right text-xs">
                <div class="rounded border px-2 py-1"><%= bucket.venue %></div>
                <div class="rounded border px-2 py-1"><%= bucket.posture %></div>
              </div>
            </div>

            <p class="mt-3 text-sm text-zinc-700"><%= bucket.diagnosis %></p>

            <div class="mt-4 space-y-3">
              <div :for={exemplar <- bucket.exemplars} class="rounded border bg-white p-3 text-sm">
                <div class="font-medium"><%= exemplar.label %></div>
                <div class="mt-1 text-zinc-600"><%= exemplar.fact %></div>
              </div>
            </div>

            <div class="mt-4">
              <.link navigate={bucket.next_step_path} class="rounded border px-3 py-2 text-sm">
                <%= bucket.next_step_label %>
              </.link>
            </div>
          </div>
        </div>
      </div>
      """
    end

    defp assign_metrics(socket, dashboard_path) do
      socket
      |> assign(
        :overview_buckets,
        OverviewReadModel.build(repo: repo(), dashboard_path: dashboard_path)
      )
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)

    defp active_buckets(buckets) do
      Enum.reject(buckets, &(&1.status == "Resolved Recently"))
    end

    defp resolved_buckets(buckets) do
      Enum.filter(buckets, &(&1.status == "Resolved Recently"))
    end

    defp cta_class(%{status: "Bridge-only Follow-up"}),
      do: "rounded border px-3 py-2 text-sm"

    defp cta_class(_bucket), do: "rounded bg-indigo-600 px-3 py-2 text-sm text-white"
  end
end
