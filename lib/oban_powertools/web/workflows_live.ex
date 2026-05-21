if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.WorkflowsLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.DisplayPolicy
    alias ObanPowertools.Workflow.{Edge, Result, Step, Workflow}
    alias ObanPowertools.Web.LiveAuth

    @impl true
    def mount(_params, %{"oban_dashboard_path" => dashboard_path}, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_workflows, %{type: :page, id: "workflows"}) do
        :ok = DisplayPolicy.assert_configured!()

        if connected?(socket) and Code.ensure_loaded?(Phoenix.PubSub) do
          Phoenix.PubSub.subscribe(ObanPowertools.PubSub, ObanPowertools.Workflow.Signal.topic())
        end

        {:ok,
         socket
         |> assign(:oban_dashboard_path, dashboard_path)
         |> assign(:workflows, [])
         |> assign(:workflow, nil)
         |> assign(:steps, [])
         |> assign(:edges, [])
         |> assign(:results, %{})
         |> assign(:selected_step, nil)
         |> load_workflows()}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      socket = load_workflows(socket)

      case Map.get(params, "id") do
        nil ->
          {:noreply,
           socket
           |> assign(:workflow, nil)
           |> assign(:steps, [])
           |> assign(:edges, [])
           |> assign(:results, %{})
           |> assign(:selected_step, nil)}

        workflow_id ->
          {:noreply, load_workflow_detail(socket, workflow_id, Map.get(params, "step"))}
      end
    end

    @impl true
    def handle_info({:workflow_signal, %{workflow_id: workflow_id}}, socket) do
      if socket.assigns.workflow && socket.assigns.workflow.id == workflow_id do
        {:noreply, load_workflow_detail(socket, workflow_id, socket.assigns.selected_step && socket.assigns.selected_step.step_name)}
      else
        {:noreply, load_workflows(socket)}
      end
    end

    def handle_info(_message, socket), do: {:noreply, socket}

    @impl true
    def render(assigns) do
      ~H"""
      <div class="space-y-6 p-6">
        <div>
          <h1 class="text-2xl font-semibold">Workflows</h1>
          <p class="text-sm text-zinc-600">
            Diagnose workflow causality here. Powertools-native pages own preview, reason, and audited mutations.
          </p>
        </div>

        <p class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          <%= LiveAuth.page_read_only_banner(:workflows) %>
        </p>

        <div :if={@workflows == []} class="rounded-lg border bg-white p-6">
          <h2 class="text-base font-semibold">No workflows yet</h2>
          <p class="mt-2 text-sm text-zinc-600">
            Persist a workflow definition to inspect its DAG state and blocker details here.
          </p>
        </div>

        <div :if={@workflows != []} class="grid gap-6 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
          <div class="overflow-hidden rounded-lg border bg-white">
            <table class="min-w-full divide-y">
              <thead class="bg-slate-50 text-left text-sm">
                <tr>
                  <th class="px-4 py-3 font-medium">Workflow</th>
                  <th class="px-4 py-3 font-medium">State</th>
                  <th class="px-4 py-3 font-medium">Steps</th>
                  <th class="px-4 py-3 font-medium">Open</th>
                </tr>
              </thead>
              <tbody class="divide-y text-sm">
                <tr :for={workflow <- @workflows}>
                  <td class="px-4 py-3 font-medium"><%= workflow.name %></td>
                  <td class="px-4 py-3"><%= workflow.state %></td>
                  <td class="px-4 py-3"><%= workflow.step_count %></td>
                  <td class="px-4 py-3">
                    <.link navigate={"/ops/jobs/workflows/#{workflow.id}"} class="rounded bg-indigo-600 px-3 py-2 text-white">
                      Inspect
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="rounded-lg border bg-white p-4">
            <%= if @workflow do %>
              <h2 class="text-base font-semibold"><%= @workflow.name %></h2>
              <p class="mt-2 text-sm text-zinc-600">State: <%= @workflow.state %></p>
              <p class="mt-1 text-sm text-zinc-600">Runnable now: <%= @workflow.runnable_step_count %></p>

              <div class="mt-4 space-y-3">
                <div :for={step <- @steps} class={["rounded border p-3", highlight_class(step, @selected_step)]}>
                  <div class="flex items-center justify-between gap-3">
                    <div>
                      <p class="font-medium"><%= step.step_name %></p>
                      <p class="text-xs text-zinc-500"><%= step.state %></p>
                    </div>
                    <.link
                      patch={selected_step_path(@workflow.id, step.step_name)}
                      class="text-sm text-indigo-700 underline"
                    >
                      Detail
                    </.link>
                  </div>
                  <p :if={step.blocker_codes != []} class="mt-2 text-xs text-amber-700">
                    blocked: <%= Enum.join(step.blocker_codes, ", ") %>
                  </p>
                </div>
              </div>
            <% else %>
              <p class="text-sm text-zinc-600">
                Select a workflow to inspect steps, blockers, and downstream readiness.
              </p>
            <% end %>
          </div>
        </div>

        <div :if={@selected_step} class="rounded-lg border bg-white p-4">
          <% result_display = workflow_result_display(@selected_step, @results, @workflow) %>
          <h2 class="text-base font-semibold"><%= @selected_step.step_name %></h2>
          <p class="mt-2 text-sm text-zinc-600">Worker: <%= @selected_step.worker %></p>
          <p class="mt-1 text-sm text-zinc-600">State: <%= @selected_step.state %></p>
          <p class="mt-1 text-sm text-zinc-600">
            Result available:
            <%= if result_display.available?, do: "yes", else: "no" %>
          </p>

          <div class="mt-4 space-y-3">
            <div :if={result_display.available?}>
              <h3 class="text-sm font-medium">Result Summary</h3>
              <p class="mt-2 text-sm"><%= result_display.summary %></p>
              <p class="mt-2 text-sm"><strong>Payload:</strong> <%= result_display.payload %></p>
              <p :if={result_display.redacted?} class="mt-2 text-xs text-amber-700">
                Redaction outcome: hidden by display policy.
              </p>
            </div>

            <div>
              <h3 class="text-sm font-medium">Dependency Reasons</h3>
              <%= if @selected_step.blocker_codes == [] do %>
                <p class="mt-2 text-sm text-zinc-600">Runnable or already resolved.</p>
              <% else %>
                <ul class="mt-2 space-y-2 text-sm">
                  <li :for={code <- @selected_step.blocker_codes}><%= code %></li>
                </ul>
              <% end %>
            </div>

            <div>
              <h3 class="text-sm font-medium">Dependencies</h3>
              <ul class="mt-2 space-y-2 text-sm">
                <li :for={dependency <- dependency_rows(@selected_step)}>
                  <strong><%= dependency["step_name"] %></strong>:
                  <%= dependency["state"] %> (<%= dependency["policy"] %>)
                </li>
              </ul>
            </div>

            <a :if={@selected_step.job_id} href={build_job_path(@oban_dashboard_path, @selected_step.job_id)} class="text-sm text-indigo-700 underline">
              Open generic job inspection in Oban Web
            </a>
          </div>
        </div>
      </div>
      """
    end

    defp load_workflows(socket) do
      workflows = repo().all(from(workflow in Workflow, order_by: [desc: workflow.inserted_at]))
      assign(socket, :workflows, workflows)
    end

    defp load_workflow_detail(socket, workflow_id, selected_step_name) do
      workflow = repo().get!(Workflow, workflow_id)

      steps =
        repo().all(
          from(step in Step,
            where: step.workflow_id == ^workflow_id,
            order_by: [asc: step.position]
          )
        )

      edges = repo().all(from(edge in Edge, where: edge.workflow_id == ^workflow_id))

      results =
        repo().all(from(result in Result, where: result.workflow_id == ^workflow_id))
        |> Map.new(&{&1.step_id, &1})

      selected_step =
        Enum.find(steps, &(&1.step_name == selected_step_name)) ||
          List.first(Enum.filter(steps, &(&1.blocker_codes != []))) ||
          List.first(steps)

      socket
      |> assign(:workflow, workflow)
      |> assign(:steps, steps)
      |> assign(:edges, edges)
      |> assign(:results, results)
      |> assign(:selected_step, selected_step)
    end

    defp dependency_rows(step) do
      step
      |> get_in([Access.key(:dependency_snapshot), "dependencies"])
      |> case do
        nil ->
          []

        dependencies ->
          Enum.map(dependencies, fn
            %{} = dependency ->
              Map.new(dependency, fn {key, value} -> {to_string(key), value} end)

            name when is_binary(name) ->
              %{"step_name" => name, "state" => "pending", "policy" => "cancel"}
          end)
      end
    end

    defp workflow_result_display(step, results, workflow) do
      results
      |> Map.get(step.id)
      |> Result.display_input()
      |> DisplayPolicy.workflow_result(%{
        surface: :workflows,
        workflow_id: workflow && workflow.id,
        step_name: step.step_name
      })
    end

    defp highlight_class(step, nil), do: if(step.blocker_codes != [], do: "border-amber-400 bg-amber-50", else: "")
    defp highlight_class(step, selected_step) do
      cond do
        step.id == selected_step.id -> "border-indigo-500 bg-indigo-50"
        step.blocker_codes != [] -> "border-amber-400 bg-amber-50"
        true -> ""
      end
    end

    defp selected_step_path(workflow_id, step_name),
      do: "/ops/jobs/workflows/#{workflow_id}?step=#{step_name}"

    defp build_job_path(base, job_id), do: Path.join([base, "jobs", Integer.to_string(job_id)])
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
