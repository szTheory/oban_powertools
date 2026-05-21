if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LifelineLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.{Audit, Lifeline}
    alias ObanPowertools.Lifeline.{ArchiveRun, Incident, RepairPreview}
    alias ObanPowertools.Web.LiveAuth
    alias ObanPowertools.Workflow.Step

    @impl true
    def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_lifeline, %{type: :page, id: "lifeline"}) do
        {:ok,
         socket
         |> assign(:oban_dashboard_path, dashboard_path)
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign(:success_message, nil)
         |> assign(:current_view, "active")
         |> assign(:preview, nil)
         |> assign(:preview_state, :idle)
         |> load_data(nil)}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_event("select_incident", %{"row-id" => row_id}, socket) do
      {:noreply,
       socket
       |> assign(:success_message, nil)
       |> load_data(%{row_id: row_id})}
    end

    def handle_event("toggle_view", %{"view" => view}, socket) do
      {:noreply,
       socket
       |> assign(:success_message, nil)
       |> load_data(%{
         view: view,
         incident_fingerprint: selected_fingerprint(socket.assigns.selected_row)
       })}
    end

    def handle_event("preview", %{"row-id" => row_id}, socket) do
      row = find_row!(socket.assigns.visible_incident_rows, row_id)

      with :ok <- ensure_previewable(row),
           :ok <- LiveAuth.authorize_action(socket, :preview_repair, row.resource),
           {:ok, preview} <-
             Lifeline.preview_repair(
               repo(),
               socket.assigns.current_actor,
               %{
                 incident_id: row.incident.id,
                 action: row.action,
                 target_type: row.target_type,
                 target_id: row.target_id
               }
             ) do
        {:noreply,
         socket
         |> assign(:selected_row, row)
         |> assign(:preview, preview)
         |> assign(:preview_state, preview_state(preview))
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign(:success_message, nil)
         |> assign(:audit_events, audit_events_for_row(row))
         |> assign(:target_detail, load_target_detail(row))}
      else
        {:error, :preview_not_available} ->
          {:noreply, assign(socket, :error_message, "This incident has no repairable target yet.")}

        {:error, :heartbeat_late} ->
          {:noreply, assign(socket, :error_message, "Heartbeat Late incidents cannot be previewed for repair.")}

        {:error, :repair_requires_missing_executor} ->
          {:noreply, assign(socket, :error_message, "Only Executor Missing incidents can preview a rescue repair.")}

        {:error, :unauthorized} ->
          {:noreply, assign(socket, :error_message, "You are not authorized to preview this repair.")}

        {:error, reason} ->
          {:noreply, assign(socket, :error_message, error_message(reason))}
      end
    end

    def handle_event("reason", %{"reason" => reason}, socket) do
      {:noreply, assign(socket, :reason, reason)}
    end

    def handle_event("execute", _params, %{assigns: %{preview: nil}} = socket) do
      {:noreply, socket}
    end

    def handle_event("execute", _params, socket) do
      preview = socket.assigns.preview
      row = socket.assigns.selected_row

      with :ok <- LiveAuth.authorize_action(socket, :execute_repair, row.resource),
           {:ok, _result} <-
             Lifeline.execute_repair(
               repo(),
               socket.assigns.current_actor,
               preview.preview_token,
               socket.assigns.reason
             ) do
         {:noreply,
         socket
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign(:success_message, "Repair executed and audit evidence was written.")
         |> assign(:preview, nil)
         |> assign(:preview_state, :idle)
         |> load_data(%{
           view: "resolved",
           incident_fingerprint: preview.incident_fingerprint
         })}
      else
        {:error, :preview_drifted} ->
          drifted_preview = repo().get_by!(RepairPreview, preview_token: preview.preview_token)

          {:noreply,
           socket
           |> assign(:preview, drifted_preview)
           |> assign(:preview_state, :drifted)
           |> assign(:error_message, "Preview Drifted. Generate a fresh preview before executing.")
           |> load_data(%{
             view: socket.assigns.current_view,
             row_id: row.id
           })}

        {:error, :reason_required} ->
          {:noreply, assign(socket, :error_message, "Enter a specific reason before executing the repair.")} 

        {:error, :reason_too_short} ->
          {:noreply, assign(socket, :error_message, "Enter at least 8 characters so the audit trail is operator-readable.")} 

        {:error, :preview_consumed} ->
          {:noreply, assign(socket, :error_message, "This preview was already consumed. Generate a fresh preview.")} 

        {:error, :unauthorized} ->
          {:noreply, assign(socket, :error_message, "You are not authorized to execute this repair.")} 

        {:error, reason} ->
          {:noreply, assign(socket, :error_message, error_message(reason))}
      end
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-8 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Lifeline</h1>
          <p class="text-sm text-zinc-600">
            Incident-first review stays here. Generic job internals still deep-link into Oban Web.
          </p>
        </div>

        <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <.metric_card label="Needs Review" value={length(@active_incident_rows)} />
          <.metric_card label="Healthy Executors" value={length(@healthy_executors)} />
          <.metric_card label="Pending Repair Previews" value={@retention.pending_previews} />
          <.metric_card label="Archived Repairs" value={@retention.archived_repairs} />
        </div>

        <div
          :if={@active_incident_rows == [] and @resolved_incident_rows == []}
          class="rounded-lg border bg-white p-6"
        >
          <h2 class="text-base font-semibold">No lifeline incidents need review</h2>
          <p class="mt-2 text-sm text-zinc-600">
            All tracked executors are heartbeating and no orphan candidates are waiting for repair. Review archive activity below if you need retention evidence.
          </p>
        </div>

        <div
          :if={@active_incident_rows != [] or @resolved_incident_rows != []}
          class="grid gap-6 xl:grid-cols-[minmax(0,1.2fr)_minmax(0,1fr)]"
        >
          <div class="overflow-hidden rounded-lg border bg-white">
            <div class="border-b bg-slate-50 px-4 py-3">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h2 class="text-base font-semibold"><%= incident_view_heading(@current_view) %></h2>
                  <p class="mt-1 text-sm text-zinc-600">
                    <%= incident_view_copy(@current_view) %>
                  </p>
                </div>
                <div class="flex gap-2">
                  <button
                    type="button"
                    phx-click="toggle_view"
                    phx-value-view="active"
                    class={view_toggle_class(@current_view == "active")}
                  >
                    Needs Review (<%= length(@active_incident_rows) %>)
                  </button>
                  <button
                    type="button"
                    phx-click="toggle_view"
                    phx-value-view="resolved"
                    class={view_toggle_class(@current_view == "resolved")}
                  >
                    Resolved (<%= length(@resolved_incident_rows) %>)
                  </button>
                </div>
              </div>
            </div>
            <div :if={@visible_incident_rows == []} class="p-4 text-sm text-zinc-600">
              <%= empty_view_copy(@current_view) %>
            </div>
            <table :if={@visible_incident_rows != []} class="min-w-full divide-y">
              <thead class="bg-slate-50 text-left text-sm">
                <tr>
                  <th class="px-4 py-3 font-medium">Incident</th>
                  <th class="px-4 py-3 font-medium">Health</th>
                  <th class="px-4 py-3 font-medium">Affected Scope</th>
                  <th class="px-4 py-3 font-medium">Action</th>
                </tr>
              </thead>
              <tbody class="divide-y text-sm">
                <tr
                  :for={row <- @visible_incident_rows}
                  class={["align-top", if(@selected_row && @selected_row.id == row.id, do: "bg-indigo-50", else: "bg-white")]}
                >
                  <td class="px-4 py-3">
                    <button
                      type="button"
                      phx-click="select_incident"
                      phx-value-row-id={row.id}
                      class="text-left"
                    >
                      <div class="font-medium"><%= row.incident.summary %></div>
                      <div class="mt-1 text-zinc-500"><%= row.target_summary %></div>
                      <div class="mt-1 text-xs text-zinc-500">
                        Detection basis: <%= detection_basis(row.incident) %>
                      </div>
                    </button>
                  </td>
                  <td class="px-4 py-3">
                    <span class={badge_class(row.incident.health_state, row.incident.status)}>
                      <%= row.incident.health_state |> health_label() %>
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <div><%= count_label(row.incident.affected_counts, "jobs") %></div>
                    <div class="text-zinc-500"><%= count_label(row.incident.affected_counts, "workflow_steps") %></div>
                  </td>
                  <td class="px-4 py-3">
                    <button
                      :if={@current_view == "active"}
                      type="button"
                      phx-click="preview"
                      phx-value-row-id={row.id}
                      disabled={not row.previewable?}
                      class={[
                        "rounded px-3 py-2",
                        if(row.previewable?, do: "bg-indigo-600 text-white", else: "cursor-not-allowed border text-zinc-400")
                      ]}
                    >
                      Preview Repair Plan
                    </button>
                    <span :if={@current_view == "resolved"} class="text-zinc-500">Resolved</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div :if={@selected_row} class="space-y-4">
            <div class="rounded-lg border bg-white p-4">
              <div class="flex flex-wrap items-center justify-between gap-3">
                <h2 class="text-base font-semibold"><%= @selected_row.target_summary %></h2>
                <span :if={@preview_state != :idle} class={preview_badge_class(@preview_state)}>
                  <%= preview_badge_copy(@preview_state) %>
                </span>
              </div>

              <p :if={@error_message} class="mt-3 text-sm text-red-700"><%= @error_message %></p>
              <p :if={@success_message} class="mt-3 text-sm text-emerald-700"><%= @success_message %></p>

              <div class="mt-4 space-y-4">
                <section>
                  <h3 class="text-sm font-medium">Detection Summary</h3>
                  <div class="mt-2 rounded border bg-slate-50 p-3 text-sm">
                    <p><strong>Last heartbeat:</strong> <%= heartbeat_copy(@selected_row.incident) %></p>
                    <p class="mt-1"><strong>Detection basis:</strong> <%= detection_basis(@selected_row.incident) %></p>
                    <p class="mt-1"><strong>Last detected:</strong> <%= timestamp_copy(@selected_row.incident.last_detected_at) %></p>
                    <p :if={@selected_row.incident.status == "resolved"} class="mt-1">
                      <strong>Resolved at:</strong> <%= timestamp_copy(@selected_row.incident.resolved_at) %>
                    </p>
                  </div>
                </section>

                <section>
                  <h3 class="text-sm font-medium">Proposed State Changes</h3>
                  <div class="mt-2 rounded border bg-slate-50 p-3 text-sm">
                    <%= if @preview do %>
                      <div><strong>Before:</strong> <%= state_copy(@preview.before_snapshot) %></div>
                      <div class="mt-1"><strong>After:</strong> <%= state_copy(@preview.after_snapshot) %></div>
                    <% else %>
                      <p>Generate a preview to inspect operator-readable before and after state changes.</p>
                    <% end %>
                  </div>
                </section>

                <section>
                  <h3 class="text-sm font-medium">Affected Records</h3>
                  <div class="mt-2 rounded border bg-slate-50 p-3 text-sm">
                    <p><strong>Scope:</strong> <%= affected_scope_copy(@selected_row.incident.affected_counts) %></p>
                    <p class="mt-1"><strong>Records:</strong> <%= affected_records_copy(@selected_row.incident) %></p>
                  </div>
                </section>

                <section>
                  <h3 class="text-sm font-medium">Audit Record to be Written</h3>
                  <div class="mt-2 rounded border bg-slate-50 p-3 text-sm">
                    <p><strong>Actor:</strong> <%= actor_copy(@current_actor) %></p>
                    <p class="mt-1"><strong>Action:</strong> <%= @selected_row.action %></p>
                    <p class="mt-1"><strong>Resource:</strong> <%= resource_copy(@selected_row) %></p>
                    <p class="mt-1"><strong>Reason:</strong> <%= audit_reason_copy(@reason) %></p>
                    <p class="mt-1"><strong>Preview Token:</strong> <%= if @preview, do: @preview.preview_token, else: "Generate preview first" %></p>
                  </div>
                </section>
              </div>

                <div :if={@current_view == "active"} class="mt-4 space-y-3">
                  <label class="block text-sm font-medium">
                    Reason
                    <input
                    type="text"
                    name="reason"
                    value={@reason}
                    phx-change="reason"
                    class="mt-2 w-full rounded border px-3 py-2"
                  />
                </label>
                <p class="text-xs text-zinc-500">
                  Execute Repair Plan: This will change job or workflow state immediately and write an immutable audit event. Enter a reason before continuing.
                </p>
                <div class="flex flex-wrap gap-3">
                  <button
                    :if={@preview}
                    type="button"
                    phx-click="execute"
                    disabled={not execute_enabled?(@preview, @reason)}
                    class={[
                      "rounded px-3 py-2",
                      if(execute_enabled?(@preview, @reason),
                        do: "bg-red-600 text-white",
                        else: "cursor-not-allowed border text-zinc-400"
                      )
                    ]}
                  >
                    Execute Repair Plan
                  </button>
                  <a
                    :if={@target_detail.job_id}
                    href={build_job_path(@oban_dashboard_path, @target_detail.job_id)}
                    class="rounded border px-3 py-2 text-sm"
                  >
                    Open Generic Job Inspection in Oban Web
                  </a>
                </div>
              </div>
            </div>

            <div class="rounded-lg border bg-white p-4">
              <h2 class="text-base font-semibold">Manual Intervention History</h2>
              <%= if @audit_events == [] do %>
                <p class="mt-2 text-sm text-zinc-600">
                  No manual intervention has been recorded for this incident yet.
                </p>
              <% else %>
                <div class="mt-3 space-y-3">
                  <div :for={event <- @audit_events} class="rounded border bg-slate-50 p-3 text-sm">
                    <div><strong>Actor:</strong> <%= event.actor_id || "system" %></div>
                    <div class="mt-1"><strong>Action:</strong> <%= event.action %></div>
                    <div class="mt-1"><strong>Resource:</strong> <%= event.resource %></div>
                    <div class="mt-1"><strong>Reason:</strong> <%= event.metadata["reason"] || "No reason recorded" %></div>
                    <div class="mt-1"><strong>Event Time:</strong> <%= timestamp_copy(event.inserted_at) %></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(0,1fr)]">
          <div class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Healthy Executors</h2>
            <%= if @healthy_executors == [] do %>
              <p class="mt-2 text-sm text-zinc-600">No healthy executors are currently tracked.</p>
            <% else %>
              <ul class="mt-3 space-y-2 text-sm">
                <li :for={row <- @healthy_executors}>
                  <strong><%= row.executor_id %></strong>
                  <span class="text-zinc-500">last heartbeat <%= timestamp_copy(row.last_heartbeat_at) %></span>
                </li>
              </ul>
            <% end %>
          </div>

          <div class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Archive Activity</h2>
            <p class="mt-2 text-sm">
              <strong>Last Archive + Prune Run:</strong>
              <%= archive_summary(@retention.last_run) %>
            </p>
            <div class="mt-3 grid gap-3 sm:grid-cols-3 text-sm">
              <div class="rounded border bg-slate-50 p-3">
                <div class="text-zinc-500">Pending Repair Previews</div>
                <div class="mt-1 text-lg font-semibold"><%= @retention.pending_previews %></div>
              </div>
              <div class="rounded border bg-slate-50 p-3">
                <div class="text-zinc-500">Archived Repairs</div>
                <div class="mt-1 text-lg font-semibold"><%= @retention.archived_repairs %></div>
              </div>
              <div class="rounded border bg-slate-50 p-3">
                <div class="text-zinc-500">Heartbeat Samples</div>
                <div class="mt-1 text-lg font-semibold"><%= @retention.heartbeat_samples %></div>
              </div>
            </div>
            <p class="mt-3 text-sm text-zinc-600">
              Archive and prune visibility is read-only here. Retention policy editing stays out of scope for this phase.
            </p>
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

    defp load_data(socket, selection) do
      repo = repo()
      Lifeline.project_incidents(repo)

      active_incident_rows =
        repo
        |> Lifeline.list_incidents(status: "active")
        |> then(&expand_rows(repo, &1))

      resolved_incident_rows =
        repo
        |> Lifeline.list_incidents(status: "resolved")
        |> then(&expand_rows(repo, &1))

      {current_view, selected_row} =
        pick_view_and_row(
          active_incident_rows,
          resolved_incident_rows,
          selection,
          socket.assigns[:current_view] || "active"
        )

      visible_incident_rows =
        if current_view == "resolved", do: resolved_incident_rows, else: active_incident_rows

      preview =
        if current_view == "active" and selected_row do
          find_pending_preview(repo, selected_row)
        end

      preview_state = preview && preview_state(preview) || :idle
      retention = Lifeline.retention_status(repo)

      socket
      |> assign(:active_incident_rows, active_incident_rows)
      |> assign(:resolved_incident_rows, resolved_incident_rows)
      |> assign(:visible_incident_rows, visible_incident_rows)
      |> assign(:current_view, current_view)
      |> assign(:healthy_executors, healthy_executors(repo))
      |> assign(:selected_row, selected_row)
      |> assign(:preview, preview)
      |> assign(:preview_state, preview_state)
      |> assign(:audit_events, selected_row && audit_events_for_row(selected_row) || [])
      |> assign(:target_detail, selected_row && load_target_detail(selected_row) || %{job_id: nil})
      |> assign(:retention, retention)
    end

    defp healthy_executors(repo) do
      Lifeline.list_executor_health(repo)
      |> Enum.filter(&(&1.health_state == "healthy"))
    end

    defp expand_rows(repo, incidents) do
      incidents
      |> Enum.flat_map(&incident_rows(repo, &1))
      |> Enum.sort_by(fn row -> {severity_rank(row.incident), -(DateTime.to_unix(row.incident.last_detected_at || row.incident.inserted_at, :second))} end)
    end

    defp incident_rows(_repo, %Incident{incident_class: "dead_executor"} = incident) do
      job_ids = Map.get(incident.evidence || %{}, "job_ids", [])

      case job_ids do
        [] ->
          [
            %{
              id: "#{incident.id}:summary",
              incident: incident,
              action: "job_rescue",
              target_type: "job",
              target_id: nil,
              target_summary: "Dead executor review",
              previewable?: false,
              resource: %{type: :job, id: "missing"}
            }
          ]

        ids ->
          Enum.map(ids, fn job_id ->
            %{
              id: "#{incident.id}:job:#{job_id}",
              incident: incident,
              action: "job_rescue",
              target_type: "job",
              target_id: to_string(job_id),
              target_summary: "Job #{job_id} on #{incident.executor_id}",
              previewable?: true,
              resource: %{type: :job, id: to_string(job_id)}
            }
          end)
      end
    end

    defp incident_rows(repo, %Incident{incident_class: "workflow_stuck", workflow_step_id: step_id} = incident) do
      step = repo.get(Step, step_id)
      step_name = step && step.step_name || Map.get(incident.evidence || %{}, "step_name", "workflow step")

      [
        %{
          id: "#{incident.id}:workflow_step:#{step_id}",
          incident: incident,
          action: "workflow_step_retry",
          target_type: "workflow_step",
          target_id: to_string(step_id),
          target_summary: "#{step_name} in workflow #{incident.workflow_id}",
          previewable?: true,
          resource: %{type: :workflow_step, id: to_string(step_id)}
        }
      ]
    end

    defp pick_view_and_row(active_rows, resolved_rows, nil, current_view) do
      default_view = if current_view == "resolved" and resolved_rows != [], do: "resolved", else: "active"
      rows = rows_for_view(default_view, active_rows, resolved_rows)
      {default_view, List.first(rows)}
    end

    defp pick_view_and_row(active_rows, resolved_rows, selection, current_view) do
      view = Map.get(selection, :view) || current_view
      row_id = Map.get(selection, :row_id)
      incident_fingerprint = Map.get(selection, :incident_fingerprint)

      case locate_selected_row(active_rows, resolved_rows, view, row_id, incident_fingerprint) do
        {selected_view, nil} ->
          rows = rows_for_view(selected_view, active_rows, resolved_rows)
          {selected_view, List.first(rows)}

        {selected_view, row} ->
          {selected_view, row}
      end
    end

    defp locate_selected_row(active_rows, resolved_rows, view, row_id, incident_fingerprint) do
      rows = rows_for_view(view, active_rows, resolved_rows)

      row =
        find_row_by_id(rows, row_id) ||
          find_row_by_fingerprint(rows, incident_fingerprint)

      cond do
        row ->
          {view, row}

        row = find_row_by_id(active_rows, row_id) ->
          {"active", row}

        row = find_row_by_id(resolved_rows, row_id) ->
          {"resolved", row}

        view == "resolved" and resolved_rows != [] ->
          {"resolved", find_row_by_fingerprint(resolved_rows, incident_fingerprint)}

        true ->
          {"active", find_row_by_fingerprint(active_rows, incident_fingerprint)}
      end
    end

    defp rows_for_view("resolved", _active_rows, resolved_rows), do: resolved_rows
    defp rows_for_view(_, active_rows, _resolved_rows), do: active_rows

    defp find_row_by_id(_rows, nil), do: nil
    defp find_row_by_id(rows, row_id), do: Enum.find(rows, &(&1.id == row_id))

    defp find_row_by_fingerprint(_rows, nil), do: nil

    defp find_row_by_fingerprint(rows, incident_fingerprint) do
      Enum.find(rows, &(&1.incident.incident_fingerprint == incident_fingerprint))
    end

    defp find_pending_preview(repo, row) do
      repo.one(
        from(preview in RepairPreview,
          where:
            preview.incident_id == ^row.incident.id and preview.action == ^row.action and
              preview.target_type == ^row.target_type and preview.target_id == ^row.target_id and
              preview.status in ["pending", "drifted"],
          order_by: [desc: preview.inserted_at],
          limit: 1
        )
      )
    end

    defp load_target_detail(%{target_type: "job", target_id: target_id}), do: %{job_id: String.to_integer(target_id)}

    defp load_target_detail(%{target_type: "workflow_step", target_id: target_id}) do
      case repo().get(Step, target_id) do
        nil -> %{job_id: nil}
        step -> %{job_id: step.job_id}
      end
    end

    defp audit_events_for_row(row) do
      Audit.list_all(repo: repo())
      |> Enum.filter(fn event ->
        event.resource == resource_copy(row) or
          event.metadata["incident_fingerprint"] == row.incident.incident_fingerprint
      end)
      |> Enum.take(5)
    end

    defp ensure_previewable(%{previewable?: true}), do: :ok
    defp ensure_previewable(_row), do: {:error, :preview_not_available}

    defp find_row!(rows, row_id), do: Enum.find(rows, &(&1.id == row_id)) || raise("incident row not found")

    defp selected_fingerprint(nil), do: nil
    defp selected_fingerprint(row), do: row.incident.incident_fingerprint

    defp execute_enabled?(nil, _reason), do: false
    defp execute_enabled?(%RepairPreview{status: "drifted"}, _reason), do: false
    defp execute_enabled?(preview, reason), do: preview.status == "pending" and String.trim(reason) |> String.length() >= 8

    defp preview_state(%RepairPreview{status: "drifted"}), do: :drifted
    defp preview_state(%RepairPreview{}), do: :ready

    defp preview_badge_class(:ready), do: "rounded border border-indigo-300 bg-indigo-50 px-3 py-1 text-sm font-medium text-indigo-700"
    defp preview_badge_class(:drifted), do: "rounded border border-amber-300 bg-amber-50 px-3 py-1 text-sm font-medium text-amber-800"

    defp preview_badge_copy(:ready), do: "Preview Ready"
    defp preview_badge_copy(:drifted), do: "Preview Drifted"

    defp severity_rank(%Incident{incident_class: "dead_executor", health_state: "missing"}), do: 0
    defp severity_rank(%Incident{incident_class: "workflow_stuck"}), do: 1
    defp severity_rank(_incident), do: 2

    defp health_label(nil), do: "Needs Review"
    defp health_label(state), do: Lifeline.health_label(state)

    defp badge_class(_health_state, "resolved"), do: "rounded border border-emerald-200 bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700"
    defp badge_class("missing", _status), do: "rounded border border-red-200 bg-red-50 px-2 py-1 text-xs font-medium text-red-700"
    defp badge_class("late", _status), do: "rounded border border-amber-200 bg-amber-50 px-2 py-1 text-xs font-medium text-amber-700"
    defp badge_class(_health_state, _status), do: "rounded border border-slate-200 bg-slate-50 px-2 py-1 text-xs font-medium text-slate-700"

    defp incident_view_heading("resolved"), do: "Resolved Incidents"
    defp incident_view_heading(_view), do: "Needs Review"

    defp incident_view_copy("resolved"),
      do: "Resolved incidents preserve repair outcomes and inline audit evidence after execution."

    defp incident_view_copy(_view),
      do: "Active incidents are sorted by severity, then most recent detection time."

    defp empty_view_copy("resolved"), do: "No resolved incidents are available yet."
    defp empty_view_copy(_view), do: "No active incidents need review right now."

    defp view_toggle_class(true),
      do: "rounded border border-indigo-300 bg-indigo-50 px-3 py-2 text-sm font-medium text-indigo-700"

    defp view_toggle_class(false),
      do: "rounded border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-600"

    defp detection_basis(%Incident{incident_class: "dead_executor"}), do: "Executor heartbeat evidence"
    defp detection_basis(%Incident{incident_class: "workflow_stuck"}), do: "Workflow blocker evidence"
    defp detection_basis(_incident), do: "Incident evidence"

    defp heartbeat_copy(%Incident{incident_class: "dead_executor"} = incident) do
      case get_in(incident.evidence, ["last_heartbeat_at"]) do
        nil -> "No heartbeat captured"
        timestamp -> timestamp_copy(timestamp)
      end
    end

    defp heartbeat_copy(_incident), do: "Not applicable"

    defp affected_scope_copy(counts) do
      [count_label(counts, "jobs"), count_label(counts, "workflow_steps")]
      |> Enum.reject(&(&1 =~ "0 "))
      |> Enum.join(", ")
    end

    defp affected_records_copy(%Incident{incident_class: "dead_executor"} = incident) do
      job_ids = Map.get(incident.evidence || %{}, "job_ids", [])
      step_ids = Map.get(incident.evidence || %{}, "workflow_step_ids", [])

      [list_copy("jobs", job_ids), list_copy("workflow steps", step_ids)]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" | ")
    end

    defp affected_records_copy(%Incident{workflow_step_id: step_id, evidence: evidence}) do
      step_name = Map.get(evidence || %{}, "step_name", "workflow step")
      blocker_codes = Map.get(evidence || %{}, "blocker_codes", [])
      "#{step_name} (#{step_id}) blocked by #{Enum.join(blocker_codes, ", ")}"
    end

    defp affected_records_copy(_incident), do: "No raw records available."

    defp list_copy(_label, []), do: nil
    defp list_copy(label, ids), do: "#{label}: #{Enum.join(Enum.map(ids, &to_string/1), ", ")}"

    defp state_copy(%{"job_id" => id, "state" => state} = snapshot),
      do: "job #{id} is #{state} (executor #{snapshot["executor_id"] || "none"})"

    defp state_copy(%{"step_id" => id, "state" => state, "blocker_codes" => blocker_codes}),
      do: "workflow step #{id} is #{state} with blockers #{Enum.join(blocker_codes || [], ", ")}"

    defp state_copy(%{"step_id" => id, "state" => state}),
      do: "workflow step #{id} is #{state}"

    defp state_copy(snapshot) when is_map(snapshot), do: inspect(snapshot)

    defp actor_copy(nil), do: "unknown"
    defp actor_copy(actor), do: Map.get(actor, :id, Map.get(actor, "id", inspect(actor)))

    defp resource_copy(row), do: "#{row.target_type}:#{row.target_id}"

    defp audit_reason_copy(reason) do
      case String.trim(reason || "") do
        "" -> "Reason required before execution"
        trimmed -> trimmed
      end
    end

    defp count_label(counts, key), do: "#{Map.get(counts || %{}, key, 0)} #{Phoenix.Naming.humanize(key)}"

    defp archive_summary(nil), do: "No archive or prune runs recorded yet."

    defp archive_summary(%ArchiveRun{} = run) do
      "#{Phoenix.Naming.humanize(run.status)} at #{timestamp_copy(run.finished_at || run.started_at)}"
    end

    defp archive_summary(_run), do: "Archive status unavailable."

    defp timestamp_copy(nil), do: "Unknown"

    defp timestamp_copy(%NaiveDateTime{} = timestamp) do
      timestamp
      |> DateTime.from_naive!("Etc/UTC")
      |> timestamp_copy()
    end

    defp timestamp_copy(%DateTime{} = timestamp) do
      seconds = DateTime.diff(DateTime.utc_now(), timestamp, :second)

      relative =
        cond do
          seconds < 60 -> "#{seconds}s ago"
          seconds < 3_600 -> "#{div(seconds, 60)}m ago"
          seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
          true -> "#{div(seconds, 86_400)}d ago"
        end

      exact = Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S UTC")
      "#{relative} (#{exact})"
    end

    defp timestamp_copy(timestamp) when is_binary(timestamp), do: timestamp
    defp timestamp_copy(_timestamp), do: "Unknown"

    defp build_job_path(base, job_id), do: Path.join([base, "jobs", to_string(job_id)])

    defp error_message(:preview_not_found), do: "The repair preview no longer exists."
    defp error_message(:preview_drifted), do: "Preview Drifted. Generate a fresh preview before executing."
    defp error_message(:incident_still_active), do: "The repair target changed, but the incident still has live evidence. Refresh and review the remaining active records."
    defp error_message(:unauthorized), do: "You are not authorized to perform this action."
    defp error_message(reason), do: inspect(reason)

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
