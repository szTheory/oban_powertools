defmodule ObanPowertools.Forensics do
  @moduledoc """
  Typed, bounded evidence assembly for the four supported Forensics families.

  Untrusted selectors are parsed before the repository is resolved. Only a
  revalidated `%Forensics.Scope{}` can dispatch to one authoritative source.
  """

  import Ecto.Query

  alias ObanPowertools.{Audit, Explain, Lifeline, RuntimeConfig}
  alias ObanPowertools.Forensics.CronHistory
  alias ObanPowertools.Forensics.EvidenceBundle
  alias ObanPowertools.Forensics.LimiterHistory
  alias ObanPowertools.Forensics.RunbookEntry
  alias ObanPowertools.Forensics.Scope
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Web.Selectors
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.Workflow.Workflow
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord

  @unavailable_reason "Evidence unavailable"
  @error_reason "Evidence did not load"
  @audit_limit 50
  @history_limit 8

  @type result ::
          {:ok, map()}
          | {:unavailable, String.t()}
          | {:error, String.t()}

  @doc """
  Builds one bounded evidence bundle from untrusted params or a parsed scope.

  Empty and invalid inputs return before resolving or calling a repository.
  Missing valid subjects use one uniform unavailable result.
  """
  @spec bundle(map(), keyword()) :: result()
  def bundle(params_or_scope, opts \\ [])

  def bundle(%Scope{} = supplied_scope, opts) when is_list(opts) do
    supplied_scope
    |> Scope.canonical_params()
    |> Scope.parse()
    |> case do
      {:ok, ^supplied_scope, _canonical} -> dispatch(supplied_scope, opts)
      _invalid -> {:unavailable, "Choose one evidence type"}
    end
  end

  def bundle(params, opts) when is_map(params) and is_list(opts) do
    case Scope.parse(params) do
      {:ok, scope, _canonical} -> dispatch(scope, opts)
      {:empty, _canonical, notice} -> {:unavailable, notice}
      {:invalid, _canonical, notice} -> {:unavailable, notice}
    end
  end

  def bundle(_params, _opts), do: {:unavailable, "Choose one evidence type"}

  @doc """
  Preserves the historical six-field selector projection for callers that are
  migrating to `Scope.parse/1`.
  """
  def selectors(params) when is_map(params) do
    %{
      resource_type: selector(params, :resource_type),
      resource_id: selector(params, :resource_id),
      workflow_id: selector(params, :workflow_id),
      step: selector(params, :step),
      incident_fingerprint: selector(params, :incident_fingerprint),
      view: selector(params, :view)
    }
  end

  def selectors(_params), do: selectors(%{})

  def workflow_bundle(repo, %Scope{kind: :workflow} = scope) do
    case repo.get(WorkflowRecord, scope.workflow_id) do
      nil ->
        {:unavailable, @unavailable_reason}

      workflow ->
        steps =
          repo.all(
            from(step in Step,
              where: step.workflow_id == ^workflow.id,
              order_by: [asc: step.position]
            )
          )

        selected_step =
          Enum.find(steps, &(&1.step_name == scope.step)) ||
            Enum.find(steps, &(&1.blocker_codes != [])) ||
            List.first(steps)

        workflow_story = Explain.workflow_story(workflow, steps, repo: repo)
        step_story = selected_step && Explain.step_story(selected_step, repo: repo)
        audit_window = Audit.forensic_window(scope, repo: repo)

        native_chronology =
          [
            %{
              occurred_at: workflow.inserted_at,
              label: "Workflow evidence was recorded",
              resource_type: "workflow",
              resource_id: workflow.id,
              source_family: "workflow",
              strength: :durable,
              event_type: "workflow.created",
              status: workflow_status(workflow.state),
              notes: workflow.name
            },
            selected_step &&
              %{
                occurred_at: selected_step.updated_at || selected_step.inserted_at,
                label: "Workflow step diagnosis was recorded",
                resource_type: "workflow_step",
                resource_id: selected_step.id,
                source_family: "workflow",
                strength: :durable,
                event_type: "workflow.step_state",
                status: workflow_status(selected_step.state),
                notes: step_story && step_story.diagnosis
              }
          ]
          |> Enum.reject(&is_nil/1)

        chronology = native_chronology ++ Enum.map(audit_window.events, &audit_item/1)
        completeness = workflow_completeness(chronology, audit_window.events)

        bundle =
          %{
            subject: %{
              type: "workflow",
              id: workflow.id,
              label: workflow.name,
              step: selected_step && selected_step.step_name,
              resource_type: scope.resource_type || selected_resource_type(selected_step),
              resource_id:
                scope.resource_id || selected_resource_id(selected_step) || workflow.id,
              entry_surface: "Powertools-native workflows"
            },
            diagnosis_summary: %{
              title: "Workflow diagnosis",
              current: workflow_story.diagnosis,
              detail:
                (selected_step &&
                   "Selected step #{selected_step.step_name} currently reports #{step_story.diagnosis || "unknown"}.") ||
                  "Workflow diagnosis recomputes from durable state on every request.",
              provenance: :durable
            },
            chronology: chronology,
            related_evidence: [
              %{
                title: "Workflow timeline anchor",
                summary: "Workflow and step state are the primary forensic anchors.",
                provenance: :supporting
              },
              %{
                title: "Audit context",
                summary: "Scoped Audit events remain supporting retained evidence.",
                provenance: :bridge_only
              }
            ],
            linked_resources: [
              %{
                label: "Workflow detail",
                path: workflow_path(workflow, selected_step),
                venue: "Powertools-native"
              },
              %{
                label: "Audit follow-up",
                path: audit_path(selected_step || workflow),
                venue: "Inspection only"
              }
            ],
            legal_next_paths:
              workflow_next_paths(workflow, selected_step, workflow_story, step_story),
            completeness: completeness,
            coverage: workflow_coverage(native_chronology, audit_window, completeness)
          }
          |> EvidenceBundle.build()
          |> enrich_runbook_entry()

        {:ok, bundle}
    end
  end

  def lifeline_bundle(repo, %Scope{kind: :incident} = scope) do
    incident =
      repo.one(
        from(incident in Incident,
          where: incident.incident_fingerprint == ^scope.incident_fingerprint,
          limit: 1
        )
      )

    case incident do
      nil ->
        {:unavailable, @unavailable_reason}

      incident ->
        audit_window = Audit.forensic_window(scope, repo: repo)

        native_chronology = [
          %{
            occurred_at: incident.first_detected_at || incident.inserted_at,
            label: "The Lifeline incident was opened",
            resource_type: "incident",
            resource_id: incident.incident_fingerprint,
            source_family: "lifeline",
            strength: :durable,
            event_type: "lifeline.incident_opened",
            status: incident_status(incident),
            notes: incident.summary
          },
          %{
            occurred_at: incident.last_detected_at || incident.updated_at || incident.inserted_at,
            label: "The latest Lifeline diagnosis was recorded",
            resource_type: "incident",
            resource_id: incident.incident_fingerprint,
            source_family: "lifeline",
            strength: :durable,
            event_type: "lifeline.incident_diagnosis",
            status: incident_status(incident),
            notes: Lifeline.health_label(incident.health_state || "missing")
          }
        ]

        chronology = native_chronology ++ Enum.map(audit_window.events, &audit_item/1)
        resource = lifeline_resource(incident, scope)
        completeness = lifeline_completeness(incident, audit_window.events)

        bundle =
          %{
            subject: %{
              type: "lifeline_incident",
              id: incident.incident_fingerprint,
              label: incident.summary,
              view: scope.view || incident_view(incident),
              resource_type: resource.resource_type,
              resource_id: resource.resource_id,
              entry_surface: "Powertools-native Lifeline"
            },
            diagnosis_summary: %{
              title: "Lifeline diagnosis",
              current: incident.health_state || incident.status,
              detail: "Lifeline is the current authoritative incident evidence source.",
              provenance: :durable
            },
            chronology: chronology,
            related_evidence: [
              %{
                title: "Incident evidence",
                summary: "The retained Lifeline incident is the current durable source.",
                provenance: :durable
              },
              %{
                title: "Audit context",
                summary: "Scoped Audit evidence remains inspection-only history.",
                provenance: :bridge_only
              }
            ],
            linked_resources: [
              %{
                label: "Lifeline detail",
                path: lifeline_path(incident, scope.view),
                venue: "Powertools-native"
              },
              %{
                label: "Audit follow-up",
                path: audit_path(resource),
                venue: "Inspection only"
              }
            ],
            legal_next_paths: [
              %{
                label: "Review incident in Lifeline",
                venue: "Powertools-native",
                path: lifeline_path(incident, scope.view)
              }
            ],
            completeness: completeness,
            coverage: incident_coverage(native_chronology, audit_window, completeness)
          }
          |> EvidenceBundle.build()
          |> enrich_runbook_entry()

        {:ok, bundle}
    end
  end

  defp dispatch(%Scope{} = scope, opts) do
    try do
      repo = RuntimeConfig.repo(opts)

      case scope.kind do
        :workflow ->
          workflow_bundle(repo, scope)

        :incident ->
          lifeline_bundle(repo, scope)

        :cron_entry ->
          source_history_bundle(CronHistory, repo, scope, "cron", "Cron")

        :limiter ->
          source_history_bundle(LimiterHistory, repo, scope, "limiter", "Limiter")
      end
    rescue
      _exception -> {:error, @error_reason}
    end
  end

  defp source_history_bundle(module, repo, scope, source_id, source_label) do
    case module.bundle(repo, scope.resource_id, Map.from_struct(scope)) do
      nil ->
        {:unavailable, @unavailable_reason}

      raw_bundle ->
        source_chronology =
          raw_bundle.chronology
          |> Enum.filter(&(&1.source_family == source_id))
          |> Enum.take(@history_limit)

        completeness = raw_bundle.completeness

        coverage = %{
          shown_count: length(source_chronology),
          total_count: nil,
          has_more?: nil,
          bounded?: true,
          retention: "Up to the newest eight retained #{source_label} facts are shown.",
          sources: [
            %{
              id: source_id,
              label: source_label,
              shown_count: length(source_chronology),
              total_count: nil,
              has_more?: nil,
              limit: @history_limit,
              provenance: :durable,
              completeness: completeness.state,
              retention: "Up to the newest eight retained #{source_label} facts."
            }
          ]
        }

        bundle =
          raw_bundle
          |> Map.put(:chronology, source_chronology)
          |> Map.put(:coverage, coverage)
          |> EvidenceBundle.build()
          |> enrich_runbook_entry()

        {:ok, bundle}
    end
  end

  defp enrich_runbook_entry(bundle) do
    Map.put(bundle, :runbook_entry, RunbookEntry.from_bundle(bundle))
  end

  defp audit_item(event) do
    identity = Audit.event_resource_identity(event)
    stable_id = event.id |> Integer.to_string() |> String.pad_leading(20, "0")

    %{
      id: "forensic-event-audit-#{stable_id}",
      occurred_at: event.inserted_at,
      label: audit_event_sentence(event.event_type),
      resource_type: identity.type,
      resource_id: identity.id,
      source_family: "audit",
      strength: :bridge_only,
      event_type: event.event_type,
      status: audit_event_status(event),
      notes: nil
    }
  end

  defp audit_event_sentence("lifeline.repair_executed"),
    do: "Historical Lifeline repair evidence was recorded"

  defp audit_event_sentence("lifeline.host_follow_up"),
    do: "Historical host follow-up evidence was recorded"

  defp audit_event_sentence("workflow.step_completed"),
    do: "Workflow step completion was recorded"

  defp audit_event_sentence("workflow.step_unblocked"),
    do: "Workflow step recovery was recorded"

  defp audit_event_sentence("workflow.recovery_completed"),
    do: "Workflow recovery was recorded"

  defp audit_event_sentence("workflow.cancel_requested"),
    do: "Workflow cancellation was requested"

  defp audit_event_sentence(_event_type), do: "Retained Audit evidence was recorded"

  defp audit_event_status(%{event_type: "lifeline.repair_executed"} = event) do
    event
    |> Audit.event_attempt_state()
    |> normalize_attempt_status()
  end

  defp audit_event_status(%{event_type: "workflow.step_completed"}), do: :succeeded
  defp audit_event_status(%{event_type: "workflow.step_unblocked"}), do: :runnable
  defp audit_event_status(%{event_type: "workflow.recovery_completed"}), do: :succeeded
  defp audit_event_status(%{event_type: "workflow.cancel_requested"}), do: :waiting
  defp audit_event_status(_event), do: :recorded

  defp normalize_attempt_status(status)
       when status in ~w(previewed attempted succeeded drifted expired consumed),
       do: String.to_existing_atom(status)

  defp normalize_attempt_status(_status), do: :unknown

  defp workflow_coverage(native, audit, completeness) do
    audit_completeness =
      cond do
        audit.has_more? -> :partial_evidence
        audit.shown_count == 0 -> :history_unavailable
        true -> :complete
      end

    %{
      shown_count: length(native) + audit.shown_count,
      total_count: length(native) + audit.total_count,
      has_more?: audit.has_more?,
      bounded?: true,
      retention: "The current workflow facts and newest retained Audit evidence are shown.",
      sources: [
        %{
          id: "workflow",
          label: "Workflow",
          shown_count: length(native),
          total_count: length(native),
          has_more?: false,
          limit: length(native),
          provenance: :durable,
          completeness: :complete,
          retention: "Current durable workflow and selected-step evidence."
        },
        %{
          id: "audit",
          label: "Audit",
          shown_count: audit.shown_count,
          total_count: audit.total_count,
          has_more?: audit.has_more?,
          limit: @audit_limit,
          provenance: :bridge_only,
          completeness: audit_completeness,
          retention: "Newest retained Audit evidence for this workflow scope."
        }
      ],
      completeness: completeness.state
    }
  end

  defp incident_coverage(native, audit, completeness) do
    audit_completeness =
      cond do
        audit.has_more? -> :partial_evidence
        audit.shown_count == 0 -> :history_unavailable
        true -> :unknown
      end

    %{
      shown_count: length(native) + audit.shown_count,
      total_count: nil,
      has_more?: audit.has_more?,
      bounded?: true,
      retention: "The current incident facts and newest retained Audit evidence are shown.",
      sources: [
        %{
          id: "lifeline",
          label: "Lifeline",
          shown_count: length(native),
          total_count: length(native),
          has_more?: false,
          limit: length(native),
          provenance: :durable,
          completeness: :complete,
          retention: "Current retained Lifeline incident evidence."
        },
        %{
          id: "audit",
          label: "Audit",
          shown_count: audit.shown_count,
          total_count: nil,
          has_more?: audit.has_more?,
          limit: @audit_limit,
          provenance: :bridge_only,
          completeness: audit_completeness,
          retention: "Newest retained Audit evidence for this incident scope."
        }
      ],
      completeness: completeness.state
    }
  end

  defp workflow_completeness(chronology, audit_events) do
    cond do
      chronology == [] ->
        %{state: :unknown, details: "No workflow chronology could be reconstructed."}

      audit_events == [] ->
        %{
          state: :partial_evidence,
          details: "Workflow diagnosis is available, but scoped Audit history is not retained."
        }

      true ->
        %{state: :complete, details: "Workflow and scoped Audit evidence are available."}
    end
  end

  defp lifeline_completeness(incident, audit_events) do
    cond do
      incident.status == "resolved" and audit_events == [] ->
        %{
          state: :history_unavailable,
          details: "The incident resolved without matching retained Audit history."
        }

      audit_events == [] ->
        %{
          state: :partial_evidence,
          details: "The Lifeline incident is available, but linked Audit history is incomplete."
        }

      true ->
        %{state: :complete, details: "Lifeline and scoped Audit evidence are available."}
    end
  end

  defp workflow_next_paths(workflow, selected_step, workflow_story, step_story) do
    [
      %{
        label: "Return to workflow diagnosis",
        venue: "Powertools-native",
        path: workflow_path(workflow, selected_step)
      }
      | lifeline_path_from_story(workflow, selected_step, workflow_story, step_story)
    ]
  end

  defp lifeline_path_from_story(workflow, selected_step, workflow_story, step_story) do
    actions =
      ((step_story && step_story.executable_actions) || []) ++ workflow_story.executable_actions

    case List.first(actions) do
      nil ->
        []

      action ->
        [
          %{
            label: action.label,
            venue: "Powertools-native Lifeline",
            path:
              Selectors.lifeline_path([
                {"workflow_id", workflow.id},
                {"step", selected_step && selected_step.step_name},
                {"action", action.id}
              ])
          }
        ]
    end
  end

  defp workflow_path(workflow, nil), do: "/ops/jobs/workflows/#{workflow.id}"

  defp workflow_path(workflow, step),
    do: "/ops/jobs/workflows/#{workflow.id}?step=#{URI.encode_www_form(step.step_name)}"

  defp lifeline_path(incident, view) do
    Selectors.lifeline_path([
      {"incident_fingerprint", incident.incident_fingerprint},
      {"view", view || incident_view(incident)}
    ])
  end

  defp incident_view(%Incident{status: "resolved"}), do: "resolved"
  defp incident_view(_incident), do: "active"

  defp audit_path(%Step{} = step),
    do:
      Selectors.audit_path([
        {"resource_type", "workflow_step"},
        {"resource_id", to_string(step.id)}
      ])

  defp audit_path(%Workflow{} = workflow),
    do:
      Selectors.audit_path([
        {"resource_type", "workflow"},
        {"resource_id", to_string(workflow.id)}
      ])

  defp audit_path(%{resource_type: type, resource_id: id})
       when not is_nil(type) and not is_nil(id) do
    Selectors.audit_path([{"resource_type", to_string(type)}, {"resource_id", to_string(id)}])
  end

  defp audit_path(_resource), do: Selectors.audit_path([])

  defp lifeline_resource(incident, scope) do
    cond do
      scope.resource_type && scope.resource_id ->
        %{resource_type: scope.resource_type, resource_id: scope.resource_id}

      incident.workflow_step_id ->
        %{resource_type: "workflow_step", resource_id: to_string(incident.workflow_step_id)}

      incident.workflow_id ->
        %{resource_type: "workflow", resource_id: to_string(incident.workflow_id)}

      true ->
        job_id = incident.evidence |> Kernel.||(%{}) |> Map.get("job_ids", []) |> List.first()
        %{resource_type: "job", resource_id: job_id && to_string(job_id)}
    end
  end

  defp workflow_status(state) when state in ["completed", "succeeded"], do: :succeeded
  defp workflow_status(state) when state in ["cancelled", "discarded", "failed"], do: :blocked
  defp workflow_status(state) when state in ["available", "executing"], do: :runnable
  defp workflow_status(state) when state in ["pending", "scheduled"], do: :waiting
  defp workflow_status(_state), do: :unknown

  defp incident_status(%Incident{status: "resolved"}), do: :resolved
  defp incident_status(%Incident{health_state: "healthy"}), do: :runnable
  defp incident_status(%Incident{health_state: "missing"}), do: :blocked
  defp incident_status(_incident), do: :needs_review

  defp selected_resource_type(nil), do: "workflow"
  defp selected_resource_type(_step), do: "workflow_step"

  defp selected_resource_id(nil), do: nil
  defp selected_resource_id(step), do: to_string(step.id)

  defp selector(params, key) do
    params
    |> Map.get(key, Map.get(params, Atom.to_string(key)))
    |> blank_to_nil()
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    if String.trim(value) == "", do: nil, else: value
  end

  defp blank_to_nil(value), do: to_string(value)
end
