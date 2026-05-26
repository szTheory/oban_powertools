defmodule ObanPowertools.ForensicsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, Cron, Forensics}
  alias ObanPowertools.Forensics.{Chronology, EvidenceBundle, LimiterHistoryFact}
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Limits.{Resource, State}
  alias ObanPowertools.TestRepo
  alias ObanPowertools.Web.ControlPlanePresenter
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

  test "bundle contract preserves diagnosis-first shape, chronology ordering, and supporting evidence labels" do
    now = DateTime.utc_now()

    bundle =
      EvidenceBundle.build(%{
        subject: %{type: "workflow", id: "wf-1"},
        diagnosis_summary: %{current: "waiting_on_dependencies"},
        chronology: [
          %{
            occurred_at: DateTime.add(now, -60, :second),
            label: "supporting snapshot",
            resource_type: "cron_entry",
            resource_id: "nightly",
            source_family: "cron",
            strength: :supporting,
            event_type: "cron.snapshot",
            notes: "current state only"
          },
          %{
            occurred_at: now,
            label: "workflow anchor",
            resource_type: "workflow",
            resource_id: "wf-1",
            source_family: "workflow",
            strength: :durable,
            event_type: "workflow.created",
            notes: "durable story"
          }
        ],
        related_evidence: [
          %{title: "Limiter fact", summary: "supporting", provenance: :supporting}
        ],
        linked_resources: [],
        legal_next_paths: [],
        completeness: %{state: :partial_evidence, details: "partial evidence"}
      })

    assert Map.has_key?(bundle, :diagnosis_summary)
    assert Map.has_key?(bundle, :related_evidence)
    assert Map.has_key?(bundle, :legal_next_paths)
    assert bundle.completeness.state == :partial_evidence
    assert Enum.map(bundle.chronology, & &1.label) == ["workflow anchor", "supporting snapshot"]
    assert hd(bundle.related_evidence).provenance == :supporting
  end

  test "chronology sorts stronger anchors ahead of weaker evidence at the same time" do
    now = DateTime.utc_now()

    items =
      [
        Chronology.item(%{
          occurred_at: now,
          label: "supporting",
          resource_type: "cron_entry",
          resource_id: "nightly",
          source_family: "cron",
          strength: :supporting,
          event_type: "cron.snapshot"
        }),
        Chronology.item(%{
          occurred_at: now,
          label: "durable",
          resource_type: "workflow",
          resource_id: "1",
          source_family: "workflow",
          strength: :durable,
          event_type: "workflow.created"
        })
      ]
      |> Chronology.sort()

    assert Enum.map(items, & &1.label) == ["durable", "supporting"]
  end

  test "workflow bundle exposes partial evidence when scoped audit history is absent" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensics-workflow") |> Workflow.insert(TestRepo)

    bundle =
      Forensics.bundle(%{"workflow_id" => workflow.id, "step" => "sync_billing"}, repo: TestRepo)

    assert bundle.subject.entry_surface == "Powertools-native workflows"
    assert bundle.diagnosis_summary.current
    assert bundle.completeness.state == :partial_evidence
    assert Enum.any?(bundle.related_evidence, &(&1.provenance == :supporting))
  end

  test "lifeline bundle marks history unavailable when resolved incident lacks retained audit evidence" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensics-resolved") |> Workflow.insert(TestRepo)

    workflow
    |> WorkflowRecord.changeset(%{state: "completed"})
    |> TestRepo.update!()

    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "workflow_stuck",
        status: "resolved",
        workflow_id: workflow.id,
        workflow_step_id: nil,
        incident_fingerprint: "workflow_stuck:#{workflow.id}:done",
        health_state: "resolved",
        summary: "resolved workflow forensic incident",
        affected_counts: %{"jobs" => 0, "workflow_steps" => 1},
        evidence: %{"workflow_name" => workflow.name},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        resolved_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    bundle =
      Forensics.bundle(%{"incident_fingerprint" => incident.incident_fingerprint}, repo: TestRepo)

    assert bundle.subject.entry_surface == "Powertools-native Lifeline"
    assert bundle.completeness.state == :history_unavailable
  end

  test "presenter keeps forensic provenance and completeness labels honest" do
    assert ControlPlanePresenter.forensic_provenance_label(:supporting) == "supporting evidence"
    assert ControlPlanePresenter.forensic_provenance_label(:bridge_only) == "Inspection only"

    assert ControlPlanePresenter.forensic_completeness_label(:partial_evidence) ==
             "partial evidence"

    assert ControlPlanePresenter.forensic_completeness_label(:history_unavailable) ==
             "history unavailable"

    assert ControlPlanePresenter.forensic_completeness_label(:unknown) == "unknown"
  end

  test "workflow and incident audit items remain available for forensic follow-up" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensics-audit") |> Workflow.insert(TestRepo)

    Audit.record(
      "workflow.step_completed",
      %{type: :workflow, id: workflow.id},
      %{"event_type" => "workflow.step_completed", "reason" => "support path"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    bundle = Forensics.bundle(%{"workflow_id" => workflow.id}, repo: TestRepo)

    assert Enum.any?(bundle.chronology, &(&1.event_type == "workflow.step_completed"))
  end

  test "cron forensic bundle explains missed fire from retained coverage without inventing certainty" do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "nightly-history",
        source: "runtime",
        worker: "Example.Worker",
        queue: "default",
        expression: "* * * * *"
      })

    slot_at = DateTime.utc_now() |> DateTime.add(-120, :second) |> truncate_minute()
    assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")

    bundle =
      Forensics.bundle(%{"resource_type" => "cron_entry", "resource_id" => entry.name},
        repo: TestRepo
      )

    assert bundle.subject.entry_surface == "Powertools-native cron"
    assert bundle.completeness.state == :complete
    assert Enum.any?(bundle.chronology, &(&1.event_type == "cron.missed_fire"))
  end

  test "limiter forensic bundle uses retained history facts and explicit completeness labels" do
    resource =
      TestRepo.insert!(%Resource{
        name: "github-api",
        scope_kind: "global",
        algorithm: "token_bucket",
        bucket_span_ms: 60_000,
        bucket_capacity: 5,
        default_weight: 1,
        partition_strategy: "global",
        partition_config: %{},
        cooldown_enabled: true,
        metadata: %{}
      })

    TestRepo.insert!(%State{
      resource_id: resource.id,
      partition_key: "__global__",
      tokens_used: 0,
      bucket_started_at: DateTime.utc_now(),
      reservation_snapshot: %{}
    })

    TestRepo.insert!(%LimiterHistoryFact{
      resource_name: resource.name,
      partition_key: "__global__",
      event_type: "limiter.reconfigured",
      cause_kind: "policy",
      occurred_at: DateTime.utc_now(),
      metadata: %{"config_diff" => %{"bucket_capacity" => %{"before" => 3, "after" => 5}}}
    })

    bundle =
      Forensics.bundle(%{"resource_type" => "limiter", "resource_id" => resource.name},
        repo: TestRepo
      )

    assert bundle.subject.entry_surface == "Powertools-native limiters"
    assert bundle.completeness.state == :complete
    assert Enum.any?(bundle.chronology, &(&1.event_type == "limiter.reconfigured"))
  end

  defp truncate_minute(%DateTime{} = dt), do: %DateTime{dt | second: 0, microsecond: {0, 0}}
end
