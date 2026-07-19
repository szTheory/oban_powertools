if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.CronLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{ControlPlane, Cron, DisplayPolicy, Telemetry}
    alias ObanPowertools.Forensics.CronHistory
    alias ObanPowertools.Lifeline.RepairPreview
    alias ObanPowertools.Web.Components.{DataDisplay, OperatorPatterns, Primitives}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

    @impl true
    def mount(_params, _mount_payload, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_cron, %{type: :page, id: "cron"}) do
        :ok = DisplayPolicy.assert_configured!()

        {:ok,
         socket
         |> assign_entries(Cron.list_entries(repo()))
         |> assign(:selected_entry, nil)
         |> assign(:detail_open?, false)
         |> assign(:preview, nil)
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign(:confirmation_form, nil)
         |> assign(:confirmation_state, :preview)
         |> assign(:confirmation_result, nil)
         |> assign(:confirmation_open?, false)
         |> assign(:receipt, nil)}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      entries = Cron.list_entries(repo())
      selected_entry = Enum.find(entries, &(&1.name == params["entry"]))

      {:noreply,
       socket
       |> assign_entries(entries)
       |> assign_selected_entry(selected_entry)
       |> assign(:detail_open?, not is_nil(selected_entry))
       |> assign(:confirmation_open?, false)
       |> assign(:preview, nil)
       |> assign(:reason, "")
       |> assign(:error_message, nil)
       |> assign(:confirmation_result, nil)
       |> assign(:receipt, nil)}
    end

    @impl true
    def handle_event("close_detail", _params, socket) do
      {:noreply, push_patch(socket, to: Selectors.cron_path([]), replace: true)}
    end

    @impl true
    def handle_event("preview", %{"action" => action, "entry" => entry_name}, socket) do
      entry = find_entry!(entry_name)
      resource = %{type: :cron_entry, id: entry.name}

      with :ok <-
             LiveAuth.authorize_action(socket, auth_action(action), resource,
               message: unauthorized_preview_message(action)
             ),
           {:ok, preview} <- Cron.preview_entry_action(repo(), action, entry) do
        Telemetry.execute_operator_action(:previewed, %{count: 1}, %{
          action: action,
          source: entry.source
        })

        {:noreply,
         socket
         |> assign_selected_entry(entry)
         |> assign(:preview, preview)
         |> assign(:reason, "")
         |> assign(:error_message, nil)}
      else
        {:error, message} when is_binary(message) ->
          {:noreply,
           socket
           |> assign(:preview, nil)
           |> assign(:reason, "")
           |> assign(:error_message, message)}

        {:error, reason} ->
          {:noreply,
           socket
           |> assign(:preview, nil)
           |> assign(:reason, "")
           |> assign(:error_message, error_message(reason))}
      end
    end

    def handle_event("reason", %{"reason" => reason}, socket) do
      {:noreply, assign(socket, :reason, reason)}
    end

    def handle_event("cancel_preview", _params, socket) do
      {:noreply,
       socket |> assign(:preview, nil) |> assign(:reason, "") |> assign(:error_message, nil)}
    end

    def handle_event("confirm", _params, %{assigns: %{preview: nil}} = socket) do
      {:noreply, socket}
    end

    def handle_event("confirm", _params, socket) do
      preview = socket.assigns.preview
      entry_name = get_in(preview.metadata, ["resource", "id"])
      resource = %{type: :cron_entry, id: entry_name}

      with :ok <- LiveAuth.authorize_action(socket, auth_action(preview.action), resource),
           {:ok, principal} <- LiveAuth.principal_for_action(socket),
           {:ok, _result} <- perform_action(preview, principal, socket.assigns.reason) do
        entries = Cron.list_entries(repo())
        selected_entry = Enum.find(entries, &(&1.name == entry_name))

        {:noreply,
         socket
         |> assign(:preview, nil)
         |> assign(:reason, "")
         |> assign(:error_message, nil)
         |> assign_entries(entries)
         |> assign_selected_entry(selected_entry)}
      else
        {:error, message} when is_binary(message) ->
          {:noreply, assign(socket, :error_message, message)}

        {:error, reason} ->
          {:noreply,
           socket
           |> maybe_reload_preview(preview.preview_token)
           |> assign(:error_message, error_message(reason))}
      end
    end

    @impl true
    def render(assigns) do
      ~H"""
      <section id="cron-page" class="obpt-cron-page" aria-labelledby="cron-page-title">
        <header class="obpt-cron-page__header">
          <h1 id="cron-page-title">Cron</h1>
          <p>Review schedules, inspect one cron entry, and take deliberate action with recorded evidence.</p>
        </header>

        <Primitives.surface :if={@read_only?} variant={:inset}>
          <p>{LiveAuth.page_read_only_banner(:cron)}</p>
        </Primitives.surface>

        <DataDisplay.state_message
          :if={@error_message && !@confirmation_open?}
          id="cron-page-error"
          state={:error}
          resource="cron entries"
        >
          <p>{@error_message}</p>
        </DataDisplay.state_message>

        <DataDisplay.data_table
          id="cron-entries"
          caption="Cron entries"
          rows={@entries}
          row_id={&entry_row_id/1}
          state={cron_table_state(@entries)}
          resource="cron entries"
          row_count={length(@entries)}
        >
          <:col :let={entry} label="Entry">
            <.link
              id={entry_dom_id(entry)}
              patch={Selectors.cron_path(entry: entry.name)}
              replace={not is_nil(@selected_entry)}
              class="obpt-link"
              aria-expanded={to_string(@selected_entry && @selected_entry.name == entry.name)}
              aria-controls="cron-entry-detail"
            >
              {entry.name}
            </.link>
          </:col>
          <:col :let={entry} label="Schedule" value_kind={:literal}>
            <span>{entry.expression}</span>
            <span>{entry.timezone}</span>
          </:col>
          <:col :let={entry} label="Policies/support">
            <span>{overlap_label(entry.overlap_policy)}</span>
            <span>{catch_up_label(entry.catch_up_policy)}</span>
            <span>{source_label(entry.source)}</span>
          </:col>
          <:col :let={entry} label="State">
            <DataDisplay.status_pill domain={:cron} state={entry_status(entry)} />
          </:col>
        </DataDisplay.data_table>

        <OperatorPatterns.detail_surface
          :if={@selected_entry && @detail_open? && !@confirmation_open?}
          id="cron-entry-detail"
          title={@selected_entry.name}
          close_label="Close cron entry details"
          open={true}
          variant={:adaptive}
          state={:ready}
          resource="cron entry details"
          logical_fallback_id={entry_dom_id(@selected_entry)}
          close_event="close_detail"
          loaded_announcement={"Cron entry #{@selected_entry.name} details loaded"}
        >
          <:body>
            <DataDisplay.description_list id="cron-entry-current">
              <:item label="Current state">
                <DataDisplay.status_pill domain={:cron} state={entry_status(@selected_entry)} />
              </:item>
              <:item label="Support">{ControlPlanePresenter.native_banner()}</:item>
              <:item label="Schedule" value_kind={:literal}>{@selected_entry.expression}</:item>
              <:item label="Timezone">{@selected_entry.timezone}</:item>
              <:item label="Queue">{@selected_entry.queue}</:item>
              <:item label="Overlap policy">{overlap_label(@selected_entry.overlap_policy)}</:item>
              <:item label="Catch-up policy">{catch_up_label(@selected_entry.catch_up_policy)}</:item>
            </DataDisplay.description_list>

            <section :if={@history_summary} aria-labelledby="cron-history-title">
              <h3 id="cron-history-title">History Summary</h3>
              <p>{@history_summary.detail}</p>
              <p>{ControlPlanePresenter.forensic_completeness_label(@history_summary.completeness.state)}</p>
              <ul :if={@history_summary.slots != []}>
                <li :for={slot <- @history_summary.slots}>
                  <strong>{history_label(slot.classification)}</strong>
                  <span>{slot.detail}</span>
                </li>
              </ul>
              <section aria-labelledby="cron-runbook-title">
                <h4 id="cron-runbook-title">Open runbook entry</h4>
                <p>{@history_summary.detail}</p>
                <p>
                  Caution: partial evidence and history unavailable states stay diagnostic only until retained cron history proves what happened.
                </p>
                <ol>
                  <li :for={venue <- ["Powertools-native", "Oban Web bridge", "host-owned follow-up"]}>
                    <span
                      data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label(venue)}
                      data-runbook-variant={follow_up_variant(venue)}
                      class={follow_up_row_class(venue)}
                    >
                      {ControlPlanePresenter.runbook_ownership_label(venue)}
                    </span>
                  </li>
                </ol>
              </section>
            </section>
          </:body>
          <:actions>
            <div :for={action <- entry_actions(@selected_entry, @current_actor)}>
              <Primitives.button
                id={entry_action_id(@selected_entry, action)}
                variant={:warning}
                disabled={not action.enabled?}
                phx-click={open_confirmation_event(action.action)}
              >
                {action.label}
              </Primitives.button>
              <p :if={not action.enabled?}>{action.disabled_reason}</p>
            </div>
          </:actions>
          <:evidence>
            <Primitives.link
              :if={can_view_forensics?(@current_actor)}
              href={forensics_path(@selected_entry.name)}
            >
              Open forensic timeline
            </Primitives.link>
          </:evidence>
        </OperatorPatterns.detail_surface>
      </section>
      """
    end

    defp perform_action(%RepairPreview{action: "pause_cron_entry"} = preview, principal, reason),
      do:
        Cron.pause_cron_entry(repo(), preview.preview_token, principal.id,
          reason: blank_to_nil(reason)
        )

    defp perform_action(%RepairPreview{action: "resume_cron_entry"} = preview, principal, reason),
      do:
        Cron.resume_cron_entry(repo(), preview.preview_token, principal.id,
          reason: blank_to_nil(reason)
        )

    defp perform_action(%RepairPreview{action: "run_cron_entry"} = preview, principal, reason),
      do:
        Cron.run_cron_entry(repo(), preview.preview_token, principal.id,
          reason: blank_to_nil(reason)
        )

    defp assign_entries(socket, entries) do
      assign(socket, :entries, entries)
      |> assign(:read_only?, read_only_page?(entries, socket.assigns.current_actor))
    end

    defp assign_selected_entry(socket, nil) do
      socket
      |> assign(:selected_entry, nil)
      |> assign(:history_summary, nil)
    end

    defp assign_selected_entry(socket, entry) do
      socket
      |> assign(:selected_entry, entry)
      |> assign(:history_summary, CronHistory.summary(repo(), entry.name))
    end

    defp maybe_reload_preview(socket, preview_token) do
      assign(socket, :preview, repo().get_by(RepairPreview, preview_token: preview_token))
    end

    defp find_entry!(entry_name) do
      Enum.find(Cron.list_entries(repo()), &(&1.name == entry_name)) || raise "entry not found"
    end

    defp auth_action("pause_cron_entry"), do: :pause_cron_entry
    defp auth_action("resume_cron_entry"), do: :resume_cron_entry
    defp auth_action("run_cron_entry"), do: :run_cron_entry

    defp entry_status(entry),
      do: entry |> ControlPlane.cron_status() |> Map.fetch!(:operator_status)

    defp cron_table_state([]), do: :empty
    defp cron_table_state(_entries), do: :ready

    defp entry_row_id(entry), do: entry_dom_id(entry)

    defp entry_dom_id(entry) do
      "cron-entry-#{Base.url_encode64(entry.name, padding: false)}"
    end

    defp entry_action_id(entry, action) do
      "#{entry_dom_id(entry)}-#{action_kind(action.action)}"
    end

    defp action_kind("pause_cron_entry"), do: "pause"
    defp action_kind("resume_cron_entry"), do: "resume"
    defp action_kind("run_cron_entry"), do: "run-now"

    defp open_confirmation_event("pause_cron_entry"), do: "open_pause_confirmation"
    defp open_confirmation_event("resume_cron_entry"), do: "open_resume_confirmation"
    defp open_confirmation_event("run_cron_entry"), do: "open_run_now_confirmation"

    defp entry_actions(entry, actor) do
      entry
      |> base_actions()
      |> Enum.map(fn action ->
        Map.put(
          action,
          :enabled?,
          LiveAuth.authorized?(actor, auth_action(action.action), %{
            type: :cron_entry,
            id: entry.name
          })
        )
      end)
      |> Enum.map(fn action ->
        Map.put(action, :disabled_reason, disabled_reason(action))
      end)
    end

    defp base_actions(%{paused_at: nil}) do
      [
        %{action: "pause_cron_entry", label: "Pause Cron Entry", emphasis: :secondary},
        %{action: "run_cron_entry", label: "Run Now", emphasis: :primary}
      ]
    end

    defp base_actions(_entry) do
      [
        %{action: "resume_cron_entry", label: "Resume Cron Entry", emphasis: :secondary},
        %{action: "run_cron_entry", label: "Run Now", emphasis: :primary}
      ]
    end

    defp disabled_reason(%{enabled?: true}), do: nil

    defp disabled_reason(%{action: "pause_cron_entry"}),
      do: unauthorized_preview_message("pause_cron_entry")

    defp disabled_reason(%{action: "resume_cron_entry"}),
      do: unauthorized_preview_message("resume_cron_entry")

    defp disabled_reason(%{action: "run_cron_entry"}),
      do: unauthorized_preview_message("run_cron_entry")

    defp unauthorized_preview_message("pause_cron_entry"),
      do: LiveAuth.permission_message(:pause_cron_entry)

    defp unauthorized_preview_message("resume_cron_entry"),
      do: LiveAuth.permission_message(:resume_cron_entry)

    defp unauthorized_preview_message("run_cron_entry"),
      do: LiveAuth.permission_message(:run_cron_entry)

    defp read_only_page?(entries, actor) do
      checks =
        for entry <- entries,
            action <- base_actions(entry) do
          {auth_action(action.action), %{type: :cron_entry, id: entry.name}}
        end

      entries != [] and not LiveAuth.any_authorized?(actor, checks)
    end

    defp error_message(reason), do: LiveAuth.mutation_error(reason)

    defp source_label("code"), do: "Code"
    defp source_label(_), do: "Runtime"
    defp overlap_label("queue_one"), do: "Queue One"
    defp overlap_label(policy), do: ObanPowertools.Web.ControlPlanePresenter.humanize(policy)
    defp catch_up_label("latest"), do: "Latest Only"
    defp catch_up_label(policy), do: ObanPowertools.Web.ControlPlanePresenter.humanize(policy)
    defp history_label(:manual_run), do: "Manual run"
    defp history_label(:missed_fire), do: "Missed fire"
    defp history_label(:delayed_claim), do: "Delayed claim"
    defp history_label(:overlap_relevant), do: "Overlap-relevant"
    defp history_label(:partial_evidence), do: "Partial evidence"
    defp history_label(:unknown), do: "Unknown"
    defp history_label(:on_time), do: "On-time"

    defp can_view_forensics?(actor),
      do: LiveAuth.authorized?(actor, :view_forensics, %{type: :page, id: "forensics"})

    defp forensics_path(entry_name),
      do:
        "/ops/jobs/forensics?resource_type=cron_entry&resource_id=#{URI.encode_www_form(entry_name)}"

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

    defp blank_to_nil(""), do: nil
    defp blank_to_nil(value), do: value
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
