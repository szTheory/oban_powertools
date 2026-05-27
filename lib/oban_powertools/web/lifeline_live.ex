if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.LifelineLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.{Audit, DisplayPolicy, Explain, Lifeline}
    alias ObanPowertools.Lifeline.{ArchiveRun, Incident, RepairPreview, TargetType}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}
    alias ObanPowertools.Workflow.{Step, Workflow}

    @impl true
    def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_lifeline, %{type: :page, id: "lifeline"}) do
        :ok = DisplayPolicy.assert_configured!()

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
    def handle_params(params, _uri, socket) do
      {:noreply,
       socket
       |> assign(:success_message, nil)
       |> load_data(selection_from_params(params))}
    end

    @impl true
    def handle_event("select_incident", %{"row-id" => row_id}, socket) do
      row = find_row!(socket.assigns.visible_incident_rows, row_id)

      {:noreply,
       socket
       |> assign(:success_message, nil)
       |> push_patch(
         to:
           selection_path(%{
             view: socket.assigns.current_view,
             row_id: row.id,
             incident_fingerprint: row.incident.incident_fingerprint
           })
       )}
    end

    def handle_event("toggle_view", %{"view" => view}, socket) do
      {:noreply,
       socket
       |> assign(:success_message, nil)
       |> push_patch(
         to:
           selection_path(%{
             view: view,
             row_id: socket.assigns.selected_row && socket.assigns.selected_row.id,
             incident_fingerprint: selected_fingerprint(socket.assigns.selected_row)
           })
       )}
    end

    def handle_event("preview", %{"row-id" => row_id}, socket) do
      row = find_row!(socket.assigns.visible_incident_rows, row_id)

      with :ok <- ensure_previewable(row),
           :ok <-
             LiveAuth.authorize_action(socket, :preview_repair, row.resource,
               message: LiveAuth.permission_message(:preview_repair)
             ),
           {:ok, _principal} <- LiveAuth.principal_for_action(socket),
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
          {:noreply,
           assign(socket, :error_message, LiveAuth.mutation_error(:preview_not_available))}

        {:error, :heartbeat_late} ->
          {:noreply,
           assign(socket, :error_message, LiveAuth.mutation_error(:preview_not_available))}

        {:error, :repair_requires_missing_executor} ->
          {:noreply,
           assign(socket, :error_message, LiveAuth.mutation_error(:preview_not_available))}

        {:error, :unauthorized} ->
          {:noreply, assign(socket, :error_message, LiveAuth.permission_message(:preview_repair))}

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

      with :ok <-
             LiveAuth.authorize_action(socket, :execute_repair, row.resource,
               message: LiveAuth.permission_message(:execute_repair)
             ),
           {:ok, _principal} <- LiveAuth.principal_for_action(socket),
           {:ok, _result} <-
             Lifeline.execute_repair(
               repo(),
               socket.assigns.current_actor,
               repair_preview_value(preview),
               socket.assigns.reason
             ) do
        next_selection =
          if row.incident.id do
            %{view: "resolved", incident_fingerprint: preview.incident_fingerprint}
          else
            %{
              view: "active",
              workflow_id: Map.get(row, :workflow_id),
              step_name: Map.get(row, :step_name),
              action: row.action
            }
          end

        {:noreply,
         socket
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign(:success_message, "Repair executed and audit evidence was written.")
         |> assign(:preview, nil)
         |> assign(:preview_state, :idle)
         |> load_data(next_selection)}
      else
        {:error, :preview_drifted} ->
          drifted_preview =
            repo().get_by!(RepairPreview, [{repair_preview_key(), repair_preview_value(preview)}])

          {:noreply,
           socket
           |> assign(:preview, drifted_preview)
           |> assign(:preview_state, :drifted)
           |> assign(:error_message, LiveAuth.mutation_error(:preview_drifted))
           |> load_data(%{
             view: socket.assigns.current_view,
             row_id: row.id
           })}

        {:error, :reason_required} ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:reason_required))}

        {:error, :reason_too_short} ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:reason_too_short))}

        {:error, :preview_consumed} ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:preview_consumed))}

        {:error, :unauthorized} ->
          {:noreply, assign(socket, :error_message, LiveAuth.permission_message(:execute_repair))}

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
            <%= ControlPlanePresenter.native_banner() %> Generic job internals still deep-link into the Oban Web bridge.
          </p>
        </div>

        <p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <%= LiveAuth.page_read_only_banner(:lifeline) %>
        </p>

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
                    <% action = preview_action(row, @current_actor) %>
                    <button
                      :if={@current_view == "active"}
                      type="button"
                      phx-click="preview"
                      phx-value-row-id={row.id}
                      disabled={not action.enabled?}
                      class={[
                        "rounded px-3 py-2",
                        if(action.enabled?, do: "bg-indigo-600 text-white", else: "cursor-not-allowed border text-zinc-400")
                      ]}
                    >
                      Preview Native Remediation
                    </button>
                    <p :if={@current_view == "active" and not is_nil(action.disabled_reason)} class="mt-1 text-xs text-zinc-500">
                      <%= action.disabled_reason %>
                    </p>
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

              <div class="mt-4 rounded border border-slate-200 bg-slate-50 p-3 text-sm text-slate-800">
                <p class="font-medium">Open the forensic bundle.</p>
                <p class="mt-1">
                  Lifeline remains a first-class Phase 32 forensic entry surface. Audit follow-up stays Inspection only and limiter or cron facts remain supporting evidence.
                </p>
                <.link
                  navigate={forensic_path(@selected_row, @current_view)}
                  class="mt-3 inline-flex rounded bg-slate-900 px-3 py-2 text-white"
                >
                  Open forensic timeline
                </.link>
              </div>

              <section class="mt-4">
                <h3 class="text-sm font-medium">Runbook continuity</h3>
                <div class="mt-2 rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
                  <%= if continuity = runbook_continuity(@preview, @audit_events) do %>
                    <p><strong>Diagnosis:</strong> <%= continuity_diagnosis(continuity) %></p>
                    <p class="mt-1"><strong>Legal next path:</strong> <%= continuity_legal_next_path(continuity) %></p>
                    <p class="mt-1"><strong>Venue:</strong> <%= continuity_venue(continuity) %></p>
                    <p class="mt-1"><strong>Attempt state:</strong> <%= continuity_attempt_state(continuity) %></p>
                    <p class="mt-1">
                      <strong>host-owned follow-up status:</strong>
                      <%= host_follow_up_status_label(@audit_events) %>
                    </p>
                    <p :if={detail = host_follow_up_status_detail(@audit_events)} class="mt-1 text-xs">
                      <%= detail %>
                    </p>
                    <p class="mt-2">
                      <strong>Evidence link:</strong>
                      <a href={forensic_path(@selected_row, @current_view)} class="text-indigo-700 underline">
                        Open forensic evidence
                      </a>
                    </p>
                    <p class="mt-1">
                      <strong>Audit follow-up:</strong>
                      <%= if path = latest_audit_follow_up_path(@audit_events) do %>
                        <.link navigate={path} class="text-indigo-700 underline">Open in Audit</.link>
                      <% else %>
                        <span>No audit follow-up available</span>
                      <% end %>
                    </p>
                  <% else %>
                    <p class="font-medium">No remediation attempts recorded yet</p>
                    <p class="mt-1">
                      This diagnosis has not entered a supported native remediation flow. Review legal next paths, then start a native preview to capture attempt context.
                    </p>
                    <p class="mt-2">
                      <strong>Evidence link:</strong>
                      <a href={forensic_path(@selected_row, @current_view)} class="text-indigo-700 underline">
                        Open forensic evidence
                      </a>
                    </p>
                    <p class="mt-1"><strong>Audit follow-up:</strong> No audit follow-up available</p>
                  <% end %>
                  <div class="mt-3 space-y-1 text-xs">
                    <div
                      data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("Powertools-native")}
                      data-runbook-variant={follow_up_variant("Powertools-native")}
                      class={follow_up_row_class("Powertools-native")}
                    >
                      <%= ControlPlanePresenter.runbook_ownership_label("Powertools-native") %>
                    </div>
                    <div
                      data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("Oban Web bridge")}
                      data-runbook-variant={follow_up_variant("Oban Web bridge")}
                      class={follow_up_row_class("Oban Web bridge")}
                    >
                      <%= ControlPlanePresenter.runbook_ownership_label("Oban Web bridge") %>
                    </div>
                    <div
                      data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("host-owned follow-up")}
                      data-runbook-variant={follow_up_variant("host-owned follow-up")}
                      class={follow_up_row_class("host-owned follow-up")}
                    >
                      <%= ControlPlanePresenter.runbook_ownership_label("host-owned follow-up") %>
                    </div>
                  </div>
                </div>
              </section>

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
                      <p><strong>Plan Summary:</strong> <%= get_in(@preview.metadata, ["summary"]) %></p>
                      <p :if={get_in(@preview.metadata, ["diagnosis"])} class="mt-1">
                        <strong>Diagnosis:</strong> <%= get_in(@preview.metadata, ["diagnosis"]) %>
                      </p>
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
                    <p><strong>Actor:</strong> <%= preview_actor_label(@current_actor) %></p>
                    <p class="mt-1"><strong>Action:</strong> <%= @selected_row.action %></p>
                    <p class="mt-1"><strong>Resource:</strong> <%= resource_copy(@selected_row) %></p>
                    <p class="mt-1"><strong>Reason:</strong> <%= preview_reason(@reason) %></p>
                    <p class="mt-1"><strong>Audit Consequence:</strong> <%= LiveAuth.audit_consequence_copy() %></p>
                    <p class="mt-1"><strong>Preview Status:</strong> <%= preview_status_copy(@preview) %></p>
                    <p class="mt-1"><strong>Preview Token:</strong> <%= if @preview, do: repair_preview_value(@preview), else: "Generate preview first" %></p>
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
                <% execute_action = execute_action(@preview, @reason, @current_actor, @selected_row) %>
                <p class="text-xs text-zinc-500">
                  Execute Remediation: This writes a native remediation attempt to audit and forensic evidence. Confirm only after reviewing reason, ownership, and expected outcome.
                </p>
                <div class="flex flex-wrap gap-3">
                  <button
                    :if={@preview}
                    type="button"
                    phx-click="execute"
                    disabled={not execute_action.enabled?}
                    class={[
                      "rounded px-3 py-2",
                      if(execute_action.enabled?,
                        do: "bg-red-600 text-white",
                        else: "cursor-not-allowed border text-zinc-400"
                      )
                    ]}
                  >
                    Execute Remediation
                  </button>
                  <a
                    :if={@target_detail.job_id}
                    href={build_job_path(@oban_dashboard_path, @target_detail.job_id)}
                    class="rounded border px-3 py-2 text-sm"
                  >
                    Open Generic Job Inspection in Oban Web bridge
                  </a>
                </div>
                <p :if={not is_nil(@preview) and not is_nil(execute_action.disabled_reason)} class="text-xs text-zinc-500">
                  <%= execute_action.disabled_reason %>
                </p>
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
                    <div><strong>Actor:</strong> <%= event_actor_label(event) %></div>
                    <div class="mt-1"><strong>Action:</strong> <%= ControlPlanePresenter.audit_event_label(event) %></div>
                    <div class="mt-1"><strong>Resource:</strong> <%= ControlPlanePresenter.audit_resource_label(event) %></div>
                    <div class="mt-1"><strong>Reason:</strong> <%= event_reason(event) %></div>
                    <div class="mt-1"><strong>Event Time:</strong> <%= timestamp_copy(event.inserted_at) %></div>
                    <.link navigate={ControlPlanePresenter.audit_follow_up_path(event)} class="mt-2 inline-flex text-indigo-700 underline">
                      Open in Audit
                    </.link>
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
              Archive and prune visibility is read-only here. <%= ControlPlanePresenter.bridge_banner() %> Retention policy editing stays out of scope for this phase.
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

      workflow_handoff_row = workflow_handoff_row(repo, selection)
      active_incident_rows = prepend_handoff_row(active_incident_rows, workflow_handoff_row)

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

      preview_state = (preview && preview_state(preview)) || :idle
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
      |> assign(:read_only?, read_only_page?(socket.assigns.current_actor, visible_incident_rows))
      |> assign(:audit_events, (selected_row && audit_events_for_row(selected_row)) || [])
      |> assign(
        :target_detail,
        (selected_row && load_target_detail(selected_row)) || %{job_id: nil}
      )
      |> assign(:retention, retention)
    end

    defp healthy_executors(repo) do
      Lifeline.list_executor_health(repo)
      |> Enum.filter(&(&1.health_state == "healthy"))
    end

    defp expand_rows(repo, incidents) do
      incidents
      |> Enum.flat_map(&incident_rows(repo, &1))
      |> Enum.sort_by(fn row ->
        {severity_rank(row.incident),
         -DateTime.to_unix(row.incident.last_detected_at || row.incident.inserted_at, :second)}
      end)
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

    defp incident_rows(
           repo,
           %Incident{incident_class: "workflow_stuck", workflow_step_id: step_id} = incident
         ) do
      step = repo.get(Step, step_id)

      step_name =
        (step && step.step_name) ||
          Map.get(incident.evidence || %{}, "step_name", "workflow step")

      story = step && Explain.step_story(step, repo: repo)
      action = primary_workflow_action((story && story.executable_actions) || [])

      [
        %{
          id: "#{incident.id}:workflow_step:#{step_id}",
          incident: incident,
          action: action.id,
          target_type: "workflow_step",
          target_id: to_string(step_id),
          target_summary: "#{step_name} in workflow #{incident.workflow_id}",
          previewable?: true,
          resource: %{type: :workflow_step, id: to_string(step_id)},
          workflow_id: incident.workflow_id,
          step_name: step_name,
          action_label: action.label
        }
      ]
    end

    defp incident_rows(_repo, %Incident{} = incident) do
      [
        %{
          id: "#{incident.id}:summary",
          incident: incident,
          action: "job_rescue",
          target_type: "job",
          target_id: nil,
          target_summary: incident.summary || incident.incident_class,
          previewable?: false,
          resource: %{type: :job, id: "missing"}
        }
      ]
    end

    defp pick_view_and_row(active_rows, resolved_rows, nil, current_view) do
      default_view =
        if current_view == "resolved" and resolved_rows != [], do: "resolved", else: "active"

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
      base_query =
        from(preview in RepairPreview,
          where:
            preview.action == ^row.action and preview.target_type == ^row.target_type and
              preview.target_id == ^row.target_id and
              preview.status in ["ready", "drifted", "expired", "consumed"],
          order_by: [desc: preview.inserted_at],
          limit: 1
        )

      query =
        if row.incident.id do
          from(preview in base_query, where: preview.incident_id == ^row.incident.id)
        else
          from(preview in base_query,
            where: preview.incident_fingerprint == ^row.incident.incident_fingerprint
          )
        end

      repo.one(query)
    end

    defp load_target_detail(%{target_type: "job", target_id: target_id})
         when is_binary(target_id) do
      case Integer.parse(target_id) do
        {job_id, ""} -> %{job_id: job_id}
        _ -> %{job_id: nil}
      end
    end

    defp load_target_detail(%{target_type: "job"}), do: %{job_id: nil}

    defp load_target_detail(%{target_type: "workflow_step", target_id: target_id}) do
      case repo().get(Step, target_id) do
        nil -> %{job_id: nil}
        step -> %{job_id: step.job_id}
      end
    end

    defp load_target_detail(%{target_type: "workflow"}), do: %{job_id: nil}

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

    defp find_row!(rows, row_id),
      do: Enum.find(rows, &(&1.id == row_id)) || raise("incident row not found")

    defp selected_fingerprint(nil), do: nil
    defp selected_fingerprint(row), do: row.incident.incident_fingerprint

    defp selection_path(selection) do
      Selectors.lifeline_path([
        {"view", Map.get(selection, :view)},
        {"incident_fingerprint", Map.get(selection, :incident_fingerprint)},
        {"row-id", Map.get(selection, :row_id)},
        {"workflow_id", Map.get(selection, :workflow_id)},
        {"step", Map.get(selection, :step_name)},
        {"action", Map.get(selection, :action)}
      ])
    end

    defp preview_action(row, actor) do
      cond do
        not row.previewable? ->
          %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:preview_not_available)}

        LiveAuth.authorized?(actor, :preview_repair, row.resource) ->
          %{enabled?: true, disabled_reason: nil}

        true ->
          %{enabled?: false, disabled_reason: LiveAuth.permission_message(:preview_repair)}
      end
    end

    defp execute_action(nil, _reason, _actor, _row),
      do: %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:preview_not_available)}

    defp execute_action(%RepairPreview{status: "drifted"}, _reason, _actor, _row),
      do: %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:preview_drifted)}

    defp execute_action(%RepairPreview{status: "expired"}, _reason, _actor, _row),
      do: %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:preview_expired)}

    defp execute_action(%RepairPreview{status: "consumed"}, _reason, _actor, _row),
      do: %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:preview_consumed)}

    defp execute_action(preview, reason, actor, row) do
      cond do
        not LiveAuth.authorized?(actor, :execute_repair, row.resource) ->
          %{enabled?: false, disabled_reason: LiveAuth.permission_message(:execute_repair)}

        preview.status != "ready" ->
          %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:mutation_conflict)}

        String.trim(reason) == "" ->
          %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:reason_required)}

        String.trim(reason) |> String.length() < 8 ->
          %{enabled?: false, disabled_reason: LiveAuth.mutation_error(:reason_too_short)}

        true ->
          %{enabled?: true, disabled_reason: nil}
      end
    end

    defp preview_state(%RepairPreview{status: "drifted"}), do: :drifted
    defp preview_state(%RepairPreview{status: "expired"}), do: :expired
    defp preview_state(%RepairPreview{status: "consumed"}), do: :consumed
    defp preview_state(%RepairPreview{}), do: :ready

    defp preview_badge_class(:ready),
      do:
        "rounded border border-indigo-300 bg-indigo-50 px-3 py-1 text-sm font-medium text-indigo-700"

    defp preview_badge_class(:drifted),
      do:
        "rounded border border-amber-300 bg-amber-50 px-3 py-1 text-sm font-medium text-amber-800"

    defp preview_badge_class(:expired),
      do:
        "rounded border border-slate-300 bg-slate-50 px-3 py-1 text-sm font-medium text-slate-700"

    defp preview_badge_class(:consumed),
      do:
        "rounded border border-emerald-300 bg-emerald-50 px-3 py-1 text-sm font-medium text-emerald-700"

    defp preview_badge_copy(:ready), do: "Preview Ready"
    defp preview_badge_copy(:drifted), do: "Preview Drifted"
    defp preview_badge_copy(:expired), do: "Preview Expired"
    defp preview_badge_copy(:consumed), do: "Preview Consumed"

    defp severity_rank(%Incident{incident_class: "dead_executor", health_state: "missing"}), do: 0
    defp severity_rank(%Incident{incident_class: "workflow_stuck"}), do: 1
    defp severity_rank(_incident), do: 2

    defp health_label(nil), do: "Needs Review"
    defp health_label(state), do: Lifeline.health_label(state)

    defp badge_class(_health_state, "resolved"),
      do:
        "rounded border border-emerald-200 bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700"

    defp badge_class("missing", _status),
      do: "rounded border border-red-200 bg-red-50 px-2 py-1 text-xs font-medium text-red-700"

    defp badge_class("late", _status),
      do:
        "rounded border border-amber-200 bg-amber-50 px-2 py-1 text-xs font-medium text-amber-700"

    defp badge_class(_health_state, _status),
      do:
        "rounded border border-slate-200 bg-slate-50 px-2 py-1 text-xs font-medium text-slate-700"

    defp incident_view_heading("resolved"), do: "Resolved Incidents"
    defp incident_view_heading(_view), do: "Needs Review"

    defp incident_view_copy("resolved"),
      do: "Resolved incidents preserve repair outcomes and inline audit evidence after execution."

    defp incident_view_copy(_view),
      do:
        "Active incidents keep preview, reason, and audit evidence close to the affected resource."

    defp empty_view_copy("resolved"), do: "No resolved incidents are available yet."
    defp empty_view_copy(_view), do: "No active incidents need review right now."

    defp view_toggle_class(true),
      do:
        "rounded border border-indigo-300 bg-indigo-50 px-3 py-2 text-sm font-medium text-indigo-700"

    defp view_toggle_class(false),
      do: "rounded border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-600"

    defp detection_basis(%Incident{incident_class: "dead_executor"}),
      do: "Executor heartbeat evidence"

    defp detection_basis(%Incident{incident_class: "workflow_stuck"}),
      do: "Workflow blocker evidence"

    defp detection_basis(%Incident{incident_class: "workflow_action"}),
      do: "Workflow diagnosis evidence"

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

    defp affected_records_copy(%Incident{workflow_step_id: step_id, evidence: evidence})
         when not is_nil(step_id) do
      step_name = Map.get(evidence || %{}, "step_name", "workflow step")
      blocker_codes = Map.get(evidence || %{}, "blocker_codes", [])
      "#{step_name} (#{step_id}) blocked by #{Enum.join(blocker_codes, ", ")}"
    end

    defp affected_records_copy(%Incident{workflow_id: workflow_id, evidence: evidence}) do
      workflow_name = Map.get(evidence || %{}, "workflow_name", workflow_id)
      diagnosis = Map.get(evidence || %{}, "diagnosis", "unknown")
      "#{workflow_name} is currently telling the durable story #{diagnosis}"
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

    defp state_copy(%{"workflow_id" => id, "state" => state} = snapshot) do
      diagnosis = snapshot["diagnosis"] || "none"
      "workflow #{id} is #{state} with diagnosis #{diagnosis}"
    end

    defp state_copy(snapshot) when is_map(snapshot), do: inspect(snapshot)

    defp resource_copy(row), do: "#{row.target_type}:#{row.target_id}"

    defp count_label(counts, key),
      do: "#{Map.get(counts || %{}, key, 0)} #{Phoenix.Naming.humanize(key)}"

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

    defp preview_actor_label(actor) do
      case ObanPowertools.Auth.audit_principal(actor) do
        {:ok, principal} ->
          DisplayPolicy.actor_label(principal, %{surface: :lifeline, section: :preview})

        {:error, _reason} ->
          "Audit principal unavailable"
      end
    end

    defp preview_reason(reason) do
      DisplayPolicy.reason(reason, %{surface: :lifeline, section: :preview})
    end

    defp preview_status_copy(nil), do: "preview_not_available"

    defp preview_status_copy(%RepairPreview{status: status}),
      do: RepairPreview.canonical_status(status)

    defp repair_preview_value(%RepairPreview{} = preview),
      do: Map.fetch!(preview, repair_preview_key())

    defp repair_preview_key, do: :preview_token

    defp event_actor_label(event) do
      event
      |> Audit.event_principal()
      |> DisplayPolicy.actor_label(%{
        surface: :lifeline,
        section: :audit_history,
        event: event.action
      })
    end

    defp event_reason(event) do
      event
      |> Audit.event_reason()
      |> DisplayPolicy.reason(%{surface: :lifeline, section: :audit_history, event: event.action})
    end

    defp runbook_continuity(preview, audit_events) do
      case preview_runbook_context(preview) do
        %{} = context -> context
        _missing -> latest_audit_runbook_context(audit_events)
      end
    end

    defp preview_runbook_context(nil), do: nil

    defp preview_runbook_context(%RepairPreview{} = preview) do
      case get_in(preview.metadata || %{}, ["runbook_context"]) do
        %{} = context -> context
        _missing -> nil
      end
    end

    defp latest_audit_runbook_context(audit_events) do
      Enum.find_value(audit_events || [], fn event ->
        case get_in(event.metadata || %{}, ["runbook_context"]) do
          %{} = context -> context
          _missing -> nil
        end
      end)
    end

    defp continuity_diagnosis(runbook_context) do
      Map.get(runbook_context || %{}, "diagnosis_state", "unknown")
    end

    defp continuity_legal_next_path(runbook_context) do
      selected_path = continuity_selected_path(runbook_context)
      intent = Map.get(selected_path, "intent", "investigate")

      ownership =
        ControlPlanePresenter.runbook_ownership_label(Map.get(selected_path, "ownership"))

      "#{intent} via #{ownership}"
    end

    defp continuity_venue(runbook_context) do
      selected_path = continuity_selected_path(runbook_context)

      Map.get(selected_path, "venue") ||
        ControlPlanePresenter.runbook_ownership_label(Map.get(selected_path, "ownership"))
    end

    defp continuity_attempt_state(runbook_context) do
      get_in(runbook_context || %{}, ["attempt", "state"]) || "unknown"
    end

    defp continuity_selected_path(runbook_context) do
      case Map.get(runbook_context || %{}, "selected_path") do
        %{} = selected_path -> selected_path
        _missing -> %{}
      end
    end

    defp host_follow_up_status_label(audit_events) do
      case latest_host_follow_up_event(audit_events) do
        nil ->
          "Host-owned follow-up unavailable"

        event ->
          event
          |> read_host_follow_up_status()
          |> ControlPlanePresenter.host_follow_up_status_label()
      end
    end

    defp host_follow_up_status_detail(audit_events) do
      case latest_host_follow_up_event(audit_events) do
        nil ->
          "No host escalation hook configured"

        event ->
          details = event.metadata["details"] || %{}

          case event.metadata["status"] do
            "host_owned_follow_up_unconfigured" ->
              details["configuration"] || "No host escalation hook configured"

            "host_owned_follow_up_callback_failed" ->
              details["reason"] || "Host-owned follow-up callback failed"

            _other ->
              nil
          end
      end
    end

    defp latest_host_follow_up_event(audit_events) do
      Enum.find(audit_events || [], &(&1.action == "lifeline.host_follow_up"))
    end

    defp latest_audit_follow_up_path([]), do: nil
    defp latest_audit_follow_up_path([event | _rest]), do: ControlPlanePresenter.audit_follow_up_path(event)

    defp read_host_follow_up_status(nil), do: "host_owned_follow_up_unconfigured"

    defp read_host_follow_up_status(event) do
      event.metadata["status"] || "host_owned_follow_up_unconfigured"
    end

    defp error_message(:preview_not_found), do: LiveAuth.mutation_error(:preview_not_available)

    defp error_message(:preview_not_available),
      do: LiveAuth.mutation_error(:preview_not_available)

    defp error_message(:preview_drifted), do: LiveAuth.mutation_error(:preview_drifted)
    defp error_message(:preview_expired), do: LiveAuth.mutation_error(:preview_expired)
    defp error_message(:preview_consumed), do: LiveAuth.mutation_error(:preview_consumed)
    defp error_message(:reason_required), do: LiveAuth.mutation_error(:reason_required)
    defp error_message(:reason_too_short), do: LiveAuth.mutation_error(:reason_too_short)

    defp error_message(:incident_still_active),
      do:
        "The repair target changed, but the incident still has live evidence. Refresh and review the remaining active records."

    defp error_message(:unauthorized), do: LiveAuth.mutation_error(:unauthorized)
    defp error_message(reason), do: inspect(reason)

    defp read_only_page?(actor, rows) do
      checks =
        Enum.flat_map(rows, fn row ->
          [
            {:preview_repair, row.resource},
            {:execute_repair, row.resource}
          ]
        end)

      rows != [] and not LiveAuth.any_authorized?(actor, checks)
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)

    defp selection_from_params(params) do
      %{
        view: params["view"],
        row_id: params["row-id"],
        incident_fingerprint: params["incident_fingerprint"],
        workflow_id: params["workflow_id"],
        step_name: params["step"],
        action: params["action"]
      }
    end

    defp forensic_path(row, current_view) do
      Selectors.forensic_path([
        {"incident_fingerprint", row.incident.incident_fingerprint},
        {"view", current_view},
        {"resource_type", row.target_type},
        {"resource_id", row.target_id}
      ])
    end

    defp follow_up_variant(path_or_venue) do
      path_or_venue
      |> ControlPlanePresenter.follow_up_render_variant()
      |> Atom.to_string()
    end

    defp follow_up_row_class(path_or_venue) do
      case ControlPlanePresenter.follow_up_render_variant(path_or_venue) do
        :native_primary ->
          "rounded border border-indigo-300 bg-indigo-100 px-2 py-1 font-semibold text-indigo-900"

        :bridge_guidance ->
          "rounded border border-slate-300 bg-white px-2 py-1 text-slate-700"

        :host_guidance ->
          "rounded border border-amber-300 bg-amber-100 px-2 py-1 text-amber-900"
      end
    end

    defp workflow_handoff_row(_repo, nil), do: nil

    defp workflow_handoff_row(repo, %{workflow_id: workflow_id, action: action} = selection)
         when is_binary(workflow_id) and is_binary(action) do
      workflow = repo.get(Workflow, workflow_id)
      step = resolve_step(repo, workflow, Map.get(selection, :step_name))

      with %Workflow{} = workflow <- workflow,
           {:ok, row} <- build_workflow_handoff_row(repo, workflow, step, action) do
        row
      else
        _ -> nil
      end
    end

    defp workflow_handoff_row(_repo, _selection), do: nil

    defp build_workflow_handoff_row(repo, workflow, step, action) do
      steps =
        repo.all(
          from(workflow_step in Step,
            where: workflow_step.workflow_id == ^workflow.id,
            order_by: [asc: workflow_step.position]
          )
        )

      workflow_story = Explain.workflow_story(workflow, steps, repo: repo)
      step_story = step && Explain.step_story(step, repo: repo)

      available_actions =
        ((step_story && step_story.executable_actions) || []) ++ workflow_story.executable_actions

      case Enum.find(available_actions, &(&1.id == action)) do
        nil ->
          :error

        action_info ->
          incident = %Incident{
            id: nil,
            incident_class: "workflow_action",
            status: "active",
            workflow_id: workflow.id,
            workflow_step_id: step && step.id,
            incident_fingerprint:
              "workflow_action:#{workflow.id}:#{(step && step.id) || "workflow"}:#{action}",
            summary: handoff_summary(workflow, step, action_info),
            affected_counts: %{
              "jobs" => 0,
              "workflow_steps" => if(step, do: 1, else: workflow.step_count)
            },
            evidence: %{
              "workflow_name" => workflow.name,
              "step_name" => step && step.step_name,
              "diagnosis" => (step_story && step_story.diagnosis) || workflow_story.diagnosis
            }
          }

          {:ok,
           %{
             id: "workflow_action:#{workflow.id}:#{(step && step.id) || "workflow"}:#{action}",
             incident: incident,
             action: action,
             action_label: action_info.label,
             target_type: action_info.target_type,
             target_id: to_string(action_info.target_id),
             target_summary: handoff_summary(workflow, step, action_info),
             previewable?: true,
             resource: %{
               type: TargetType.to_atom(action_info.target_type),
               id: to_string(action_info.target_id)
             },
             workflow_id: workflow.id,
             step_name: step && step.step_name
           }}
      end
    end

    defp prepend_handoff_row(rows, nil), do: rows

    defp prepend_handoff_row(rows, row) do
      [row | Enum.reject(rows, &(&1.id == row.id))]
    end

    defp resolve_step(_repo, _workflow, nil), do: nil

    defp resolve_step(repo, workflow, step_name) do
      repo.one(
        from(step in Step,
          where: step.workflow_id == ^workflow.id and step.step_name == ^step_name,
          limit: 1
        )
      )
    end

    defp primary_workflow_action(actions) do
      Enum.find(actions, &(&1.id == "workflow_step_retry")) ||
        Enum.find(actions, &(&1.id == "workflow_step_cancel")) ||
        %{id: "workflow_step_retry", label: "Retry step"}
    end

    defp handoff_summary(workflow, nil, action_info),
      do: "#{action_info.label} for workflow #{workflow.name || workflow.id}"

    defp handoff_summary(workflow, step, action_info),
      do: "#{action_info.label} for #{step.step_name} in workflow #{workflow.name || workflow.id}"
  end
end
