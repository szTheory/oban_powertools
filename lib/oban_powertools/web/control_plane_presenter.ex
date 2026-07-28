defmodule ObanPowertools.Web.ControlPlanePresenter do
  @moduledoc """
  Shared control-plane labels, ownership copy, and venue-aware wording.
  """

  alias ObanPowertools.{Audit, ControlPlane, DisplayPolicy, RuntimeConfig}
  alias ObanPowertools.Web.Selectors

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
