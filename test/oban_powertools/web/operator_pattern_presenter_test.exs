defmodule ObanPowertools.Web.OperatorPatternPresenterTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Audit
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

  @phase80_job_presenters ~w[
    present_job_row present_job_quick_review
  ]a

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

  test "exports the two finite Phase 80 Jobs browse presentation seams" do
    assert Code.ensure_loaded?(Presenter), "Phase 80 requires #{Presenter}"

    for presenter <- @phase80_job_presenters do
      assert function_exported?(Presenter, presenter, 2),
             "Phase 80 requires #{inspect(Presenter)}.#{presenter}/2"
    end
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
