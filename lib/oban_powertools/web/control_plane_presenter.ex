defmodule ObanPowertools.Web.ControlPlanePresenter do
  @moduledoc """
  Shared control-plane labels, ownership copy, and venue-aware wording.
  """

  alias ObanPowertools.{Audit, ControlPlane, DisplayPolicy, RuntimeConfig}
  alias ObanPowertools.Forensics.Chronology
  alias ObanPowertools.Lifeline.{ArchiveRun, Incident, RepairPreview}
  alias ObanPowertools.Web.{Selectors, StatusTaxonomy}

  @workflow_scan_limit 50
  @workflow_step_limit 100
  @workflow_result_limit 50
  @workflow_evidence_limit 25
  @batch_member_limit 50
  @batch_callback_limit 25
  @batch_result_limit 50
  @batch_audit_limit 25
  @incident_limit 50
  @executor_limit 25
  @lifeline_audit_limit 50
  @archive_limit 25

  @batch_states ~w[
    inserting executing exhausted insert_failed callback_failed completed
  ]
  @batch_member_states ~w[
    available scheduled executing retryable cancelled discarded completed failed unknown
  ]
  @callback_states ~w[pending claimed delivered failed lease_expired unknown]
  @repair_states ~w[
    preview partial skipped failed drifted expired consumed disconnected interrupted success
  ]
  @lifeline_result_states %{
    "preview" => :preview,
    "partial" => :partial,
    "skipped" => :skipped,
    "failed" => :failed,
    "drifted" => :drifted,
    "expired" => :expired,
    "consumed" => :consumed,
    "disconnected" => :disconnected,
    "interrupted" => :interrupted,
    "success" => :success
  }
  @lifeline_incident_states %{
    "active" => :active,
    "blocked" => :blocked,
    "completed" => :completed,
    "failed" => :failed,
    "pending" => :pending,
    "resolved" => :resolved,
    "running" => :running
  }
  @lifeline_health_states %{
    "healthy" => :healthy,
    "late" => :late,
    "missing" => :missing
  }
  @workflow_states ~w[
    available scheduled executing retryable pending blocked cancelled discarded completed failed
    waiting runnable resolved needs_review unknown
  ]

  @status_labels %{
    needs_review: "Needs Review",
    blocked: "Blocked",
    waiting: "Waiting",
    runnable: "Runnable",
    resolved: "Resolved",
    bridge_only: "Bridge-only Follow-up"
  }

  @operator_result_states %{
    "success" => :success,
    "failed" => :failed,
    "skipped" => :skipped
  }
  @audit_outcome_states Map.put(@operator_result_states, "unknown", :unknown)
  @overview_kinds %{
    "needs_review" => :needs_review,
    "blocked" => :blocked,
    "waiting" => :waiting,
    "bridge_only" => :bridge_only,
    "runnable" => :runnable,
    "resolved_continuity" => :resolved_continuity
  }
  @overview_domains %{"overview" => :overview}
  @overview_severities %{
    "neutral" => :neutral,
    "info" => :info,
    "warning" => :warning,
    "danger" => :danger
  }
  @overview_ownerships %{
    "powertools_native" => :powertools_native,
    "Powertools-native" => :powertools_native,
    "oban_web_bridge" => :oban_web_bridge,
    "Oban Web bridge" => :oban_web_bridge,
    "host_owned" => :host_owned,
    "Host-owned" => :host_owned
  }
  @overview_statuses Map.merge(@overview_kinds, %{"resolved" => :resolved})
  @cron_action_kinds %{
    "pause" => :pause,
    "pause_cron_entry" => :pause,
    "resume" => :resume,
    "resume_cron_entry" => :resume,
    "run_now" => :run_now,
    "run_cron_entry_now" => :run_now
  }
  @cron_result_states %{
    "success" => :success,
    "skipped" => :skipped,
    "duplicate" => :duplicate,
    "partial" => :partial,
    "failed" => :failed,
    "expired" => :expired,
    "drifted" => :drifted,
    "consumed" => :consumed
  }
  @job_states %{
    "available" => "Available",
    "scheduled" => "Scheduled",
    "executing" => "Executing",
    "retryable" => "Retryable",
    "cancelled" => "Cancelled",
    "discarded" => "Discarded",
    "completed" => "Completed"
  }
  @job_action_kinds %{
    "retry" => :retry,
    "cancel" => :cancel,
    "discard" => :discard
  }
  @job_result_states %{
    "success" => :success,
    "skipped" => :skipped,
    "failed" => :failed,
    "expired" => :expired,
    "drifted" => :drifted,
    "consumed" => :consumed
  }
  @job_error_limit 10
  @job_error_text_limit 1_000
  @audit_event_labels %{
    "cron.missed_fire" => "Missed schedule recorded",
    "cron.paused" => "Cron entry paused",
    "cron.previewed" => "Cron action previewed",
    "cron.reconfigured" => "Cron entry reconfigured",
    "cron.snapshot" => "Cron snapshot recorded",
    "lifeline.host_follow_up" => "Host follow-up recorded",
    "lifeline.incident_diagnosis" => "Incident diagnosis recorded",
    "lifeline.incident_opened" => "Incident opened",
    "lifeline.repair_executed" => "Repair executed",
    "lifeline.repair_requested" => "Repair requested",
    "limiter.blocked" => "Limiter blocked",
    "limiter.cooled_down" => "Limiter cooled down",
    "limiter.reconfigured" => "Limiter reconfigured",
    "limiter.released" => "Limiter released",
    "oban_web.inspection" => "Oban Web inspection recorded",
    "workflow.created" => "Workflow created",
    "workflow.step_completed" => "Workflow step completed",
    "workflow.step_state" => "Workflow step state recorded"
  }
  @blocker_evidence_kinds %{
    "current" => :current,
    "block_start_snapshot" => :block_start_snapshot
  }
  @evidence_completeness %{
    "complete" => :complete,
    "partial" => :partial,
    "unknown" => :unknown,
    "unavailable" => :unavailable
  }
  @sensitive_presentation_source_field_names ~w[
    api_key apikey access_key private_key secret_key client_secret client_id_secret
    access_token refresh_token id_token auth_token bearer_token authorization
    password passwd pwd credential credentials signing_key encryption_key
  ]
  @sensitive_presentation_source_field_components ~w[
    token hash error authorization password passwd pwd secret credential credentials exception
    stacktrace
  ]
  @audit_presentation_data_fields ~w[
    field before after label value items
  ]
  @forensic_scope_types %{
    "workflow" => {:workflow, "Workflow"},
    "lifeline_incident" => {:lifeline_incident, "Lifeline incident"},
    "cron_entry" => {:cron_entry, "Cron entry"},
    "limiter" => {:limiter, "Limiter"}
  }
  @forensic_sources %{
    "workflow" => "Workflow",
    "lifeline" => "Lifeline",
    "cron" => "Cron",
    "limiter" => "Limiter",
    "audit" => "Audit"
  }
  @forensic_statuses ~w[
    available scheduled executing retryable cancelled discarded completed
    needs_review blocked waiting runnable resolved success succeeded skipped failed
    previewed attempted drifted expired consumed recorded on_time manual_run
    partial_evidence unknown
  ]a
  @forensic_destination_queries %{
    workflow: ~w[step],
    lifeline: ~w[
      resource_type resource_id workflow_id step incident_fingerprint view action
    ],
    cron: ~w[entry],
    limiter: ~w[resource],
    audit: ~w[resource_type resource_id page event event_type]
  }
  @forensic_note_limit 1_000

  @doc """
  Projects one authorized batch list row into a finite presentation map.

  The context supplies navigation destinations and observation time. Domain
  structs, callback payloads, job args, and mutation authority are deliberately
  excluded from the result.
  """
  def present_batch_row(batch, context) when is_map(batch) and is_map(context) do
    progress = batch_progress(presentation_value(batch, :progress))

    %{
      id: presentation_text(presentation_value(batch, :id), "Unavailable"),
      name: batch_name(batch),
      status: finite_state(presentation_value(batch, :status), @batch_states),
      progress: progress,
      failed_count: nonnegative(presentation_value(batch, :failed_count)),
      retryable_failed_count: nonnegative(presentation_value(batch, :retryable_failed_count)),
      callback_summary: batch_callback_summary(presentation_value(batch, :callback_summary)),
      chain?: presentation_value(batch, :chain?) == true,
      blocked_state: batch_blocked_state(presentation_value(batch, :blocked_state)),
      updated_at: safe_time(presentation_value(batch, :updated_at)),
      detail_href:
        authorized_destination(
          presentation_value(context, :detail_href) ||
            Selectors.batch_detail_path(presentation_value(batch, :id)),
          context
        )
    }
  end

  def present_batch_row(_batch, _context),
    do: raise(ArgumentError, "batch row source and context must be maps")

  @doc """
  Projects an authorized batch detail and applies every finite render cap.
  """
  def present_batch_detail(detail, context) when is_map(detail) and is_map(context) do
    members =
      detail
      |> presentation_value(:failed_members)
      |> bounded_collection(@batch_member_limit, &present_batch_member/1)

    callbacks =
      detail
      |> presentation_value(:callbacks)
      |> bounded_collection(@batch_callback_limit, &present_batch_callback/1)

    results =
      detail
      |> presentation_value(:results)
      |> bounded_collection(@batch_result_limit, &present_batch_result/1)

    audit =
      detail
      |> presentation_value(:audit_events)
      |> bounded_collection(@batch_audit_limit, &present_batch_audit/1)

    %{
      id: presentation_text(presentation_value(detail, :id), "Unavailable"),
      name: batch_name(detail),
      status: finite_state(presentation_value(detail, :status), @batch_states),
      progress: batch_progress(presentation_value(detail, :progress)),
      blocked_state: batch_blocked_state(presentation_value(detail, :blocked_state)),
      failed_members: members.items,
      callbacks: callbacks.items,
      results: results.items,
      audit_events: audit.items,
      member_evidence: completeness(members, "members"),
      callback_evidence: completeness(callbacks, "callbacks"),
      result_evidence: completeness(results, "results"),
      audit_evidence: completeness(audit, "audit entries"),
      callback_summary: batch_callback_summary(presentation_value(detail, :callback_summary)),
      chain_context: batch_chain_context(presentation_value(detail, :chain_context)),
      inserted_at: safe_time(presentation_value(detail, :inserted_at)),
      updated_at: safe_time(presentation_value(detail, :updated_at)),
      completed_at: safe_time(presentation_value(detail, :completed_at)),
      back_href: authorized_destination(presentation_value(context, :back_href), context)
    }
  end

  def present_batch_detail(_detail, _context),
    do: raise(ArgumentError, "batch detail source and context must be maps")

  @doc """
  Converts a parent-owned retry preview into consequence-only confirmation copy.
  """
  def present_batch_retry_preview(preview, context)
      when is_map(preview) and is_map(context) do
    state = finite_state(presentation_value(preview, :status), @repair_states)
    count = nonnegative(presentation_value(context, :selected_count))

    noun =
      context
      |> presentation_value(:object_noun)
      |> Kernel.||("failed job")
      |> presentation_text("failed job")

    plural_noun = "#{noun}#{if(count == 1, do: "", else: "s")}"

    %{
      state: state,
      title: "Retry #{plural_noun}",
      object_label: presentation_text(presentation_value(context, :object_label), "Batch"),
      scope: "#{count} currently eligible #{plural_noun}",
      consequence:
        "Lifeline will revalidate each selected #{noun} immediately before attempting retry.",
      reversibility:
        "Accepted retries cannot be recalled; changed or ineligible jobs are skipped and reported.",
      support_boundary:
        "This preview is not authorization and does not prove that retried jobs will complete.",
      action: finite_text(presentation_value(preview, :action), "job_retry")
    }
  end

  def present_batch_retry_preview(_preview, _context),
    do: raise(ArgumentError, "batch retry preview source and context must be maps")

  @doc "Projects an authorized workflow scan row into a closed finite map."
  def present_workflow_row(value, context) when is_map(value) and is_map(context) do
    context = Map.put_new(context, :render_limit, @workflow_scan_limit)

    %{
      id: presentation_text(presentation_value(value, :id), "Unavailable"),
      name: presentation_text(presentation_value(value, :name), "Unnamed workflow"),
      status:
        finite_state(
          presentation_value(value, :status) || presentation_value(value, :state),
          @workflow_states
        ),
      step_count: nonnegative(presentation_value(value, :step_count)),
      runnable_step_count: nonnegative(presentation_value(value, :runnable_step_count)),
      completed_step_count: nonnegative(presentation_value(value, :completed_step_count)),
      detail_href:
        authorized_destination(
          presentation_value(context, :detail_href) ||
            Selectors.workflow_detail_path(presentation_value(value, :id)),
          context
        )
    }
  end

  def present_workflow_row(_value, _context),
    do: raise(ArgumentError, "workflow row source and context must be maps")

  @doc "Projects workflow diagnosis and applies all finite evidence windows."
  def present_workflow_detail(value, context) when is_map(value) and is_map(context) do
    steps =
      value
      |> presentation_value(:steps)
      |> bounded_collection(@workflow_step_limit, fn step ->
        present_workflow_step(step, context)
      end)

    results =
      value
      |> presentation_value(:results)
      |> bounded_collection(@workflow_result_limit, &present_workflow_result/1)

    evidence =
      value
      |> presentation_value(:evidence)
      |> bounded_collection(@workflow_evidence_limit, &present_workflow_evidence/1)

    %{
      id: presentation_text(presentation_value(value, :id), "Unavailable"),
      name: presentation_text(presentation_value(value, :name), "Unnamed workflow"),
      status:
        finite_state(
          presentation_value(value, :status) || presentation_value(value, :state),
          @workflow_states
        ),
      diagnosis:
        presentation_text(presentation_value(value, :diagnosis), "Diagnosis unavailable."),
      semantics: workflow_semantics(presentation_value(value, :semantics)),
      callback_posture: workflow_callback_posture(presentation_value(value, :callback_posture)),
      latest_recovery_session: safe_scalar(presentation_value(value, :latest_recovery_session)),
      refusal: workflow_refusal(presentation_value(value, :rejection_summary)),
      steps: steps.items,
      results: results.items,
      evidence: evidence.items,
      step_evidence: completeness(steps, "workflow steps"),
      result_evidence: completeness(results, "workflow results"),
      diagnostic_evidence: completeness(evidence, "diagnostic evidence")
    }
  end

  def present_workflow_detail(_value, _context),
    do: raise(ArgumentError, "workflow detail source and context must be maps")

  @doc "Projects one semantic workflow step without raw input or context."
  def present_workflow_step(value, context) when is_map(value) and is_map(context) do
    blocker_codes =
      value
      |> presentation_value(:blocker_codes)
      |> case do
        values when is_list(values) -> Enum.map(values, &presentation_text(&1, "unknown"))
        _ -> []
      end

    %{
      id: presentation_text(presentation_value(value, :id), "Unavailable"),
      name:
        presentation_text(
          presentation_value(value, :name) || presentation_value(value, :step_name),
          "Unnamed step"
        ),
      status:
        finite_state(
          presentation_value(value, :status) || presentation_value(value, :state),
          @workflow_states
        ),
      position: nonnegative(presentation_value(value, :position)),
      blocked?: blocker_codes != [],
      blocker_codes: blocker_codes,
      detail_href: authorized_destination(presentation_value(context, :detail_href), context)
    }
  end

  def present_workflow_step(_value, _context),
    do: raise(ArgumentError, "workflow step source and context must be maps")

  @doc "Projects selected-step diagnosis and only pre-authorized destinations."
  def present_workflow_step_detail(value, context, destinations)
      when is_map(value) and is_map(context) and is_map(destinations) do
    %{
      id: presentation_text(presentation_value(value, :id), "Unavailable"),
      name:
        presentation_text(
          presentation_value(value, :name) || presentation_value(value, :step_name),
          "Unnamed step"
        ),
      worker: presentation_text(presentation_value(value, :worker), "Unavailable"),
      status:
        finite_state(
          presentation_value(value, :status) || presentation_value(value, :state),
          @workflow_states
        ),
      diagnosis:
        presentation_text(presentation_value(value, :diagnosis), "Diagnosis unavailable."),
      dependency_labels: workflow_dependency_labels(presentation_value(value, :dependencies)),
      refusal: workflow_refusal(presentation_value(value, :rejection_summary)),
      result: present_workflow_result(presentation_value(value, :result) || %{}),
      lifeline_href:
        authorized_destination(presentation_value(destinations, :lifeline_href), context),
      forensics_href:
        authorized_destination(presentation_value(destinations, :forensics_href), context),
      oban_web_href:
        authorized_destination(presentation_value(destinations, :oban_web_href), context)
    }
  end

  def present_workflow_step_detail(_value, _context, _destinations),
    do:
      raise(ArgumentError, "workflow step detail source, context, and destinations must be maps")

  @doc "Projects bounded Lifeline support counts without claiming complete system health."
  def present_lifeline_summary(value) when is_map(value) and not is_struct(value) do
    status = lifeline_state(presentation_value(value, :status), @lifeline_health_states, :missing)

    %{
      status: status,
      status_spec: StatusTaxonomy.spec(:lifeline_health, status),
      active_count: nonnegative(presentation_value(value, :active_count)),
      resolved_count: nonnegative(presentation_value(value, :resolved_count)),
      pending_preview_count: nonnegative(presentation_value(value, :pending_preview_count)),
      archived_repair_count: nonnegative(presentation_value(value, :archived_repair_count)),
      completeness: lifeline_completeness(presentation_value(value, :completeness))
    }
  end

  def present_lifeline_summary(_value) do
    %{
      status: :missing,
      status_spec: StatusTaxonomy.spec(:lifeline_health, :missing),
      active_count: 0,
      resolved_count: 0,
      pending_preview_count: 0,
      archived_repair_count: 0,
      completeness: :unavailable
    }
  end

  @doc "Projects one authorized typed incident row into an exact non-enumerating map."
  def present_incident_row(%{incident: %Incident{} = incident} = value, context)
      when is_map(context) do
    if presentation_value(context, :authorized?) == false do
      unavailable_incident_row()
    else
      status =
        lifeline_state(
          incident.status,
          @lifeline_incident_states,
          :pending
        )

      health =
        lifeline_state(
          incident.health_state,
          @lifeline_health_states,
          :missing
        )

      %{
        id: presentation_text(presentation_value(value, :id), "incident-unavailable"),
        subject: presentation_text(incident.summary, "Incident unavailable"),
        status: status,
        status_spec: StatusTaxonomy.spec(:lifeline_incident, status),
        severity: StatusTaxonomy.spec(:lifeline_health, health).tone,
        observed_at: safe_time(incident.last_detected_at || incident.first_detected_at),
        affected_scope:
          presentation_text(
            presentation_value(value, :target_summary),
            "Affected scope unavailable"
          ),
        preview_available?: presentation_value(value, :previewable?) == true,
        detail_href: authorized_destination(presentation_value(context, :detail_href), context)
      }
    end
  end

  def present_incident_row(_value, _context), do: unavailable_incident_row()

  @doc "Projects current incident diagnosis separately from bounded historical evidence."
  def present_incident_detail(%{incident: %Incident{} = incident} = value, context)
      when is_map(context) do
    if presentation_value(context, :authorized?) == false do
      unavailable_incident_detail()
    else
      status =
        lifeline_state(
          incident.status,
          @lifeline_incident_states,
          :pending
        )

      history =
        context
        |> presentation_value(:history)
        |> bounded_lifeline_history()

      %{
        id: presentation_text(presentation_value(value, :id), "incident-unavailable"),
        subject: presentation_text(incident.summary, "Incident unavailable"),
        status: status,
        status_spec: StatusTaxonomy.spec(:lifeline_incident, status),
        current_diagnosis:
          presentation_text(
            presentation_value(context, :current_diagnosis),
            "Current diagnosis unavailable."
          ),
        provenance:
          presentation_text(
            presentation_value(context, :provenance),
            "Current retained evidence unavailable."
          ),
        affected_scope:
          presentation_text(
            presentation_value(value, :target_summary),
            "Affected scope unavailable"
          ),
        legal_route: authorized_destination(presentation_value(context, :legal_route), context),
        history: history.items,
        completeness: if(history.has_more?, do: :partial, else: history.completeness)
      }
    end
  end

  def present_incident_detail(_value, _context), do: unavailable_incident_detail()

  @doc "Projects consequence-only repair confirmation while leaving capability identity private."
  def present_repair_confirmation(%RepairPreview{} = value, context, _destinations)
      when is_map(context) do
    preview_state = repair_preview_presentation_state(value.status)

    %{
      state: preview_state,
      status_spec: repair_status_spec(preview_state),
      title: presentation_text(presentation_value(context, :title), "Confirm Lifeline repair"),
      action:
        presentation_text(presentation_value(context, :action_label), "Execute remediation"),
      object_label:
        presentation_text(presentation_value(context, :object_label), "Lifeline incident"),
      observed_at: safe_time(presentation_value(context, :observed_at)),
      observed_state:
        presentation_text(presentation_value(context, :observed_state), "State unavailable"),
      affected_records:
        bounded_lifeline_texts(presentation_value(context, :affected_records), @incident_limit),
      proposed_changes:
        bounded_lifeline_texts(presentation_value(context, :proposed_changes), @incident_limit),
      non_effects:
        bounded_lifeline_texts(presentation_value(context, :non_effects), @incident_limit),
      consequence: "Lifeline revalidates and attempts each eligible target independently.",
      reversibility:
        "Accepted changes may not be reversible; changed or ineligible targets are reported.",
      support_boundary:
        "Execution is per target and non-atomic. It does not guarantee downstream recovery.",
      progress: repair_progress(presentation_value(context, :progress))
    }
  end

  def present_repair_confirmation(_value, _context, _destinations) do
    failed_repair_confirmation()
  end

  @doc "Projects every finite repair outcome without overstating partial work."
  def present_repair_result(value, context)
      when is_map(value) and not is_struct(value) and is_map(context) do
    state = lifeline_result_state(presentation_value(value, :state))
    target_results = bounded_repair_results(presentation_value(value, :target_results))
    clean_success? = state == :success

    %{
      state: state,
      status_spec: repair_status_spec(state),
      message: repair_result_message(state),
      recovery: repair_result_recovery(state),
      target_results: target_results.items,
      completeness: if(target_results.has_more?, do: :partial, else: target_results.completeness),
      audit_href:
        if(clean_success?,
          do: authorized_destination(presentation_value(context, :audit_href), context),
          else: nil
        ),
      receipt:
        if(clean_success?,
          do: "Repair outcome recorded. Audit evidence is available.",
          else: nil
        ),
      requires_fresh_preview?: not clean_success?
    }
  end

  def present_repair_result(_value, _context) do
    %{
      state: :failed,
      status_spec: repair_status_spec(:failed),
      message: repair_result_message(:failed),
      recovery: repair_result_recovery(:failed),
      target_results: [],
      completeness: :unavailable,
      audit_href: nil,
      receipt: nil,
      requires_fresh_preview?: true
    }
  end

  @doc "Projects immutable typed Lifeline Audit evidence through caller-owned safe labels."
  def present_lifeline_audit_entry(%Audit{} = value, context) when is_map(context) do
    %{
      id: to_string(value.id || "audit"),
      event_label:
        Map.get(
          @audit_event_labels,
          value.event_type || value.action,
          "Audit evidence recorded"
        ),
      target_label:
        presentation_text(presentation_value(context, :target_label), "Target unavailable"),
      actor_label:
        presentation_text(presentation_value(context, :actor_label), "Actor unavailable"),
      reason:
        presentation_text(
          presentation_value(context, :safe_reason),
          "No operator reason available."
        ),
      recorded_at: safe_time(value.inserted_at),
      evidence_href: authorized_destination(presentation_value(context, :evidence_href), context)
    }
  end

  def present_lifeline_audit_entry(_value, _context) do
    %{
      id: "audit-unavailable",
      event_label: "Audit evidence unavailable",
      target_label: "Target unavailable",
      actor_label: "Actor unavailable",
      reason: "No operator reason available.",
      recorded_at: nil,
      evidence_href: nil
    }
  end

  @doc "Projects one current executor heartbeat without exposing its raw heartbeat record."
  def present_executor_row(value) when is_map(value) and not is_struct(value) do
    _ = @executor_limit

    status =
      lifeline_state(
        presentation_value(value, :health_state),
        @lifeline_health_states,
        :missing
      )

    id = presentation_text(presentation_value(value, :executor_id), "executor-unavailable")

    %{
      id: id,
      name: id,
      status: status,
      status_spec: StatusTaxonomy.spec(:lifeline_health, status),
      observed_at: safe_time(presentation_value(value, :last_heartbeat_at)),
      guidance: executor_guidance(status)
    }
  end

  def present_executor_row(_value),
    do: present_executor_row(%{executor_id: "executor-unavailable", health_state: "missing"})

  @doc "Projects the latest typed archive run as retained, never current, evidence."
  def present_archive_summary(%ArchiveRun{} = value) do
    _ = @archive_limit

    status =
      lifeline_state(
        value.status,
        @lifeline_incident_states,
        :pending
      )

    %{
      status: status,
      status_spec: StatusTaxonomy.spec(:lifeline_incident, status),
      retained_count: nonnegative(value.archived_count),
      pruned_count: nonnegative(value.pruned_count),
      blocked_count: nonnegative(value.blocked_count),
      observed_at: safe_time(value.finished_at || value.started_at),
      completeness: if(status == :completed, do: :complete, else: :partial),
      guidance: "Archive history is retained evidence, not current incident truth."
    }
  end

  def present_archive_summary(_value) do
    %{
      status: :pending,
      status_spec: StatusTaxonomy.spec(:lifeline_incident, :pending),
      retained_count: 0,
      pruned_count: 0,
      blocked_count: 0,
      observed_at: nil,
      completeness: :unavailable,
      guidance: "Archive history is unavailable."
    }
  end

  @doc """
  Projects one Overview bucket through the fixed Wave 1 presentation contract.
  """
  def present_overview_bucket(bucket) do
    ensure_presentation_map!(bucket, "overview bucket")

    kind =
      normalize_closed_value!(
        presentation_value(bucket, :kind),
        @overview_kinds,
        "overview bucket kind"
      )

    count = normalize_nonnegative_integer!(presentation_value(bucket, :count), "overview count")
    exemplars = normalize_overview_exemplars!(presentation_value(bucket, :exemplars))

    %{
      id: normalize_presentation_id!(presentation_value(bucket, :id), "overview bucket id"),
      kind: kind,
      title: required_presentation_text!(presentation_value(bucket, :title), "overview title"),
      count: count,
      summary:
        required_presentation_text!(presentation_value(bucket, :summary), "overview summary"),
      impact: required_presentation_text!(presentation_value(bucket, :impact), "overview impact"),
      observed_at:
        required_presentation_text!(
          presentation_value(bucket, :observed_at),
          "overview observation"
        ),
      observed_datetime:
        normalize_datetime!(
          presentation_value(bucket, :observed_datetime),
          "overview observation datetime"
        ),
      domain:
        normalize_closed_value!(
          presentation_value(bucket, :domain),
          @overview_domains,
          "overview domain"
        ),
      status:
        normalize_closed_value!(
          presentation_value(bucket, :status),
          @overview_statuses,
          "overview status"
        ),
      severity:
        normalize_closed_value!(
          presentation_value(bucket, :severity),
          @overview_severities,
          "overview severity"
        ),
      completeness:
        normalize_closed_value!(
          presentation_value(bucket, :completeness),
          @evidence_completeness,
          "overview completeness"
        ),
      ownership:
        normalize_closed_value!(
          presentation_value(bucket, :ownership),
          @overview_ownerships,
          "overview ownership"
        ),
      sample_count_label: overview_sample_count_label(kind, count),
      next_step_label: overview_next_step_label(kind),
      next_step_path:
        required_presentation_text!(
          presentation_value(bucket, :next_step_path),
          "overview next step destination"
        ),
      exemplars: exemplars
    }
  end

  @doc """
  Returns fixed confirmation copy for one Cron action.
  """
  def present_cron_action(action) do
    ensure_presentation_map!(action, "cron action")

    kind =
      normalize_closed_value!(
        presentation_value(action, :kind),
        @cron_action_kinds,
        "cron action kind"
      )

    object_label =
      required_presentation_text!(presentation_value(action, :object_label), "cron entry label")

    cron_action_presentation(kind, object_label)
  end

  @doc """
  Returns one truthful, closed Cron action result without claiming job execution.
  """
  def present_cron_result(result) do
    ensure_presentation_map!(result, "cron result")

    kind =
      normalize_closed_value!(
        presentation_value(result, :kind),
        @cron_action_kinds,
        "cron result kind"
      )

    state =
      normalize_closed_value!(
        presentation_value(result, :state),
        @cron_result_states,
        "cron result state"
      )

    recorded_result =
      optional_presentation_text(
        presentation_value(result, :recorded_result),
        "cron recorded result"
      )

    %{
      state: state,
      message: cron_result_message(kind, state),
      recorded_result: recorded_result,
      recovery: cron_result_recovery(state),
      audit_href:
        optional_presentation_text(
          presentation_value(result, :audit_href),
          "cron result audit destination"
        ),
      receipt: cron_result_receipt(kind, state, result, recorded_result)
    }
  end

  @doc """
  Projects one current limiter blocker while consuming, but never returning, its classifier.
  """
  def present_limiter_blocker(blocker) do
    ensure_presentation_map!(blocker, "limiter blocker")

    %{
      id: normalize_presentation_id!(presentation_value(blocker, :id), "limiter blocker id"),
      evidence_kind: normalize_current_evidence!(presentation_value(blocker, :evidence_kind)),
      label:
        required_presentation_text!(presentation_value(blocker, :label), "limiter blocker label"),
      summary:
        required_presentation_text!(
          presentation_value(blocker, :summary),
          "limiter blocker summary"
        ),
      affected_scope:
        optional_presentation_text(
          presentation_value(blocker, :affected_scope),
          "limiter affected scope"
        ),
      clearing_condition:
        required_presentation_text!(
          presentation_value(blocker, :clearing_condition),
          "limiter clearing condition"
        ),
      evidence_source:
        required_presentation_text!(
          presentation_value(blocker, :evidence_source),
          "limiter evidence source"
        )
    }
  end

  @doc """
  Projects the bounded fields needed by one Audit table row.
  """
  def present_audit_row(%Audit{} = event, context) do
    metadata = validate_audit_event!(event, context)
    identity = Audit.event_resource_identity(event)
    event_label = finite_audit_event_label(event)
    target_label = audit_target_label(identity, event.resource)
    actor = audit_actor(event, audit_policy_context(context, event))
    reason = audit_reason(metadata, audit_policy_context(context, event))
    {recorded_at, recorded_datetime} = audit_recorded_time!(event.inserted_at)

    %{
      id: normalize_audit_id!(event.id),
      event_label: event_label,
      target_label: target_label,
      target_href: audit_target_href(identity),
      actor: actor,
      reason_summary: reason,
      recorded_at: recorded_at,
      recorded_datetime: recorded_datetime,
      evidence_href: audit_evidence_href(identity, event),
      evidence_label: "View evidence for #{event_label} on #{target_label}"
    }
  end

  def present_audit_row(_event, _context),
    do: raise(ArgumentError, "audit row source must be an Audit event")

  @doc """
  Projects one immutable Audit detail through a strict metadata allowlist.
  """
  def present_audit_detail(%Audit{} = event, context) do
    metadata = validate_audit_event!(event, context)
    identity = Audit.event_resource_identity(event)
    policy_context = audit_policy_context(context, event)
    action = finite_audit_event_label(event)
    actor = audit_actor(event, policy_context)
    reason = audit_reason(metadata, policy_context)
    target = audit_target_label(identity, event.resource)
    {recorded_at, recorded_datetime} = audit_recorded_time!(event.inserted_at)
    changes = audit_presentation_data(metadata, :changes, "audit changes")
    evidence = audit_presentation_data(metadata, :evidence, "audit evidence")

    %{
      sentence: "#{actor} recorded #{String.downcase(action)} for #{target}.",
      outcome:
        first_metadata_text(metadata, [:outcome, :result, :decision]) || "Outcome not recorded",
      outcome_state: audit_outcome_state(metadata),
      actor: actor,
      action: action,
      target: target,
      reason: reason,
      source: first_metadata_text(metadata, [:source]) || "Source not recorded",
      correlation:
        first_metadata_text(metadata, [:correlation, :correlation_id, :request_id]) ||
          "Correlation not recorded",
      occurred_at: recorded_at,
      occurred_datetime: recorded_datetime,
      recorded_at_label: "Recorded at",
      changes: changes,
      evidence: evidence
    }
  end

  def present_audit_detail(_event, _context),
    do: raise(ArgumentError, "audit detail source must be an Audit event")

  @doc """
  Projects one Oban job into the exact eight finite Jobs table facts.

  Selection and review state are caller-owned presentation booleans. Job arguments,
  metadata, errors, and provider values are never traversed or returned.
  """
  def present_job_row(%Oban.Job{} = job, context) do
    context = ensure_job_context!(context)
    id = normalize_job_id!(job.id)
    state = normalize_job_state!(job.state)

    %{
      id: id,
      worker: required_presentation_text!(job.worker, "job worker"),
      state: state,
      queue: required_presentation_text!(job.queue, "job queue"),
      scheduled: job_row_time!(job.scheduled_at),
      attempts: job_attempts!(job.attempt, job.max_attempts),
      selection: %{
        label: "Select job #{id}",
        checked?: job_context_boolean!(context, :selected?, false)
      },
      review: %{
        label: "Review job #{id}",
        current?: job_context_boolean!(context, :reviewing?, false)
      }
    }
  end

  def present_job_row(_job, _context),
    do: raise(ArgumentError, "job row source must be an Oban job")

  @doc """
  Projects one bounded, read-only Jobs quick review.

  The result contains only current identity/status facts, a non-provider failure
  summary, output availability, enqueue-redaction disclosure, and an allowlisted
  full-detail destination. Raw payloads and histories never enter the projection.
  """
  def present_job_quick_review(%Oban.Job{} = job, context) do
    context = ensure_job_context!(context)
    id = normalize_job_id!(job.id)
    state = normalize_job_state!(job.state)

    %{
      id: id,
      title: "Review job #{id}",
      state: %{value: state, label: Map.fetch!(@job_states, state)},
      worker: required_presentation_text!(job.worker, "job worker"),
      queue: required_presentation_text!(job.queue, "job queue"),
      attempts: job_attempts!(job.attempt, job.max_attempts),
      relevant_time: job_relevant_time!(job),
      failure_summary: job_failure_summary(job),
      recorded_output_available?:
        job_context_boolean!(context, :recorded_output_available?, false),
      enqueue_redaction: job_enqueue_redaction(job.meta),
      full_details_href:
        Selectors.job_detail_path(
          id,
          job_context_list_params(context)
        )
    }
  end

  def present_job_quick_review(_job, _context),
    do: raise(ArgumentError, "job quick review source must be an Oban job")

  @doc """
  Projects one job into the closed, incident-first detail contract.

  Arguments, metadata, and recorded output must arrive as already-rendered policy
  displays. Only bounded, classified error summaries are derived from the job.
  """
  def present_job_detail(%Oban.Job{} = job, context) do
    context = ensure_job_context!(context)
    state = normalize_job_state!(job.state)

    %{
      support: %{
        heading: "Current state",
        state: state,
        state_label: Map.fetch!(@job_states, state),
        summary: "This job is #{state}.",
        availability: "Current job detail is available for operator review."
      },
      actions: Enum.map(job_legal_actions(state), &present_job_action/1),
      identity: job_identity(job, state),
      timing: job_timing(job),
      errors: job_errors(job.errors),
      data: job_policy_data!(context),
      redaction: %{
        enqueue: job_enqueue_redaction(job.meta),
        policy: "Arguments, metadata, and recorded output use the configured display policy."
      },
      destinations: job_destinations!(context)
    }
  end

  def present_job_detail(_job, _context),
    do: raise(ArgumentError, "job detail source must be an Oban job")

  @doc """
  Returns the exact confirmation contract for one single-job action.
  """
  def present_job_action(action) do
    action
    |> normalize_job_action!()
    |> job_action_presentation()
  end

  @doc """
  Returns one closed single-job action result and recovery instruction.

  Unknown provider-shaped inputs fail closed without traversing or rendering them.
  """
  def present_job_action_result(result) when is_map(result) and not is_struct(result) do
    state = normalize_job_result_state(presentation_value(result, :state))
    action = normalize_optional_job_action(presentation_value(result, :action))
    job_id = normalize_optional_job_id(presentation_value(result, :job_id))

    %{
      state: state,
      message: job_result_message(action, state),
      recovery: job_result_recovery(state),
      receipt: job_result_receipt(action, state, job_id),
      audit_href: job_result_audit_href!(result, state),
      requires_fresh_preview?: state != :success
    }
  end

  def present_job_action_result(_result) do
    %{
      state: :failed,
      message: "The job action was not recorded.",
      recovery: "Create a new preview before trying again.",
      receipt: nil,
      audit_href: nil,
      requires_fresh_preview?: true
    }
  end

  @doc """
  Projects one internal evidence bundle into the closed Forensics page contract.

  Destinations are emitted only when their canonical local URL is present in the
  caller-owned authorization context. Unknown source fields and structs are not
  traversed.
  """
  def present_forensics(evidence, context) do
    evidence = forensic_plain_map(evidence)
    authorized = forensic_authorized_destinations(context)
    subject = evidence |> presentation_value(:subject) |> forensic_plain_map()
    diagnosis = evidence |> presentation_value(:diagnosis_summary) |> forensic_plain_map()
    completeness = evidence |> presentation_value(:completeness) |> forensic_plain_map()

    events =
      evidence
      |> presentation_value(:chronology)
      |> forensic_plain_list()
      |> Enum.filter(&forensic_plain_map?/1)
      |> Enum.map(&Chronology.item/1)
      |> Chronology.sort()

    destinations = forensic_destinations(evidence, authorized)
    coverage = forensic_coverage(evidence, completeness, events)

    %{
      support: %{
        state: :ready,
        heading: "Read-only evidence",
        copy: "Forensics summarizes retained Powertools evidence and does not prove root cause."
      },
      scope: forensic_scope(subject),
      summary: forensic_summary(diagnosis, completeness, coverage.summary),
      next_steps: forensic_next_steps(destinations),
      latest_remediation: forensic_latest_remediation(subject, events),
      events: Enum.map(events, &forensic_event(&1, destinations)),
      coverage: coverage,
      audit_href: forensic_audit_href(destinations)
    }
  end

  @doc """
  Normalizes ordered active-filter presentation maps through a finite key contract.
  """
  def normalize_active_filters(filters) when is_list(filters) do
    filters
    |> Enum.map(fn filter ->
      ensure_presentation_map!(filter, "active filter")

      %{
        id: normalize_presentation_id!(presentation_value(filter, :id), "active filter id"),
        label: required_presentation_text!(presentation_value(filter, :label), "filter label"),
        value: required_presentation_text!(presentation_value(filter, :value), "filter value"),
        remove_href:
          required_presentation_text!(
            presentation_value(filter, :remove_href),
            "filter removal destination"
          ),
        remove_label:
          required_presentation_text!(
            presentation_value(filter, :remove_label),
            "filter removal label"
          )
      }
    end)
    |> ensure_unique_presentation_ids!("active filters")
  end

  def normalize_active_filters(_filters),
    do: raise(ArgumentError, "active filters must be a list of presentation maps")

  @doc """
  Normalizes ordered per-object operator results without merging failed and skipped outcomes.
  """
  def normalize_operator_results(results) when is_list(results) do
    results
    |> Enum.map(fn result ->
      ensure_presentation_map!(result, "operator result")

      %{
        id: normalize_presentation_id!(presentation_value(result, :id), "operator result id"),
        object_label:
          required_presentation_text!(
            presentation_value(result, :object_label),
            "operator result object label"
          ),
        outcome:
          normalize_closed_value!(
            presentation_value(result, :outcome),
            @operator_result_states,
            "operator result outcome"
          ),
        message:
          required_presentation_text!(
            presentation_value(result, :message),
            "operator result message"
          ),
        recovery:
          optional_presentation_text(
            presentation_value(result, :recovery),
            "operator result recovery"
          ),
        audit_href:
          optional_presentation_text(
            presentation_value(result, :audit_href),
            "operator result audit destination"
          )
      }
    end)
    |> ensure_unique_presentation_ids!("operator results")
  end

  def normalize_operator_results(_results),
    do: raise(ArgumentError, "operator results must be a list of presentation maps")

  @doc """
  Normalizes every supplied blocker while preserving live versus block-start evidence.
  """
  def normalize_blockers(blockers) when is_list(blockers) do
    blockers
    |> Enum.map(fn blocker ->
      ensure_presentation_map!(blocker, "blocker")

      %{
        id: normalize_presentation_id!(presentation_value(blocker, :id), "blocker id"),
        evidence_kind:
          normalize_closed_value!(
            presentation_value(blocker, :evidence_kind),
            @blocker_evidence_kinds,
            "blocker evidence kind"
          ),
        label: required_presentation_text!(presentation_value(blocker, :label), "blocker label"),
        summary:
          required_presentation_text!(presentation_value(blocker, :summary), "blocker summary"),
        affected_scope:
          optional_presentation_text(
            presentation_value(blocker, :affected_scope),
            "blocker affected scope"
          ),
        clearing_condition:
          required_presentation_text!(
            presentation_value(blocker, :clearing_condition),
            "blocker clearing condition"
          ),
        evidence_source:
          required_presentation_text!(
            presentation_value(blocker, :evidence_source),
            "blocker evidence source"
          ),
        technical_code:
          optional_presentation_text(
            presentation_value(blocker, :technical_code),
            "blocker technical code"
          )
      }
    end)
    |> ensure_unique_presentation_ids!("blockers")
  end

  def normalize_blockers(_blockers),
    do: raise(ArgumentError, "blockers must be a list of presentation maps")

  @doc """
  Normalizes one immutable audit entry with explicit missing reason and outcome copy.
  """
  def normalize_audit_entry(entry) do
    ensure_presentation_map!(entry, "audit entry")

    changes = presentation_value(entry, :changes)
    evidence = presentation_value(entry, :evidence)
    ensure_safe_presentation_data!(changes, "audit changes")
    ensure_safe_presentation_data!(evidence, "audit evidence")
    ensure_audit_presentation_data!(changes, "audit changes")
    ensure_audit_presentation_data!(evidence, "audit evidence")

    normalized = %{
      sentence:
        required_presentation_text!(presentation_value(entry, :sentence), "audit sentence"),
      outcome:
        optional_presentation_text(presentation_value(entry, :outcome), "audit outcome") ||
          "Outcome not recorded",
      outcome_state:
        normalize_closed_value!(
          presentation_value(entry, :outcome_state) || :unknown,
          @audit_outcome_states,
          "audit outcome state"
        ),
      actor: required_presentation_text!(presentation_value(entry, :actor), "audit actor"),
      action: required_presentation_text!(presentation_value(entry, :action), "audit action"),
      target: required_presentation_text!(presentation_value(entry, :target), "audit target"),
      reason:
        optional_presentation_text(presentation_value(entry, :reason), "audit reason") ||
          "No operator reason recorded",
      source:
        optional_presentation_text(presentation_value(entry, :source), "audit source") ||
          "Source not recorded",
      correlation:
        optional_presentation_text(presentation_value(entry, :correlation), "audit correlation") ||
          "Correlation not recorded",
      occurred_at:
        required_presentation_text!(
          presentation_value(entry, :occurred_at),
          "audit absolute time"
        ),
      occurred_datetime:
        normalize_datetime!(presentation_value(entry, :occurred_datetime), "audit datetime"),
      changes: changes,
      evidence: evidence
    }

    case optional_presentation_text(
           presentation_value(entry, :recorded_at_label),
           "audit recorded time label"
         ) do
      nil -> normalized
      label -> Map.put(normalized, :recorded_at_label, label)
    end
  end

  @doc """
  Closes evidence completeness over complete, partial, unknown, and unavailable.
  """
  def normalize_evidence_completeness(value) do
    key = if is_atom(value), do: Atom.to_string(value), else: value
    Map.get(@evidence_completeness, key, :unknown)
  end

  def status_label(status) when is_binary(status) do
    String.to_existing_atom(status) |> status_label()
  rescue
    ArgumentError -> humanize(status)
  end

  def status_label(status), do: Map.get(@status_labels, status, humanize(status))

  def ownership_badge(ownership), do: ControlPlane.ownership_badge(ownership)

  def ownership_posture(:powertools_native), do: "Audited action"
  def ownership_posture(:oban_web_bridge), do: "Inspection only"
  def ownership_posture(:host_owned), do: "Host-owned"

  def continuity_posture, do: "Continuity evidence"

  def runbook_ownership_label(ownership)
      when ownership in [:powertools_native, "powertools_native"],
      do: "Powertools-native"

  def runbook_ownership_label(ownership) when ownership in [:oban_web_bridge, "oban_web_bridge"],
    do: "Oban Web bridge"

  def runbook_ownership_label(ownership) when ownership in [:host_owned, "host_owned"],
    do: "host-owned follow-up"

  def runbook_ownership_label("Powertools-native"), do: "Powertools-native"
  def runbook_ownership_label("Oban Web bridge"), do: "Oban Web bridge"
  def runbook_ownership_label("Inspection only"), do: "Oban Web bridge"
  def runbook_ownership_label("host-owned follow-up"), do: "host-owned follow-up"

  def runbook_ownership_label(ownership) when is_binary(ownership) do
    ownership
    |> String.downcase()
    |> runbook_path_posture()
  end

  def runbook_ownership_label(_ownership), do: "host-owned follow-up"

  def runbook_path_posture(path_or_venue)
      when path_or_venue in [:powertools_native, "powertools_native"],
      do: "Powertools-native"

  def runbook_path_posture(path_or_venue)
      when path_or_venue in [:oban_web_bridge, "oban_web_bridge"],
      do: "Oban Web bridge"

  def runbook_path_posture(path_or_venue) when path_or_venue in [:host_owned, "host_owned"],
    do: "host-owned follow-up"

  def runbook_path_posture(path_or_venue) when is_binary(path_or_venue) do
    normalized = String.downcase(path_or_venue)

    cond do
      String.contains?(normalized, "powertools-native") -> "Powertools-native"
      String.contains?(normalized, "/ops/jobs") -> "Powertools-native"
      String.contains?(normalized, "lifeline") -> "Powertools-native"
      String.contains?(normalized, "oban web") -> "Oban Web bridge"
      String.contains?(normalized, "inspection only") -> "Oban Web bridge"
      true -> "host-owned follow-up"
    end
  end

  def runbook_path_posture(_path_or_venue), do: "host-owned follow-up"

  def follow_up_kind(%{} = follow_up) do
    follow_up
    |> follow_up_value("ownership")
    |> case do
      nil ->
        follow_up
        |> follow_up_value("venue")
        |> follow_up_kind()

      ownership ->
        follow_up_kind(ownership)
    end
  end

  def follow_up_kind(path_or_venue) do
    case runbook_path_posture(path_or_venue) do
      "Powertools-native" -> :powertools_native
      "Oban Web bridge" -> :oban_web_bridge
      _other -> :host_owned
    end
  end

  def follow_up_render_variant(path_or_venue_or_follow_up) do
    case follow_up_kind(path_or_venue_or_follow_up) do
      :powertools_native -> :native_primary
      :oban_web_bridge -> :bridge_guidance
      :host_owned -> :host_guidance
    end
  end

  def runbook_boundary_note(:powertools_native),
    do: "Powertools-native path stays inside the audited native control plane."

  def runbook_boundary_note(:oban_web_bridge),
    do: "Oban Web bridge path is inspection-only and read-only."

  def runbook_boundary_note(:host_owned),
    do: "host-owned follow-up path is outside Powertools delivery and runbook truth."

  def runbook_boundary_note(path_or_venue) do
    case runbook_path_posture(path_or_venue) do
      "Powertools-native" -> runbook_boundary_note(:powertools_native)
      "Oban Web bridge" -> runbook_boundary_note(:oban_web_bridge)
      "host-owned follow-up" -> runbook_boundary_note(:host_owned)
    end
  end

  def native_banner do
    "#{ownership_badge(:powertools_native)} surfaces keep diagnosis, preview, reason, and #{ownership_posture(:powertools_native) |> String.downcase()} together."
  end

  def bridge_banner do
    "#{ownership_badge(:oban_web_bridge)} remains #{ownership_posture(:oban_web_bridge) |> String.downcase()} and read-only."
  end

  def forensic_provenance_label(:durable), do: "durable"
  def forensic_provenance_label("durable"), do: "durable"
  def forensic_provenance_label(:supporting), do: "supporting evidence"
  def forensic_provenance_label("supporting"), do: "supporting evidence"
  def forensic_provenance_label(:bridge_only), do: "Inspection only"
  def forensic_provenance_label("bridge_only"), do: "Inspection only"
  def forensic_provenance_label(:missing), do: "unknown"
  def forensic_provenance_label("missing"), do: "unknown"
  def forensic_provenance_label(_provenance), do: "unknown"

  def forensic_completeness_label(:complete), do: "complete"
  def forensic_completeness_label("complete"), do: "complete"
  def forensic_completeness_label(:partial_evidence), do: "partial evidence"
  def forensic_completeness_label("partial_evidence"), do: "partial evidence"
  def forensic_completeness_label(:history_unavailable), do: "history unavailable"
  def forensic_completeness_label("history_unavailable"), do: "history unavailable"
  def forensic_completeness_label(:unknown), do: "unknown"
  def forensic_completeness_label("unknown"), do: "unknown"
  def forensic_completeness_label(_completeness), do: "unknown"

  def host_follow_up_status_label("host_owned_follow_up_unconfigured"),
    do: "Host-owned follow-up unavailable"

  def host_follow_up_status_label("host_owned_follow_up_callback_invoked"),
    do: "Host-owned follow-up callback invoked"

  def host_follow_up_status_label("host_owned_follow_up_callback_failed"),
    do: "Host-owned follow-up callback failed"

  def host_follow_up_status_label(_status), do: "Host-owned follow-up unavailable"

  def venue_label(venue), do: ControlPlane.venue_label(venue)

  def audit_event_label(event), do: Audit.event_label(event)

  def audit_resource_label(event) do
    identity = Audit.event_resource_identity(event)

    [identity.type, identity.id]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(":")
  end

  def audit_follow_up_path(event) do
    identity = Audit.event_resource_identity(event)

    Selectors.audit_path([
      {"resource_type", identity.type},
      {"resource_id", identity.id},
      {"event_type", Audit.event_label(event)}
    ])
  end

  def workflow_refusal(nil), do: nil

  def workflow_refusal(rejection) do
    %{
      outcome: "Needs Review",
      reason: rejection.message || refusal_reason_label(rejection.code),
      next_move: legal_next_move_label(rejection.legal_next_steps),
      venue: refusal_venue_label(rejection.legal_next_steps),
      code: rejection.code
    }
  end

  defp forensic_scope(subject) do
    {type, type_label} =
      Map.get(
        @forensic_scope_types,
        forensic_text(presentation_value(subject, :type), "unknown"),
        {:unknown, "Unknown evidence"}
      )

    %{
      type: type,
      type_label: type_label,
      identity: forensic_text(presentation_value(subject, :id), "Unavailable"),
      subject: forensic_text(presentation_value(subject, :label), "Evidence subject unavailable"),
      ownership:
        forensic_text(
          presentation_value(subject, :entry_surface),
          "Evidence ownership unavailable"
        )
    }
  end

  defp forensic_summary(diagnosis, completeness, coverage_summary) do
    %{
      heading: "Investigation summary",
      diagnosis: forensic_status_label(presentation_value(diagnosis, :current)),
      detail:
        forensic_text(
          presentation_value(diagnosis, :detail),
          "No current diagnosis detail is available."
        ),
      provenance: forensic_provenance_display(presentation_value(diagnosis, :provenance)),
      completeness: forensic_completeness_display(presentation_value(completeness, :state)),
      coverage: coverage_summary
    }
  end

  defp forensic_event(item, destinations) do
    {timestamp, datetime} = forensic_time(item.occurred_at)

    %{
      id: item.id,
      timestamp: timestamp,
      datetime: datetime,
      title: forensic_sentence(item.label),
      source: forensic_event_source(item.source_family, item.strength),
      status: forensic_status_label(item.status),
      domain: :forensics,
      state: forensic_status_state(item.status),
      notes: item.notes,
      follow_ups: forensic_event_follow_ups(item, destinations)
    }
  end

  defp forensic_latest_remediation(subject, events) do
    if presentation_value(subject, :type) == "lifeline_incident" do
      case Enum.find(events, &(&1.event_type == "lifeline.repair_executed")) do
        nil ->
          nil

        event ->
          {occurred_at, occurred_datetime} = forensic_time(event.occurred_at)

          %{
            heading: "Latest remediation evidence",
            historical?: true,
            status: forensic_status_label(event.status),
            summary:
              "Historical Lifeline repair evidence was recorded. It does not change the current diagnosis.",
            occurred_at: occurred_at,
            occurred_datetime: occurred_datetime,
            provenance: forensic_provenance_display(event.strength)
          }
      end
    end
  end

  defp forensic_coverage(evidence, completeness, events) do
    coverage = evidence |> presentation_value(:coverage) |> forensic_plain_map()
    shown_count = forensic_count(presentation_value(coverage, :shown_count), length(events))
    total_count = forensic_optional_count(presentation_value(coverage, :total_count))
    has_more? = forensic_optional_boolean(presentation_value(coverage, :has_more?))
    summary = forensic_coverage_summary(shown_count, total_count, has_more?)

    %{
      heading: "Evidence limits and sources",
      summary: summary,
      shown_count: shown_count,
      total_count: total_count,
      has_more?: has_more?,
      bounded?: forensic_boolean(presentation_value(coverage, :bounded?), true),
      completeness: forensic_completeness_display(presentation_value(completeness, :state)),
      retention:
        forensic_text(
          presentation_value(coverage, :retention),
          "Only the retained evidence available to these sources is shown."
        ),
      sources:
        coverage
        |> presentation_value(:sources)
        |> forensic_plain_list()
        |> Enum.filter(&forensic_plain_map?/1)
        |> Enum.map(&forensic_coverage_source/1)
    }
  end

  defp forensic_coverage_source(source) do
    %{
      id: forensic_text(presentation_value(source, :id), "unknown"),
      label: forensic_text(presentation_value(source, :label), "Unknown source"),
      shown_count: forensic_count(presentation_value(source, :shown_count), 0),
      total_count: forensic_optional_count(presentation_value(source, :total_count)),
      has_more?: forensic_optional_boolean(presentation_value(source, :has_more?)),
      limit: forensic_optional_count(presentation_value(source, :limit)),
      provenance: forensic_provenance_display(presentation_value(source, :provenance)),
      completeness: forensic_completeness_display(presentation_value(source, :completeness)),
      retention:
        forensic_text(
          presentation_value(source, :retention),
          "No source retention detail is available."
        )
    }
  end

  defp forensic_coverage_summary(shown_count, _total_count, true),
    do: "Showing the newest #{shown_count} events; more evidence exists."

  defp forensic_coverage_summary(shown_count, total_count, false)
       when is_integer(total_count) and shown_count < total_count,
       do: "Showing #{shown_count} of #{total_count} retained events."

  defp forensic_coverage_summary(shown_count, _total_count, false),
    do: "Showing all #{shown_count} available events in this source window."

  defp forensic_coverage_summary(shown_count, total_count, nil) when is_integer(total_count),
    do: "Showing #{shown_count} of #{total_count} retained events."

  defp forensic_coverage_summary(shown_count, _total_count, nil),
    do: "Showing #{shown_count} retained events; total availability is unknown."

  defp forensic_next_steps(destinations) do
    destinations
    |> Enum.reject(&(&1.kind == :audit))
    |> Enum.with_index()
    |> Enum.map(fn {destination, index} ->
      %{
        id: destination.id,
        label: destination.label,
        href: destination.href,
        role: if(index == 0, do: :primary, else: :additional),
        support: forensic_destination_support(destination.kind)
      }
    end)
  end

  defp forensic_audit_href(destinations) do
    case Enum.find(destinations, &(&1.kind == :audit)) do
      nil -> nil
      destination -> destination.href
    end
  end

  defp forensic_event_follow_ups(event, destinations) do
    kinds =
      case {event.source_family, event.event_type} do
        {"workflow", _event_type} ->
          [:workflow]

        {"lifeline", _event_type} ->
          [:lifeline]

        {"cron", _event_type} ->
          [:cron]

        {"limiter", _event_type} ->
          [:limiter]

        {"audit", event_type} when is_binary(event_type) ->
          [forensic_event_destination_kind(event_type)]

        _other ->
          []
      end

    destinations
    |> Enum.filter(&(&1.kind in kinds))
    |> Enum.map(&%{label: &1.label, href: &1.href})
  end

  defp forensic_event_destination_kind("workflow." <> _suffix), do: :workflow
  defp forensic_event_destination_kind("lifeline." <> _suffix), do: :lifeline
  defp forensic_event_destination_kind("cron." <> _suffix), do: :cron
  defp forensic_event_destination_kind("limiter." <> _suffix), do: :limiter
  defp forensic_event_destination_kind(_event_type), do: :audit

  defp forensic_destinations(evidence, authorized) do
    evidence
    |> forensic_destination_candidates()
    |> Enum.reduce([], fn candidate, destinations ->
      case forensic_destination(candidate, authorized) do
        nil ->
          destinations

        destination ->
          if Enum.any?(
               destinations,
               &(&1.canonical == destination.canonical or &1.kind == destination.kind)
             ) do
            destinations
          else
            destinations ++ [destination]
          end
      end
    end)
  end

  defp forensic_destination_candidates(evidence) do
    forensic_plain_list(presentation_value(evidence, :legal_next_paths)) ++
      forensic_plain_list(presentation_value(evidence, :linked_resources))
  end

  defp forensic_destination(candidate, authorized)
       when is_map(candidate) and not is_struct(candidate) do
    path = presentation_value(candidate, :path)

    with true <- is_binary(path),
         {:ok, kind, canonical} <- forensic_canonical_destination(path),
         {:ok, href} <- Map.fetch(authorized, canonical) do
      %{
        id: forensic_destination_id(kind),
        label: forensic_destination_label(kind),
        href: href,
        kind: kind,
        canonical: canonical
      }
    else
      _unavailable -> nil
    end
  end

  defp forensic_destination(_candidate, _authorized), do: nil

  defp forensic_authorized_destinations(context) do
    context =
      cond do
        is_map(context) and not is_struct(context) -> context
        is_list(context) -> Map.new(context)
        true -> %{}
      end

    context
    |> presentation_value(:authorized_hrefs)
    |> forensic_plain_list()
    |> Enum.reduce(%{}, fn href, authorized ->
      case forensic_canonical_destination(href) do
        {:ok, _kind, canonical} -> Map.put_new(authorized, canonical, href)
        :error -> authorized
      end
    end)
  end

  defp forensic_canonical_destination(href) when is_binary(href) do
    uri = URI.parse(href)

    with nil <- uri.scheme,
         nil <- uri.host,
         nil <- uri.userinfo,
         nil <- uri.fragment,
         {:ok, kind} <- forensic_destination_kind(uri.path),
         {:ok, query} <- forensic_destination_query(uri.query, kind) do
      canonical =
        case URI.encode_query(Enum.sort(query)) do
          "" -> uri.path
          encoded -> "#{uri.path}?#{encoded}"
        end

      {:ok, kind, canonical}
    else
      _unsafe -> :error
    end
  rescue
    ArgumentError -> :error
  end

  defp forensic_canonical_destination(_href), do: :error

  defp forensic_destination_kind("/ops/jobs/lifeline"), do: {:ok, :lifeline}
  defp forensic_destination_kind("/ops/jobs/cron"), do: {:ok, :cron}
  defp forensic_destination_kind("/ops/jobs/limiters"), do: {:ok, :limiter}
  defp forensic_destination_kind("/ops/jobs/audit"), do: {:ok, :audit}

  defp forensic_destination_kind(path) when is_binary(path) do
    if Regex.match?(~r|\A/ops/jobs/workflows/[^/?]+\z|, path),
      do: {:ok, :workflow},
      else: :error
  end

  defp forensic_destination_kind(_path), do: :error

  defp forensic_destination_query(nil, _kind), do: {:ok, %{}}

  defp forensic_destination_query(query, kind) when is_binary(query) do
    decoded = URI.decode_query(query)

    if Enum.all?(Map.keys(decoded), &(&1 in Map.fetch!(@forensic_destination_queries, kind))) do
      {:ok, decoded}
    else
      :error
    end
  end

  defp forensic_destination_id(:workflow), do: "open-workflow"
  defp forensic_destination_id(:lifeline), do: "review-incident-in-lifeline"
  defp forensic_destination_id(:cron), do: "open-cron-entry"
  defp forensic_destination_id(:limiter), do: "review-limiter-blockers"
  defp forensic_destination_id(:audit), do: "view-matching-audit-evidence"

  defp forensic_destination_label(:workflow), do: "Open workflow"
  defp forensic_destination_label(:lifeline), do: "Review incident in Lifeline"
  defp forensic_destination_label(:cron), do: "Open cron entry"
  defp forensic_destination_label(:limiter), do: "Review limiter blockers"
  defp forensic_destination_label(:audit), do: "View matching audit evidence"

  defp forensic_destination_support(:workflow),
    do: "Review the current workflow diagnosis before taking any action."

  defp forensic_destination_support(:lifeline),
    do: "Review current evidence and reauthorize the incident before taking any action."

  defp forensic_destination_support(:cron),
    do: "Review current schedule evidence before taking any action."

  defp forensic_destination_support(:limiter),
    do: "Review current blocker evidence before taking any action."

  defp forensic_time(%NaiveDateTime{} = value) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> forensic_time()
  end

  defp forensic_time(%DateTime{} = value) do
    utc = DateTime.shift_zone!(value, "Etc/UTC")

    {
      "#{Calendar.strftime(utc, "%B")} #{utc.day}, #{utc.year} at #{Calendar.strftime(utc, "%H:%M")} UTC",
      DateTime.to_iso8601(utc)
    }
  end

  defp forensic_time(_value), do: {"Timestamp unavailable", "Timestamp unavailable"}

  defp forensic_event_source(source_family, provenance) do
    source = Map.get(@forensic_sources, source_family, "Unknown source")
    "#{source} · #{forensic_provenance_display(provenance)}"
  end

  defp forensic_provenance_display(value) when value in [:durable, "durable"],
    do: "Durable evidence"

  defp forensic_provenance_display(value) when value in [:supporting, "supporting"],
    do: "Supporting evidence"

  defp forensic_provenance_display(value) when value in [:bridge_only, "bridge_only"],
    do: "Inspection only"

  defp forensic_provenance_display(_value), do: "Provenance unavailable"

  defp forensic_completeness_display(value) when value in [:complete, "complete"], do: "Complete"

  defp forensic_completeness_display(value)
       when value in [:partial_evidence, "partial_evidence"],
       do: "Partial evidence"

  defp forensic_completeness_display(value)
       when value in [:history_unavailable, "history_unavailable"],
       do: "History unavailable"

  defp forensic_completeness_display(_value), do: "Unknown"

  defp forensic_status_state(value) when is_binary(value) do
    Enum.find(@forensic_statuses, :unknown, &(Atom.to_string(&1) == value))
  end

  defp forensic_status_state(value) when value in @forensic_statuses, do: value
  defp forensic_status_state(_value), do: :unknown

  defp forensic_status_label(value) do
    case forensic_status_state(value) do
      :unknown -> "Status unavailable"
      status -> humanize(status)
    end
  end

  defp forensic_sentence(value) do
    sentence = forensic_text(value, "Evidence was recorded")
    if Regex.match?(~r/[.!?]\z/, sentence), do: sentence, else: sentence <> "."
  end

  defp forensic_text(value, fallback) when is_atom(value),
    do: value |> Atom.to_string() |> forensic_text(fallback)

  defp forensic_text(value, fallback) when is_integer(value),
    do: value |> Integer.to_string() |> forensic_text(fallback)

  defp forensic_text(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      text -> forensic_bounded_text(text)
    end
  end

  defp forensic_text(_value, fallback), do: fallback

  defp forensic_bounded_text(text) do
    if String.length(text) > @forensic_note_limit do
      String.slice(text, 0, @forensic_note_limit - 1) <> "…"
    else
      text
    end
  end

  defp forensic_count(value, _fallback) when is_integer(value) and value >= 0, do: value
  defp forensic_count(_value, fallback), do: fallback

  defp forensic_optional_count(nil), do: nil
  defp forensic_optional_count(value) when is_integer(value) and value >= 0, do: value
  defp forensic_optional_count(_value), do: nil

  defp forensic_boolean(value, _fallback) when is_boolean(value), do: value
  defp forensic_boolean(_value, fallback), do: fallback

  defp forensic_optional_boolean(value) when is_boolean(value), do: value
  defp forensic_optional_boolean(_value), do: nil

  defp forensic_plain_map(value) when is_map(value) and not is_struct(value), do: value
  defp forensic_plain_map(_value), do: %{}
  defp forensic_plain_map?(value), do: is_map(value) and not is_struct(value)
  defp forensic_plain_list(value) when is_list(value), do: value
  defp forensic_plain_list(_value), do: []

  defp overview_sample_count_label(:bridge_only, count),
    do: "#{count} representative follow-ups"

  defp overview_sample_count_label(_kind, count), do: "#{count} shown"

  defp overview_next_step_label(:bridge_only), do: "Inspect in Oban Web"
  defp overview_next_step_label(:needs_review), do: "Review Needs Review"
  defp overview_next_step_label(:blocked), do: "Review Blocked Limiters"
  defp overview_next_step_label(:waiting), do: "Review Waiting Work"
  defp overview_next_step_label(:runnable), do: "Review Runnable Capacity"
  defp overview_next_step_label(:resolved_continuity), do: "Review Resolved Continuity"

  defp normalize_overview_exemplars!(exemplars) when is_list(exemplars) do
    exemplars
    |> Enum.take(3)
    |> Enum.map(&normalize_overview_exemplar!/1)
  end

  defp normalize_overview_exemplars!(_exemplars),
    do: raise(ArgumentError, "overview exemplars must be a list")

  defp normalize_overview_exemplar!(exemplar) do
    ensure_presentation_map!(exemplar, "overview exemplar")

    [
      :id,
      :label,
      :fact,
      :status,
      :attention_reason,
      :evidence_completeness,
      :path,
      :evidence_path,
      :venue,
      :ownership,
      :source,
      :family,
      :bucket
    ]
    |> Enum.reduce(%{}, fn key, normalized ->
      case presentation_value(exemplar, key) do
        nil -> normalized
        value -> Map.put(normalized, key, normalize_exemplar_value!(value))
      end
    end)
  end

  defp normalize_exemplar_value!(value)
       when is_binary(value) or is_number(value) or is_boolean(value) or is_atom(value),
       do: value

  defp normalize_exemplar_value!(_value),
    do: raise(ArgumentError, "overview exemplar values must be finite scalars")

  defp cron_action_presentation(:pause, object_label) do
    %{
      kind: :pause,
      confirm_label: "Pause cron entry",
      dismiss_label: "Keep running",
      title: "Pause #{object_label}",
      consequence:
        "Future schedule claims stop. Work that is already running or enqueued is unaffected.",
      support_boundary: "The existing schedule and already-claimed work remain unchanged.",
      pending_copy: "Pausing cron entry",
      intent: :warning
    }
  end

  defp cron_action_presentation(:resume, object_label) do
    %{
      kind: :resume,
      confirm_label: "Resume cron entry",
      dismiss_label: "Keep paused",
      title: "Resume #{object_label}",
      consequence: "Future schedule claims continue. Missed work is not run retroactively.",
      support_boundary: "Only future schedule claims continue after this action.",
      pending_copy: "Resuming cron entry",
      intent: :warning
    }
  end

  defp cron_action_presentation(:run_now, object_label) do
    %{
      kind: :run_now,
      confirm_label: "Run cron entry now",
      dismiss_label: "Keep current schedule",
      title: "Run #{object_label} now",
      consequence:
        "Powertools attempts a manual schedule-slot claim. Overlap policy may skip, queue, or enqueue it.",
      support_boundary: "A recorded slot claim does not prove that a job ran.",
      pending_copy: "Claiming a manual schedule slot",
      intent: :warning
    }
  end

  defp cron_result_message(:run_now, :success),
    do: "The manual schedule-slot claim result was recorded."

  defp cron_result_message(_kind, :success), do: "The cron entry state change was recorded."
  defp cron_result_message(:run_now, :skipped), do: "The manual schedule-slot claim was skipped."
  defp cron_result_message(_kind, :skipped), do: "The cron action was skipped."
  defp cron_result_message(_kind, :duplicate), do: "This action was already recorded."
  defp cron_result_message(_kind, :partial), do: "Only part of the requested action was recorded."
  defp cron_result_message(_kind, :failed), do: "The cron action was not recorded."
  defp cron_result_message(_kind, :expired), do: "The action preview expired before execution."
  defp cron_result_message(_kind, :drifted), do: "The cron entry changed after the preview."
  defp cron_result_message(_kind, :consumed), do: "The action preview was already used."

  defp cron_result_recovery(:success), do: nil

  defp cron_result_recovery(:drifted),
    do: "Review the current cron entry, then create a new preview."

  defp cron_result_recovery(_state), do: "Create a new preview before trying again."

  defp cron_result_receipt(_kind, state, _result, _recorded_result) when state != :success,
    do: nil

  defp cron_result_receipt(kind, :success, result, recorded_result) do
    object_label =
      required_presentation_text!(presentation_value(result, :object_label), "cron entry label")

    case kind do
      :pause ->
        "Cron entry #{object_label} paused. Audit evidence recorded."

      :resume ->
        "Cron entry #{object_label} resumed. Audit evidence recorded."

      :run_now ->
        recorded_result = recorded_result || "result recorded"

        "Manual slot claim recorded for #{object_label}: #{recorded_result}. Audit evidence recorded."
    end
  end

  defp job_action_presentation(:retry) do
    %{
      kind: :retry,
      intent: :warning,
      title: "Retry this job",
      object_label: "Job",
      scope: "1 ready job",
      confirm_label: "Retry job",
      dismiss_label: "Keep current state",
      consequence:
        "Powertools requests a retry for each ready job. A retry request does not mean the job completed.",
      reversibility: "The retry request cannot be withdrawn after it is recorded.",
      support_boundary: "Audit evidence records the request, not successful job completion.",
      pending_copy: "Requesting retry"
    }
  end

  defp job_action_presentation(:cancel) do
    %{
      kind: :cancel,
      intent: :danger,
      title: "Cancel this job",
      object_label: "Job",
      scope: "1 ready job",
      confirm_label: "Cancel job",
      dismiss_label: "Keep running",
      consequence: "Each ready job stops and will not retry. This cannot be undone.",
      reversibility: "Cancellation is irreversible.",
      support_boundary: "Audit evidence records the cancellation request and its outcome.",
      pending_copy: "Cancelling job"
    }
  end

  defp job_action_presentation(:discard) do
    %{
      kind: :discard,
      intent: :danger,
      title: "Discard this job",
      object_label: "Job",
      scope: "1 ready job",
      confirm_label: "Discard job",
      dismiss_label: "Keep current state",
      consequence:
        "Each ready job is marked discarded and will not retry. This cannot be undone.",
      reversibility: "Discarding is irreversible.",
      support_boundary: "Audit evidence records the discard request and its outcome.",
      pending_copy: "Discarding job"
    }
  end

  defp normalize_job_action!(value) do
    normalize_closed_value!(value, @job_action_kinds, "job action")
  end

  defp normalize_optional_job_action(value) do
    normalize_job_action!(value)
  rescue
    ArgumentError -> nil
  end

  defp normalize_job_result_state(value) do
    normalize_closed_value!(value, @job_result_states, "job result state")
  rescue
    ArgumentError -> :failed
  end

  defp normalize_optional_job_id(value) when is_integer(value) and value > 0, do: value
  defp normalize_optional_job_id(_value), do: nil

  defp job_result_message(:retry, :success), do: "The retry request was recorded."
  defp job_result_message(:cancel, :success), do: "The cancellation was recorded."
  defp job_result_message(:discard, :success), do: "The discard request was recorded."
  defp job_result_message(_action, :success), do: "The job action was recorded."
  defp job_result_message(_action, :skipped), do: "The job action was skipped."
  defp job_result_message(_action, :failed), do: "The job action was not recorded."
  defp job_result_message(_action, :expired), do: "The action preview expired before execution."
  defp job_result_message(_action, :drifted), do: "The job changed after the preview."
  defp job_result_message(_action, :consumed), do: "The action preview was already used."

  defp job_result_recovery(:success), do: nil

  defp job_result_recovery(:drifted),
    do: "Review the current job, then Create a new preview."

  defp job_result_recovery(_state), do: "Create a new preview before trying again."

  defp job_result_receipt(_action, state, _job_id) when state != :success, do: nil

  defp job_result_receipt(:retry, :success, job_id) when is_integer(job_id),
    do: "Retry requested for job #{job_id}. Audit evidence recorded."

  defp job_result_receipt(:cancel, :success, job_id) when is_integer(job_id),
    do: "Job #{job_id} cancelled. Audit evidence recorded."

  defp job_result_receipt(:discard, :success, job_id) when is_integer(job_id),
    do: "Job #{job_id} discarded. Audit evidence recorded."

  defp job_result_receipt(_action, :success, _job_id), do: nil

  defp job_result_audit_href!(result, :success) do
    case presentation_value(result, :audit_href) do
      nil -> nil
      href -> validate_job_destination!(href)
    end
  end

  defp job_result_audit_href!(_result, _state), do: nil

  defp job_legal_actions("retryable"), do: [:retry, :cancel, :discard]

  defp job_legal_actions(state) when state in ["available", "scheduled", "executing"],
    do: [:cancel, :discard]

  defp job_legal_actions(state) when state in ["cancelled", "discarded", "completed"],
    do: [:retry]

  defp job_identity(job, state) do
    [
      %{label: "Job ID", value: Integer.to_string(normalize_job_id!(job.id)), value_kind: :text},
      %{
        label: "Worker",
        value: required_presentation_text!(job.worker, "job worker"),
        value_kind: :code
      },
      %{
        label: "Queue",
        value: required_presentation_text!(job.queue, "job queue"),
        value_kind: :text
      },
      %{label: "State", value: Map.fetch!(@job_states, state), value_kind: :status},
      %{
        label: "Attempts",
        value: job_attempts!(job.attempt, job.max_attempts),
        value_kind: :text
      },
      %{
        label: "Priority",
        value: job_priority(job.priority),
        value_kind: :text
      }
    ]
  end

  defp job_priority(value) when is_integer(value) and value >= 0, do: Integer.to_string(value)
  defp job_priority(nil), do: "Unavailable"

  defp job_priority(_value),
    do: raise(ArgumentError, "job priority must be nonnegative")

  defp job_timing(job) do
    [
      job_timing_value("Inserted", job.inserted_at),
      job_timing_value("Scheduled", job.scheduled_at),
      job_timing_value("Attempted", job.attempted_at),
      job_timing_value("Completed", job.completed_at),
      job_timing_value("Cancelled", job.cancelled_at),
      job_timing_value("Discarded", job.discarded_at)
    ]
  end

  defp job_timing_value(label, nil), do: %{label: label, value: "Unavailable", datetime: nil}

  defp job_timing_value(label, value) do
    value
    |> job_time!()
    |> Map.put(:label, label)
  end

  defp job_errors(errors) when is_list(errors) do
    errors
    |> Enum.map(&job_error_candidate/1)
    |> Enum.sort_by(& &1.sort_key, :desc)
    |> Enum.take(@job_error_limit)
    |> Enum.map(&Map.delete(&1, :sort_key))
  end

  defp job_errors(_errors), do: []

  defp job_error_candidate(error) when is_map(error) and not is_struct(error) do
    attempt = job_error_attempt(presentation_value(error, :attempt))
    {occurred_at, occurred_datetime, time_sort} = job_error_time(presentation_value(error, :at))

    case presentation_value(error, :error) do
      text when is_binary(text) ->
        {class, message} = parse_job_error(text)
        {class, class_truncated?} = bound_job_error_text(class)
        {message, message_truncated?} = bound_job_error_text(message)

        %{
          class: class,
          message: message,
          occurred_at: occurred_at,
          occurred_datetime: occurred_datetime,
          attempt: attempt,
          truncated?: class_truncated? or message_truncated?,
          sort_key: {time_sort, attempt}
        }

      _unknown ->
        unavailable_job_error(occurred_at, occurred_datetime, time_sort, attempt)
    end
  end

  defp job_error_candidate(_error) do
    unavailable_job_error("Timestamp unavailable", nil, 0, 0)
  end

  defp unavailable_job_error(occurred_at, occurred_datetime, time_sort, attempt) do
    %{
      class: "Failure class unavailable",
      message: "Failure details are unavailable.",
      occurred_at: occurred_at,
      occurred_datetime: occurred_datetime,
      attempt: attempt,
      truncated?: false,
      sort_key: {time_sort, attempt}
    }
  end

  defp parse_job_error(text) do
    if sensitive_job_error?(text) do
      {"Failure class unavailable", "Failure details are redacted."}
    else
      case Regex.run(~r/\A\*\* \(([^)\r\n]+)\)\s*(.*)/s, text, capture: :all_but_first) do
        [class, message] ->
          {
            required_job_error_text(class, "Failure class unavailable"),
            required_job_error_text(
              first_job_error_line(message),
              "Failure details are unavailable."
            )
          }

        _unrecognized ->
          {"Failure class unavailable", "Failure details are unavailable."}
      end
    end
  end

  defp sensitive_job_error?(text) do
    Regex.match?(
      ~r/(?:https?|ftp):\/\/|(?:token|secret|password|passwd|credential|authorization|cookie|api[-_ ]?key|headers?|payload)\s*[=:]/i,
      text
    )
  end

  defp first_job_error_line(text) do
    text
    |> String.split(~r/\R/, parts: 2)
    |> hd()
  end

  defp required_job_error_text(text, fallback) do
    case String.trim(text) do
      "" -> fallback
      value -> value
    end
  end

  defp bound_job_error_text(text) do
    if String.length(text) > @job_error_text_limit do
      {String.slice(text, 0, @job_error_text_limit - 1) <> "…", true}
    else
      {text, false}
    end
  end

  defp job_error_attempt(value) when is_integer(value) and value >= 0, do: value
  defp job_error_attempt(_value), do: 0

  defp job_error_time(%DateTime{} = value) do
    time = job_time!(value)
    {time.value, time.datetime, DateTime.to_unix(value, :microsecond)}
  end

  defp job_error_time(%NaiveDateTime{} = value) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> job_error_time()
  end

  defp job_error_time(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, parsed, _offset} -> job_error_time(parsed)
      {:error, _reason} -> {"Timestamp unavailable", nil, 0}
    end
  end

  defp job_error_time(_value), do: {"Timestamp unavailable", nil, 0}

  defp job_policy_data!(context) do
    %{
      arguments: %{
        label: "Arguments",
        kind: :args,
        display: validate_job_policy_display!(presentation_value(context, :args_display), :args)
      },
      metadata: %{
        label: "Metadata",
        kind: :meta,
        display: validate_job_policy_display!(presentation_value(context, :meta_display), :meta)
      },
      recorded_output: %{
        label: "Recorded output",
        kind: :recorded_output,
        display:
          validate_job_policy_display!(
            presentation_value(context, :recorded_output_display),
            :recorded_output
          )
      }
    }
  end

  defp validate_job_policy_display!({:raw_json, json} = display, _kind) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, value} ->
        ensure_safe_job_policy_data!(value)
        display

      {:error, _reason} ->
        raise ArgumentError, "job policy display must contain valid JSON"
    end
  end

  defp validate_job_policy_display!({:string, text} = display, _kind) when is_binary(text) do
    required_presentation_text!(text, "job policy display")
    display
  end

  defp validate_job_policy_display!({:fallback, "[redacted]"} = display, _kind), do: display

  defp validate_job_policy_display!(display, :recorded_output)
       when is_map(display) and not is_struct(display) do
    %{
      available?:
        job_recorded_output_boolean!(presentation_value(display, :available?), "availability"),
      summary:
        optional_presentation_text(presentation_value(display, :summary), "output summary"),
      status: optional_presentation_text(presentation_value(display, :status), "output status"),
      payload: job_recorded_output_payload!(presentation_value(display, :payload)),
      redacted?:
        job_recorded_output_boolean!(presentation_value(display, :redacted?), "redaction"),
      attempt: job_recorded_output_integer(presentation_value(display, :attempt)),
      payload_bytes: job_recorded_output_integer(presentation_value(display, :payload_bytes)),
      recorded_at: optional_job_recorded_output_time(presentation_value(display, :recorded_at)),
      retention:
        optional_presentation_text(presentation_value(display, :retention), "output retention"),
      expires_at: optional_job_recorded_output_time(presentation_value(display, :expires_at))
    }
  end

  defp validate_job_policy_display!(_display, _kind),
    do: raise(ArgumentError, "job policy display has an unsupported shape")

  defp ensure_safe_job_policy_data!(value) when is_map(value) do
    Enum.each(value, fn {key, nested} ->
      if sensitive_presentation_source_key?(normalize_presentation_source_key(key)) and
           not redacted_job_policy_value?(nested) do
        raise ArgumentError, "job policy display contains a prohibited source field"
      end

      ensure_safe_job_policy_data!(nested)
    end)
  end

  defp ensure_safe_job_policy_data!(value) when is_list(value),
    do: Enum.each(value, &ensure_safe_job_policy_data!/1)

  defp ensure_safe_job_policy_data!(_value), do: :ok

  defp redacted_job_policy_value?(value) when is_binary(value) do
    normalized = String.downcase(value)
    normalized in ["[redacted]", "redacted", "redacted at enqueue", "[hidden]", "hidden"]
  end

  defp redacted_job_policy_value?(_value), do: false

  defp job_recorded_output_boolean!(value, _field) when is_boolean(value), do: value

  defp job_recorded_output_boolean!(_value, field),
    do: raise(ArgumentError, "job recorded output #{field} must be boolean")

  defp job_recorded_output_integer(nil), do: nil
  defp job_recorded_output_integer(value) when is_integer(value) and value >= 0, do: value

  defp job_recorded_output_integer(_value),
    do: raise(ArgumentError, "job recorded output count must be nonnegative")

  defp job_recorded_output_payload!(value) do
    ensure_safe_presentation_data!(value, "job recorded output")
    value
  end

  defp optional_job_recorded_output_time(nil), do: nil
  defp optional_job_recorded_output_time(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp optional_job_recorded_output_time(%NaiveDateTime{} = value) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp optional_job_recorded_output_time(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _datetime, _offset} -> value
      {:error, _reason} -> raise ArgumentError, "job recorded output time must be ISO 8601"
    end
  end

  defp optional_job_recorded_output_time(_value),
    do: raise(ArgumentError, "job recorded output time must be a datetime")

  defp job_destinations!(context) do
    [
      job_destination(
        "job-audit",
        "View matching audit evidence",
        presentation_value(context, :audit_href)
      ),
      job_destination(
        "job-forensics",
        "Open job forensics",
        presentation_value(context, :forensics_href)
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp job_destination(_id, _label, nil), do: nil

  defp job_destination(id, label, href),
    do: %{id: id, label: label, href: validate_job_destination!(href)}

  defp validate_job_destination!(href) when is_binary(href) do
    uri = URI.parse(href)

    if uri.scheme || uri.host || not String.starts_with?(uri.path || "", "/ops/jobs") do
      raise ArgumentError, "job evidence destination must be local to Jobs"
    end

    query = URI.decode_query(uri.query || "")
    ensure_safe_presentation_data!(query, "job evidence destination")
    href
  end

  defp validate_job_destination!(_href),
    do: raise(ArgumentError, "job evidence destination must be text")

  defp normalize_current_evidence!(value) do
    case normalize_closed_value!(value, @blocker_evidence_kinds, "limiter evidence kind") do
      :current -> :current
      :block_start_snapshot -> raise ArgumentError, "limiter blocker must use current evidence"
    end
  end

  defp ensure_job_context!(context) when is_map(context) and not is_struct(context), do: context
  defp ensure_job_context!(context) when is_list(context), do: Map.new(context)

  defp ensure_job_context!(_context),
    do: raise(ArgumentError, "job presentation context must be a plain map")

  defp normalize_job_id!(value) when is_integer(value) and value > 0, do: value
  defp normalize_job_id!(_value), do: raise(ArgumentError, "job id must be a positive integer")

  defp normalize_job_state!(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_job_state!()

  defp normalize_job_state!(value) when is_binary(value) do
    if Map.has_key?(@job_states, value) do
      value
    else
      raise ArgumentError, "unsupported job state"
    end
  end

  defp normalize_job_state!(_value), do: raise(ArgumentError, "unsupported job state")

  defp job_attempts!(attempt, max_attempts)
       when is_integer(attempt) and attempt >= 0 and is_integer(max_attempts) and
              max_attempts > 0,
       do: "#{attempt} of #{max_attempts}"

  defp job_attempts!(_attempt, _max_attempts),
    do: raise(ArgumentError, "job attempts must be finite nonnegative counts")

  defp job_row_time!(value) do
    %{value: label, datetime: datetime} = job_time!(value)
    %{label: label, datetime: datetime}
  end

  defp job_relevant_time!(%Oban.Job{attempted_at: %DateTime{} = value}),
    do: Map.put(job_time!(value), :label, "Attempted")

  defp job_relevant_time!(%Oban.Job{scheduled_at: value}),
    do: Map.put(job_time!(value), :label, "Scheduled")

  defp job_time!(%DateTime{} = value) do
    utc = DateTime.shift_zone!(value, "Etc/UTC")

    %{
      value:
        "#{Calendar.strftime(utc, "%B")} #{utc.day}, #{utc.year} at #{Calendar.strftime(utc, "%H:%M")} UTC",
      datetime: DateTime.to_iso8601(utc)
    }
  end

  defp job_time!(%NaiveDateTime{} = value) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> job_time!()
  end

  defp job_time!(_value), do: raise(ArgumentError, "job time must be a datetime")

  defp job_failure_summary(%Oban.Job{errors: errors, unsaved_error: unsaved_error})
       when errors not in [nil, []] or not is_nil(unsaved_error),
       do: "Latest failure recorded. Open full job details for the redacted error summary."

  defp job_failure_summary(_job), do: "No failure summary recorded."

  defp job_enqueue_redaction(meta) when is_map(meta) do
    case Map.get(meta, "__redacted_fields__") || Map.get(meta, :__redacted_fields__) do
      fields when is_list(fields) and fields != [] ->
        count = length(fields)

        %{
          redacted?: true,
          summary:
            if(count == 1,
              do: "1 argument field was redacted at enqueue.",
              else: "#{count} argument fields were redacted at enqueue."
            )
        }

      _missing ->
        %{redacted?: false, summary: "No enqueue redaction was recorded."}
    end
  end

  defp job_enqueue_redaction(_meta),
    do: %{redacted?: false, summary: "No enqueue redaction was recorded."}

  defp job_context_boolean!(context, key, default) do
    case presentation_value(context, key) do
      nil -> default
      value when is_boolean(value) -> value
      _value -> raise ArgumentError, "job presentation #{key} must be boolean"
    end
  end

  defp job_context_list_params(context) do
    case presentation_value(context, :list_params) do
      nil -> []
      params when is_map(params) or is_list(params) -> params
      _params -> raise ArgumentError, "job list params must be a map or list"
    end
  end

  defp validate_audit_event!(%Audit{} = event, context) do
    ensure_presentation_map!(context, "audit presentation context")
    metadata = event.metadata || %{}

    if not is_map(metadata) or is_struct(metadata) do
      raise ArgumentError, "audit metadata must be a plain map"
    end

    ensure_safe_presentation_data!(metadata, "audit metadata")
    _ = audit_presentation_data(metadata, :changes, "audit changes")
    _ = audit_presentation_data(metadata, :evidence, "audit evidence")
    metadata
  end

  defp audit_policy_context(context, event) do
    surface = presentation_value(context, :surface)
    section = presentation_value(context, :section)

    %{
      surface: normalize_audit_context_value(surface, [:audit], :audit, "audit surface"),
      section:
        normalize_audit_context_value(
          section,
          [:table, :selected_evidence, :detail],
          :detail,
          "audit section"
        ),
      event: event.event_type || event.action
    }
  end

  defp normalize_audit_context_value(nil, _allowed, fallback, _field), do: fallback

  defp normalize_audit_context_value(value, allowed, _fallback, field) do
    normalized =
      if is_binary(value),
        do: Map.get(Map.new(allowed, &{Atom.to_string(&1), &1}), value),
        else: value

    if normalized in allowed do
      normalized
    else
      raise ArgumentError, "unsupported #{field}"
    end
  end

  defp audit_actor(event, context) do
    principal = Audit.event_principal(event)

    actor =
      case RuntimeConfig.display_policy() do
        nil -> principal.label || principal.id || "system"
        _module -> DisplayPolicy.actor_label(principal, context)
      end

    required_presentation_text!(actor, "audit actor")
  end

  defp audit_reason(metadata, context) do
    case optional_presentation_text(presentation_value(metadata, :reason), "audit reason") do
      nil ->
        "No operator reason recorded"

      reason ->
        rendered =
          case RuntimeConfig.display_policy() do
            nil -> reason
            _module -> DisplayPolicy.reason(reason, context)
          end

        required_presentation_text!(rendered, "audit reason")
    end
  end

  defp finite_audit_event_label(event) do
    Map.get(@audit_event_labels, event.event_type || event.action, "Recorded event")
  end

  defp audit_target_label(identity, fallback) do
    case {optional_identity_text(identity.type), optional_identity_text(identity.id)} do
      {type, id} when is_binary(type) and is_binary(id) -> "#{type}:#{id}"
      _missing -> required_presentation_text!(fallback, "audit target")
    end
  end

  defp audit_target_href(%{type: "job", id: id}) when not is_nil(id),
    do: Selectors.job_detail_path(id)

  defp audit_target_href(_identity), do: nil

  defp audit_evidence_href(identity, event) do
    Selectors.audit_path([
      {"resource_type", optional_identity_text(identity.type)},
      {"resource_id", optional_identity_text(identity.id)},
      {"page", 1},
      {"event", normalize_audit_id!(event.id)}
    ])
  end

  defp optional_identity_text(nil), do: nil

  defp optional_identity_text(value) when is_binary(value),
    do: optional_presentation_text(value, "audit identity")

  defp optional_identity_text(value) when is_integer(value), do: Integer.to_string(value)

  defp optional_identity_text(_value),
    do: raise(ArgumentError, "audit identity must be text or an integer")

  defp normalize_audit_id!(value) when is_integer(value) and value > 0, do: value

  defp normalize_audit_id!(value),
    do: normalize_presentation_id!(value, "audit event id")

  defp audit_recorded_time!(%NaiveDateTime{} = value) do
    value
    |> DateTime.from_naive!("Etc/UTC")
    |> audit_recorded_time!()
  end

  defp audit_recorded_time!(%DateTime{} = value) do
    utc = DateTime.shift_zone!(value, "Etc/UTC")

    recorded_at =
      "#{Calendar.strftime(utc, "%B")} #{utc.day}, #{utc.year} at #{Calendar.strftime(utc, "%H:%M")} UTC"

    {recorded_at, DateTime.to_iso8601(utc)}
  end

  defp audit_recorded_time!(_value),
    do: raise(ArgumentError, "audit recorded time must be a datetime")

  defp audit_presentation_data(metadata, key, name) do
    value = presentation_value(metadata, key)
    ensure_audit_presentation_data!(value, name)
    redact_sensitive_audit_presentation_data(value)
  end

  defp redact_sensitive_audit_presentation_data(value) when is_map(value) do
    if sensitive_audit_identifier?(presentation_value(value, :field)) or
         sensitive_audit_identifier?(presentation_value(value, :label)) do
      nil
    else
      Enum.reduce(value, %{}, fn {key, nested}, redacted ->
        case redact_sensitive_audit_presentation_data(nested) do
          nil -> redacted
          safe -> Map.put(redacted, key, safe)
        end
      end)
    end
  end

  defp redact_sensitive_audit_presentation_data(value) when is_list(value) do
    value
    |> Enum.map(&redact_sensitive_audit_presentation_data/1)
    |> Enum.reject(&is_nil/1)
  end

  defp redact_sensitive_audit_presentation_data(value), do: value

  defp sensitive_audit_identifier?(value) when is_binary(value) or is_atom(value),
    do: value |> normalize_presentation_source_key() |> sensitive_presentation_source_key?()

  defp sensitive_audit_identifier?(_value), do: false

  defp first_metadata_text(metadata, keys) do
    Enum.find_value(keys, fn key ->
      optional_presentation_text(presentation_value(metadata, key), "audit #{key}")
    end)
  end

  defp audit_outcome_state(metadata) do
    case presentation_value(metadata, :outcome_state) do
      nil -> :unknown
      value -> normalize_closed_value!(value, @audit_outcome_states, "audit outcome state")
    end
  end

  defp legal_next_move_label([]),
    do: "Review the workflow diagnosis before retrying a bounded action."

  defp legal_next_move_label(steps) do
    steps
    |> Enum.map(&humanize/1)
    |> Enum.join(", ")
  end

  defp refusal_venue_label(steps) do
    if Enum.any?(steps, &(&1 in ["retry", "cancel"])) do
      "Powertools-native Lifeline"
    else
      "Workflow diagnosis"
    end
  end

  defp refusal_reason_label(nil), do: "This action is not available right now."
  defp refusal_reason_label(code), do: humanize(code)

  defp presentation_value(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp batch_name(batch) do
    presentation_text(
      presentation_value(batch, :name) || presentation_value(batch, :short_id),
      "Unnamed batch"
    )
  end

  defp batch_progress(progress) when is_map(progress) do
    total = nonnegative(presentation_value(progress, :total_count))
    completed = min(nonnegative(presentation_value(progress, :completed_count)), total)

    %{
      total_count: total,
      completed_count: completed,
      inserted_count: nonnegative(presentation_value(progress, :inserted_count)),
      success_count: nonnegative(presentation_value(progress, :success_count)),
      discard_count: nonnegative(presentation_value(progress, :discard_count)),
      cancelled_count: nonnegative(presentation_value(progress, :cancelled_count)),
      snooze_count: nonnegative(presentation_value(progress, :snooze_count)),
      percent:
        case presentation_value(progress, :percent) do
          value when is_number(value) -> value |> max(0) |> min(100)
          _ -> if(total == 0, do: 0, else: Float.round(completed / total * 100, 1))
        end
    }
  end

  defp batch_progress(_progress),
    do: %{
      total_count: 0,
      completed_count: 0,
      inserted_count: 0,
      success_count: 0,
      discard_count: 0,
      cancelled_count: 0,
      snooze_count: 0,
      percent: 0
    }

  defp batch_callback_summary(summary) when is_map(summary) do
    Map.new(~w[total pending failed claimed delivered stuck]a, fn key ->
      {key, nonnegative(presentation_value(summary, key))}
    end)
  end

  defp batch_callback_summary(_summary),
    do: %{total: 0, pending: 0, failed: 0, claimed: 0, delivered: 0, stuck: 0}

  defp batch_blocked_state(state) when is_map(state) do
    %{
      name: finite_atom(presentation_value(state, :name), :unknown),
      severity:
        finite_atom(
          presentation_value(state, :severity),
          :neutral,
          ~w[neutral info success warning danger]a
        ),
      title: presentation_text(presentation_value(state, :title), "Status unavailable"),
      copy:
        presentation_text(
          presentation_value(state, :copy),
          "Current retained evidence does not explain this state."
        ),
      evidence: batch_blocked_evidence(presentation_value(state, :evidence))
    }
  end

  defp batch_blocked_state(_state) do
    %{
      name: :unknown,
      severity: :neutral,
      title: "Status unavailable",
      copy: "Current retained evidence does not explain this state.",
      evidence: []
    }
  end

  defp batch_blocked_evidence(evidence) when is_map(evidence) do
    ~w[
      remaining_count discard_count inserted_count total_count failed_chunk failure_kind
      upstream_job_id chain_step_name chain_step_index chain_step_count completed_at failed_at
    ]a
    |> Enum.flat_map(fn key ->
      case safe_scalar(presentation_value(evidence, key)) do
        nil -> []
        value -> [%{label: humanize_presentation_key(key), value: to_string(value)}]
      end
    end)
  end

  defp batch_blocked_evidence(_evidence), do: []

  defp present_batch_member(member) when is_map(member) do
    %{
      job_id: normalize_nonnegative_integer!(presentation_value(member, :job_id), "batch job id"),
      worker: presentation_text(presentation_value(member, :worker), "Unknown"),
      queue: presentation_text(presentation_value(member, :queue), "Unknown"),
      state:
        finite_state(
          presentation_value(member, :oban_state) ||
            presentation_value(member, :batch_member_state),
          @batch_member_states
        ),
      attempt: nonnegative(presentation_value(member, :attempt)),
      max_attempts: nonnegative(presentation_value(member, :max_attempts)),
      error: safe_display_text(presentation_value(member, :last_error_display)),
      bridge_href: presentation_text(presentation_value(member, :bridge_path), "#"),
      retry_eligible?: presentation_value(member, :retry_eligible?) == true
    }
  end

  defp present_batch_member(_member),
    do: raise(ArgumentError, "batch member source must be a map")

  defp present_batch_callback(callback) when is_map(callback) do
    %{
      id: presentation_text(presentation_value(callback, :id), "Unavailable"),
      event: presentation_text(presentation_value(callback, :event), "Unknown event"),
      dedupe_key: presentation_text(presentation_value(callback, :dedupe_key), "Unavailable"),
      status: finite_state(presentation_value(callback, :status), @callback_states),
      attempts: nonnegative(presentation_value(callback, :attempts)),
      available_at: safe_time(presentation_value(callback, :available_at)),
      claimed_at: safe_time(presentation_value(callback, :claimed_at)),
      lease_expires_at: safe_time(presentation_value(callback, :lease_expires_at)),
      delivered_at: safe_time(presentation_value(callback, :delivered_at)),
      error: safe_display_text(presentation_value(callback, :last_error_display)),
      retry_eligible?: presentation_value(callback, :retry_eligible?) == true
    }
  end

  defp present_batch_callback(_callback),
    do: raise(ArgumentError, "batch callback source must be a map")

  defp present_batch_result(result) when is_map(result) do
    %{
      id: presentation_text(presentation_value(result, :id), "result"),
      state: finite_state(presentation_value(result, :state), @repair_states),
      message:
        presentation_text(presentation_value(result, :message), "No result detail available.")
    }
  end

  defp present_batch_result(_result),
    do: raise(ArgumentError, "batch result source must be a map")

  defp present_batch_audit(event) when is_map(event) do
    %{
      id: presentation_text(presentation_value(event, :id), "audit"),
      event_label: audit_event_label(event),
      resource_label: audit_resource_label(event),
      inserted_at: safe_time(presentation_value(event, :inserted_at))
    }
  end

  defp present_batch_audit(_event),
    do: raise(ArgumentError, "batch audit source must be a map")

  defp batch_chain_context(context) when is_map(context) do
    %{
      chain?: presentation_value(context, :chain?) == true,
      chain_id: safe_scalar(presentation_value(context, :chain_id)),
      chain_step_name: safe_scalar(presentation_value(context, :chain_step_name)),
      chain_step_index: safe_scalar(presentation_value(context, :chain_step_index)),
      chain_step_count: safe_scalar(presentation_value(context, :chain_step_count)),
      upstream_job_id: safe_scalar(presentation_value(context, :upstream_job_id)),
      next_step: safe_scalar(presentation_value(context, :next_step))
    }
  end

  defp batch_chain_context(_context),
    do: %{
      chain?: false,
      chain_id: nil,
      chain_step_name: nil,
      chain_step_index: nil,
      chain_step_count: nil,
      upstream_job_id: nil,
      next_step: nil
    }

  defp workflow_semantics(value) when is_map(value) do
    %{
      label: presentation_text(presentation_value(value, :label), "Unavailable"),
      mode: presentation_text(presentation_value(value, :mode), "Unavailable")
    }
  end

  defp workflow_semantics(_value), do: %{label: "Unavailable", mode: "Unavailable"}

  defp workflow_callback_posture(value) when is_map(value) do
    %{
      delivered: nonnegative(presentation_value(value, :delivered)),
      failed: nonnegative(presentation_value(value, :failed)),
      pending: nonnegative(presentation_value(value, :pending))
    }
  end

  defp workflow_callback_posture(_value), do: %{delivered: 0, failed: 0, pending: 0}

  defp workflow_dependency_labels(values) when is_list(values) do
    Enum.map(values, fn
      value when is_binary(value) ->
        presentation_text(value, "Unknown dependency")

      value when is_map(value) ->
        presentation_text(
          presentation_value(value, :step_name) || presentation_value(value, :name),
          "Unknown dependency"
        )

      _value ->
        "Unknown dependency"
    end)
  end

  defp workflow_dependency_labels(_values), do: []

  defp present_workflow_result(value) when is_map(value) do
    %{
      status:
        finite_state(
          presentation_value(value, :status),
          ~w[available completed failed expired unavailable unknown]
        ),
      summary: presentation_text(presentation_value(value, :summary), "No retained result."),
      payload: safe_display_text(presentation_value(value, :payload)),
      redacted?: presentation_value(value, :redacted?) == true
    }
    |> ensure_safe_presentation_data!("workflow result")
  end

  defp present_workflow_result(_value),
    do: %{
      status: :unavailable,
      summary: "No retained result.",
      payload: "Unavailable",
      redacted?: false
    }

  defp present_workflow_evidence(value) when is_map(value) do
    value
    |> Enum.reject(fn {key, _item} ->
      sensitive_presentation_source_key?(normalize_presentation_source_key(key))
    end)
    |> Enum.take(8)
    |> Map.new(fn {key, item} ->
      {to_string(key), safe_scalar(item) || "Redacted"}
    end)
    |> ensure_safe_presentation_data!("workflow evidence")
  end

  defp present_workflow_evidence(value) when is_binary(value),
    do: %{"summary" => presentation_text(value, "Unavailable")}

  defp present_workflow_evidence(_value), do: %{"summary" => "Unavailable"}

  defp bounded_collection(values, limit, projector) do
    values =
      case values do
        list when is_list(list) -> Enum.take(list, limit + 1)
        nil -> []
        _ -> raise ArgumentError, "bounded presentation source must be a list"
      end

    %{
      items: values |> Enum.take(limit) |> Enum.map(projector),
      complete?: length(values) <= limit
    }
  end

  defp completeness(%{items: items, complete?: complete?}, noun) do
    %{
      complete?: complete?,
      rendered_count: length(items),
      guidance:
        if(
          complete?,
          do: "All retained #{noun} in this bounded view are shown.",
          else: "More #{noun} exist; this view shows a bounded partial evidence window."
        )
    }
  end

  defp finite_state(value, allowed) do
    normalized = value |> to_string() |> String.downcase()
    if normalized in allowed, do: safe_atom(normalized), else: :unknown
  end

  defp finite_atom(value, fallback, allowed \\ nil)
  defp finite_atom(value, _fallback, nil) when is_atom(value), do: value

  defp finite_atom(value, fallback, allowed) when is_list(allowed) do
    atom = if is_atom(value), do: value, else: safe_atom(to_string(value))
    if atom in allowed, do: atom, else: fallback
  end

  defp finite_atom(_value, fallback, _allowed), do: fallback

  defp nonnegative(value) when is_integer(value), do: max(value, 0)
  defp nonnegative(value) when is_float(value), do: max(trunc(value), 0)
  defp nonnegative(_value), do: 0

  defp safe_time(nil), do: nil
  defp safe_time(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp safe_time(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp safe_time(value) when is_binary(value), do: String.slice(value, 0, 100)
  defp safe_time(_value), do: nil

  defp safe_scalar(value) when is_binary(value), do: String.slice(value, 0, 500)
  defp safe_scalar(value) when is_number(value) or is_boolean(value), do: value
  defp safe_scalar(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp safe_scalar(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp safe_scalar(_value), do: nil

  defp safe_display_text({kind, value})
       when kind in [:raw_json, :string, :fallback] and is_binary(value),
       do: String.slice(value, 0, 1_000)

  defp safe_display_text(value) when is_binary(value), do: String.slice(value, 0, 1_000)
  defp safe_display_text(_value), do: "Unavailable"

  defp presentation_text(value, _fallback) when is_atom(value), do: Atom.to_string(value)

  defp presentation_text(value, fallback) when is_binary(value) do
    case String.trim(value) do
      "" -> fallback
      text -> String.slice(text, 0, 1_000)
    end
  end

  defp presentation_text(_value, fallback), do: fallback
  defp finite_text(value, fallback), do: presentation_text(value, fallback)

  defp authorized_destination(nil, _context), do: nil

  defp authorized_destination(destination, context) do
    href = presentation_text(destination, "#")
    allowed = presentation_value(context, :authorized_hrefs)
    if is_list(allowed) and href not in allowed, do: nil, else: href
  end

  defp lifeline_state(value, states, fallback) do
    key = if is_atom(value), do: Atom.to_string(value), else: value
    Map.get(states, key, fallback)
  end

  defp lifeline_completeness(value)
       when value in [:complete, "complete", :partial, "partial", :unavailable, "unavailable"] do
    case value do
      "complete" -> :complete
      "partial" -> :partial
      "unavailable" -> :unavailable
      atom -> atom
    end
  end

  defp lifeline_completeness(_value), do: :unavailable

  defp unavailable_incident_row do
    %{
      id: "incident-unavailable",
      subject: "Incident unavailable",
      status: :pending,
      status_spec: StatusTaxonomy.spec(:lifeline_incident, :pending),
      severity: :neutral,
      observed_at: nil,
      affected_scope: "Affected scope unavailable",
      preview_available?: false,
      detail_href: nil
    }
  end

  defp unavailable_incident_detail do
    %{
      id: "incident-unavailable",
      subject: "Incident unavailable",
      status: :pending,
      status_spec: StatusTaxonomy.spec(:lifeline_incident, :pending),
      current_diagnosis: "Current diagnosis unavailable.",
      provenance: "Current retained evidence unavailable.",
      affected_scope: "Affected scope unavailable",
      legal_route: nil,
      history: [],
      completeness: :unavailable
    }
  end

  defp bounded_lifeline_history(values) when is_list(values) do
    items =
      values
      |> Enum.take(@lifeline_audit_limit + 1)
      |> Enum.take(@lifeline_audit_limit)
      |> Enum.flat_map(fn
        value when is_map(value) and not is_struct(value) ->
          [
            %{
              label: presentation_text(presentation_value(value, :label), "Evidence unavailable"),
              occurred_at: safe_time(presentation_value(value, :occurred_at))
            }
          ]

        _value ->
          []
      end)

    %{
      items: items,
      has_more?: length(values) > @lifeline_audit_limit,
      completeness: :complete
    }
  end

  defp bounded_lifeline_history(_values),
    do: %{items: [], has_more?: false, completeness: :unavailable}

  defp bounded_lifeline_texts(values, limit) when is_list(values) do
    values
    |> Enum.take(limit)
    |> Enum.map(&presentation_text(&1, "Unavailable"))
  end

  defp bounded_lifeline_texts(_values, _limit), do: []

  defp repair_preview_presentation_state(value)
       when value in ["ready", "pending", :ready, :pending],
       do: :preview

  defp repair_preview_presentation_state(value), do: lifeline_result_state(value)

  defp lifeline_result_state(value) do
    key = if is_atom(value), do: Atom.to_string(value), else: value
    Map.get(@lifeline_result_states, key, :failed)
  end

  defp repair_status_spec(state) when state in [:success, :failed, :skipped],
    do: StatusTaxonomy.spec(:operator_result, state)

  defp repair_status_spec(state), do: StatusTaxonomy.spec(:lifeline_preview, state)

  defp repair_progress(value) when is_map(value) and not is_struct(value) do
    total = nonnegative(presentation_value(value, :total))
    completed = min(nonnegative(presentation_value(value, :completed)), total)

    %{
      completed: completed,
      total: total,
      percent: if(total == 0, do: 0, else: Float.round(completed / total * 100, 1))
    }
  end

  defp repair_progress(_value), do: nil

  defp failed_repair_confirmation do
    %{
      state: :failed,
      status_spec: repair_status_spec(:failed),
      title: "Confirm Lifeline repair",
      action: "Execute remediation",
      object_label: "Lifeline incident",
      observed_at: nil,
      observed_state: "State unavailable",
      affected_records: [],
      proposed_changes: [],
      non_effects: [],
      consequence: "Lifeline could not prepare a safe repair confirmation.",
      reversibility: "No change is authorized from this presentation.",
      support_boundary: "Create a new preview before trying again.",
      progress: nil
    }
  end

  defp bounded_repair_results(values) when is_list(values) do
    items =
      values
      |> Enum.take(@incident_limit + 1)
      |> Enum.take(@incident_limit)
      |> Enum.flat_map(fn
        value when is_map(value) and not is_struct(value) ->
          state = lifeline_result_state(presentation_value(value, :state))

          [
            %{
              state: state,
              status_spec: repair_status_spec(state),
              label: presentation_text(presentation_value(value, :label), "Target unavailable"),
              message:
                presentation_text(
                  presentation_value(value, :message),
                  repair_result_message(state)
                )
            }
          ]

        _value ->
          []
      end)

    %{
      items: items,
      has_more?: length(values) > @incident_limit,
      completeness: :complete
    }
  end

  defp bounded_repair_results(_values),
    do: %{items: [], has_more?: false, completeness: :unavailable}

  defp repair_result_message(:success),
    do: "Every reported target completed and durable Audit evidence was recorded."

  defp repair_result_message(:partial),
    do: "Some targets changed and others did not. Review every target result."

  defp repair_result_message(:skipped),
    do: "The repair was skipped because current target truth was not eligible."

  defp repair_result_message(:failed), do: "The repair was not recorded as successful."
  defp repair_result_message(:drifted), do: "Current target truth changed after preview."
  defp repair_result_message(:expired), do: "The repair preview expired before execution."
  defp repair_result_message(:consumed), do: "The repair preview was already used."

  defp repair_result_message(:disconnected),
    do: "The connection ended before completion was known."

  defp repair_result_message(:interrupted),
    do: "Execution was interrupted before completion was known."

  defp repair_result_message(:preview), do: "The repair is ready for operator confirmation."

  defp repair_result_recovery(:success), do: nil

  defp repair_result_recovery(state) when state in [:partial, :disconnected, :interrupted],
    do: "Review current truth and durable Audit evidence before creating a new preview."

  defp repair_result_recovery(_state), do: "Create a new preview before trying again."

  defp executor_guidance(:healthy),
    do: "No Lifeline action is indicated by this current heartbeat."

  defp executor_guidance(:late),
    do: "Review the current heartbeat before considering remediation."

  defp executor_guidance(:missing),
    do: "Review the associated incident and authorize any remediation separately."

  defp humanize_presentation_key(key) do
    key
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp required_presentation_text!(value, field) do
    optional_presentation_text(value, field) ||
      raise ArgumentError, "#{field} must be non-empty text"
  end

  defp optional_presentation_text(nil, _field), do: nil

  defp optional_presentation_text(value, field) when is_atom(value),
    do: value |> Atom.to_string() |> optional_presentation_text(field)

  defp optional_presentation_text(value, _field) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      text -> text
    end
  end

  defp optional_presentation_text(_value, field),
    do: raise(ArgumentError, "#{field} must be text")

  defp normalize_presentation_id!(value, field) do
    id = required_presentation_text!(value, field)

    if Regex.match?(~r/\A[A-Za-z][A-Za-z0-9_.:-]*\z/, id) do
      id
    else
      raise ArgumentError, "#{field} must be a stable identifier"
    end
  end

  defp normalize_nonnegative_integer!(value, _field) when is_integer(value) and value >= 0,
    do: value

  defp normalize_nonnegative_integer!(_value, field),
    do: raise(ArgumentError, "#{field} must be a nonnegative integer")

  defp normalize_closed_value!(value, values, field) do
    key = if is_atom(value), do: Atom.to_string(value), else: value

    case Map.fetch(values, key) do
      {:ok, normalized} -> normalized
      :error -> raise ArgumentError, "unsupported #{field}"
    end
  end

  defp normalize_datetime!(value, field) do
    datetime = required_presentation_text!(value, field)

    case DateTime.from_iso8601(datetime) do
      {:ok, _parsed, _offset} -> datetime
      {:error, _reason} -> raise ArgumentError, "#{field} must be a valid ISO 8601 datetime"
    end
  end

  defp ensure_unique_presentation_ids!(items, collection) do
    ids = Enum.map(items, & &1.id)

    if Enum.uniq(ids) == ids do
      items
    else
      raise ArgumentError, "#{collection} require unique ids"
    end
  end

  defp ensure_presentation_map!(value, name) when is_map(value) do
    if is_struct(value) do
      raise ArgumentError, "#{name} must be a plain presentation map"
    end

    ensure_safe_presentation_data!(value, name)
  end

  defp ensure_presentation_map!(_value, name),
    do: raise(ArgumentError, "#{name} must be a plain presentation map")

  defp ensure_safe_presentation_data!(nil, _name), do: :ok

  defp ensure_safe_presentation_data!(value, name) when is_struct(value),
    do: raise(ArgumentError, "#{name} must not contain structs")

  defp ensure_safe_presentation_data!(value, name) when is_map(value) do
    Enum.each(value, fn {key, nested} ->
      normalized_key = normalize_presentation_source_key(key)

      if not is_nil(nested) and sensitive_presentation_source_key?(normalized_key) do
        raise ArgumentError, "#{name} contains a prohibited source field"
      end

      ensure_safe_presentation_data!(nested, name)
    end)
  end

  defp ensure_safe_presentation_data!(value, name) when is_list(value),
    do: Enum.each(value, &ensure_safe_presentation_data!(&1, name))

  defp ensure_safe_presentation_data!(_value, _name), do: :ok

  defp ensure_audit_presentation_data!(nil, _name), do: :ok

  defp ensure_audit_presentation_data!(value, name) when is_struct(value),
    do: raise(ArgumentError, "#{name} must not contain structs")

  defp ensure_audit_presentation_data!(value, name) when is_map(value) do
    Enum.each(value, fn {key, nested} ->
      if normalize_presentation_source_key(key) not in @audit_presentation_data_fields do
        raise ArgumentError, "#{name} contains an unsupported presentation field"
      end

      ensure_audit_presentation_data!(nested, name)
    end)
  end

  defp ensure_audit_presentation_data!(value, name) when is_list(value),
    do: Enum.each(value, &ensure_audit_presentation_data!(&1, name))

  defp ensure_audit_presentation_data!(value, _name)
       when is_binary(value) or is_number(value) or is_boolean(value) or is_atom(value),
       do: :ok

  defp ensure_audit_presentation_data!(_value, name),
    do: raise(ArgumentError, "#{name} contains unsupported presentation data")

  defp sensitive_presentation_source_key?(normalized_key) do
    components = String.split(normalized_key, "_", trim: true)

    normalized_key in @sensitive_presentation_source_field_names or
      Enum.any?(components, &(&1 in @sensitive_presentation_source_field_components))
  end

  defp normalize_presentation_source_key(key) do
    key
    |> to_string()
    |> String.replace(~r/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
    |> String.replace(~r/([a-z0-9])([A-Z])/, "\\1_\\2")
    |> String.replace(~r/[^A-Za-z0-9]+/, "_")
    |> String.trim("_")
    |> String.downcase()
  end

  def humanize(atom) when is_atom(atom), do: humanize(Atom.to_string(atom))

  def humanize(bin) when is_binary(bin) do
    bin
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp follow_up_value(map, key) do
    Map.get(map, key) || Map.get(map, safe_atom(key))
  end

  defp safe_atom(binary) when is_binary(binary) do
    String.to_existing_atom(binary)
  rescue
    ArgumentError -> nil
  end

  defp safe_atom(_), do: nil
end
