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
         |> assign(:confirmation_action, nil)
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
       |> assign(:confirmation_action, nil)
       |> assign(:confirmation_result, nil)
       |> assign(:receipt, nil)}
    end

    @impl true
    def handle_event("close_detail", _params, socket) do
      {:noreply, push_patch(socket, to: Selectors.cron_path([]), replace: true)}
    end

    @impl true
    def handle_event("open_pause_confirmation", _params, socket),
      do: open_confirmation(socket, "pause_cron_entry")

    def handle_event("open_resume_confirmation", _params, socket),
      do: open_confirmation(socket, "resume_cron_entry")

    def handle_event("open_run_now_confirmation", _params, socket),
      do: open_confirmation(socket, "run_cron_entry")

    def handle_event("validate_confirmation", %{"confirmation" => params}, socket) do
      {form, reason, errors} = validate_confirmation(params)

      {:noreply,
       assign(socket,
         confirmation_form: form,
         reason: reason,
         confirmation_state: :preview,
         confirmation_result: nil,
         error_message: first_confirmation_error(errors)
       )}
    end

    def handle_event("validate_confirmation", _params, socket), do: {:noreply, socket}

    def handle_event("submit_confirmation", _params, %{assigns: %{preview: nil}} = socket),
      do: {:noreply, socket}

    def handle_event("submit_confirmation", %{"confirmation" => params}, socket) do
      {form, reason, errors} = validate_confirmation(params)
      preview = socket.assigns.preview
      entry_name = socket.assigns.selected_entry && socket.assigns.selected_entry.name
      resource = %{type: :cron_entry, id: entry_name}

      if errors != %{} do
        {:noreply,
         assign(socket,
           confirmation_form: form,
           reason: reason,
           confirmation_state: :preview,
           confirmation_result: nil,
           error_message: first_confirmation_error(errors)
         )}
      else
        result =
          with :ok <- LiveAuth.authorize_action(socket, auth_action(preview.action), resource),
               {:ok, principal} <- LiveAuth.principal_for_action(socket),
               {:ok, result} <- perform_action(preview, principal, reason) do
            {:ok, result}
          end

        {:noreply,
         apply_confirmation_result(socket, preview.action, entry_name, result, form, reason)}
      end
    end

    def handle_event("submit_confirmation", _params, socket), do: {:noreply, socket}

    def handle_event("dismiss_confirmation", _params, socket) do
      {:noreply, close_confirmation(socket)}
    end

    def handle_event("create_new_preview", _params, socket) do
      case socket.assigns.confirmation_action do
        %{kind: kind} -> open_confirmation(socket, backend_action(kind), socket.assigns.reason)
        _missing -> {:noreply, socket}
      end
    end

    def handle_event("dismiss_receipt", _params, socket) do
      {:noreply, assign(socket, :receipt, nil)}
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

        <OperatorPatterns.confirm_action_dialog
          :if={@confirmation_open? && @selected_entry && @confirmation_action}
          id="cron-confirmation"
          intent={@confirmation_action.intent}
          state={@confirmation_state}
          title={@confirmation_action.title}
          object_label={@selected_entry.name}
          scope={"Cron entry #{@selected_entry.name}"}
          consequence={@confirmation_action.consequence}
          reversibility={confirmation_reversibility(@confirmation_action.kind)}
          support_boundary={@confirmation_action.support_boundary}
          form={@confirmation_form}
          confirm_label={@confirmation_action.confirm_label}
          dismiss_label={@confirmation_action.dismiss_label}
          pending_copy={@confirmation_action.pending_copy}
          logical_fallback_id={confirmation_fallback_id(@selected_entry, @confirmation_action.kind)}
          submit_event="submit_confirmation"
          dismiss_event="dismiss_confirmation"
          dismissible={@confirmation_state != :submitting}
          results={confirmation_results(@confirmation_result, @selected_entry.name)}
        >
          <:recovery>
            <Primitives.button
              :if={recoverable_confirmation?(@confirmation_state)}
              variant={:primary}
              phx-click="create_new_preview"
            >
              Create new preview
            </Primitives.button>
          </:recovery>
          <:audit>
            <Primitives.link
              :if={@confirmation_result && @confirmation_result.audit_href}
              href={@confirmation_result.audit_href}
            >
              Open audit evidence
            </Primitives.link>
          </:audit>
          <:support_details>
            <p>Actor: {confirmation_actor_label(@current_actor)}</p>
            <p>{LiveAuth.audit_consequence_copy()}</p>
            <p :if={recoverable_confirmation?(@confirmation_state) && @reason != ""}>
              Reason draft: {@reason}
            </p>
            <p :if={@error_message}>{@error_message}</p>
          </:support_details>
        </OperatorPatterns.confirm_action_dialog>

        <DataDisplay.toast
          :if={@receipt}
          id="cron-receipt"
          tone={:success}
          urgency={:polite}
          dismiss_event="dismiss_receipt"
          dismiss_key="cron-receipt"
        >
          <p>{@receipt.message}</p>
          <Primitives.link href={@receipt.audit_href}>Open audit evidence</Primitives.link>
        </DataDisplay.toast>
      </section>
      """
    end

    defp open_confirmation(socket, action, reason \\ "") do
      entry = socket.assigns.selected_entry

      with %{name: entry_name} <- entry,
           true <- action_available?(entry, action),
           resource = %{type: :cron_entry, id: entry_name},
           :ok <-
             LiveAuth.authorize_action(socket, auth_action(action), resource,
               message: unauthorized_preview_message(action)
             ),
           {:ok, preview} <- Cron.preview_entry_action(repo(), action, entry) do
        Telemetry.execute_operator_action(:previewed, %{count: 1}, %{
          action: action,
          source: entry.source
        })

        reason = safe_reason_draft(reason)

        {:noreply,
         assign(socket,
           preview: preview,
           reason: reason,
           error_message: nil,
           detail_open?: false,
           confirmation_form: confirmation_form(reason),
           confirmation_state: :preview,
           confirmation_action:
             ControlPlanePresenter.present_cron_action(%{
               kind: action_kind_atom(action),
               object_label: entry.name
             }),
           confirmation_result: nil,
           confirmation_open?: true,
           receipt: nil
         )}
      else
        {:error, message} when is_binary(message) ->
          {:noreply, assign(socket, :error_message, message)}

        {:error, reason} ->
          {:noreply, assign(socket, :error_message, confirmation_error_message(reason))}

        _missing_or_unavailable ->
          {:noreply, socket}
      end
    end

    defp apply_confirmation_result(socket, action, entry_name, {:ok, result}, form, reason) do
      presentation =
        ControlPlanePresenter.present_cron_result(%{
          kind: action_kind_atom(action),
          state: cron_result_state(action, result),
          object_label: entry_name,
          recorded_result: recorded_result(action, result),
          audit_href: audit_path(entry_name)
        })

      if presentation.state == :success do
        apply_clean_success(socket, entry_name, presentation)
      else
        assign_recoverable_result(socket, presentation, form, reason)
      end
    end

    defp apply_confirmation_result(socket, action, _entry_name, {:error, reason}, form, draft) do
      state = cron_error_state(reason)

      presentation =
        ControlPlanePresenter.present_cron_result(%{
          kind: action_kind_atom(action),
          state: state,
          audit_href: nil
        })

      socket
      |> assign_recoverable_result(presentation, form, draft)
      |> assign(:error_message, confirmation_error_message(reason))
      |> assign(:confirmation_state, confirmation_state(state))
      |> then(fn socket ->
        if is_binary(reason), do: assign(socket, :error_message, reason), else: socket
      end)
    end

    defp apply_clean_success(socket, entry_name, presentation) do
      entries = Cron.list_entries(repo())
      selected_entry = Enum.find(entries, &(&1.name == entry_name))

      socket
      |> assign_entries(entries)
      |> assign_selected_entry(selected_entry)
      |> assign(:detail_open?, not is_nil(selected_entry))
      |> assign(:preview, nil)
      |> assign(:reason, "")
      |> assign(:error_message, nil)
      |> assign(:confirmation_form, confirmation_form())
      |> assign(:confirmation_state, :preview)
      |> assign(:confirmation_action, nil)
      |> assign(:confirmation_result, nil)
      |> assign(:confirmation_open?, false)
      |> assign(:receipt, %{message: presentation.receipt, audit_href: presentation.audit_href})
    end

    defp assign_recoverable_result(socket, presentation, form, reason) do
      assign(socket,
        confirmation_form: form,
        confirmation_state: confirmation_state(presentation.state),
        confirmation_result: presentation,
        confirmation_open?: true,
        detail_open?: false,
        reason: reason,
        error_message: nil,
        receipt: nil
      )
    end

    defp close_confirmation(socket) do
      socket
      |> assign(:preview, nil)
      |> assign(:reason, "")
      |> assign(:error_message, nil)
      |> assign(:detail_open?, not is_nil(socket.assigns.selected_entry))
      |> assign(:confirmation_form, confirmation_form())
      |> assign(:confirmation_state, :preview)
      |> assign(:confirmation_action, nil)
      |> assign(:confirmation_result, nil)
      |> assign(:confirmation_open?, false)
    end

    defp validate_confirmation(params) when is_map(params) do
      reason = params |> Map.get("reason", "") |> safe_reason_draft()
      errors = if reason == "", do: %{reason: ["Enter a reason before continuing."]}, else: %{}
      {confirmation_form(reason, errors), reason, errors}
    end

    defp confirmation_form(reason \\ "", errors \\ %{}) do
      Phoenix.Component.to_form(%{"reason" => reason},
        as: :confirmation,
        errors: form_errors(errors)
      )
    end

    defp form_errors(errors) do
      Enum.flat_map(errors, fn {field, messages} ->
        Enum.map(messages, &{field, {&1, []}})
      end)
    end

    defp first_confirmation_error(%{reason: [message | _]}), do: message
    defp first_confirmation_error(_errors), do: nil

    defp confirmation_results(nil, _entry_name), do: []

    defp confirmation_results(result, entry_name) do
      outcome = if result.state in [:skipped, :duplicate], do: :skipped, else: :failed

      [
        %{
          id: "cron-result",
          object_label: entry_name,
          outcome: outcome,
          message: result.message,
          recovery: result.recovery,
          audit_href: result.audit_href
        }
      ]
    end

    defp confirmation_state(state) when state in [:expired, :drifted, :consumed], do: state
    defp confirmation_state(state) when state in [:skipped, :duplicate, :partial], do: :partial
    defp confirmation_state(_state), do: :failed

    defp recoverable_confirmation?(state),
      do: state in [:partial, :failed, :expired, :drifted, :consumed]

    defp confirmation_reversibility(:pause),
      do: "Resume the cron entry later to allow future schedule claims again."

    defp confirmation_reversibility(:resume),
      do: "Pause the cron entry again later to stop future schedule claims."

    defp confirmation_reversibility(:run_now),
      do: "The recorded manual slot claim cannot be withdrawn after submission."

    defp confirmation_fallback_id(entry, kind) do
      entry_action_id(entry, %{action: backend_action(kind)})
    end

    defp confirmation_actor_label(actor) do
      case ObanPowertools.Auth.audit_principal(actor) do
        {:ok, principal} ->
          DisplayPolicy.actor_label(principal, %{surface: :cron, section: :confirmation})

        {:error, _reason} ->
          "Audit principal unavailable"
      end
    end

    defp action_available?(entry, action),
      do: Enum.any?(base_actions(entry), &(&1.action == action))

    defp action_kind_atom("pause_cron_entry"), do: :pause
    defp action_kind_atom("resume_cron_entry"), do: :resume
    defp action_kind_atom("run_cron_entry"), do: :run_now

    defp backend_action(:pause), do: "pause_cron_entry"
    defp backend_action(:resume), do: "resume_cron_entry"
    defp backend_action(:run_now), do: "run_cron_entry"

    defp cron_result_state("run_cron_entry", %{decision: %{decision: "skipped"}}),
      do: :skipped

    defp cron_result_state("run_cron_entry", %{decision: %{decision: "duplicate"}}),
      do: :duplicate

    defp cron_result_state(_action, _result), do: :success

    defp cron_error_state(:preview_expired), do: :expired
    defp cron_error_state(:preview_drifted), do: :drifted
    defp cron_error_state(:preview_consumed), do: :consumed
    defp cron_error_state(_reason), do: :failed

    defp recorded_result("run_cron_entry", %{decision: %{decision: decision}}),
      do: recorded_decision(decision)

    defp recorded_result(_action, _result), do: nil

    defp recorded_decision("allow"), do: "work enqueued"
    defp recorded_decision("enqueued"), do: "work enqueued"
    defp recorded_decision("queued_follow_up"), do: "follow-up queued"

    defp recorded_decision("cancelled_previous"),
      do: "previous work canceled and new work enqueued"

    defp recorded_decision("skipped"), do: "overlap policy skipped the slot claim"
    defp recorded_decision("duplicate"), do: "duplicate slot claim recorded"
    defp recorded_decision(_decision), do: "slot claim result recorded"

    defp audit_path(entry_name),
      do: Selectors.audit_path(resource_type: "cron_entry", resource_id: entry_name)

    defp safe_reason_draft(reason) when is_binary(reason), do: String.trim(reason)
    defp safe_reason_draft(_reason), do: ""

    defp confirmation_error_message(:preview_expired), do: "This preview expired."
    defp confirmation_error_message(:preview_drifted), do: "This preview is out of date."
    defp confirmation_error_message(:preview_consumed), do: "This preview was already used."

    defp confirmation_error_message(:preview_not_found),
      do: "This preview is unavailable. Create a new preview before continuing."

    defp confirmation_error_message(:preview_not_available),
      do: "This action is no longer available for the selected cron entry."

    defp confirmation_error_message(reason) when is_binary(reason), do: reason

    defp confirmation_error_message(_reason),
      do: "The cron action could not be recorded. Create a new preview before trying again."

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
        %{action: "pause_cron_entry", label: "Pause cron entry", emphasis: :secondary},
        %{action: "run_cron_entry", label: "Run cron entry now", emphasis: :primary}
      ]
    end

    defp base_actions(_entry) do
      [
        %{action: "resume_cron_entry", label: "Resume cron entry", emphasis: :secondary},
        %{action: "run_cron_entry", label: "Run cron entry now", emphasis: :primary}
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

    defp blank_to_nil(value) when is_binary(value) do
      case String.trim(value) do
        "" -> nil
        trimmed -> trimmed
      end
    end

    defp blank_to_nil(_value), do: nil
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
