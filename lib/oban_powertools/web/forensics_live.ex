if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ObanPowertools.Web.ForensicsLive do
    @moduledoc false

    use Phoenix.LiveView

    alias ObanPowertools.Forensics
    alias ObanPowertools.Forensics.Scope
    alias ObanPowertools.Web.Components.{DataDisplay, Forms, OperatorPatterns, Primitives}
    alias ObanPowertools.Web.{ControlPlanePresenter, LiveAuth, Selectors}
    alias Phoenix.LiveView.JS

    @bare_path "/ops/jobs/forensics"
    @page_assigns ~w[
      scope_form scope_state scope_notice support summary next_steps
      latest_remediation events coverage audit_href
    ]a
    @draft_keys ~w(evidence_type workflow_id step incident_fingerprint view resource_id)
    @evidence_types ~w(workflow incident cron limiter)
    @support %{
      state: :ready,
      heading: "Read-only evidence",
      copy: "Forensics summarizes retained Powertools evidence and does not prove root cause."
    }
    @empty_notice %{
      heading: "Choose evidence to inspect.",
      copy:
        "Select Workflow, Lifeline incident, Cron entry, or Limiter, then enter its identifier."
    }
    @unavailable_notice %{
      heading: "Evidence unavailable",
      copy: "It may not exist, may no longer be retained, or you may not have access."
    }
    @error_notice %{
      heading: "Evidence did not load",
      copy:
        "Retry the request. If the problem continues, review the matching Audit log or check the host logs."
    }

    @impl true
    def mount(_params, _session, socket) do
      with {:ok, socket} <-
             LiveAuth.authorize_page(socket, :view_forensics, %{type: :page, id: "forensics"}) do
        {:ok, assign_empty(socket)}
      else
        {:error, socket} -> {:ok, socket}
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      case Scope.parse(params) do
        {:empty, [], _notice} ->
          {:noreply, assign_empty(socket)}

        {:invalid, [], _notice} ->
          socket =
            socket
            |> assign_empty()
            |> assign(:scope_notice, %{
              heading: "Choose one evidence type",
              copy:
                "Conflicting scope values were not applied. Select one evidence type and inspect it again.",
              focus?: true
            })
            |> assign(:invalid_replacement?, true)

          if connected?(socket) do
            {:noreply, push_patch(socket, to: @bare_path, replace: true)}
          else
            {:noreply, socket}
          end

        {:ok, %Scope{} = scope, _canonical_params} ->
          {:noreply, load_scope(socket, scope)}
      end
    end

    @impl true
    def handle_event("validate_scope", %{"scope" => params}, socket) do
      draft = normalize_draft(params)
      errors = validate_draft(draft)

      {:noreply,
       socket
       |> assign(:scope_form, scope_form(draft, errors))
       |> assign(:scope_notice, nil)}
    end

    def handle_event("validate_scope", _params, socket) do
      {:noreply,
       socket
       |> assign(:scope_form, scope_form(%{}, %{evidence_type: ["Choose one evidence type."]}))
       |> assign(:scope_notice, nil)}
    end

    @impl true
    def handle_event("inspect_evidence", %{"scope" => params}, socket) do
      draft = normalize_draft(params)

      case draft_scope(draft) do
        {:ok, scope} ->
          {:noreply,
           socket
           |> assign(:scope_notice, nil)
           |> push_patch(to: Selectors.forensic_path(scope))}

        {:error, errors} ->
          {:noreply,
           socket
           |> assign(:scope_form, scope_form(draft, errors))
           |> assign(:scope_notice, %{
             heading: "Choose evidence to inspect",
             copy: "Correct the highlighted field, then inspect the evidence again.",
             focus?: true
           })}
      end
    end

    def handle_event("inspect_evidence", _params, socket) do
      handle_event("inspect_evidence", %{"scope" => %{}}, socket)
    end

    @impl true
    def render(assigns) do
      assigns
      |> Map.take([:__changed__ | @page_assigns])
      |> page_content()
    end

    attr(:scope_form, Phoenix.HTML.Form, required: true)
    attr(:scope_state, :atom, required: true)
    attr(:scope_notice, :map, default: nil)
    attr(:support, :map, required: true)
    attr(:summary, :map, default: nil)
    attr(:next_steps, :list, required: true)
    attr(:latest_remediation, :map, default: nil)
    attr(:events, :list, required: true)
    attr(:coverage, :map, default: nil)
    attr(:audit_href, :string, default: nil)

    def page_content(assigns) do
      events = Enum.take(assigns.events, 50)
      primary_step = Enum.find(assigns.next_steps, &(&1.role == :primary))

      additional_steps =
        Enum.reject(assigns.next_steps, fn step ->
          primary_step && step.id == primary_step.id
        end)

      assigns =
        assigns
        |> assign(:events, events)
        |> assign(:primary_step, primary_step)
        |> assign(:additional_steps, additional_steps)

      ~H"""
      <main class="obpt-page obpt-page--forensics">
        <header class="obpt-page-header">
          <h1>Forensics</h1>
          <p>
            Inspect a supported evidence scope, review the current diagnosis, and follow the retained record.
          </p>
        </header>

        <section
          id="forensics-support"
          class="obpt-surface"
          data-obpt-support-state={@support.state}
          aria-labelledby="forensics-support-heading"
        >
          <h2 id="forensics-support-heading">{@support.heading}</h2>
          <p>{@support.copy}</p>
        </section>

        <section
          :if={@scope_notice}
          id="forensics-scope-errors"
          class="obpt-notice"
          role="alert"
          tabindex="-1"
          phx-mounted={if(@scope_notice[:focus?], do: JS.focus(to: "#forensics-scope-errors"))}
        >
          <h2>{@scope_notice.heading}</h2>
          <p>{@scope_notice.copy}</p>
        </section>

        <OperatorPatterns.filter_bar
          id="forensics-scope"
          form={@scope_form}
          mode={:submit}
          result_summary="Choose one supported evidence scope."
          results_target_id="forensics-result-state"
          filters_expanded
          change_event="validate_scope"
          submit_event="inspect_evidence"
          submit_label="Inspect evidence"
        >
          <:fields>
            <Forms.select
              field={@scope_form[:evidence_type]}
              label="Evidence type"
              options={[
                {"Choose evidence type", ""},
                {"Workflow", "workflow"},
                {"Lifeline incident", "incident"},
                {"Cron entry", "cron"},
                {"Limiter", "limiter"}
              ]}
              required
            />

            <Forms.input
              :if={scope_type(@scope_form) == "workflow"}
              field={@scope_form[:workflow_id]}
              label="Workflow ID"
              hint="Enter the stable workflow identifier."
              required
            />
            <Forms.input
              :if={scope_type(@scope_form) == "workflow"}
              field={@scope_form[:step]}
              label="Step"
              hint="Optional workflow step name."
            />

            <Forms.input
              :if={scope_type(@scope_form) == "incident"}
              field={@scope_form[:incident_fingerprint]}
              label="Incident fingerprint"
              hint="Enter the stable Lifeline incident fingerprint."
              required
            />
            <Forms.select
              :if={scope_type(@scope_form) == "incident"}
              field={@scope_form[:view]}
              label="Incident view"
              hint="Optional Lifeline incident state."
              options={[
                {"Any retained incident", ""},
                {"Active", "active"},
                {"Resolved", "resolved"}
              ]}
            />

            <Forms.input
              :if={scope_type(@scope_form) == "cron"}
              field={@scope_form[:resource_id]}
              label="Cron entry ID"
              hint="Enter the stable cron entry identifier."
              required
            />

            <Forms.input
              :if={scope_type(@scope_form) == "limiter"}
              field={@scope_form[:resource_id]}
              label="Limiter ID"
              hint="Enter the stable limiter identifier."
              required
            />
          </:fields>
        </OperatorPatterns.filter_bar>

        <section
          :if={@scope_state == :empty}
          id="forensics-result-state"
          class="obpt-state-message"
          data-obpt-state="empty"
          aria-labelledby="forensics-result-heading"
        >
          <h2 id="forensics-result-heading">{empty_notice().heading}</h2>
          <p>{empty_notice().copy}</p>
        </section>

        <section
          :if={@scope_state == :unavailable}
          id="forensics-result-state"
          class="obpt-state-message"
          data-obpt-state="unavailable"
          aria-labelledby="forensics-result-heading"
        >
          <h2 id="forensics-result-heading">{unavailable_notice().heading}</h2>
          <p>{unavailable_notice().copy}</p>
        </section>

        <section
          :if={@scope_state == :error}
          id="forensics-result-state"
          class="obpt-state-message"
          data-obpt-state="error"
          aria-labelledby="forensics-result-heading"
        >
          <h2 id="forensics-result-heading">{error_notice().heading}</h2>
          <p>{error_notice().copy}</p>
        </section>

        <section
          :if={@scope_state == :ready}
          id="forensics-result-state"
          class="obpt-forensics-results"
          data-obpt-state="ready"
        >
          <section
            id="forensics-investigation-summary"
            class="obpt-surface"
            aria-labelledby="forensics-investigation-summary-heading"
          >
            <h2 id="forensics-investigation-summary-heading">{@summary.heading}</h2>
            <DataDisplay.description_list
              id="forensics-summary-facts"
              state={:ready}
              resource="investigation summary"
            >
              <:item label="Subject">{@summary.scope.subject}</:item>
              <:item label="Evidence type">{@summary.scope.type_label}</:item>
              <:item label="Ownership">{@summary.scope.ownership}</:item>
              <:item label="Current diagnosis">{@summary.diagnosis}</:item>
              <:item label="Detail">{@summary.detail}</:item>
              <:item label="Provenance">{@summary.provenance}</:item>
              <:item label="Completeness">{@summary.completeness}</:item>
              <:item label="Coverage">{@summary.coverage}</:item>
            </DataDisplay.description_list>
          </section>

          <section
            id="forensics-next-steps"
            class="obpt-surface"
            aria-labelledby="forensics-next-steps-heading"
          >
            <h2 id="forensics-next-steps-heading">What to do next</h2>

            <div :if={@primary_step} class="obpt-forensics-guidance" data-obpt-primary-guidance>
              <Primitives.link href={@primary_step.href}>{@primary_step.label}</Primitives.link>
              <p>{@primary_step.support}</p>
            </div>

            <p :if={is_nil(@primary_step)}>
              No authorized follow-up destination is available for this evidence.
            </p>

            <details :if={@additional_steps != []} class="obpt-forensics-guidance-disclosure">
              <summary>Review all guidance</summary>
              <ul>
                <li :for={step <- @additional_steps} id={"forensics-guidance-#{step.id}"}>
                  <Primitives.link href={step.href}>{step.label}</Primitives.link>
                  <p>{step.support}</p>
                </li>
              </ul>
            </details>
          </section>

          <section
            :if={@latest_remediation}
            id="forensics-latest-remediation"
            class="obpt-surface"
            aria-labelledby="forensics-latest-remediation-heading"
            data-obpt-historical-evidence
          >
            <h2 id="forensics-latest-remediation-heading">
              {@latest_remediation.heading}
            </h2>
            <p>
              Historical evidence only. It does not replace the current investigation summary.
            </p>
            <p>{@latest_remediation.summary}</p>
            <dl>
              <div>
                <dt>Status</dt>
                <dd>{@latest_remediation.status}</dd>
              </div>
              <div>
                <dt>Recorded at</dt>
                <dd>
                  <time datetime={@latest_remediation.occurred_datetime}>
                    {@latest_remediation.occurred_at}
                  </time>
                </dd>
              </div>
              <div>
                <dt>Provenance</dt>
                <dd>{@latest_remediation.provenance}</dd>
              </div>
            </dl>
          </section>

          <section
            id="forensics-event-log"
            class="obpt-surface"
            aria-labelledby="forensics-event-log-heading"
          >
            <h2 id="forensics-event-log-heading">Event log</h2>
            <p :if={@events == []} class="obpt-forensics-history-unavailable">
              <strong>Event history unavailable.</strong>
              Current evidence may still be available, but this source cannot provide retained history.
            </p>
            <DataDisplay.timeline
              id="forensics-events"
              state={:ready}
              resource="forensic events"
            >
              <:event
                :for={event <- @events}
                timestamp={event.timestamp}
                title={event.title}
                source={event.source}
              >
                <p :if={event.notes}>{event.notes}</p>
                <p><strong>Status:</strong> {event.status}</p>
                <ul :if={event.follow_ups != []}>
                  <li :for={follow_up <- event.follow_ups}>
                    <Primitives.link href={follow_up.href}>{follow_up.label}</Primitives.link>
                  </li>
                </ul>
              </:event>
            </DataDisplay.timeline>
          </section>

          <section
            id="forensics-evidence-coverage"
            class="obpt-surface"
            aria-labelledby="forensics-evidence-coverage-heading"
          >
            <h2 id="forensics-evidence-coverage-heading">{@coverage.heading}</h2>
            <p>{@coverage.summary}</p>
            <p>{@coverage.retention}</p>
            <dl>
              <div>
                <dt>Completeness</dt>
                <dd>{@coverage.completeness}</dd>
              </div>
              <div>
                <dt>Bounded window</dt>
                <dd>{if(@coverage.bounded?, do: "Yes", else: "Unknown")}</dd>
              </div>
            </dl>
            <ul class="obpt-forensics-sources">
              <li :for={source <- @coverage.sources} id={"forensics-source-#{source.id}"}>
                <h3>{source.label}</h3>
                <p>{coverage_source_count(source)}</p>
                <p>{source.provenance} · {source.completeness}</p>
                <p>{source.retention}</p>
              </li>
            </ul>
            <Primitives.link :if={@audit_href} href={@audit_href}>
              View matching audit evidence
            </Primitives.link>
          </section>
        </section>
      </main>
      """
    end

    defp assign_empty(socket) do
      preserved_notice =
        if Map.get(socket.assigns, :invalid_replacement?, false) do
          Map.get(socket.assigns, :scope_notice)
        end

      socket
      |> assign(:scope_form, scope_form(%{}))
      |> assign(:scope_state, :empty)
      |> assign(:scope_notice, preserved_notice)
      |> assign(:support, @support)
      |> assign(:summary, nil)
      |> assign(:next_steps, [])
      |> assign(:latest_remediation, nil)
      |> assign(:events, [])
      |> assign(:coverage, nil)
      |> assign(:audit_href, nil)
      |> assign(:invalid_replacement?, false)
    end

    defp load_scope(socket, %Scope{} = scope) do
      socket =
        socket
        |> assign(:scope_form, scope |> scope_draft() |> scope_form())
        |> assign(:scope_notice, nil)
        |> assign(:invalid_replacement?, false)

      if scope_authorized?(socket.assigns.current_actor, scope) do
        case Forensics.bundle(scope, repo: repo()) do
          {:ok, bundle} ->
            presentation =
              ControlPlanePresenter.present_forensics(bundle, %{
                authorized_hrefs:
                  authorized_destination_hrefs(socket.assigns.current_actor, bundle)
              })

            assign_ready(socket, presentation)

          {:unavailable, _safe_reason} ->
            assign_unavailable(socket)

          {:error, _safe_reason} ->
            assign_error(socket)
        end
      else
        assign_unavailable(socket)
      end
    rescue
      _error -> assign_error(socket)
    end

    defp assign_ready(socket, presentation) do
      socket
      |> assign(:scope_state, :ready)
      |> assign(:support, presentation.support)
      |> assign(:summary, Map.put(presentation.summary, :scope, presentation.scope))
      |> assign(:next_steps, presentation.next_steps)
      |> assign(:latest_remediation, presentation.latest_remediation)
      |> assign(:events, presentation.events)
      |> assign(:coverage, presentation.coverage)
      |> assign(:audit_href, presentation.audit_href)
    end

    defp assign_unavailable(socket) do
      socket
      |> assign(:scope_state, :unavailable)
      |> assign(:support, @support)
      |> assign(:summary, nil)
      |> assign(:next_steps, [])
      |> assign(:latest_remediation, nil)
      |> assign(:events, [])
      |> assign(:coverage, nil)
      |> assign(:audit_href, nil)
    end

    defp assign_error(socket) do
      socket
      |> assign(:scope_state, :error)
      |> assign(:support, @support)
      |> assign(:summary, nil)
      |> assign(:next_steps, [])
      |> assign(:latest_remediation, nil)
      |> assign(:events, [])
      |> assign(:coverage, nil)
      |> assign(:audit_href, nil)
    end

    defp scope_form(draft, errors \\ %{}) do
      Phoenix.Component.to_form(normalize_draft(draft),
        as: :scope,
        id: "forensics-scope-form",
        errors: form_errors(errors)
      )
    end

    defp form_errors(errors) do
      Enum.flat_map(errors, fn {field, messages} ->
        Enum.map(messages, &{field, {&1, []}})
      end)
    end

    defp normalize_draft(params) when is_map(params) do
      Map.new(@draft_keys, fn key ->
        value = Map.get(params, key, Map.get(params, String.to_existing_atom(key), ""))
        {key, if(is_binary(value), do: value, else: "")}
      end)
    end

    defp normalize_draft(_params), do: normalize_draft(%{})

    defp validate_draft(draft) do
      type = draft["evidence_type"]

      %{}
      |> add_error(type not in @evidence_types, :evidence_type, "Choose one evidence type.")
      |> add_error(
        type == "workflow" and blank?(draft["workflow_id"]),
        :workflow_id,
        "Enter a workflow ID."
      )
      |> add_error(
        type == "incident" and blank?(draft["incident_fingerprint"]),
        :incident_fingerprint,
        "Enter an incident fingerprint."
      )
      |> add_error(
        type == "incident" and draft["view"] not in ["", "active", "resolved"],
        :view,
        "Choose Active, Resolved, or any retained incident."
      )
      |> add_error(
        type == "cron" and blank?(draft["resource_id"]),
        :resource_id,
        "Enter a cron entry ID."
      )
      |> add_error(
        type == "limiter" and blank?(draft["resource_id"]),
        :resource_id,
        "Enter a limiter ID."
      )
    end

    defp add_error(errors, true, field, message),
      do: Map.update(errors, field, [message], &(&1 ++ [message]))

    defp add_error(errors, false, _field, _message), do: errors

    defp draft_scope(draft) do
      errors = validate_draft(draft)

      if errors == %{} do
        draft
        |> draft_selectors()
        |> Scope.parse()
        |> case do
          {:ok, scope, _canonical} -> {:ok, scope}
          _invalid -> {:error, %{evidence_type: ["Choose one evidence type."]}}
        end
      else
        {:error, errors}
      end
    end

    defp draft_selectors(%{"evidence_type" => "workflow"} = draft) do
      %{"workflow_id" => draft["workflow_id"], "step" => blank_to_nil(draft["step"])}
    end

    defp draft_selectors(%{"evidence_type" => "incident"} = draft) do
      %{
        "incident_fingerprint" => draft["incident_fingerprint"],
        "view" => blank_to_nil(draft["view"])
      }
    end

    defp draft_selectors(%{"evidence_type" => "cron"} = draft) do
      %{"resource_type" => "cron_entry", "resource_id" => draft["resource_id"]}
    end

    defp draft_selectors(%{"evidence_type" => "limiter"} = draft) do
      %{"resource_type" => "limiter", "resource_id" => draft["resource_id"]}
    end

    defp scope_draft(%Scope{kind: :workflow} = scope) do
      %{
        "evidence_type" => "workflow",
        "workflow_id" => scope.workflow_id,
        "step" => scope.step
      }
    end

    defp scope_draft(%Scope{kind: :incident} = scope) do
      %{
        "evidence_type" => "incident",
        "incident_fingerprint" => scope.incident_fingerprint,
        "view" => scope.view
      }
    end

    defp scope_draft(%Scope{kind: :cron_entry} = scope) do
      %{"evidence_type" => "cron", "resource_id" => scope.resource_id}
    end

    defp scope_draft(%Scope{kind: :limiter} = scope) do
      %{"evidence_type" => "limiter", "resource_id" => scope.resource_id}
    end

    defp scope_type(form), do: form[:evidence_type].value || ""

    defp scope_authorized?(actor, %Scope{} = scope) do
      LiveAuth.authorized?(actor, scope_action(scope.kind), %{
        type: scope.kind,
        id: scope_identity(scope)
      })
    end

    defp scope_action(:workflow), do: :view_workflows
    defp scope_action(:incident), do: :view_lifeline
    defp scope_action(:cron_entry), do: :view_cron
    defp scope_action(:limiter), do: :view_limiters

    defp scope_identity(%Scope{kind: :workflow, workflow_id: id}), do: id
    defp scope_identity(%Scope{kind: :incident, incident_fingerprint: id}), do: id
    defp scope_identity(%Scope{resource_id: id}), do: id

    defp authorized_destination_hrefs(actor, bundle) do
      bundle
      |> destination_candidates()
      |> Enum.filter(fn href ->
        case destination_action(href) do
          nil -> false
          action -> LiveAuth.authorized?(actor, action, %{type: :destination, id: href})
        end
      end)
    end

    defp destination_candidates(bundle) do
      [:legal_next_paths, :linked_resources]
      |> Enum.flat_map(fn key ->
        bundle
        |> Map.get(key, [])
        |> Enum.flat_map(fn
          %{path: path} when is_binary(path) -> [path]
          %{"path" => path} when is_binary(path) -> [path]
          _unsupported -> []
        end)
      end)
      |> Enum.uniq()
    end

    defp destination_action(href) do
      case URI.parse(href).path do
        "/ops/jobs/lifeline" -> :view_lifeline
        "/ops/jobs/cron" -> :view_cron
        "/ops/jobs/limiters" -> :view_limiters
        "/ops/jobs/audit" -> :view_audit
        "/ops/jobs/workflows/" <> _id -> :view_workflows
        _unsupported -> nil
      end
    end

    defp coverage_source_count(%{shown_count: shown_count, has_more?: true}),
      do: "Newest #{shown_count} retained events; more evidence exists."

    defp coverage_source_count(%{shown_count: shown_count, total_count: total_count})
         when is_integer(total_count) and shown_count < total_count,
         do: "Showing #{shown_count} of #{total_count} retained events."

    defp coverage_source_count(%{shown_count: shown_count, has_more?: false}),
      do: "All #{shown_count} available events in this source window."

    defp coverage_source_count(%{shown_count: shown_count}),
      do: "#{shown_count} retained events; total availability is unknown."

    defp empty_notice, do: @empty_notice
    defp unavailable_notice, do: @unavailable_notice
    defp error_notice, do: @error_notice
    defp blank?(value), do: not is_binary(value) or String.trim(value) == ""
    defp blank_to_nil(value), do: if(blank?(value), do: nil, else: value)
    defp repo, do: Application.fetch_env!(:oban_powertools, :repo)
  end
end
