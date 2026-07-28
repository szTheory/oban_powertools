if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.JobsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{DisplayPolicy, JobRecord, Jobs, Lifeline}
    alias ObanPowertools.Web.Components.{DataDisplay, Forms, OperatorPatterns, Primitives}
    alias ObanPowertools.Web.{ControlPlanePresenter, JobsParams, LiveAuth, Selectors}

    @valid_states ~w(available scheduled executing retryable cancelled discarded completed)
    @allowed_preview_actions ~w(job_retry job_cancel job_discard)

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
    def handle_params(%{"id" => id}, _uri, socket) do
      {:noreply, load_job_detail(socket, id)}
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

    def handle_event("preview", %{"action" => action}, socket)
        when action in @allowed_preview_actions do
      with :ok <-
             LiveAuth.authorize_action(socket, :preview_repair, %{
               type: :job,
               id: to_string(socket.assigns.job.id)
             }),
           {:ok, preview} <-
             Lifeline.preview_repair(repo(), socket.assigns.current_actor, %{
               incident_id: nil,
               action: action,
               target_type: "job",
               target_id: socket.assigns.job.id
             }) do
        {:noreply,
         socket
         |> assign(:preview, preview)
         |> assign(:reason, "")
         |> assign(:error_message, nil)}
      else
        {:error, :unauthorized} -> {:noreply, socket}
        {:error, msg} -> {:noreply, assign(socket, :error_message, to_string(msg))}
      end
    end

    def handle_event("preview", _, socket), do: {:noreply, socket}

    def handle_event("preview_bulk", %{"action" => action}, socket) do
      {:noreply,
       socket
       |> assign(:bulk_preview_action, action)
       |> assign(:reason, "")
       |> assign(:error_message, nil)}
    end

    def handle_event("close_preview", _, socket) do
      {:noreply,
       assign(socket, preview: nil, bulk_preview_action: nil, reason: "", error_message: nil)}
    end

    def handle_event("reason", %{"reason" => r}, socket) do
      {:noreply, assign(socket, :reason, r)}
    end

    def handle_event("execute", params, socket) do
      reason_from_params = Map.get(params, "reason")
      reason = String.trim(reason_from_params || socket.assigns.reason)

      if reason == "" do
        {:noreply, socket}
      else
        with :ok <-
               LiveAuth.authorize_action(socket, :execute_repair, %{
                 type: :job,
                 id: to_string(socket.assigns.job.id)
               }),
             {:ok, %{target: target}} <-
               Lifeline.execute_repair(
                 repo(),
                 socket.assigns.current_actor,
                 socket.assigns.preview.preview_token,
                 reason
               ) do
          socket =
            socket
            |> put_flash(
              :info,
              "Job ##{target.id} successfully " <>
                action_word(socket.assigns.preview.action) <> "."
            )
            |> push_patch(to: Selectors.job_detail_path(target.id))

          {:noreply, load_job_detail(socket, target.id)}
        else
          {:error, :unauthorized} ->
            {:noreply, socket}

          {:error, :preview_drifted} ->
            {:noreply,
             assign(
               socket,
               :error_message,
               "Could not execute action. The job's state was changed by another process or operator. Please refresh to see the latest state."
             )}

          {:error, reason} ->
            {:noreply, assign(socket, :error_message, "Error: #{inspect(reason)}")}
        end
      end
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

    defp action_word("job_retry"), do: "retried"
    defp action_word("job_cancel"), do: "cancelled"
    defp action_word("job_discard"), do: "discarded"
    defp action_word(action), do: action

    @impl true
    def render(%{live_action: :show} = assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <%= if @job_not_found? do %>
          <div class="rounded-lg border bg-white p-6">
            <h1 class="text-2xl font-semibold">Job not found</h1>
            <p class="mt-2 text-sm text-zinc-600">
              Job not found. It may have been pruned or the ID is invalid. Return to the job list.
            </p>
            <.link navigate={Selectors.jobs_path([])} class="mt-3 inline-flex text-indigo-700 underline">
              Back to Jobs
            </.link>
          </div>
        <% else %>
          <div class="flex flex-wrap items-start justify-between gap-4">
            <h1 class="text-2xl font-semibold">Job #<%= @job.id %></h1>
            <div class="flex gap-2 items-center">
              <%= if not @read_only? do %>
                <button :if={@job.state in ["retryable", "discarded", "cancelled", "completed"]} phx-click="preview" phx-value-action="job_retry" class="rounded bg-white px-4 py-2 text-sm font-semibold text-indigo-600 border border-indigo-200 hover:bg-indigo-50">Retry Job</button>
                <button :if={@job.state in ["available", "scheduled", "executing", "retryable"]} phx-click="preview" phx-value-action="job_cancel" class="rounded bg-white px-4 py-2 text-sm font-semibold text-red-600 border border-red-200 hover:bg-red-50">Cancel Job</button>
                <button :if={@job.state in ["available", "scheduled", "executing", "retryable"]} phx-click="preview" phx-value-action="job_discard" class="rounded bg-white px-4 py-2 text-sm font-semibold text-red-600 border border-red-200 hover:bg-red-50">Discard Job</button>
              <% end %>
              <.link navigate={@back_path} class="text-indigo-700 underline">Back to Jobs</.link>
            </div>
          </div>

          <p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            <%= LiveAuth.page_read_only_banner(:job_detail) %>
          </p>

          <%!-- Identity card --%>
          <div class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Identity</h2>
            <dl class="mt-3 space-y-2 text-sm">
              <div class="flex gap-4">
                <dt class="w-36 text-zinc-500">Worker</dt>
                <dd><%= short_worker_name(@job.worker) %></dd>
              </div>
              <div class="flex gap-4">
                <dt class="w-36 text-zinc-500">Queue</dt>
                <dd><%= @job.queue %></dd>
              </div>
              <div class="flex gap-4">
                <dt class="w-36 text-zinc-500">State</dt>
                <dd>
                  <span class="obpt-badge" data-obpt-tone={state_badge_tone(@job.state)}>
                    <%= @job.state %>
                  </span>
                </dd>
              </div>
              <div class="flex gap-4">
                <dt class="w-36 text-zinc-500">Job ID</dt>
                <dd><%= @job.id %></dd>
              </div>
              <div class="flex gap-4">
                <dt class="w-36 text-zinc-500">Attempt</dt>
                <dd><%= @job.attempt %> / <%= @job.max_attempts %></dd>
              </div>
              <%!-- Timing fields — only non-nil are rendered per D-14 --%>
              <div :if={@job.inserted_at} class="flex gap-4">
                <dt class="w-36 text-zinc-500">Inserted At</dt>
                <dd><%= timestamp_copy(@job.inserted_at) %></dd>
              </div>
              <div :if={@job.scheduled_at} class="flex gap-4">
                <dt class="w-36 text-zinc-500">Scheduled At</dt>
                <dd><%= timestamp_copy(@job.scheduled_at) %></dd>
              </div>
              <div :if={@job.attempted_at} class="flex gap-4">
                <dt class="w-36 text-zinc-500">Attempted At</dt>
                <dd><%= timestamp_copy(@job.attempted_at) %></dd>
              </div>
              <div :if={@job.completed_at} class="flex gap-4">
                <dt class="w-36 text-zinc-500">Completed At</dt>
                <dd><%= timestamp_copy(@job.completed_at) %></dd>
              </div>
              <div :if={@job.cancelled_at} class="flex gap-4">
                <dt class="w-36 text-zinc-500">Cancelled At</dt>
                <dd><%= timestamp_copy(@job.cancelled_at) %></dd>
              </div>
              <div :if={@job.discarded_at} class="flex gap-4">
                <dt class="w-36 text-zinc-500">Discarded At</dt>
                <dd><%= timestamp_copy(@job.discarded_at) %></dd>
              </div>
            </dl>
          </div>

          <%!-- Args / Meta panels — side-by-side on xl per UI-SPEC --%>
          <div class="grid gap-6 xl:grid-cols-2">
            <div class="rounded-lg border bg-white p-4">
              <h2 class="text-base font-semibold">Args</h2>
              <div class="mt-3">
                <%= case @args_display do %>
                  <% {:raw_json, json} -> %>
                    <pre class="text-sm bg-slate-50 p-3 rounded overflow-x-auto"><%= json %></pre>
                  <% {:string, text} -> %>
                    <pre class="text-sm bg-slate-50 p-3 rounded overflow-x-auto"><%= text %></pre>
                  <% {:fallback, msg} -> %>
                    <span class="text-zinc-500"><%= msg %></span>
                <% end %>
              </div>
            </div>

            <div class="rounded-lg border bg-white p-4">
              <h2 class="text-base font-semibold">Meta</h2>
              <div class="mt-3">
                <%= case @meta_display do %>
                  <% {:raw_json, json} -> %>
                    <pre class="text-sm bg-slate-50 p-3 rounded overflow-x-auto"><%= json %></pre>
                  <% {:string, text} -> %>
                    <pre class="text-sm bg-slate-50 p-3 rounded overflow-x-auto"><%= text %></pre>
                  <% {:fallback, msg} -> %>
                    <span class="text-zinc-500"><%= msg %></span>
                <% end %>
              </div>
            </div>
          </div>

          <%!-- Redaction disclosure — shown near Meta card when __redacted_fields__ present (REDACT-03, D-13) --%>
          <%= if @redacted_fields != [] do %>
            <div class="rounded-lg border bg-white p-4">
              <p class="text-xs font-semibold text-zinc-500">
                Fields redacted at enqueue:
                <%= Enum.map(@redacted_fields, &":#{&1}") |> Enum.join(", ") %>
              </p>
            </div>
          <% end %>

          <%!-- Recorded output panel --%>
          <div class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Recorded Output</h2>
            <%= if @recorded_output.available? do %>
              <dl class="mt-3 grid gap-3 text-sm md:grid-cols-2">
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Availability</dt>
                  <dd>Available</dd>
                </div>
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Summary</dt>
                  <dd><%= @recorded_output.summary %></dd>
                </div>
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Status</dt>
                  <dd><%= @recorded_output.status || "Unknown" %></dd>
                </div>
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Attempt</dt>
                  <dd><%= @recorded_output.attempt || "Unknown" %></dd>
                </div>
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Payload Bytes</dt>
                  <dd><%= @recorded_output.payload_bytes || "Unknown" %></dd>
                </div>
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Recorded At</dt>
                  <dd><%= timestamp_copy(@recorded_output.recorded_at) %></dd>
                </div>
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Retention</dt>
                  <dd><%= @recorded_output.retention || "Unknown" %></dd>
                </div>
                <div class="flex gap-4">
                  <dt class="w-36 text-zinc-500">Expires At</dt>
                  <dd><%= timestamp_copy(@recorded_output.expires_at) %></dd>
                </div>
                <div class="flex gap-4 md:col-span-2">
                  <dt class="w-36 text-zinc-500">Redacted Metadata</dt>
                  <dd><%= if @recorded_output.redacted?, do: "Stored redaction metadata present", else: "None" %></dd>
                </div>
              </dl>
              <div class="mt-4">
                <h3 class="text-sm font-semibold text-zinc-700">Payload</h3>
                <pre class="mt-2 text-sm bg-slate-50 p-3 rounded overflow-x-auto"><%= payload_copy(@recorded_output.payload) %></pre>
              </div>
            <% else %>
              <p class="mt-3 text-sm text-zinc-600">No recorded output found for this job.</p>
            <% end %>
          </div>

          <%!-- Errors panel --%>
          <div class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Errors</h2>
            <%= if (@job.errors || []) == [] do %>
              <p class="mt-3 text-sm text-zinc-600">No errors recorded for this job.</p>
            <% else %>
              <div class="mt-3 space-y-3">
                <div :for={err <- @job.errors || []} class="rounded border bg-slate-50 p-3 text-sm space-y-1">
                  <div><span class="font-semibold">Attempt <%= err["attempt"] %></span></div>
                  <div class="text-zinc-500"><%= timestamp_copy(err["at"]) %></div>
                  <pre class="text-sm whitespace-pre-wrap"><%= err["error"] %></pre>
                </div>
              </div>
            <% end %>
          </div>

          <%!-- Attempt history panel --%>
          <div class="rounded-lg border bg-white p-4">
            <h2 class="text-base font-semibold">Attempt History</h2>
            <%= if @job.attempt == 0 and (@job.errors || []) == [] do %>
              <p class="mt-3 text-sm text-zinc-600">No attempt history available.</p>
            <% else %>
              <div class="mt-3 space-y-2 text-sm">
                <%= for attempt_num <- 1..max(@job.attempt, length(@job.errors || [])) do %>
                  <% err = Enum.find(@job.errors || [], &(&1["attempt"] == attempt_num)) %>
                  <div class="flex gap-4">
                    <span class="w-24 text-zinc-500">Attempt <%= attempt_num %></span>
                    <span><%= if err, do: timestamp_copy(err["at"]), else: "In progress" %></span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>

        <%!-- Action Preview Modal --%>
        <%= if @preview do %>
          <div class="obpt-modal-backdrop">
            <div class="obpt-modal">
              <h2 class="text-base font-semibold">
                <%= case @preview.action do %>
                  <% "job_retry" -> %> Retry Job #<%= @job.id %>
                  <% "job_cancel" -> %> Cancel Job #<%= @job.id %>
                  <% "job_discard" -> %> Discard Job #<%= @job.id %>
                <% end %>
              </h2>

              <div class="obpt-modal-summary">
                <div><strong>Job ID:</strong> <%= @job.id %></div>
                <div><strong>Current State:</strong> <%= @job.state %></div>
                <div><strong>Action:</strong> <%= @preview.action %></div>
              </div>

              <form phx-change="reason" phx-submit="execute" class="mt-4 space-y-4">
                <label class="obpt-form-label">Reason (required)</label>
                <input type="text" name="reason" value={@reason} placeholder="e.g., Network timeout, operator intervention..." class="obpt-input" />

                <div :if={@error_message} class="obpt-alert obpt-alert--danger">
                  <%= @error_message %>
                </div>

                <div class="mt-6 flex justify-end gap-4">
                  <button type="button" phx-click="close_preview" class="obpt-button obpt-button--neutral">Keep Job</button>
                  <button type="submit" disabled={String.trim(@reason) == ""} class={preview_confirm_button_class(@preview.action)}>
                    <%= case @preview.action do %>
                      <% "job_retry" -> %> Confirm Retry
                      <% "job_cancel" -> %> Confirm Cancel
                      <% "job_discard" -> %> Confirm Discard
                    <% end %>
                  </button>
                </div>
              </form>
            </div>
          </div>
        <% end %>
      </div>
      """
    end

    def render(assigns), do: page_content(assigns)

    attr(:rows, :list, default: [])
    attr(:counts, :map, required: true)
    attr(:filter, :any, required: true)
    attr(:filter_form, Phoenix.HTML.Form, required: true)
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

    # --- Private helpers ---

    defp load_job_detail(socket, job_id) do
      case Jobs.get(repo(), job_id) do
        nil ->
          socket
          |> assign(:job, nil)
          |> assign(:job_not_found?, true)
          |> assign(:args_display, nil)
          |> assign(:meta_display, nil)
          |> assign(:recorded_output, DisplayPolicy.render_job_field(:job_recorded, nil, %{}))
          |> assign(:redacted_fields, [])
          |> assign(:back_path, Selectors.jobs_path([]))

        %Oban.Job{} = job ->
          args_display = DisplayPolicy.render_job_field(:job_args, job.args, %{job: job})
          meta_display = DisplayPolicy.render_job_field(:job_meta, job.meta, %{job: job})
          recorded_output = recorded_output_display(job)
          redacted_fields = get_in(job.meta || %{}, ["__redacted_fields__"]) || []

          socket
          |> assign(:job, job)
          |> assign(:job_not_found?, false)
          |> assign(:args_display, args_display)
          |> assign(:meta_display, meta_display)
          |> assign(:recorded_output, recorded_output)
          |> assign(:redacted_fields, redacted_fields)
          |> assign(:preview, nil)
          |> assign(:reason, "")
          |> assign(:error_message, nil)
          |> assign(:success_message, nil)
          |> assign(:back_path, back_path_from_session(socket))
          |> assign(
            :read_only?,
            not LiveAuth.authorized?(
              Map.get(socket.assigns, :current_actor),
              :retry_job,
              %{type: :job, id: to_string(job.id)}
            )
          )
      end
    end

    defp recorded_output_display(%Oban.Job{} = job) do
      context = %{surface: :jobs, field: :recorded, job: job}

      case JobRecord.fetch_result(repo(), job.id) do
        {:ok, _payload} ->
          case JobRecord.fetch_record(repo(), job.id) do
            {:ok, record} -> DisplayPolicy.render_job_field(:job_recorded, record, context)
            {:error, :not_found} -> DisplayPolicy.render_job_field(:job_recorded, nil, context)
          end

        {:error, :not_found} ->
          DisplayPolicy.render_job_field(:job_recorded, nil, context)
      end
    end

    defp back_path_from_session(socket) do
      filter = Map.get(socket.assigns, :filter)

      if filter do
        Selectors.jobs_path([
          {"state", to_string(filter.state)},
          {"queue", filter.queue},
          {"worker", filter.worker},
          {"tags", if(filter.tags, do: Enum.join(filter.tags, ","))},
          {"args", if(filter.args, do: Jason.encode!(filter.args))},
          {"meta", if(filter.meta, do: Jason.encode!(filter.meta))}
        ])
      else
        Selectors.jobs_path([])
      end
    end

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
      |> assign(:job, nil)
      |> assign(:job_not_found?, false)
      |> assign(:args_display, nil)
      |> assign(:meta_display, nil)
      |> assign(:redacted_fields, [])
      |> assign(:preview, nil)
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

    defp state_badge_tone("executing"), do: "info"
    defp state_badge_tone("retryable"), do: "warning"
    defp state_badge_tone("discarded"), do: "danger"
    defp state_badge_tone("completed"), do: "success"
    defp state_badge_tone(_), do: "neutral"

    defp preview_confirm_button_class("job_retry"), do: "obpt-button obpt-button--primary"
    defp preview_confirm_button_class(_), do: "obpt-button obpt-button--danger"

    defp short_worker_name(worker) when is_binary(worker),
      do: worker |> String.split(".") |> List.last()

    defp short_worker_name(nil), do: "—"

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

    defp payload_copy(payload) when is_binary(payload), do: payload

    defp payload_copy(payload) do
      Jason.encode!(payload || %{}, pretty: true)
    rescue
      _ -> inspect(payload)
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
