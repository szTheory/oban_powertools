defmodule ObanPowertools.Web.LimitersLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Explain
  alias ObanPowertools.Forensics.LimiterHistoryFact
  alias ObanPowertools.Limits.{Resource, State}

  test "renders current blockers and block-start snapshot with job deep link", %{conn: conn} do
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

    {:ok, _view, html} = live(conn, "/ops/jobs/limiters?resource=user-api")
    assert html =~ "Review blockers"
    assert html =~ "Current blockers"
    assert html =~ "Snapshot at block start"
    assert html =~ "Open in Oban Web"
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

    assert html =~ "Review blockers" or html =~ "Current blockers"

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

    assert html =~ "Retained history"
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

  test "ownership boundary remains explicit", %{conn: conn} do
    resource =
      TestRepo.insert!(%Resource{
        name: "ownership-boundary-limiter",
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

    connection =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-11", permissions: [:view_limiters, :view_forensics]}
      )

    {:ok, view, html} = live(connection, "/ops/jobs/limiters?resource=#{resource.name}")

    assert html =~ "Powertools-native"
    assert html =~ "Oban Web bridge"
    assert html =~ "host-owned follow-up"

    assert has_element?(
             view,
             ~s([data-runbook-ownership="Powertools-native"][data-runbook-variant="native_primary"])
           )

    assert has_element?(
             view,
             ~s([data-runbook-ownership="Oban Web bridge"][data-runbook-variant="bridge_guidance"])
           )

    assert has_element?(
             view,
             ~s([data-runbook-ownership="host-owned follow-up"][data-runbook-variant="host_guidance"])
           )

    refute has_element?(
             view,
             ~s([data-runbook-ownership="Oban Web bridge"][data-runbook-variant="native_primary"])
           )

    refute has_element?(
             view,
             ~s([data-runbook-ownership="host-owned follow-up"][data-runbook-variant="native_primary"])
           )

    refute html =~ "alert delivered"
    refute html =~ "ticket created"
    refute html =~ "page sent"
    refute html =~ "PagerDuty"
    refute html =~ "Slack"
  end

  @tag phase79_slice: "limiters"
  test "uses a read-only DataTable and canonical resource-owned detail history", %{conn: conn} do
    for name <- ["api/global ?&=", "billing-export"] do
      insert_resource!(name)
    end

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-79", permissions: [:view_limiters]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/limiters")
    encoded = URI.encode_www_form("api/global ?&=")

    assert has_element?(view, "#limiters-page")
    assert has_element?(view, "#limiters-table.obpt-data-table")
    assert has_element?(view, "#limiters-table caption", "Limiters")

    assert html =~
             "Review limiter state, understand what blocks progress now, and follow the right evidence path."

    assert has_element?(view, "#limiters-table th", "Limiter")
    assert has_element?(view, "#limiters-table th", "Scope")
    assert has_element?(view, "#limiters-table th", "State")
    refute has_element?(view, "#limiters-table input[type='checkbox']")
    refute has_element?(view, "#limiters-table tbody tr[phx-click]")

    assert has_element?(
             view,
             "a[href='/ops/jobs/limiters?resource=#{encoded}'][aria-label='Review blockers for api/global ?&=']",
             "Review blockers"
           )

    view
    |> element("a[href='/ops/jobs/limiters?resource=#{encoded}']")
    |> render_click()

    assert_patch(view, "/ops/jobs/limiters?resource=#{encoded}")
    assert has_element?(view, "#limiter-detail")

    view
    |> element("a[href='/ops/jobs/limiters?resource=billing-export']")
    |> render_click()

    assert_patch(view, "/ops/jobs/limiters?resource=billing-export")
    render_hook(view, "close_detail", %{})
    assert_patch(view, "/ops/jobs/limiters")
    refute has_element?(view, "#limiter-detail")
  end

  @tag phase79_slice: "limiters"
  test "locks current evidence before snapshot, retained history, and destinations", %{conn: conn} do
    resource = insert_resource!("evidence-order")
    insert_state!(resource, tokens_used: 5, cooldown_reason: "operator hold")

    TestRepo.insert!(%Explain{
      job_id: 791,
      worker: "ExampleWorker",
      status: "blocked",
      scope_kind: "global",
      scope_id: resource.name,
      blocker_codes: ["PHASE79_TECH_CODE_SENTINEL"],
      details: %{
        "partition_key" => "tenant-79",
        "live_now" => [
          %{
            "code" => "PHASE79_TECH_CODE_SENTINEL",
            "summary" => "Capacity is currently reserved for another tenant."
          }
        ]
      },
      captured_at: DateTime.utc_now()
    })

    TestRepo.insert!(%LimiterHistoryFact{
      resource_name: resource.name,
      partition_key: "tenant-79",
      event_type: "limiter.blocked",
      cause_kind: "policy",
      occurred_at: DateTime.utc_now(),
      metadata: %{"reason" => "historical policy observation"}
    })

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-evidence-79", permissions: [:view_limiters, :view_forensics]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/limiters?resource=evidence-order")

    assert_occurs_in_order(html, [
      ~s(id="limiter-detail"),
      ~s(id="limiter-current-blockers"),
      ~s(id="limiter-block-start-snapshot"),
      ~s(id="limiter-retained-history"),
      ~s(id="limiter-destinations")
    ])

    assert html =~ "Affected scope"
    assert html =~ "tenant-79"
    assert html =~ "Clears when"
    assert html =~ "Observed"
    assert html =~ "Snapshot at block start"
    assert html =~ "Retained history"
    assert has_element?(view, "#limiter-destinations a", "Open forensic timeline")
    assert has_element?(view, "#limiter-destinations a", "Open in Oban Web")
    refute html =~ "PHASE79_TECH_CODE_SENTINEL"
    refute html =~ "root cause"
    refute html =~ ~r/phx-(click|submit)="(pause|resume|run|repair|execute)/
  end

  @tag phase79_slice: "limiters"
  test "incomplete current evidence never claims Runnable or No blockers", %{conn: conn} do
    insert_resource!("evidence-unavailable")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-unavailable-79", permissions: [:view_limiters]}
      )

    {:ok, view, html} =
      live(conn, "/ops/jobs/limiters?resource=evidence-unavailable")

    assert has_element?(
             view,
             "#limiter-current-blockers[data-obpt-evidence-state='unavailable']"
           )

    assert html =~ "Current blocker evidence is unavailable"
    refute html =~ "Runnable"
    refute html =~ "No blockers"
    refute has_element?(view, "a", "Open forensic timeline")
  end

  @tag phase79_slice: "limiters"
  test "complete empty current evidence visibly reports Runnable", %{conn: conn} do
    resource = insert_resource!("runnable-evidence")
    insert_state!(resource, tokens_used: 0, cooldown_until: nil)

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-runnable-79", permissions: [:view_limiters]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/limiters?resource=runnable-evidence")

    assert has_element?(
             view,
             "#limiter-current-blockers .obpt-why-blocked__empty-truth",
             "Runnable"
           )

    refute html =~ "No blockers"
  end

  @tag phase79_slice: "limiters"
  test "resource and state scans stay batched and the page exposes no mutation handler" do
    source = File.read!("lib/oban_powertools/web/limiters_live.ex")

    assert source =~ "states_by_resource"
    assert source =~ "Enum.group_by"

    refute source =~
             ~r/for\s+resource\s+<-\s+repo\(\)\.all.*repo\(\)\.all\(from\(state/s

    events =
      Regex.scan(~r/def handle_event\("([^"]+)"/, source, capture: :all_but_first)
      |> List.flatten()
      |> MapSet.new()

    assert MapSet.subset?(events, MapSet.new(["inspect", "close_detail"]))
    assert source =~ "now = DateTime.utc_now()"
  end

  @tag phase79_slice: "limiters"
  test "resource and state list query counts stay constant as the scan grows", %{conn: conn} do
    insert_resource!("single-resource")

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-query-shape-79", permissions: [:view_limiters]}
      )

    one_resource_counts = capture_limiter_queries(fn -> live(conn, "/ops/jobs/limiters") end)

    for index <- 1..12 do
      insert_resource!("many-resources-#{index}")
    end

    many_resource_counts = capture_limiter_queries(fn -> live(conn, "/ops/jobs/limiters") end)

    assert Map.take(one_resource_counts, [
             "oban_powertools_limit_resources",
             "oban_powertools_limit_states"
           ]) ==
             Map.take(many_resource_counts, [
               "oban_powertools_limit_resources",
               "oban_powertools_limit_states"
             ])

    assert one_resource_counts["oban_powertools_limit_resources"] == 2
    assert one_resource_counts["oban_powertools_limit_states"] == 2
  end

  defp insert_resource!(name) do
    TestRepo.insert!(%Resource{
      name: name,
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
  end

  defp insert_state!(resource, opts) do
    TestRepo.insert!(%State{
      resource_id: resource.id,
      partition_key: "tenant-79",
      tokens_used: Keyword.fetch!(opts, :tokens_used),
      bucket_started_at: DateTime.utc_now(),
      cooldown_until:
        Keyword.get_lazy(opts, :cooldown_until, fn ->
          DateTime.add(DateTime.utc_now(), 60, :second)
        end),
      cooldown_reason: Keyword.get(opts, :cooldown_reason),
      reservation_snapshot: %{}
    })
  end

  defp assert_occurs_in_order(text, markers) do
    indexes =
      Enum.map(markers, fn marker ->
        case :binary.match(text, marker) do
          {index, _length} -> index
          :nomatch -> flunk("expected #{inspect(marker)} in rendered Limiters HTML")
        end
      end)

    assert indexes == Enum.sort(indexes)
  end

  defp capture_limiter_queries(fun) do
    handler_id = {__MODULE__, make_ref()}
    event = TestRepo.config() |> Keyword.fetch!(:telemetry_prefix) |> Kernel.++([:query])
    test_pid = self()

    :telemetry.attach(
      handler_id,
      event,
      fn _event, _measurements, metadata, pid ->
        if metadata[:source] in [
             "oban_powertools_limit_resources",
             "oban_powertools_limit_states"
           ] do
          send(pid, {:limiter_query, metadata.source})
        end
      end,
      test_pid
    )

    try do
      fun.()
      collect_limiter_queries(%{})
    after
      :telemetry.detach(handler_id)
    end
  end

  defp collect_limiter_queries(counts) do
    receive do
      {:limiter_query, source} ->
        collect_limiter_queries(Map.update(counts, source, 1, &(&1 + 1)))
    after
      0 -> counts
    end
  end
end
