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
          <%= if @bundle[:runbook_entry] do %>
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 class="text-base font-semibold"><%= @bundle.runbook_entry.title %></h2>
                <p class="mt-1 text-xs text-zinc-500">Advisory runbook guidance from the current evidence bundle.</p>
              </div>
              <a
                :if={@bundle.runbook_entry.evidence_path}
                href={@bundle.runbook_entry.evidence_path}
                class="rounded border border-indigo-200 px-3 py-2 text-sm text-indigo-700"
              >
                Evidence link
              </a>
            </div>

            <div class="mt-4 grid gap-4 md:grid-cols-2">
              <div class="rounded border bg-slate-50 p-3">
                <h3 class="text-sm font-semibold">Diagnosis state</h3>
                <p class="mt-1 text-sm text-zinc-600"><%= @bundle.runbook_entry.diagnosis_state %></p>
              </div>

              <div class="rounded border bg-slate-50 p-3">
                <h3 class="text-sm font-semibold">Why it matters now</h3>
                <p class="mt-1 text-sm text-zinc-600"><%= @bundle.runbook_entry.why_now %></p>
              </div>
            </div>

            <div class="mt-4">
              <h3 class="text-sm font-semibold">Prerequisites</h3>
              <div class="mt-2 space-y-2">
                <div :for={item <- @bundle.runbook_entry.prerequisites} class="rounded border bg-slate-50 p-3">
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="font-medium"><%= item.label %></span>
                    <span class="rounded border px-2 py-1 text-xs text-zinc-600"><%= item.state %></span>
                  </div>
                  <p class="mt-1 text-sm text-zinc-600"><%= item.detail %></p>
                </div>
              </div>
            </div>

            <div class="mt-4">
              <h3 class="text-sm font-semibold">Cautions</h3>
              <div class="mt-2 space-y-2">
                <div :for={item <- @bundle.runbook_entry.cautions} class={caution_class(item)}>
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="font-medium"><%= item.label %></span>
                    <span class="rounded border px-2 py-1 text-xs"><%= item.severity %></span>
                  </div>
                  <p class="mt-1 text-sm"><%= item.detail %></p>
                </div>
              </div>
            </div>

            <div class="mt-4">
              <h3 class="text-sm font-semibold">Recommended order</h3>
              <div class="mt-2 space-y-2">
                <div
                  :for={item <- @bundle.runbook_entry.ordered_next_paths}
                  data-runbook-ownership={item.ownership}
                  class={runbook_path_class(item)}
                >
                  <div class="flex flex-wrap items-center gap-2">
                    <span class="rounded border px-2 py-1 text-xs"><%= item.ownership %></span>
                    <span class="text-xs text-zinc-500"><%= item.venue %></span>
                    <span class="text-xs text-zinc-500"><%= item.intent %></span>
                  </div>
                  <div class="mt-2 flex flex-wrap items-center gap-3">
                    <span class="text-sm font-medium"><%= item.order %>. <%= item.label %></span>
                    <a :if={item.path} href={item.path} class={runbook_path_link_class(item)}>
                      Open path
                    </a>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-4">
              <h3 class="text-sm font-semibold">Unsupported boundaries</h3>
              <div class="mt-2 space-y-2">
                <p :for={boundary <- @bundle.runbook_entry.unsupported_boundaries} class="rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
                  <%= boundary %>
                </p>
              </div>
            </div>

            <div class="mt-4 rounded border bg-slate-50 p-3">
              <h3 class="text-sm font-semibold">Evidence completeness</h3>
              <p class="mt-1 text-sm text-zinc-600">
                <%= ControlPlanePresenter.forensic_completeness_label(@bundle.runbook_entry.evidence_completeness.state) %>
              </p>
              <p class="mt-1 text-sm text-zinc-600"><%= completeness_details(@bundle.runbook_entry.evidence_completeness) %></p>
            </div>
          <% else %>
            <h2 class="text-base font-semibold">Open runbook entry</h2>
            <p class="mt-2 text-sm text-zinc-600">
              Runbook guidance is unavailable because the evidence bundle could not be assembled. Refresh the page, then open the forensic timeline for the same resource.
            </p>
          <% end %>
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

    defp caution_class(%{severity: :warning}),
      do: "rounded border border-amber-200 bg-amber-50 p-3 text-amber-800"

    defp caution_class(_item), do: "rounded border bg-slate-50 p-3 text-zinc-600"

    defp runbook_path_class(%{ownership: "Powertools-native"}),
      do: "rounded border border-indigo-200 bg-indigo-50 p-3"

    defp runbook_path_class(_item), do: "rounded border bg-white p-3"

    defp runbook_path_link_class(%{ownership: "Powertools-native"}),
      do: "rounded bg-indigo-700 px-3 py-2 text-sm text-white"

    defp runbook_path_link_class(_item), do: "text-sm text-indigo-700 underline"

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
