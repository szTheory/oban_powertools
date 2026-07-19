defmodule PhoenixHostWeb.Phase79BrowserFixturesTest do
  use ExUnit.Case, async: false

  import Ecto.Query
  import Plug.Conn
  import Plug.Test

  alias ObanPowertools.{Audit, Explain}
  alias ObanPowertools.Cron.Entry
  alias ObanPowertools.Forensics.LimiterHistoryFact
  alias ObanPowertools.Lifeline.{Incident, RepairPreview}
  alias ObanPowertools.Limits.Resource
  alias PhoenixHost.Repo

  @endpoint PhoenixHostWeb.Endpoint
  @fixture_enabled System.get_env("PHASE79_BROWSER_FIXTURES") == "1"
  @projects ~w(chromium-320 chromium-tablet chromium-wide)

  if @fixture_enabled do
    setup_all do
      previous = System.get_env("PHASE79_BROWSER_FIXTURE_SECRET")
      secret = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
      System.put_env("PHASE79_BROWSER_FIXTURE_SECRET", secret)

      on_exit(fn ->
        if previous,
          do: System.put_env("PHASE79_BROWSER_FIXTURE_SECRET", previous),
          else: System.delete_env("PHASE79_BROWSER_FIXTURE_SECRET")
      end)

      {:ok, secret: secret}
    end

    test "reset is deterministic, idempotent, isolated, and returns only public fields", %{
      secret: secret
    } do
      Enum.each(@projects, fn project ->
        params = %{"project" => project, "run" => "contract"}
        first = post_json("/reset", params, secret)
        second = post_json("/reset", params, secret)

        assert first.status == 200
        assert second.status == 200
        assert decode(first) == decode(second)
        assert_public_reset!(decode(second), project, "contract")

        assert Repo.aggregate(
                 from(entry in Entry, where: like(entry.name, ^"phase79-#{project}-contract-%")),
                 :count
               ) == 3

        assert Repo.aggregate(
                 from(resource in Resource,
                   where: like(resource.name, ^"phase79-#{project}-contract-%")
                 ),
                 :count
               ) == 2

        assert Repo.aggregate(
                 from(event in Audit,
                   where:
                     event.resource_type == "phase79_fixture" and
                       event.resource_id == ^"#{project}:contract"
                 ),
                 :count
               ) == 45
      end)

      isolated = post_json("/reset", %{"project" => "chromium-wide", "run" => "isolated"}, secret)
      assert isolated.status == 200

      assert Repo.exists?(
               from(entry in Entry,
                 where: like(entry.name, ^"phase79-chromium-wide-contract-%")
               )
             )

      assert Repo.exists?(
               from(entry in Entry,
                 where: like(entry.name, ^"phase79-chromium-wide-isolated-%")
               )
             )
    end

    test "fixture state includes Cron, Limiter, Audit, Overview, and clean preview evidence", %{
      secret: secret
    } do
      state =
        "/reset"
        |> post_json(%{"project" => "chromium-wide", "run" => "domain"}, secret)
        |> decode()

      assert state["counts"] == %{
               "auditFiltered" => 45,
               "auditNewerUnrelated" => 21,
               "cronEntries" => 3,
               "limiterResources" => 2,
               "overviewActive" => 1,
               "overviewResolved" => 1
             }

      assert Repo.get_by!(Entry, name: state["cron"]["firstEntry"]).paused_at == nil
      refute is_nil(Repo.get_by!(Entry, name: state["cron"]["pausedEntry"]).paused_at)
      assert Repo.get_by!(Resource, name: state["limiters"]["blockedResource"])
      assert Repo.get_by!(Explain, scope_id: state["limiters"]["blockedResource"])

      assert Repo.exists?(
               from(fact in LimiterHistoryFact,
                 where: fact.resource_name == ^state["limiters"]["blockedResource"]
               )
             )

      assert Repo.aggregate(
               from(incident in Incident,
                 where: incident.incident_fingerprint == ^"phase79:chromium-wide:domain:active"
               ),
               :count
             ) == 1

      assert Repo.aggregate(
               from(preview in RepairPreview,
                 where:
                   preview.target_id ==
                     ^Repo.get_by!(Entry, name: state["cron"]["recoveryEntry"]).id
               ),
               :count
             ) == 1
    end

    test "actor and recovery actions are authenticated and scoped to one fixture run", %{
      secret: secret
    } do
      current = reset("chromium-wide", "recovery", secret)
      other = reset("chromium-tablet", "other", secret)

      operator =
        post_json("/actor", actor_params("chromium-wide", "recovery", "operator"), secret)

      read_only =
        post_json("/actor", actor_params("chromium-wide", "recovery", "read_only"), secret)

      assert decode(operator) == %{"actor" => "operator", "state" => "authenticated"}
      assert decode(read_only) == %{"actor" => "read_only", "state" => "authenticated"}
      assert operator.resp_cookies["_phoenix_host_key"]
      assert read_only.resp_cookies["_phoenix_host_key"]

      other_entry = Repo.get_by!(Entry, name: other["cron"]["recoveryEntry"])
      other_preview = Repo.get_by!(RepairPreview, target_id: other_entry.id)

      for recovery <- ~w(expired drifted consumed skipped partial) do
        response =
          post_json(
            "/recovery",
            %{"entry" => current["cron"]["recoveryEntry"], "recovery" => recovery},
            secret
          )

        assert response.status == 200
        assert decode(response) == %{"recovery" => recovery, "state" => "prepared"}
        assert Repo.get!(RepairPreview, other_preview.id).status == other_preview.status
      end
    end

    test "missing and wrong secrets receive the same empty 404 before parameter validation", %{
      secret: secret
    } do
      missing = post_json("/reset", %{}, nil)
      wrong = post_json("/reset", %{}, secret <> "-wrong")

      assert {missing.status, missing.resp_body} == {404, ""}
      assert {wrong.status, wrong.resp_body} == {404, ""}
    end

    test "router exposes exactly the three explicit POST controller mappings" do
      source = File.read!("lib/phoenix_host_web/router.ex")

      assert source =~ ~s(post "/reset", Phase79BrowserFixturesController, :reset)
      assert source =~ ~s(post "/actor", Phase79BrowserFixturesController, :actor)
      assert source =~ ~s(post "/recovery", Phase79BrowserFixturesController, :recovery)
      refute source =~ ~s(get "/__phase79_browser_fixtures__)
      refute source =~ "resources \"/__phase79_browser_fixtures__"
      refute source =~ "forward \"/__phase79_browser_fixtures__"
    end

    defp reset(project, run, secret) do
      "/reset"
      |> post_json(%{"project" => project, "run" => run}, secret)
      |> decode()
    end

    defp actor_params(project, run, actor) do
      %{"project" => project, "run" => run, "actor" => actor}
    end

    defp assert_public_reset!(state, project, run) do
      assert state["project"] == project
      assert state["run"] == run
      assert state["actors"] == ["operator", "read_only"]
      assert state["audit"]["boundaryPage"] == 3
      assert is_binary(state["audit"]["firstEvent"])
      assert is_binary(state["audit"]["secondEvent"])
      assert length(state["confidentialitySentinels"]) == 2

      forbidden = ~w(secret preview_token plan_hash metadata error token hash credential)
      keys = state |> all_keys() |> Enum.map(&String.downcase/1)
      refute Enum.any?(keys, fn key -> Enum.any?(forbidden, &String.contains?(key, &1)) end)
    end

    defp all_keys(map) when is_map(map) do
      Enum.flat_map(map, fn {key, value} -> [to_string(key) | all_keys(value)] end)
    end

    defp all_keys(list) when is_list(list), do: Enum.flat_map(list, &all_keys/1)
    defp all_keys(_value), do: []
  else
    @tag :route_off
    test "fixture modules and routes are absent when the compile-time flag is off" do
      refute Code.ensure_loaded?(PhoenixHostWeb.Phase79BrowserFixtures)
      refute Code.ensure_loaded?(PhoenixHostWeb.Phase79BrowserFixturesController)

      response = post_json("/reset", %{}, nil)
      assert response.status == 404
      assert response.resp_body == ""
    end
  end

  defp post_json(action, params, secret) do
    conn = conn(:post, "/__phase79_browser_fixtures__#{action}", Jason.encode!(params))
    conn = put_req_header(conn, "content-type", "application/json")
    conn = if secret, do: put_req_header(conn, "x-phase79-fixture-secret", secret), else: conn
    @endpoint.call(conn, @endpoint.init([]))
  end

  defp decode(conn), do: Jason.decode!(conn.resp_body)
end
