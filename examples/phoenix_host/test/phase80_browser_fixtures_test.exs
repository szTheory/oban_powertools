defmodule PhoenixHostWeb.Phase80BrowserFixturesTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  @endpoint PhoenixHostWeb.Endpoint
  @fixture_enabled System.get_env("PHASE80_BROWSER_FIXTURES") == "1"

  if @fixture_enabled do
    import Ecto.Query

    alias ObanPowertools.{Audit, Jobs}
    alias ObanPowertools.Cron.Entry
    alias ObanPowertools.Forensics.LimiterHistoryFact
    alias ObanPowertools.Lifeline.Incident
    alias ObanPowertools.Limits.Resource
    alias ObanPowertools.Workflow.Workflow
    alias PhoenixHost.Repo

    @projects ~w(chromium-320 chromium-tablet chromium-wide)
    @states ~w(available scheduled executing retryable cancelled discarded completed)

    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      :ok
    end

    setup_all do
      previous = System.get_env("PHASE80_BROWSER_FIXTURE_SECRET")
      secret = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
      System.put_env("PHASE80_BROWSER_FIXTURE_SECRET", secret)

      on_exit(fn ->
        if previous,
          do: System.put_env("PHASE80_BROWSER_FIXTURE_SECRET", previous),
          else: System.delete_env("PHASE80_BROWSER_FIXTURE_SECRET")
      end)

      {:ok, secret: secret}
    end

    test "reset is deterministic, bounded, idempotent, and isolated from other fixture runs", %{
      secret: secret
    } do
      Enum.each(@projects, fn project ->
        first = reset(project, "contract", secret)
        second = reset(project, "contract", secret)

        assert first == second
        assert_public_reset!(second, project, "contract")

        key = "#{project}:contract"

        assert Repo.aggregate(
                 from(job in Oban.Job,
                   where: fragment("?->>'phase80_key' = ?", job.meta, ^key)
                 ),
                 :count
               ) == 2_500

        assert Repo.all(
                 from(job in Oban.Job,
                   where: fragment("?->>'phase80_key' = ?", job.meta, ^key),
                   distinct: job.state,
                   select: job.state,
                   order_by: job.state
                 )
               ) == Enum.sort(@states)

        boundary_filter = %Jobs{
          state: :retryable,
          queue: second["jobs"]["boundaryQueue"],
          page: 2
        }

        assert Jobs.count(Repo, boundary_filter) == 40
        assert length(Jobs.list(Repo, boundary_filter)) == 20
      end)

      other = reset("chromium-wide", "other", secret)
      reset("chromium-wide", "contract", secret)

      assert Repo.exists?(
               from(job in Oban.Job,
                 where:
                   job.id == ^other["jobs"]["stateIds"]["available"] and
                     fragment("?->>'phase80_key' = ?", job.meta, ^"chromium-wide:other")
               )
             )
    end

    test "reset seeds all four bounded forensic families and preserves Phase 79 rows", %{
      secret: secret
    } do
      phase79 =
        PhoenixHostWeb.Phase79BrowserFixtures.reset(%{
          "project" => "chromium-wide",
          "run" => "coexist"
        })

      assert {:ok, phase79_state} = phase79

      state = reset("chromium-wide", "coexist", secret)
      key = "chromium-wide:coexist"

      assert Repo.get(Workflow, state["forensics"]["workflowId"])

      assert Repo.get_by(
               Incident,
               incident_fingerprint: state["forensics"]["incidentFingerprint"]
             )

      assert Repo.get_by(Entry, name: state["forensics"]["cronEntry"])
      assert Repo.get_by(Resource, name: state["forensics"]["limiterResource"])

      assert Repo.aggregate(
               from(fact in LimiterHistoryFact,
                 where: fact.resource_name == ^state["forensics"]["limiterResource"]
               ),
               :count
             ) == 8

      assert Repo.aggregate(
               from(event in Audit,
                 where:
                   event.resource_type == "workflow" and
                     event.resource_id == ^state["forensics"]["workflowId"]
               ),
               :count
             ) == 55

      assert Repo.aggregate(
               from(event in Audit,
                 where: fragment("?->>'phase80_key' = ?", event.metadata, ^key)
               ),
               :count
             ) == 110

      assert Repo.get_by(Entry, name: phase79_state["cron"]["firstEntry"])
    end

    test "actor, batch barrier, perturbation, and evidence commands are closed and scoped", %{
      secret: secret
    } do
      state = reset("chromium-wide", "commands", secret)

      ops =
        post_json(
          "/actor",
          %{
            "project" => "chromium-wide",
            "run" => "commands",
            "actor" => "ops"
          },
          secret
        )

      restricted =
        post_json(
          "/actor",
          %{
            "project" => "chromium-wide",
            "run" => "commands",
            "actor" => "restricted"
          },
          secret
        )

      assert decode(ops) == %{"actor" => "ops", "state" => "authenticated"}
      assert decode(restricted) == %{"actor" => "restricted", "state" => "authenticated"}
      assert ops.resp_cookies["_phoenix_host_key"]
      assert restricted.resp_cookies["_phoenix_host_key"]

      held = batch("chromium-wide", "commands", "hold", secret)
      assert held == %{"command" => "hold", "state" => "held"}
      assert batch("chromium-wide", "commands", "status", secret) == held

      released = batch("chromium-wide", "commands", "release", secret)
      assert released == %{"command" => "release", "state" => "released"}

      assert batch("chromium-wide", "commands", "perturb", secret, %{
               "target" => "drifted"
             }) == %{"command" => "perturb", "state" => "prepared"}

      drifted_id = state["jobs"]["targets"]["drifted"]
      assert Repo.get!(Oban.Job, drifted_id).state == "scheduled"

      evidence = evidence("chromium-wide", "commands", secret)
      assert Map.keys(evidence) |> Enum.sort() == ~w(audit counts project run states)
      assert evidence["project"] == "chromium-wide"
      assert evidence["run"] == "commands"
      assert Map.keys(evidence["counts"]) |> Enum.sort() == ~w(auditedEffects jobs)
      assert Map.keys(evidence["audit"]) == ["complete"]

      assert Map.keys(evidence["states"]) |> Enum.sort() ==
               Enum.sort(Map.keys(state["jobs"]["targets"]))

      assert post_json("/batch", %{"project" => "chromium-wide"}, secret).status == 404

      assert post_json(
               "/batch",
               %{
                 "project" => "chromium-wide",
                 "run" => "commands",
                 "command" => "execute"
               },
               secret
             ).status == 404
    end

    test "missing and wrong secrets are identical empty 404s before JSON schema validation", %{
      secret: secret
    } do
      missing = post_json("/reset", %{"unknown" => "value"}, nil)
      wrong = post_json("/reset", %{"unknown" => "value"}, secret <> "-wrong")

      assert {missing.status, missing.resp_body} == {404, ""}
      assert {wrong.status, wrong.resp_body} == {404, ""}
    end

    test "request and response schemas reject unknown and sensitive fields", %{secret: secret} do
      unknown =
        post_json(
          "/reset",
          %{"project" => "chromium-wide", "run" => "closed", "extra" => true},
          secret
        )

      assert {unknown.status, unknown.resp_body} == {404, ""}

      state = reset("chromium-wide", "closed", secret)
      serialized = Jason.encode!(state)

      for forbidden <- [
            "phase80-args-sentinel",
            "phase80-meta-sentinel",
            "phase80-output-sentinel",
            "phase80-error-sentinel",
            "phase80-reason-sentinel",
            "phase80-runbook-sentinel",
            "preview_token",
            "plan_hash",
            "credential",
            "raw_error",
            "metadata"
          ] do
        refute String.contains?(String.downcase(serialized), forbidden)
      end
    end

    test "router exposes exactly four POST-only Phase 80 actions and no catch-all" do
      source = File.read!("lib/phoenix_host_web/router.ex")

      assert source =~ ~s(post "/reset", Phase80BrowserFixturesController, :reset)
      assert source =~ ~s(post "/actor", Phase80BrowserFixturesController, :actor)
      assert source =~ ~s(post "/batch", Phase80BrowserFixturesController, :batch)
      assert source =~ ~s(post "/evidence", Phase80BrowserFixturesController, :evidence)
      refute source =~ ~s(get "/__phase80_browser_fixtures__)
      refute source =~ "resources \"/__phase80_browser_fixtures__"
      refute source =~ "forward \"/__phase80_browser_fixtures__"
    end

    defp reset(project, run, secret) do
      "/reset"
      |> post_json(%{"project" => project, "run" => run}, secret)
      |> assert_ok()
      |> decode()
    end

    defp batch(project, run, command, secret, extra \\ %{}) do
      params =
        Map.merge(%{"project" => project, "run" => run, "command" => command}, extra)

      "/batch"
      |> post_json(params, secret)
      |> assert_ok()
      |> decode()
    end

    defp evidence(project, run, secret) do
      "/evidence"
      |> post_json(%{"project" => project, "run" => run}, secret)
      |> assert_ok()
      |> decode()
    end

    defp assert_ok(conn) do
      assert conn.status == 200
      conn
    end

    defp assert_public_reset!(state, project, run) do
      assert Map.keys(state) |> Enum.sort() ==
               ~w(actors batch counts forensics jobs project run)

      assert state["project"] == project
      assert state["run"] == run
      assert state["actors"] == ["ops", "restricted"]
      assert state["batch"] == %{"state" => "idle"}

      assert state["counts"] == %{
               "incidentEvents" => 55,
               "jobs" => 2_500,
               "workflowEvents" => 55
             }

      assert state["jobs"]["pageSize"] == 20
      assert state["jobs"]["totalCount"] == 2_500
      assert state["jobs"]["finalPage"] == 125
      assert state["jobs"]["finalPageCount"] == 20
      assert state["jobs"]["underLimitCount"] < 100
      assert state["jobs"]["overLimitCount"] > 100
      assert Map.keys(state["jobs"]["stateIds"]) |> Enum.sort() == Enum.sort(@states)

      assert Map.keys(state["forensics"]) |> Enum.sort() ==
               ~w(cronEntry eventWindow incidentFingerprint limiterResource workflowId workflowStep)

      assert state["forensics"]["eventWindow"] == 55
    end

    defp decode(conn), do: Jason.decode!(conn.resp_body)
  else
    test "fixture modules and all four routes are absent with the compile-time flag off" do
      refute Code.ensure_loaded?(PhoenixHostWeb.Phase80BrowserFixtures)
      refute Code.ensure_loaded?(PhoenixHostWeb.Phase80BrowserFixturesController)

      for action <- ~w(reset actor batch evidence) do
        response = post_json("/#{action}", %{}, nil)
        assert {response.status, response.resp_body} == {404, ""}
      end
    end

    test "route-off source retains strict test and environment gating" do
      router = File.read!("lib/phoenix_host_web/router.ex")
      fixture = File.read!("test/support/phase80_browser_fixtures.ex")

      gate = "Mix.env() == :test and System.get_env(\"PHASE80_BROWSER_FIXTURES\") == \"1\""

      assert router =~ gate
      assert fixture =~ gate
      refute router =~ ~s(get "/__phase80_browser_fixtures__)
    end
  end

  defp post_json(action, params, secret) do
    conn = conn(:post, "/__phase80_browser_fixtures__#{action}", Jason.encode!(params))
    conn = put_req_header(conn, "content-type", "application/json")
    conn = if secret, do: put_req_header(conn, "x-phase80-fixture-secret", secret), else: conn
    @endpoint.call(conn, @endpoint.init([]))
  end
end
