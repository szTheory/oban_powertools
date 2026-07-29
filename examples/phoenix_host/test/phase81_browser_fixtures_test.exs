defmodule PhoenixHostWeb.Phase81BrowserFixturesTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  @endpoint PhoenixHostWeb.Endpoint
  @enabled System.get_env("PHASE81_BROWSER_FIXTURES") == "1"

  if @enabled do
    import Ecto.Query

    alias ObanPowertools.{Audit, BatchJob, Callback, Lifeline}
    alias ObanPowertools.Lifeline.{ArchiveRun, Heartbeat, Incident, RepairPreview}
    alias ObanPowertools.Workflow.{Edge, Result, Step, Workflow}
    alias PhoenixHost.Repo

    setup do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
      :ok
    end

    setup_all do
      previous = System.get_env("PHASE81_BROWSER_FIXTURE_SECRET")
      secret = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
      System.put_env("PHASE81_BROWSER_FIXTURE_SECRET", secret)

      on_exit(fn ->
        if previous,
          do: System.put_env("PHASE81_BROWSER_FIXTURE_SECRET", previous),
          else: System.delete_env("PHASE81_BROWSER_FIXTURE_SECRET")
      end)

      {:ok, secret: secret}
    end

    test "reset is deterministic, isolated, and seeds every exact bounded family", %{
      secret: secret
    } do
      first = reset("chromium-wide", "contract", secret)
      second = reset("chromium-wide", "contract", secret)

      assert first == second

      assert first["counts"] == %{
               "workflows" => 51,
               "workflowSteps" => 101,
               "workflowResults" => 51,
               "workflowEvidence" => 26,
               "batchMembers" => 51,
               "batchCallbacks" => 26,
               "batchAudit" => 26,
               "incidents" => 51,
               "executors" => 26,
               "lifelineAudit" => 51
             }

      key = "chromium-wide:contract"
      workflow_id = first["handles"]["workflowId"]
      batch_id = first["handles"]["batchId"]

      assert Repo.aggregate(
               from(workflow in Workflow,
                 where: fragment("?->>'phase81_key' = ?", workflow.workflow_context, ^key)
               ),
               :count
             ) == 51

      assert Repo.aggregate(from(step in Step, where: step.workflow_id == ^workflow_id), :count) ==
               101

      assert Repo.aggregate(
               from(result in Result, where: result.workflow_id == ^workflow_id),
               :count
             ) == 51

      assert Repo.aggregate(
               from(edge in Edge, where: edge.workflow_id == ^workflow_id),
               :count
             ) == 26

      assert Repo.aggregate(from(member in BatchJob, where: member.batch_id == ^batch_id), :count) ==
               51

      assert Repo.aggregate(
               from(callback in Callback, where: callback.batch_id == ^batch_id),
               :count
             ) == 26

      assert Repo.aggregate(
               from(incident in Incident,
                 where: fragment("?->>'phase81_key' = ?", incident.metadata, ^key)
               ),
               :count
             ) == 51

      assert Repo.aggregate(
               from(heartbeat in Heartbeat,
                 where: fragment("?->>'phase81_key' = ?", heartbeat.metadata, ^key)
               ),
               :count
             ) == 26

      assert Repo.aggregate(
               from(run in ArchiveRun,
                 where: fragment("?->>'phase81_key' = ?", run.metadata, ^key)
               ),
               :count
             ) == 26

      assert Repo.aggregate(
               from(event in Audit,
                 where: fragment("?->>'phase81_key' = ?", event.metadata, ^key)
               ),
               :count
             ) == 103

      other = reset("chromium-tablet", "contract", secret)
      refute other["handles"]["batchId"] == batch_id
      assert reset("chromium-wide", "contract", secret) == first
    end

    test "actor and every authorization or execution race control are closed and scoped", %{
      secret: secret
    } do
      reset("chromium-wide", "races", secret)

      for actor <- ~w(ops restricted) do
        response =
          post_json(
            "/actor",
            %{"project" => "chromium-wide", "run" => "races", "actor" => actor},
            secret
          )

        assert response.status == 200
        assert decode(response) == %{"actor" => actor, "state" => "authenticated"}
        assert response.resp_cookies["_phoenix_host_key"]
      end

      for command <- ~w(revoke drift duplicate disconnect interrupt restore) do
        response =
          post_json(
            "/race",
            %{"project" => "chromium-wide", "run" => "races", "command" => command},
            secret
          )

        expected = if command == "restore", do: "authorized", else: command
        assert decode(response) == %{"command" => command, "state" => expected}

        status =
          post_json(
            "/race",
            %{"project" => "chromium-wide", "run" => "races", "command" => "status"},
            secret
          )

        assert decode(status) == %{"command" => "status", "state" => expected}
      end
    end

    test "drift and duplicate controls alter real Lifeline execution outcomes" do
      state =
        PhoenixHostWeb.Phase81BrowserFixtures.reset(%{
          "project" => "chromium-wide",
          "run" => "production-races"
        })

      assert {:ok, fixture} = state
      key = "chromium-wide:production-races"
      actor = %{id: "phase81-operator", label: "ops", role: :ops, phase81_key: key}

      job =
        Repo.one!(
          from(job in Oban.Job,
            where: fragment("?->>'phase81_key' = ?", job.meta, ^key) and job.state == "executing"
          )
        )

      assert {:ok, drift_preview} =
               Lifeline.preview_repair(Repo, actor, %{
                 incident_fingerprint: fixture["handles"]["incidentId"],
                 action: "job_rescue",
                 target_type: "job",
                 target_id: job.id
               })

      assert {:ok, %{"state" => "drift"}} =
               PhoenixHostWeb.Phase81BrowserFixtures.control_race(
                 %{
                   "project" => "chromium-wide",
                   "run" => "production-races",
                   "command" => "drift"
                 },
                 "drift"
               )

      assert {:error, :preview_drifted} =
               Lifeline.execute_repair(
                 Repo,
                 actor,
                 drift_preview.preview_token,
                 "Target changed after preview."
               )

      assert Repo.get!(RepairPreview, drift_preview.id).status == "drifted"

      {:ok, fixture} =
        PhoenixHostWeb.Phase81BrowserFixtures.reset(%{
          "project" => "chromium-wide",
          "run" => "production-races"
        })

      job =
        Repo.one!(
          from(job in Oban.Job,
            where: fragment("?->>'phase81_key' = ?", job.meta, ^key) and job.state == "executing"
          )
        )

      assert {:ok, duplicate_preview} =
               Lifeline.preview_repair(Repo, actor, %{
                 incident_fingerprint: fixture["handles"]["incidentId"],
                 action: "job_rescue",
                 target_type: "job",
                 target_id: job.id
               })

      assert {:ok, %{"state" => "duplicate"}} =
               PhoenixHostWeb.Phase81BrowserFixtures.control_race(
                 %{
                   "project" => "chromium-wide",
                   "run" => "production-races",
                   "command" => "duplicate"
                 },
                 "duplicate"
               )

      assert {:error, :preview_consumed} =
               Lifeline.execute_repair(
                 Repo,
                 actor,
                 duplicate_preview.preview_token,
                 "Second execution must be suppressed."
               )
    end

    test "credential, method, command, identity, and request schema fail closed", %{
      secret: secret
    } do
      missing = post_json("/reset", %{"unknown" => true}, nil)
      wrong = post_json("/reset", %{"unknown" => true}, secret <> "-wrong")
      assert {missing.status, missing.resp_body} == {404, ""}
      assert {wrong.status, wrong.resp_body} == {404, ""}

      assert post_json(
               "/reset",
               %{"project" => "chromium-wide", "run" => "closed", "unknown" => true},
               secret
             ).status == 404

      assert post_json(
               "/reset",
               %{"project" => "outside", "run" => "closed"},
               secret
             ).status == 404

      assert post_json(
               "/race",
               %{"project" => "chromium-wide", "run" => "closed", "command" => "execute"},
               secret
             ).status == 404

      get =
        conn(:get, "/__phase81_browser_fixtures__/reset")
        |> @endpoint.call(@endpoint.init([]))

      assert get.status == 404
    end

    test "all public responses recursively exclude credentials, tokens, snapshots, and authority",
         %{secret: secret} do
      reset_response =
        post_json(
          "/reset",
          %{"project" => "chromium-wide", "run" => "public"},
          secret
        )

      actor_response =
        post_json(
          "/actor",
          %{"project" => "chromium-wide", "run" => "public", "actor" => "ops"},
          secret
        )

      race_response =
        post_json(
          "/race",
          %{"project" => "chromium-wide", "run" => "public", "command" => "drift"},
          secret
        )

      for response <- [reset_response, actor_response, race_response] do
        body = String.downcase(response.resp_body)
        refute body =~ String.downcase(secret)
        refute body =~ "secret"
        refute body =~ "token"
        refute body =~ "snapshot"
        refute body =~ "credential"
        refute body =~ "authority"
      end
    end

    defp reset(project, run, secret) do
      "/reset"
      |> post_json(%{"project" => project, "run" => run}, secret)
      |> decode()
    end

    defp decode(conn), do: Jason.decode!(conn.resp_body)
  else
    test "fixture modules and all routes are absent with the compile-time flag off" do
      refute Code.ensure_loaded?(PhoenixHostWeb.Phase81BrowserFixtures)
      refute Code.ensure_loaded?(PhoenixHostWeb.Phase81BrowserFixturesController)

      for action <- ~w(reset actor race) do
        response = post_json("/#{action}", %{}, nil)
        assert {response.status, response.resp_body} == {404, ""}
      end
    end

    test "route-off source retains strict test, flag, and POST-only gating" do
      router = File.read!("lib/phoenix_host_web/router.ex")
      fixture = File.read!("test/support/phase81_browser_fixtures.ex")
      gate = "Mix.env() == :test and System.get_env(\"PHASE81_BROWSER_FIXTURES\") == \"1\""

      assert router =~ gate
      assert fixture =~ gate
      refute router =~ ~s(get "/__phase81_browser_fixtures__)
    end
  end

  defp post_json(action, params, secret) do
    conn = conn(:post, "/__phase81_browser_fixtures__#{action}", Jason.encode!(params))
    conn = put_req_header(conn, "content-type", "application/json")
    conn = if secret, do: put_req_header(conn, "x-phase81-fixture-secret", secret), else: conn
    @endpoint.call(conn, @endpoint.init([]))
  end
end
