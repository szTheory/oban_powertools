if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.WorkflowsLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.{ControlPlane, DisplayPolicy, Explain}
    alias ObanPowertools.Workflow.{Edge, Result, Step, Workflow}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

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
         |> assign(:workflow_story, nil)
         |> assign(:step_stories, %{})
         |> assign(:selected_step, nil)
         |> assign(:selected_step_story, nil)
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
           |> assign(:workflow_story, nil)
           |> assign(:step_stories, %{})
           |> assign(:selected_step, nil)
           |> assign(:selected_step_story, nil)}

        workflow_id ->
          {:noreply, load_workflow_detail(socket, workflow_id, Map.get(params, "step"))}
      end
    end

    @impl true
    def handle_info({:workflow_signal, %{workflow_id: workflow_id}}, socket) do
      if socket.assigns.workflow && socket.assigns.workflow.id == workflow_id do
        {:noreply,
         load_workflow_detail(
           socket,
           workflow_id,
           socket.assigns.selected_step && socket.assigns.selected_step.step_name
         )}
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
            Diagnose workflow causality here. <%= ControlPlanePresenter.native_banner() %>
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
                  <th class="px-4 py-3 font-medium">Operator Status</th>
                  <th class="px-4 py-3 font-medium">Steps</th>
                  <th class="px-4 py-3 font-medium">Open</th>
                </tr>
              </thead>
              <tbody class="divide-y text-sm">
                <tr :for={workflow <- @workflows}>
                  <td class="px-4 py-3 font-medium"><%= workflow.name %></td>
                  <td class="px-4 py-3"><%= workflow_status_label(workflow) %></td>
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
              <p class="mt-2 text-sm text-zinc-600">Operator Status: <%= workflow_status_label(@workflow, @workflow_story) %></p>
              <p class="mt-1 text-sm text-zinc-600">Diagnosis: <%= @workflow_story.diagnosis %></p>
              <p class="mt-1 text-sm text-zinc-600">Runnable now: <%= @workflow.runnable_step_count %></p>
              <p class="mt-1 text-sm text-zinc-600">
                Semantics: <%= @workflow_story.semantics.label %> (<%= @workflow_story.semantics.mode %>)
              </p>
              <p class="mt-1 text-sm text-zinc-600">
                Callback posture:
                delivered <%= @workflow_story.callback_posture.delivered %>,
                failed <%= @workflow_story.callback_posture.failed %>,
                pending <%= @workflow_story.callback_posture.pending %>
              </p>
              <p :if={@workflow_story.latest_recovery_session} class="mt-1 text-sm text-zinc-600">
                Latest recovery session: <%= @workflow_story.latest_recovery_session.id %>
              </p>
              <% workflow_refusal = ControlPlanePresenter.workflow_refusal(@workflow_story.rejection_summary) %>
              <div :if={workflow_refusal} class="mt-2 rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
                <p><strong>Outcome:</strong> <%= workflow_refusal.outcome %></p>
                <p class="mt-1"><strong>Reason:</strong> <%= workflow_refusal.reason %></p>
                <p class="mt-1"><strong>Legal next move:</strong> <%= workflow_refusal.next_move %></p>
                <p class="mt-1"><strong>Venue:</strong> <%= workflow_refusal.venue %></p>
                <p class="mt-1 text-xs text-amber-700">Machine code: <%= workflow_refusal.code %></p>
              </div>

              <div class="mt-4 space-y-3">
                <div :for={step <- @steps} class={["rounded border p-3", highlight_class(step, @selected_step)]}>
                  <% story = Map.fetch!(@step_stories, step.id) %>
                  <div class="flex items-center justify-between gap-3">
                    <div>
                      <p class="font-medium"><%= step.step_name %></p>
                      <p class="text-xs text-zinc-500"><%= step_status_label(story) %></p>
                      <p class="text-xs text-zinc-500">diagnosis: <%= story.diagnosis || "none" %></p>
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
                  <p :if={story.blocker_summaries != []} class="mt-1 text-xs text-zinc-500">
                    why: <%= Enum.join(story.blocker_summaries, "; ") %>
                  </p>
                  <% step_refusal = ControlPlanePresenter.workflow_refusal(story.rejection_summary) %>
                  <p :if={step_refusal} class="mt-1 text-xs text-amber-700">
                    next move: <%= step_refusal.next_move %>
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
          <p class="mt-1 text-sm text-zinc-600">Operator Status: <%= step_status_label(@selected_step_story) %></p>
          <p class="mt-1 text-sm text-zinc-600">Diagnosis: <%= @selected_step_story.diagnosis || "none" %></p>
          <p class="mt-1 text-sm text-zinc-600">
            Result available:
            <%= if result_display.available?, do: "yes", else: "no" %>
          </p>
          <% selected_step_refusal = ControlPlanePresenter.workflow_refusal(@selected_step_story.rejection_summary) %>
          <div :if={selected_step_refusal} class="mt-2 rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
            <p><strong>Outcome:</strong> <%= selected_step_refusal.outcome %></p>
            <p class="mt-1"><strong>Reason:</strong> <%= selected_step_refusal.reason %></p>
            <p class="mt-1"><strong>Legal next move:</strong> <%= selected_step_refusal.next_move %></p>
            <p class="mt-1"><strong>Venue:</strong> <%= selected_step_refusal.venue %></p>
            <p class="mt-1 text-xs text-amber-700">Machine code: <%= selected_step_refusal.code %></p>
          </div>
          <div :if={lifeline_handoff(@workflow, @selected_step, @workflow_story, @selected_step_story)} class="mt-3 rounded border border-indigo-200 bg-indigo-50 p-3 text-sm text-indigo-900">
            <p class="font-medium">
              Review the bounded action in Lifeline.
            </p>
            <p class="mt-1">
              Diagnose workflow causality here. <%= ControlPlanePresenter.runbook_ownership_label(:powertools_native) %> pages own preview, reason, venue, and <%= ControlPlanePresenter.ownership_posture(:powertools_native) %> controls.
            </p>
            <.link
              navigate={lifeline_handoff(@workflow, @selected_step, @workflow_story, @selected_step_story).path}
              class="mt-3 inline-flex rounded bg-indigo-600 px-3 py-2 text-white"
            >
              <%= lifeline_handoff(@workflow, @selected_step, @workflow_story, @selected_step_story).label %>
            </.link>
          </div>

          <div class="mt-3 rounded border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
            <p class="font-medium">Open runbook entry</p>
            <p class="mt-1">
              Blocked workflow steps stay advisory here until the operator chooses a legal next venue.
            </p>
            <p class="mt-2">
              <strong>Legal next move:</strong>
              <%= if lifeline_handoff(@workflow, @selected_step, @workflow_story, @selected_step_story),
                do: lifeline_handoff(@workflow, @selected_step, @workflow_story, @selected_step_story).label,
                else: "Review workflow diagnosis before retrying a bounded action." %>
            </p>
            <p class="mt-1">
              <strong>Venue:</strong>
              <%= ControlPlanePresenter.runbook_ownership_label(:powertools_native) %>
            </p>
            <div class="mt-2 space-y-1 text-xs">
              <div
                data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("Powertools-native")}
                data-runbook-variant={follow_up_variant("Powertools-native")}
                class={follow_up_row_class("Powertools-native")}
              >
                <%= ControlPlanePresenter.runbook_ownership_label("Powertools-native") %>
              </div>
              <div
                data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("Oban Web bridge")}
                data-runbook-variant={follow_up_variant("Oban Web bridge")}
                class={follow_up_row_class("Oban Web bridge")}
              >
                <%= ControlPlanePresenter.runbook_ownership_label("Oban Web bridge") %>
              </div>
              <div
                data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label("host-owned follow-up")}
                data-runbook-variant={follow_up_variant("host-owned follow-up")}
                class={follow_up_row_class("host-owned follow-up")}
              >
                <%= ControlPlanePresenter.runbook_ownership_label("host-owned follow-up") %>
              </div>
            </div>
            <a href={forensic_path(@workflow, @selected_step)} class="mt-3 inline-block text-sm text-indigo-700 underline">
              evidence link
            </a>
          </div>

          <div class="mt-3 rounded border border-slate-200 bg-slate-50 p-3 text-sm text-slate-800">
            <p class="font-medium">Open the forensic bundle.</p>
            <p class="mt-1">
              Workflows remain a first-class Phase 32 forensic entry surface. Supporting limiter and cron context stays labeled as supporting evidence.
            </p>
            <.link
              navigate={forensic_path(@workflow, @selected_step)}
              class="mt-3 inline-flex rounded bg-slate-900 px-3 py-2 text-white"
            >
              Open forensic timeline
            </.link>
          </div>

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
                  <li :for={{code, summary} <- Enum.zip(@selected_step_story.blocker_codes, @selected_step_story.blocker_summaries)}>
                    <%= code %>: <%= summary %>
                  </li>
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
              Open generic job inspection in Oban Web bridge
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

      workflow_story = Explain.workflow_story(workflow, steps, repo: repo())
      step_stories = Map.new(steps, &{&1.id, Explain.step_story(&1, repo: repo())})
      selected_step_story = selected_step && Map.fetch!(step_stories, selected_step.id)

      socket
      |> assign(:workflow, workflow)
      |> assign(:steps, steps)
      |> assign(:edges, edges)
      |> assign(:results, results)
      |> assign(:workflow_story, workflow_story)
      |> assign(:step_stories, step_stories)
      |> assign(:selected_step, selected_step)
      |> assign(:selected_step_story, selected_step_story)
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

    defp highlight_class(step, nil),
      do: if(step.blocker_codes != [], do: "border-amber-400 bg-amber-50", else: "")

    defp highlight_class(step, selected_step) do
      cond do
        step.id == selected_step.id -> "border-indigo-500 bg-indigo-50"
        step.blocker_codes != [] -> "border-amber-400 bg-amber-50"
        true -> ""
      end
    end

    defp selected_step_path(workflow_id, step_name),
      do: "/ops/jobs/workflows/#{workflow_id}?step=#{URI.encode_www_form(step_name)}"

    defp forensic_path(workflow, selected_step) do
      Selectors.forensic_path([
        {"workflow_id", workflow.id},
        {"step", selected_step && selected_step.step_name},
        {"resource_type", if(selected_step, do: "workflow_step", else: "workflow")},
        {"resource_id", selected_step && selected_step.id}
      ])
    end

    defp lifeline_handoff(workflow, selected_step, workflow_story, selected_step_story) do
      step_actions =
        selected_step_story.executable_actions
        |> Enum.filter(&(&1.target_type == "workflow_step"))

      workflow_actions =
        workflow_story.executable_actions
        |> Enum.filter(&(&1.target_type == "workflow"))

      action = List.first(step_actions) || List.first(workflow_actions)

      if action do
        %{
          label: "Review in Lifeline: #{action.label}",
          path:
            Selectors.lifeline_path([
              {"workflow_id", workflow.id},
              {"step", selected_step && selected_step.step_name},
              {"action", action.id}
            ])
        }
      end
    end

    defp build_job_path(base, job_id), do: Path.join([base, "jobs", Integer.to_string(job_id)])

    defp workflow_status_label(workflow),
      do: workflow_status_label(workflow, %{diagnosis: workflow.state, latest_rejection: nil})

    defp workflow_status_label(_workflow, story) do
      story
      |> ControlPlane.workflow_status()
      |> Map.fetch!(:operator_status)
      |> ControlPlanePresenter.status_label()
    end

    defp step_status_label(story) do
      story
      |> ControlPlane.workflow_status()
      |> Map.fetch!(:operator_status)
      |> ControlPlanePresenter.status_label()
    end

    defp follow_up_variant(path_or_venue) do
      path_or_venue
      |> ControlPlanePresenter.follow_up_render_variant()
      |> Atom.to_string()
    end

    defp follow_up_row_class(path_or_venue) do
      case ControlPlanePresenter.follow_up_render_variant(path_or_venue) do
        :native_primary -> "rounded border border-indigo-300 bg-indigo-100 px-2 py-1"
        :bridge_guidance -> "rounded border border-slate-300 bg-white px-2 py-1"
        :host_guidance -> "rounded border border-amber-300 bg-amber-100 px-2 py-1"
      end
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
