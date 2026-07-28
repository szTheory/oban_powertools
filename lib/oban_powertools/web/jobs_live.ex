if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.JobsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{DisplayPolicy, JobRecord, Jobs, Lifeline}
    alias ObanPowertools.Web.Components.{DataDisplay, Forms, OperatorPatterns, Primitives}
    alias ObanPowertools.Web.{ControlPlanePresenter, JobsParams, LiveAuth, Selectors}

    @valid_states ~w(available scheduled executing retryable cancelled discarded completed)
    @allowed_preview_actions ~w(job_retry job_cancel job_discard)
    @job_action_kinds %{"retry" => :retry, "cancel" => :cancel, "discard" => :discard}
    @job_action_values %{retry: "job_retry", cancel: "job_cancel", discard: "job_discard"}
    @job_action_permissions %{retry: :retry_job, cancel: :cancel_job, discard: :discard_job}
    @job_action_states %{
      retry: ~w(retryable cancelled discarded completed),
      cancel: ~w(available scheduled executing retryable),
      discard: ~w(available scheduled executing retryable)
    }
    @job_action_preview_private :oban_powertools_job_action_preview

    @impl true
    def mount(params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      action = socket.assigns.live_action

      {permission, resource_type, resource_id} =
        case action do
          :show -> {:view_job_detail, :job, params["id"]}
          _ -> {:view_jobs, :page, "jobs"}
        end

      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, permission, %{type: resource_type, id: resource_id}) do
        :ok = DisplayPolicy.assert_configured!()

        {:ok,
         socket
         |> assign(:oban_dashboard_path, dashboard_path)
         |> assign_defaults()
         |> maybe_init_live_counts()}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(%{"id" => id} = params, _uri, socket) do
      parsed_return =
        params
        |> Map.take(~w(state queue worker tags args meta page))
        |> JobsParams.parse_url()

      {:noreply, load_job_detail(socket, id, parsed_return.canonical_params)}
    end

    def handle_params(params, _uri, socket) do
      if not connected?(socket) and params == %{} do
        # The host router's disconnected render does not expose query params.
        # Keep the finite defaults and defer every index query until the
        # connected phase can canonicalize the actual URL first.
        {:noreply, socket}
      else
        parsed = JobsParams.parse_url(params)

        if connected?(socket) and parsed.replace? do
          {:noreply,
           socket
           |> maybe_assign_url_notice(parsed.notices)
           |> reset_browse_transients()
           |> push_patch(
             to: Selectors.jobs_path(parsed.canonical_params),
             replace: true
           )}
        else
          {:noreply,
           socket
           |> maybe_assign_url_notice(parsed.notices)
           |> load_jobs(parsed.query, parsed.quick_review_id)}
        end
      end
    end

    @impl true
    def handle_event("select_state", %{"state" => state}, socket) do
      if state in @valid_states do
        query = %{socket.assigns.filter | state: String.to_existing_atom(state), page: 1}

        {:noreply,
         socket
         |> assign(:url_notice, nil)
         |> assign(:review_notice, nil)
         |> reset_browse_transients()
         |> push_patch(to: Selectors.jobs_path(canonical_params(query)))}
      else
        {:noreply, socket}
      end
    end

    def handle_event("validate_filters", %{"filter" => params}, socket) do
      validation = JobsParams.validate_draft(params)
      {:noreply, assign_filter_draft(socket, validation)}
    end

    def handle_event("validate_filters", _params, socket), do: {:noreply, socket}

    def handle_event("apply_filters", %{"filter" => params}, socket) do
      validation = JobsParams.validate_draft(params)

      if validation.valid? do
        query =
          socket.assigns.filter
          |> Map.merge(validation.applied)
          |> Map.put(:page, 1)

        {:noreply,
         socket
         |> assign_filter_draft(validation)
         |> assign(:url_notice, nil)
         |> assign(:review_notice, nil)
         |> reset_browse_transients()
         |> push_patch(to: Selectors.jobs_path(canonical_params(query)))}
      else
        {:noreply, assign_filter_draft(socket, validation)}
      end
    end

    def handle_event("apply_filters", _params, socket), do: {:noreply, socket}

    def handle_event("remove_filter", %{"filter" => field}, socket)
        when field in ~w(queue worker tags args meta) do
      query =
        socket.assigns.filter
        |> Map.put(String.to_existing_atom(field), nil)
        |> Map.put(:page, 1)

      {:noreply,
       socket
       |> assign(:url_notice, nil)
       |> assign(:review_notice, nil)
       |> reset_browse_transients()
       |> push_patch(to: Selectors.jobs_path(canonical_params(query)))}
    end

    def handle_event("remove_filter", _params, socket), do: {:noreply, socket}

    def handle_event("clear_filters", _params, socket) do
      query = %Jobs{state: socket.assigns.filter.state}

      {:noreply,
       socket
       |> assign(:url_notice, nil)
       |> assign(:review_notice, nil)
       |> reset_browse_transients()
       |> push_patch(to: Selectors.jobs_path(canonical_params(query)))}
    end

    def handle_event("toggle_job", %{"id" => id_str}, socket) do
      case Integer.parse(id_str) do
        {id, ""} ->
          if id in socket.assigns.page_job_ids do
            selected_jobs = socket.assigns.selected_jobs

            selected_jobs =
              if MapSet.member?(selected_jobs, id) do
                MapSet.delete(selected_jobs, id)
              else
                MapSet.put(selected_jobs, id)
              end

            {:noreply, refresh_selection(socket, selected_jobs, false)}
          else
            {:noreply, socket}
          end

        _invalid ->
          {:noreply, socket}
      end
    end

    def handle_event("toggle_page", _, socket) do
      job_ids = socket.assigns.page_job_ids
      selected_jobs = socket.assigns.selected_jobs
      all_selected? = job_ids != [] and Enum.all?(job_ids, &MapSet.member?(selected_jobs, &1))

      selected_jobs =
        if all_selected? do
          Enum.reduce(job_ids, selected_jobs, &MapSet.delete(&2, &1))
        else
          Enum.reduce(job_ids, selected_jobs, &MapSet.put(&2, &1))
        end

      {:noreply, refresh_selection(socket, selected_jobs, false)}
    end

    def handle_event("toggle_all", params, socket),
      do: handle_event("toggle_page", params, socket)

    def handle_event("select_all_global", _, socket) do
      {:noreply, refresh_selection(socket, socket.assigns.selected_jobs, true)}
    end

    def handle_event("clear_selection", _, socket) do
      {:noreply, refresh_selection(socket, MapSet.new(), false)}
    end

    def handle_event("paginate", %{"page" => page_str}, socket) do
      case Integer.parse(page_str) do
        {page, ""} when page >= 1 ->
          query = %{socket.assigns.filter | page: page}

          {:noreply,
           socket
           |> assign(:review_notice, nil)
           |> assign(:quick_review, nil)
           |> assign(:quick_review_id, nil)
           |> push_patch(to: Selectors.jobs_path(canonical_params(query)))}

        _ ->
          {:noreply, socket}
      end
    end

    def handle_event("select_review", %{"id" => id_str}, socket) do
      case Integer.parse(id_str) do
        {id, ""} when id > 0 ->
          replace? = not is_nil(socket.assigns.quick_review_id)

          {:noreply,
           socket
           |> assign(:review_notice, nil)
           |> push_patch(
             to: Selectors.jobs_path(canonical_params(socket.assigns.filter, id)),
             replace: replace?
           )}

        _invalid ->
          {:noreply, socket}
      end
    end

    def handle_event("close_review", _params, socket) do
      {:noreply,
       socket
       |> assign(:review_notice, nil)
       |> push_patch(
         to: Selectors.jobs_path(canonical_params(socket.assigns.filter)),
         replace: true
       )}
    end

    def handle_event("preview_action", %{"kind" => kind}, socket) do
      case Map.fetch(@job_action_kinds, kind) do
        {:ok, action_kind} -> {:noreply, preview_job_action(socket, action_kind, "")}
        :error -> {:noreply, socket}
      end
    end

    def handle_event("preview_action", _params, socket), do: {:noreply, socket}

    def handle_event("close_action_confirmation", _params, socket) do
      {:noreply, clear_job_action_confirmation(socket)}
    end

    def handle_event("new_action_preview", _params, socket) do
      case Map.get(socket.assigns, :action_kind) do
        kind when kind in [:retry, :cancel, :discard] ->
          reason_draft = Map.get(socket.assigns, :action_reason_draft, "")

          {:noreply,
           socket
           |> put_private(@job_action_preview_private, nil)
           |> preview_job_action(kind, reason_draft)}

        _missing ->
          {:noreply, socket}
      end
    end

    def handle_event(
          "execute_action",
          %{"confirmation" => %{"reason" => reason}},
          socket
        ) do
      if Map.get(socket.assigns, :confirmation_state) == :preview do
        case validate_action_reason(reason) do
          {:ok, reason_draft} ->
            {:noreply, execute_job_action(socket, reason_draft)}

          {:error, reason_draft} ->
            {:noreply,
             socket
             |> assign(:action_reason_draft, reason_draft)
             |> assign(:confirmation_form, action_confirmation_form(reason_draft, :invalid))}
        end
      else
        {:noreply, socket}
      end
    end

    def handle_event("execute_action", _params, socket) do
      {:noreply,
       socket
       |> assign(:action_reason_draft, "")
       |> assign(:confirmation_form, action_confirmation_form("", :invalid))}
    end

    def handle_event("preview_bulk", %{"action" => action}, socket)
        when action in @allowed_preview_actions do
      {:noreply,
       socket
       |> assign(:bulk_preview_action, action)
       |> assign(:reason, "")
       |> assign(:error_message, nil)}
    end

    def handle_event("preview_bulk", _params, socket), do: {:noreply, socket}

    def handle_event("close_preview", _, socket) do
      {:noreply,
       assign(socket,
         preview: nil,
         preview_action: nil,
         bulk_preview_action: nil,
         reason: "",
         error_message: nil
       )}
    end

    def handle_event("reason", %{"reason" => r}, socket) do
      {:noreply, assign(socket, :reason, r)}
    end

    def handle_event("execute_bulk", params, socket) do
      reason_from_params = Map.get(params, "reason")
      reason = String.trim(reason_from_params || socket.assigns.reason)
      action = socket.assigns.bulk_preview_action

      if reason == "" or is_nil(action) do
        {:noreply, socket}
      else
        actor = socket.assigns.current_actor
        filter = socket.assigns.filter

        job_ids =
          if socket.assigns.global_select do
            Jobs.list_ids(repo(), filter)
          else
            socket.assigns.selected_jobs
          end

        {successes, failures} =
          Enum.reduce(job_ids, {0, 0}, fn job_id, {succ, fail} ->
            case Lifeline.preview_repair(repo(), actor, %{
                   incident_id: nil,
                   action: action,
                   target_type: "job",
                   target_id: job_id
                 }) do
              {:ok, preview} ->
                case Lifeline.execute_repair(repo(), actor, preview.preview_token, reason) do
                  {:ok, _} -> {succ + 1, fail}
                  _ -> {succ, fail + 1}
                end

              _ ->
                {succ, fail + 1}
            end
          end)

        socket =
          socket
          |> put_flash(
            :info,
            "Bulk action complete: #{successes} successes, #{failures} failures."
          )
          |> assign(:selected_jobs, MapSet.new())
          |> assign(:global_select, false)
          |> assign(:bulk_preview_action, nil)

        {:noreply, load_jobs(socket, socket.assigns.filter)}
      end
    end

    @impl true
    def handle_info(:poll_counts, socket) do
      if connected?(socket), do: Process.send_after(self(), :poll_counts, 5000)
      {:noreply, update_live_counts(socket)}
    end

    def handle_info({:notification, :metrics, _payload}, socket) do
      {:noreply, update_live_counts(socket)}
    end

    def handle_info(_, socket), do: {:noreply, socket}

    defp maybe_init_live_counts(socket) do
      if connected?(socket) do
        if Code.ensure_loaded?(Oban.Met) do
          Oban.Notifier.listen([:metrics])
        else
          Process.send_after(self(), :poll_counts, 5000)
        end
      end

      socket
    end

    defp update_live_counts(socket) do
      filter = socket.assigns.filter

      counts =
        if Code.ensure_loaded?(Oban.Met) and not has_filters?(filter) do
          # Oban_met metrics act as a high-performance cache. If filters are active,
          # we gracefully fallback to database polling to show the correct sliced counts.
          case apply(Oban.Met, :latest, [Oban, :full_count, [group: "state"]]) do
            oban_counts when is_map(oban_counts) or is_list(oban_counts) ->
              Map.new(oban_counts, fn {k, v} -> {to_string(k), v} end)

            _ ->
              Jobs.count_by_state(repo(), filter)
          end
        else
          Jobs.count_by_state(repo(), filter)
        end

      assign(socket, :counts, counts)
    end

    defp has_filters?(filter) do
      not (is_nil(filter.queue) and is_nil(filter.worker) and is_nil(filter.tags) and
             is_nil(filter.args) and is_nil(filter.meta))
    end

    @impl true
    def render(%{live_action: :show} = assigns), do: page_content(assigns)

    def render(assigns), do: page_content(assigns)

    attr(:rows, :list, default: [])
    attr(:counts, :map, required: true)
    attr(:filter, :any, required: true)
    attr(:filter_form, :any, required: true)
    attr(:filter_copy, :map, required: true)
    attr(:filter_errors, :map, default: %{})
    attr(:filters_dirty?, :boolean, default: false)
    attr(:filters_expanded?, :boolean, default: false)
    attr(:active_filters, :list, default: [])
    attr(:clear_filters_href, :string, required: true)
    attr(:result_summary, :string, required: true)
    attr(:pagination, :map, required: true)
    attr(:page_selection_state, :atom, required: true)
    attr(:selected_count, :integer, default: 0)
    attr(:selected_jobs, :any, default: MapSet.new())
    attr(:global_select, :boolean, default: false)
    attr(:read_only?, :boolean, default: true)
    attr(:url_notice, :string, default: nil)
    attr(:review_notice, :string, default: nil)
    attr(:quick_review, :map, default: nil)
    attr(:quick_review_id, :integer, default: nil)
    attr(:bulk_preview_action, :string, default: nil)
    attr(:reason, :string, default: "")
    attr(:error_message, :string, default: nil)

    def page_content(assigns) do
      if Map.get(assigns, :page_mode) == :detail do
        detail_page_content(assigns)
      else
        assigns = assign(assigns, :states, @valid_states)

        ~H"""
        <section id="jobs-page" class="obpt-jobs-page" aria-labelledby="jobs-page-title">
          <header class="obpt-jobs-page__header">
            <h1 id="jobs-page-title">Jobs</h1>
            <p>
              Review current job state, apply precise filters, and take deliberate action with recorded evidence.
            </p>
          </header>

          <Primitives.surface :if={@read_only?} variant={:inset}>
            <p>{LiveAuth.page_read_only_banner(:jobs)}</p>
          </Primitives.surface>

          <Primitives.surface :if={@url_notice} variant={:inset}>
            <h2>Some filters were not applied</h2>
            <p>{@url_notice}</p>
          </Primitives.surface>

          <Primitives.surface :if={@review_notice} variant={:inset}>
            <h2>Job unavailable</h2>
            <p>{@review_notice}</p>
          </Primitives.surface>

          <nav class="obpt-jobs-page__states" aria-label="Job state">
            <Primitives.button
              :for={state <- @states}
              id={"jobs-state-#{state}"}
              phx-click="select_state"
              phx-value-state={state}
              variant={if(to_string(@filter.state) == state, do: :primary, else: :neutral)}
              aria-current={if(to_string(@filter.state) == state, do: "page")}
            >
              {state_label(state)} ({Map.get(@counts, state, 0)})
            </Primitives.button>
          </nav>

          <OperatorPatterns.filter_bar
            id="jobs-filter"
            form={@filter_form}
            mode={:submit}
            result_summary={@result_summary}
            results_target_id="jobs-results"
            active_filters={@active_filters}
            dirty={@filters_dirty?}
            filters_expanded={@filters_expanded?}
            change_event="validate_filters"
            submit_event="apply_filters"
            clear_href={@clear_filters_href}
          >
            <:fields>
              <Forms.input
                field={@filter_form[:queue]}
                label="Queue"
                variant={:filter}
                placeholder="All queues"
              />
              <Forms.input
                field={@filter_form[:worker]}
                label="Worker module"
                variant={:filter}
                placeholder="All worker modules"
              />
              <Forms.input
                field={@filter_form[:tags]}
                label="Tags"
                hint={@filter_copy.tags_help}
                variant={:filter}
                placeholder="All tags"
              />
            </:fields>
            <:advanced_fields>
              <Forms.input
                field={@filter_form[:args]}
                label="Args contain"
                hint={@filter_copy.json_help}
                errors={field_errors(@filter_errors, :args)}
                variant={:filter}
                placeholder="JSON object"
              />
              <Forms.input
                field={@filter_form[:meta]}
                label="Meta contain"
                hint={@filter_copy.json_help}
                errors={field_errors(@filter_errors, :meta)}
                variant={:filter}
                placeholder="JSON object"
              />
            </:advanced_fields>
          </OperatorPatterns.filter_bar>

          <section
            :if={@selected_count > 0}
            id="jobs-selection-summary"
            class="obpt-jobs-page__selection-summary"
            aria-live="polite"
          >
            <p>{selection_count_copy(@selected_count)}</p>
            <Primitives.button phx-click="clear_selection">Clear selection</Primitives.button>
            <div :if={!@read_only?} class="obpt-jobs-page__selection-actions">
              <Primitives.button
                :if={to_string(@filter.state) in ["retryable", "cancelled", "discarded", "completed"]}
                phx-click="preview_bulk"
                phx-value-action="job_retry"
                variant={:warning}
              >
                Retry jobs
              </Primitives.button>
              <Primitives.button
                :if={to_string(@filter.state) in ["available", "scheduled", "executing", "retryable"]}
                phx-click="preview_bulk"
                phx-value-action="job_cancel"
                variant={:danger}
              >
                Cancel jobs
              </Primitives.button>
              <Primitives.button
                :if={to_string(@filter.state) in ["available", "scheduled", "executing", "retryable"]}
                phx-click="preview_bulk"
                phx-value-action="job_discard"
                variant={:danger}
              >
                Discard jobs
              </Primitives.button>
            </div>
          </section>

          <DataDisplay.data_table
            id="jobs-results"
            caption="Jobs"
            rows={@rows}
            row_id={& &1.id}
            state={:ready}
            resource="jobs"
            row_count={@pagination.total_count}
            pagination_summary={@pagination.summary}
          >
            <:toolbar>
              <label for="jobs-page-selection">
                <input
                  id="jobs-page-selection"
                  type="checkbox"
                  phx-click="toggle_page"
                  checked={@page_selection_state == :checked}
                  aria-checked={page_selection_aria(@page_selection_state)}
                  data-obpt-page-selection={@page_selection_state}
                />
                <span>Select current page</span>
              </label>
            </:toolbar>
            <:selection :let={row}>
              <label for={"job-select-#{row.id}"}>
                <input
                  id={"job-select-#{row.id}"}
                  type="checkbox"
                  checked={row.selection.checked?}
                  phx-click="toggle_job"
                  phx-value-id={row.id}
                  aria-label={row.selection.label}
                />
                <span class="obpt-sr-only">{row.selection.label}</span>
              </label>
            </:selection>
            <:col :let={row} label="Worker" value_kind={:module}>
              <DataDisplay.machine_value
                id={"job-worker-#{row.id}"}
                value={row.worker}
                kind={:module}
                truncate={false}
              />
            </:col>
            <:col :let={row} label="State">
              <DataDisplay.status_pill domain={:job} state={row.state} />
            </:col>
            <:col :let={row} label="Queue" value_kind={:literal}>
              <DataDisplay.machine_value
                id={"job-queue-#{row.id}"}
                value={row.queue}
                kind={:literal}
                truncate={false}
              />
            </:col>
            <:col :let={row} label="Scheduled">
              <time datetime={row.scheduled.datetime}>{row.scheduled.label}</time>
            </:col>
            <:col :let={row} label="Attempts">{row.attempts}</:col>
            <:col :let={row} label="Job ID" value_kind={:id}>
              <DataDisplay.machine_value
                id={"job-id-#{row.id}"}
                value={to_string(row.id)}
                kind={:id}
                truncate={false}
              />
            </:col>
            <:col :let={row} label="Review job">
              <Primitives.button
                id={"job-review-#{row.id}"}
                phx-click="select_review"
                phx-value-id={row.id}
                variant={if(row.review.current?, do: :primary, else: :neutral)}
                aria-label={row.review.label}
                aria-expanded={to_string(row.review.current?)}
                aria-controls={if(row.review.current?, do: "job-quick-review")}
              >
                {if(row.review.current?, do: "Reviewing", else: "Review job")}
              </Primitives.button>
            </:col>
          </DataDisplay.data_table>

          <DataDisplay.empty_state
            :if={@rows == []}
            id="jobs-empty"
            heading="No jobs match the applied filters"
            body="Remove a filter or clear all filters to widen the review."
          />

          <nav class="obpt-jobs-page__pagination" aria-label="Jobs pages">
            <Primitives.button
              id="jobs-previous-page"
              phx-click="paginate"
              phx-value-page={@pagination.page - 1}
              disabled={!@pagination.previous?}
            >
              Previous
            </Primitives.button>
            <span>{@pagination.summary}</span>
            <Primitives.button
              id="jobs-next-page"
              phx-click="paginate"
              phx-value-page={@pagination.page + 1}
              disabled={!@pagination.next?}
            >
              Next
            </Primitives.button>
          </nav>

          <OperatorPatterns.detail_surface
            :if={@quick_review}
            id="job-quick-review"
            title={@quick_review.title}
            close_label="Close job review"
            open={true}
            variant={:adaptive}
            state={:ready}
            resource="job review"
            logical_fallback_id={"job-review-#{@quick_review.id}"}
            close_event="close_review"
            loaded_announcement={"Job #{@quick_review.id} review loaded"}
          >
            <:body>
              <DataDisplay.description_list id="job-quick-review-facts">
                <:item label="Job ID" value_kind={:id}>{@quick_review.id}</:item>
                <:item label="State">
                  <DataDisplay.status_pill domain={:job} state={@quick_review.state.value} />
                </:item>
                <:item label="Worker" value_kind={:module}>{@quick_review.worker}</:item>
                <:item label="Queue" value_kind={:literal}>{@quick_review.queue}</:item>
                <:item label="Attempts">{@quick_review.attempts}</:item>
                <:item label={@quick_review.relevant_time.label}>
                  <time datetime={@quick_review.relevant_time.datetime}>
                    {@quick_review.relevant_time.value}
                  </time>
                </:item>
                <:item label="Latest failure">{@quick_review.failure_summary}</:item>
                <:item label="Recorded output">
                  {if(@quick_review.recorded_output_available?, do: "Available", else: "Not recorded")}
                </:item>
                <:item label="Enqueue redaction">{@quick_review.enqueue_redaction.summary}</:item>
              </DataDisplay.description_list>
            </:body>
            <:actions>
              <Primitives.link navigate={@quick_review.full_details_href}>
                Open full job details
              </Primitives.link>
            </:actions>
          </OperatorPatterns.detail_surface>

          <%= if @bulk_preview_action do %>
            <div class="obpt-modal-backdrop">
              <div class="obpt-modal">
                <h2>{bulk_preview_title(@bulk_preview_action, @selected_count)}</h2>
                <p>Each job is processed independently.</p>
                <form phx-change="reason" phx-submit="execute_bulk">
                  <label for="jobs-bulk-reason">Reason (required)</label>
                  <input id="jobs-bulk-reason" type="text" name="reason" value={@reason} />
                  <p :if={@error_message}>{@error_message}</p>
                  <Primitives.button phx-click="close_preview">Cancel</Primitives.button>
                  <Primitives.button
                    type="submit"
                    variant={if(@bulk_preview_action == "job_retry", do: :warning, else: :danger)}
                    disabled={String.trim(@reason) == ""}
                  >
                    {bulk_confirm_label(@bulk_preview_action)}
                  </Primitives.button>
                </form>
              </div>
            </div>
          <% end %>
        </section>
        """
      end
    end

    defp detail_page_content(assigns) do
      detail = Map.get(assigns, :detail)

      assigns =
        assigns
        |> assign(:detail, detail)
        |> assign(:detail_unavailable?, Map.get(assigns, :detail_unavailable?, is_nil(detail)))
        |> assign(:back_path, Map.get(assigns, :back_path, Selectors.jobs_path([])))
        |> assign(:read_only?, Map.get(assigns, :read_only?, true))
        |> assign(:action_controls, Map.get(assigns, :action_controls, []))
        |> assign(:confirmation_action, Map.get(assigns, :confirmation_action))
        |> assign(:confirmation_state, Map.get(assigns, :confirmation_state, :preview))
        |> assign(:confirmation_form, Map.get(assigns, :confirmation_form))
        |> assign(:confirmation_results, Map.get(assigns, :confirmation_results, []))
        |> assign(:confirmation_object_label, Map.get(assigns, :confirmation_object_label))
        |> assign(:confirmation_fallback_id, Map.get(assigns, :confirmation_fallback_id))
        |> assign(:confirmation_audit_href, Map.get(assigns, :confirmation_audit_href))
        |> assign(:receipt, Map.get(assigns, :receipt))
        |> assign(:detail_job_id, detail_job_id(detail))
        |> assign(:recorded_output_facts, recorded_output_facts(detail))

      ~H"""
      <section id="job-detail-page" class="obpt-jobs-page" aria-labelledby="job-detail-title">
        <Primitives.surface :if={@detail_unavailable?} id="job-unavailable" variant={:inset}>
          <h1 id="job-detail-title">Job unavailable</h1>
          <p>
            It may not exist, may no longer be available, or you may not have access. Return to Jobs and choose another job.
          </p>
          <Primitives.link navigate={@back_path}>Back to Jobs</Primitives.link>
        </Primitives.surface>

        <%= if !@detail_unavailable? do %>
          <header class="obpt-jobs-page__header">
            <div>
              <h1 id="job-detail-title">Job #{if(@detail_job_id, do: @detail_job_id)}</h1>
              <p>Review current job truth, bounded failure evidence, and redacted data.</p>
            </div>
            <Primitives.link navigate={@back_path}>Back to Jobs</Primitives.link>
          </header>

          <Primitives.surface id="job-current-state" variant={:attention}>
            <p>{@detail.support.heading}</p>
            <h2>{@detail.support.state_label}</h2>
            <p>{@detail.support.summary}</p>
            <p>{@detail.support.availability}</p>
          </Primitives.surface>

          <Primitives.surface id="job-actions" variant={:inset}>
            <h2>Legal actions</h2>
            <p :if={@read_only?}>{LiveAuth.page_read_only_banner(:job_detail)}</p>
            <div>
              <Primitives.button
                :for={action <- @action_controls}
                id={"job-action-#{action.kind}"}
                phx-click="preview_action"
                phx-value-kind={action.kind}
                variant={action.intent}
                disabled_reason={action.disabled_reason}
              >
                {action.confirm_label}
              </Primitives.button>
            </div>
          </Primitives.surface>

          <Primitives.surface variant={:plain}>
            <h2>Identity</h2>
            <DataDisplay.description_list id="job-identity">
              <:item
                :for={item <- @detail.identity}
                label={item.label}
                value_kind={item.value_kind}
              >
                <DataDisplay.status_pill
                  :if={item.label == "State"}
                  domain={:job}
                  state={@detail.support.state}
                />
                <span :if={item.label != "State"}>{item.value}</span>
              </:item>
            </DataDisplay.description_list>
          </Primitives.surface>

          <Primitives.surface variant={:plain}>
            <h2>Timing</h2>
            <DataDisplay.description_list id="job-timing">
              <:item :for={item <- @detail.timing} label={item.label}>
                <time :if={item.datetime} datetime={item.datetime}>{item.value}</time>
                <span :if={!item.datetime}>{item.value}</span>
              </:item>
            </DataDisplay.description_list>
          </Primitives.surface>

          <Primitives.surface id="job-errors" variant={:plain}>
            <h2>Errors and Attempt History</h2>
            <p :if={@detail.errors == []}>No errors recorded for this job.</p>
            <ol :if={@detail.errors != []}>
              <li :for={error <- @detail.errors}>
                <p>Attempt {error.attempt}</p>
                <p>{error.class}</p>
                <p>{error.message}</p>
                <time :if={error.occurred_datetime} datetime={error.occurred_datetime}>
                  {error.occurred_at}
                </time>
                <span :if={!error.occurred_datetime}>{error.occurred_at}</span>
                <p :if={error.truncated?}>Failure summary truncated to 1,000 characters.</p>
              </li>
            </ol>
          </Primitives.surface>

          <Primitives.surface variant={:plain}>
            <h2>Arguments, metadata, and recorded output</h2>
            <h3>{@detail.data.arguments.label}</h3>
            <DataDisplay.args_viewer
              id="job-arguments"
              label={@detail.data.arguments.label}
              kind={@detail.data.arguments.kind}
              display={@detail.data.arguments.display}
            />
            <h3>{@detail.data.metadata.label}</h3>
            <DataDisplay.args_viewer
              id="job-metadata"
              label={@detail.data.metadata.label}
              kind={@detail.data.metadata.kind}
              display={@detail.data.metadata.display}
            />
            <h3>{@detail.data.recorded_output.label}</h3>
            <DataDisplay.args_viewer
              id="job-recorded-output"
              label={@detail.data.recorded_output.label}
              kind={@detail.data.recorded_output.kind}
              display={@detail.data.recorded_output.display}
            />
            <DataDisplay.description_list
              :if={@recorded_output_facts != []}
              id="job-recorded-output-facts"
            >
              <:item :for={item <- @recorded_output_facts} label={item.label}>
                {item.value}
              </:item>
            </DataDisplay.description_list>
            <p>{@detail.redaction.enqueue.summary}</p>
            <p>{@detail.redaction.policy}</p>
          </Primitives.surface>

          <Primitives.surface id="job-destinations" variant={:inset}>
            <h2>Related evidence</h2>
            <p :if={@detail.destinations == []}>No authorized related evidence is available.</p>
            <ul :if={@detail.destinations != []}>
              <li :for={destination <- @detail.destinations}>
                <Primitives.link navigate={destination.href}>{destination.label}</Primitives.link>
              </li>
            </ul>
          </Primitives.surface>

          <DataDisplay.toast :if={@receipt} id="job-action-receipt" tone={:success}>
            <p>{@receipt.message}</p>
            <Primitives.link :if={@receipt.audit_href} navigate={@receipt.audit_href}>
              Open audit evidence
            </Primitives.link>
          </DataDisplay.toast>

          <OperatorPatterns.confirm_action_dialog
            :if={@confirmation_action && @confirmation_form}
            id="job-action-confirmation"
            intent={@confirmation_action.intent}
            state={@confirmation_state}
            title={@confirmation_action.title}
            object_label={@confirmation_object_label}
            scope={@confirmation_action.scope}
            consequence={@confirmation_action.consequence}
            reversibility={@confirmation_action.reversibility}
            support_boundary={@confirmation_action.support_boundary}
            form={@confirmation_form}
            confirm_label={@confirmation_action.confirm_label}
            dismiss_label={@confirmation_action.dismiss_label}
            pending_copy={@confirmation_action.pending_copy}
            logical_fallback_id={@confirmation_fallback_id}
            submit_event="execute_action"
            dismiss_event="close_action_confirmation"
            results={@confirmation_results}
          >
            <:recovery>
              <Primitives.button type="button" variant={:neutral} phx-click="new_action_preview">
                Create new preview
              </Primitives.button>
            </:recovery>
            <:audit :if={@confirmation_audit_href}>
              <Primitives.link navigate={@confirmation_audit_href}>Open audit evidence</Primitives.link>
            </:audit>
          </OperatorPatterns.confirm_action_dialog>
        <% end %>
      </section>
      """
    end

    # --- Private helpers ---

    defp load_job_detail(socket, job_id) do
      load_job_detail(socket, job_id, Map.get(socket.assigns, :detail_return_params, []))
    end

    defp load_job_detail(socket, job_id, return_params) do
      actor = Map.get(socket.assigns, :current_actor)
      back_path = Selectors.jobs_path(return_params)

      with {:ok, normalized_id} <- normalize_detail_job_id(job_id),
           true <-
             LiveAuth.authorized?(actor, :view_job_detail, %{
               type: :job,
               id: Integer.to_string(normalized_id)
             }),
           %Oban.Job{} = job <- Jobs.get(repo(), normalized_id) do
        context = %{
          args_display: DisplayPolicy.render_job_field(:job_args, job.args, %{job: job}),
          meta_display: DisplayPolicy.render_job_field(:job_meta, job.meta, %{job: job}),
          recorded_output_display: recorded_output_display(job),
          audit_href: authorized_job_audit_href(actor, job.id)
        }

        detail = ControlPlanePresenter.present_job_detail(job, context)
        action_controls = job_action_controls(detail.actions, actor, job.id)

        socket
        |> put_private(@job_action_preview_private, nil)
        |> assign(:page_mode, :detail)
        |> assign(:detail, detail)
        |> assign(:detail_unavailable?, false)
        |> assign(:job_id, job.id)
        |> assign(:job_state, job.state)
        |> assign(:detail_return_params, return_params)
        |> assign(:action_controls, action_controls)
        |> assign_job_action_confirmation_defaults()
        |> assign(:receipt, nil)
        |> assign(:reason, "")
        |> assign(:error_message, nil)
        |> assign(:success_message, nil)
        |> assign(:back_path, back_path)
        |> assign(:read_only?, Enum.all?(action_controls, &(not &1.enabled?)))
      else
        _unavailable ->
          socket
          |> put_private(@job_action_preview_private, nil)
          |> assign(:page_mode, :detail)
          |> assign(:detail, nil)
          |> assign(:detail_unavailable?, true)
          |> assign(:job_id, nil)
          |> assign(:job_state, nil)
          |> assign(:detail_return_params, return_params)
          |> assign(:action_controls, [])
          |> assign_job_action_confirmation_defaults()
          |> assign(:receipt, nil)
          |> assign(:reason, "")
          |> assign(:error_message, nil)
          |> assign(:success_message, nil)
          |> assign(:back_path, back_path)
          |> assign(:read_only?, true)
      end
    end

    defp preview_job_action(socket, action_kind, reason_draft) do
      with {:ok, job} <- authorize_job_action(socket, action_kind, :preview_repair),
           {:ok, preview} <-
             Lifeline.preview_repair(
               repo(),
               socket.assigns.current_actor,
               %{
                 incident_id: nil,
                 action: Map.fetch!(@job_action_values, action_kind),
                 target_type: "job",
                 target_id: job.id
               },
               telemetry_metadata: %{source: "jobs_detail"}
             ) do
        presentation = ControlPlanePresenter.present_job_action(action_kind)

        socket
        |> put_private(@job_action_preview_private, %{
          preview_token: preview.preview_token
        })
        |> assign(:action_kind, action_kind)
        |> assign(:action_reason_draft, reason_draft)
        |> assign(:confirmation_action, presentation)
        |> assign(:confirmation_state, :preview)
        |> assign(:confirmation_form, action_confirmation_form(reason_draft))
        |> assign(:confirmation_results, [])
        |> assign(:confirmation_object_label, "Job #{job.id}")
        |> assign(:confirmation_fallback_id, "job-action-#{action_kind}")
        |> assign(:confirmation_audit_href, nil)
      else
        _unavailable_or_unauthorized -> socket
      end
    end

    defp execute_job_action(socket, reason_draft) do
      action_kind = Map.get(socket.assigns, :action_kind)
      private_preview = Map.get(socket.private, @job_action_preview_private)

      with action_kind when action_kind in [:retry, :cancel, :discard] <- action_kind,
           %{preview_token: preview_token} when is_binary(preview_token) <- private_preview,
           {:ok, _job} <- authorize_job_action(socket, action_kind, :execute_repair),
           {:ok, %{target: target}} <-
             Lifeline.execute_repair(
               repo(),
               socket.assigns.current_actor,
               preview_token,
               reason_draft,
               telemetry_metadata: %{source: "jobs_detail"}
             ) do
        result =
          ControlPlanePresenter.present_job_action_result(%{
            state: :success,
            action: action_kind,
            job_id: target.id,
            audit_href: authorized_job_audit_href(socket.assigns.current_actor, target.id)
          })

        receipt = %{message: result.receipt, audit_href: result.audit_href}

        socket
        |> clear_job_action_confirmation()
        |> load_job_detail(target.id)
        |> assign(:receipt, receipt)
      else
        {:error, reason} ->
          assign_job_action_failure(socket, action_kind, reason, reason_draft)

        _missing_or_forged ->
          assign_job_action_failure(socket, action_kind, :failed, reason_draft)
      end
    end

    defp authorize_job_action(socket, action_kind, service_permission)
         when action_kind in [:retry, :cancel, :discard] and
                service_permission in [:preview_repair, :execute_repair] do
      job_id = Map.get(socket.assigns, :job_id)
      resource = %{type: :job, id: to_string(job_id)}
      action_permission = Map.fetch!(@job_action_permissions, action_kind)

      with true <- is_integer(job_id) and job_id > 0,
           :ok <- LiveAuth.authorize_action(socket, :view_job_detail, resource),
           :ok <- LiveAuth.authorize_action(socket, action_permission, resource),
           %Oban.Job{id: ^job_id} = job <- Jobs.get(repo(), job_id),
           true <- job_action_legal?(action_kind, job.state),
           :ok <- LiveAuth.authorize_action(socket, service_permission, resource),
           {:ok, _principal} <- LiveAuth.principal_for_action(socket) do
        {:ok, job}
      else
        _unavailable_or_unauthorized -> {:error, :unauthorized}
      end
    end

    defp job_action_legal?(action_kind, state) do
      state in Map.fetch!(@job_action_states, action_kind)
    end

    defp job_action_controls(actions, actor, job_id) do
      resource = %{type: :job, id: Integer.to_string(job_id)}

      Enum.map(actions, fn action ->
        permission = Map.fetch!(@job_action_permissions, action.kind)
        action_allowed? = LiveAuth.authorized?(actor, permission, resource)
        preview_allowed? = LiveAuth.authorized?(actor, :preview_repair, resource)
        execute_allowed? = LiveAuth.authorized?(actor, :execute_repair, resource)
        enabled? = action_allowed? and preview_allowed? and execute_allowed?

        disabled_reason =
          cond do
            not action_allowed? -> LiveAuth.permission_message(permission)
            not preview_allowed? -> LiveAuth.permission_message(:preview_repair)
            not execute_allowed? -> LiveAuth.permission_message(:execute_repair)
            true -> nil
          end

        Map.merge(action, %{
          enabled?: enabled?,
          disabled_reason: disabled_reason
        })
      end)
    end

    defp validate_action_reason(reason) when is_binary(reason) do
      reason_draft = String.trim(reason)

      if String.length(reason_draft) >= 8,
        do: {:ok, reason_draft},
        else: {:error, reason_draft}
    end

    defp validate_action_reason(_reason), do: {:error, ""}

    defp action_confirmation_form(reason_draft, validity \\ :valid) do
      options =
        if validity == :invalid do
          [
            errors: [reason: {"Enter at least 8 characters.", []}],
            action: :validate
          ]
        else
          []
        end

      Phoenix.Component.to_form(
        %{"reason" => reason_draft},
        [
          as: :confirmation,
          id: "job-action-confirmation-form"
        ] ++ options
      )
    end

    defp assign_job_action_failure(socket, action_kind, reason, reason_draft) do
      result_state = job_action_result_state(reason)
      confirmation_state = job_action_confirmation_state(result_state)

      result =
        ControlPlanePresenter.present_job_action_result(%{
          state: result_state,
          action: action_kind,
          job_id: Map.get(socket.assigns, :job_id)
        })

      results =
        if result_state in [:failed, :skipped] do
          [
            %{
              id: "job-action-result",
              object_label: "Job #{Map.get(socket.assigns, :job_id)}",
              outcome: result_state,
              message: result.message,
              recovery: result.recovery,
              audit_href: nil
            }
          ]
        else
          []
        end

      socket
      |> put_private(@job_action_preview_private, nil)
      |> assign(:action_reason_draft, reason_draft)
      |> assign(:confirmation_state, confirmation_state)
      |> assign(:confirmation_form, action_confirmation_form(reason_draft))
      |> assign(:confirmation_results, results)
      |> assign(:confirmation_audit_href, nil)
    end

    defp job_action_result_state(:preview_expired), do: :expired
    defp job_action_result_state(:preview_drifted), do: :drifted
    defp job_action_result_state(:preview_consumed), do: :consumed
    defp job_action_result_state(:mutation_conflict), do: :skipped
    defp job_action_result_state(_reason), do: :failed

    defp job_action_confirmation_state(state)
         when state in [:expired, :drifted, :consumed],
         do: state

    defp job_action_confirmation_state(:skipped), do: :partial
    defp job_action_confirmation_state(_state), do: :failed

    defp clear_job_action_confirmation(socket) do
      socket
      |> put_private(@job_action_preview_private, nil)
      |> assign_job_action_confirmation_defaults()
    end

    defp assign_job_action_confirmation_defaults(socket) do
      assign(socket,
        action_kind: nil,
        action_reason_draft: "",
        confirmation_action: nil,
        confirmation_state: :preview,
        confirmation_form: nil,
        confirmation_results: [],
        confirmation_object_label: nil,
        confirmation_fallback_id: nil,
        confirmation_audit_href: nil
      )
    end

    defp normalize_detail_job_id(value) when is_integer(value) and value > 0, do: {:ok, value}

    defp normalize_detail_job_id(value) when is_binary(value) do
      case Integer.parse(value) do
        {id, ""} when id > 0 -> {:ok, id}
        _invalid -> :error
      end
    end

    defp normalize_detail_job_id(_value), do: :error

    defp recorded_output_display(%Oban.Job{} = job) do
      context = %{surface: :jobs, field: :recorded, job: job}

      case JobRecord.fetch_record(repo(), job.id) do
        {:ok, record} -> DisplayPolicy.render_job_field(:job_recorded, record, context)
        {:error, :not_found} -> DisplayPolicy.render_job_field(:job_recorded, nil, context)
      end
    end

    defp authorized_job_audit_href(actor, job_id) do
      resource = %{type: :job, id: Integer.to_string(job_id)}

      if LiveAuth.authorized?(actor, :view_audit, resource) do
        Selectors.audit_path(resource_type: "job", resource_id: job_id)
      end
    end

    defp detail_job_id(%{identity: identity}) when is_list(identity) do
      case Enum.find(identity, &(&1.label == "Job ID")) do
        %{value: value} -> value
        _missing -> nil
      end
    end

    defp detail_job_id(_detail), do: nil

    defp recorded_output_facts(%{data: %{recorded_output: %{display: display}}})
         when is_map(display) do
      [
        %{
          label: "Availability",
          value: if(display.available?, do: "Available", else: "Unavailable")
        },
        %{label: "Summary", value: display.summary || "Unavailable"},
        %{label: "Status", value: display.status || "Unavailable"},
        %{label: "Attempt", value: display.attempt || "Unavailable"},
        %{label: "Payload Bytes", value: display.payload_bytes || "Unavailable"},
        %{label: "Recorded At", value: display.recorded_at || "Unavailable"},
        %{label: "Retention", value: display.retention || "Unavailable"},
        %{label: "Expires At", value: display.expires_at || "Unavailable"},
        %{
          label: "Redacted Metadata",
          value: if(display.redacted?, do: "Stored redaction metadata present", else: "None")
        }
      ]
    end

    defp recorded_output_facts(_detail), do: []

    defp assign_defaults(socket) do
      initial_query = %Jobs{}
      initial_validation = JobsParams.validate_draft(%{})

      socket
      |> assign(:rows, [])
      |> assign(:page_job_ids, [])
      |> assign(:filter, initial_query)
      |> assign(:counts, Map.new(@valid_states, &{&1, 0}))
      |> assign(:exact_count, 0)
      |> assign(:pagination, pagination(initial_query, 0, 0))
      |> assign(:result_summary, state_summary(initial_query.state, 0))
      |> assign(:filter_draft, initial_validation.draft)
      |> assign(:filter_errors, %{})
      |> assign(:filter_copy, initial_validation.copy)
      |> assign(
        :filter_form,
        Phoenix.Component.to_form(initial_validation.draft,
          as: :filter,
          id: "jobs-filter-form"
        )
      )
      |> assign(:filters_dirty?, false)
      |> assign(:filters_expanded?, false)
      |> assign(:active_filters, [])
      |> assign(:clear_filters_href, Selectors.jobs_path(state: "available"))
      |> assign(:page_selection_state, :unchecked)
      |> assign(:selected_count, 0)
      |> assign(:url_notice, nil)
      |> assign(:review_notice, nil)
      |> assign(:quick_review, nil)
      |> assign(:quick_review_id, nil)
      |> assign(:page_mode, :index)
      |> assign(:detail, nil)
      |> assign(:detail_unavailable?, false)
      |> assign(:detail_return_params, [])
      |> assign(:job_id, nil)
      |> assign(:job_state, nil)
      |> assign(:action_controls, [])
      |> assign_job_action_confirmation_defaults()
      |> assign(:preview, nil)
      |> assign(:preview_action, nil)
      |> assign(:confirmation, nil)
      |> assign(:receipt, nil)
      |> assign(:bulk_preview_action, nil)
      |> assign(:selected_jobs, MapSet.new())
      |> assign(:global_select, false)
      |> assign(:reason, "")
      |> assign(:error_message, nil)
      |> assign(:success_message, nil)
      |> assign(:back_path, Selectors.jobs_path([]))
      |> assign(
        :read_only?,
        not LiveAuth.authorized?(
          Map.get(socket.assigns, :current_actor),
          :retry_job,
          %{type: :page, id: "jobs"}
        )
      )
    end

    defp load_jobs(socket, filter, quick_review_id \\ nil) do
      jobs = Jobs.list(repo(), filter)
      exact_count = Jobs.count(repo(), filter)
      counts = Jobs.count_by_state(repo(), filter)

      socket =
        socket
        |> assign(:filter, filter)
        |> assign(:counts, counts)
        |> assign(:exact_count, exact_count)
        |> assign(:page_job_ids, Enum.map(jobs, & &1.id))
        |> assign(:pagination, pagination(filter, exact_count, length(jobs)))
        |> assign(:result_summary, state_summary(filter.state, exact_count))
        |> assign_applied_filter_state(filter)
        |> load_quick_review(quick_review_id, filter)

      reviewing_id = socket.assigns.quick_review_id
      selected_jobs = socket.assigns.selected_jobs

      rows =
        Enum.map(jobs, fn job ->
          ControlPlanePresenter.present_job_row(job, %{
            selected?: MapSet.member?(selected_jobs, job.id),
            reviewing?: job.id == reviewing_id
          })
        end)

      socket
      |> assign(:rows, rows)
      |> assign(:counts, counts)
      |> assign_selection_state()
      |> assign_read_only()
    end

    defp load_quick_review(socket, nil, _filter) do
      socket
      |> assign(:quick_review, nil)
      |> assign(:quick_review_id, nil)
    end

    defp load_quick_review(socket, job_id, filter) do
      actor = Map.get(socket.assigns, :current_actor)
      resource = %{type: :job, id: to_string(job_id)}

      job =
        if LiveAuth.authorized?(actor, :view_job_detail, resource) do
          Jobs.get(repo(), job_id)
        end

      case job do
        %Oban.Job{} = job ->
          review =
            ControlPlanePresenter.present_job_quick_review(job, %{
              list_params: canonical_params(filter),
              recorded_output_available?: recorded_output_available?(job.id)
            })

          socket
          |> assign(:quick_review, review)
          |> assign(:quick_review_id, job.id)
          |> assign(:review_notice, nil)

        _unavailable ->
          socket
          |> assign(:quick_review, nil)
          |> assign(:quick_review_id, nil)
          |> assign(
            :review_notice,
            "It may not exist, may no longer be available, or you may not have access. Return to Jobs and choose another job."
          )
          |> push_patch(
            to: Selectors.jobs_path(canonical_params(filter)),
            replace: true
          )
      end
    end

    defp recorded_output_available?(job_id) do
      match?({:ok, _payload}, JobRecord.fetch_result(repo(), job_id))
    end

    defp assign_applied_filter_state(socket, filter) do
      validation = JobsParams.validate_draft(draft_params(filter))

      socket
      |> assign(:filter_draft, validation.draft)
      |> assign(:filter_errors, %{})
      |> assign(:filter_copy, validation.copy)
      |> assign(
        :filter_form,
        Phoenix.Component.to_form(validation.draft,
          as: :filter,
          id: "jobs-filter-form"
        )
      )
      |> assign(:filters_dirty?, false)
      |> assign(:filters_expanded?, advanced_filters?(validation.draft))
      |> assign(:active_filters, active_filters(filter))
      |> assign(
        :clear_filters_href,
        Selectors.jobs_path(canonical_params(%Jobs{state: filter.state}))
      )
    end

    defp assign_filter_draft(socket, validation) do
      applied_draft = draft_params(socket.assigns.filter)

      socket
      |> assign(:filter_draft, validation.draft)
      |> assign(:filter_errors, validation.errors)
      |> assign(:filter_copy, validation.copy)
      |> assign(
        :filter_form,
        Phoenix.Component.to_form(validation.draft,
          as: :filter,
          id: "jobs-filter-form"
        )
      )
      |> assign(:filters_dirty?, validation.draft != applied_draft)
      |> assign(
        :filters_expanded?,
        advanced_filters?(validation.draft) or validation.errors != %{}
      )
    end

    defp draft_params(filter) do
      %{
        "queue" => filter.queue || "",
        "worker" => filter.worker || "",
        "tags" => if(filter.tags, do: Enum.join(filter.tags, ", "), else: ""),
        "args" => if(filter.args, do: Jason.encode!(filter.args), else: ""),
        "meta" => if(filter.meta, do: Jason.encode!(filter.meta), else: "")
      }
    end

    defp advanced_filters?(draft) do
      String.trim(Map.get(draft, "args", "")) != "" or
        String.trim(Map.get(draft, "meta", "")) != ""
    end

    defp active_filters(filter) do
      [
        {:queue, "Queue", filter.queue},
        {:worker, "Worker module", filter.worker},
        {:tags, "Tags", if(filter.tags, do: Enum.join(filter.tags, ", "))},
        {:args, "Args contain", if(filter.args, do: Jason.encode!(filter.args))},
        {:meta, "Meta contain", if(filter.meta, do: Jason.encode!(filter.meta))}
      ]
      |> Enum.reject(fn {_field, _label, value} -> is_nil(value) or value == "" end)
      |> Enum.map(fn {field, label, value} ->
        query =
          filter
          |> Map.put(field, nil)
          |> Map.put(:page, 1)

        %{
          id: Atom.to_string(field),
          label: label,
          value: value,
          remove_href: Selectors.jobs_path(canonical_params(query)),
          remove_label: "Remove #{label} filter"
        }
      end)
    end

    defp canonical_params(filter, quick_review_id \\ nil) do
      [
        {"state", to_string(filter.state)},
        {"queue", filter.queue},
        {"worker", filter.worker},
        {"tags", if(filter.tags, do: Enum.join(filter.tags, ","))},
        {"args", if(filter.args, do: Jason.encode!(filter.args))},
        {"meta", if(filter.meta, do: Jason.encode!(filter.meta))},
        {"page", if(filter.page > 1, do: to_string(filter.page))},
        {"job", if(quick_review_id, do: to_string(quick_review_id))}
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    end

    defp pagination(filter, total_count, row_count) do
      offset = (filter.page - 1) * filter.page_size
      from = if row_count == 0, do: 0, else: offset + 1
      to = if row_count == 0, do: 0, else: min(offset + row_count, total_count)

      %{
        page: filter.page,
        page_size: filter.page_size,
        total_count: total_count,
        from: from,
        to: to,
        previous?: filter.page > 1,
        next?: filter.page * filter.page_size < total_count,
        summary:
          if(row_count == 0,
            do: "Showing 0 of #{total_count}",
            else: "Showing #{from}–#{to} of #{total_count}"
          )
      }
    end

    defp state_summary(state, count) do
      "#{count} #{state} #{if(count == 1, do: "job", else: "jobs")}"
    end

    defp refresh_selection(socket, selected_jobs, global_select) do
      rows =
        Enum.map(socket.assigns.rows, fn row ->
          put_in(row, [:selection, :checked?], MapSet.member?(selected_jobs, row.id))
        end)

      socket
      |> assign(:rows, rows)
      |> assign(:selected_jobs, selected_jobs)
      |> assign(:global_select, global_select)
      |> assign_selection_state()
    end

    defp assign_selection_state(socket) do
      job_ids = socket.assigns.page_job_ids
      selected_jobs = socket.assigns.selected_jobs

      page_selection_state =
        cond do
          socket.assigns.global_select and job_ids != [] ->
            :checked

          job_ids == [] ->
            :unchecked

          Enum.all?(job_ids, &MapSet.member?(selected_jobs, &1)) ->
            :checked

          Enum.any?(job_ids, &MapSet.member?(selected_jobs, &1)) ->
            :mixed

          true ->
            :unchecked
        end

      selected_count =
        if socket.assigns.global_select do
          socket.assigns.exact_count
        else
          MapSet.size(selected_jobs)
        end

      assign(socket,
        page_selection_state: page_selection_state,
        selected_count: selected_count
      )
    end

    defp reset_browse_transients(socket) do
      socket
      |> assign(:selected_jobs, MapSet.new())
      |> assign(:global_select, false)
      |> assign(:selected_count, 0)
      |> assign(:page_selection_state, :unchecked)
      |> assign(:quick_review, nil)
      |> assign(:quick_review_id, nil)
      |> assign(:preview, nil)
      |> assign(:bulk_preview_action, nil)
      |> assign(:reason, "")
      |> assign(:error_message, nil)
      |> assign(:success_message, nil)
      |> assign(:frozen_scope, nil)
      |> assign(:bulk_results, nil)
      |> assign(:confirmation, nil)
    end

    defp maybe_assign_url_notice(socket, []), do: socket

    defp maybe_assign_url_notice(socket, notices) do
      assign(socket, :url_notice, List.first(notices))
    end

    defp field_errors(errors, field) do
      case Map.get(errors, field) do
        nil -> []
        error -> [error]
      end
    end

    defp state_label(state), do: state |> String.replace("_", " ") |> String.capitalize()

    defp page_selection_aria(:checked), do: "true"
    defp page_selection_aria(:mixed), do: "mixed"
    defp page_selection_aria(:unchecked), do: "false"

    defp selection_count_copy(1), do: "1 job selected"
    defp selection_count_copy(count), do: "#{count} jobs selected"

    defp bulk_preview_title("job_retry", count), do: "Bulk Retry #{count} Jobs"
    defp bulk_preview_title("job_cancel", count), do: "Bulk Cancel #{count} Jobs"
    defp bulk_preview_title("job_discard", count), do: "Bulk Discard #{count} Jobs"
    defp bulk_preview_title(_action, count), do: "Bulk Action for #{count} Jobs"

    defp bulk_confirm_label("job_retry"), do: "Confirm Bulk Retry"
    defp bulk_confirm_label("job_cancel"), do: "Confirm Bulk Cancel"
    defp bulk_confirm_label("job_discard"), do: "Confirm Bulk Discard"
    defp bulk_confirm_label(_action), do: "Confirm Bulk Action"

    defp assign_read_only(socket) do
      assign(
        socket,
        :read_only?,
        not LiveAuth.authorized?(
          Map.get(socket.assigns, :current_actor),
          :retry_job,
          %{type: :page, id: "jobs"}
        )
      )
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
