defmodule ObanPowertools.Web.OperatorPatternPresenterTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Audit
  alias ObanPowertools.Lifeline.{ArchiveRun, Incident, RepairPreview}
  alias ObanPowertools.Web.ControlPlanePresenter, as: Presenter

  @source_path "lib/oban_powertools/web/control_plane_presenter.ex"
  @hostile ~s|<b dir="rtl">مرحبا & operator</b>|

  @normalizers ~w[
    normalize_active_filters normalize_operator_results normalize_blockers normalize_audit_entry
    normalize_evidence_completeness
  ]a

  @phase79_presenters ~w[
    present_overview_bucket present_cron_action present_cron_result present_limiter_blocker
    present_audit_row present_audit_detail
  ]a

  @phase80_job_presenters [
    present_job_row: 2,
    present_job_quick_review: 2,
    present_job_detail: 2,
    present_job_action: 1,
    present_job_action_result: 1
  ]

  @phase80_forensics_presenters [present_forensics: 2]

  @phase81_presenters [
    present_batch_row: 2,
    present_batch_detail: 2,
    present_batch_retry_preview: 2,
    present_workflow_row: 2,
    present_workflow_detail: 2,
    present_workflow_step: 2,
    present_workflow_step_detail: 3,
    present_lifeline_summary: 1,
    present_incident_row: 2,
    present_incident_detail: 2,
    present_repair_confirmation: 3,
    present_repair_result: 2,
    present_lifeline_audit_entry: 2,
    present_executor_row: 1,
    present_archive_summary: 1
  ]

  test "exports all five finite Phase 78 presenter seams" do
    assert Code.ensure_loaded?(Presenter), "Phase 78 requires #{Presenter}"

    for normalizer <- @normalizers do
      assert function_exported?(Presenter, normalizer, 1),
             "GROUP-01 requires #{inspect(Presenter)}.#{normalizer}/1"
    end
  end

  @tag phase79_slice: "shared"
  test "exports the six finite Phase 79 page presentation seams" do
    assert Code.ensure_loaded?(Presenter), "Phase 79 requires #{Presenter}"

    for presenter <- @phase79_presenters do
      arity = if presenter in [:present_audit_row, :present_audit_detail], do: 2, else: 1

      assert function_exported?(Presenter, presenter, arity),
             "Phase 79 requires #{inspect(Presenter)}.#{presenter}/#{arity}"
    end
  end

  test "exports the five finite Phase 80 Jobs presentation seams" do
    assert Code.ensure_loaded?(Presenter), "Phase 80 requires #{Presenter}"

    for {presenter, arity} <- @phase80_job_presenters do
      assert function_exported?(Presenter, presenter, arity),
             "Phase 80 requires #{inspect(Presenter)}.#{presenter}/#{arity}"
    end
  end

  test "exports the finite Phase 80 Forensics presentation seam" do
    assert Code.ensure_loaded?(Presenter), "Phase 80 requires #{Presenter}"

    for {presenter, arity} <- @phase80_forensics_presenters do
      assert function_exported?(Presenter, presenter, arity),
             "Phase 80 requires #{inspect(Presenter)}.#{presenter}/#{arity}"
    end
  end

  @tag phase81_slice: "contracts"
  test "exports every finite Wave 3 presenter seam before page composition changes" do
    assert Code.ensure_loaded?(Presenter), "Phase 81 requires #{Presenter}"

    missing =
      Enum.reject(@phase81_presenters, fn {presenter, arity} ->
        function_exported?(Presenter, presenter, arity)
      end)

    assert missing == [],
           "Phase 81 closed presentation seams are missing: #{inspect(missing)}"
  end

  @tag phase81_slice: "contracts"
  test "Wave 3 presenter source is fail-closed and names every finite render bound" do
    source = File.read!(@source_path)

    for {constant, limit} <- [
          workflow_scan_limit: 50,
          workflow_step_limit: 100,
          workflow_result_limit: 50,
          workflow_evidence_limit: 25,
          batch_member_limit: 50,
          batch_callback_limit: 25,
          batch_result_limit: 50,
          batch_audit_limit: 25,
          incident_limit: 50,
          executor_limit: 25,
          lifeline_audit_limit: 50,
          archive_limit: 25
        ] do
      assert source =~ "@#{constant} #{limit}",
             "Phase 81 requires @#{constant} #{limit} at the closed presentation boundary"
    end

    for forbidden <- [
          "preview_token",
          "plan_hash",
          "before_snapshot",
          "after_snapshot",
          "raw_metadata",
          "provider_error"
        ] do
      refute Regex.match?(~r/\b#{forbidden}\s*:/, source),
             "Phase 81 presenter output must not expose #{forbidden}"
    end
  end

  @tag phase81_slice: "lifeline"
  test "Lifeline incident projections are exact, taxonomy-backed, and uniformly unavailable" do
    incident = %Incident{
      id: "5ca1dafe-cd96-42e0-a5ed-f5887e7e02a1",
      incident_class: "dead_executor",
      status: "active",
      incident_fingerprint: "dead_executor:alpha",
      health_state: "missing",
      summary: "Executor alpha stopped reporting",
      affected_counts: %{"jobs" => 3},
      first_detected_at: ~U[2026-07-29 12:00:00Z],
      last_detected_at: ~U[2026-07-29 12:05:00Z],
      evidence: %{"preview_token" => "SYNTHETIC_PREVIEW_TOKEN"},
      metadata: %{"plan_hash" => "SYNTHETIC_PLAN_HASH"}
    }

    row_source = %{
      id: "incident-row-1",
      incident: incident,
      target_summary: "3 affected jobs",
      previewable?: true
    }

    context = %{
      detail_href: "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Aalpha",
      authorized_hrefs: ["/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Aalpha"]
    }

    assert %{
             id: "incident-row-1",
             subject: "Executor alpha stopped reporting",
             status: :active,
             status_spec: %{
               label: "Active",
               tone: :warning,
               icon: :alert,
               sr_prefix: "Lifeline incident status"
             },
             severity: :danger,
             observed_at: "2026-07-29T12:05:00Z",
             affected_scope: "3 affected jobs",
             preview_available?: true,
             detail_href:
               "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Aalpha"
           } = Presenter.present_incident_row(row_source, context)

    detail =
      Presenter.present_incident_detail(row_source, %{
        current_diagnosis: "The executor is missing.",
        provenance: "Current retained Lifeline evidence",
        legal_route: "/ops/jobs/forensics?resource_type=lifeline_incident",
        authorized_hrefs: ["/ops/jobs/forensics?resource_type=lifeline_incident"],
        history: Enum.map(1..51, &%{label: "Evidence #{&1}", occurred_at: ~U[2026-07-29 12:00:00Z]})
      })

    assert Map.keys(detail) |> Enum.sort() ==
             ~w[
               affected_scope completeness current_diagnosis history id legal_route provenance
               status status_spec subject
             ]a

    assert length(detail.history) == 50
    assert detail.completeness == :partial

    unavailable_context = %{authorized?: false}

    assert Presenter.present_incident_detail(row_source, unavailable_context) ==
             Presenter.present_incident_detail(%{malformed: true}, unavailable_context)

    serialized = inspect({Presenter.present_incident_row(row_source, context), detail})
    refute serialized =~ "SYNTHETIC_PREVIEW_TOKEN"
    refute serialized =~ "SYNTHETIC_PLAN_HASH"
  end

  @tag phase81_slice: "lifeline"
  test "Lifeline support evidence is finite, exact, and taxonomy-backed" do
    summary =
      Presenter.present_lifeline_summary(%{
        status: "healthy",
        active_count: 2,
        resolved_count: 4,
        pending_preview_count: 1,
        archived_repair_count: 8,
        completeness: :partial
      })

    assert summary == %{
             status: :healthy,
             status_spec: %{
               label: "Healthy",
               tone: :success,
               icon: :check,
               sr_prefix: "Lifeline health"
             },
             active_count: 2,
             resolved_count: 4,
             pending_preview_count: 1,
             archived_repair_count: 8,
             completeness: :partial
           }

    assert Presenter.present_executor_row(%{
             executor_id: "executor-alpha",
             health_state: "healthy",
             last_heartbeat_at: ~U[2026-07-29 12:00:00Z]
           }) == %{
             id: "executor-alpha",
             name: "executor-alpha",
             status: :healthy,
             status_spec: %{
               label: "Healthy",
               tone: :success,
               icon: :check,
               sr_prefix: "Lifeline health"
             },
             observed_at: "2026-07-29T12:00:00Z",
             guidance: "No Lifeline action is indicated by this current heartbeat."
           }

    archive = %ArchiveRun{
      id: "b107d26d-39e2-49d8-8ec1-c2ec584283ba",
      status: "completed",
      archived_count: 8,
      pruned_count: 3,
      blocked_count: 1,
      started_at: ~U[2026-07-29 11:00:00Z],
      finished_at: ~U[2026-07-29 11:05:00Z],
      metadata: %{"secret" => "SYNTHETIC_SECRET"}
    }

    assert Presenter.present_archive_summary(archive) == %{
             status: :completed,
             status_spec: %{
               label: "Completed",
               tone: :success,
               icon: :check,
               sr_prefix: "Lifeline incident status"
             },
             retained_count: 8,
             pruned_count: 3,
             blocked_count: 1,
             observed_at: "2026-07-29T11:05:00Z",
             completeness: :complete,
             guidance: "Archive history is retained evidence, not current incident truth."
           }
  end

  @tag phase81_slice: "lifeline"
  test "repair confirmation and outcomes never project capability identity or atomicity claims" do
    preview = %RepairPreview{
      status: "ready",
      action: "job_rescue",
      affected_counts: %{"jobs" => 2},
      preview_token: "1d4e55f8-f78b-46a0-a6db-e042f654a0fd",
      plan_hash: "SYNTHETIC_PLAN_HASH",
      before_snapshot: %{"secret" => "SYNTHETIC_BEFORE"},
      after_snapshot: %{"secret" => "SYNTHETIC_AFTER"},
      evidence: %{"provider_error" => "SYNTHETIC_PROVIDER_ERROR"}
    }

    confirmation =
      Presenter.present_repair_confirmation(
        preview,
        %{
          action_label: "Rescue affected jobs",
          object_label: "Dead executor incident",
          observed_at: ~U[2026-07-29 12:05:00Z],
          observed_state: "Executor missing",
          affected_records: ["Job 41", "Job 42"],
          proposed_changes: ["Mark each eligible job retryable"],
          non_effects: ["Does not guarantee downstream completion"]
        },
        %{}
      )

    assert Map.keys(confirmation) |> Enum.sort() ==
             ~w[
               action affected_records consequence non_effects object_label observed_at
               observed_state progress proposed_changes reversibility state status_spec
               support_boundary title
             ]a

    assert confirmation.state == :preview
    assert confirmation.progress == nil
    assert confirmation.support_boundary =~ "per target"
    assert confirmation.support_boundary =~ "non-atomic"
    refute confirmation.support_boundary =~ "exactly once"

    for state <- ~w[success partial skipped failed drifted expired consumed disconnected interrupted] do
      result =
        Presenter.present_repair_result(
          %{state: state, target_results: [%{state: state, label: "Job 41"}]},
          %{audit_href: "/ops/jobs/audit?event_type=lifeline.repair_executed"}
        )

      assert result.state == String.to_existing_atom(state)
      assert result.requires_fresh_preview? == (state != "success")
      assert result.audit_href == if(state == "success", do: "/ops/jobs/audit?event_type=lifeline.repair_executed", else: nil)
      assert result.receipt == if(state == "success", do: "Repair outcome recorded. Audit evidence is available.", else: nil)
    end

    serialized = inspect({confirmation, Presenter.present_repair_result(%{state: "failed"}, %{})})

    for sentinel <- ~w[
          SYNTHETIC_PLAN_HASH SYNTHETIC_BEFORE SYNTHETIC_AFTER SYNTHETIC_PROVIDER_ERROR
          1d4e55f8-f78b-46a0-a6db-e042f654a0fd
        ] do
      refute serialized =~ sentinel
    end
  end

  @tag phase81_slice: "lifeline"
  test "Lifeline Audit projection is typed, bounded by caller reads, and route-authorized" do
    event = %Audit{
      id: 42,
      actor_id: "operator-1",
      action: "lifeline.repair_executed",
      event_type: "lifeline.repair_executed",
      resource: "job:41",
      resource_type: "job",
      resource_id: "41",
      inserted_at: ~N[2026-07-29 12:10:00],
      metadata: %{
        "reason" => "SYNTHETIC_RAW_REASON",
        "preview_token" => "SYNTHETIC_PREVIEW_TOKEN"
      }
    }

    href = "/ops/jobs/audit?resource_type=job&resource_id=41"

    assert Presenter.present_lifeline_audit_entry(event, %{
             actor_label: "Operator 1",
             target_label: "Job 41",
             safe_reason: "Incident response approved",
             evidence_href: href,
             authorized_hrefs: [href]
           }) == %{
             id: "42",
             event_label: "Repair executed",
             target_label: "Job 41",
             actor_label: "Operator 1",
             reason: "Incident response approved",
             recorded_at: "2026-07-29T12:10:00",
             evidence_href: href
           }
  end

  @tag phase81_slice: "batches"
  test "Batches detail projection is exact, bounded, and confidentiality safe" do
    members =
      for id <- 1..51 do
        %{
          job_id: id,
          worker: "MyApp.Worker",
          queue: "default",
          oban_state: "discarded",
          attempt: 1,
          max_attempts: 20,
          last_error_display: {:string, "safe failure"},
          bridge_path: "/ops/jobs/oban/jobs/#{id}",
          retry_eligible?: true,
          args: %{"secret" => "must-not-render"}
        }
      end

    callbacks =
      for id <- 1..26 do
        %{
          id: "callback-#{id}",
          event: "batch.exhausted",
          dedupe_key: "dedupe-#{id}",
          status: "failed",
          attempts: 1,
          last_error_display: {:string, "safe callback failure"},
          retry_eligible?: true,
          payload: %{"secret" => "must-not-render"}
        }
      end

    detail =
      Presenter.present_batch_detail(
        %{
          id: "batch-1",
          name: "Billing replay",
          status: "callback_failed",
          progress: %{total_count: 51, completed_count: 2, percent: 3.9},
          blocked_state: %{
            name: :callback_failed,
            severity: :warning,
            title: "Callback failed",
            copy: "A callback requires review.",
            evidence: %{discard_count: 2, provider_error: "must-not-render"}
          },
          failed_members: members,
          callbacks: callbacks,
          callback_summary: %{total: 26, failed: 26},
          chain_context: %{chain?: true, chain_id: "chain-1"},
          audit_events: []
        },
        %{back_href: "/ops/jobs/batches?status=all"}
      )

    assert Map.keys(detail) |> Enum.sort() ==
             ~w[
               audit_events audit_evidence back_href blocked_state callback_evidence
               callback_summary callbacks chain_context completed_at failed_members id
               inserted_at member_evidence name progress result_evidence results status updated_at
             ]a
             |> Enum.sort()

    assert length(detail.failed_members) == 50
    assert length(detail.callbacks) == 25
    refute detail.member_evidence.complete?
    refute detail.callback_evidence.complete?
    assert detail.member_evidence.guidance =~ "partial evidence"
    refute inspect(detail) =~ "must-not-render"
  end

  @tag phase81_slice: "batches"
  test "Batches retry projection omits preview authority and preserves finite outcome truth" do
    presentation =
      Presenter.present_batch_retry_preview(
        %{
          status: "drifted",
          action: "job_retry",
          preview_token: "must-not-render",
          plan_hash: "must-not-render"
        },
        %{selected_count: 2, object_label: "Batch billing"}
      )

    assert presentation.state == :drifted
    assert presentation.scope == "2 currently eligible failed jobs"
    refute Map.has_key?(presentation, :preview_token)
    refute Map.has_key?(presentation, :plan_hash)
    refute inspect(presentation) =~ "must-not-render"

    assert_raise ArgumentError, fn ->
      Presenter.present_batch_detail([], %{})
    end
  end

  test "Forensics returns exactly eight diagnosis-first redaction-safe fields" do
    lifeline_href =
      "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Aalpha&view=active"

    audit_href =
      "/ops/jobs/audit?resource_type=job&resource_id=42"

    page =
      present(:present_forensics, [
        forensic_evidence_fixture(),
        %{authorized_hrefs: [lifeline_href, audit_href]}
      ])

    assert Map.keys(page) |> Enum.sort() ==
             Enum.sort([
               :support,
               :scope,
               :summary,
               :next_steps,
               :latest_remediation,
               :events,
               :coverage,
               :audit_href
             ])

    assert page.support == %{
             state: :ready,
             heading: "Read-only evidence",
             copy:
               "Forensics summarizes retained Powertools evidence and does not prove root cause."
           }

    assert page.scope == %{
             type: :lifeline_incident,
             type_label: "Lifeline incident",
             identity: "dead_executor:alpha",
             subject: "Executor alpha is unavailable",
             ownership: "Powertools-native Lifeline"
           }

    assert Map.keys(page.summary) |> Enum.sort() ==
             Enum.sort([
               :heading,
               :diagnosis,
               :detail,
               :provenance,
               :completeness,
               :coverage
             ])

    assert page.summary.heading == "Investigation summary"
    assert page.summary.diagnosis == "Blocked"
    assert page.summary.provenance == "Durable evidence"
    assert page.summary.completeness == "Partial evidence"
    assert page.summary.coverage == "Showing the newest 2 events; more evidence exists."

    assert page.next_steps == [
             %{
               id: "review-incident-in-lifeline",
               label: "Review incident in Lifeline",
               href: lifeline_href,
               role: :primary,
               support:
                 "Review current evidence and reauthorize the incident before taking any action."
             }
           ]

    assert page.latest_remediation == %{
             heading: "Latest remediation evidence",
             historical?: true,
             status: "Succeeded",
             summary:
               "Historical Lifeline repair evidence was recorded. It does not change the current diagnosis.",
             occurred_at: "July 28, 2026 at 14:00 UTC",
             occurred_datetime: "2026-07-28T14:00:00Z",
             provenance: "Inspection only"
           }

    assert page.audit_href == audit_href
    assert Enum.map(page.events, & &1.id) == ["forensic-event-repair", "forensic-event-opened"]

    for event <- page.events do
      assert Map.keys(event) |> Enum.sort() ==
               Enum.sort([
                 :id,
                 :timestamp,
                 :datetime,
                 :title,
                 :source,
                 :status,
                 :domain,
                 :state,
                 :notes,
                 :follow_ups
               ])

      assert is_binary(event.timestamp)
      assert is_binary(event.datetime)
      assert is_binary(event.title)
      assert is_binary(event.source)
      assert is_binary(event.status)
      assert event.domain == :forensics
      assert is_atom(event.state)
      assert is_list(event.follow_ups)
    end

    assert page.coverage == %{
             heading: "Evidence limits and sources",
             summary: "Showing the newest 2 events; more evidence exists.",
             shown_count: 2,
             total_count: nil,
             has_more?: true,
             bounded?: true,
             completeness: "Partial evidence",
             retention: "The newest retained incident and Audit evidence is shown.",
             sources: [
               %{
                 id: "lifeline",
                 label: "Lifeline",
                 shown_count: 1,
                 total_count: 1,
                 has_more?: false,
                 limit: 1,
                 provenance: "Durable evidence",
                 completeness: "Complete",
                 retention: "Current retained incident evidence."
               },
               %{
                 id: "audit",
                 label: "Audit",
                 shown_count: 1,
                 total_count: nil,
                 has_more?: true,
                 limit: 50,
                 provenance: "Inspection only",
                 completeness: "Partial evidence",
                 retention: "Newest retained Audit evidence for this incident scope."
               }
             ]
           }

    serialized = inspect(page, printable_limit: :infinity, limit: :infinity)

    for sentinel <- ~w[
          SYNTHETIC_REASON SYNTHETIC_RUNBOOK SYNTHETIC_ERROR SYNTHETIC_STACKTRACE
          SYNTHETIC_PAYLOAD SYNTHETIC_URL SYNTHETIC_HEADER SYNTHETIC_TOKEN
          SYNTHETIC_CREDENTIAL SYNTHETIC_METADATA
        ] do
      refute serialized =~ sentinel
    end

    refute serialized =~ "repair_executed"
    refute serialized =~ "bridge_only"

    refute "incident_fingerprint" in (page
                                      |> nested_keys()
                                      |> Enum.map(&normalize_key/1))
  end

  test "Forensics guidance is authorized noun-only canonical-URL-deduplicated and fail closed" do
    evidence = forensic_evidence_fixture()

    page =
      present(:present_forensics, [
        evidence,
        %{
          authorized_hrefs: [
            "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Aalpha&view=active",
            "/ops/jobs/workflows/workflow-1?step=sync"
          ]
        }
      ])

    assert Enum.map(page.next_steps, & &1.label) == [
             "Review incident in Lifeline",
             "Open workflow"
           ]

    assert Enum.map(page.next_steps, & &1.role) == [:primary, :additional]
    assert page.audit_href == nil
    assert Enum.uniq_by(page.next_steps, &canonical_href(&1.href)) == page.next_steps

    allowed_labels = [
      "Open workflow",
      "Review incident in Lifeline",
      "Open cron entry",
      "Review limiter blockers",
      "View matching audit evidence"
    ]

    assert Enum.all?(page.next_steps, &(&1.label in allowed_labels))

    closed = present(:present_forensics, [evidence, %{}])
    assert closed.next_steps == []
    assert closed.audit_href == nil
    assert Enum.all?(closed.events, &(&1.follow_ups == []))
  end

  test "Forensics omits remediation without genuine Lifeline repair history and caps safe notes" do
    evidence =
      forensic_evidence_fixture()
      |> put_in([:subject, :type], "workflow")
      |> put_in([:subject, :id], "workflow-1")
      |> put_in([:subject, :label], "Billing workflow")
      |> put_in([:subject, :entry_surface], "Powertools-native workflows")
      |> put_in([:chronology], [
        %{
          id: "forensic-event-workflow",
          occurred_at: ~U[2026-07-28 15:00:00Z],
          label: "Workflow state was recorded",
          resource_type: "workflow",
          resource_id: "workflow-1",
          source_family: "workflow",
          strength: :durable,
          event_type: "workflow.step_state",
          status: :waiting,
          notes: String.duplicate("界", 1_200)
        }
      ])

    page = present(:present_forensics, [evidence, %{authorized_hrefs: []}])

    assert page.latest_remediation == nil
    assert [event] = page.events
    assert String.length(event.notes) == 1_000
    assert String.ends_with?(event.notes, "…")
    assert event.status == "Waiting"
    assert event.state == :waiting
  end

  test "Jobs row projects exactly eight grammatical table and control facts" do
    job = job_fixture()

    row =
      present(:present_job_row, [
        job,
        %{selected?: true, reviewing?: true}
      ])

    assert Map.keys(row) |> Enum.sort() ==
             Enum.sort([
               :id,
               :worker,
               :state,
               :queue,
               :scheduled,
               :attempts,
               :selection,
               :review
             ])

    assert row.id == 42
    assert row.worker == "Acme.Workers.ReconcileCustomerLedger"
    assert row.state == "retryable"
    assert row.queue == "critical"

    assert row.scheduled == %{
             label: "July 28, 2026 at 02:00 UTC",
             datetime: "2026-07-28T02:00:00Z"
           }

    assert row.attempts == "3 of 20"
    assert row.selection == %{label: "Select job 42", checked?: true}
    assert row.review == %{label: "Review job 42", current?: true}
  end

  test "Jobs quick review exposes only bounded identity and availability truth" do
    review =
      present(:present_job_quick_review, [
        job_fixture(),
        %{
          recorded_output_available?: true,
          list_params: [
            {"state", "retryable"},
            {"page", "2"},
            {"job", "42"},
            {"return_to", "https://attacker.invalid/?token=SYNTHETIC_TOKEN"}
          ]
        }
      ])

    assert Map.keys(review) |> Enum.sort() ==
             Enum.sort([
               :id,
               :title,
               :state,
               :worker,
               :queue,
               :attempts,
               :relevant_time,
               :failure_summary,
               :recorded_output_available?,
               :enqueue_redaction,
               :full_details_href
             ])

    assert review.id == 42
    assert review.title == "Review job 42"
    assert review.state == %{value: "retryable", label: "Retryable"}
    assert review.worker == "Acme.Workers.ReconcileCustomerLedger"
    assert review.queue == "critical"
    assert review.attempts == "3 of 20"

    assert review.relevant_time == %{
             label: "Attempted",
             value: "July 28, 2026 at 02:05 UTC",
             datetime: "2026-07-28T02:05:00Z"
           }

    assert review.failure_summary ==
             "Latest failure recorded. Open full job details for the redacted error summary."

    assert review.recorded_output_available?

    assert review.enqueue_redaction == %{
             redacted?: true,
             summary: "2 argument fields were redacted at enqueue."
           }

    assert review.full_details_href ==
             "/ops/jobs/jobs/42?state=retryable&page=2"
  end

  test "Jobs browse presenters drop nested sensitive aliases and source sentinels" do
    sensitive_sources = [
      {"token", %{"preview_token" => "SYNTHETIC_TOKEN"}},
      {"secret", %{"clientSecret" => "SYNTHETIC_SECRET"}},
      {"password", %{"password" => "SYNTHETIC_PASSWORD"}},
      {"credential", %{"credentials" => ["SYNTHETIC_CREDENTIAL"]}},
      {"authorization", %{"authorization" => "SYNTHETIC_AUTHORIZATION"}},
      {"cookie", %{"cookie" => "SYNTHETIC_COOKIE"}},
      {"header", %{"headers" => [%{"x-api-key" => "SYNTHETIC_HEADER"}]}},
      {"url query", %{"url" => "https://example.test/?key=SYNTHETIC_URL_QUERY"}},
      {"metadata", %{"metadata" => %{"provider" => "SYNTHETIC_METADATA"}}},
      {"payload", %{"payload" => %{"body" => "SYNTHETIC_PAYLOAD"}}},
      {"reason", %{"reason" => "SYNTHETIC_REASON"}},
      {"exception", %{"exception" => %{"message" => "SYNTHETIC_EXCEPTION"}}},
      {"stacktrace", %{"stacktrace" => ["SYNTHETIC_STACKTRACE"]}}
    ]

    forbidden_keys =
      ~w[
        args meta metadata payload stacktrace exception reason token secret password credential
        credentials authorization cookie header headers audit_history attempt_history actions
        mutation
      ]

    for {alias_name, nested} <- sensitive_sources do
      job = %{
        job_fixture()
        | args: %{"nested" => nested},
          meta: %{
            "__redacted_fields__" => ["password"],
            "nested" => nested
          },
          errors: [
            %{
              "attempt" => 3,
              "at" => "2026-07-28T02:05:00Z",
              "error" => nested
            }
          ],
          unsaved_error: nested
      }

      context = %{
        selected?: false,
        reviewing?: false,
        recorded_output_available?: true,
        list_params: [{"state", "retryable"}],
        provider_metadata: nested
      }

      outputs = [
        present(:present_job_row, [job, context]),
        present(:present_job_quick_review, [job, context])
      ]

      for output <- outputs do
        serialized = inspect(output, printable_limit: :infinity, limit: :infinity)

        refute serialized =~ "SYNTHETIC_",
               "#{alias_name} sentinel survived Jobs presentation"

        output
        |> nested_keys()
        |> Enum.map(&normalize_key/1)
        |> Enum.each(fn key ->
          refute key in forbidden_keys,
                 "#{alias_name} projected forbidden key #{inspect(key)}"
        end)
      end
    end
  end

  test "Jobs full detail is a closed incident-first projection with policy-safe displays" do
    detail =
      present(:present_job_detail, [
        job_fixture(),
        %{
          args_display: {:raw_json, ~s({"customer_id":"[redacted]"})},
          meta_display: {:string, "Metadata hidden by host policy."},
          recorded_output_display: %{
            available?: false,
            summary: "No recorded output found for this job.",
            status: nil,
            payload: "No recorded output found for this job.",
            redacted?: false
          },
          audit_href: "/ops/jobs/audit?resource_type=job&resource_id=42"
        }
      ])

    assert Map.keys(detail) |> Enum.sort() ==
             Enum.sort([
               :support,
               :actions,
               :identity,
               :timing,
               :errors,
               :data,
               :redaction,
               :destinations
             ])

    assert detail.support == %{
             heading: "Current state",
             state: "retryable",
             state_label: "Retryable",
             summary: "This job is retryable.",
             availability: "Current job detail is available for operator review."
           }

    assert Enum.map(detail.actions, & &1.kind) == [:retry, :cancel, :discard]

    assert Enum.map(detail.identity, & &1.label) ==
             ["Job ID", "Worker", "Queue", "State", "Attempts", "Priority"]

    assert Enum.map(detail.timing, & &1.label) ==
             ["Inserted", "Scheduled", "Attempted", "Completed", "Cancelled", "Discarded"]

    assert [%{class: "RuntimeError", message: "provider request failed"} = error] =
             detail.errors

    assert error.occurred_at == "July 28, 2026 at 02:05 UTC"
    assert error.occurred_datetime == "2026-07-28T02:05:00Z"
    refute error.truncated?

    assert detail.data.arguments.display == {:raw_json, ~s({"customer_id":"[redacted]"})}
    assert detail.data.metadata.display == {:string, "Metadata hidden by host policy."}
    assert detail.data.recorded_output.display.available? == false

    assert detail.redaction.enqueue == %{
             redacted?: true,
             summary: "2 argument fields were redacted at enqueue."
           }

    assert detail.destinations == [
             %{
               id: "job-audit",
               label: "View matching audit evidence",
               href: "/ops/jobs/audit?resource_type=job&resource_id=42"
             }
           ]

    serialized = inspect(detail, printable_limit: :infinity, limit: :infinity)
    refute serialized =~ "cust-42"
    refute serialized =~ "__redacted_fields__"
    refute serialized =~ "** (RuntimeError)"
  end

  test "Jobs full detail retains only the newest ten safe bounded errors" do
    long_message = String.duplicate("界", 1_050)

    errors =
      Enum.map(1..12, fn attempt ->
        %{
          "attempt" => attempt,
          "at" => DateTime.add(~U[2026-07-28 02:00:00Z], attempt, :minute),
          "error" =>
            "** (RuntimeError) #{if(attempt == 12, do: long_message, else: "failure #{attempt}")}"
        }
      end)

    detail =
      present(:present_job_detail, [
        %{job_fixture() | errors: Enum.reverse(errors)},
        detail_context()
      ])

    assert length(detail.errors) == 10
    assert hd(detail.errors).occurred_datetime == "2026-07-28T02:12:00Z"
    assert List.last(detail.errors).occurred_datetime == "2026-07-28T02:03:00Z"
    assert hd(detail.errors).truncated?
    assert String.length(hd(detail.errors).message) == 1_000
    assert String.ends_with?(hd(detail.errors).message, "…")

    sensitive =
      present(:present_job_detail, [
        %{
          job_fixture()
          | errors: [
              %{
                "attempt" => 4,
                "at" => "2026-07-28T02:06:00Z",
                "error" =>
                  "** (RuntimeError) request failed at https://secret.invalid/?token=SYNTHETIC_TOKEN"
              },
              %{"unexpected" => %RuntimeError{message: "SYNTHETIC_EXCEPTION"}}
            ]
        },
        detail_context()
      ])

    refute inspect(sensitive) =~ "SYNTHETIC_"
    assert Enum.any?(sensitive.errors, &(&1.message == "Failure details are redacted."))
    assert Enum.any?(sensitive.errors, &(&1.message == "Failure details are unavailable."))
  end

  test "single job actions use exact labels, intent, consequence, and support copy" do
    expected = %{
      retry: %{
        intent: :warning,
        confirm_label: "Retry job",
        dismiss_label: "Keep current state",
        consequence:
          "Powertools requests a retry for each ready job. A retry request does not mean the job completed."
      },
      cancel: %{
        intent: :danger,
        confirm_label: "Cancel job",
        dismiss_label: "Keep running",
        consequence: "Each ready job stops and will not retry. This cannot be undone."
      },
      discard: %{
        intent: :danger,
        confirm_label: "Discard job",
        dismiss_label: "Keep current state",
        consequence:
          "Each ready job is marked discarded and will not retry. This cannot be undone."
      }
    }

    for {kind, contract} <- expected do
      action = present(:present_job_action, [kind])

      assert Map.keys(action) |> Enum.sort() ==
               Enum.sort([
                 :kind,
                 :intent,
                 :title,
                 :object_label,
                 :scope,
                 :confirm_label,
                 :dismiss_label,
                 :consequence,
                 :reversibility,
                 :support_boundary,
                 :pending_copy
               ])

      assert Map.take(action, Map.keys(contract)) == contract
      assert action.support_boundary =~ "Audit"
      refute action.title in ["Confirm", "Are you sure?"]
    end

    assert_raise ArgumentError, ~r/job action/i, fn ->
      present(:present_job_action, [:unknown])
    end
  end

  test "single job action results keep clean success distinct from every recovery state" do
    success =
      present(:present_job_action_result, [
        %{
          state: :success,
          action: :retry,
          job_id: 42,
          audit_href: "/ops/jobs/audit?resource_type=job&resource_id=42"
        }
      ])

    assert success == %{
             state: :success,
             message: "The retry request was recorded.",
             recovery: nil,
             receipt: "Retry requested for job 42. Audit evidence recorded.",
             audit_href: "/ops/jobs/audit?resource_type=job&resource_id=42",
             requires_fresh_preview?: false
           }

    for state <- [:skipped, :failed, :expired, :drifted, :consumed] do
      result =
        present(:present_job_action_result, [
          %{state: state, action: :retry, job_id: 42}
        ])

      assert result.state == state
      assert result.receipt == nil
      assert result.recovery =~ "Create a new preview"
      assert result.requires_fresh_preview?
    end

    unknown =
      present(:present_job_action_result, [
        %{
          state: :provider_failure,
          raw_error: %RuntimeError{message: "SYNTHETIC_INTERNAL_ERROR"},
          preview_token: "SYNTHETIC_PREVIEW_TOKEN"
        }
      ])

    assert unknown.state == :failed
    assert unknown.receipt == nil
    assert unknown.requires_fresh_preview?
    refute inspect(unknown) =~ "SYNTHETIC_"
  end

  test "Jobs detail rejects unsafe component displays and external evidence destinations" do
    assert_raise ArgumentError, ~r/prohibited source field/i, fn ->
      present(:present_job_detail, [
        job_fixture(),
        Map.put(detail_context(), :args_display, {:raw_json, ~s({"token":"SYNTHETIC"})})
      ])
    end

    assert_raise ArgumentError, ~r/destination/i, fn ->
      present(:present_job_detail, [
        job_fixture(),
        Map.put(
          detail_context(),
          :audit_href,
          "https://attacker.invalid/?token=SYNTHETIC_TOKEN"
        )
      ])
    end
  end

  @tag phase79_slice: "shared"
  test "Overview presentation preserves fixed bridge truth and bounds deterministic exemplars" do
    input = %{
      id: "bridge-only-follow-up",
      kind: :bridge_only,
      title: "Bridge-only Follow-up",
      count: 4,
      summary: "Representative follow-up remains in Oban Web.",
      impact: "Powertools does not own this inspection surface.",
      observed_at: "July 19, 2026 at 14:00 UTC",
      observed_datetime: "2026-07-19T14:00:00Z",
      domain: :overview,
      status: :bridge_only,
      severity: :neutral,
      completeness: :partial,
      ownership: :oban_web_bridge,
      next_step_path: "/ops/jobs/oban",
      exemplars: Enum.map(1..4, &%{id: "follow-up-#{&1}", label: "Follow-up #{&1}"})
    }

    presented = present(:present_overview_bucket, [input])

    assert Map.keys(presented) |> Enum.sort() ==
             Enum.sort([
               :id,
               :kind,
               :title,
               :count,
               :summary,
               :impact,
               :observed_at,
               :observed_datetime,
               :domain,
               :status,
               :severity,
               :completeness,
               :ownership,
               :sample_count_label,
               :next_step_label,
               :next_step_path,
               :exemplars
             ])

    assert presented.title == "Bridge-only Follow-up"
    assert presented.sample_count_label == "4 representative follow-ups"
    assert presented.next_step_label == "Inspect in Oban Web"
    assert presented.next_step_path == "/ops/jobs/oban"
    assert Enum.map(presented.exemplars, & &1.id) == ~w[follow-up-1 follow-up-2 follow-up-3]
    refute inspect(presented) =~ "global total"
  end

  @tag phase79_slice: "shared"
  test "Cron actions use exact action-specific labels, warning intent, and consequence truth" do
    expectations = [
      pause: {
        "Pause cron entry",
        "Keep running",
        "Future schedule claims stop. Work that is already running or enqueued is unaffected."
      },
      resume: {
        "Resume cron entry",
        "Keep paused",
        "Future schedule claims continue. Missed work is not run retroactively."
      },
      run_now: {
        "Run cron entry now",
        "Keep current schedule",
        "Powertools attempts a manual schedule-slot claim. Overlap policy may skip, queue, or enqueue it."
      }
    ]

    for {kind, {confirm, dismiss, consequence}} <- expectations do
      action = present(:present_cron_action, [%{kind: kind, object_label: "nightly"}])

      assert Map.keys(action) |> Enum.sort() ==
               Enum.sort([
                 :kind,
                 :confirm_label,
                 :dismiss_label,
                 :title,
                 :consequence,
                 :support_boundary,
                 :pending_copy,
                 :intent
               ])

      assert action.kind == kind
      assert action.confirm_label == confirm
      assert action.dismiss_label == dismiss
      assert action.consequence == consequence
      assert action.intent == :warning
      refute action.title in ["Confirm", "Are you sure?"]
    end
  end

  @tag phase79_slice: "shared"
  test "Cron result presentation never turns a recorded run-now claim into completed work" do
    result =
      present(:present_cron_result, [
        %{
          kind: :run_now,
          state: :skipped,
          recorded_result: "overlap policy skipped the slot claim",
          audit_href: "/ops/jobs/audit?resource_type=cron_entry&resource_id=nightly"
        }
      ])

    assert Map.keys(result) |> Enum.sort() ==
             Enum.sort([
               :state,
               :message,
               :recorded_result,
               :recovery,
               :audit_href,
               :receipt
             ])

    assert result.state == :skipped
    assert result.recovery =~ "preview"
    assert result.receipt == nil
    refute String.downcase(result.message) =~ "job ran"
    refute String.downcase(result.message) =~ "completed"
  end

  @tag phase79_slice: "shared"
  test "Limiter presentation keeps affected scope and omits internal classifier codes" do
    blocker =
      present(:present_limiter_blocker, [
        %{
          id: "global-cooldown",
          evidence_kind: :current,
          technical_code: "cooldown_active",
          label: "Cooldown is active",
          summary: "New reservations wait until the cooldown clears.",
          affected_scope: "All queues using the billing limiter",
          clearing_condition: "Wait for the cooldown window to end.",
          evidence_source: "Current limiter state"
        }
      ])

    assert blocker == %{
             id: "global-cooldown",
             evidence_kind: :current,
             label: "Cooldown is active",
             summary: "New reservations wait until the cooldown clears.",
             affected_scope: "All queues using the billing limiter",
             clearing_condition: "Wait for the cooldown window to end.",
             evidence_source: "Current limiter state"
           }

    refute Map.has_key?(blocker, :technical_code)
    refute inspect(blocker) =~ "cooldown_active"
  end

  @tag phase79_slice: "shared"
  test "Audit row and detail use exact absence copy, Recorded at, and closed safe fields" do
    event = %Audit{
      id: 41,
      actor_id: nil,
      action: "lifeline.repair_requested",
      command_key: "execute_repair",
      event_type: "lifeline.repair_requested",
      resource: "job:123",
      resource_type: "job",
      resource_id: "123",
      metadata: %{},
      inserted_at: ~N[2026-07-19 14:30:00.000000]
    }

    context = %{surface: :audit, section: :selected_evidence}
    row = present(:present_audit_row, [event, context])
    detail = present(:present_audit_detail, [event, context])

    assert Map.keys(row) |> Enum.sort() ==
             Enum.sort([
               :id,
               :event_label,
               :target_label,
               :target_href,
               :actor,
               :reason_summary,
               :recorded_at,
               :recorded_datetime,
               :evidence_href,
               :evidence_label
             ])

    assert row.reason_summary == "No operator reason recorded"
    assert row.recorded_at =~ "UTC"
    assert row.recorded_datetime == "2026-07-19T14:30:00.000000Z"
    assert row.evidence_href =~ "resource_type=job&resource_id=123&page=1&event=41"

    assert detail.reason == "No operator reason recorded"
    assert detail.outcome == "Outcome not recorded"
    assert detail.source == "Source not recorded"
    assert detail.correlation == "Correlation not recorded"
    assert detail.recorded_at_label == "Recorded at"
    assert detail.occurred_datetime == row.recorded_datetime
    refute inspect(detail) =~ "execute_repair"
  end

  @tag phase79_slice: "shared"
  test "Audit detail redacts sensitive semantic change identifiers and preserves safe siblings" do
    event = %Audit{
      id: 42,
      actor_id: "operator-1",
      action: "cron.reconfigured",
      event_type: "cron.reconfigured",
      resource: "cron_entry:nightly",
      resource_type: "cron_entry",
      resource_id: "nightly",
      metadata: %{
        "changes" => [
          %{
            "field" => "accessToken",
            "before" => "SYNTHETIC_OLD_ACCESS_TOKEN",
            "after" => "SYNTHETIC_NEW_ACCESS_TOKEN"
          },
          %{"label" => "APIKey", "value" => "SYNTHETIC_API_KEY"},
          %{"field" => "password", "value" => "SYNTHETIC_PASSWORD"},
          %{"field" => "plan_hash", "value" => "SYNTHETIC_PLAN_HASH"},
          %{"label" => "credentials", "value" => "SYNTHETIC_CREDENTIAL"},
          %{"field" => "queue", "before" => "default", "after" => "critical"}
        ]
      },
      inserted_at: ~N[2026-07-19 14:45:00.000000]
    }

    detail =
      present(:present_audit_detail, [
        event,
        %{surface: :audit, section: :selected_evidence}
      ])

    refute inspect(detail) =~ "SYNTHETIC_"

    assert detail.changes == [
             %{"field" => "queue", "before" => "default", "after" => "critical"}
           ]
  end

  @tag phase79_slice: "shared"
  test "Audit presentation rejects secret metadata and implementation-shaped evidence" do
    base = %Audit{
      id: 42,
      actor_id: "operator-1",
      action: "cron.previewed",
      event_type: "cron.previewed",
      resource: "cron_entry:nightly",
      resource_type: "cron_entry",
      resource_id: "nightly",
      inserted_at: ~N[2026-07-19 14:45:00.000000]
    }

    for metadata <- [
          %{"preview_token" => "SYNTHETIC_PREVIEW_TOKEN"},
          %{"plan_hash" => "SYNTHETIC_PLAN_HASH"},
          %{"credentials" => %{"password" => "SYNTHETIC_PASSWORD"}},
          %{"principal" => %{"access_token" => "SYNTHETIC_ACCESS_TOKEN"}},
          %{"exception" => "SYNTHETIC_EXCEPTION"},
          %{"stacktrace" => ["SYNTHETIC_STACKTRACE"]},
          %{"evidence" => %{"arbitrary_provider_blob" => "SYNTHETIC_SECRET"}}
        ] do
      assert_raise ArgumentError, fn ->
        present(:present_audit_detail, [%{base | metadata: metadata}, %{surface: :audit}])
      end
    end

    assert_raise ArgumentError, fn ->
      present(:present_audit_detail, [
        %{"metadata" => %{"preview_token" => "SYNTHETIC_PREVIEW_TOKEN"}},
        %{surface: :audit}
      ])
    end
  end

  test "normalizes active filters from finite atom and string aliases in stable order" do
    filters = [
      %{
        id: "queue-critical",
        label: "Queue",
        value: @hostile,
        remove_href: "/ops/jobs/jobs?state=available",
        remove_label: "Remove Queue: critical filter",
        ignored: "must not project"
      },
      %{
        "id" => "state-available",
        "label" => "State",
        "value" => "available",
        "remove_href" => "/ops/jobs/jobs?queue=critical",
        "remove_label" => "Remove State: available filter",
        "raw_query" => "must not project"
      }
    ]

    assert normalize(:normalize_active_filters, filters) == [
             %{
               id: "queue-critical",
               label: "Queue",
               value: @hostile,
               remove_href: "/ops/jobs/jobs?state=available",
               remove_label: "Remove Queue: critical filter"
             },
             %{
               id: "state-available",
               label: "State",
               value: "available",
               remove_href: "/ops/jobs/jobs?queue=critical",
               remove_label: "Remove State: available filter"
             }
           ]

    assert_raise ArgumentError, ~r/(duplicate|unique).*id/i, fn ->
      normalize(:normalize_active_filters, [hd(filters), hd(filters)])
    end
  end

  test "normalizes ordered success, failed, and skipped results without merging recovery" do
    input = [
      %{
        id: "result-1",
        object_label: "Job 1",
        outcome: :success,
        message: "Retry requested.",
        recovery: nil,
        audit_href: "/ops/jobs/audit?resource_id=1"
      },
      %{
        "id" => "result-2",
        "object_label" => "Job 2",
        "outcome" => "failed",
        "message" => "Retry request failed.",
        "recovery" => "Create a fresh preview.",
        "audit_href" => nil
      },
      %{
        id: "result-3",
        object_label: "Job 3",
        outcome: :skipped,
        message: "Retry skipped because the job changed.",
        recovery: "Refresh the job before acting.",
        audit_href: nil
      }
    ]

    results = normalize(:normalize_operator_results, input)

    assert Enum.map(results, & &1.id) == ~w[result-1 result-2 result-3]
    assert Enum.map(results, & &1.outcome) == [:success, :failed, :skipped]
    assert Enum.at(results, 1).recovery == "Create a fresh preview."
    assert Enum.at(results, 2).recovery == "Refresh the job before acting."

    assert Map.keys(hd(results)) |> Enum.sort() ==
             Enum.sort([:id, :object_label, :outcome, :message, :recovery, :audit_href])

    assert_raise ArgumentError, ~r/outcome/i, fn ->
      normalize(:normalize_operator_results, [Map.put(hd(input), :outcome, :unknown)])
    end
  end

  test "normalizes every blocker while keeping current and block-start evidence distinct" do
    input = [
      %{
        id: "current-queue",
        evidence_kind: :current,
        label: "Current state",
        summary: "The critical queue is paused.",
        clearing_condition: "Resume the queue after reviewing the incident.",
        evidence_source: "Live queue state",
        technical_code: "queue_paused"
      },
      %{
        "id" => "snapshot-limiter",
        "evidence_kind" => "block_start_snapshot",
        "label" => "Block-start snapshot",
        "summary" => @hostile,
        "clearing_condition" => "Refresh current limiter evidence before acting.",
        "evidence_source" => "Snapshot captured at block start",
        "technical_code" => nil
      }
    ]

    blockers = normalize(:normalize_blockers, input)

    assert Enum.map(blockers, & &1.id) == ["current-queue", "snapshot-limiter"]
    assert Enum.map(blockers, & &1.evidence_kind) == [:current, :block_start_snapshot]
    assert Enum.map(blockers, & &1.label) == ["Current state", "Block-start snapshot"]
    assert List.last(blockers).summary == @hostile
    refute inspect(blockers) =~ "root cause"
  end

  test "evidence completeness is closed and never infers complete truth" do
    for value <- [
          :complete,
          "complete",
          :partial,
          "partial",
          :unknown,
          "unknown",
          :unavailable,
          "unavailable"
        ] do
      expected = if is_binary(value), do: String.to_existing_atom(value), else: value
      assert normalize(:normalize_evidence_completeness, value) == expected
    end

    assert normalize(:normalize_evidence_completeness, nil) == :unknown
    assert normalize(:normalize_evidence_completeness, "") == :unknown
    assert normalize(:normalize_evidence_completeness, :unsupported) == :unknown

    unknown = "phase78-never-an-atom-#{System.unique_integer([:positive])}"
    assert normalize(:normalize_evidence_completeness, unknown) == :unknown
    assert_raise ArgumentError, fn -> String.to_existing_atom(unknown) end
  end

  test "audit normalization preserves absolute history and explicit missing reason and outcome" do
    input = %{
      "sentence" => "System policy requested a retry for job job-123.",
      "outcome" => nil,
      "actor" => "System policy",
      "action" => "Retry requested",
      "target" => @hostile,
      "reason" => nil,
      "source" => "Powertools-native",
      "correlation" => "audit-2026-0001",
      "occurred_at" => "July 18, 2026 at 21:00 UTC",
      "occurred_datetime" => "2026-07-18T21:00:00Z",
      "changes" => [%{"field" => "queue", "before" => "default", "after" => "critical"}],
      "evidence" => "Already redacted evidence",
      "preview_token" => nil
    }

    assert normalize(:normalize_audit_entry, input) == %{
             sentence: "System policy requested a retry for job job-123.",
             outcome: "Outcome not recorded",
             outcome_state: :unknown,
             actor: "System policy",
             action: "Retry requested",
             target: @hostile,
             reason: "No operator reason recorded",
             source: "Powertools-native",
             correlation: "audit-2026-0001",
             occurred_at: "July 18, 2026 at 21:00 UTC",
             occurred_datetime: "2026-07-18T21:00:00Z",
             changes: [%{"field" => "queue", "before" => "default", "after" => "critical"}],
             evidence: "Already redacted evidence"
           }

    assert normalize(:normalize_audit_entry, Map.put(input, "outcome_state", "failed")).outcome_state ==
             :failed

    assert_raise ArgumentError, ~r/outcome state/i, fn ->
      normalize(:normalize_audit_entry, Map.put(input, "outcome_state", "invalid"))
    end

    assert_raise ArgumentError, ~r/datetime/i, fn ->
      normalize(:normalize_audit_entry, Map.put(input, "occurred_datetime", "yesterday"))
    end
  end

  test "hostile text remains ordinary data for escaped HEEx rendering" do
    [filter] =
      normalize(:normalize_active_filters, [
        %{
          id: "hostile-filter",
          label: @hostile,
          value: @hostile,
          remove_href: "/ops/jobs/jobs",
          remove_label: @hostile
        }
      ])

    assert filter.label == @hostile
    assert filter.value == @hostile

    escaped = filter.label |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    assert escaped =~ "&lt;b"
    assert escaped =~ "مرحبا"
    refute escaped =~ "<b"
  end

  test "rejects backend structs, exceptions, tokens, hashes, and raw errors" do
    assert_raise ArgumentError, fn -> normalize(:normalize_operator_results, [%Oban.Job{}]) end
    assert_raise ArgumentError, fn -> normalize(:normalize_blockers, [%RuntimeError{}]) end

    for forbidden <- [
          %{id: "token", preview_token: "secret-preview-token"},
          %{id: "hash", plan_hash: "secret-plan-hash"},
          %{id: "error", raw_error: %RuntimeError{message: "database password"}}
        ] do
      assert_raise ArgumentError, fn -> normalize(:normalize_active_filters, [forbidden]) end
    end
  end

  test "rejects common credential-key aliases and arbitrary audit evidence maps" do
    audit_entry = %{
      sentence: "System policy requested a retry for job job-123.",
      outcome: "Retry requested",
      outcome_state: :success,
      actor: "System policy",
      action: "Retry requested",
      target: "job-123",
      reason: "Incident response",
      source: "Powertools-native",
      correlation: "audit-2026-0001",
      occurred_at: "July 18, 2026 at 21:00 UTC",
      occurred_datetime: "2026-07-18T21:00:00Z",
      changes: nil,
      evidence: nil
    }

    for sensitive_key <- [
          "APIKey",
          "apikey",
          "secretKey",
          "credentials",
          "clientSecret",
          "accessToken",
          "auth_token",
          "passwd",
          "sessionToken"
        ] do
      unsafe_entry = %{audit_entry | evidence: %{sensitive_key => "SYNTHETIC_SECRET"}}

      assert_raise ArgumentError, ~r/prohibited source field/, fn ->
        normalize(:normalize_audit_entry, unsafe_entry)
      end
    end

    assert_raise ArgumentError, ~r/unsupported presentation field/, fn ->
      normalize(:normalize_audit_entry, %{
        audit_entry
        | evidence: %{"unclassifiedMetadata" => "SYNTHETIC_SECRET"}
      })
    end
  end

  test "source keeps normalizers finite without new atom or raw-error conversion paths" do
    source = File.read!(@source_path)

    for normalizer <- @normalizers do
      assert source =~ ~r/^\s*def #{normalizer}\(/m,
             "Phase 78 requires #{normalizer}/1 in ControlPlanePresenter"
    end

    refute source =~ "String.to_atom"

    assert count(source, "String.to_existing_atom") == 2,
           "Phase 78 must not add String.to_existing_atom beyond the two pre-existing helpers"

    for forbidden <- [
          "inspect(error)",
          "Map.from_struct",
          "preview_token",
          "plan_hash",
          "raw_error",
          "Exception.message"
        ] do
      refute source =~ forbidden
    end
  end

  defp normalize(function, input) do
    Code.ensure_loaded!(Presenter)

    assert function_exported?(Presenter, function, 1),
           "GROUP-01 requires #{inspect(Presenter)}.#{function}/1"

    apply(Presenter, function, [input])
  end

  defp present(function, arguments) do
    Code.ensure_loaded!(Presenter)

    assert function_exported?(Presenter, function, length(arguments)),
           "Phase 79 requires #{inspect(Presenter)}.#{function}/#{length(arguments)}"

    apply(Presenter, function, arguments)
  end

  defp count(text, needle), do: length(String.split(text, needle)) - 1

  defp job_fixture do
    %Oban.Job{
      id: 42,
      state: "retryable",
      queue: "critical",
      worker: "Acme.Workers.ReconcileCustomerLedger",
      args: %{"customer_id" => "cust-42"},
      meta: %{"__redacted_fields__" => ["authorization", "password"]},
      errors: [
        %{
          "attempt" => 3,
          "at" => "2026-07-28T02:05:00Z",
          "error" => "** (RuntimeError) provider request failed"
        }
      ],
      attempt: 3,
      max_attempts: 20,
      inserted_at: ~U[2026-07-28 01:55:00Z],
      scheduled_at: ~U[2026-07-28 02:00:00Z],
      attempted_at: ~U[2026-07-28 02:05:00Z]
    }
  end

  defp detail_context do
    %{
      args_display: {:raw_json, ~s({"customer_id":"[redacted]"})},
      meta_display: {:string, "Metadata hidden by host policy."},
      recorded_output_display: %{
        available?: false,
        summary: "No recorded output found for this job.",
        status: nil,
        payload: "No recorded output found for this job.",
        redacted?: false
      }
    }
  end

  defp forensic_evidence_fixture do
    %{
      subject: %{
        type: "lifeline_incident",
        id: "dead_executor:alpha",
        label: "Executor alpha is unavailable",
        entry_surface: "Powertools-native Lifeline",
        resource_type: "job",
        resource_id: "42",
        continuity: %{
          reason: "SYNTHETIC_REASON",
          runbook_context: "SYNTHETIC_RUNBOOK",
          preview_token: "SYNTHETIC_TOKEN"
        }
      },
      diagnosis_summary: %{
        title: "Lifeline diagnosis",
        current: "blocked",
        detail: "The executor is not reporting current health.",
        provenance: :durable,
        raw_error: "SYNTHETIC_ERROR"
      },
      chronology: [
        %{
          id: "forensic-event-repair",
          occurred_at: ~U[2026-07-28 14:00:00Z],
          label: "Lifeline repair evidence was recorded",
          resource_type: "job",
          resource_id: "42",
          source_family: "audit",
          strength: :bridge_only,
          event_type: "lifeline.repair_executed",
          status: :succeeded,
          notes: "SYNTHETIC_REASON",
          runbook_context: %{"stacktrace" => "SYNTHETIC_STACKTRACE"}
        },
        %{
          id: "forensic-event-opened",
          occurred_at: ~U[2026-07-28 13:00:00Z],
          label: "The Lifeline incident was opened",
          resource_type: "incident",
          resource_id: "dead_executor:alpha",
          source_family: "lifeline",
          strength: :durable,
          event_type: "lifeline.incident_opened",
          status: :blocked,
          notes: nil,
          payload: "SYNTHETIC_PAYLOAD"
        }
      ],
      related_evidence: [
        %{
          title: "Incident evidence",
          summary: "The retained incident is the current durable source.",
          provenance: :durable,
          metadata: "SYNTHETIC_METADATA"
        }
      ],
      linked_resources: [
        %{
          label: "Lifeline detail",
          path: "/ops/jobs/lifeline?view=active&incident_fingerprint=dead_executor%3Aalpha",
          venue: "Powertools-native"
        },
        %{
          label: "Lifeline duplicate",
          path: "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Aalpha&view=active",
          venue: "Powertools-native"
        },
        %{
          label: "Workflow detail",
          path: "/ops/jobs/workflows/workflow-1?step=sync",
          venue: "Powertools-native"
        },
        %{
          label: "Audit follow-up",
          path: "/ops/jobs/audit?resource_type=job&resource_id=42",
          venue: "Inspection only"
        },
        %{
          label: "Sensitive URL",
          path: "https://example.invalid/?token=SYNTHETIC_URL",
          venue: "External"
        }
      ],
      legal_next_paths: [
        %{
          label: "Review incident",
          path: "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Aalpha&view=active",
          venue: "Powertools-native",
          authorization: "SYNTHETIC_CREDENTIAL"
        },
        %{
          label: "Unsupported",
          path: "/ops/jobs/unsupported?header=SYNTHETIC_HEADER",
          venue: "Powertools-native"
        }
      ],
      completeness: %{
        state: :partial_evidence,
        details: "Some retained incident evidence may be outside this bounded window."
      },
      coverage: %{
        shown_count: 2,
        total_count: nil,
        has_more?: true,
        bounded?: true,
        retention: "The newest retained incident and Audit evidence is shown.",
        sources: [
          %{
            id: "lifeline",
            label: "Lifeline",
            shown_count: 1,
            total_count: 1,
            has_more?: false,
            limit: 1,
            provenance: :durable,
            completeness: :complete,
            retention: "Current retained incident evidence."
          },
          %{
            id: "audit",
            label: "Audit",
            shown_count: 1,
            total_count: nil,
            has_more?: true,
            limit: 50,
            provenance: :bridge_only,
            completeness: :partial_evidence,
            retention: "Newest retained Audit evidence for this incident scope.",
            error: "SYNTHETIC_ERROR"
          }
        ]
      },
      runbook_entry: %{
        reason: "SYNTHETIC_REASON",
        context: "SYNTHETIC_RUNBOOK",
        credentials: "SYNTHETIC_CREDENTIAL"
      },
      unknown_source: %Oban.Job{args: %{"token" => "SYNTHETIC_TOKEN"}}
    }
  end

  defp canonical_href(href) do
    uri = URI.parse(href)

    query =
      uri.query
      |> to_string()
      |> URI.decode_query()
      |> Enum.sort()
      |> URI.encode_query()

    if query == "", do: uri.path, else: "#{uri.path}?#{query}"
  end

  defp nested_keys(value) when is_map(value) do
    Enum.flat_map(value, fn {key, nested} -> [key | nested_keys(nested)] end)
  end

  defp nested_keys(value) when is_list(value), do: Enum.flat_map(value, &nested_keys/1)
  defp nested_keys(_value), do: []

  defp normalize_key(key) do
    key
    |> to_string()
    |> Macro.underscore()
  end
end
