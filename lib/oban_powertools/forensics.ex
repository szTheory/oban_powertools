defmodule ObanPowertools.Forensics do
  import Ecto.Query

  alias ObanPowertools.{Audit, Explain, Lifeline}
  alias ObanPowertools.Web.Selectors
  alias ObanPowertools.Forensics.CronHistory
  alias ObanPowertools.Forensics.EvidenceBundle
  alias ObanPowertools.Forensics.LimiterHistory
  alias ObanPowertools.Forensics.RunbookEntry
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.Workflow.Workflow
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord

  def bundle(params, opts \\ []) when is_map(params) do
    repo = Keyword.get(opts, :repo, Application.fetch_env!(:oban_powertools, :repo))
    selectors = selectors(params)

    cond do
      selectors.workflow_id ->
        workflow_bundle(repo, selectors)

      selectors.incident_fingerprint ->
        lifeline_bundle(repo, selectors)

      selectors.resource_type == "cron_entry" and selectors.resource_id ->
        CronHistory.bundle(repo, selectors.resource_id, selectors) || unknown_bundle(selectors)

      selectors.resource_type == "limiter" and selectors.resource_id ->
        LimiterHistory.bundle(repo, selectors.resource_id, selectors) || unknown_bundle(selectors)

      true ->
        unknown_bundle(selectors)
    end
  end

  def selectors(params) do
    %{
      resource_type: blank_to_nil(params[:resource_type] || params["resource_type"]),
      resource_id: blank_to_nil(params[:resource_id] || params["resource_id"]),
      workflow_id: blank_to_nil(params[:workflow_id] || params["workflow_id"]),
      step: blank_to_nil(params[:step] || params["step"]),
      incident_fingerprint:
        blank_to_nil(params[:incident_fingerprint] || params["incident_fingerprint"]),
      view: blank_to_nil(params[:view] || params["view"])
    }
  end

  def workflow_bundle(repo, selectors) do
    workflow = repo.get(WorkflowRecord, selectors.workflow_id)

    if workflow do
      steps =
        repo.all(
          from(step in Step,
            where: step.workflow_id == ^workflow.id,
            order_by: [asc: step.position]
          )
        )

      selected_step =
        Enum.find(steps, &(&1.step_name == selectors.step)) ||
          Enum.find(steps, &(&1.blocker_codes != [])) ||
          List.first(steps)

      workflow_story = Explain.workflow_story(workflow, steps, repo: repo)
      step_story = selected_step && Explain.step_story(selected_step, repo: repo)
      audit_events = workflow_audit_events(repo, workflow, selected_step)

      chronology =
        [
          %{
            occurred_at: workflow.inserted_at,
            label: "Workflow recorded",
            resource_type: "workflow",
            resource_id: workflow.id,
            source_family: "workflow",
            strength: :durable,
            event_type: "workflow.created",
            notes: workflow.name
          },
          selected_step &&
            %{
              occurred_at: selected_step.updated_at || selected_step.inserted_at,
              label: "Step diagnosis: #{selected_step.step_name}",
              resource_type: "workflow_step",
              resource_id: selected_step.id,
              source_family: "workflow",
              strength: :durable,
              event_type: "workflow.step_state",
              notes: step_story && step_story.diagnosis
            }
        ]
        |> Enum.reject(&is_nil/1)
        |> Kernel.++(Enum.map(audit_events, &audit_item/1))

      %{
        subject: %{
          type: "workflow",
          id: workflow.id,
          label: workflow.name,
          step: selected_step && selected_step.step_name,
          resource_type: selectors.resource_type || selected_resource_type(selected_step),
          resource_id: selectors.resource_id || selected_resource_id(selected_step),
          entry_surface: "Powertools-native workflows"
        },
        diagnosis_summary: %{
          title: "Workflow diagnosis",
          current: workflow_story.diagnosis,
          detail:
            (selected_step &&
               "Selected step #{selected_step.step_name} currently reports #{step_story.diagnosis || "unknown"}.") ||
              "Workflow diagnosis recomputes from durable state on every mount.",
          provenance: :durable
        },
        chronology: chronology,
        related_evidence: [
          %{
            title: "Workflow timeline anchor",
            summary: "Workflow and step state are the primary forensic anchors in Phase 32.",
            provenance: :durable
          },
          %{
            title: "Limiter and cron context",
            summary:
              "Limiter and cron facts remain supporting evidence until Phase 33 closes their history semantics.",
            provenance: :supporting
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
        completeness: workflow_completeness(chronology, audit_events)
      }
      |> EvidenceBundle.build()
      |> enrich_runbook_entry()
    else
      unknown_bundle(selectors)
    end
  end

  def lifeline_bundle(repo, selectors) do
    incident =
      repo.one(
        from(incident in Incident,
          where: incident.incident_fingerprint == ^selectors.incident_fingerprint,
          limit: 1
        )
      )

    if incident do
      audit_events = incident_audit_events(repo, incident)
      continuity = latest_native_remediation_continuity(audit_events)

      chronology =
        [
          %{
            occurred_at: incident.first_detected_at || incident.inserted_at,
            label: "Incident opened",
            resource_type: "incident",
            resource_id: incident.incident_fingerprint,
            source_family: "lifeline",
            strength: :durable,
            event_type: "lifeline.incident_opened",
            notes: incident.summary
          },
          %{
            occurred_at: incident.last_detected_at || incident.updated_at || incident.inserted_at,
            label: "Latest incident diagnosis",
            resource_type: "incident",
            resource_id: incident.incident_fingerprint,
            source_family: "lifeline",
            strength: :durable,
            event_type: "lifeline.incident_diagnosis",
            notes: Lifeline.health_label(incident.health_state || "missing")
          }
        ]
        |> Kernel.++(Enum.map(audit_events, &audit_item/1))

      resource = lifeline_resource(incident, selectors)

      subject =
        %{
          type: "lifeline_incident",
          id: incident.incident_fingerprint,
          label: incident.summary,
          view: selectors.view || incident_view(incident),
          resource_type: resource.resource_type,
          resource_id: resource.resource_id,
          entry_surface: "Powertools-native Lifeline"
        }
        |> maybe_put_continuity(continuity)

      %{
        subject: subject,
        diagnosis_summary: %{
          title: "Lifeline diagnosis",
          current: incident.health_state || incident.status,
          detail: "Lifeline remains a first-class investigative home for incident evidence.",
          provenance: :durable
        },
        chronology: chronology,
        related_evidence: [
          %{
            title: "Incident evidence",
            summary:
              "This bundle preserves the Lifeline incident story and any linked audit evidence.",
            provenance: :durable
          },
          %{
            title: "Bridge posture",
            summary: "Audit remains Inspection only for scoped follow-up evidence.",
            provenance: :bridge_only
          }
        ],
        linked_resources: [
          %{
            label: "Lifeline detail",
            path: lifeline_path(incident, selectors.view),
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
            path: lifeline_path(incident, selectors.view)
          }
        ],
        completeness: lifeline_completeness(incident, audit_events)
      }
      |> EvidenceBundle.build()
      |> enrich_runbook_entry()
    else
      unknown_bundle(selectors)
    end
  end

  defp unknown_bundle(selectors) do
    %{
      subject: %{
        type: "unknown",
        id: "unknown",
        label: "Unknown forensic scope",
        entry_surface: "unknown"
      },
      diagnosis_summary: %{
        title: "Unknown diagnosis",
        current: "unknown",
        detail:
          "No durable workflow or Lifeline selector was available for this forensic request.",
        provenance: :missing
      },
      chronology: [],
      related_evidence: [],
      linked_resources: [],
      legal_next_paths: [],
      completeness: %{
        state: :unknown,
        details:
          "unknown: provide workflow_id, incident_fingerprint, or a supported resource_type/resource_id forensic selector.",
        selectors: selectors
      }
    }
    |> EvidenceBundle.build()
    |> enrich_runbook_entry()
  end

  defp enrich_runbook_entry(bundle) do
    Map.put(bundle, :runbook_entry, RunbookEntry.from_bundle(bundle))
  end

  defp workflow_audit_events(repo, workflow, selected_step) do
    Audit.list_all(repo: repo)
    |> Enum.filter(fn event ->
      workflow_hit =
        event.resource_type == "workflow" and
          to_string(event.resource_id) == to_string(workflow.id)

      step_hit =
        (selected_step &&
           event.resource_type == "workflow_step") and
          to_string(event.resource_id) == to_string(selected_step.id)

      workflow_hit or step_hit
    end)
  end

  defp incident_audit_events(repo, incident) do
    Audit.list_all(repo: repo)
    |> Enum.filter(fn event ->
      event.metadata["incident_fingerprint"] == incident.incident_fingerprint
    end)
  end

  defp audit_item(event) do
    identity = Audit.event_resource_identity(event)
    runbook_context = Audit.event_runbook_context(event)

    %{
      occurred_at: event.inserted_at,
      label: Audit.event_label(event),
      resource_type: identity.type,
      resource_id: identity.id,
      source_family: "audit",
      strength: :bridge_only,
      event_type: event.event_type,
      notes: Audit.event_reason(event),
      reason: Audit.event_reason(event),
      action: event.action,
      attempt_state: Audit.event_attempt_state(event),
      selected_path: Audit.event_selected_path(event),
      runbook_context: runbook_context
    }
  end

  defp latest_native_remediation_continuity(audit_events) do
    audit_events
    |> Enum.filter(fn event ->
      (event.event_type || event.action) == "lifeline.repair_executed"
    end)
    |> Enum.sort_by(
      fn event -> {event.inserted_at || ~N[1970-01-01 00:00:00], event.id || 0} end,
      :desc
    )
    |> Enum.find(&is_map(Audit.event_runbook_context(&1)))
    |> case do
      nil ->
        nil

      event ->
        runbook_context = Audit.event_runbook_context(event)
        attempt = get_in(runbook_context, ["attempt"]) || %{}
        preview_token = get_in(runbook_context, ["preview_token"])
        host_follow_up_event = latest_host_follow_up_event(audit_events, preview_token)

        %{
          "attempt_state" => Audit.event_attempt_state(event),
          "action" => attempt["action"] || event.action,
          "reason" => Audit.event_reason(event),
          "selected_path" => Audit.event_selected_path(event),
          "runbook_context" => runbook_context,
          "host_follow_up_status" => host_follow_up_status(host_follow_up_event),
          "host_follow_up_details" => host_follow_up_details(host_follow_up_event)
        }
    end
  end

  defp latest_host_follow_up_event(audit_events, preview_token) do
    audit_events
    |> Enum.filter(fn event -> (event.event_type || event.action) == "lifeline.host_follow_up" end)
    |> Enum.sort_by(
      fn event -> {event.inserted_at || ~N[1970-01-01 00:00:00], event.id || 0} end,
      :desc
    )
    |> Enum.find(fn event ->
      is_nil(preview_token) or event.metadata["preview_token"] == preview_token
    end)
  end

  defp host_follow_up_status(nil), do: "host_owned_follow_up_unconfigured"
  defp host_follow_up_status(event), do: event.metadata["status"] || "host_owned_follow_up_unconfigured"

  defp host_follow_up_details(nil), do: %{"configuration" => "No host escalation hook configured"}
  defp host_follow_up_details(event), do: event.metadata["details"] || %{}

  defp maybe_put_continuity(subject, nil), do: subject
  defp maybe_put_continuity(subject, continuity), do: Map.put(subject, :continuity, continuity)

  defp workflow_completeness(chronology, audit_events) do
    cond do
      chronology == [] ->
        %{state: :unknown, details: "unknown: no workflow chronology could be reconstructed."}

      audit_events == [] ->
        %{
          state: :partial_evidence,
          details:
            "partial evidence: workflow diagnosis is available, but scoped audit history is not yet present."
        }

      true ->
        %{state: :complete, details: "Complete forensic bundle from workflow and audit evidence."}
    end
  end

  defp lifeline_completeness(incident, audit_events) do
    cond do
      incident.status == "resolved" and audit_events == [] ->
        %{
          state: :history_unavailable,
          details:
            "history unavailable: the incident resolved without matching retained audit history."
        }

      audit_events == [] ->
        %{
          state: :partial_evidence,
          details:
            "partial evidence: the Lifeline incident is available, but linked audit follow-up is incomplete."
        }

      true ->
        %{state: :complete, details: "Complete forensic bundle from Lifeline and audit evidence."}
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
    do: Selectors.audit_path([{"resource_type", "workflow_step"}, {"resource_id", to_string(step.id)}])

  defp audit_path(%Workflow{} = workflow),
    do: Selectors.audit_path([{"resource_type", "workflow"}, {"resource_id", to_string(workflow.id)}])

  defp audit_path(%{resource_type: type, resource_id: id})
       when not is_nil(type) and not is_nil(id) do
    Selectors.audit_path([{"resource_type", to_string(type)}, {"resource_id", to_string(id)}])
  end

  defp audit_path(%{type: type, id: id}) do
    Selectors.audit_path([{"resource_type", to_string(type)}, {"resource_id", to_string(id)}])
  end

  defp lifeline_resource(incident, selectors) do
    cond do
      selectors.resource_type && selectors.resource_id ->
        %{resource_type: selectors.resource_type, resource_id: selectors.resource_id}

      incident.workflow_step_id ->
        %{resource_type: "workflow_step", resource_id: to_string(incident.workflow_step_id)}

      incident.workflow_id ->
        %{resource_type: "workflow", resource_id: to_string(incident.workflow_id)}

      true ->
        job_ids = Map.get(incident.evidence || %{}, "job_ids", [])
        %{resource_type: "job", resource_id: job_ids |> List.first() |> to_string()}
    end
  end

  defp selected_resource_type(nil), do: "workflow"
  defp selected_resource_type(_step), do: "workflow_step"

  defp selected_resource_id(nil), do: nil
  defp selected_resource_id(step), do: to_string(step.id)

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: to_string(value)
end
