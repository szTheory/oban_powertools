defmodule ObanPowertools.ForensicsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, Cron, Forensics}

  alias ObanPowertools.Forensics.{
    AttentionProjection,
    Chronology,
    EvidenceBundle,
    LimiterHistoryFact,
    Provenance,
    RunbookEntry,
    Scope
  }

  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Limits.{Resource, State}
  alias ObanPowertools.TestRepo
  alias ObanPowertools.Web.ControlPlanePresenter
  alias ObanPowertools.Workflow
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord
  alias ObanPowertools.WorkflowFixtures

  @allowed_selector_keys MapSet.new([
                           "resource_type",
                           "resource_id",
                           "workflow_id",
                           "step",
                           "incident_fingerprint",
                           "view"
                         ])

  describe "typed forensic scope grammar" do
    test "returns the real empty chooser for absent and blank selectors" do
      assert Scope.parse(%{}) == {:empty, [], "Choose evidence to inspect."}

      assert Scope.parse(%{
               "resource_type" => "",
               "resource_id" => "  ",
               "workflow_id" => nil,
               "step" => "",
               "incident_fingerprint" => " ",
               "view" => nil
             }) == {:empty, [], "Choose evidence to inspect."}
    end

    test "accepts exactly the four typed families and canonicalizes them in six-key order" do
      cases = [
        {
          %{"workflow_id" => "workflow-1"},
          :workflow,
          [{"workflow_id", "workflow-1"}]
        },
        {
          %{
            "resource_type" => "workflow_step",
            "resource_id" => "step-row-7",
            "workflow_id" => "workflow-1",
            "step" => "sync_billing"
          },
          :workflow,
          [
            {"resource_type", "workflow_step"},
            {"resource_id", "step-row-7"},
            {"workflow_id", "workflow-1"},
            {"step", "sync_billing"}
          ]
        },
        {
          %{
            "resource_type" => "job",
            "resource_id" => "42",
            "incident_fingerprint" => "dead_executor:alpha",
            "view" => "active"
          },
          :incident,
          [
            {"resource_type", "job"},
            {"resource_id", "42"},
            {"incident_fingerprint", "dead_executor:alpha"},
            {"view", "active"}
          ]
        },
        {
          %{"incident_fingerprint" => "workflow_stuck:1", "view" => "resolved"},
          :incident,
          [{"incident_fingerprint", "workflow_stuck:1"}, {"view", "resolved"}]
        },
        {
          %{"resource_type" => "cron_entry", "resource_id" => "nightly"},
          :cron_entry,
          [{"resource_type", "cron_entry"}, {"resource_id", "nightly"}]
        },
        {
          %{"resource_type" => "limiter", "resource_id" => "payments"},
          :limiter,
          [{"resource_type", "limiter"}, {"resource_id", "payments"}]
        }
      ]

      for {params, kind, canonical} <- cases do
        assert {:ok, %{kind: ^kind} = scope, ^canonical} = Scope.parse(params)
        assert scope.__struct__ == Scope
        assert Scope.canonical_params(scope) == canonical
      end
    end

    test "accepts only consistent workflow and incident context pairs" do
      valid = [
        %{
          "resource_type" => "workflow",
          "resource_id" => "workflow-1",
          "workflow_id" => "workflow-1"
        },
        %{
          "resource_type" => "workflow_step",
          "resource_id" => "step-row-7",
          "workflow_id" => "workflow-1",
          "step" => "sync"
        },
        %{
          "resource_type" => "workflow",
          "resource_id" => "workflow-1",
          "workflow_id" => "workflow-1",
          "incident_fingerprint" => "workflow_stuck:workflow-1"
        },
        %{
          "resource_type" => "workflow_step",
          "resource_id" => "step-row-7",
          "workflow_id" => "workflow-1",
          "step" => "sync",
          "incident_fingerprint" => "workflow_stuck:workflow-1:sync"
        }
      ]

      assert Enum.map(valid, &Scope.parse/1)
             |> Enum.all?(fn
               {:ok, %{__struct__: Scope}, _params} -> true
               _other -> false
             end)
    end

    test "rejects every mixed orphan incomplete unknown arbitrary-job and seventh-key scope before a read" do
      invalid = [
        %{"step" => "sync"},
        %{"view" => "active"},
        %{"workflow_id" => "workflow-1", "view" => "active"},
        %{"incident_fingerprint" => "incident-1", "view" => "archived"},
        %{"resource_type" => "workflow"},
        %{"resource_id" => "workflow-1"},
        %{"resource_type" => "unknown", "resource_id" => "1"},
        %{"resource_type" => "job", "resource_id" => "42"},
        %{
          "resource_type" => "workflow",
          "resource_id" => "different-workflow",
          "workflow_id" => "workflow-1"
        },
        %{
          "resource_type" => "workflow_step",
          "resource_id" => "step-row-7",
          "workflow_id" => "workflow-1"
        },
        %{
          "resource_type" => "cron_entry",
          "resource_id" => "nightly",
          "workflow_id" => "workflow-1"
        },
        %{
          "resource_type" => "limiter",
          "resource_id" => "payments",
          "incident_fingerprint" => "incident-1"
        },
        %{"workflow_id" => "workflow-1", "seventh" => "conflict"}
      ]

      for params <- invalid do
        result = Scope.parse(params)
        if match?({:ok, %{__struct__: Scope}, _canonical}, result), do: send(self(), :repo_read)

        assert result == {:invalid, [], "Choose one evidence type"}
        refute_received :repo_read
      end
    end

    test "round-trips Unicode and delimiter-heavy identities without changing values" do
      workflow_id = "workflow:α/مرحبا?next=#one % two&three=four"
      step = "sync/課金?mode=full#attempt 1&retry=true"

      assert {:ok, scope, canonical} =
               Scope.parse(%{"workflow_id" => workflow_id, "step" => step})

      path = ObanPowertools.Web.Selectors.forensic_path(canonical)
      decoded = path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

      assert decoded == %{"workflow_id" => workflow_id, "step" => step}
      assert Scope.canonical_params(scope) == canonical
    end
  end

  describe "typed evidence assembly" do
    test "empty invalid and forged typed scopes return safe unavailable results with zero reads" do
      cases = [
        {%{}, "Choose evidence to inspect."},
        {%{"workflow_id" => "workflow-1", "incident_fingerprint" => "incident-1"},
         "Choose one evidence type"},
        {%{"resource_type" => "job", "resource_id" => "42"}, "Choose one evidence type"},
        {%Scope{kind: :workflow, workflow_id: nil}, "Choose one evidence type"}
      ]

      for {params, reason} <- cases do
        {result, queries} =
          capture_select_queries(fn ->
            Forensics.bundle(params, repo: TestRepo)
          end)

        assert result == {:unavailable, reason}
        assert queries == []
      end
    end

    test "well-formed missing scopes are uniformly unavailable" do
      for params <- [
            %{"workflow_id" => Ecto.UUID.generate()},
            %{"incident_fingerprint" => "missing:incident"},
            %{"resource_type" => "cron_entry", "resource_id" => "missing-cron"},
            %{"resource_type" => "limiter", "resource_id" => "missing-limiter"}
          ] do
        assert Forensics.bundle(params, repo: TestRepo) ==
                 {:unavailable, "Evidence unavailable"}
      end
    end

    test "workflow assembly uses the bounded Audit window and exposes exact source coverage" do
      {:ok, workflow} =
        WorkflowFixtures.workflow_fixture(name: "bounded-workflow") |> Workflow.insert(TestRepo)

      for index <- 1..55 do
        {:ok, event} =
          Audit.record(
            "workflow.step_completed",
            %{type: :workflow, id: workflow.id},
            %{"event_type" => "workflow.step_completed", "reason" => "SYNTHETIC_REASON_#{index}"},
            repo: TestRepo,
            actor_id: "operator"
          )

        event
        |> Ecto.Changeset.change(
          inserted_at: ~N[2026-07-28 12:00:00] |> NaiveDateTime.add(index, :second)
        )
        |> TestRepo.update!()
      end

      {result, queries} =
        capture_select_queries(fn ->
          Forensics.bundle(%{"workflow_id" => workflow.id}, repo: TestRepo)
        end)

      assert {:ok, bundle} = result
      audit_source = Enum.find(bundle.coverage.sources, &(&1.id == "audit"))
      workflow_source = Enum.find(bundle.coverage.sources, &(&1.id == "workflow"))

      assert audit_source == %{
               id: "audit",
               label: "Audit",
               shown_count: 50,
               total_count: 55,
               has_more?: true,
               limit: 50,
               provenance: :bridge_only,
               completeness: :partial_evidence,
               retention: "Newest retained Audit evidence for this workflow scope."
             }

      assert workflow_source.shown_count >= 1
      assert workflow_source.total_count == workflow_source.shown_count
      assert workflow_source.has_more? == false
      assert Enum.count(bundle.chronology, &(&1.source_family == "audit")) == 50
      refute inspect(bundle, limit: :infinity, printable_limit: :infinity) =~ "SYNTHETIC_REASON"

      assert Enum.count(queries, &(&1.source == "oban_powertools_audit_events")) == 2
      assert Enum.all?(queries, &(&1.source != "oban_powertools_lifeline_incidents"))
      assert Enum.all?(queries, &(&1.source != "oban_powertools_cron_entries"))
      assert Enum.all?(queries, &(&1.source != "oban_powertools_limit_resources"))
    end
  end

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

  test "chronology produces stable closed identity and newest-first order" do
    now = DateTime.utc_now()

    items =
      [
        Chronology.item(%{
          occurred_at: DateTime.add(now, -1, :second),
          label: "Supporting evidence recorded",
          resource_type: "cron_entry",
          resource_id: "nightly",
          source_family: "cron",
          strength: :supporting,
          event_type: "cron.snapshot",
          reason: "SYNTHETIC_REASON",
          payload: "SYNTHETIC_PAYLOAD"
        }),
        Chronology.item(%{
          occurred_at: now,
          label: "Workflow evidence recorded",
          resource_type: "workflow",
          resource_id: "1",
          source_family: "workflow",
          strength: :durable,
          event_type: "workflow.created",
          notes: String.duplicate("n", 1_100)
        })
      ]
      |> Chronology.sort()

    assert Enum.map(items, & &1.label) ==
             ["Workflow evidence recorded", "Supporting evidence recorded"]

    for item <- items do
      assert Map.keys(item) |> Enum.sort() ==
               Enum.sort([
                 :id,
                 :occurred_at,
                 :label,
                 :resource_type,
                 :resource_id,
                 :source_family,
                 :strength,
                 :event_type,
                 :status,
                 :notes
               ])

      assert String.starts_with?(item.id, "forensic-event-")
    end

    assert String.length(hd(items).notes) == 1_000
    assert String.ends_with?(hd(items).notes, "…")
    refute inspect(items) =~ "SYNTHETIC_"

    assert Chronology.sort(Enum.reverse(items)) == items
  end

  test "workflow bundle exposes partial evidence when scoped audit history is absent" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensics-workflow") |> Workflow.insert(TestRepo)

    bundle =
      ok_bundle(%{"workflow_id" => workflow.id, "step" => "sync_billing"})

    assert bundle.subject.entry_surface == "Powertools-native workflows"
    assert bundle.diagnosis_summary.current
    assert bundle.completeness.state == :partial_evidence
    assert Enum.any?(bundle.related_evidence, &(&1.provenance == :supporting))
  end

  test "forensic evidence and continuity links keep the stable selector allowlist" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "selector-allowlist-workflow")
      |> Workflow.insert(TestRepo)

    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "active",
        executor_id: "selector-allowlist",
        incident_fingerprint: "dead_executor:selector-allowlist",
        health_state: "missing",
        summary: "selector allowlist incident",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [123], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    workflow_bundle =
      ok_bundle(%{"workflow_id" => workflow.id, "step" => "sync_billing"})

    lifeline_bundle =
      ok_bundle(%{
        "incident_fingerprint" => incident.incident_fingerprint,
        "view" => "active"
      })

    assert_selector_keys_allowed(workflow_bundle.runbook_entry.evidence_path)
    assert_selector_keys_allowed(lifeline_bundle.runbook_entry.evidence_path)

    assert_selector_keys_allowed(
      Enum.find(lifeline_bundle.linked_resources, &(&1.label == "Lifeline detail")).path
    )

    refute workflow_bundle.runbook_entry.evidence_path =~ "preview_token="
    refute lifeline_bundle.runbook_entry.evidence_path =~ "reason="
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
      ok_bundle(%{"incident_fingerprint" => incident.incident_fingerprint})

    assert bundle.subject.entry_surface == "Powertools-native Lifeline"
    assert bundle.completeness.state == :history_unavailable
  end

  test "lifeline forensic chronology keeps only finite repair status from runbook continuity" do
    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "workflow_stuck",
        status: "active",
        workflow_id: nil,
        workflow_step_id: nil,
        incident_fingerprint: "workflow_stuck:continuity:#{System.unique_integer([:positive])}",
        health_state: "missing",
        summary: "continuity test incident",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [123], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    runbook_context = %{
      "entry" => %{"title" => "Open runbook entry"},
      "diagnosis_state" => "blocked",
      "evidence_completeness" => "complete",
      "selected_path" => %{
        "ownership" => "Powertools-native",
        "venue" => "Powertools-native Lifeline",
        "intent" => "remediate"
      },
      "attempt" => %{
        "state" => "succeeded",
        "action" => "job_rescue",
        "target_type" => "job",
        "target_id" => "123"
      },
      "selectors" => %{
        "incident_fingerprint" => incident.incident_fingerprint,
        "resource_type" => "job",
        "resource_id" => "123"
      },
      "plan_hash" => "plan-hash",
      "preview_token" => "preview-token"
    }

    {:ok, _event} =
      Audit.record(
        "lifeline.repair_executed",
        %{type: :job, id: 123},
        %{
          "event_type" => "lifeline.repair_executed",
          "incident_fingerprint" => incident.incident_fingerprint,
          "reason" => "Operator retried the stuck job",
          "runbook_context" => runbook_context
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    bundle =
      ok_bundle(%{"incident_fingerprint" => incident.incident_fingerprint})

    audit_item = Enum.find(bundle.chronology, &(&1.event_type == "lifeline.repair_executed"))

    assert audit_item.status == :succeeded
    assert audit_item.notes == nil

    assert Map.keys(audit_item) |> Enum.sort() ==
             Enum.sort([
               :id,
               :occurred_at,
               :label,
               :resource_type,
               :resource_id,
               :source_family,
               :strength,
               :event_type,
               :status,
               :notes
             ])

    serialized = inspect(bundle, printable_limit: :infinity, limit: :infinity)
    refute serialized =~ "Operator retried the stuck job"
    refute serialized =~ "preview-token"
    refute serialized =~ "plan-hash"
    refute serialized =~ "job_rescue"
  end

  test "latest genuine repair evidence remains historical and excludes the operator reason" do
    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "workflow_stuck",
        status: "active",
        workflow_id: nil,
        workflow_step_id: nil,
        incident_fingerprint:
          "workflow_stuck:continuity-latest:#{System.unique_integer([:positive])}",
        health_state: "missing",
        summary: "continuity latest test incident",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [123], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    {:ok, _older_event} =
      Audit.record(
        "lifeline.repair_executed",
        %{type: :job, id: 123},
        %{
          "event_type" => "lifeline.repair_executed",
          "incident_fingerprint" => incident.incident_fingerprint,
          "reason" => "Preview captured",
          "runbook_context" => %{
            "selected_path" => %{"ownership" => "powertools-native", "venue" => "lifeline"},
            "attempt" => %{
              "state" => "previewed",
              "action" => "job_rescue",
              "target_type" => "job",
              "target_id" => "123"
            }
          }
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    {:ok, _latest_event} =
      Audit.record(
        "lifeline.repair_executed",
        %{type: :job, id: 123},
        %{
          "event_type" => "lifeline.repair_executed",
          "incident_fingerprint" => incident.incident_fingerprint,
          "reason" => "Operator completed rescue",
          "runbook_context" => %{
            "selected_path" => %{
              "ownership" => "Powertools-native",
              "venue" => "Powertools-native Lifeline"
            },
            "attempt" => %{
              "state" => "succeeded",
              "action" => "job_rescue",
              "target_type" => "job",
              "target_id" => "123"
            }
          }
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    bundle =
      ok_bundle(%{"incident_fingerprint" => incident.incident_fingerprint})

    repairs =
      Enum.filter(bundle.chronology, &(&1.event_type == "lifeline.repair_executed"))

    assert Enum.map(repairs, & &1.status) == [:succeeded, :previewed]

    refute inspect(bundle, printable_limit: :infinity, limit: :infinity) =~
             "Operator completed rescue"

    refute Enum.any?(bundle.runbook_entry.cautions, &(&1.label == "Remediation continuity"))
  end

  test "missing runbook continuity metadata degrades safely without remediation summary caution" do
    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "workflow_stuck",
        status: "active",
        workflow_id: nil,
        workflow_step_id: nil,
        incident_fingerprint:
          "workflow_stuck:continuity-none:#{System.unique_integer([:positive])}",
        health_state: "missing",
        summary: "continuity fallback incident",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [123], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    {:ok, _event} =
      Audit.record(
        "lifeline.repair_executed",
        %{type: :job, id: 123},
        %{
          "event_type" => "lifeline.repair_executed",
          "incident_fingerprint" => incident.incident_fingerprint,
          "reason" => "Legacy event without continuity metadata"
        },
        repo: TestRepo,
        actor_id: "ops-1"
      )

    bundle =
      ok_bundle(%{"incident_fingerprint" => incident.incident_fingerprint})

    audit_item = Enum.find(bundle.chronology, &(&1.event_type == "lifeline.repair_executed"))
    assert audit_item
    assert audit_item.status == :unknown
    assert audit_item.notes == nil

    refute Enum.any?(bundle.runbook_entry.cautions, &(&1.label == "Remediation continuity"))
  end

  test "runbook continuity preserves explicit attempt-state vocabulary" do
    for state <- ~w(previewed attempted succeeded drifted expired consumed) do
      entry =
        RunbookEntry.from_bundle(%{
          subject: %{
            type: "lifeline_incident",
            id: "continuity-state-#{state}",
            continuity: %{
              attempt_state: state,
              action: "job_rescue",
              reason: "State vocabulary check",
              selected_path: %{
                ownership: "Powertools-native",
                venue: "Powertools-native Lifeline"
              }
            }
          },
          diagnosis_summary: %{current: "blocked", detail: "State test."},
          legal_next_paths: [],
          completeness: %{state: :complete, details: "Complete forensic bundle."}
        })

      continuity_caution = Enum.find(entry.cautions, &(&1.label == "Remediation continuity"))
      assert continuity_caution
      assert continuity_caution.detail =~ state
    end
  end

  test "partial evidence and history unavailable continuity stay explicit without completion claims" do
    entry =
      RunbookEntry.from_bundle(%{
        subject: %{type: "unknown", id: "unknown", label: "Unknown forensic scope"},
        diagnosis_summary: %{
          current: "unknown",
          detail:
            "partial evidence and history unavailable states keep bridge-only and host-owned follow-up guidance explicit."
        },
        legal_next_paths: [
          %{
            label: "bridge-only investigation lane",
            venue: "Inspection only",
            path: "/ops/jobs/oban"
          },
          %{label: "host-owned follow-up escalation", venue: "PagerDuty", path: nil}
        ],
        completeness: %{
          state: :history_unavailable,
          details:
            "history unavailable: partial evidence and unknown chronology remain explicit follow-up boundaries."
        }
      })

    labels = Enum.map(entry.ordered_next_paths, &String.downcase(&1.label))
    details = entry.evidence_completeness.details

    assert Enum.any?(labels, &String.contains?(&1, "bridge-only"))
    assert Enum.any?(labels, &String.contains?(&1, "host-owned follow-up"))
    assert details =~ "history unavailable"
    assert details =~ "partial evidence"
    assert details =~ "unknown"
    refute inspect(entry) =~ "completed remediation"
    refute inspect(entry) =~ "succeeded"
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

  test "forensic label and runbook completeness helpers do not atomize novel strings" do
    novel_state = "novel_completeness_#{System.unique_integer([:positive])}"
    novel_provenance = "novel_provenance_#{System.unique_integer([:positive])}"
    novel_key = "novel_key_#{System.unique_integer([:positive])}"

    assert_no_existing_atom(novel_state)
    assert_no_existing_atom(novel_provenance)
    assert_no_existing_atom(novel_key)

    assert Provenance.normalize_completeness(novel_state) == :unknown
    assert Provenance.normalize_provenance(novel_provenance) == :missing
    assert ControlPlanePresenter.forensic_completeness_label(novel_state) == "unknown"
    assert ControlPlanePresenter.forensic_provenance_label(novel_provenance) == "unknown"

    entry =
      RunbookEntry.from_bundle(%{
        subject: %{type: "unknown", id: "unknown", label: "Unknown forensic scope"},
        diagnosis_summary: %{current: "unknown", detail: "Unknown state."},
        legal_next_paths: [],
        completeness: %{
          "state" => novel_state,
          "details" => "Novel completeness degraded safely.",
          novel_key => "ignored"
        }
      })

    assert entry.evidence_completeness.state == :unknown
    assert entry.evidence_completeness.details == "Novel completeness degraded safely."

    bundle =
      EvidenceBundle.build(%{
        completeness: %{
          "state" => novel_state,
          "details" => "Novel bundle completeness degraded safely.",
          novel_key => "ignored"
        }
      })

    assert bundle.completeness.state == :unknown
    assert bundle.completeness.details == "Novel bundle completeness degraded safely."
    assert_no_existing_atom(novel_state)
    assert_no_existing_atom(novel_provenance)
    assert_no_existing_atom(novel_key)
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

    bundle = ok_bundle(%{"workflow_id" => workflow.id})

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
      ok_bundle(%{"resource_type" => "cron_entry", "resource_id" => entry.name})

    assert bundle.subject.entry_surface == "Powertools-native cron"
    assert bundle.completeness.state == :complete
    assert Enum.any?(bundle.chronology, &(&1.event_type == "cron.missed_fire"))

    cron_source = Enum.find(bundle.coverage.sources, &(&1.id == "cron"))
    assert cron_source.limit == 8
    assert cron_source.shown_count <= 8
    assert cron_source.provenance == :durable
    assert bundle.coverage.bounded?
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
      ok_bundle(%{"resource_type" => "limiter", "resource_id" => resource.name})

    assert bundle.subject.entry_surface == "Powertools-native limiters"
    assert bundle.completeness.state == :complete
    assert Enum.any?(bundle.chronology, &(&1.event_type == "limiter.reconfigured"))

    limiter_source = Enum.find(bundle.coverage.sources, &(&1.id == "limiter"))
    assert limiter_source.limit == 8
    assert limiter_source.shown_count <= 8
    assert limiter_source.provenance == :durable
    assert bundle.coverage.bounded?
  end

  test "supported forensic bundles expose canonical runbook entries with stable selectors" do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "runbook-workflow") |> Workflow.insert(TestRepo)

    incident =
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "active",
        executor_id: "runbook-executor",
        incident_fingerprint: "dead_executor:runbook-executor",
        health_state: "missing",
        summary: "missing executor runbook-executor",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [123], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
      |> TestRepo.insert!()

    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "runbook-cron",
        source: "runtime",
        worker: "Example.Worker",
        queue: "default",
        expression: "* * * * *"
      })

    slot_at = DateTime.utc_now() |> DateTime.add(-120, :second) |> truncate_minute()
    assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")

    resource =
      TestRepo.insert!(%Resource{
        name: "runbook-limiter",
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
      event_type: "limiter.blocked",
      cause_kind: "policy",
      occurred_at: DateTime.utc_now(),
      metadata: %{}
    })

    workflow_bundle =
      ok_bundle(%{"workflow_id" => workflow.id, "step" => "sync_billing"})

    lifeline_bundle =
      ok_bundle(%{
        "incident_fingerprint" => incident.incident_fingerprint,
        "view" => "active"
      })

    cron_bundle =
      ok_bundle(%{"resource_type" => "cron_entry", "resource_id" => entry.name})

    limiter_bundle =
      ok_bundle(%{"resource_type" => "limiter", "resource_id" => resource.name})

    assert {:unavailable, "Choose evidence to inspect."} =
             Forensics.bundle(%{}, repo: TestRepo)

    for bundle <- [workflow_bundle, lifeline_bundle, cron_bundle, limiter_bundle] do
      assert Map.has_key?(bundle, :runbook_entry)
      assert bundle.runbook_entry.title == "Open runbook entry"
    end

    assert workflow_bundle.runbook_entry.evidence_path =~ "workflow_id=#{workflow.id}"
    assert workflow_bundle.runbook_entry.evidence_path =~ "step=sync_billing"

    assert lifeline_bundle.runbook_entry.evidence_path =~
             "incident_fingerprint=dead_executor%3Arunbook-executor"

    assert lifeline_bundle.runbook_entry.evidence_path =~ "view=active"
    assert cron_bundle.runbook_entry.evidence_path =~ "resource_type=cron_entry"
    assert cron_bundle.runbook_entry.evidence_path =~ "resource_id=runbook-cron"
    assert limiter_bundle.runbook_entry.evidence_path =~ "resource_type=limiter"
    assert limiter_bundle.runbook_entry.evidence_path =~ "resource_id=runbook-limiter"
  end

  test "cron and limiter runbook paths label ownership before action intent" do
    {:ok, entry} =
      Cron.sync_entry(TestRepo, %{
        name: "runbook-unknown-window",
        source: "runtime",
        worker: "Example.Worker",
        queue: "default",
        expression: "* * * * *"
      })

    cron_bundle =
      ok_bundle(%{"resource_type" => "cron_entry", "resource_id" => entry.name})

    resource =
      TestRepo.insert!(%Resource{
        name: "runbook-policy",
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
      tokens_used: 5,
      bucket_started_at: DateTime.utc_now(),
      reservation_snapshot: %{}
    })

    limiter_bundle =
      ok_bundle(%{"resource_type" => "limiter", "resource_id" => resource.name})

    for bundle <- [cron_bundle, limiter_bundle] do
      labels = Enum.map(bundle.runbook_entry.ordered_next_paths, & &1.label)
      ownerships = Enum.map(bundle.runbook_entry.ordered_next_paths, & &1.ownership)

      assert "Powertools-native" in ownerships
      assert "Oban Web bridge" in ownerships
      assert "host-owned follow-up" in ownerships
      assert Enum.any?(labels, &String.starts_with?(&1, "Oban Web bridge:"))
      assert Enum.any?(labels, &String.starts_with?(&1, "host-owned follow-up:"))
    end
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

    assert entry.why_now ==
             "Selected step sync_billing currently reports waiting_on_dependencies."

    assert [%{label: "Evidence bundle", state: :met}, %{label: "Legal next path", state: :met}] =
             entry.prerequisites

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
             %{
               label: "host-owned follow-up: Open pager escalation",
               ownership: "host-owned follow-up"
             }
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
          diagnosis_summary: %{
            current: Atom.to_string(state),
            detail: "#{expected_copy}: retained facts are incomplete."
          },
          legal_next_paths: [],
          completeness: %{
            state: state,
            details: "#{expected_copy}: retained facts are incomplete."
          }
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

  defp ok_bundle(params) do
    assert {:ok, bundle} = Forensics.bundle(params, repo: TestRepo)
    bundle
  end

  defp capture_select_queries(fun) do
    handler_id = {__MODULE__, make_ref()}
    event = TestRepo.config() |> Keyword.fetch!(:telemetry_prefix) |> Kernel.++([:query])
    test_pid = self()
    query_ref = make_ref()

    :telemetry.attach(
      handler_id,
      event,
      fn _event, _measurements, metadata, {pid, ref} ->
        if String.starts_with?(metadata[:query] || "", "SELECT") do
          send(pid, {ref, Map.take(metadata, [:source, :query])})
        end
      end,
      {test_pid, query_ref}
    )

    try do
      result = fun.()
      {result, collect_select_queries(query_ref, [])}
    after
      :telemetry.detach(handler_id)
    end
  end

  defp collect_select_queries(query_ref, queries) do
    receive do
      {^query_ref, query} -> collect_select_queries(query_ref, [query | queries])
    after
      0 -> Enum.reverse(queries)
    end
  end

  defp assert_no_existing_atom(value) do
    assert_raise ArgumentError, fn -> String.to_existing_atom(value) end
  end

  defp assert_selector_keys_allowed(path) do
    parsed = URI.parse(path)
    keys = parsed.query |> URI.decode_query() |> Map.keys() |> MapSet.new()

    assert MapSet.subset?(keys, @allowed_selector_keys)
  end
end
