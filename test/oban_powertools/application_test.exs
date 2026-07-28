defmodule ObanPowertools.ApplicationTest do
  use ExUnit.Case

  alias ObanPowertools.Lifeline.HeartbeatWriter

  @repo_error "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo before using persistence-backed features."
  @bulk_limit_error "Oban Powertools :jobs_bulk_target_limit must be an integer from 1 through 1000"

  test "configured runtime includes heartbeat writer in the application supervisor" do
    children = Supervisor.which_children(ObanPowertools.Supervisor)
    child_ids = Enum.map(children, fn {id, _pid, _type, _modules} -> id end)

    assert HeartbeatWriter in child_ids
    assert ObanPowertools.Jobs.TaskSupervisor in child_ids
    assert Enum.count(child_ids, &(&1 == ObanPowertools.Jobs.TaskSupervisor)) == 1

    task_supervisor = Process.whereis(ObanPowertools.Jobs.TaskSupervisor)

    assert is_pid(task_supervisor)

    assert Enum.any?(children, fn
             {ObanPowertools.Jobs.TaskSupervisor, ^task_supervisor, :supervisor,
              [Task.Supervisor]} ->
               true

             _child ->
               false
           end)
  end

  test "application start succeeds without repo wiring and omits heartbeat writer" do
    original_repo = Application.get_env(:oban_powertools, :repo)
    original_limit = Application.fetch_env(:oban_powertools, :jobs_bulk_target_limit)

    on_exit(fn ->
      if original_repo do
        Application.put_env(:oban_powertools, :repo, original_repo)
      else
        Application.delete_env(:oban_powertools, :repo)
      end

      restore_application_env(:jobs_bulk_target_limit, original_limit)
      ensure_application_started()
    end)

    stop_application()
    Application.delete_env(:oban_powertools, :repo)
    Application.put_env(:oban_powertools, :jobs_bulk_target_limit, 1000)

    assert {:ok, pid} = ObanPowertools.Application.start(:normal, [])

    children = Supervisor.which_children(pid)
    child_ids = Enum.map(children, fn {id, _child, _type, _modules} -> id end)

    refute HeartbeatWriter in child_ids
    assert ObanPowertools.Jobs.TaskSupervisor in child_ids

    task_supervisor = Process.whereis(ObanPowertools.Jobs.TaskSupervisor)
    assert is_pid(task_supervisor)

    assert Enum.count(children, fn {_id, child, _type, _modules} -> child == task_supervisor end) ==
             1

    assert :ok = Supervisor.stop(pid)
  end

  test "invalid Jobs bulk target config fails startup before the task supervisor starts" do
    original_limit = Application.fetch_env(:oban_powertools, :jobs_bulk_target_limit)

    on_exit(fn ->
      restore_application_env(:jobs_bulk_target_limit, original_limit)
      ensure_application_started()
    end)

    stop_application()
    Application.put_env(:oban_powertools, :jobs_bulk_target_limit, 0)

    assert_raise ArgumentError, ~r/#{Regex.escape(@bulk_limit_error)}/, fn ->
      ObanPowertools.Application.start(:normal, [])
    end

    refute Process.whereis(ObanPowertools.Jobs.TaskSupervisor)
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

  defp restore_application_env(key, {:ok, value}),
    do: Application.put_env(:oban_powertools, key, value)

  defp restore_application_env(key, :error), do: Application.delete_env(:oban_powertools, key)

  defp stop_application do
    _ = Application.stop(:oban_powertools)

    case Process.whereis(ObanPowertools.Supervisor) do
      nil -> :ok
      pid -> Supervisor.stop(pid)
    end
  end

  defp ensure_application_started do
    case Application.start(:oban_powertools) do
      :ok -> :ok
      {:error, {:already_started, :oban_powertools}} -> :ok
    end
  end
end
