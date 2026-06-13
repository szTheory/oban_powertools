ExUnit.start()

skip_db_boot? = System.get_env("OBAN_POWERTOOLS_SKIP_DB_BOOT") in ["1", "true"]

unless skip_db_boot? do
  Code.require_file("test/support/migrations/0_create_tables.exs")
  Code.require_file("test/support/migrations/1_phase_2_tables.exs")
  Code.require_file("test/support/migrations/2_phase_3_tables.exs")
  Code.require_file("test/support/migrations/3_phase_4_tables.exs")
  Code.require_file("test/support/migrations/4_phase_5_tables.exs")
  Code.require_file("test/support/migrations/5_phase_6_tables.exs")
  Code.require_file("test/support/migrations/6_phase_55_tables.exs")

  {:ok, _} = ObanPowertools.TestRepo.start_link()

  {:ok, _, _} =
    Ecto.Migrator.with_repo(ObanPowertools.TestRepo, fn repo ->
      Ecto.Migrator.run(
        repo,
        Application.app_dir(:oban_powertools, "test/support/migrations"),
        :up,
        all: true
      )

      audit_tables? =
        repo
        |> Ecto.Adapters.SQL.query!("SELECT to_regclass('public.oban_powertools_audit_events')")
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(audit_tables?) do
        Ecto.Migrator.up(repo, 0, ObanPowertools.TestRepo.Migrations.CreateTables, log: false)
      end

      Ecto.Adapters.SQL.query!(
        repo,
        """
        ALTER TABLE oban_powertools_audit_events
        ADD COLUMN IF NOT EXISTS command_key text,
        ADD COLUMN IF NOT EXISTS event_type text,
        ADD COLUMN IF NOT EXISTS resource_type text,
        ADD COLUMN IF NOT EXISTS resource_id text
        """
      )

      Ecto.Adapters.SQL.query!(
        repo,
        """
        CREATE INDEX IF NOT EXISTS oban_powertools_audit_events_event_type_index
        ON oban_powertools_audit_events (event_type)
        """
      )

      Ecto.Adapters.SQL.query!(
        repo,
        """
        CREATE INDEX IF NOT EXISTS oban_powertools_audit_events_resource_identity_index
        ON oban_powertools_audit_events (resource_type, resource_id)
        """
      )

      phase_2_tables? =
        repo
        |> Ecto.Adapters.SQL.query!(
          "SELECT to_regclass('public.oban_powertools_limit_resources')"
        )
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(phase_2_tables?) do
        Ecto.Migrator.up(repo, 1, ObanPowertools.TestRepo.Migrations.Phase2Tables, log: false)
      end

      phase_3_tables? =
        repo
        |> Ecto.Adapters.SQL.query!("SELECT to_regclass('public.oban_powertools_workflows')")
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(phase_3_tables?) do
        Ecto.Migrator.up(repo, 2, ObanPowertools.TestRepo.Migrations.Phase3Tables, log: false)
      end

      phase_4_tables? =
        repo
        |> Ecto.Adapters.SQL.query!("SELECT to_regclass('public.oban_powertools_heartbeats')")
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(phase_4_tables?) do
        Ecto.Migrator.up(repo, 3, ObanPowertools.TestRepo.Migrations.Phase4Tables, log: false)
      end

      phase_5_tables? =
        repo
        |> Ecto.Adapters.SQL.query!(
          "SELECT to_regclass('public.oban_powertools_workflow_command_attempts')"
        )
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(phase_5_tables?) do
        Ecto.Migrator.up(repo, 4, ObanPowertools.TestRepo.Migrations.Phase5Tables, log: false)
      end

      phase_6_tables? =
        repo
        |> Ecto.Adapters.SQL.query!(
          "SELECT to_regclass('public.oban_powertools_workflow_recovery_sessions')"
        )
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(phase_6_tables?) do
        Ecto.Migrator.up(repo, 5, ObanPowertools.TestRepo.Migrations.Phase6Tables, log: false)
      end

      phase_55_tables? =
        repo
        |> Ecto.Adapters.SQL.query!("SELECT to_regclass('public.oban_powertools_job_records')")
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(phase_55_tables?) do
        Ecto.Migrator.up(repo, 6, ObanPowertools.TestRepo.Migrations.Phase55Tables, log: false)
      end

      limiter_history_tables? =
        repo
        |> Ecto.Adapters.SQL.query!(
          "SELECT to_regclass('public.oban_powertools_limiter_history_facts')"
        )
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(limiter_history_tables?) do
        Ecto.Adapters.SQL.query!(
          repo,
          """
          CREATE TABLE oban_powertools_limiter_history_facts (
            id uuid PRIMARY KEY,
            resource_name text NOT NULL,
            partition_key text NOT NULL DEFAULT '__global__',
            event_type text NOT NULL,
            cause_kind text,
            occurred_at timestamp(6) without time zone NOT NULL,
            eligible_at timestamp(6) without time zone,
            metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
            inserted_at timestamp(0) without time zone NOT NULL,
            updated_at timestamp(0) without time zone
          )
          """
        )

        Ecto.Adapters.SQL.query!(
          repo,
          """
          CREATE INDEX oban_powertools_limiter_history_facts_resource_name_occurred_at_index
          ON oban_powertools_limiter_history_facts (resource_name, occurred_at)
          """
        )

        Ecto.Adapters.SQL.query!(
          repo,
          """
          CREATE INDEX oban_powertools_limiter_history_facts_event_type_index
          ON oban_powertools_limiter_history_facts (event_type)
          """
        )
      end

      cron_coverage_tables? =
        repo
        |> Ecto.Adapters.SQL.query!("SELECT to_regclass('public.oban_powertools_cron_coverages')")
        |> Map.fetch!(:rows)
        |> List.first()
        |> List.first()

      if is_nil(cron_coverage_tables?) do
        Ecto.Adapters.SQL.query!(
          repo,
          """
          CREATE TABLE oban_powertools_cron_coverages (
            id uuid PRIMARY KEY,
            entry_id uuid NOT NULL REFERENCES oban_powertools_cron_entries(id) ON DELETE CASCADE,
            slot_at timestamp(6) without time zone NOT NULL,
            status text NOT NULL DEFAULT 'healthy',
            metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
            inserted_at timestamp(0) without time zone NOT NULL,
            updated_at timestamp(0) without time zone
          )
          """
        )

        Ecto.Adapters.SQL.query!(
          repo,
          """
          CREATE UNIQUE INDEX oban_powertools_cron_coverages_entry_id_slot_at_index
          ON oban_powertools_cron_coverages (entry_id, slot_at)
          """
        )

        Ecto.Adapters.SQL.query!(
          repo,
          """
          CREATE INDEX oban_powertools_cron_coverages_status_index
          ON oban_powertools_cron_coverages (status)
          """
        )
      end
    end)

  config = Application.get_all_env(:oban)
  {:ok, _} = Oban.start_link(config)
  {:ok, _} = ObanPowertools.TestEndpoint.start_link()

  Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, :manual)
end
