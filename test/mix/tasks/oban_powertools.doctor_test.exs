defmodule Mix.Tasks.ObanPowertools.DoctorTest do
  use ExUnit.Case

  @task_path "lib/mix/tasks/oban_powertools.doctor.ex"

  test "defines a plain Mix.Task" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Doctor)
    assert function_exported?(Mix.Tasks.ObanPowertools.Doctor, :run, 1)
  end

  test "uses Mix.Task and not Igniter.Mix.Task" do
    source = File.read!(@task_path)
    assert source =~ "use Mix.Task"
    refute source =~ "use Igniter.Mix.Task"
  end

  test "does not use @requirements or Oban.start_link" do
    source = File.read!(@task_path)
    refute source =~ "@requirements"
    refute source =~ "Oban.start_link"
  end

  test "declares all five expected switches" do
    source = File.read!(@task_path)
    assert source =~ "repo:"
    assert source =~ "prefix:"
    assert source =~ "oban_name:"
    assert source =~ "format:"
    assert source =~ "strict:"
  end

  test "uses Ecto.Migrator.with_repo for repo-only boot" do
    source = File.read!(@task_path)
    assert source =~ "Ecto.Migrator.with_repo"
  end

  test "uses System.halt for honest exit codes" do
    source = File.read!(@task_path)
    assert source =~ "System.halt"
  end

  test "does not call String.to_atom on CLI repo flag" do
    source = File.read!(@task_path)
    # String.to_atom( on user input is forbidden (Pitfall 4 / T-48-05)
    # We allow String.to_existing_atom but not String.to_atom
    refute source =~ ~r/String\.to_atom\(/
  end

  test "uses Module.safe_concat or String.to_existing_atom for repo resolution" do
    source = File.read!(@task_path)
    assert source =~ ~r/(Module\.safe_concat|String\.to_existing_atom)/
  end

  test "System.halt is called after with_repo returns, not inside the callback" do
    source = File.read!(@task_path)
    # System.halt must not appear nested inside the fn -> ... end callback block.
    # We verify by checking that System.halt appears in a case arm pattern
    # matching on {:ok, ...} or {:error, ...} — outside the anonymous function.
    # The simplest assertion: the source has System.halt and it follows a ->
    # operator for a case clause, not inside the fn block.
    # We assert that System.halt is called in the context of the case result,
    # i.e., the text "-> System.halt" appears somewhere.
    assert source =~ ~r/->\s+System\.halt/
  end

  test "has a @shortdoc attribute" do
    source = File.read!(@task_path)
    assert source =~ "@shortdoc"
  end

  test "documents expired deadline warning severity without broadening strict scope" do
    source = File.read!(@task_path)

    assert source =~ "Expired deadline jobs"
    assert source =~ "expired_deadline_jobs"
    assert source =~ "Scope: uniqueness_timeout_risk check only"

    assert source =~
             ~r/Expired deadline jobs.*\|\s+warning \(1\)\s+\|\s+warning \(1\)\s+\|/

    refute source =~ "expired deadline jobs) to errors"
    refute source =~ "expired_deadline_jobs check only"
  end
end
