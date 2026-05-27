defmodule ObanPowertools.Web.EngineOverviewLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.{Audit, Cron, Explain}
  alias ObanPowertools.Forensics.LimiterHistoryFact
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Limits.{Resource, State}

  test "renders diagnosis-first cards with native and bridge ownership labels", %{conn: conn} do
    seed_overview_fixture!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_overview]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs")

    assert html =~ "Diagnosis-first overview"
    assert html =~ "Needs Review"
    assert html =~ "Blocked"
    assert html =~ "Waiting"
    assert html =~ "Runnable"
    assert html =~ "Resolved Recently"
    assert html =~ "Bridge-only Follow-up"
    assert html =~ "Review Needs Review"
    assert html =~ "Oban Web bridge"
    assert html =~ "Inspection only"
    assert html =~ "Continuity evidence"
    assert has_element?(view, "a[href*='/ops/jobs/lifeline?view=active']")
    assert has_element?(view, "a[href*='/ops/jobs/limiters?resource=payments-api']")
    assert has_element?(view, "a[href*='/ops/jobs/cron?entry=nightly-sync']")
    assert has_element?(view, "a[href*='/oban/jobs/321']")
  end

  test "keeps diagnosis context visible for read-only overview viewers", %{conn: conn} do
    seed_overview_fixture!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-viewer", permissions: [:view_overview]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs")

    assert html =~ "Needs Review"
    assert html =~ "Oban Web bridge"
    assert html =~ "Inspection only"
    refute html =~ "Preview Action"
    refute html =~ "name=\"reason\""
  end

  test "renders bounded historical attention inside existing overview buckets", %{conn: conn} do
    %{blocked_resource: blocked_resource, nightly: nightly} = seed_overview_fixture!()

    TestRepo.insert!(%LimiterHistoryFact{
      resource_name: blocked_resource.name,
      partition_key: "__global__",
      event_type: "limiter.blocked",
      cause_kind: "policy",
      occurred_at: DateTime.utc_now(),
      metadata: %{"reason" => "policy cooldown"}
    })

    slot_at = DateTime.utc_now() |> DateTime.add(-120, :second) |> truncate_minute()
    assert {:ok, _coverage} = Cron.record_coverage(TestRepo, nightly, slot_at, status: "healthy")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_overview]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs")

    assert html =~ "Diagnosis-first overview"
    assert html =~ "Needs Review"
    assert html =~ "Blocked"
    assert html =~ "Waiting"
    assert html =~ "Runnable"
    assert html =~ "Bridge-only Follow-up"
    assert html =~ "Resolved Recently"

    assert html =~ "Blocked by policy cooldown for payments-api"
    assert html =~ "Recent cron history shows a missed fire while scheduler coverage was healthy."
    refute html =~ "Historical Attention"
    refute html =~ "raw event"
    refute html =~ "event feed"

    refute html =~ "fourth historical exemplar"
  end

  defp seed_overview_fixture! do
    blocked_resource =
      TestRepo.insert!(%Resource{
        name: "payments-api",
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

    runnable_resource =
      TestRepo.insert!(%Resource{
        name: "billing-export",
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
      resource_id: blocked_resource.id,
      partition_key: "__global__",
      tokens_used: 5,
      bucket_started_at: DateTime.utc_now(),
      cooldown_until: DateTime.add(DateTime.utc_now(), 60, :second),
      cooldown_reason: "operator hold",
      reservation_snapshot: %{}
    })

    TestRepo.insert!(%State{
      resource_id: runnable_resource.id,
      partition_key: "__global__",
      tokens_used: 1,
      bucket_started_at: DateTime.utc_now(),
      cooldown_until: nil,
      cooldown_reason: nil,
      reservation_snapshot: %{}
    })

    TestRepo.insert!(%Explain{
      job_id: 321,
      worker: "ExampleWorker",
      status: "blocked",
      scope_kind: "global",
      scope_id: blocked_resource.name,
      blocker_codes: ["limit_reached"],
      details: %{
        "live_now" => [%{"code" => "limit_reached", "summary" => "resource bucket is saturated"}]
      },
      captured_at: DateTime.utc_now()
    })

    {:ok, nightly} =
      Cron.sync_entry(TestRepo, %{
        name: "nightly-sync",
        source: "code",
        worker: "DemoWorker",
        queue: "default",
        expression: "* * * * *"
      })

    {:ok, _paused} = Cron.pause_entry(TestRepo, nightly, "ops-seed", reason: "seed")

    TestRepo.insert!(
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "active",
        executor_id: "executor-1",
        incident_fingerprint: "dead_executor:executor-1",
        health_state: "missing",
        summary: "missing executor executor-1",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [321], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        metadata: %{}
      })
    )

    TestRepo.insert!(
      %Incident{}
      |> Incident.changeset(%{
        incident_class: "dead_executor",
        status: "resolved",
        executor_id: "executor-2",
        incident_fingerprint: "dead_executor:executor-2",
        health_state: "resolved",
        summary: "resolved executor executor-2",
        affected_counts: %{"jobs" => 1, "workflow_steps" => 0},
        evidence: %{"job_ids" => [654], "workflow_step_ids" => []},
        first_detected_at: DateTime.utc_now(),
        last_detected_at: DateTime.utc_now(),
        resolved_at: DateTime.utc_now(),
        metadata: %{}
      })
    )

    Audit.record(
      "lifeline.repair_executed",
      %{type: :job, id: "654"},
      %{"event_type" => "lifeline.repair_executed", "reason" => "repair closed"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    %{blocked_resource: blocked_resource, runnable_resource: runnable_resource, nightly: nightly}
  end

  defp truncate_minute(%DateTime{} = dt), do: %DateTime{dt | second: 0, microsecond: {0, 0}}
end
