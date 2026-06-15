if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.BatchesLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{Batches, DisplayPolicy, Lifeline}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

    @valid_statuses ~w(all inserting executing exhausted insert_failed callback_failed completed)
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
             LiveAuth.authorize_action(socket, :preview_repair, %{
               type: :batch,
               id: socket.assigns.batch_detail.id
             }) do
        {:noreply,
         socket
         |> assign(:bulk_preview?, true)
         |> assign(:callback_preview, nil)
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
           :ok <- LiveAuth.authorize_action(socket, :preview_repair, %{type: :callback, id: id}),
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

    def handle_event("close_preview", _params, socket) do
      {:noreply,
       assign(socket,
         bulk_preview?: false,
         callback_preview: nil,
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
    def render(%{live_action: :show} = assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <%= if @batch_not_found? do %>
          <div class="rounded-lg border bg-white p-6">
            <h1 class="text-2xl font-semibold">Batch not found</h1>
            <p class="mt-2 text-sm text-zinc-600">
              Batch not found. It may have been pruned or the ID is invalid.
            </p>
            <.link navigate={Selectors.batches_path([{"status", "all"}])} class="mt-3 inline-flex text-indigo-700 underline">
              Back to Batches
            </.link>
          </div>
        <% else %>
          <div class="flex flex-wrap items-start justify-between gap-4">
            <div>
              <h1 class="text-2xl font-semibold">Batch <%= batch_name(@batch_detail) %></h1>
              <p class="mt-1 text-sm text-zinc-600">
                Native Powertools pages own audited mutations; generic job internals deep-link into the Oban Web bridge.
              </p>
            </div>
            <div class="flex items-center gap-3">
              <span class={"rounded border px-2 py-1 text-xs font-semibold " <> status_badge_class(@batch_detail.status)}>
                <%= @batch_detail.status %>
              </span>
              <.link navigate={@back_path} class="text-sm font-semibold text-indigo-700 underline">
                Back to Batches
              </.link>
            </div>
          </div>

          <p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            <%= LiveAuth.page_read_only_banner(:batch_detail) %>
          </p>

          <p :if={@success_message} class="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
            <%= @success_message %>
          </p>

          <div :if={@error_message && is_nil(@callback_preview) && !@bulk_preview?} class="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
            <%= @error_message %>
          </div>

          <section class="grid gap-6 xl:grid-cols-2">
            <div class="rounded-lg border bg-white p-4">
              <h2 class="text-base font-semibold">Identity</h2>
              <dl class="mt-3 grid gap-3 text-sm md:grid-cols-2">
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Batch ID</dt>
                  <dd class="break-all"><%= @batch_detail.id %></dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Name</dt>
                  <dd><%= @batch_detail.name || "Unnamed batch" %></dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Inserted Count</dt>
                  <dd><%= @batch_detail.progress.inserted_count %></dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Total Count</dt>
                  <dd><%= @batch_detail.progress.total_count %></dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Updated</dt>
                  <dd><%= timestamp_copy(@batch_detail.updated_at) %></dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Completed</dt>
                  <dd><%= timestamp_copy(@batch_detail.completed_at) %></dd>
                </div>
              </dl>
            </div>

            <div class="rounded-lg border bg-white p-4">
              <h2 class="text-base font-semibold">Progress</h2>
              <div class="mt-3 space-y-3 text-sm">
                <div class="flex justify-between">
                  <span>
                    <%= @batch_detail.progress.completed_count %> / <%= @batch_detail.progress.total_count %>
                  </span>
                  <span><%= @batch_detail.progress.percent %>%</span>
                </div>
                <div class="h-2 overflow-hidden rounded bg-slate-100">
                  <div class="h-2 bg-indigo-600" style={"width: #{progress_width(@batch_detail.progress.percent)}"}></div>
                </div>
                <p class="text-zinc-600"><%= @batch_detail.blocked_state.copy %></p>
              </div>
            </div>
          </section>

          <section class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Why this batch is blocked</h2>
            <div class="mt-3 rounded border bg-slate-50 p-3 text-sm">
              <div class="flex flex-wrap items-center gap-2">
                <span class={"rounded border px-2 py-1 text-xs font-semibold " <> severity_badge_class(@batch_detail.blocked_state.severity)}>
                  <%= @batch_detail.blocked_state.title %>
                </span>
                <span><%= @batch_detail.blocked_state.copy %></span>
              </div>
              <pre class="mt-3 overflow-x-auto rounded bg-white p-3 text-xs"><%= payload_copy(@batch_detail.blocked_state.evidence) %></pre>
            </div>
          </section>

          <section class="rounded-lg border bg-white p-4">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h2 class="text-base font-semibold">Failed Members</h2>
                <p class="mt-1 text-sm text-zinc-600">
                  Retryable selections are page-local and validated from current batch evidence.
                </p>
              </div>
              <div class="flex items-center gap-3">
                <button
                  :if={MapSet.size(@selected_failed_jobs) == 0}
                  type="button"
                  phx-click="preview_bulk_retry"
                  disabled={not @can_retry_batch_jobs? or MapSet.size(@selected_failed_jobs) == 0}
                  class={primary_button_class(@can_retry_batch_jobs? and MapSet.size(@selected_failed_jobs) > 0)}
                >
                  Retry Failed Jobs
                </button>
              </div>
            </div>

            <p :if={not @can_retry_batch_jobs?} class="mt-3 text-sm text-amber-700">
              Permission: read-only (:retry_batch_jobs). <%= LiveAuth.permission_message(:retry_batch_jobs) %>
            </p>

            <div :if={MapSet.size(@selected_failed_jobs) > 0} class="mt-4 flex items-center justify-between rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-3">
              <span class="text-sm font-semibold text-indigo-800"><%= MapSet.size(@selected_failed_jobs) %> failed jobs selected</span>
              <button
                type="button"
                phx-click="preview_bulk_retry"
                disabled={not @can_retry_batch_jobs?}
                class={primary_button_class(@can_retry_batch_jobs?)}
              >
                Retry Failed Jobs
              </button>
            </div>

            <%= if @batch_detail.failed_members == [] do %>
              <p class="mt-4 text-sm text-zinc-600">No failed members are currently recorded for this batch.</p>
            <% else %>
              <div class="mt-4 overflow-hidden rounded-lg border">
                <table class="min-w-full divide-y">
                  <thead class="bg-slate-50 text-left text-sm">
                    <tr>
                      <th class="w-10 px-4 py-3 font-semibold">
                        <input type="checkbox" phx-click="toggle_all_failed_jobs" class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" aria-label="Select all retry-eligible failed jobs" />
                      </th>
                      <th class="px-4 py-3 font-semibold">Job</th>
                      <th class="px-4 py-3 font-semibold">Worker</th>
                      <th class="px-4 py-3 font-semibold">Queue</th>
                      <th class="px-4 py-3 font-semibold">State</th>
                      <th class="px-4 py-3 font-semibold">Attempt</th>
                      <th class="px-4 py-3 font-semibold">Last Error</th>
                      <th class="px-4 py-3 font-semibold">Bridge</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y text-sm">
                    <tr :for={member <- @batch_detail.failed_members}>
                      <td class="px-4 py-3">
                        <input
                          type="checkbox"
                          checked={MapSet.member?(@selected_failed_jobs, member.job_id)}
                          disabled={not member.retry_eligible?}
                          phx-click="toggle_failed_job"
                          phx-value-id={member.job_id}
                          class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                          aria-label={"Select failed job #{member.job_id}"}
                        />
                      </td>
                      <td class="px-4 py-3"><%= member.job_id %></td>
                      <td class="px-4 py-3"><%= short_worker_name(member.worker) %></td>
                      <td class="px-4 py-3"><%= member.queue || "Unknown" %></td>
                      <td class="px-4 py-3">
                        <span class={"rounded border px-2 py-1 text-xs font-semibold " <> status_badge_class(member.oban_state || member.batch_member_state)}>
                          <%= member.oban_state || member.batch_member_state || "unknown" %>
                        </span>
                      </td>
                      <td class="px-4 py-3"><%= member.attempt || 0 %> / <%= member.max_attempts || "?" %></td>
                      <td class="px-4 py-3">
                        <pre class="max-w-xs whitespace-pre-wrap rounded bg-slate-50 p-2 text-xs"><%= display_copy(member.last_error_display) %></pre>
                      </td>
                      <td class="px-4 py-3">
                        <a href={member.bridge_path} class="text-indigo-700 underline">
                          Open Generic Job Inspection in Oban Web bridge
                        </a>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <% end %>
          </section>

          <section class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Callback Outbox</h2>
            <%= if @batch_detail.callbacks == [] do %>
              <p class="mt-3 text-sm text-zinc-600">No stuck or dead callbacks are blocking this batch.</p>
            <% else %>
              <div class="mt-4 overflow-hidden rounded-lg border">
                <table class="min-w-full divide-y">
                  <thead class="bg-slate-50 text-left text-sm">
                    <tr>
                      <th class="px-4 py-3 font-semibold">Event</th>
                      <th class="px-4 py-3 font-semibold">Status</th>
                      <th class="px-4 py-3 font-semibold">Attempts</th>
                      <th class="px-4 py-3 font-semibold">Lease</th>
                      <th class="px-4 py-3 font-semibold">Last Error</th>
                      <th class="px-4 py-3 font-semibold">Action</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y text-sm">
                    <tr :for={callback <- @batch_detail.callbacks}>
                      <td class="px-4 py-3">
                        <div class="font-semibold"><%= callback.event %></div>
                        <div class="text-xs text-zinc-500"><%= callback.dedupe_key %></div>
                      </td>
                      <td class="px-4 py-3">
                        <span class={"rounded border px-2 py-1 text-xs font-semibold " <> status_badge_class(callback.status)}>
                          <%= callback.status %>
                        </span>
                      </td>
                      <td class="px-4 py-3"><%= callback.attempts %></td>
                      <td class="px-4 py-3 text-xs text-zinc-600">
                        <div>Available: <%= timestamp_copy(callback.available_at) %></div>
                        <div>Claimed: <%= timestamp_copy(callback.claimed_at) %></div>
                        <div>Lease: <%= timestamp_copy(callback.lease_expires_at) %></div>
                        <div>Delivered: <%= timestamp_copy(callback.delivered_at) %></div>
                      </td>
                      <td class="px-4 py-3">
                        <pre class="max-w-xs whitespace-pre-wrap rounded bg-slate-50 p-2 text-xs"><%= display_copy(callback.last_error_display) %></pre>
                      </td>
                      <td class="px-4 py-3">
                        <%= if callback.retry_eligible? do %>
                          <button
                            type="button"
                            phx-click="preview_callback_retry"
                            phx-value-id={callback.id}
                            disabled={not callback_retry_allowed?(@callback_retry_permissions, callback.id)}
                            class={primary_button_class(callback_retry_allowed?(@callback_retry_permissions, callback.id))}
                          >
                            Preview Callback Retry
                          </button>
                          <p :if={not callback_retry_allowed?(@callback_retry_permissions, callback.id)} class="mt-2 text-xs text-amber-700">
                            Permission: read-only (:retry_callback). <%= LiveAuth.permission_message(:retry_callback) %>
                          </p>
                        <% else %>
                          <span class="text-xs text-zinc-500">Not retryable</span>
                        <% end %>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            <% end %>
          </section>

          <section class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Chain Context</h2>
            <%= if @batch_detail.chain_context.chain? do %>
              <dl class="mt-3 grid gap-3 text-sm md:grid-cols-2">
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Chain ID</dt>
                  <dd><%= @batch_detail.chain_context[:chain_id] %></dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Step</dt>
                  <dd>
                    <%= @batch_detail.chain_context[:chain_step_name] || "Unknown" %>
                    <%= if @batch_detail.chain_context[:chain_step_index] do %>
                      (<%= @batch_detail.chain_context[:chain_step_index] %>/<%= @batch_detail.chain_context[:chain_step_count] || "?" %>)
                    <% end %>
                  </dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Upstream Job</dt>
                  <dd><%= @batch_detail.chain_context[:upstream_job_id] || "Unknown" %></dd>
                </div>
                <div>
                  <dt class="text-xs font-semibold text-zinc-500">Next Step</dt>
                  <dd><%= @batch_detail.chain_context[:next_step] || "Unknown" %></dd>
                </div>
              </dl>
            <% else %>
              <p class="mt-3 text-sm text-zinc-600">No chain metadata is attached to this batch.</p>
            <% end %>
            <p :if={@batch_detail.blocked_state.name in [:output_unavailable, :output_expired]} class="mt-4 rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
              <%= @output_unavailable_copy %>
            </p>
          </section>

          <section class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Manual Intervention History</h2>
            <%= if @batch_detail.audit_events == [] do %>
              <p class="mt-3 text-sm text-zinc-600">No manual intervention audit evidence is recorded for this batch.</p>
            <% else %>
              <div class="mt-3 divide-y rounded border text-sm">
                <div :for={event <- @batch_detail.audit_events} class="p-3">
                  <div class="font-semibold"><%= ControlPlanePresenter.audit_event_label(event) %></div>
                  <div class="text-xs text-zinc-500">
                    <%= ControlPlanePresenter.audit_resource_label(event) %> · <%= timestamp_copy(event.inserted_at) %>
                  </div>
                </div>
              </div>
            <% end %>
          </section>
        <% end %>

        <%= if @bulk_preview? do %>
          <div class="fixed inset-0 z-50 flex items-center justify-center bg-zinc-900/50 p-4 backdrop-blur-sm">
            <div class="relative w-full max-w-2xl rounded-lg bg-white p-6 shadow-xl">
              <h2 class="text-base font-semibold">Retry Failed Jobs</h2>
              <p class="mt-2 text-sm text-zinc-600">
                Lifeline will preview each selected failed job before execution. Jobs that changed state before execution are skipped and reported.
              </p>
              <div class="mt-4 rounded bg-slate-50 p-4 text-sm">
                <div><strong>Affected records:</strong> <%= MapSet.size(@selected_failed_jobs) %> jobs</div>
                <div><strong>Audit consequence:</strong> <%= LiveAuth.audit_consequence_copy() %></div>
              </div>
              <form phx-change="reason" phx-submit="execute_bulk_retry" class="mt-4 space-y-4">
                <label class="block text-sm font-semibold text-zinc-700">Reason (required)</label>
                <input type="text" name="reason" value={@reason} placeholder="e.g., upstream outage resolved, safe to replay failed rows" class="w-full rounded-md border-gray-300 text-sm" />
                <div :if={@error_message} class="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-800">
                  <%= @error_message %>
                </div>
                <div class="flex justify-end gap-4">
                  <button type="button" phx-click="close_preview" class="text-sm font-semibold text-slate-600">Cancel</button>
                  <button type="submit" disabled={String.trim(@reason) == ""} class={primary_button_class(String.trim(@reason) != "")}>
                    Confirm Retry
                  </button>
                </div>
              </form>
            </div>
          </div>
        <% end %>

        <%= if @callback_preview do %>
          <div class="fixed inset-0 z-50 flex items-center justify-center bg-zinc-900/50 p-4 backdrop-blur-sm">
            <div class="relative w-full max-w-2xl rounded-lg bg-white p-6 shadow-xl">
              <h2 class="text-base font-semibold">Preview Callback Retry</h2>
              <div class="mt-4 grid gap-4 text-sm md:grid-cols-2">
                <div class="rounded bg-slate-50 p-4">
                  <div class="font-semibold">Before</div>
                  <pre class="mt-2 overflow-x-auto text-xs"><%= payload_copy(@callback_preview.before_snapshot) %></pre>
                </div>
                <div class="rounded bg-slate-50 p-4">
                  <div class="font-semibold">After</div>
                  <pre class="mt-2 overflow-x-auto text-xs"><%= payload_copy(@callback_preview.after_snapshot) %></pre>
                </div>
              </div>
              <div class="mt-4 rounded bg-slate-50 p-4 text-sm">
                <div><strong>Action:</strong> <%= @callback_preview.action %></div>
                <div><strong>Preview status:</strong> <%= @callback_preview.status %></div>
                <div><strong>Preview token:</strong> <%= @callback_preview.preview_token %></div>
                <div><strong>Audit consequence:</strong> <%= LiveAuth.audit_consequence_copy() %></div>
              </div>
              <form phx-change="reason" phx-submit="execute_callback_retry" class="mt-4 space-y-4">
                <label class="block text-sm font-semibold text-zinc-700">Reason (required)</label>
                <input type="text" name="reason" value={@reason} placeholder="e.g., upstream outage resolved, safe to retry callback" class="w-full rounded-md border-gray-300 text-sm" />
                <div :if={@error_message} class="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-800">
                  <%= @error_message %>
                </div>
                <div class="flex justify-end gap-4">
                  <button type="button" phx-click="close_preview" class="text-sm font-semibold text-slate-600">Cancel</button>
                  <button type="submit" disabled={String.trim(@reason) == ""} class={primary_button_class(String.trim(@reason) != "")}>
                    Retry Callback
                  </button>
                </div>
              </form>
            </div>
          </div>
        <% end %>
      </div>
      """
    end

    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Batches</h1>
          <p class="mt-1 text-sm text-zinc-600">
            Inspect batch and chain progress, failed members, blocked states, and Lifeline recovery paths. Native Powertools pages own audited mutations; generic job internals deep-link into the Oban Web bridge.
          </p>
          <p class="mt-1 text-xs text-zinc-500"><%= ControlPlanePresenter.native_banner() %></p>
        </div>

        <p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <%= LiveAuth.page_read_only_banner(:batches) %>
        </p>

        <p :if={@success_message} class="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
          <%= @success_message %>
        </p>

        <div :if={@load_error?} class="rounded-lg border border-red-200 bg-red-50 p-6">
          <h2 class="text-base font-semibold text-red-800">Could not load batch data.</h2>
          <p class="mt-2 text-sm text-red-700">
            Refresh the page; if this continues, verify the Powertools batch and callback migrations are installed.
          </p>
        </div>

        <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <div class="rounded-lg border bg-white p-4">
            <div class="text-xs font-semibold text-zinc-500">Total Batches</div>
            <div class="mt-2 text-2xl font-semibold"><%= @metrics.total %></div>
          </div>
          <div class="rounded-lg border bg-white p-4">
            <div class="text-xs font-semibold text-zinc-500">Needs Attention</div>
            <div class="mt-2 text-2xl font-semibold"><%= @metrics.needs_attention %></div>
          </div>
          <div class="rounded-lg border bg-white p-4">
            <div class="text-xs font-semibold text-zinc-500">Executing</div>
            <div class="mt-2 text-2xl font-semibold"><%= @metrics.executing %></div>
          </div>
          <div class="rounded-lg border bg-white p-4">
            <div class="text-xs font-semibold text-zinc-500">Completed</div>
            <div class="mt-2 text-2xl font-semibold"><%= @metrics.completed %></div>
          </div>
        </section>

        <nav class="flex flex-wrap gap-2">
          <button :for={status <- @valid_statuses} type="button" phx-click="select_status" phx-value-status={status} class={status_tab_class(to_string(@filter.status) == status)}>
            <%= status %> (<%= Map.get(@counts, status, 0) %>)
          </button>
        </nav>

        <form phx-change="filter">
          <div class="flex flex-wrap gap-4">
            <div>
              <label class="block text-sm font-semibold text-zinc-700">Batch name or ID</label>
              <input type="text" name="filter[query]" value={@filter.query || ""} placeholder="All batches" class="mt-1 rounded border px-3 py-2 text-sm" />
            </div>
            <div>
              <label class="block text-sm font-semibold text-zinc-700">Queue</label>
              <input type="text" name="filter[queue]" value={@filter.queue || ""} placeholder="All queues" class="mt-1 rounded border px-3 py-2 text-sm" />
            </div>
            <div>
              <label class="block text-sm font-semibold text-zinc-700">Worker</label>
              <input type="text" name="filter[worker]" value={@filter.worker || ""} placeholder="All workers" class="mt-1 rounded border px-3 py-2 text-sm" />
            </div>
            <label class="flex min-h-10 items-end gap-2 text-sm font-semibold text-zinc-700">
              <input type="hidden" name="filter[chain_only]" value="false" />
              <input type="checkbox" name="filter[chain_only]" value="true" checked={@filter.chain_only} class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
              Chain only
            </label>
          </div>
        </form>

        <%= if @batches == [] do %>
          <div class="rounded-lg border bg-white p-6">
            <h2 class="text-base font-semibold">No batches match this view</h2>
            <p class="mt-2 text-sm text-zinc-600">
              No batch rows match the selected status and filters. Try a different status, clear filters, or inspect Jobs for ungrouped work.
            </p>
          </div>
        <% else %>
          <div class="overflow-hidden rounded-lg border bg-white">
            <table class="min-w-full divide-y">
              <thead class="bg-slate-50 text-left text-sm">
                <tr>
                  <th class="px-4 py-3 font-semibold">Batch</th>
                  <th class="px-4 py-3 font-semibold">Status</th>
                  <th class="px-4 py-3 font-semibold">Progress</th>
                  <th class="px-4 py-3 font-semibold">Failed</th>
                  <th class="px-4 py-3 font-semibold">Callbacks</th>
                  <th class="px-4 py-3 font-semibold">Updated</th>
                  <th class="px-4 py-3 font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y text-sm">
                <tr :for={batch <- @batches}>
                  <td class="px-4 py-3">
                    <div class="font-semibold"><%= batch.name || batch.short_id %></div>
                    <div class="text-xs text-zinc-500"><%= batch.id %></div>
                    <span :if={batch.chain?} class="mt-2 inline-flex rounded border border-indigo-200 bg-indigo-50 px-2 py-1 text-xs font-semibold text-indigo-700">Chain</span>
                  </td>
                  <td class="px-4 py-3">
                    <span class={"rounded border px-2 py-1 text-xs font-semibold " <> status_badge_class(batch.status)}>
                      <%= batch.status %>
                    </span>
                    <div class="mt-2 text-xs text-zinc-600"><%= batch.blocked_state.title %></div>
                  </td>
                  <td class="px-4 py-3">
                    <div class="flex justify-between text-xs">
                      <span><%= batch.progress.completed_count %>/<%= batch.progress.total_count %></span>
                      <span><%= batch.progress.percent %>%</span>
                    </div>
                    <div class="mt-2 h-2 overflow-hidden rounded bg-slate-100">
                      <div class="h-2 bg-indigo-600" style={"width: #{progress_width(batch.progress.percent)}"}></div>
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <div><%= batch.failed_count %> failed</div>
                    <div class="text-xs text-zinc-500"><%= batch.retryable_failed_count %> retryable</div>
                  </td>
                  <td class="px-4 py-3 text-xs">
                    <div>pending <%= batch.callback_summary.pending %></div>
                    <div>failed <%= batch.callback_summary.failed %></div>
                    <div>claimed <%= batch.callback_summary.claimed %></div>
                    <div>delivered <%= batch.callback_summary.delivered %></div>
                  </td>
                  <td class="px-4 py-3"><%= timestamp_copy(batch.updated_at) %></td>
                  <td class="px-4 py-3">
                    <.link navigate={Selectors.batch_detail_path(batch.id)} class="text-indigo-700 underline">
                      Open Batch
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>

        <div class="flex gap-2">
          <%= if @filter.page <= 1 do %>
            <span class="cursor-not-allowed rounded border px-3 py-2 text-sm text-zinc-400">Previous</span>
          <% else %>
            <button type="button" phx-click="paginate" phx-value-page={@filter.page - 1} class="rounded border px-3 py-2 text-sm">Previous</button>
          <% end %>
          <%= if length(@batches) < @filter.page_size do %>
            <span class="cursor-not-allowed rounded border px-3 py-2 text-sm text-zinc-400">Next</span>
          <% else %>
            <button type="button" phx-click="paginate" phx-value-page={@filter.page + 1} class="rounded border px-3 py-2 text-sm">Next</button>
          <% end %>
        </div>
      </div>
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
      batches = Batches.list(repo(), filter)
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
      case Batches.get(repo(), batch_id) do
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

          socket
          |> assign(:batch_detail, detail)
          |> assign(:batch_not_found?, false)
          |> assign(:selected_failed_jobs, MapSet.new())
          |> assign(:bulk_preview?, false)
          |> assign(:callback_preview, nil)
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
        |> assign(:read_only?, true)
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

    defp status_tab_class(true),
      do:
        "rounded border border-indigo-300 bg-indigo-50 px-3 py-2 text-sm font-semibold text-indigo-700"

    defp status_tab_class(false),
      do:
        "rounded border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-600"

    defp primary_button_class(true),
      do:
        "rounded border border-indigo-600 bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-700"

    defp primary_button_class(false),
      do:
        "cursor-not-allowed rounded border border-slate-200 bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-400"

    defp status_badge_class("completed"), do: "border-emerald-200 bg-emerald-50 text-emerald-700"
    defp status_badge_class("delivered"), do: "border-emerald-200 bg-emerald-50 text-emerald-700"
    defp status_badge_class("executing"), do: "border-indigo-200 bg-indigo-50 text-indigo-700"
    defp status_badge_class("failed"), do: "border-red-200 bg-red-50 text-red-700"
    defp status_badge_class("discarded"), do: "border-red-200 bg-red-50 text-red-700"
    defp status_badge_class("callback_failed"), do: "border-amber-200 bg-amber-50 text-amber-700"
    defp status_badge_class("insert_failed"), do: "border-amber-200 bg-amber-50 text-amber-700"
    defp status_badge_class("exhausted"), do: "border-amber-200 bg-amber-50 text-amber-700"
    defp status_badge_class("claimed"), do: "border-slate-200 bg-slate-50 text-slate-700"
    defp status_badge_class("pending"), do: "border-slate-200 bg-slate-50 text-slate-700"
    defp status_badge_class(_status), do: "border-slate-200 bg-slate-50 text-slate-700"

    defp severity_badge_class(:success), do: "border-emerald-200 bg-emerald-50 text-emerald-700"
    defp severity_badge_class(:warning), do: "border-amber-200 bg-amber-50 text-amber-700"
    defp severity_badge_class(_severity), do: "border-slate-200 bg-slate-50 text-slate-700"

    defp progress_width(percent) when is_number(percent) do
      "#{percent |> max(0) |> min(100)}%"
    end

    defp progress_width(_percent), do: "0%"

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

    defp display_copy({:raw_json, json}), do: json
    defp display_copy({:string, text}), do: text
    defp display_copy({:fallback, text}), do: text
    defp display_copy(nil), do: ""
    defp display_copy(value) when is_binary(value), do: value
    defp display_copy(value), do: payload_copy(value)

    defp payload_copy(payload) when is_binary(payload), do: payload

    defp payload_copy(payload) do
      Jason.encode!(payload || %{}, pretty: true)
    rescue
      _ -> inspect(payload)
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
