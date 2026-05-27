defmodule ObanPowertools.Web.LimitersLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Explain
  alias ObanPowertools.Forensics.LimiterHistoryFact
  alias ObanPowertools.Limits.{Resource, State}

  test "renders Live Now and Snapshot at Block Start with job deep link", %{conn: conn} do
    resource =
      TestRepo.insert!(%Resource{
        name: "user-api",
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
      tokens_used: 2,
      bucket_started_at: DateTime.utc_now(),
      cooldown_until: DateTime.add(DateTime.utc_now(), 60, :second),
      cooldown_reason: "operator hold",
      reservation_snapshot: %{}
    })

    snapshot =
      TestRepo.insert!(%Explain{
        job_id: 123,
        worker: "ExampleWorker",
        status: "blocked",
        scope_kind: "global",
        scope_id: resource.name,
        blocker_codes: ["cooldown"],
        details: %{
          "partition_key" => "__global__",
          "weight" => 1,
          "live_now" => [
            %{"code" => "limit_reached", "summary" => "resource bucket is saturated"}
          ]
        },
        captured_at: DateTime.utc_now()
      })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_limiters]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/limiters")
    assert html =~ "Inspect Job Blockers"

    html =
      view
      |> element("button[phx-value-resource='user-api']")
      |> render_click()

    assert html =~ "Live Now"
    assert html =~ "Snapshot at Block Start"
    assert html =~ "Open generic job inspection in Oban Web bridge"
    assert html =~ "Powertools-native"
    assert html =~ Integer.to_string(snapshot.job_id)
  end

  test "restores selected limiter context across remount with resource param", %{conn: conn} do
    resource =
      TestRepo.insert!(%Resource{
        name: "mailer-api",
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
      cooldown_until: DateTime.add(DateTime.utc_now(), 60, :second),
      cooldown_reason: "operator hold",
      reservation_snapshot: %{}
    })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_limiters]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/limiters?resource=mailer-api")
    assert html =~ "mailer-api"

    assert html =~ "Select a limiter row to compare Live Now against Snapshot at Block Start." or
             html =~ "Live Now"

    {:ok, _remounted_view, remounted_html} = live(conn, "/ops/jobs/limiters?resource=mailer-api")
    assert remounted_html =~ "mailer-api"
    refute remounted_html =~ "preview_token"
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/limiters")
  end

  test "renders history summary and forensic handoff for limiter detail", %{conn: conn} do
    resource =
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

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-3", permissions: [:view_limiters, :view_forensics]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs/limiters?resource=#{resource.name}")

    assert html =~ "History Summary"
    assert html =~ "Open runbook entry"
    assert html =~ "Runnable now, with recent history showing a limiter reconfiguration"
    assert html =~ "Powertools-native"
    assert html =~ "Oban Web bridge"
    assert html =~ "host-owned follow-up"
    assert html =~ "partial evidence"
    assert html =~ "history unavailable"
    assert html =~ "Open forensic timeline"
    assert html =~ "Limiter reconfigured"
    assert html =~ "/ops/jobs/forensics?resource_type=limiter&amp;resource_id=payments-api"
  end
end
