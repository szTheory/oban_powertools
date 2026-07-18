defmodule ObanPowertools.Web.OperatorPatternPresenterTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Web.ControlPlanePresenter, as: Presenter

  @source_path "lib/oban_powertools/web/control_plane_presenter.ex"
  @hostile ~s|<b dir="rtl">مرحبا & operator</b>|

  @normalizers ~w[
    normalize_active_filters normalize_operator_results normalize_blockers normalize_audit_entry
    normalize_evidence_completeness
  ]a

  test "exports all five finite Phase 78 presenter seams" do
    assert Code.ensure_loaded?(Presenter), "Phase 78 requires #{Presenter}"

    for normalizer <- @normalizers do
      assert function_exported?(Presenter, normalizer, 1),
             "GROUP-01 requires #{inspect(Presenter)}.#{normalizer}/1"
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
      "changes" => %{"queue" => ["default", "critical"]},
      "evidence" => "Already redacted evidence",
      "preview_token" => nil
    }

    assert normalize(:normalize_audit_entry, input) == %{
             sentence: "System policy requested a retry for job job-123.",
             outcome: "Outcome not recorded",
             actor: "System policy",
             action: "Retry requested",
             target: @hostile,
             reason: "No operator reason recorded",
             source: "Powertools-native",
             correlation: "audit-2026-0001",
             occurred_at: "July 18, 2026 at 21:00 UTC",
             occurred_datetime: "2026-07-18T21:00:00Z",
             changes: %{"queue" => ["default", "critical"]},
             evidence: "Already redacted evidence"
           }

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
    assert function_exported?(Presenter, function, 1),
           "GROUP-01 requires #{inspect(Presenter)}.#{function}/1"

    apply(Presenter, function, [input])
  end

  defp count(text, needle), do: length(String.split(text, needle)) - 1
end
