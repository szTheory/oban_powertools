defmodule ObanPowertools.Web.EngineOverviewLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.{Audit, Cron, Explain}
  alias ObanPowertools.Forensics.LimiterHistoryFact
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Limits.{Resource, State}
  alias ObanPowertools.Web.{ControlPlanePresenter, EngineOverviewLive, OverviewReadModel}

  test "renders diagnosis-first cards with native and bridge ownership labels", %{conn: conn} do
    seed_overview_fixture!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_overview]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs")

    assert html =~ "See what needs attention, why it matters, and where to continue."
    assert html =~ "Needs Review"
    assert html =~ "Blocked"
    assert html =~ "Waiting"
    assert html =~ "Runnable"
    assert html =~ "Resolved continuity"
    assert html =~ "Bridge-only Follow-up"
    assert html =~ "Review Needs Review"
    assert html =~ "partial evidence"
    assert html =~ "Oban Web bridge"
    assert html =~ "Inspection only"
    assert html =~ "Continuity evidence"
    assert has_element?(view, "a[href*='/ops/jobs/lifeline?view=active']")
    assert has_element?(view, "a[href*='/ops/jobs/limiters?resource=payments-api']")
    assert has_element?(view, "a[href*='/ops/jobs/cron?entry=nightly-sync']")
    assert has_element?(view, "a[href*='/oban/jobs/321']")
  end

  test "encodes incident fingerprints in overview Lifeline and Forensics links", %{conn: conn} do
    seed_overview_fixture!(
      active_fingerprint: "dead_executor:executor&with=delimiters",
      resolved_fingerprint: "dead_executor:resolved&with=delimiters"
    )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_overview]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs")

    active_fingerprint = URI.encode_www_form("dead_executor:executor&with=delimiters")
    resolved_fingerprint = URI.encode_www_form("dead_executor:resolved&with=delimiters")

    assert has_element?(
             view,
             "a[href='/ops/jobs/lifeline?view=active&incident_fingerprint=#{active_fingerprint}']"
           )

    assert has_element?(
             view,
             "a[href='/ops/jobs/lifeline?view=resolved&incident_fingerprint=#{resolved_fingerprint}']"
           )

    assert html =~ "/ops/jobs/forensics?incident_fingerprint=#{active_fingerprint}"
    assert html =~ "/ops/jobs/forensics?incident_fingerprint=#{resolved_fingerprint}"
    refute html =~ "incident_fingerprint=dead_executor:executor&with=delimiters"
    refute html =~ "incident_fingerprint=dead_executor:resolved&with=delimiters"
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

    assert html =~ "See what needs attention, why it matters, and where to continue."
    assert html =~ "Needs Review"
    assert html =~ "Blocked"
    assert html =~ "Waiting"
    assert html =~ "Runnable"
    assert html =~ "Bridge-only Follow-up"
    assert html =~ "Resolved continuity"

    assert html =~ "Blocked by policy cooldown for payments-api"
    assert html =~ "Recent cron history shows a missed fire while scheduler coverage was healthy."
    refute html =~ "Historical " <> "Attention"
    refute html =~ "raw " <> "event"
    refute html =~ "event " <> "feed"

    refute html =~ "fourth historical exemplar"
  end

  test "renders attention details with evidence links and stable overview URLs", %{conn: conn} do
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

    {:ok, view, html} = live(conn, "/ops/jobs")

    assert html =~ "Blocked by policy cooldown for payments-api"
    assert html =~ "Recent cron history shows a missed fire while scheduler coverage was healthy."
    assert html =~ "history unavailable"
    assert html =~ "Powertools-native"
    assert html =~ "Open forensic timeline"
    assert html =~ "Open runbook entry"

    assert has_element?(
             view,
             "a[href='/ops/jobs/forensics?resource_id=payments-api&resource_type=limiter']",
             "Open forensic timeline"
           )

    assert has_element?(
             view,
             "a[href='/ops/jobs/limiters?resource=payments-api']",
             "Open runbook entry"
           )

    refute html =~ "attention_reason="
    refute html =~ "reason="
    refute html =~ "copy="
    refute html =~ "preview_token="
    refute html =~ URI.encode_www_form("Blocked by policy cooldown for payments-api")
  end

  test "renders empty guidance inside quiet overview buckets", %{conn: conn} do
    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_overview]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs")

    assert html =~ "No current follow-up identified"

    assert html =~
             "Available evidence identifies no current native or bridge follow-up. Open Jobs to review individual job state."
  end

  test "visual hierarchy proxy: stable triage headings precede historical exemplars and no feed-like section is rendered",
       %{conn: conn} do
    seed_overview_fixture!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_overview]}
      )

    {:ok, _view, html} = live(conn, "/ops/jobs")

    assert_occurs_in_order(html, [
      "Current attention",
      "Needs Review",
      "Blocked",
      "Waiting",
      "Bridge-only Follow-up",
      "Runnable",
      "Resolved continuity"
    ])

    first_bucket = byte_index(html, "Needs Review")

    for exemplar_marker <- [
          "Open forensic timeline",
          "Open runbook entry",
          "Blocked by policy cooldown for payments-api"
        ] do
      idx = byte_index(html, exemplar_marker)

      assert idx > first_bucket,
             "expected historical exemplar marker #{inspect(exemplar_marker)} to render nested inside a bucket (after first bucket heading), got byte index #{idx} vs first bucket at #{first_bucket}"
    end

    for forbidden <- ["Event Feed", "Activity Feed", "Event Stream", "Recent Activity"] do
      refute html =~ forbidden,
             "rendered overview contains forbidden feed-like section heading #{inspect(forbidden)}"
    end
  end

  @tag phase79_slice: "overview"
  test "renders one static semantic tree in the immutable triage order", %{conn: conn} do
    seed_overview_fixture!()

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-79", permissions: [:view_overview]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs")

    assert has_element?(view, "#overview-page")
    assert length(Regex.scan(~r/<h1\b/, html)) == 1
    assert has_element?(view, "h1", "Overview")
    assert html =~ "See what needs attention, why it matters, and where to continue."
    assert has_element?(view, "#overview-current-attention h2", "Current attention")

    assert_occurs_in_order(html, [
      ~s(id="overview-needs-review"),
      ~s(id="overview-blocked"),
      ~s(id="overview-waiting"),
      ~s(id="overview-bridge-follow-up"),
      ~s(id="overview-runnable"),
      ~s(id="overview-resolved-continuity")
    ])

    assert html =~ "representative follow-ups"
    assert html =~ "Oban Web"
    assert has_element?(view, "#overview-bridge-follow-up a", "Inspect in Oban Web")
    refute html =~ "Resolved Recently"
    refute html =~ "recently"

    for forbidden <- [
          ~s(role="alert"),
          "aria-live=",
          "phx-update=\"stream\"",
          "phx-hook=\"poll",
          "Chart",
          "Event Feed",
          "preview_token",
          "plan_hash",
          "blocker_codes"
        ] do
      refute html =~ forbidden
    end
  end

  @tag phase79_slice: "overview"
  test "read model keeps semantic lanes bounded and selector destinations legal" do
    seed_overview_fixture!()

    buckets =
      OverviewReadModel.build(
        repo: TestRepo,
        dashboard_path: "/oban",
        now: ~U[2026-07-19 18:00:00Z]
      )

    assert Enum.map(buckets, &Map.get(&1, :id)) == [
             :needs_review,
             :blocked,
             :waiting,
             :bridge_follow_up,
             :runnable,
             :resolved_continuity
           ]

    assert Enum.all?(buckets, &(length(&1.exemplars) <= 3))

    assert buckets
           |> Enum.map(&ControlPlanePresenter.present_overview_bucket/1)
           |> Enum.map(& &1.id) == [
             "needs_review",
             "blocked",
             "waiting",
             "bridge_follow_up",
             "runnable",
             "resolved_continuity"
           ]

    for bucket <- buckets, exemplar <- bucket.exemplars do
      assert is_binary(exemplar.path)
      assert String.starts_with?(exemplar.path, ["/ops/jobs", "/oban"])
    end
  end

  @tag phase79_slice: "overview"
  test "read model uses one injected observation time for byte-stable presentation input" do
    seed_overview_fixture!()
    now = ~U[2026-07-19 18:00:00Z]

    first = OverviewReadModel.build(repo: TestRepo, dashboard_path: "/oban", now: now)
    second = OverviewReadModel.build(repo: TestRepo, dashboard_path: "/oban", now: now)

    assert first == second
    assert Enum.all?(first, &(&1.observed_at == "July 19, 2026 at 18:00 UTC"))
    assert Enum.all?(first, &(&1.observed_datetime == DateTime.to_iso8601(now)))
  end

  @tag phase79_slice: "overview"
  test "page content is the render tree and safely preserves Unicode presentation text" do
    buckets =
      OverviewReadModel.build(
        repo: TestRepo,
        dashboard_path: "/oban",
        now: ~U[2026-07-19 18:00:00Z]
      )
      |> Enum.map(fn
        %{id: :needs_review} = bucket ->
          %{
            bucket
            | count: 1,
              summary: "مراجعة 東京 🚦 <script>alert(1)</script>",
              impact: "One current incident needs operator review.",
              exemplars: [
                %{
                  label: "عامل 東京 <strong>unsafe</strong>",
                  fact: "Unicode evidence remains readable.",
                  status: :active,
                  path: "/ops/jobs/lifeline",
                  venue: "Powertools",
                  ownership: "Powertools-native",
                  source: "lifeline"
                }
              ]
          }

        bucket ->
          bucket
      end)
      |> Enum.map(&ControlPlanePresenter.present_overview_bucket/1)

    direct =
      render_component(&EngineOverviewLive.page_content/1, overview_buckets: buckets)

    delegated = render_component(&EngineOverviewLive.render/1, overview_buckets: buckets)

    assert direct == delegated
    assert direct =~ "مراجعة 東京 🚦"
    assert direct =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
    assert direct =~ "عامل 東京 &lt;strong&gt;unsafe&lt;/strong&gt;"
    refute direct =~ "<script>"
    refute direct =~ "<strong>unsafe</strong>"
  end

  @tag phase79_slice: "overview"
  test "resolved continuity filters audit support before the twenty-row bound" do
    assert {:ok, repair} =
             Audit.record(
               "lifeline.repair_executed",
               %{type: :job, id: "older-repair-job"},
               %{
                 "event_type" => "lifeline.repair_executed",
                 "reason" => "older repair evidence"
               },
               repo: TestRepo,
               actor_id: "ops-79"
             )

    for index <- 1..21 do
      assert {:ok, _event} =
               Audit.record(
                 "cron.paused",
                 %{type: :cron_entry, id: "newer-unrelated-#{index}"},
                 %{"event_type" => "cron.paused", "reason" => "unrelated"},
                 repo: TestRepo,
                 actor_id: "ops-79"
               )
    end

    continuity =
      TestRepo
      |> then(
        &OverviewReadModel.build(
          repo: &1,
          dashboard_path: "/oban",
          now: ~U[2026-07-19 18:00:00Z]
        )
      )
      |> Enum.find(&(&1.id == :resolved_continuity))

    assert [%{source: "audit", label: "job:older-repair-job", path: path}] =
             continuity.exemplars

    assert path ==
             "/ops/jobs/audit?resource_type=job&resource_id=older-repair-job&event_type=lifeline.repair_executed"

    assert repair.id < Enum.max(Enum.map(Audit.list_all(repo: TestRepo), & &1.id))
  end

  @tag phase79_slice: "overview"
  test "quiet overview uses compact available-evidence truth without live or mutation semantics",
       %{
         conn: conn
       } do
    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-quiet-79", permissions: [:view_overview]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs")

    assert html =~ "No current follow-up identified"

    assert html =~
             "Available evidence identifies no current native or bridge follow-up. Open Jobs to review individual job state."

    assert has_element?(view, "#overview-needs-review")
    assert has_element?(view, "#overview-blocked")
    assert has_element?(view, "#overview-waiting")
    refute html =~ ~r/phx-(click|submit|change)="(pause|resume|run|execute|repair)/
    refute html =~ ~s(role="alert")
    refute html =~ "aria-live="
  end

  defp seed_overview_fixture!(opts \\ []) do
    active_fingerprint = Keyword.get(opts, :active_fingerprint, "dead_executor:executor-1")
    resolved_fingerprint = Keyword.get(opts, :resolved_fingerprint, "dead_executor:executor-2")

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
        incident_fingerprint: active_fingerprint,
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
        incident_fingerprint: resolved_fingerprint,
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

  defp assert_occurs_in_order(text, markers) do
    Enum.reduce(markers, {text, 0}, fn marker, {remaining, offset} ->
      assert String.contains?(remaining, marker),
             "expected #{inspect(marker)} after byte offset #{offset}"

      {index, _len} = :binary.match(remaining, marker)
      next_offset = offset + index + byte_size(marker)

      next_remaining =
        binary_part(
          remaining,
          index + byte_size(marker),
          byte_size(remaining) - index - byte_size(marker)
        )

      {next_remaining, next_offset}
    end)
  end

  test "encodes delimiter-heavy incident fingerprints with the full canonical delimiter set in overview links",
       %{conn: conn} do
    # Full D-19 delimiter set: : / ? # % space & =
    active_fingerprint = "dead_executor:exec/path?frag#tag with%20space&query=value"
    resolved_fingerprint = "dead_executor:resolved/path?frag#tag with%20space&query=value"

    seed_overview_fixture!(
      active_fingerprint: active_fingerprint,
      resolved_fingerprint: resolved_fingerprint
    )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_overview]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs")

    encoded_active = URI.encode_www_form(active_fingerprint)
    encoded_resolved = URI.encode_www_form(resolved_fingerprint)

    # Lifeline links use encoded fingerprint
    assert has_element?(
             view,
             "a[href='/ops/jobs/lifeline?view=active&incident_fingerprint=#{encoded_active}']"
           )

    assert has_element?(
             view,
             "a[href='/ops/jobs/lifeline?view=resolved&incident_fingerprint=#{encoded_resolved}']"
           )

    # Forensics links use encoded fingerprint
    assert html =~ "/ops/jobs/forensics?incident_fingerprint=#{encoded_active}"
    assert html =~ "/ops/jobs/forensics?incident_fingerprint=#{encoded_resolved}"

    # Raw delimiters must NOT appear unencoded in fingerprint parameter context
    refute html =~ "incident_fingerprint=dead_executor:exec/path"
    refute html =~ "incident_fingerprint=dead_executor:resolved/path"
    refute html =~ "incident_fingerprint=#{active_fingerprint}"
    refute html =~ "incident_fingerprint=#{resolved_fingerprint}"
  end

  defp byte_index(text, marker) do
    case :binary.match(text, marker) do
      {index, _len} -> index
      :nomatch -> flunk("expected #{inspect(marker)} to be present in rendered HTML")
    end
  end
end
