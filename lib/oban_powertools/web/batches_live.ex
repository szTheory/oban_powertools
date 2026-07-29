if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.BatchesLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{Batches, DisplayPolicy, Lifeline}
    alias ObanPowertools.Web.Components.{DataDisplay, Forms, OperatorPatterns, Primitives}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

    @valid_statuses ~w(all inserting executing exhausted insert_failed callback_failed completed)
    @batch_member_limit 50
    @batch_callback_limit 25
    @batch_result_limit 50
    @batch_audit_limit 25
    @output_unavailable_copy "A chain step needs upstream output that is missing, expired, or was not recorded. Review the failed callback and retry only after the upstream output contract is corrected."

    @impl true
    def mount(params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      action = socket.assigns.live_action

      {permission, resource_type, resource_id} =
        case action do
          :show -> {:view_batch_detail, :batch, params["id"]}
          _ -> {:view_batches, :page, "batches"}
        end

      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, permission, %{type: resource_type, id: resource_id}) do
        :ok = DisplayPolicy.assert_configured!()

        {:ok,
         socket
         |> assign(:oban_dashboard_path, dashboard_path)
         |> assign_defaults()}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(%{"id" => id}, _uri, socket) do
      {:noreply, load_batch_detail(socket, id)}
    end

    def handle_params(params, _uri, socket) do
      case {connected?(socket), Map.get(params, "status")} do
        {true, nil} ->
          {:noreply, push_patch(socket, to: Selectors.batches_path([{"status", "all"}]))}

        _ ->
          filter = filter_from_params(params)
          {:noreply, load_batches(assign(socket, :selected_failed_jobs, MapSet.new()), filter)}
      end
    end

    @impl true
    def handle_event("select_status", %{"status" => status}, socket) do
      if status in @valid_statuses do
        filter = %{socket.assigns.filter | status: status_atom(status), page: 1}

        {:noreply,
         socket
         |> assign(:selected_failed_jobs, MapSet.new())
         |> push_patch(to: Selectors.batches_path(filter_path(filter)))}
      else
        {:noreply, socket}
      end
    end

    def handle_event("filter", %{"filter" => params}, socket) do
      filter = socket.assigns.filter

      new_filter = %{
        filter
        | query: blank_to_nil(Map.get(params, "query")),
          queue: blank_to_nil(Map.get(params, "queue")),
          worker: blank_to_nil(Map.get(params, "worker")),
          chain_only: truthy?(Map.get(params, "chain_only")),
          page: 1
      }

      {:noreply,
       socket
       |> assign(:selected_failed_jobs, MapSet.new())
       |> push_patch(to: Selectors.batches_path(filter_path(new_filter)))}
    end

    def handle_event("toggle_failed_job", %{"id" => id_str}, socket) do
      with {id, ""} <- Integer.parse(id_str),
           true <- MapSet.member?(eligible_failed_job_ids(socket), id) do
        selected = socket.assigns.selected_failed_jobs

        selected =
          if MapSet.member?(selected, id) do
            MapSet.delete(selected, id)
          else
            MapSet.put(selected, id)
          end

        {:noreply, assign(socket, :selected_failed_jobs, selected)}
      else
        _ -> {:noreply, socket}
      end
    end

    def handle_event("toggle_all_failed_jobs", _params, socket) do
      eligible = eligible_failed_job_ids(socket)
      selected = socket.assigns.selected_failed_jobs
      all_selected? = MapSet.size(eligible) > 0 and MapSet.subset?(eligible, selected)

      selected =
        if all_selected? do
          MapSet.difference(selected, eligible)
        else
          MapSet.union(selected, eligible)
        end

      {:noreply, assign(socket, :selected_failed_jobs, selected)}
    end

    def handle_event("preview_bulk_retry", _params, socket) do
      with true <- MapSet.size(socket.assigns.selected_failed_jobs) > 0,
           true <- socket.assigns.can_retry_batch_jobs?,
           :ok <-
             LiveAuth.authorize_action(
               socket,
               :preview_repair,
               %{
                 type: :batch,
                 id: socket.assigns.batch_detail.id
               },
               message: "Permission changed. Refresh the batch and try again."
             ) do
        {:noreply,
         socket
         |> assign(:bulk_preview?, true)
         |> assign(:callback_preview, nil)
         |> assign(:callback_preview_presentation, nil)
         |> assign(:reason, "")
         |> assign(:error_message, nil)}
      else
        false ->
          {:noreply,
           assign(socket, :error_message, "Select at least one retry-eligible failed job.")}

        {:error, message} ->
          {:noreply, assign(socket, :error_message, message)}
      end
    end

    def handle_event("preview_callback_retry", %{"id" => id}, socket) do
      with {:ok, callback} <- find_retryable_callback(socket, id),
           true <- callback_retry_allowed?(socket, callback.id),
           :ok <-
             LiveAuth.authorize_action(
               socket,
               :preview_repair,
               %{type: :callback, id: id},
               message: "Permission changed. Refresh the batch and try again."
             ),
           {:ok, preview} <-
             Lifeline.preview_repair(repo(), socket.assigns.current_actor, %{
               incident_id: nil,
               action: "callback_retry",
               target_type: "callback",
               target_id: callback.id
             }) do
        {:noreply,
         socket
         |> assign(:callback_preview, preview)
         |> assign(
           :callback_preview_presentation,
           ControlPlanePresenter.present_batch_retry_preview(preview, %{
             selected_count: 1,
             object_label: "Callback #{callback.event}",
             object_noun: "callback"
           })
         )
         |> assign(:bulk_preview?, false)
         |> assign(:reason, "")
         |> assign(:error_message, nil)}
      else
        false ->
          {:noreply, assign(socket, :error_message, LiveAuth.permission_message(:retry_callback))}

        {:error, :not_found} ->
          {:noreply, assign(socket, :error_message, "callback_not_retryable")}

        {:error, :unauthorized} ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:unauthorized))}

        {:error, message} when is_binary(message) ->
          {:noreply, assign(socket, :error_message, message)}

        {:error, reason} ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(reason))}
      end
    end

    def handle_event("reason", %{"reason" => reason}, socket) do
      {:noreply, assign(socket, :reason, reason)}
    end

    def handle_event("reason", %{"batch_retry" => %{"reason" => reason}}, socket) do
      {:noreply, assign(socket, :reason, reason)}
    end

    def handle_event("close_preview", _params, socket) do
      {:noreply,
       assign(socket,
         bulk_preview?: false,
         callback_preview: nil,
         callback_preview_presentation: nil,
         reason: "",
         error_message: nil
       )}
    end

    def handle_event("execute_bulk_retry", params, socket) do
      reason = submit_reason(params, socket)

      cond do
        reason == "" ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:reason_required))}

        not socket.assigns.can_retry_batch_jobs? ->
          {:noreply,
           assign(socket, :error_message, LiveAuth.permission_message(:retry_batch_jobs))}

        true ->
          with :ok <-
                 LiveAuth.authorize_action(socket, :execute_repair, %{
                   type: :batch,
                   id: socket.assigns.batch_detail.id
                 }) do
            actor = socket.assigns.current_actor

            {successes, failures} =
              socket.assigns.selected_failed_jobs
              |> Enum.filter(&MapSet.member?(eligible_failed_job_ids(socket), &1))
              |> Enum.reduce({0, 0}, fn job_id, {success_count, failure_count} ->
                case Lifeline.preview_repair(repo(), actor, %{
                       incident_id: nil,
                       action: "job_retry",
                       target_type: "job",
                       target_id: job_id
                     }) do
                  {:ok, preview} ->
                    case Lifeline.execute_repair(repo(), actor, preview.preview_token, reason) do
                      {:ok, _result} -> {success_count + 1, failure_count}
                      _error -> {success_count, failure_count + 1}
                    end

                  _error ->
                    {success_count, failure_count + 1}
                end
              end)

            message = "Batch retry complete: #{successes} retried, #{failures} skipped or failed."

            socket =
              socket
              |> put_flash(:info, message)
              |> assign(:success_message, message)
              |> assign(:selected_failed_jobs, MapSet.new())
              |> assign(:bulk_preview?, false)
              |> assign(:reason, "")
              |> assign(:error_message, nil)

            {:noreply, load_batch_detail(socket, socket.assigns.batch_detail.id)}
          else
            {:error, message} ->
              {:noreply, assign(socket, :error_message, message)}
          end
      end
    end

    def handle_event("execute_callback_retry", params, socket) do
      reason = submit_reason(params, socket)
      preview = socket.assigns.callback_preview

      cond do
        is_nil(preview) ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:preview_not_found))}

        reason == "" ->
          {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:reason_required))}

        true ->
          with :ok <-
                 LiveAuth.authorize_action(socket, :execute_repair, %{
                   type: :callback,
                   id: preview.target_id
                 }),
               {:ok, _result} <-
                 Lifeline.execute_repair(
                   repo(),
                   socket.assigns.current_actor,
                   preview.preview_token,
                   reason
                 ) do
            message = "Callback retry complete."

            socket =
              socket
              |> put_flash(:info, message)
              |> assign(:success_message, message)
              |> assign(:callback_preview, nil)
              |> assign(:callback_preview_presentation, nil)
              |> assign(:reason, "")
              |> assign(:error_message, nil)

            {:noreply, load_batch_detail(socket, socket.assigns.batch_detail.id)}
          else
            {:error, :unauthorized} ->
              {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(:unauthorized))}

            {:error, reason} ->
              {:noreply, assign(socket, :error_message, LiveAuth.mutation_error(reason))}
          end
      end
    end

    def handle_event("paginate", %{"page" => page_str}, socket) do
      case Integer.parse(page_str) do
        {page, ""} when page >= 1 ->
          filter = %{socket.assigns.filter | page: page}
          {:noreply, push_patch(socket, to: Selectors.batches_path(filter_path(filter)))}

        _ ->
          {:noreply, socket}
      end
    end

    @impl true
    def render(%{live_action: :show} = assigns), do: detail_page_content(assigns)
    def render(assigns), do: page_content(assigns)

    def detail_page_content(assigns) do
      assigns =
        assigns
        |> assign_new(:batch_page_id, fn -> "batch-detail-page" end)
        |> assign_new(:batch_retry_form, fn ->
          to_form(%{"reason" => assigns[:reason] || ""}, as: :batch_retry)
        end)

      ~H"""
      <main id={@batch_page_id} class="obpt-batches-page obpt-batches-page--detail">
        <%= if @batch_not_found? do %>
          <header class="obpt-page__header">
            <h1>Batch unavailable</h1>
            <p>It may not exist, may no longer be retained, or you may not have access. Return to Batches and choose another batch.</p>
            <Primitives.link navigate={Selectors.batches_path([{"status", "all"}])}>
              Back to Batches
            </Primitives.link>
          </header>
        <% else %>
          <header class="obpt-page__header obpt-batches-page__header">
            <div>
              <h1>Batch {batch_name(@batch_detail)}</h1>
              <p>Review current progress, bounded failure evidence, callback posture, and safe Lifeline recovery paths.</p>
            </div>
            <div class="obpt-batches-page__header-actions">
              <DataDisplay.status_pill domain={:batch} state={@batch_detail.status} />
              <Primitives.link navigate={@back_path}>
                Back to Batches
              </Primitives.link>
            </div>
          </header>

          <p :if={@read_only?} class="obpt-batches-page__notice" role="status">
            {LiveAuth.page_read_only_banner(:batch_detail)}
          </p>

          <p :if={@success_message} class="obpt-batches-page__notice" role="status">
            {@success_message}
          </p>

          <DataDisplay.state_message
            :if={@error_message && is_nil(@callback_preview) && !@bulk_preview?}
            id="batch-detail-error"
            state={:error}
            resource="batch action"
          >
            {@error_message}
          </DataDisplay.state_message>

          <section class="obpt-batches-page__summary" aria-label="Batch summary">
            <Primitives.surface variant={:elevated}>
              <h2>Identity</h2>
              <DataDisplay.description_list id="batch-identity">
                <:item label="Batch ID" value_kind={:id}>
                  <DataDisplay.machine_value id="batch-id" value={@batch_detail.id} />
                </:item>
                <:item label="Name">{@batch_detail.name || "Unnamed batch"}</:item>
                <:item label="Inserted count">{@batch_detail.progress.inserted_count}</:item>
                <:item label="Total count">{@batch_detail.progress.total_count}</:item>
                <:item label="Updated">{timestamp_copy(@batch_detail.updated_at)}</:item>
                <:item label="Completed">{timestamp_copy(@batch_detail.completed_at)}</:item>
              </DataDisplay.description_list>
            </Primitives.surface>

            <Primitives.surface variant={:elevated}>
              <h2>Progress</h2>
              <DataDisplay.progress_bar
                id="batch-detail-progress"
                label="Batch progress"
                value={@batch_detail.progress.completed_count}
                max={max(@batch_detail.progress.total_count, 1)}
              />
              <p>{@batch_detail.blocked_state.copy}</p>
            </Primitives.surface>
          </section>

          <Primitives.surface variant={:attention}>
            <h2>Why this batch is blocked</h2>
            <Primitives.badge
              label={@batch_detail.blocked_state.title}
              tone={batch_blocked_tone(@batch_detail.blocked_state.severity)}
            />
            <p>{@batch_detail.blocked_state.copy}</p>
            <DataDisplay.description_list id="batch-blocker-evidence">
              <:item :for={item <- @batch_detail.blocked_state.evidence} label={item.label}>
                {item.value}
              </:item>
            </DataDisplay.description_list>
          </Primitives.surface>

          <Primitives.surface variant={:plain}>
            <div class="obpt-batches-page__section-header">
              <div>
                <h2>Failed Members</h2>
                <p>
                  Retryable selections are page-local and validated from current batch evidence.
                </p>
              </div>
            </div>

            <p :if={not @can_retry_batch_jobs?}>
              Permission: read-only (:retry_batch_jobs). <%= LiveAuth.permission_message(:retry_batch_jobs) %>
            </p>

            <Primitives.surface :if={MapSet.size(@selected_failed_jobs) > 0} variant={:inset}>
              <strong>{selected_jobs_copy(@selected_failed_jobs)}</strong>
              <Primitives.button
                type="button"
                phx-click="preview_bulk_retry"
                aria-label={"Preview failed job retries for #{MapSet.size(@selected_failed_jobs)} selected jobs"}
                disabled={not @can_retry_batch_jobs?}
                variant={:danger}
              >
                Preview failed job retries
              </Primitives.button>
            </Primitives.surface>

            <DataDisplay.data_table
              id="batch-members"
              caption="Failed batch members"
              rows={@batch_detail.failed_members}
              row_id={& &1.job_id}
              state={if(@batch_detail.failed_members == [], do: :empty, else: :ready)}
              resource="failed batch members"
              row_count={length(@batch_detail.failed_members)}
              pagination_summary={if(!@batch_detail.member_evidence.complete?, do: @batch_detail.member_evidence.guidance)}
            >
              <:state_detail>
                <strong>No failed members recorded</strong>
                <span>Current evidence contains no failed members for this batch.</span>
              </:state_detail>
              <:toolbar>
                <Primitives.button
                  type="button"
                  phx-click="toggle_all_failed_jobs"
                  aria-label="Select all eligible failed jobs"
                >
                  Select all eligible
                </Primitives.button>
              </:toolbar>
              <:selection :let={member}>
                <input
                  type="checkbox"
                  checked={MapSet.member?(@selected_failed_jobs, member.job_id)}
                  disabled={not member.retry_eligible?}
                  phx-click="toggle_failed_job"
                  phx-value-id={member.job_id}
                  aria-label={"Select failed job #{member.job_id}"}
                />
              </:selection>
              <:col :let={member} label="Job" value_kind={:id}>
                <DataDisplay.machine_value id={"batch-member-#{member.job_id}"} value={to_string(member.job_id)} />
              </:col>
              <:col :let={member} label="Worker" value_kind={:module}>{short_worker_name(member.worker)}</:col>
              <:col :let={member} label="Queue">{member.queue || "Unknown"}</:col>
              <:col :let={member} label="Status">
                <DataDisplay.status_pill domain={:batch_member} state={member.state} />
              </:col>
              <:col :let={member} label="Attempt">{member.attempt || 0} / {member.max_attempts || "?"}</:col>
              <:col :let={member} label="Last error">
                <DataDisplay.code_block
                  id={"batch-member-#{member.job_id}-error"}
                  label={"Last error for job #{member.job_id}"}
                  content={member.error || "No recorded error"}
                />
              </:col>
              <:action :let={member}>
                <Primitives.link href={member.bridge_href}>
                  Open Generic Job Inspection in Oban Web bridge
                </Primitives.link>
              </:action>
            </DataDisplay.data_table>
          </Primitives.surface>

          <Primitives.surface variant={:plain}>
            <h2>Callback Outbox</h2>
            <DataDisplay.data_table
              id="batch-callbacks"
              caption="Batch callbacks"
              rows={@batch_detail.callbacks}
              row_id={& &1.id}
              state={if(@batch_detail.callbacks == [], do: :empty, else: :ready)}
              resource="batch callbacks"
              row_count={length(@batch_detail.callbacks)}
              pagination_summary={
                if(!@batch_detail.callback_evidence.complete?,
                  do: "Additional callbacks exist; this view shows the first #{@batch_detail.callback_evidence.rendered_count} callbacks."
                )
              }
            >
              <:state_detail>
                <strong>No blocked callbacks recorded</strong>
                <span>Current evidence contains no stuck or dead callback for this batch.</span>
              </:state_detail>
              <:col :let={callback} label="Event">
                <strong>{callback.event}</strong>
                <DataDisplay.machine_value
                  id={"batch-callback-#{callback.id}-dedupe"}
                  value={callback.dedupe_key}
                />
              </:col>
              <:col :let={callback} label="Status">
                <DataDisplay.status_pill domain={:callback_outbox} state={callback.status} />
              </:col>
              <:col :let={callback} label="Attempts">{callback.attempts}</:col>
              <:col :let={callback} label="Lease">
                <span>Available: {timestamp_copy(callback.available_at)}</span>
                <span>Claimed: {timestamp_copy(callback.claimed_at)}</span>
                <span>Lease: {timestamp_copy(callback.lease_expires_at)}</span>
                <span>Delivered: {timestamp_copy(callback.delivered_at)}</span>
              </:col>
              <:col :let={callback} label="Last error">
                <DataDisplay.code_block
                  id={"batch-callback-#{callback.id}-error"}
                  label={"Last error for #{callback.event}"}
                  content={callback.error || "No recorded error"}
                />
              </:col>
              <:action :let={callback}>
                <Primitives.button
                  :if={callback.retry_eligible?}
                  type="button"
                  phx-click="preview_callback_retry"
                  phx-value-id={callback.id}
                  aria-label={"Preview callback retry for #{callback.event}"}
                  disabled={not callback_retry_allowed?(@callback_retry_permissions, callback.id)}
                  disabled_reason={
                    if(!callback_retry_allowed?(@callback_retry_permissions, callback.id),
                      do: LiveAuth.permission_message(:retry_callback)
                    )
                  }
                  variant={:danger}
                >
                  Preview callback retry
                </Primitives.button>
                <span :if={not callback.retry_eligible?}>Not retryable</span>
              </:action>
            </DataDisplay.data_table>
          </Primitives.surface>

          <Primitives.surface variant={:plain}>
            <h2>Chain Context</h2>
            <%= if @batch_detail.chain_context.chain? do %>
              <DataDisplay.description_list id="batch-chain-context">
                <:item label="Chain ID" value_kind={:id}>{@batch_detail.chain_context[:chain_id]}</:item>
                <:item label="Step">{batch_chain_step(@batch_detail.chain_context)}</:item>
                <:item label="Upstream job">{@batch_detail.chain_context[:upstream_job_id] || "Unknown"}</:item>
                <:item label="Next step">{@batch_detail.chain_context[:next_step] || "Unknown"}</:item>
              </DataDisplay.description_list>
            <% else %>
              <DataDisplay.state_message id="batch-chain-empty" state={:empty} resource="chain context">
                <strong>No chain context recorded</strong>
                <span>This batch has no retained chain metadata.</span>
              </DataDisplay.state_message>
            <% end %>
            <p :if={@batch_detail.blocked_state.name in [:output_unavailable, :output_expired]}>
              {@output_unavailable_copy}
            </p>
          </Primitives.surface>

          <Primitives.surface variant={:plain}>
            <h2>Manual Intervention History</h2>
            <DataDisplay.timeline
              id="batch-audit-history"
              state={if(@batch_detail.audit_events == [], do: :empty, else: :ready)}
              resource="manual intervention history"
            >
              <:event
                :for={event <- @batch_detail.audit_events}
                timestamp={timestamp_copy(event.inserted_at)}
                title={event.event_label}
                source={event.resource_label}
              >
                <span>Recorded operator action.</span>
              </:event>
            </DataDisplay.timeline>
          </Primitives.surface>
        <% end %>

        <OperatorPatterns.confirm_action_dialog
          :if={@bulk_preview?}
          id="batch-bulk-preview"
          intent={:warning}
          state={:preview}
          title="Preview failed job retries"
          object_label={"Batch #{batch_name(@batch_detail)}"}
          scope={selected_jobs_copy(@selected_failed_jobs)}
          consequence="Lifeline previews and processes each selected failed job independently. Jobs that changed are skipped and reported; a retry request does not mean the job completed."
          reversibility="Accepted retries enqueue new work and may not be reversible."
          support_boundary="Execution is per job and non-atomic; a preview is not proof that a retry completed."
          form={@batch_retry_form}
          bulk_count={MapSet.size(@selected_failed_jobs)}
          bulk_scope="Current retry-eligible failed jobs in this batch"
          confirm_label={"Retry #{MapSet.size(@selected_failed_jobs)} failed jobs"}
          dismiss_label="Keep current state"
          pending_copy="Retrying selected failed jobs"
          logical_fallback_id="batch-members"
          submit_event="execute_bulk_retry"
          dismiss_event="close_preview"
        >
          <:support_details>
            <p>{LiveAuth.audit_consequence_copy()}</p>
            <p :if={@error_message} role="alert">{@error_message}</p>
          </:support_details>
        </OperatorPatterns.confirm_action_dialog>

        <OperatorPatterns.confirm_action_dialog
          :if={@callback_preview && @callback_preview_presentation}
          id="batch-callback-preview"
          intent={:warning}
          state={:preview}
          title="Preview callback retry"
          object_label={@callback_preview_presentation.object_label}
          scope={@callback_preview_presentation.scope}
          consequence="Lifeline retries this callback after reauthorization. Delivery may still fail, and this action does not replay completed work."
          reversibility="An accepted retry can deliver the callback and may not be reversible."
          support_boundary="Lifeline revalidates current callback state before one non-atomic retry attempt."
          form={@batch_retry_form}
          confirm_label="Retry callback"
          dismiss_label="Keep current state"
          pending_copy="Retrying callback"
          logical_fallback_id="batch-callbacks"
          submit_event="execute_callback_retry"
          dismiss_event="close_preview"
        >
          <:support_details>
            <p>Preview status: {@callback_preview_presentation.state}</p>
            <p>{LiveAuth.audit_consequence_copy()}</p>
            <p :if={@error_message} role="alert">{@error_message}</p>
          </:support_details>
        </OperatorPatterns.confirm_action_dialog>
      </main>
      """
    end

    def page_content(assigns) do
      filter_form =
        to_form(
          %{
            "query" => assigns.filter.query || "",
            "queue" => assigns.filter.queue || "",
            "worker" => assigns.filter.worker || "",
            "chain_only" => assigns.filter.chain_only
          },
          as: :filter
        )

      assigns = assign(assigns, :filter_form, filter_form)

      ~H"""
      <main id="batches-page" class="obpt-batches-page">
        <header class="obpt-page__header">
          <h1>Batches</h1>
          <p>
            Review batch and chain progress, understand blocked work, and follow Lifeline-routed recovery with recorded evidence.
          </p>
        </header>

        <p :if={@read_only?} class="obpt-batches-page__notice" role="status">
          {LiveAuth.page_read_only_banner(:batches)}
        </p>

        <p :if={@success_message} class="obpt-batches-page__notice" role="status">
          {@success_message}
        </p>

        <DataDisplay.state_message :if={@load_error?} id="batches-load-error" state={:error} resource="batches">
          <strong>Batches did not load.</strong>
          <p>Retry the request. If the problem continues, check the host logs.</p>
        </DataDisplay.state_message>

        <section class="obpt-batches-page__metrics" aria-label="Batch summary">
          <DataDisplay.metric_card id="batches-total" label="Total Batches" value={to_string(@metrics.total)} />
          <DataDisplay.metric_card id="batches-attention" label="Needs Attention" value={to_string(@metrics.needs_attention)} tone={:warning} />
          <DataDisplay.metric_card id="batches-executing" label="Executing" value={to_string(@metrics.executing)} tone={:info} />
          <DataDisplay.metric_card id="batches-completed" label="Completed" value={to_string(@metrics.completed)} tone={:success} />
        </section>

        <nav class="obpt-batches-page__statuses" aria-label="Batch status">
          <Primitives.button
            :for={status <- @valid_statuses}
            type="button"
            phx-click="select_status"
            phx-value-status={status}
            variant={if(to_string(@filter.status) == status, do: :primary, else: :neutral)}
          >
            {batch_status_label(status)} ({Map.get(@counts, status, 0)})
          </Primitives.button>
        </nav>

        <.form for={@filter_form} phx-change="filter" class="obpt-batches-page__filters">
          <Forms.input field={@filter_form[:query]} label="Batch name or ID" placeholder="All batches" />
          <Forms.input field={@filter_form[:queue]} label="Queue" placeholder="All queues" />
          <Forms.input field={@filter_form[:worker]} label="Worker" placeholder="All workers" />
          <Forms.checkbox field={@filter_form[:chain_only]} label="Chain only" />
        </.form>

        <DataDisplay.data_table
          id="batches-table"
          caption="Current batches"
          rows={@batches}
          row_id={:id}
          state={if(@batches == [], do: :empty, else: :ready)}
          resource="batches"
          row_count={length(@batches)}
          pagination_summary={"Page #{@filter.page}; up to #{@filter.page_size} batches per page."}
        >
          <:state_detail>
            <%= if batches_filtered?(@filter) do %>
              <strong>No batches match this view</strong>
              <span>Choose another status or clear the name filter to widen the review.</span>
            <% else %>
              <strong>No batches available</strong>
              <span>Batch evidence will appear here when this host records batch work.</span>
            <% end %>
          </:state_detail>
          <:col :let={batch} label="Batch" value_kind={:id}>
            <strong>{batch.name || batch.short_id}</strong>
            <DataDisplay.machine_value id={"batch-#{batch.id}-id"} value={batch.id} />
            <Primitives.badge :if={batch.chain?} label="Chain" tone={:info} size={:sm} />
          </:col>
          <:col :let={batch} label="Operator status">
            <DataDisplay.status_pill domain={:batch} state={batch.status} />
            <span>{batch.blocked_state.title}</span>
          </:col>
          <:col :let={batch} label="Progress">
            <DataDisplay.progress_bar
              id={"batch-progress-#{batch.id}"}
              label={"Progress for #{batch.name || batch.short_id}"}
              value={batch.progress.completed_count}
              max={max(batch.progress.total_count, 1)}
            />
          </:col>
          <:col :let={batch} label="Failed">
            <span>{batch.failed_count} failed</span>
            <span>{batch.retryable_failed_count} retryable</span>
          </:col>
          <:col :let={batch} label="Callbacks">
            <span>Pending {batch.callback_summary.pending}</span>
            <span>Failed {batch.callback_summary.failed}</span>
            <span>Claimed {batch.callback_summary.claimed}</span>
            <span>Delivered {batch.callback_summary.delivered}</span>
          </:col>
          <:col :let={batch} label="Updated">{timestamp_copy(batch.updated_at)}</:col>
          <:action :let={batch}>
            <Primitives.link navigate={Selectors.batch_detail_path(batch.id)}>
              Open batch
            </Primitives.link>
          </:action>
        </DataDisplay.data_table>

        <nav class="obpt-batches-page__pagination" aria-label="Batch pages">
          <Primitives.button
            type="button"
            phx-click="paginate"
            phx-value-page={max(@filter.page - 1, 1)}
            disabled={@filter.page <= 1}
          >
            Previous
          </Primitives.button>
          <Primitives.button
            type="button"
            phx-click="paginate"
            phx-value-page={@filter.page + 1}
            disabled={length(@batches) < @filter.page_size}
          >
            Next
          </Primitives.button>
        </nav>
      </main>
      """
    end

    defp assign_defaults(socket) do
      socket
      |> assign(:valid_statuses, @valid_statuses)
      |> assign(:batches, [])
      |> assign(:counts, Map.new(@valid_statuses, &{&1, 0}))
      |> assign(:metrics, %{total: 0, needs_attention: 0, executing: 0, completed: 0})
      |> assign(:filter, %Batches{})
      |> assign(:batch_detail, nil)
      |> assign(:batch_not_found?, false)
      |> assign(:selected_failed_jobs, MapSet.new())
      |> assign(:bulk_preview?, false)
      |> assign(:callback_preview, nil)
      |> assign(:callback_preview_presentation, nil)
      |> assign(:callback_retry_permissions, %{})
      |> assign(:can_retry_batch_jobs?, false)
      |> assign(:read_only?, true)
      |> assign(:load_error?, false)
      |> assign(:reason, "")
      |> assign(:error_message, nil)
      |> assign(:success_message, nil)
      |> assign(:back_path, Selectors.batches_path([{"status", "all"}]))
      |> assign(:output_unavailable_copy, @output_unavailable_copy)
    end

    defp load_batches(socket, %Batches{} = filter) do
      batches =
        Batches.list(repo(), filter)
        |> Enum.map(fn batch ->
          ControlPlanePresenter.present_batch_row(batch, %{
            detail_href: Selectors.batch_detail_path(batch.id)
          })
        end)

      counts = Batches.count_by_status(repo(), filter)

      socket
      |> assign(:batches, batches)
      |> assign(:counts, counts)
      |> assign(:metrics, metrics_from_counts(counts))
      |> assign(:filter, filter)
      |> assign(:load_error?, false)
      |> assign_index_read_only()
    rescue
      _error ->
        socket
        |> assign(:batches, [])
        |> assign(:counts, Map.new(@valid_statuses, &{&1, 0}))
        |> assign(:metrics, %{total: 0, needs_attention: 0, executing: 0, completed: 0})
        |> assign(:filter, filter)
        |> assign(:load_error?, true)
        |> assign_index_read_only()
    end

    defp load_batch_detail(socket, batch_id) do
      case Batches.get(repo(), batch_id,
             member_limit: @batch_member_limit + 1,
             callback_limit: @batch_callback_limit + 1
           ) do
        nil ->
          socket
          |> assign(:batch_detail, nil)
          |> assign(:batch_not_found?, true)
          |> assign(:selected_failed_jobs, MapSet.new())
          |> assign(:bulk_preview?, false)
          |> assign(:callback_preview, nil)
          |> assign(:read_only?, true)
          |> assign(:back_path, Selectors.batches_path([{"status", "all"}]))

        detail ->
          actor = Map.get(socket.assigns, :current_actor)

          can_retry_batch_jobs? =
            LiveAuth.authorized?(actor, :retry_batch_jobs, %{type: :batch, id: detail.id})

          callback_permissions =
            Map.new(detail.callbacks, fn callback ->
              {callback.id,
               LiveAuth.authorized?(actor, :retry_callback, %{type: :callback, id: callback.id})}
            end)

          presentation =
            detail
            |> bounded_batch_detail_source()
            |> ControlPlanePresenter.present_batch_detail(%{
              back_href: back_path_from_filter(socket)
            })

          socket
          |> assign(:batch_detail, presentation)
          |> assign(:batch_not_found?, false)
          |> assign(:selected_failed_jobs, MapSet.new())
          |> assign(:bulk_preview?, false)
          |> assign(:callback_preview, nil)
          |> assign(:callback_preview_presentation, nil)
          |> assign(:callback_retry_permissions, callback_permissions)
          |> assign(:can_retry_batch_jobs?, can_retry_batch_jobs?)
          |> assign(:read_only?, read_only_detail?(can_retry_batch_jobs?, callback_permissions))
          |> assign(:load_error?, false)
          |> assign(:back_path, back_path_from_filter(socket))
      end
    rescue
      _error ->
        socket
        |> assign(:batch_detail, nil)
        |> assign(:batch_not_found?, true)
        |> assign(:selected_failed_jobs, MapSet.new())
        |> assign(:bulk_preview?, false)
        |> assign(:callback_preview, nil)
        |> assign(:callback_preview_presentation, nil)
        |> assign(:read_only?, true)
    end

    defp bounded_batch_detail_source(detail) do
      detail
      |> Map.put(
        :failed_members,
        detail.failed_members
        |> Enum.sort_by(&{not &1.retry_eligible?, &1.job_id})
        |> Enum.take(@batch_member_limit + 1)
      )
      |> Map.put(:callbacks, Enum.take(detail.callbacks, @batch_callback_limit + 1))
      |> Map.put(:results, Enum.take(Map.get(detail, :results, []), @batch_result_limit + 1))
      |> Map.put(
        :audit_events,
        Enum.take(detail.audit_events, @batch_audit_limit + 1)
      )
    end

    defp assign_index_read_only(socket) do
      actor = Map.get(socket.assigns, :current_actor)

      assign(
        socket,
        :read_only?,
        not LiveAuth.authorized?(actor, :retry_batch_jobs, %{type: :page, id: "batches"})
      )
    end

    defp read_only_detail?(can_retry_batch_jobs?, callback_permissions) do
      not can_retry_batch_jobs? and
        not Enum.any?(callback_permissions, fn {_id, allowed?} -> allowed? end)
    end

    defp filter_from_params(params) do
      status = Map.get(params, "status", "all")

      %Batches{
        status: status_atom(status),
        query: blank_to_nil(Map.get(params, "query")),
        queue: blank_to_nil(Map.get(params, "queue")),
        worker: blank_to_nil(Map.get(params, "worker")),
        chain_only: truthy?(Map.get(params, "chain_only")),
        page: positive_int(Map.get(params, "page"), 1),
        page_size: %Batches{}.page_size
      }
    end

    defp filter_path(filter) do
      [
        {"status", to_string(filter.status)},
        {"query", filter.query},
        {"queue", filter.queue},
        {"worker", filter.worker},
        {"chain_only", if(filter.chain_only, do: "true")},
        {"page", if(filter.page > 1, do: to_string(filter.page))}
      ]
    end

    defp metrics_from_counts(counts) do
      %{
        total: Map.get(counts, "all", 0),
        needs_attention:
          Map.get(counts, "exhausted", 0) + Map.get(counts, "insert_failed", 0) +
            Map.get(counts, "callback_failed", 0),
        executing: Map.get(counts, "executing", 0),
        completed: Map.get(counts, "completed", 0)
      }
    end

    defp eligible_failed_job_ids(socket) do
      socket.assigns
      |> Map.get(:batch_detail)
      |> case do
        nil ->
          MapSet.new()

        detail ->
          detail.failed_members
          |> Enum.filter(& &1.retry_eligible?)
          |> Enum.map(& &1.job_id)
          |> MapSet.new()
      end
    end

    defp find_retryable_callback(socket, id) do
      callbacks =
        case Map.get(socket.assigns, :batch_detail) do
          nil -> []
          detail -> detail.callbacks
        end

      case Enum.find(callbacks, &(to_string(&1.id) == to_string(id) and &1.retry_eligible?)) do
        nil -> {:error, :not_found}
        callback -> {:ok, callback}
      end
    end

    defp callback_retry_allowed?(%{assigns: assigns}, id) do
      assigns.callback_retry_permissions
      |> callback_retry_allowed?(id)
    end

    defp callback_retry_allowed?(socket, id) when is_struct(socket, Phoenix.LiveView.Socket) do
      socket.assigns.callback_retry_permissions
      |> callback_retry_allowed?(id)
    end

    defp callback_retry_allowed?(permissions, id) when is_map(permissions) do
      Map.get(permissions, id, false)
    end

    defp submit_reason(params, socket) do
      params
      |> Map.get("batch_retry", params)
      |> Map.get("reason", socket.assigns.reason || "")
      |> to_string()
      |> String.trim()
    end

    defp back_path_from_filter(socket) do
      filter = Map.get(socket.assigns, :filter)

      if filter do
        Selectors.batches_path(filter_path(filter))
      else
        Selectors.batches_path([{"status", "all"}])
      end
    end

    defp status_atom(status) when status in @valid_statuses, do: String.to_atom(status)
    defp status_atom(_status), do: :all

    defp blank_to_nil(nil), do: nil
    defp blank_to_nil(""), do: nil
    defp blank_to_nil(value), do: value

    defp truthy?(value), do: value in [true, "true", "on", "1", 1]

    defp positive_int(nil, default), do: default

    defp positive_int(value, default) do
      case Integer.parse(to_string(value)) do
        {int, ""} when int >= 1 -> int
        _ -> default
      end
    end

    defp batch_status_label(status) do
      status
      |> to_string()
      |> String.replace("_", " ")
      |> String.capitalize()
    end

    defp batches_filtered?(filter) do
      to_string(filter.status) != "all" or filter.query not in [nil, ""] or
        filter.queue not in [nil, ""] or filter.worker not in [nil, ""] or
        filter.chain_only
    end

    defp batch_blocked_tone(:success), do: :success
    defp batch_blocked_tone(:warning), do: :warning
    defp batch_blocked_tone(:danger), do: :danger
    defp batch_blocked_tone(_severity), do: :neutral

    defp selected_jobs_copy(selected) do
      case MapSet.size(selected) do
        1 -> "1 failed job selected"
        count -> "#{count} failed jobs selected"
      end
    end

    defp batch_chain_step(context) do
      name = context[:chain_step_name] || "Unknown"

      if context[:chain_step_index] do
        "#{name} (#{context[:chain_step_index]}/#{context[:chain_step_count] || "?"})"
      else
        name
      end
    end

    defp batch_name(%{name: name}) when is_binary(name) and name != "", do: name
    defp batch_name(%{short_id: short_id}), do: short_id
    defp batch_name(%{id: id}) when is_binary(id), do: String.slice(id, 0, 8)
    defp batch_name(_batch), do: "unknown"

    defp short_worker_name(worker) when is_binary(worker),
      do: worker |> String.split(".") |> List.last()

    defp short_worker_name(_worker), do: "Unknown"

    defp timestamp_copy(nil), do: "Unknown"

    defp timestamp_copy(%NaiveDateTime{} = timestamp) do
      timestamp
      |> DateTime.from_naive!("Etc/UTC")
      |> timestamp_copy()
    end

    defp timestamp_copy(%DateTime{} = timestamp) do
      seconds = DateTime.diff(DateTime.utc_now(), timestamp, :second)

      relative =
        if seconds < 0 do
          abs_s = abs(seconds)

          cond do
            abs_s < 60 -> "in #{abs_s}s"
            abs_s < 3_600 -> "in #{div(abs_s, 60)}m"
            abs_s < 86_400 -> "in #{div(abs_s, 3_600)}h"
            true -> "in #{div(abs_s, 86_400)}d"
          end
        else
          cond do
            seconds < 60 -> "#{seconds}s ago"
            seconds < 3_600 -> "#{div(seconds, 60)}m ago"
            seconds < 86_400 -> "#{div(seconds, 3_600)}h ago"
            true -> "#{div(seconds, 86_400)}d ago"
          end
        end

      exact = Calendar.strftime(timestamp, "%Y-%m-%d %H:%M:%S UTC")
      "#{relative} (#{exact})"
    end

    defp timestamp_copy(timestamp) when is_binary(timestamp), do: timestamp
    defp timestamp_copy(_timestamp), do: "Unknown"

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
