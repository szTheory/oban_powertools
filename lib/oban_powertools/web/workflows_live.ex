if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.WorkflowsLive do
    @moduledoc false

    use Phoenix.LiveView

    import Ecto.Query

    alias ObanPowertools.{ControlPlane, DisplayPolicy, Explain}
    alias ObanPowertools.Workflow.{Edge, Result, Step, Workflow}
    alias ObanPowertools.Web.Components.{DataDisplay, OperatorPatterns}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}

    @workflow_scan_limit 50
    @workflow_step_limit 100
    @workflow_result_limit 50
    @workflow_evidence_limit 25

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
         |> assign(:workflow_unavailable?, false)
         |> assign(:workflow_scan_complete?, true)
         |> assign(:step_evidence_complete?, true)
         |> assign(:result_evidence_complete?, true)
         |> assign(:diagnostic_evidence_complete?, true)
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
           |> assign(:selected_step_story, nil)
           |> assign(:workflow_unavailable?, false)}

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
      page_content(assigns)
    end

    @doc "Renders the production Workflows page from finite, already-authorized assigns."
    def page_content(assigns) do
      ~H"""
      <div id="workflows-page" class="obpt-page obpt-workflows-page">
        <header class="obpt-page__header">
          <h1 class="obpt-page__title">Workflows</h1>
          <p class="obpt-page__intro">
            Review workflow progress, understand blocked steps, and follow the supported recovery path.
          </p>
        </header>

        <p class="obpt-page__support-truth">
          {LiveAuth.page_read_only_banner(:workflows)}
        </p>

        <DataDisplay.data_table
          id="workflows-table"
          caption="Current workflows"
          rows={@workflows}
          row_id={:id}
          state={if(@workflows == [], do: :empty, else: :ready)}
          state_heading="No workflows available"
          state_body="Persisted workflow definitions will appear here when evidence is available."
          row_count={length(@workflows)}
          pagination_summary={
            if(@workflow_scan_complete?,
              do: "All retained workflows in this bounded view are shown.",
              else: "More workflows exist; this view shows the first 50."
            )
          }
        >
          <:col :let={workflow} label="Workflow">{workflow.name}</:col>
          <:col :let={workflow} label="Operator status">
            <DataDisplay.status_pill domain={:workflow} state={workflow.state} />
          </:col>
          <:col :let={workflow} label="Steps">{workflow.step_count}</:col>
          <:action :let={workflow}>
            <.link
              id={"workflow-#{workflow.id}-detail-link"}
              navigate={Selectors.workflow_detail_path(workflow.id)}
              aria-label={"Inspect workflow #{workflow.name}"}
            >
              Inspect workflow
            </.link>
          </:action>
        </DataDisplay.data_table>

        <section
          :if={@workflow_unavailable?}
          id="workflow-unavailable"
          aria-label="Workflow unavailable"
        >
          <DataDisplay.empty_state
            id="workflow-unavailable-state"
            heading="Workflow unavailable"
            body="It may not exist, may no longer be retained, or you may not have access. Return to Workflows and choose another workflow."
            data-obpt-data-state="unavailable"
          >
            <:action>
              <.link navigate={Selectors.workflows_path([])}>
                Return to Workflows
              </.link>
            </:action>
          </DataDisplay.empty_state>
        </section>

        <section :if={@workflow} class="obpt-workflows-page__diagnosis" aria-labelledby="workflow-title">
          <h2 id="workflow-title">{@workflow.name}</h2>
          <DataDisplay.description_list id="workflow-summary" state={:ready}>
            <:item label="Operator Status:">
              {workflow_status_label(@workflow, @workflow_story)}
            </:item>
            <:item label="Diagnosis:">{workflow_diagnosis_label(@workflow_story.diagnosis)}</:item>
            <:item label="Runnable now:">{@workflow.runnable_step_count}</:item>
            <:item label="Semantics:">
              {@workflow_story.semantics.label} ({@workflow_story.semantics.mode})
            </:item>
            <:item label="Callback posture:">
              delivered {@workflow_story.callback_posture.delivered},
              failed {@workflow_story.callback_posture.failed},
              pending {@workflow_story.callback_posture.pending}
            </:item>
            <:item :if={@workflow_story.latest_recovery_session} label="Latest recovery session:">
              {@workflow_story.latest_recovery_session.id}
            </:item>
          </DataDisplay.description_list>
          <p class="obpt-workflows-page__semantics">
            Semantics: {@workflow_story.semantics.label} ({@workflow_story.semantics.mode})
          </p>

          <p :if={!@step_evidence_complete?} class="obpt-evidence-completeness">
            More workflow steps exist; this diagnosis shows the first 100 in semantic order.
          </p>
          <p :if={!@result_evidence_complete?} class="obpt-evidence-completeness">
            More workflow results exist; this diagnosis shows a bounded partial window.
          </p>
          <p :if={!@diagnostic_evidence_complete?} class="obpt-evidence-completeness">
            More dependency evidence exists; this diagnosis shows a bounded partial window.
          </p>

          <% workflow_refusal = ControlPlanePresenter.workflow_refusal(@workflow_story.rejection_summary) %>
          <section :if={workflow_refusal} class="obpt-workflows-page__refusal" aria-label="Workflow refusal">
            <p><strong>Outcome:</strong> {workflow_refusal.outcome}</p>
            <p><strong>Reason:</strong> {workflow_refusal.reason}</p>
            <p><strong>Legal next move:</strong> {workflow_refusal.next_move}</p>
            <p><strong>Venue:</strong> {workflow_refusal.venue}</p>
            <p>
              Machine code:
              <DataDisplay.machine_value
                id="workflow-refusal-code"
                value={workflow_refusal.code}
                kind={:literal}
              />
            </p>
          </section>

          <h2 id="workflow-steps-title">Workflow steps</h2>
          <ol
            id="workflow-steps"
            class="obpt-workflows-page__steps"
            aria-labelledby="workflow-steps-title"
          >
            <li
              :for={step <- @steps}
              id={"workflow-step-#{step.id}"}
              class="obpt-workflows-page__step"
              data-selected={@selected_step && step.id == @selected_step.id}
            >
              <% story = Map.fetch!(@step_stories, step.id) %>
              <h3>{step.step_name}</h3>
              <DataDisplay.status_pill domain={:workflow_step} state={step.state} />
              <p>Diagnosis: {workflow_diagnosis_label(story.diagnosis)}</p>
              <p :if={story.blocker_summaries != []}>
                Why: {Enum.join(story.blocker_summaries, "; ")}
              </p>
              <.link
                patch={Selectors.workflow_detail_path(@workflow.id, step: step.step_name)}
                aria-label={"Review step #{step.step_name} in #{@workflow.name}"}
              >
                Review step
              </.link>
            </li>
          </ol>
        </section>

        <section :if={@selected_step} class="obpt-workflows-page__selected-step" aria-labelledby="selected-step-title">
          <% result_display = workflow_result_display(@selected_step, @results, @workflow) %>
          <h2 id="selected-step-title">{@selected_step.step_name}</h2>
          <DataDisplay.description_list id="selected-step-summary" state={:ready}>
            <:item label="Worker:">{@selected_step.worker}</:item>
            <:item label="Operator Status:">{step_status_label(@selected_step_story)}</:item>
            <:item label="Diagnosis:">{workflow_diagnosis_label(@selected_step_story.diagnosis)}</:item>
            <:item label="Result available:">{if(result_display.available?, do: "yes", else: "no")}</:item>
          </DataDisplay.description_list>

          <% selected_step_refusal = ControlPlanePresenter.workflow_refusal(@selected_step_story.rejection_summary) %>
          <section :if={selected_step_refusal} class="obpt-workflows-page__refusal" aria-label="Step refusal">
            <p><strong>Outcome:</strong> {selected_step_refusal.outcome}</p>
            <p><strong>Reason:</strong> {selected_step_refusal.reason}</p>
            <p><strong>Legal next move:</strong> {selected_step_refusal.next_move}</p>
            <p><strong>Venue:</strong> {selected_step_refusal.venue}</p>
            <p>
              Machine code:
              <DataDisplay.machine_value
                id="selected-step-refusal-code"
                value={selected_step_refusal.code}
                kind={:literal}
              />
            </p>
          </section>

          <%= if handoff = lifeline_handoff(@workflow, @selected_step, @workflow_story, @selected_step_story) do %>
            <section class="obpt-workflows-page__handoff">
              <h3>Review the bounded action in Lifeline.</h3>
              <p>
                Diagnose workflow causality here. {ControlPlanePresenter.runbook_ownership_label(:powertools_native)}
                pages own preview, reason, venue, and {ControlPlanePresenter.ownership_posture(:powertools_native)} controls.
              </p>
              <.link
                navigate={handoff.path}
                aria-label={"Review recovery in Lifeline: #{handoff.label}"}
              >
                {handoff.label}
              </.link>
            </section>
          <% end %>

          <section class="obpt-workflows-page__runbook">
            <h3>Open runbook entry</h3>
            <p>Blocked workflow steps stay advisory here until the operator chooses a legal next venue.</p>
            <p><strong>Legal next move:</strong> Review workflow diagnosis before retrying a bounded action.</p>
            <p><strong>Venue:</strong> {ControlPlanePresenter.runbook_ownership_label(:powertools_native)}</p>
            <div
              :for={ownership <- ["Powertools-native", "Oban Web bridge", "host-owned follow-up"]}
              data-runbook-ownership={ControlPlanePresenter.runbook_ownership_label(ownership)}
              data-runbook-variant={follow_up_variant(ownership)}
              class={follow_up_row_class(ownership)}
            >
              {ControlPlanePresenter.runbook_ownership_label(ownership)}
            </div>
          </section>

          <section class="obpt-workflows-page__forensics">
            <h3>Open the forensic bundle.</h3>
            <p>Supporting limiter and cron context stays labeled as supporting evidence.</p>
            <.link navigate={forensic_path(@workflow, @selected_step)}>Open forensic evidence</.link>
          </section>

          <section :if={result_display.available?} aria-labelledby="workflow-result-title">
            <h3 id="workflow-result-title">Result Summary</h3>
            <p>{result_display.summary}</p>
            <p><strong>Payload:</strong> {result_display.payload}</p>
            <p :if={result_display.redacted?}>Redaction outcome: hidden by display policy.</p>
          </section>

          <section aria-labelledby="dependency-reasons-title">
            <h3 id="dependency-reasons-title">Dependency Reasons</h3>
            <p :if={@selected_step.blocker_codes == []}>Runnable or already resolved.</p>
            <ul :if={@selected_step.blocker_codes != []}>
              <li :for={{code, summary} <- Enum.zip(@selected_step_story.blocker_codes, @selected_step_story.blocker_summaries)}>
                <span>{summary}</span>
                <DataDisplay.machine_value
                  id={"selected-step-blocker-#{code}"}
                  value={code}
                  kind={:literal}
                />
              </li>
            </ul>
          </section>

          <OperatorPatterns.why_blocked
            id="selected-step-blockers"
            title="Why blocked?"
            summary={
              if(@selected_step.blocker_codes == [],
                do: "No current blocker is recorded for the selected step.",
                else: "The selected step has current blocking evidence."
              )
            }
            impact="Current state and dependency evidence are shown independently. Visual order does not establish cause."
            observed_at={workflow_observed_at(@selected_step)}
            observed_datetime={workflow_observed_at(@selected_step)}
            evidence_state={:current}
            completeness={if(@diagnostic_evidence_complete?, do: :complete, else: :partial)}
            blockers={workflow_blockers(@selected_step, @selected_step_story)}
          />

          <section aria-labelledby="dependencies-title">
            <h3 id="dependencies-title">Dependencies</h3>
            <ol>
              <li :for={dependency <- dependency_rows(@selected_step)}>
                <strong>{dependency["step_name"]}</strong>:
                {dependency["state"]} ({dependency["policy"]})
              </li>
            </ol>
          </section>

          <a :if={@selected_step.job_id} href={build_job_path(@oban_dashboard_path, @selected_step.job_id)}>
            Open generic job inspection in Oban Web bridge
          </a>
        </section>
      </div>
      """
    end

    defp load_workflows(socket) do
      workflows =
        repo().all(
          from(workflow in Workflow,
            order_by: [desc: workflow.inserted_at],
            limit: @workflow_scan_limit + 1
          )
        )

      socket
      |> assign(:workflows, Enum.take(workflows, @workflow_scan_limit))
      |> assign(:workflow_scan_complete?, length(workflows) <= @workflow_scan_limit)
    end

    defp load_workflow_detail(socket, workflow_id, selected_step_name) do
      with {:ok, parsed_id} <- Ecto.UUID.cast(workflow_id),
           true <-
             LiveAuth.authorized?(
               socket.assigns.current_actor,
               :view_workflows,
               %{type: :workflow, id: parsed_id}
             ),
           %Workflow{} = workflow <- repo().get(Workflow, parsed_id) do
        load_available_workflow_detail(socket, workflow, selected_step_name)
      else
        _unavailable -> assign_unavailable_workflow(socket)
      end
    end

    defp load_available_workflow_detail(socket, workflow, selected_step_name) do
      steps =
        repo().all(
          from(step in Step,
            where: step.workflow_id == ^workflow.id,
            order_by: [asc: step.position],
            limit: @workflow_step_limit + 1
          )
        )

      edges =
        repo().all(
          from(edge in Edge,
            where: edge.workflow_id == ^workflow.id,
            order_by: [asc: edge.inserted_at],
            limit: @workflow_evidence_limit + 1
          )
        )

      result_window =
        repo().all(
          from(result in Result,
            where: result.workflow_id == ^workflow.id,
            order_by: [desc: result.recorded_at, desc: result.id],
            limit: @workflow_result_limit + 1
          )
        )

      step_evidence_complete? = length(steps) <= @workflow_step_limit
      result_evidence_complete? = length(result_window) <= @workflow_result_limit
      diagnostic_evidence_complete? = length(edges) <= @workflow_evidence_limit
      steps = Enum.take(steps, @workflow_step_limit)
      edges = Enum.take(edges, @workflow_evidence_limit)
      step_ids = Enum.map(steps, & &1.id)

      results =
        repo().all(
          from(result in Result,
            where: result.workflow_id == ^workflow.id and result.step_id in ^step_ids,
            distinct: result.step_id,
            order_by: [asc: result.step_id, desc: result.recorded_at, desc: result.id]
          )
        )
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
      |> assign(:workflow_unavailable?, false)
      |> assign(:step_evidence_complete?, step_evidence_complete?)
      |> assign(:result_evidence_complete?, result_evidence_complete?)
      |> assign(:diagnostic_evidence_complete?, diagnostic_evidence_complete?)
    end

    defp assign_unavailable_workflow(socket) do
      socket
      |> assign(:workflow, nil)
      |> assign(:steps, [])
      |> assign(:edges, [])
      |> assign(:results, %{})
      |> assign(:workflow_story, nil)
      |> assign(:step_stories, %{})
      |> assign(:selected_step, nil)
      |> assign(:selected_step_story, nil)
      |> assign(:workflow_unavailable?, true)
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

    defp workflow_blockers(step, story) do
      step.blocker_codes
      |> Enum.zip(story.blocker_summaries)
      |> Enum.with_index()
      |> Enum.map(fn {{code, summary}, index} ->
        %{
          id: "workflow-blocker-#{index}",
          evidence_kind: :current,
          label: code,
          summary: summary,
          affected_scope: step.step_name,
          clearing_condition:
            "Refresh current workflow evidence before choosing a recovery venue.",
          evidence_source: "Current workflow step diagnosis",
          technical_code: code
        }
      end)
    end

    defp workflow_observed_at(%{last_transition_at: %DateTime{} = value}),
      do: DateTime.to_iso8601(value)

    defp workflow_observed_at(%{last_transition_at: %NaiveDateTime{} = value}),
      do: NaiveDateTime.to_iso8601(value) <> "Z"

    defp workflow_observed_at(_step), do: "1970-01-01T00:00:00Z"

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
      else
        %{
          label: "Review recovery in Lifeline",
          path:
            Selectors.lifeline_path([
              {"workflow_id", workflow.id},
              {"step", selected_step && selected_step.step_name}
            ])
        }
      end
    end

    defp build_job_path(base, job_id), do: Path.join([base, "jobs", Integer.to_string(job_id)])

    defp workflow_status_label(_workflow, story) do
      story
      |> ControlPlane.workflow_status()
      |> Map.fetch!(:operator_status)
      |> ControlPlanePresenter.status_label()
    end

    defp workflow_diagnosis_label(:waiting_on_dependencies),
      do: "Waiting for required dependencies"

    defp workflow_diagnosis_label(:ready), do: "Ready for the next supported step"
    defp workflow_diagnosis_label(:completed), do: "All retained steps are complete"
    defp workflow_diagnosis_label(nil), do: "No current diagnosis recorded"

    defp workflow_diagnosis_label(value) do
      value
      |> to_string()
      |> String.replace("_", " ")
      |> String.capitalize()
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
        :native_primary -> "obpt-runbook-ownership obpt-runbook-ownership--native"
        :bridge_guidance -> "obpt-runbook-ownership obpt-runbook-ownership--bridge"
        :host_guidance -> "obpt-runbook-ownership obpt-runbook-ownership--host"
      end
    end

    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
