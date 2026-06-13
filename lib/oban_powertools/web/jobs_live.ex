if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.JobsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{DisplayPolicy, JobRecord, Jobs, Lifeline}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

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
         |> assign_defaults()}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(%{"id" => id}, _uri, socket) do
      {:noreply, load_job_detail(socket, id)}
    end

    def handle_params(params, _uri, socket) do
      case {connected?(socket), Map.get(params, "state")} do
        {true, nil} ->
          # Live (connected) phase with no state param — redirect to default state.
          {:noreply, push_patch(socket, to: Selectors.jobs_path([{"state", "available"}]))}

        _ ->
          # Dead render (conn.params is %Plug.Conn.Unfetched{} regardless of URL query string),
          # or live phase with state param present — build filter and load jobs.
          filter = filter_from_params(params)
          {:noreply, load_jobs(socket, filter)}
      end
    end

    @impl true
    def handle_event("select_state", %{"state" => state}, socket) do
      if state in @valid_states do
        filter = socket.assigns.filter
        new_filter = %{filter | state: String.to_existing_atom(state), page: 1}

        {:noreply,
         socket
         |> assign(:selected_jobs, MapSet.new())
         |> push_patch(to: Selectors.jobs_path(filter_path(new_filter)))}
      else
        {:noreply, socket}
      end
    end

    def handle_event(
          "filter",
          %{"filter" => %{"queue" => q, "worker" => w, "tags" => tags_str}},
          socket
        ) do
      filter = socket.assigns.filter
      queue = if q == "", do: nil, else: q
      worker = if w == "", do: nil, else: w

      tags =
        case tags_str do
          nil -> nil
          "" -> nil
          str -> str |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
        end

      new_filter = %{filter | queue: queue, worker: worker, tags: tags, page: 1}

      {:noreply,
       socket
       |> assign(:selected_jobs, MapSet.new())
       |> push_patch(to: Selectors.jobs_path(filter_path(new_filter)))}
    end

    def handle_event("toggle_job", %{"id" => id_str}, socket) do
      case Integer.parse(id_str) do
        {id, ""} ->
          selected_jobs = socket.assigns.selected_jobs

          selected_jobs =
            if MapSet.member?(selected_jobs, id) do
              MapSet.delete(selected_jobs, id)
            else
              MapSet.put(selected_jobs, id)
            end

          {:noreply, assign(socket, :selected_jobs, selected_jobs)}

        _invalid ->
          {:noreply, socket}
      end
    end

    def handle_event("toggle_all", _, socket) do
      jobs = socket.assigns.jobs
      selected_jobs = socket.assigns.selected_jobs
      all_selected? = length(jobs) > 0 and Enum.all?(jobs, &(&1.id in selected_jobs))

      selected_jobs =
        if all_selected? do
          Enum.reduce(jobs, selected_jobs, &MapSet.delete(&2, &1.id))
        else
          Enum.reduce(jobs, selected_jobs, &MapSet.put(&2, &1.id))
        end

      {:noreply, assign(socket, :selected_jobs, selected_jobs)}
    end

    def handle_event("paginate", %{"page" => page_str}, socket) do
      case Integer.parse(page_str) do
        {page, ""} when page >= 1 ->
          filter = socket.assigns.filter
          new_filter = %{filter | page: page}
          {:noreply, push_patch(socket, to: Selectors.jobs_path(filter_path(new_filter)))}

        _ ->
          {:noreply, socket}
      end
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

        {successes, failures} =
          Enum.reduce(socket.assigns.selected_jobs, {0, 0}, fn job_id, {succ, fail} ->
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
          |> assign(:bulk_preview_action, nil)

        {:noreply, load_jobs(socket, socket.assigns.filter)}
      end
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
                  <span class={"rounded border px-2 py-1 text-xs font-semibold " <> state_badge_class(@job.state)}>
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
          <div class="fixed inset-0 bg-zinc-900/50 backdrop-blur-sm z-50 flex items-center justify-center">
            <div class="relative bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
              <h2 class="text-base font-semibold">
                <%= case @preview.action do %>
                  <% "job_retry" -> %> Retry Job #<%= @job.id %>
                  <% "job_cancel" -> %> Cancel Job #<%= @job.id %>
                  <% "job_discard" -> %> Discard Job #<%= @job.id %>
                <% end %>
              </h2>

              <div class="mt-4 rounded bg-slate-50 p-4 text-sm space-y-1">
                <div><strong>Job ID:</strong> <%= @job.id %></div>
                <div><strong>Current State:</strong> <%= @job.state %></div>
                <div><strong>Action:</strong> <%= @preview.action %></div>
              </div>

              <form phx-change="reason" phx-submit="execute" class="mt-4 space-y-4">
                <label class="block text-sm font-semibold text-zinc-700">Reason (required)</label>
                <input type="text" name="reason" value={@reason} placeholder="e.g., Network timeout, operator intervention..." class="w-full rounded-md border-gray-300 text-sm" />

                <div :if={@error_message} class="mt-4 rounded bg-red-50 p-4 text-sm text-red-800 border border-red-200">
                  <%= @error_message %>
                </div>

                <div class="mt-6 flex justify-end gap-4">
                  <button type="button" phx-click="close_preview" class="text-sm font-semibold text-slate-600">Keep Job</button>
                  <button type="submit" disabled={String.trim(@reason) == ""} class={"rounded px-4 py-2 text-sm font-semibold text-white " <> if(@preview.action == "job_retry", do: "bg-indigo-600 hover:bg-indigo-700", else: "bg-red-600 hover:bg-red-700")}>
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

    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Jobs</h1>
          <p class="text-sm text-zinc-600">
            Browse and inspect Oban jobs by state. <%= ControlPlanePresenter.native_banner() %>
          </p>
        </div>

        <p :if={@read_only?} class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <%= LiveAuth.page_read_only_banner(:jobs) %>
        </p>

        <%= if MapSet.size(@selected_jobs) > 0 do %>
          <div class="flex items-center justify-between rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-3">
            <span class="text-sm font-semibold text-indigo-800"><%= MapSet.size(@selected_jobs) %> jobs selected</span>
            <div class="flex gap-2">
              <%= if not @read_only? do %>
                <button :if={to_string(@filter.state) in ["retryable", "cancelled", "discarded", "completed"]} phx-click="preview_bulk" phx-value-action="job_retry" class="rounded bg-white px-4 py-2 text-sm font-semibold text-indigo-600 border border-indigo-200 hover:bg-indigo-50">Retry</button>
                <button :if={to_string(@filter.state) in ["available", "scheduled", "executing", "retryable"]} phx-click="preview_bulk" phx-value-action="job_cancel" class="rounded bg-white px-4 py-2 text-sm font-semibold text-red-600 border border-red-200 hover:bg-red-50">Cancel</button>
                <button :if={to_string(@filter.state) in ["available", "scheduled", "executing", "retryable"]} phx-click="preview_bulk" phx-value-action="job_discard" class="rounded bg-white px-4 py-2 text-sm font-semibold text-red-600 border border-red-200 hover:bg-red-50">Discard</button>
              <% end %>
            </div>
          </div>
        <% end %>

        <nav class="flex flex-wrap gap-2">
          <%= for state <- ~w(available scheduled executing retryable cancelled discarded completed) do %>
            <button
              phx-click="select_state"
              phx-value-state={state}
              class={state_tab_class(to_string(@filter.state) == state)}
            >
              <%= state %> (<%= Map.get(@counts, state, 0) %>)
            </button>
          <% end %>
        </nav>

        <form phx-change="filter">
          <div class="flex flex-wrap gap-4">
            <div>
              <label class="block text-sm font-semibold text-zinc-700">Queue</label>
              <input
                type="text"
                name="filter[queue]"
                value={@filter.queue || ""}
                placeholder="All queues"
                class="mt-1 rounded border px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label class="block text-sm font-semibold text-zinc-700">Worker</label>
              <input
                type="text"
                name="filter[worker]"
                value={@filter.worker || ""}
                placeholder="All workers"
                class="mt-1 rounded border px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label class="block text-sm font-semibold text-zinc-700">Tags</label>
              <input
                type="text"
                name="filter[tags]"
                value={if @filter.tags, do: Enum.join(@filter.tags, ","), else: ""}
                placeholder="Any tag"
                class="mt-1 rounded border px-3 py-2 text-sm"
              />
            </div>
          </div>
        </form>

        <%= if @jobs == [] do %>
          <div class="rounded-lg border bg-white p-6">
            <h2 class="text-base font-semibold">No <%= @filter.state %> jobs</h2>
            <p class="mt-2 text-sm text-zinc-600">
              No jobs are currently in the <%= @filter.state %> state. Try a different state or filter.
            </p>
          </div>
        <% else %>
          <div class="overflow-hidden rounded-lg border bg-white">
            <table class="min-w-full divide-y">
              <thead class="bg-slate-50 text-left text-sm">
                <tr>
                  <th class="px-4 py-3 font-semibold w-10">
                    <input type="checkbox" checked={length(@jobs) > 0 and Enum.all?(@jobs, &(&1.id in @selected_jobs))} phx-click="toggle_all" class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
                  </th>
                  <th class="px-4 py-3 font-semibold">State</th>
                  <th class="px-4 py-3 font-semibold">Worker</th>
                  <th class="px-4 py-3 font-semibold">Queue</th>
                  <th class="px-4 py-3 font-semibold">Job ID</th>
                  <th class="px-4 py-3 font-semibold">Scheduled At</th>
                  <th class="px-4 py-3 font-semibold">Attempts</th>
                </tr>
              </thead>
              <tbody class="divide-y text-sm">
                <tr :for={job <- @jobs}>
                  <td class="px-4 py-3">
                    <input type="checkbox" checked={job.id in @selected_jobs} phx-click="toggle_job" phx-value-id={job.id} class="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500" />
                  </td>
                  <td class="px-4 py-3">
                    <span class={"rounded border px-2 py-1 text-xs font-semibold " <> state_badge_class(job.state)}>
                      <%= job.state %>
                    </span>
                  </td>
                  <td class="px-4 py-3">
                    <.link navigate={Selectors.job_detail_path(job.id)} class="text-indigo-700 underline">
                      <%= short_worker_name(job.worker) %>
                    </.link>
                  </td>
                  <td class="px-4 py-3"><%= job.queue %></td>
                  <td class="px-4 py-3"><%= job.id %></td>
                  <td class="px-4 py-3"><%= timestamp_copy(job.scheduled_at) %></td>
                  <td class="px-4 py-3"><%= job.attempt %> / <%= job.max_attempts %></td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>

        <div class="flex gap-2">
          <%= if @filter.page <= 1 do %>
            <span class="cursor-not-allowed rounded border px-3 py-2 text-sm text-zinc-400">Previous</span>
          <% else %>
            <button
              phx-click="paginate"
              phx-value-page={@filter.page - 1}
              class="rounded border px-3 py-2 text-sm"
            >
              Previous
            </button>
          <% end %>
          <%= if length(@jobs) < @filter.page_size do %>
            <span class="cursor-not-allowed rounded border px-3 py-2 text-sm text-zinc-400">Next</span>
          <% else %>
            <button
              phx-click="paginate"
              phx-value-page={@filter.page + 1}
              class="rounded border px-3 py-2 text-sm"
            >
              Next
            </button>
          <% end %>
        </div>

        <%!-- Bulk Action Preview Modal --%>
        <%= if @bulk_preview_action do %>
          <div class="fixed inset-0 bg-zinc-900/50 backdrop-blur-sm z-50 flex items-center justify-center">
            <div class="relative bg-white rounded-lg shadow-xl p-6 w-full max-w-md">
              <h2 class="text-base font-semibold">
                <%= case @bulk_preview_action do %>
                  <% "job_retry" -> %> Bulk Retry <%= MapSet.size(@selected_jobs) %> Jobs
                  <% "job_cancel" -> %> Bulk Cancel <%= MapSet.size(@selected_jobs) %> Jobs
                  <% "job_discard" -> %> Bulk Discard <%= MapSet.size(@selected_jobs) %> Jobs
                <% end %>
              </h2>

              <p class="mt-2 text-sm text-zinc-600">
                You are about to <%= case @bulk_preview_action do %><% "job_retry" -> %>retry<% "job_cancel" -> %>cancel<% "job_discard" -> %>discard<% end %> <%= MapSet.size(@selected_jobs) %> jobs. This will execute independent repairs for each job.
              </p>

              <form phx-change="reason" phx-submit="execute_bulk" class="mt-4 space-y-4">
                <label class="block text-sm font-semibold text-zinc-700">Reason (required)</label>
                <input type="text" name="reason" value={@reason} placeholder="e.g., Network timeout, operator intervention..." class="w-full rounded-md border-gray-300 text-sm" />

                <div :if={@error_message} class="mt-4 rounded bg-red-50 p-4 text-sm text-red-800 border border-red-200">
                  <%= @error_message %>
                </div>

                <div class="mt-6 flex justify-end gap-4">
                  <button type="button" phx-click="close_preview" class="text-sm font-semibold text-slate-600">Cancel</button>
                  <button type="submit" disabled={String.trim(@reason) == ""} class={"rounded px-4 py-2 text-sm font-semibold text-white " <> if(@bulk_preview_action == "job_retry", do: "bg-indigo-600 hover:bg-indigo-700", else: "bg-red-600 hover:bg-red-700")}>
                    <%= case @bulk_preview_action do %>
                      <% "job_retry" -> %> Confirm Bulk Retry
                      <% "job_cancel" -> %> Confirm Bulk Cancel
                      <% "job_discard" -> %> Confirm Bulk Discard
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
          {"tags", if(filter.tags, do: Enum.join(filter.tags, ","))}
        ])
      else
        Selectors.jobs_path([])
      end
    end

    defp assign_defaults(socket) do
      socket
      |> assign(:jobs, [])
      |> assign(:filter, %Jobs{})
      |> assign(:counts, Map.new(@valid_states, &{&1, 0}))
      |> assign(:job, nil)
      |> assign(:job_not_found?, false)
      |> assign(:args_display, nil)
      |> assign(:meta_display, nil)
      |> assign(:redacted_fields, [])
      |> assign(:preview, nil)
      |> assign(:bulk_preview_action, nil)
      |> assign(:selected_jobs, MapSet.new())
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

    defp load_jobs(socket, filter) do
      jobs = Jobs.list(repo(), filter)
      counts = Jobs.count_by_state(repo(), filter)

      socket
      |> assign(:jobs, jobs)
      |> assign(:counts, counts)
      |> assign(:filter, filter)
      |> assign_read_only()
    end

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

    defp filter_from_params(params) do
      tags =
        case Map.get(params, "tags") do
          nil -> nil
          "" -> nil
          str -> str |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
        end

      state_str = Map.get(params, "state", "available")

      state =
        if state_str in @valid_states do
          String.to_existing_atom(state_str)
        else
          :available
        end

      page =
        case Integer.parse(Map.get(params, "page", "1")) do
          {p, ""} when p >= 1 -> p
          _ -> 1
        end

      %Jobs{
        state: state,
        queue: Map.get(params, "queue"),
        worker: Map.get(params, "worker"),
        tags: tags,
        page: page,
        page_size: %Jobs{}.page_size
      }
    end

    defp filter_path(filter) do
      [
        {"state", to_string(filter.state)},
        {"queue", filter.queue},
        {"worker", filter.worker},
        {"tags", if(filter.tags, do: Enum.join(filter.tags, ","))},
        {"page", if(filter.page > 1, do: to_string(filter.page))}
      ]
    end

    defp state_tab_class(true),
      do:
        "rounded border border-indigo-300 bg-indigo-50 px-3 py-2 text-sm font-semibold text-indigo-700"

    defp state_tab_class(false),
      do:
        "rounded border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-600"

    defp state_badge_class("available"), do: "border-slate-200 bg-slate-50 text-slate-700"
    defp state_badge_class("scheduled"), do: "border-slate-200 bg-slate-50 text-slate-700"
    defp state_badge_class("executing"), do: "border-indigo-200 bg-indigo-50 text-indigo-700"
    defp state_badge_class("retryable"), do: "border-amber-200 bg-amber-50 text-amber-700"
    defp state_badge_class("cancelled"), do: "border-slate-200 bg-slate-50 text-slate-500"
    defp state_badge_class("discarded"), do: "border-red-200 bg-red-50 text-red-700"
    defp state_badge_class("completed"), do: "border-emerald-200 bg-emerald-50 text-emerald-700"
    defp state_badge_class(_), do: "border-slate-200 bg-slate-50 text-slate-700"

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
