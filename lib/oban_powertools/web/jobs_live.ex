if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.JobsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.{DisplayPolicy, Jobs}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

    @valid_states ~w(available scheduled executing retryable cancelled discarded completed)

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

        {:noreply, push_patch(socket, to: Selectors.jobs_path(filter_path(new_filter)))}
      else
        {:noreply, socket}
      end
    end

    def handle_event("filter", %{"filter" => %{"queue" => q, "worker" => w, "tags" => tags_str}}, socket) do
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
      {:noreply, push_patch(socket, to: Selectors.jobs_path(filter_path(new_filter)))}
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
            <.link navigate={@back_path} class="text-indigo-700 underline">Back to Jobs</.link>
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
          |> assign(:back_path, Selectors.jobs_path([]))

        %Oban.Job{} = job ->
          args_display = DisplayPolicy.render_job_field(:job_args, job.args, %{job: job})
          meta_display = DisplayPolicy.render_job_field(:job_meta, job.meta, %{job: job})

          socket
          |> assign(:job, job)
          |> assign(:job_not_found?, false)
          |> assign(:args_display, args_display)
          |> assign(:meta_display, meta_display)
          |> assign(:back_path, back_path_from_session(socket))
          |> assign(:read_only?, not LiveAuth.authorized?(
               Map.get(socket.assigns, :current_actor),
               :retry_job,
               %{type: :job, id: to_string(job.id)}
             ))
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
      |> assign(:back_path, Selectors.jobs_path([]))
      |> assign(:read_only?, not LiveAuth.authorized?(
           Map.get(socket.assigns, :current_actor),
           :retry_job,
           %{type: :page, id: "jobs"}
         ))
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
      assign(socket, :read_only?, not LiveAuth.authorized?(
        Map.get(socket.assigns, :current_actor),
        :retry_job,
        %{type: :page, id: "jobs"}
      ))
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
      do: "rounded border border-indigo-300 bg-indigo-50 px-3 py-2 text-sm font-semibold text-indigo-700"

    defp state_tab_class(false),
      do: "rounded border border-slate-200 bg-white px-3 py-2 text-sm font-semibold text-slate-600"

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

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
