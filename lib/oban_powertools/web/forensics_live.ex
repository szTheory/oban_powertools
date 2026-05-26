if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.ForensicsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.Forensics
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth}

    @allowed_params ~w(resource_type resource_id workflow_id step incident_fingerprint view)

    @impl true
    def mount(_params, _session, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_forensics, %{type: :page, id: "forensics"}) do
        {:ok,
         socket
         |> assign(:bundle, Forensics.bundle(%{}, repo: repo()))
         |> assign(:selectors, %{})}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      selectors =
        params
        |> Map.take(@allowed_params)
        |> Forensics.selectors()

      {:noreply,
       socket
       |> assign(:selectors, selectors)
       |> assign(:bundle, Forensics.bundle(selectors, repo: repo()))}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Forensics</h1>
          <p class="text-sm text-zinc-600">
            One diagnosis-first forensic story for Powertools-native workflow and Lifeline investigations. Limiter and cron context remains supporting evidence, while audit follow-up stays Inspection only.
          </p>
        </div>

        <p class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <%= LiveAuth.page_read_only_banner(:forensics) %>
        </p>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Diagnosis Summary</h2>
          <p class="mt-2 text-sm text-zinc-600">
            Subject: <%= @bundle.subject.label %> (<%= @bundle.subject.entry_surface || "unknown" %>)
          </p>
          <p class="mt-1 text-sm text-zinc-600">
            Current diagnosis: <%= @bundle.diagnosis_summary.current %>
          </p>
          <p class="mt-1 text-sm text-zinc-600"><%= @bundle.diagnosis_summary.detail %></p>
        </div>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Timeline</h2>
          <%= if @bundle.chronology == [] do %>
            <p class="mt-2 text-sm text-zinc-600">
              No chronology evidence is available yet. <%= completeness_details(@bundle.completeness) %>
            </p>
          <% else %>
            <div class="mt-3 space-y-3">
              <div :for={item <- @bundle.chronology} class="rounded border bg-slate-50 p-3">
                <div class="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <p class="font-medium"><%= item.label %></p>
                    <p class="text-xs text-zinc-500">
                      <%= item.source_family %> • <%= ControlPlanePresenter.forensic_provenance_label(item.strength) %>
                    </p>
                  </div>
                  <a
                    :if={item.resource_type && item.resource_id}
                    href={audit_follow_up_path(item)}
                    class="text-sm text-indigo-700 underline"
                  >
                    Audit follow-up
                  </a>
                </div>
                <p class="mt-2 text-sm text-zinc-600"><%= item.notes || "No additional notes." %></p>
                <p class="mt-1 text-xs text-zinc-500">
                  <%= format_timestamp(item.occurred_at) %> • <%= item.resource_type %>:<%= item.resource_id %>
                </p>
              </div>
            </div>
          <% end %>
        </div>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Related Evidence</h2>
          <div class="mt-3 space-y-3">
            <div :for={item <- @bundle.related_evidence} class="rounded border bg-slate-50 p-3">
              <p class="font-medium"><%= item.title %></p>
              <p class="mt-1 text-sm text-zinc-600"><%= item.summary %></p>
              <p class="mt-1 text-xs text-zinc-500">
                <%= ControlPlanePresenter.forensic_provenance_label(item.provenance) %>
              </p>
            </div>
          </div>
        </div>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Linked Resources</h2>
          <div class="mt-3 space-y-2 text-sm">
            <div :for={item <- @bundle.linked_resources}>
              <a href={item.path} class="text-indigo-700 underline"><%= item.label %></a>
              <span class="text-zinc-500"> — <%= item.venue %></span>
            </div>
          </div>
        </div>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Legal Next Paths</h2>
          <div class="mt-3 space-y-2 text-sm">
            <div :for={item <- @bundle.legal_next_paths}>
              <a href={item.path} class="text-indigo-700 underline"><%= item.label %></a>
              <span class="text-zinc-500"> — <%= item.venue %></span>
            </div>
          </div>
        </div>

        <div class="rounded-lg border bg-white p-4">
          <h2 class="text-base font-semibold">Evidence Completeness</h2>
          <p class="mt-2 text-sm text-zinc-600">
            <%= ControlPlanePresenter.forensic_completeness_label(@bundle.completeness.state) %>
          </p>
          <p class="mt-1 text-sm text-zinc-600"><%= completeness_details(@bundle.completeness) %></p>
        </div>

        <div class="rounded-lg border bg-slate-50 p-4 text-xs text-zinc-500">
          Selectors:
          <%= @selectors |> Enum.reject(fn {_key, value} -> is_nil(value) end) |> Enum.map_join(", ", fn {key, value} -> "#{key}=#{value}" end) %>
        </div>
      </div>
      """
    end

    defp audit_follow_up_path(item) do
      [
        {"resource_type", item.resource_type},
        {"resource_id", item.resource_id},
        {"event_type", item.event_type}
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
      |> URI.encode_query()
      |> then(&"/ops/jobs/audit?#{&1}")
    end

    defp format_timestamp(nil), do: "Unknown"

    defp format_timestamp(%NaiveDateTime{} = timestamp) do
      timestamp
      |> DateTime.from_naive!("Etc/UTC")
      |> format_timestamp()
    end

    defp format_timestamp(%DateTime{} = timestamp) do
      Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S UTC")
    end

    defp completeness_details(%{details: details}), do: details
    defp completeness_details(_), do: "No completeness details available."

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
