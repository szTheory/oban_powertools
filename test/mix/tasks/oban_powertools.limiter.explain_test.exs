defmodule Mix.Tasks.ObanPowertools.Limiter.ExplainTest do
  use ExUnit.Case

  @task_path "lib/mix/tasks/oban_powertools.limiter.explain.ex"

  test "defines a plain Mix.Task (OPS-06)" do
    Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Limiter.Explain)
    assert function_exported?(Mix.Tasks.ObanPowertools.Limiter.Explain, :run, 1)
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

  test "uses Ecto.Migrator.with_repo for repo-only boot" do
    source = File.read!(@task_path)
    assert source =~ "Ecto.Migrator.with_repo"
  end

  test "imports Ecto.Query for from/2 macro in resource-primary DB query" do
    source = File.read!(@task_path)
    assert source =~ "import Ecto.Query"
  end

  test "does not call String.to_atom on CLI flags (T-48-05)" do
    source = File.read!(@task_path)
    refute source =~ ~r/String\.to_atom\(/
  end

  test "uses Module.safe_concat for module resolution (T-49-03)" do
    source = File.read!(@task_path)
    assert source =~ "Module.safe_concat"
  end

  test "System.halt is called after with_repo returns, not inside the callback" do
    source = File.read!(@task_path)
    assert source =~ ~r/->\s+System\.halt/
  end

  test "declares required switches" do
    source = File.read!(@task_path)
    assert source =~ "resource:"
    assert source =~ "partition:"
    assert source =~ "worker:"
    assert source =~ "args:"
    assert source =~ "repo:"
    assert source =~ "format:"
  end

  test "has a @shortdoc attribute" do
    source = File.read!(@task_path)
    assert source =~ "@shortdoc"
  end

  test "worker path detects no-limits workers via limit_snapshot, not explain/3 return (CR-01, D-02)" do
    source = File.read!(@task_path)
    # Explain.explain/3 returns a plain runnable map even for a worker with no :limits
    # (its `with {:ok, snapshot}` binds nil and falls through), so the task MUST resolve
    # the worker's declared snapshot itself and exit 2 on nil — otherwise a no-limits
    # worker silently reports runnable with exit 0.
    assert source =~ "limit_snapshot"
    assert source =~ ~r/\{:ok, snapshot\} when not is_nil\(snapshot\)/
    assert source =~ "worker has no limits configured"
  end

  test "sources the rate-limit glossary via ObanPowertools.Limits.Glossary (OPS-08)" do
    source = File.read!(@task_path)
    # D-08: glossary is a single source of truth from Glossary module, referenced in @moduledoc
    assert source =~ "Glossary"
  end

  test "@moduledoc (compiled) contains the rate-limit glossary term token_bucket (OPS-08)" do
    # Verify the compiled moduledoc contains the glossary text (Glossary.text/0 interpolated at compile time)
    {:docs_v1, _, :elixir, _, %{"en" => moduledoc}, _, _} =
      Code.fetch_docs(Mix.Tasks.ObanPowertools.Limiter.Explain)

    assert moduledoc =~ "token_bucket"
    assert moduledoc =~ "bucket_capacity"
    assert moduledoc =~ "bucket_span_ms"
    assert moduledoc =~ "weight_by"
    assert moduledoc =~ "partition_by"
    assert moduledoc =~ "cooldown"
    assert moduledoc =~ "limit_reached"
  end

  test "drives Explain.explain_snapshot/2 for the resource-primary path" do
    source = File.read!(@task_path)
    assert source =~ "Explain.explain_snapshot"
  end

  test "calls Explain.explain( for the worker-secondary path" do
    source = File.read!(@task_path)
    assert source =~ ~r/Explain\.explain\(/
  end
end

defmodule Mix.Tasks.ObanPowertools.Limiter.ExplainIntegrationTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Explain
  alias ObanPowertools.TestRepo

  @resource_name "test-limiter-explain-resource"

  # ---------------------------------------------------------------------------
  # Resource-primary path: existing snapshot
  # ---------------------------------------------------------------------------

  test "resource-primary path: explain_snapshot/2 returns map with status for a snapshot row (OPS-06)" do
    snapshot = insert_explain_snapshot!(@resource_name, "blocked")

    explanation = Explain.explain_snapshot(snapshot, repo: TestRepo)

    assert is_map(explanation)
    assert Map.has_key?(explanation, :status)
    assert Map.has_key?(explanation, :blockers)
    assert Map.has_key?(explanation, :live_now)
  end

  test "resource-primary path: dispatch resolves snapshot and returns 0 (OPS-06)" do
    insert_explain_snapshot!(@resource_name <> "-dispatch", "blocked")

    # ExUnit captures IO; we care about the exit code, not the output
    exit_code =
      Mix.Tasks.ObanPowertools.Limiter.Explain.dispatch(
        TestRepo,
        [resource: @resource_name <> "-dispatch", partition: "__global__"],
        :human
      )

    assert exit_code == 0
  end

  # ---------------------------------------------------------------------------
  # Honest empty state (D-04)
  # ---------------------------------------------------------------------------

  test "resource with no snapshot yields honest empty state: runnable / no limiter state recorded yet (OPS-06, D-04)" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        exit_code =
          Mix.Tasks.ObanPowertools.Limiter.Explain.dispatch(
            TestRepo,
            [resource: "no-such-resource-#{System.unique_integer()}"],
            :human
          )

        send(self(), {:exit_code, exit_code})
      end)

    assert_received {:exit_code, 0}
    assert output =~ "runnable"
    assert output =~ "no limiter state recorded yet"
  end

  test "honest empty state: json format includes status runnable and empty blockers (D-04)" do
    json_output =
      ExUnit.CaptureIO.capture_io(fn ->
        Mix.Tasks.ObanPowertools.Limiter.Explain.dispatch(
          TestRepo,
          [resource: "no-such-resource-json-#{System.unique_integer()}", format: "json"],
          :json
        )
      end)

    assert {:ok, payload} = Jason.decode(json_output)
    assert payload["schema_version"] == 1
    assert payload["status"] == "runnable"
    assert payload["blockers"] == []
    assert payload["message"] =~ "no limiter state recorded yet"
  end

  # ---------------------------------------------------------------------------
  # Unknown worker module -> exit 2 (D-04 / D-02)
  # ---------------------------------------------------------------------------

  test "unknown --worker module string triggers exit-2 cannot-run path with clear error (D-04, OPS-06)" do
    output =
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        exit_code =
          Mix.Tasks.ObanPowertools.Limiter.Explain.dispatch(
            TestRepo,
            [worker: "Does.Not.Exist.Worker"],
            :human
          )

        send(self(), {:exit_code, exit_code})
      end)

    assert_received {:exit_code, 2}
    assert output =~ "unknown --worker module"
    assert output =~ "Does.Not.Exist.Worker"
  end

  # ---------------------------------------------------------------------------
  # JSON format: schema_version: 1
  # ---------------------------------------------------------------------------

  test "json format emits schema_version: 1 top-level (OPS-06)" do
    insert_explain_snapshot!(@resource_name <> "-json", "blocked")

    json_output =
      ExUnit.CaptureIO.capture_io(fn ->
        Mix.Tasks.ObanPowertools.Limiter.Explain.dispatch(
          TestRepo,
          [resource: @resource_name <> "-json"],
          :json
        )
      end)

    assert {:ok, payload} = Jason.decode(json_output)
    assert payload["schema_version"] == 1
    assert Map.has_key?(payload, "resource")
    assert Map.has_key?(payload, "status")
    assert Map.has_key?(payload, "blockers")
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp insert_explain_snapshot!(resource_name, status) do
    {:ok, snapshot} =
      %Explain{}
      |> Explain.changeset(%{
        job_id: 0,
        worker: "Test.Worker",
        status: status,
        scope_kind: "global",
        scope_id: resource_name,
        blocker_codes: ["limit_reached"],
        details: %{"partition_key" => "__global__", "weight" => 1},
        captured_at: DateTime.utc_now()
      })
      |> TestRepo.insert()

    snapshot
  end
end
