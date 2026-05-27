defmodule ObanPowertools.ForensicsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, Cron, Forensics}

  alias ObanPowertools.Forensics.{
    AttentionProjection,
    Chronology,
    EvidenceBundle,
    LimiterHistoryFact,
    RunbookEntry
  }

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

  test "attention projection caps bucket exemplars and orders by diagnosis impact before label" do
    candidates = [
      %{
        bucket: "Blocked",
        family: :cron,
        label: "z cron newest",
        status: :missed_fire,
        attention_reason: "Cron missed-fire history changes the next safe path.",
        evidence_completeness: :complete,
        path: "/ops/jobs/cron?entry=z",
        evidence_path: "/ops/jobs/forensics?resource_type=cron_entry&resource_id=z",
        source: "cron-history",
        rank: 40
      },
      %{
        bucket: "Blocked",
        family: :limiter,
        label: "a limiter",
        status: :blocked,
        attention_reason: "Limiter history shows active blocking pressure.",
        evidence_completeness: :complete,
        path: "/ops/jobs/limiters?resource=a",
        evidence_path: "/ops/jobs/forensics?resource_type=limiter&resource_id=a",
        source: "limiter-history",
        rank: 20
      },
      %{
        bucket: "Blocked",
        family: :lifeline,
        label: "b lifeline",
        status: :active,
        attention_reason: "Active Lifeline incident should be inspected before older history.",
        evidence_completeness: :complete,
        path: "/ops/jobs/lifeline?incident_fingerprint=active",
        evidence_path: "/ops/jobs/forensics?incident_fingerprint=active",
        source: "lifeline"
      },
      %{
        bucket: "Blocked",
        family: :workflow,
        label: "c workflow",
        status: :blocked,
        attention_reason: "Workflow step is blocked.",
        evidence_completeness: :complete,
        path: "/ops/jobs/workflows?workflow_id=wf-1",
        evidence_path: "/ops/jobs/forensics?workflow_id=wf-1",
        source: "workflow"
      }
    ]

    exemplars = AttentionProjection.project_bucket("Blocked", candidates)

    assert length(exemplars) == 3
    assert Enum.map(exemplars, & &1.label) == ["b lifeline", "a limiter", "z cron newest"]
  end

  test "attention projection preserves degraded evidence labels without causal certainty copy" do
    candidates = [
      %{
        "bucket" => "Waiting",
        "family" => "cron",
        "label" => "partial evidence cron",
        "status" => "partial_evidence",
        "attention_reason" => "partial evidence: retained scheduler coverage is incomplete.",
        "evidence_completeness" => "partial_evidence",
        "path" => "/ops/jobs/cron?entry=partial",
        "evidence_path" => "/ops/jobs/forensics?resource_type=cron_entry&resource_id=partial",
        "source" => "cron-history"
      },
      %{
        bucket: "Waiting",
        family: :limiter,
        label: "history unavailable limiter",
        status: :history_unavailable,
        attention_reason:
          "history unavailable: current state is visible but retained history is absent.",
        evidence_completeness: :history_unavailable,
        path: "/ops/jobs/limiters?resource=missing",
        evidence_path: "/ops/jobs/forensics?resource_type=limiter&resource_id=missing",
        source: "limiter-history"
      },
      %{
        bucket: "Waiting",
        family: :cron,
        label: "unknown cron",
        status: :unknown,
        attention_reason: "unknown: retained cron windows cannot prove what happened.",
        evidence_completeness: :unknown,
        path: "/ops/jobs/cron?entry=unknown",
        evidence_path: "/ops/jobs/forensics?resource_type=cron_entry&resource_id=unknown",
        source: "cron-history"
      }
    ]

    exemplars = AttentionProjection.project_bucket("Waiting", candidates)

    assert Enum.map(exemplars, & &1.evidence_completeness) |> Enum.sort() == [
             "history unavailable",
             "partial evidence",
             "unknown"
           ]

    refute Enum.any?(exemplars, &String.contains?(&1.attention_reason, "caused"))
  end

  test "attention projection excludes action intent without honest next path" do
    candidates = [
      %{
        bucket: "Needs Review",
        family: :limiter,
        label: "missing path",
        status: :blocked,
        attention_reason: "Limiter history needs review.",
        evidence_completeness: :complete,
        evidence_path: "/ops/jobs/forensics?resource_type=limiter&resource_id=missing",
        source: "limiter-history"
      },
      %{
        bucket: "Needs Review",
        family: :cron,
        label: "neutral guidance",
        status: :unknown,
        attention_reason: "unknown: retained cron windows cannot prove what happened.",
        evidence_completeness: :unknown,
        path: "/ops/jobs/cron?entry=neutral",
        evidence_path: "/ops/jobs/forensics?resource_type=cron_entry&resource_id=neutral",
        source: "cron-history"
      }
    ]

    assert [%{label: "neutral guidance", path: "/ops/jobs/cron?entry=neutral"}] =
             AttentionProjection.project_bucket("Needs Review", candidates)
  end

  test "runbook entry builds advisory guidance from a complete evidence bundle" do
    bundle =
      EvidenceBundle.build(%{
        subject: %{
          type: "workflow",
          id: "wf-123",
          label: "billing workflow",
          entry_surface: "Powertools-native workflows"
        },
        diagnosis_summary: %{
          current: "waiting_on_dependencies",
          detail: "Selected step sync_billing currently reports waiting_on_dependencies.",
          provenance: :durable
        },
        legal_next_paths: [
          %{
            label: "Return to workflow diagnosis",
            path: "/ops/jobs/workflows/wf-123?step=sync_billing",
            venue: "Powertools-native"
          },
          %{
            label: "Inspect scoped audit evidence",
            path: "/ops/jobs/audit?resource_type=workflow&resource_id=wf-123",
            venue: "Inspection only"
          },
          %{
            label: "Coordinate customer retry window",
            path: nil,
            venue: "External runbook"
          }
        ],
        completeness: %{
          state: :complete,
          details: "Complete forensic bundle from workflow and audit evidence."
        }
      })

    entry = RunbookEntry.from_bundle(bundle)

    assert entry.title == "Open runbook entry"
    assert entry.diagnosis_state == "waiting_on_dependencies"
    assert entry.why_now == "Selected step sync_billing currently reports waiting_on_dependencies."
    assert [%{label: "Evidence bundle", state: :met}, %{label: "Legal next path", state: :met}] = entry.prerequisites
    assert [%{label: "Advisory boundary", severity: :info} | _] = entry.cautions
    assert entry.evidence_path == "/ops/jobs/forensics?workflow_id=wf-123"
    assert entry.evidence_completeness.state == :complete
    assert Enum.any?(entry.unsupported_boundaries, &String.contains?(&1, "advisory only"))

    assert [
             %{order: 1, ownership: "Powertools-native", venue: "Powertools-native"},
             %{order: 2, ownership: "Oban Web bridge", venue: "Inspection only"},
             %{order: 3, ownership: "host-owned follow-up", venue: "External runbook"}
           ] = entry.ordered_next_paths
  end

  test "runbook entry labels bridge-only and host-owned paths before path labels" do
    entry =
      RunbookEntry.from_bundle(%{
        subject: %{type: "limiter", id: "github-api", label: "github-api"},
        diagnosis_summary: %{current: "blocked", detail: "Blocked by policy cooldown."},
        legal_next_paths: [
          %{label: "Inspect Oban job details", venue: "Inspection only", path: "/ops/jobs/oban"},
          %{label: "Open pager escalation", venue: "PagerDuty", path: nil}
        ],
        completeness: %{state: "complete", details: "Complete limiter bundle."}
      })

    assert [
             %{label: "Oban Web bridge: Inspect Oban job details", ownership: "Oban Web bridge"},
             %{label: "host-owned follow-up: Open pager escalation", ownership: "host-owned follow-up"}
           ] = entry.ordered_next_paths
  end

  test "runbook entry degrades partial unavailable and unknown evidence without execution claims" do
    for {state, expected_copy} <- [
          {:partial_evidence, "partial evidence"},
          {:history_unavailable, "history unavailable"},
          {:unknown, "unknown"}
        ] do
      entry =
        RunbookEntry.from_bundle(%{
          subject: %{type: "unknown", id: "unknown", label: "Unknown forensic scope"},
          diagnosis_summary: %{current: Atom.to_string(state), detail: "#{expected_copy}: retained facts are incomplete."},
          legal_next_paths: [],
          completeness: %{state: state, details: "#{expected_copy}: retained facts are incomplete."}
        })

      assert entry.evidence_completeness.state == state
      assert Enum.any?(entry.cautions, &String.contains?(&1.detail, expected_copy))
      assert Enum.any?(entry.unsupported_boundaries, &String.contains?(&1, expected_copy))
      refute inspect(entry) =~ "completed remediation"
      refute inspect(entry) =~ "delivery"
      refute inspect(entry) =~ "executed"
      refute inspect(entry) =~ "session"
      refute inspect(entry) =~ "checklist"
    end
  end

  defp truncate_minute(%DateTime{} = dt), do: %DateTime{dt | second: 0, microsecond: {0, 0}}
end
