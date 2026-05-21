defmodule ObanPowertools.ApplicationTest do
  use ExUnit.Case

  alias ObanPowertools.Lifeline.HeartbeatWriter

  @repo_error "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo before using persistence-backed features."

  test "configured runtime includes heartbeat writer in the application supervisor" do
    child_ids =
      ObanPowertools.Supervisor
      |> Supervisor.which_children()
      |> Enum.map(fn {id, _pid, _type, _modules} -> id end)

    assert HeartbeatWriter in child_ids
  end

  test "application start succeeds without repo wiring and omits heartbeat writer" do
    original_repo = Application.get_env(:oban_powertools, :repo)

    on_exit(fn ->
      if original_repo do
        Application.put_env(:oban_powertools, :repo, original_repo)
      else
        Application.delete_env(:oban_powertools, :repo)
      end

      Application.start(:oban_powertools)
    end)

    :ok = Application.stop(:oban_powertools)
    Application.delete_env(:oban_powertools, :repo)

    assert {:ok, pid} = ObanPowertools.Application.start(:normal, [])

    child_ids =
      pid
      |> Supervisor.which_children()
      |> Enum.map(fn {id, _child, _type, _modules} -> id end)

    refute HeartbeatWriter in child_ids

    assert :ok = Supervisor.stop(pid)
  end

  test "direct heartbeat startup without repo wiring raises the shared setup error" do
    original_repo = Application.get_env(:oban_powertools, :repo)

    on_exit(fn ->
      if original_repo do
        Application.put_env(:oban_powertools, :repo, original_repo)
      else
        Application.delete_env(:oban_powertools, :repo)
      end
    end)

    Application.delete_env(:oban_powertools, :repo)

    assert_raise RuntimeError, @repo_error, fn ->
      HeartbeatWriter.init(interval_ms: 5, provider: fn -> [] end)
    end
  end
end
