if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.JobsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{DisplayPolicy, JobRecord, Jobs, Lifeline, RuntimeConfig}
    alias ObanPowertools.Jobs.BatchCoordinator
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
    @jobs_bulk_handle_private :oban_powertools_jobs_bulk_handle

    @impl true
    def mount(params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      action = socket.assigns.live_action

      {permission, resource_type, resource_id} =
        case action do
          :show -> {:view_job_detail, :job, detail_resource_id(params["id"])}
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

            {:noreply, refresh_selection(socket, selected_jobs)}
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

      {:noreply, refresh_selection(socket, selected_jobs)}
    end

    def handle_event("toggle_all", params, socket),
      do: handle_event("toggle_page", params, socket)

    def handle_event("select_all_matching", _params, socket) do
      {:noreply, freeze_all_matching_selection(socket)}
    end

    def handle_event("clear_selection", _, socket) do
      {:noreply, refresh_selection(socket, MapSet.new())}
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
      {:noreply, start_bulk_preview(socket, action)}
    end

    def handle_event("preview_bulk", _params, socket), do: {:noreply, socket}

    def handle_event("close_preview", _, socket) do
      {:noreply, clear_bulk_confirmation(socket)}
    end

    def handle_event("new_bulk_preview", _params, socket) do
      case Map.get(socket.assigns, :bulk_action_kind) do
        action when action in [:retry, :cancel, :discard] ->
          {:noreply,
           socket
           |> assign(:frozen_scope, nil)
           |> start_bulk_preview(Map.fetch!(@job_action_values, action))}

        _missing ->
          {:noreply, socket}
      end
    end

    def handle_event(
          "execute_bulk",
          %{"confirmation" => confirmation},
          socket
        ) do
      {:noreply, validate_and_start_bulk_execution(socket, confirmation)}
    end

    def handle_event("execute_bulk", _params, socket), do: {:noreply, socket}

    def handle_event("bulk_result_page", %{"page" => page}, socket) do
      {:noreply, assign_bulk_result_page(socket, page)}
    end

    @impl true
    def handle_info(:poll_counts, socket) do
      if connected?(socket), do: Process.send_after(self(), :poll_counts, 5000)
      {:noreply, update_live_counts(socket)}
    end

    def handle_info({:notification, :metrics, _payload}, socket) do
      {:noreply, update_live_counts(socket)}
    end

    def handle_info({:jobs_batch_progress, run_ref, progress}, socket) do
      if current_bulk_run_ref(socket) == run_ref do
        {:noreply, assign(socket, :bulk_progress, progress)}
      else
        {:noreply, socket}
      end
    end

    def handle_info(
          {:jobs_batch_complete, run_ref, %{receipt: %{stage: :preview}} = display},
          socket
        ) do
      if current_bulk_run_ref(socket) == run_ref do
        {:noreply, assign_bulk_preview(socket, display)}
      else
        {:noreply, socket}
      end
    end

    def handle_info(
          {:jobs_batch_complete, run_ref, %{receipt: %{stage: :execution}} = display},
          socket
        ) do
      if current_bulk_run_ref(socket) == run_ref do
        {:noreply, finalize_bulk_execution(socket, display)}
      else
        {:noreply, socket}
      end
    end

    def handle_info({:jobs_batch_failed, run_ref, safe_reason}, socket) do
      if current_bulk_run_ref(socket) == run_ref do
        {:noreply, assign_bulk_failure(socket, safe_reason)}
      else
        {:noreply, socket}
      end
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
    attr(:all_matching_offer?, :boolean, default: false)
    attr(:selection_scope_copy, :string, default: nil)
    attr(:bulk_action_enabled, :map, default: %{retry: false, cancel: false, discard: false})
    attr(:read_only?, :boolean, default: true)
    attr(:url_notice, :string, default: nil)
    attr(:review_notice, :string, default: nil)
    attr(:quick_review, :map, default: nil)
    attr(:quick_review_id, :integer, default: nil)
    attr(:bulk_action_kind, :atom, default: nil)
    attr(:bulk_confirmation_action, :map, default: nil)
    attr(:bulk_confirmation_state, :atom, default: :preview)
    attr(:bulk_confirmation_form, :any, default: nil)
    attr(:bulk_preview, :map, default: nil)
    attr(:bulk_progress, :map, default: nil)
    attr(:bulk_results, :list, default: [])
    attr(:bulk_result_page, :map, default: nil)
    attr(:bulk_result_summary, :string, default: nil)
    attr(:bulk_announcement, :string, default: nil)
    attr(:error_message, :string, default: nil)
    attr(:success_message, :string, default: nil)

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

          <DataDisplay.toast :if={@success_message} id="jobs-bulk-receipt" tone={:success}>
            <p>{@success_message}</p>
          </DataDisplay.toast>

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
            <p :if={@selection_scope_copy}>{@selection_scope_copy}</p>
            <Primitives.button
              :if={@all_matching_offer?}
              id="jobs-select-all-matching"
              phx-click="select_all_matching"
              variant={:primary}
            >
              Select all {@exact_count} jobs matching these filters
            </Primitives.button>
            <p :if={@error_message} id="jobs-bulk-scope-error" role="alert">
              {@error_message}
            </p>
            <Primitives.button phx-click="clear_selection">Clear selection</Primitives.button>
            <div :if={!@read_only?} class="obpt-jobs-page__selection-actions">
              <Primitives.button
                :if={
                  @bulk_action_enabled.retry &&
                    to_string(@filter.state) in [
                      "retryable",
                      "cancelled",
                      "discarded",
                      "completed"
                    ]
                }
                phx-click="preview_bulk"
                phx-value-action="job_retry"
                variant={:warning}
              >
                Retry jobs
              </Primitives.button>
              <Primitives.button
                :if={
                  @bulk_action_enabled.cancel &&
                    to_string(@filter.state) in [
                      "available",
                      "scheduled",
                      "executing",
                      "retryable"
                    ]
                }
                phx-click="preview_bulk"
                phx-value-action="job_cancel"
                variant={:danger}
              >
                Cancel jobs
              </Primitives.button>
              <Primitives.button
                :if={
                  @bulk_action_enabled.discard &&
                    to_string(@filter.state) in [
                      "available",
                      "scheduled",
                      "executing",
                      "retryable"
                    ]
                }
                phx-click="preview_bulk"
                phx-value-action="job_discard"
                variant={:danger}
              >
                Discard jobs
              </Primitives.button>
            </div>
          </section>

          <div
            id="jobs-results-region"
            class="obpt-jobs-page__results-region"
            role="region"
            aria-label="Jobs results"
            tabindex="0"
          >
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
          </div>

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

          <p
            :if={@bulk_announcement}
            id="jobs-bulk-announcement"
            role="status"
            aria-live="polite"
            aria-atomic="true"
          >
            {@bulk_announcement}
          </p>

          <OperatorPatterns.confirm_action_dialog
            :if={@bulk_confirmation_action && @bulk_confirmation_form && @bulk_preview}
            id="jobs-bulk-confirmation"
            intent={@bulk_confirmation_action.intent}
            state={@bulk_confirmation_state}
            title={@bulk_confirmation_action.title}
            object_label={@bulk_confirmation_action.object_label}
            scope={@bulk_confirmation_action.scope}
            consequence={@bulk_confirmation_action.consequence}
            reversibility={@bulk_confirmation_action.reversibility}
            support_boundary={@bulk_confirmation_action.support_boundary}
            form={@bulk_confirmation_form}
            bulk_count={bulk_ready_count(@bulk_preview)}
            bulk_scope={@bulk_confirmation_action.bulk_scope}
            confirm_label={@bulk_confirmation_action.confirm_label}
            dismiss_label={@bulk_confirmation_action.dismiss_label}
            pending_copy={@bulk_confirmation_action.pending_copy}
            logical_fallback_id="jobs-selection-summary"
            submit_event="execute_bulk"
            dismiss_event="close_preview"
            progress={bulk_progress_presentation(@bulk_progress)}
            results={bulk_visible_results(@bulk_result_page)}
          >
            <:support_details>
              <p>
                Each job is processed independently. Some actions may succeed while others are skipped or fail.
              </p>
              <p>
                Closing this page will not stop work already started. A service restart may interrupt unfinished jobs; completed actions remain in the Audit log.
              </p>
            </:support_details>
            <:recovery>
              <p :if={@bulk_result_summary}>{@bulk_result_summary}</p>
              <p>
                Review the Audit log for completed actions before creating a fresh preview.
              </p>
              <Primitives.button
                :if={@bulk_confirmation_state in [:partial, :failed]}
                id="jobs-bulk-fresh-preview"
                type="button"
                variant={:primary}
                phx-click="new_bulk_preview"
              >
                Create fresh preview
              </Primitives.button>
              <nav
                :if={@bulk_result_page && @bulk_result_page.total_pages > 1}
                aria-label="Bulk result pages"
              >
                <Primitives.button
                  type="button"
                  phx-click="bulk_result_page"
                  phx-value-page={@bulk_result_page.page - 1}
                  disabled={!@bulk_result_page.previous?}
                >
                  Previous results
                </Primitives.button>
                <span>
                  Result page {@bulk_result_page.page} of {@bulk_result_page.total_pages}
                </span>
                <Primitives.button
                  type="button"
                  phx-click="bulk_result_page"
                  phx-value-page={@bulk_result_page.page + 1}
                  disabled={!@bulk_result_page.next?}
                >
                  Next results
                </Primitives.button>
              </nav>
            </:recovery>
          </OperatorPatterns.confirm_action_dialog>
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

      with {:ok, normalized_id} <- JobsParams.parse_job_id(job_id),
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

    defp freeze_all_matching_selection(socket) do
      if socket.assigns.all_matching_offer? do
        do_freeze_all_matching_selection(socket)
      else
        socket
      end
    end

    defp do_freeze_all_matching_selection(socket) do
      limit = RuntimeConfig.jobs_bulk_target_limit()
      observed_at = DateTime.utc_now() |> DateTime.truncate(:second)

      candidates =
        repo()
        |> Jobs.ordered_ids_window(socket.assigns.filter, limit)
        |> Map.put(:selected_count, socket.assigns.exact_count)

      case BatchCoordinator.freeze_scope(
             :all_matching,
             candidates,
             bulk_filter_identity(socket.assigns.filter),
             observed_at
           ) do
        {:ok, scope} ->
          socket
          |> cancel_bulk_preview()
          |> assign_bulk_defaults()
          |> assign(:frozen_scope, scope)
          |> assign(:selected_jobs, MapSet.new(scope.ids))
          |> assign(
            :selection_scope_copy,
            "All #{scope.selected_count} jobs matching the applied filters"
          )
          |> assign_selection_state()

        {:error, {:too_many_targets, ^limit}} ->
          assign(
            socket,
            :error_message,
            "This action is limited to #{limit} jobs. Narrow the applied filters before continuing."
          )

        {:error, _safe_reason} ->
          assign(socket, :error_message, "The matching job scope could not be frozen.")
      end
    end

    defp start_bulk_preview(socket, action_value) do
      with {:ok, action_kind} <- bulk_action_kind(action_value),
           {:ok, scope} <- bulk_scope_for_preview(socket),
           {:ok, handle} <-
             BatchCoordinator.start_preview(
               self(),
               repo(),
               socket.assigns.current_actor,
               action_kind,
               scope,
               []
             ) do
        socket
        |> cancel_bulk_preview()
        |> put_private(@jobs_bulk_handle_private, handle)
        |> assign(:frozen_scope, scope)
        |> assign(:bulk_action_kind, action_kind)
        |> assign(:bulk_preview, nil)
        |> assign(:bulk_confirmation_action, nil)
        |> assign(:bulk_confirmation_form, nil)
        |> assign(:bulk_confirmation_state, :preview)
        |> assign(:bulk_progress, nil)
        |> assign(:bulk_results, [])
        |> assign(:bulk_result_page, nil)
        |> assign(:bulk_result_summary, nil)
        |> assign(:bulk_announcement, "Creating a fresh bulk preview.")
        |> assign(:error_message, nil)
      else
        {:error, :empty_scope} ->
          assign(socket, :error_message, "Select at least one job before creating a preview.")

        {:error, {:too_many_targets, limit}} ->
          assign(
            socket,
            :error_message,
            "This action is limited to #{limit} jobs. Narrow the applied filters before continuing."
          )

        {:error, _safe_reason} ->
          assign(socket, :error_message, "The bulk preview could not be started.")
      end
    end

    defp bulk_scope_for_preview(socket) do
      case Map.get(socket.assigns, :frozen_scope) do
        %BatchCoordinator.Scope{} = scope ->
          {:ok, scope}

        nil ->
          ids =
            socket.assigns.selected_jobs
            |> MapSet.to_list()
            |> Enum.sort()

          if ids == [] do
            {:error, :empty_scope}
          else
            BatchCoordinator.freeze_scope(
              :explicit,
              ids,
              bulk_filter_identity(socket.assigns.filter),
              DateTime.utc_now() |> DateTime.truncate(:second)
            )
          end
      end
    end

    defp assign_bulk_preview(socket, %{receipt: receipt, results: results}) do
      scope = socket.assigns.frozen_scope
      ready_count = receipt.ready
      excluded_count = receipt.excluded
      off_page_count = Enum.count(scope.ids, &(&1 not in socket.assigns.page_job_ids))
      action_kind = receipt.action

      preview = %{
        receipt: receipt,
        results: results,
        scope: scope,
        off_page_count: off_page_count
      }

      confirmation_state = if ready_count == 0, do: :failed, else: :preview

      socket =
        socket
        |> assign(:bulk_preview, preview)
        |> assign(
          :bulk_confirmation_action,
          bulk_confirmation_action(
            socket,
            action_kind,
            scope,
            ready_count,
            excluded_count,
            off_page_count
          )
        )
        |> assign(:bulk_confirmation_state, confirmation_state)
        |> assign(:bulk_confirmation_form, bulk_confirmation_form("", ""))
        |> assign(
          :bulk_announcement,
          "#{ready_count} jobs are ready and #{excluded_count} are excluded."
        )

      if ready_count == 0 do
        safe_results = Enum.map(results, &preview_result_for_display/1)

        socket
        |> assign(
          :bulk_result_summary,
          "No jobs are ready for this action. Review the excluded jobs or create a fresh preview after the jobs change."
        )
        |> assign(:bulk_results, safe_results)
        |> assign_bulk_result_page(1)
      else
        socket
      end
    end

    defp validate_and_start_bulk_execution(socket, confirmation) do
      if socket.assigns.bulk_confirmation_state == :preview do
        do_validate_and_start_bulk_execution(socket, confirmation)
      else
        socket
      end
    end

    defp do_validate_and_start_bulk_execution(socket, confirmation) do
      reason = confirmation |> Map.get("reason", "") |> String.trim()
      confirmation_count = confirmation |> Map.get("confirmation_count", "") |> String.trim()
      ready_count = bulk_ready_count(socket.assigns.bulk_preview)

      errors =
        []
        |> maybe_add_bulk_error(
          String.length(reason) < 8,
          :reason,
          "Enter at least 8 characters."
        )
        |> maybe_add_bulk_error(
          confirmation_count != Integer.to_string(ready_count || 0),
          :confirmation_count,
          "Type exactly #{ready_count || 0} to confirm."
        )

      cond do
        ready_count in [nil, 0] ->
          socket

        errors != [] ->
          assign(
            socket,
            :bulk_confirmation_form,
            bulk_confirmation_form(reason, confirmation_count, errors)
          )

        true ->
          handle = Map.get(socket.private, @jobs_bulk_handle_private)

          case BatchCoordinator.start_execution(
                 self(),
                 repo(),
                 socket.assigns.current_actor,
                 handle,
                 reason,
                 []
               ) do
            {:ok, _run_ref} ->
              socket
              |> assign(:bulk_confirmation_state, :submitting)
              |> assign(:bulk_progress, %{
                processed: 0,
                total: ready_count,
                success: 0,
                skipped: 0,
                failed: 0
              })
              |> assign(
                :bulk_confirmation_form,
                bulk_confirmation_form(reason, confirmation_count)
              )
              |> assign(
                :bulk_announcement,
                "#{bulk_action_noun(socket.assigns.bulk_action_kind)} for #{ready_count} jobs started."
              )

            {:error, _safe_reason} ->
              assign_bulk_failure(socket, :execution_unavailable)
          end
      end
    end

    defp finalize_bulk_execution(socket, %{receipt: receipt, results: execution_results}) do
      preview = socket.assigns.bulk_preview
      scope = preview.scope

      if valid_bulk_receipt?(receipt, preview, socket.assigns.bulk_action_kind) and
           execution_positions_valid?(execution_results, preview.results) do
        execution_by_position = Map.new(execution_results, &{&1.position, &1})

        combined_results =
          Enum.map(preview.results, fn result ->
            case result.outcome do
              :ready -> Map.fetch!(execution_by_position, result.position)
              :excluded -> preview_result_for_display(result)
            end
          end)

        successful_positions =
          execution_results
          |> Enum.filter(&(&1.outcome == :success))
          |> MapSet.new(& &1.position)

        unresolved_ids =
          scope.ids
          |> Enum.with_index()
          |> Enum.reject(fn {_id, position} ->
            MapSet.member?(successful_positions, position)
          end)
          |> Enum.map(&elem(&1, 0))

        all_success? =
          preview.receipt.excluded == 0 and
            receipt.all_success? and
            receipt.total == scope.selected_count

        if all_success? do
          action = bulk_action_noun(socket.assigns.bulk_action_kind)

          socket
          |> clear_bulk_confirmation()
          |> assign(:selected_jobs, MapSet.new())
          |> assign(
            :success_message,
            "#{action} requested for #{receipt.success} jobs. Audit evidence was recorded per job."
          )
          |> assign_selection_state()
          |> load_jobs(socket.assigns.filter)
        else
          confirmation_state = if receipt.success > 0, do: :partial, else: :failed
          action = bulk_action_noun(socket.assigns.bulk_action_kind)

          socket
          |> assign(:selected_jobs, MapSet.new(unresolved_ids))
          |> assign(:selection_scope_copy, "Unresolved jobs retained for a fresh preview")
          |> assign(:bulk_confirmation_state, confirmation_state)
          |> assign(:bulk_results, combined_results)
          |> assign(
            :bulk_result_summary,
            "#{action} finished with mixed results. Review skipped and failed jobs before trying again."
          )
          |> assign(
            :bulk_announcement,
            "#{action} finished: #{receipt.success} succeeded, #{receipt.skipped + preview.receipt.excluded} skipped, and #{receipt.failed} failed."
          )
          |> load_jobs(socket.assigns.filter)
          |> assign_bulk_result_page(1)
        end
      else
        assign_bulk_failure(socket, :execution_unavailable)
      end
    end

    defp valid_bulk_receipt?(receipt, preview, action_kind) do
      receipt.action == action_kind and
        receipt.total == preview.receipt.ready and
        receipt.success + receipt.skipped + receipt.failed == receipt.total
    end

    defp execution_positions_valid?(execution_results, preview_results)
         when is_list(execution_results) and is_list(preview_results) do
      ready_positions =
        for %{outcome: :ready, position: position} <- preview_results do
          position
        end

      execution_positions =
        Enum.map(execution_results, fn
          %{position: position} -> position
          _invalid -> :invalid
        end)

      length(execution_positions) == length(ready_positions) and
        Enum.all?(execution_positions, &(is_integer(&1) and &1 >= 0)) and
        MapSet.size(MapSet.new(execution_positions)) == length(execution_positions) and
        MapSet.new(execution_positions) == MapSet.new(ready_positions)
    end

    defp execution_positions_valid?(_execution_results, _preview_results), do: false

    defp assign_bulk_failure(socket, safe_reason) do
      if Map.get(socket.assigns, :bulk_preview) do
        interrupted? = socket.assigns.bulk_confirmation_state == :submitting

        summary =
          if interrupted? do
            "This run may have been interrupted. Review the Audit log for completed actions before creating a fresh preview."
          else
            bulk_failure_copy(safe_reason)
          end

        socket
        |> assign(:bulk_confirmation_state, :failed)
        |> assign(:bulk_result_summary, summary)
        |> assign(:bulk_announcement, summary)
      else
        assign(socket, :error_message, bulk_failure_copy(safe_reason))
      end
    end

    defp assign_bulk_result_page(socket, requested_page) do
      page =
        case requested_page do
          value when is_integer(value) ->
            value

          value when is_binary(value) ->
            case Integer.parse(value) do
              {integer, ""} -> integer
              _invalid -> 1
            end

          _invalid ->
            1
        end

      safe_page = BatchCoordinator.result_page(socket.assigns.bulk_results, page)
      scope = Map.get(socket.assigns, :frozen_scope)
      actor = Map.get(socket.assigns, :current_actor)

      visible_results =
        Enum.map(safe_page.results, &decorate_bulk_result(&1, scope, actor))

      assign(socket, :bulk_result_page, %{safe_page | results: visible_results})
    end

    defp decorate_bulk_result(result, %BatchCoordinator.Scope{} = scope, actor) do
      job_id = Enum.at(scope.ids, result.position)

      %{
        id: "bulk-result-#{result.position}",
        object_label: "Job #{job_id}",
        outcome: result.outcome,
        message: result.message,
        recovery: result.recovery,
        audit_href: authorized_job_audit_href(actor, job_id)
      }
    end

    defp preview_result_for_display(result) do
      %{result | outcome: :skipped}
    end

    defp bulk_confirmation_action(
           socket,
           action_kind,
           scope,
           ready_count,
           excluded_count,
           off_page_count
         ) do
      observed_time = Calendar.strftime(scope.observed_at, "%H:%M:%S")
      action = bulk_action_noun(action_kind)
      action_lower = String.downcase(action)

      %{
        intent: if(action_kind == :retry, do: :warning, else: :danger),
        title: "#{action} #{ready_count} ready jobs",
        object_label: "#{scope.selected_count} selected jobs",
        scope:
          "#{scope.selected_count} selected, #{ready_count} ready, #{excluded_count} excluded, #{off_page_count} off-page. " <>
            "This selection was captured at #{observed_time} UTC. New matching jobs will not be included.",
        bulk_scope:
          "#{bulk_scope_label(scope.mode)}. #{human_filter_identity(socket.assigns.filter)}.",
        consequence: bulk_consequence(action_kind),
        reversibility: bulk_reversibility(action_kind),
        support_boundary:
          "Each Lifeline action records independent per-job evidence; the batch is not atomic.",
        confirm_label: "#{action} #{ready_count} jobs",
        dismiss_label: bulk_dismiss_label(action_kind),
        pending_copy: "#{String.capitalize(action_lower)}ing #{ready_count} jobs…"
      }
    end

    defp bulk_confirmation_form(reason, confirmation_count, errors \\ []) do
      options =
        if errors == [] do
          []
        else
          [errors: errors, action: :validate]
        end

      Phoenix.Component.to_form(
        %{"reason" => reason, "confirmation_count" => confirmation_count},
        [as: :confirmation, id: "jobs-bulk-confirmation-form"] ++ options
      )
    end

    defp maybe_add_bulk_error(errors, true, field, message),
      do: errors ++ [{field, {message, []}}]

    defp maybe_add_bulk_error(errors, false, _field, _message), do: errors

    defp bulk_action_kind(action_value) do
      case Enum.find(@job_action_values, fn {_kind, value} -> value == action_value end) do
        {kind, _value} -> {:ok, kind}
        nil -> {:error, :unsupported_action}
      end
    end

    defp bulk_ready_count(%{receipt: %{ready: ready}}) when ready > 0, do: ready
    defp bulk_ready_count(_preview), do: nil

    defp bulk_progress_presentation(%{processed: processed, total: total}) when total > 0,
      do: %{value: processed, max: total}

    defp bulk_progress_presentation(_progress), do: nil

    defp bulk_visible_results(%{results: results}), do: results
    defp bulk_visible_results(_page), do: []

    defp current_bulk_run_ref(socket) do
      case Map.get(socket.private, @jobs_bulk_handle_private) do
        %{run_ref: run_ref} -> run_ref
        _missing -> nil
      end
    end

    defp cancel_bulk_preview(socket) do
      case Map.get(socket.private, @jobs_bulk_handle_private) do
        %{run_ref: run_ref, coordinator: coordinator}
        when is_reference(run_ref) and is_pid(coordinator) ->
          send(coordinator, {:cancel, run_ref})

        _missing ->
          :ok
      end

      put_private(socket, @jobs_bulk_handle_private, nil)
    end

    defp clear_bulk_confirmation(socket) do
      socket
      |> cancel_bulk_preview()
      |> assign_bulk_defaults()
      |> assign_selection_state()
    end

    defp assign_bulk_defaults(socket) do
      socket
      |> put_private(@jobs_bulk_handle_private, nil)
      |> assign(:frozen_scope, nil)
      |> assign(:bulk_action_kind, nil)
      |> assign(:bulk_confirmation_action, nil)
      |> assign(:bulk_confirmation_state, :preview)
      |> assign(:bulk_confirmation_form, nil)
      |> assign(:bulk_preview, nil)
      |> assign(:bulk_progress, nil)
      |> assign(:bulk_results, [])
      |> assign(:bulk_result_page, nil)
      |> assign(:bulk_result_summary, nil)
      |> assign(:bulk_announcement, nil)
      |> assign(:selection_scope_copy, nil)
      |> assign(:error_message, nil)
    end

    defp bulk_filter_identity(filter) do
      filter
      |> canonical_params()
      |> URI.encode_query()
    end

    defp human_filter_identity(filter) do
      optional =
        [
          {"queue", filter.queue},
          {"worker", filter.worker},
          {"tags", if(filter.tags, do: Enum.join(filter.tags, ", "))}
        ]
        |> Enum.reject(fn {_label, value} -> is_nil(value) or value == "" end)
        |> Enum.map_join(", ", fn {label, value} -> "#{label} #{value}" end)

      base = "#{state_label(to_string(filter.state))} jobs matching the applied filters"
      if optional == "", do: base, else: "#{base}: #{optional}"
    end

    defp bulk_scope_label(:all_matching), do: "All matching frozen scope"
    defp bulk_scope_label(:explicit), do: "Explicit frozen selection"

    defp bulk_action_noun(:retry), do: "Retry"
    defp bulk_action_noun(:cancel), do: "Cancel"
    defp bulk_action_noun(:discard), do: "Discard"

    defp bulk_consequence(:retry),
      do:
        "Powertools requests a retry for each ready job. A retry request does not mean the job completed."

    defp bulk_consequence(:cancel),
      do: "Each ready job stops and will not retry. This cannot be undone."

    defp bulk_consequence(:discard),
      do: "Each ready job is marked discarded and will not retry. This cannot be undone."

    defp bulk_reversibility(:retry), do: "A retry request cannot be undone."
    defp bulk_reversibility(:cancel), do: "Cancellation cannot be undone."
    defp bulk_reversibility(:discard), do: "Discarding cannot be undone."

    defp bulk_dismiss_label(:cancel), do: "Keep running"
    defp bulk_dismiss_label(_action), do: "Keep current state"

    defp bulk_failure_copy(:nothing_ready),
      do:
        "No jobs are ready for this action. Review the excluded jobs or create a fresh preview after the jobs change."

    defp bulk_failure_copy(:not_authorized),
      do: "The bulk action is no longer authorized. Create a fresh preview after access changes."

    defp bulk_failure_copy(_safe_reason),
      do:
        "The bulk action is unavailable. Review current job truth before creating a fresh preview."

    defp detail_resource_id(job_id) do
      case JobsParams.parse_job_id(job_id) do
        {:ok, normalized_id} -> Integer.to_string(normalized_id)
        :error -> nil
      end
    end

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
      |> assign(:all_matching_offer?, false)
      |> assign(:selection_scope_copy, nil)
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
      |> assign(:selected_jobs, MapSet.new())
      |> assign_bulk_defaults()
      |> assign(:success_message, nil)
      |> assign(:back_path, Selectors.jobs_path([]))
      |> assign(:bulk_action_enabled, %{retry: false, cancel: false, discard: false})
      |> assign(:read_only?, true)
      |> assign_read_only()
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

    defp refresh_selection(socket, selected_jobs) do
      rows =
        Enum.map(socket.assigns.rows, fn row ->
          put_in(row, [:selection, :checked?], MapSet.member?(selected_jobs, row.id))
        end)

      socket
      |> cancel_bulk_preview()
      |> assign(:rows, rows)
      |> assign(:selected_jobs, selected_jobs)
      |> assign(:success_message, nil)
      |> assign_bulk_defaults()
      |> assign_selection_state()
    end

    defp assign_selection_state(socket) do
      job_ids = socket.assigns.page_job_ids
      selected_jobs = socket.assigns.selected_jobs

      page_selection_state =
        cond do
          job_ids == [] ->
            :unchecked

          Enum.all?(job_ids, &MapSet.member?(selected_jobs, &1)) ->
            :checked

          Enum.any?(job_ids, &MapSet.member?(selected_jobs, &1)) ->
            :mixed

          true ->
            :unchecked
        end

      selected_count = MapSet.size(selected_jobs)
      frozen_scope = Map.get(socket.assigns, :frozen_scope)

      all_matching_offer? =
        page_selection_state == :checked and
          socket.assigns.exact_count > selected_count and
          is_nil(frozen_scope)

      assign(socket,
        page_selection_state: page_selection_state,
        selected_count: selected_count,
        all_matching_offer?: all_matching_offer?
      )
    end

    defp reset_browse_transients(socket) do
      socket
      |> cancel_bulk_preview()
      |> assign(:selected_jobs, MapSet.new())
      |> assign(:selected_count, 0)
      |> assign(:all_matching_offer?, false)
      |> assign(:selection_scope_copy, nil)
      |> assign(:page_selection_state, :unchecked)
      |> assign(:quick_review, nil)
      |> assign(:quick_review_id, nil)
      |> assign(:preview, nil)
      |> assign(:success_message, nil)
      |> assign(:confirmation, nil)
      |> assign_bulk_defaults()
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

    defp assign_read_only(socket) do
      actor = Map.get(socket.assigns, :current_actor)
      resource = %{type: :page, id: "jobs"}

      enabled =
        Map.new(@job_action_permissions, fn {action_kind, permission} ->
          {action_kind, LiveAuth.authorized?(actor, permission, resource)}
        end)

      socket
      |> assign(:bulk_action_enabled, enabled)
      |> assign(:read_only?, not Enum.any?(enabled, fn {_action, allowed?} -> allowed? end))
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
