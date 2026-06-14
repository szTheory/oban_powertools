defmodule ObanPowertools.Doctor.Checks do
  @moduledoc false

  alias ObanPowertools.Doctor.Finding

  # Expected Oban v14 indexes on oban_jobs (per migration v01-v14 exhaustive trace)
  @expected_indexes [
    "oban_jobs_state_queue_priority_scheduled_at_id_index",
    "oban_jobs_args_index",
    "oban_jobs_meta_index",
    "oban_jobs_state_cancelled_at_index",
    "oban_jobs_state_discarded_at_index"
  ]

  # GIN indexes specifically needed for uniqueness-timeout performance
  @gin_indexes ["oban_jobs_args_index", "oban_jobs_meta_index"]

  # Eligible job states for uniqueness-timeout risk threshold check
  @eligible_states ["available", "scheduled", "retryable", "executing"]

  # Threshold for eligible job count — above this, uniqueness-timeout risk is flagged
  @uniqueness_backlog_threshold 50_000

  # Powertools table manifest grouped by migration set (D-12)
  # Source: lib/mix/tasks/oban_powertools.install.ex migration functions (authoritative)
  @powertools_manifest %{
    "foundation" => [
      "oban_powertools_audit_events",
      "oban_powertools_idempotency_receipts",
      "oban_powertools_batches",
      "oban_powertools_batch_jobs"
    ],
    "smart-engine" => [
      "oban_powertools_limit_resources",
      "oban_powertools_limit_states",
      "oban_powertools_cron_entries",
      "oban_powertools_cron_slots",
      "oban_powertools_blocker_snapshots",
      "oban_powertools_limiter_history_facts",
      "oban_powertools_cron_coverages"
    ],
    "workflow" => [
      "oban_powertools_workflows",
      "oban_powertools_workflow_steps",
      "oban_powertools_workflow_edges",
      "oban_powertools_workflow_results",
      "oban_powertools_workflow_awaits",
      "oban_powertools_workflow_signals",
      "oban_powertools_workflow_recovery_sessions",
      "oban_powertools_workflow_recovery_attempts",
      "oban_powertools_callbacks",
      "oban_powertools_workflow_command_attempts"
    ],
    "heartbeat-lifeline" => [
      "oban_powertools_heartbeats",
      "oban_powertools_lifeline_incidents",
      "oban_powertools_repair_previews",
      "oban_powertools_archive_runs",
      "oban_powertools_repair_archives"
    ],
    "output-recording" => [
      "oban_powertools_job_records"
    ]
  }

  # ---
  # Index validity check (OPS-03)
  # ---

  @doc """
  Check for INVALID or not-ready indexes on oban_jobs in the given prefix/schema.
  Returns [] on a clean DB; returns error findings for each INVALID index found.
  On query failure, returns a cannot-run error finding (D-06).
  """
  def index_validity(repo, prefix) do
    sql = """
    SELECT
      i.relname        AS index_name,
      ix.indisvalid    AS is_valid,
      ix.indisready    AS is_ready
    FROM pg_catalog.pg_class     c
    JOIN pg_catalog.pg_namespace n  ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_index     ix ON ix.indrelid = c.oid
    JOIN pg_catalog.pg_class     i  ON i.oid = ix.indexrelid
    WHERE c.relname  = 'oban_jobs'
      AND n.nspname  = $1
      AND NOT ix.indisprimary
    ORDER BY i.relname
    """

    case repo.query(sql, [prefix], log: false) do
      {:ok, %{rows: rows}} ->
        findings_for_index_rows(rows, prefix)

      {:error, reason} ->
        [
          %Finding{
            check: :index_validity,
            severity: :error,
            message: "Cannot query pg_catalog (index_validity): #{inspect(reason)}",
            remediation: "Check DB connectivity and permissions."
          }
        ]
    end
  end

  # ---
  # Missing indexes check (OPS-03)
  # ---

  @doc """
  Check that all 5 expected Oban v14 indexes are present on oban_jobs.
  Returns [] if all expected indexes exist; returns error findings for absent ones.
  """
  def missing_indexes(repo, prefix) do
    sql = """
    SELECT i.relname AS index_name
    FROM pg_catalog.pg_class     c
    JOIN pg_catalog.pg_namespace n  ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_index     ix ON ix.indrelid = c.oid
    JOIN pg_catalog.pg_class     i  ON i.oid = ix.indexrelid
    WHERE c.relname  = 'oban_jobs'
      AND n.nspname  = $1
      AND NOT ix.indisprimary
    ORDER BY i.relname
    """

    case repo.query(sql, [prefix], log: false) do
      {:ok, %{rows: rows}} ->
        present_indexes = Enum.map(rows, fn [name] -> name end)

        @expected_indexes
        |> Enum.reject(&(&1 in present_indexes))
        |> Enum.map(fn name ->
          %Finding{
            check: :missing_indexes,
            severity: :error,
            message: "Expected Oban v14 index '#{name}' is absent from #{prefix}.oban_jobs",
            remediation: "Run `mix ecto.migrate` to apply pending Oban migrations."
          }
        end)

      {:error, reason} ->
        [
          %Finding{
            check: :missing_indexes,
            severity: :error,
            message: "Cannot query pg_catalog (missing_indexes): #{inspect(reason)}",
            remediation: "Check DB connectivity and permissions."
          }
        ]
    end
  end

  # ---
  # Oban migration version check — Lane 1 (OPS-04, D-11)
  # ---

  @doc """
  Compare the DB's Oban migration version (via pg_catalog.obj_description) against
  Oban.Migrations.Postgres.current_version/0. Returns [] if db_version == expected;
  returns error findings for absence or drift.
  """
  def oban_migration_version(repo, prefix) do
    db_version = oban_db_version(repo, prefix)
    expected_version = Oban.Migrations.Postgres.current_version()

    cond do
      is_nil(db_version) ->
        [
          %Finding{
            check: :oban_migration_version,
            severity: :error,
            message:
              "oban_jobs table absent in schema '#{prefix}' (Oban not migrated or wrong prefix)",
            remediation: "Run `mix ecto.migrate` to install Oban migrations."
          }
        ]

      db_version < expected_version ->
        [
          %Finding{
            check: :oban_migration_version,
            severity: :error,
            message:
              "Oban migrations at v#{db_version}, expected v#{expected_version} — migration drift detected",
            remediation: "Run `mix ecto.migrate` to apply pending Oban migrations."
          }
        ]

      db_version > expected_version ->
        [
          %Finding{
            check: :oban_migration_version,
            severity: :warning,
            message:
              "Oban migrations at v#{db_version}, but the installed library expects v#{expected_version} — " <>
                "the database was migrated by a newer Oban than this app runs",
            remediation:
              "Upgrade the `oban` dependency to match the migrated schema (v#{db_version}), " <>
                "or confirm the version skew is intentional."
          }
        ]

      true ->
        []
    end
  end

  @doc """
  Read the Oban migration version recorded in the `oban_jobs` table comment
  (`pg_catalog.obj_description`) for the given prefix/schema. Returns the integer
  version, or `nil` when the table is absent or the comment is missing/unparseable.
  Parses defensively — a non-integer comment (e.g. a DBA note) yields `nil`, never
  a crash (a raised `String.to_integer/1` would take down the whole run/2 pipeline).
  """
  def oban_db_version(repo, prefix) do
    sql = """
    SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
    FROM pg_class
    LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
    WHERE pg_class.relname = 'oban_jobs'
    AND pg_namespace.nspname = $1
    """

    case repo.query(sql, [prefix], log: false) do
      {:ok, %{rows: [[v]]}} when is_binary(v) ->
        case Integer.parse(v) do
          {n, _rest} -> n
          :error -> nil
        end

      _ ->
        nil
    end
  end

  # ---
  # Powertools table presence check — Lane 2 (OPS-04, D-11, D-12)
  # Always queries the 'public' schema (Powertools tables are not Oban-prefixed).
  # ---

  @doc """
  Check presence of all Powertools tables, grouped by migration set.
  Always checks the 'public' schema (D-12 / RESEARCH Open Q3 resolution).
  Returns [] if all 4 groups are fully present; returns named error findings per group
  with any absent tables.
  """
  def powertools_tables(repo) do
    all_tables = Enum.flat_map(@powertools_manifest, fn {_group, tables} -> tables end)

    sql = """
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = ANY($1)
      AND table_type = 'BASE TABLE'
    """

    case repo.query(sql, [all_tables], log: false) do
      {:ok, %{rows: rows}} ->
        present_tables = Enum.map(rows, fn [name] -> name end) |> MapSet.new()

        Enum.flat_map(@powertools_manifest, fn {group, expected_tables} ->
          missing = Enum.reject(expected_tables, &MapSet.member?(present_tables, &1))

          if missing == [] do
            []
          else
            [
              %Finding{
                check: :powertools_tables,
                severity: :error,
                message:
                  "Powertools migration set '#{group}' is missing #{length(missing)} table(s): #{Enum.join(missing, ", ")}",
                remediation:
                  "Run `mix ecto.migrate` to install missing Powertools migrations for the '#{group}' set."
              }
            ]
          end
        end)

      {:error, reason} ->
        [
          %Finding{
            check: :powertools_tables,
            severity: :error,
            message: "Cannot query information_schema (powertools_tables): #{inspect(reason)}",
            remediation: "Check DB connectivity and permissions."
          }
        ]
    end
  end

  # ---
  # Uniqueness-timeout risk check (OPS-04, D-05)
  # ---

  @doc """
  Check for uniqueness-timeout risk: absent GIN indexes on args/meta, or eligible job
  count above threshold (#{@uniqueness_backlog_threshold}).
  Severity: :warning by default, :error when strict: true (D-05).
  """
  def uniqueness_timeout_risk(repo, prefix, opts) do
    strict = Keyword.get(opts, :strict, false)
    severity = if strict, do: :error, else: :warning

    # Sub-check A: GIN index presence (reuse index catalog query)
    gin_findings = check_gin_indexes(repo, prefix, severity)

    # Sub-check B: Eligible job count — identifier-safe via regex validation
    count_findings = check_eligible_job_count(repo, prefix, severity)

    gin_findings ++ count_findings
  end

  @doc """
  Check for retryable Oban jobs whose Powertools deadline metadata is already expired.
  Returns warning findings for parseable expired deadlines and ignores malformed metadata.
  """
  def expired_deadline_jobs(repo, prefix) do
    if valid_identifier?(prefix) do
      deadline_key = ObanPowertools.Worker.Deadlines.meta_key()

      sql = """
      SELECT id, worker, meta->>$1
      FROM #{prefix}.oban_jobs
      WHERE state = $2
        AND meta ? $1
      ORDER BY id
      """

      case repo.query(sql, [deadline_key, "retryable"], log: false) do
        {:ok, %{rows: rows}} ->
          expired_deadline_findings(rows, deadline_key, DateTime.utc_now())

        {:error, reason} ->
          [
            %Finding{
              check: :expired_deadline_jobs,
              severity: :error,
              message:
                "Cannot query expired deadline jobs for #{prefix}.oban_jobs: #{inspect(reason)}",
              remediation: "Check that #{prefix}.oban_jobs exists and the DB is reachable."
            }
          ]
      end
    else
      [
        %Finding{
          check: :expired_deadline_jobs,
          severity: :error,
          message:
            "Cannot check expired deadline jobs: prefix '#{prefix}' is not a valid identifier " <>
              "(must match /^[a-z_][a-z0-9_]*$/)",
          remediation:
            "Use a valid Postgres schema name for --prefix (lowercase letters, digits, underscores)."
        }
      ]
    end
  end

  # ---
  # Public test helper: separately testable finding construction from catalog rows
  # ---

  @doc false
  def findings_for_index_rows(rows, prefix) do
    rows
    |> Enum.filter(fn [_name, valid, ready] -> not valid or not ready end)
    |> Enum.map(fn [name, _valid, _ready] ->
      %Finding{
        check: :index_validity,
        severity: :error,
        message:
          "INVALID index #{name} on #{prefix}.oban_jobs (failed CREATE INDEX CONCURRENTLY)",
        remediation: "Run: REINDEX INDEX CONCURRENTLY #{prefix}.#{name}"
      }
    end)
  end

  # ---
  # Private helpers
  # ---

  defp expired_deadline_findings(rows, deadline_key, now) do
    Enum.flat_map(rows, fn [id, worker, deadline_iso] ->
      case DateTime.from_iso8601(deadline_iso) do
        {:ok, deadline_at, _offset} ->
          if DateTime.compare(deadline_at, now) == :lt do
            [
              %Finding{
                check: :expired_deadline_jobs,
                severity: :warning,
                message:
                  "Expired deadline: retryable job #{id} (#{worker}) has #{deadline_key} #{deadline_iso} in the past",
                remediation:
                  "Inspect the job, then retry, cancel, discard, or re-enqueue it after confirming whether the work should still run."
              }
            ]
          else
            []
          end

        _malformed ->
          []
      end
    end)
  end

  defp check_gin_indexes(repo, prefix, severity) do
    sql = """
    SELECT i.relname AS index_name
    FROM pg_catalog.pg_class     c
    JOIN pg_catalog.pg_namespace n  ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_index     ix ON ix.indrelid = c.oid
    JOIN pg_catalog.pg_class     i  ON i.oid = ix.indexrelid
    WHERE c.relname  = 'oban_jobs'
      AND n.nspname  = $1
      AND NOT ix.indisprimary
    ORDER BY i.relname
    """

    case repo.query(sql, [prefix], log: false) do
      {:ok, %{rows: rows}} ->
        present = Enum.map(rows, fn [name] -> name end)

        @gin_indexes
        |> Enum.reject(&(&1 in present))
        |> Enum.map(fn name ->
          col = if String.contains?(name, "args"), do: "args", else: "meta"

          %Finding{
            check: :uniqueness_timeout_risk,
            severity: severity,
            message:
              "Missing GIN index '#{name}' on #{prefix}.oban_jobs — uniqueness checks will be slow without it",
            remediation:
              "Run `CREATE INDEX CONCURRENTLY #{name} ON #{prefix}.oban_jobs USING GIN (#{col})` " <>
                "— required for unique-check performance (Oban migration v10)."
          }
        end)

      {:error, reason} ->
        # A query error is NOT a clean result — surface it as a cannot-run error so
        # the check never silently reports healthy (honest exit codes, D-06/T-48-07).
        [
          %Finding{
            check: :uniqueness_timeout_risk,
            severity: :error,
            message:
              "Cannot query pg_catalog (uniqueness_timeout_risk GIN check): #{inspect(reason)}",
            remediation: "Check DB connectivity and permissions."
          }
        ]
    end
  end

  # Identifier-safe eligible job count query:
  # The prefix is validated against a safe identifier regex before being used
  # as a schema qualifier in the FROM clause (T-48-01).
  # Pattern: (b) from the plan — validate prefix as /^[a-z_][a-z0-9_]*$/ before quoting.
  defp check_eligible_job_count(repo, prefix, severity) do
    if valid_identifier?(prefix) do
      # Safe to use prefix as identifier because it passed the allowlist regex.
      # The states come from the @eligible_states compile-time constant — no user
      # input in the query string.
      states_list = Enum.map_join(@eligible_states, ",", &"'#{&1}'")

      sql =
        "SELECT count(*) FROM #{prefix}.oban_jobs WHERE state IN (#{states_list})"

      case repo.query(sql, [], log: false) do
        {:ok, %{rows: [[count]]}} when count >= @uniqueness_backlog_threshold ->
          [
            %Finding{
              check: :uniqueness_timeout_risk,
              severity: severity,
              message:
                "Eligible job backlog (#{count}) exceeds threshold (#{@uniqueness_backlog_threshold}) — " <>
                  "high job counts slow Oban unique-job checks",
              remediation:
                "Consider adding the Oban Reindexer plugin or draining the queue backlog " <>
                  "before enabling `unique:` on new workers."
            }
          ]

        {:ok, _} ->
          []

        {:error, reason} ->
          # Don't swallow a query failure as healthy — report cannot-run so the
          # exit code stays honest (D-06/T-48-07).
          [
            %Finding{
              check: :uniqueness_timeout_risk,
              severity: :error,
              message:
                "Cannot query eligible job count for #{prefix}.oban_jobs: #{inspect(reason)}",
              remediation: "Check that #{prefix}.oban_jobs exists and the DB is reachable."
            }
          ]
      end
    else
      [
        %Finding{
          check: :uniqueness_timeout_risk,
          severity: :error,
          message:
            "Cannot check eligible job count: prefix '#{prefix}' is not a valid identifier " <>
              "(must match /^[a-z_][a-z0-9_]*$/)",
          remediation:
            "Use a valid Postgres schema name for --prefix (lowercase letters, digits, underscores)."
        }
      ]
    end
  end

  # Validates that a prefix is a safe Postgres identifier before using it as one.
  # Allows lowercase letters, digits, and underscores, starting with a letter or underscore.
  defp valid_identifier?(prefix) when is_binary(prefix) do
    Regex.match?(~r/^[a-z_][a-z0-9_]*$/, prefix)
  end

  defp valid_identifier?(_), do: false
end
