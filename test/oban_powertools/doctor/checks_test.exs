defmodule ObanPowertools.Doctor.ChecksTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.Doctor.Checks
  alias ObanPowertools.TestRepo

  # Helper to create a direct Postgrex connection for DDL in on_exit callbacks.
  # on_exit runs after sandbox teardown, so we need a raw connection (no pool/sandbox).
  defp direct_postgrex_query!(sql) do
    db_config =
      Application.get_env(:oban_powertools, ObanPowertools.TestRepo)
      |> Keyword.delete(:pool)
      |> Keyword.put(:pool_size, 1)

    {:ok, conn} = Postgrex.start_link(db_config)
    Postgrex.query!(conn, sql, [])
    GenServer.stop(conn)
  end

  describe "index_validity/2" do
    test "returns [] on a clean DB with no INVALID indexes" do
      result = Checks.index_validity(TestRepo, "public")
      assert result == []
    end

    test "findings_for_index_rows/1 produces an :error finding for a row with indisvalid=false" do
      rows = [["oban_jobs_args_index", false, true]]
      findings = Checks.findings_for_index_rows(rows, "public")

      assert length(findings) == 1
      [finding] = findings
      assert finding.check == :index_validity
      assert finding.severity == :error
      assert finding.message =~ "INVALID index"
      assert finding.message =~ "oban_jobs_args_index"
      assert finding.remediation =~ "REINDEX INDEX CONCURRENTLY"
    end

    test "findings_for_index_rows/1 produces an :error finding for a row with indisready=false" do
      rows = [["oban_jobs_meta_index", true, false]]
      findings = Checks.findings_for_index_rows(rows, "public")

      assert length(findings) == 1
      [finding] = findings
      assert finding.severity == :error
    end

    test "prefix is bound as $1 — bogus prefix returns [] not an error" do
      result = Checks.index_validity(TestRepo, "nonexistent_schema_xyz")
      assert result == []
    end
  end

  describe "missing_indexes/2" do
    test "returns [] when all 5 expected v14 indexes are present" do
      result = Checks.missing_indexes(TestRepo, "public")
      assert result == []
    end

    test "returns an :error finding naming the dropped index" do
      Ecto.Adapters.SQL.query!(
        TestRepo,
        "DROP INDEX IF EXISTS public.oban_jobs_args_index"
      )

      # Restore the index via direct Postgrex connection (on_exit runs after sandbox teardown).
      # CONCURRENTLY cannot run inside a transaction; use plain CREATE INDEX for tests.
      on_exit(fn ->
        direct_postgrex_query!(
          "CREATE INDEX IF NOT EXISTS oban_jobs_args_index ON public.oban_jobs USING GIN (args)"
        )
      end)

      result = Checks.missing_indexes(TestRepo, "public")
      assert length(result) >= 1

      assert Enum.any?(result, fn f ->
               f.check == :missing_indexes and
                 f.severity == :error and
                 f.message =~ "oban_jobs_args_index"
             end)
    end
  end

  describe "oban_migration_version/2" do
    test "returns [] on the migrated test DB (db_version == current_version)" do
      result = Checks.oban_migration_version(TestRepo, "public")
      assert result == []
    end

    test "returns an :error finding for a non-existent prefix (oban_jobs absent)" do
      result = Checks.oban_migration_version(TestRepo, "nonexistent_schema_xyz")
      assert length(result) == 1
      [finding] = result
      assert finding.check == :oban_migration_version
      assert finding.severity == :error

      assert finding.message =~ "absent" or finding.message =~ "not migrated" or
               finding.message =~ "v0"
    end
  end

  describe "powertools_tables/1" do
    test "returns [] on the migrated test DB (all 4 groups present)" do
      result = Checks.powertools_tables(TestRepo)
      assert result == []
    end

    test "queries public schema regardless of prefix — the function takes repo only" do
      # The function signature is powertools_tables(repo) — no prefix argument.
      # Verify it compiles and runs correctly.
      result = Checks.powertools_tables(TestRepo)
      assert is_list(result)
    end
  end

  describe "uniqueness_timeout_risk/3" do
    test "returns [] when GIN indexes are present and job count is below threshold" do
      result = Checks.uniqueness_timeout_risk(TestRepo, "public", [])
      assert result == []
    end

    test "with strict: true, a risk finding (if any) has :error severity" do
      # Drop args GIN index to trigger a risk finding
      Ecto.Adapters.SQL.query!(
        TestRepo,
        "DROP INDEX IF EXISTS public.oban_jobs_args_index"
      )

      # Restore index via direct Postgrex connection (on_exit runs after sandbox teardown).
      on_exit(fn ->
        direct_postgrex_query!(
          "CREATE INDEX IF NOT EXISTS oban_jobs_args_index ON public.oban_jobs USING GIN (args)"
        )
      end)

      result = Checks.uniqueness_timeout_risk(TestRepo, "public", strict: true)
      assert Enum.any?(result, fn f -> f.severity == :error end)
    end

    test "with strict: false (default), a risk finding from missing GIN index has :warning severity" do
      Ecto.Adapters.SQL.query!(
        TestRepo,
        "DROP INDEX IF EXISTS public.oban_jobs_args_index"
      )

      # Restore index via direct Postgrex connection (on_exit runs after sandbox teardown).
      on_exit(fn ->
        direct_postgrex_query!(
          "CREATE INDEX IF NOT EXISTS oban_jobs_args_index ON public.oban_jobs USING GIN (args)"
        )
      end)

      result = Checks.uniqueness_timeout_risk(TestRepo, "public", strict: false)
      assert Enum.any?(result, fn f -> f.severity == :warning end)
    end
  end

  describe "expired_deadline_jobs/2" do
    test "returns warning findings for expired retryable jobs" do
      past_iso =
        DateTime.utc_now()
        |> DateTime.add(-60, :second)
        |> DateTime.to_iso8601()

      job = insert_oban_job!(%{"__deadline_at__" => past_iso}, state: "retryable")

      assert [
               %{
                 check: :expired_deadline_jobs,
                 severity: :warning,
                 message: message,
                 remediation: remediation
               }
             ] = Checks.expired_deadline_jobs(TestRepo, "public")

      assert message =~ "Expired deadline"
      assert message =~ "retryable job #{job.id}"
      assert message =~ "Example.Worker"
      assert remediation =~ "retry"
    end

    test "ignores future retryable deadlines" do
      future_iso =
        DateTime.utc_now()
        |> DateTime.add(60, :second)
        |> DateTime.to_iso8601()

      insert_oban_job!(%{"__deadline_at__" => future_iso}, state: "retryable")

      assert [] = Checks.expired_deadline_jobs(TestRepo, "public")
    end

    test "ignores expired deadlines in non-retryable states" do
      past_iso =
        DateTime.utc_now()
        |> DateTime.add(-60, :second)
        |> DateTime.to_iso8601()

      insert_oban_job!(%{"__deadline_at__" => past_iso}, state: "available")

      assert [] = Checks.expired_deadline_jobs(TestRepo, "public")
    end

    test "ignores malformed deadline metadata without crashing" do
      insert_oban_job!(%{"__deadline_at__" => "not-a-date"}, state: "retryable")

      assert [] = Checks.expired_deadline_jobs(TestRepo, "public")
    end

    test "invalid prefix returns a bounded error finding before interpolation" do
      assert [
               %{
                 check: :expired_deadline_jobs,
                 severity: :error,
                 message: message
               }
             ] = Checks.expired_deadline_jobs(TestRepo, "bad-prefix;drop")

      assert message =~ "not a valid identifier"
    end
  end

  defp insert_oban_job!(meta, opts) do
    state = Keyword.fetch!(opts, :state)

    %{}
    |> Oban.Job.new(worker: "Example.Worker", queue: :default, meta: meta)
    |> Ecto.Changeset.change(state: state)
    |> TestRepo.insert!()
  end
end
