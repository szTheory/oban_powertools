ExUnit.start()

skip_db_boot? = System.get_env("OBAN_POWERTOOLS_SKIP_DB_BOOT") in ["1", "true"]

unless skip_db_boot? do
  Code.require_file("test/support/migrations/0_create_tables.exs")
  Code.require_file("test/support/migrations/1_phase_2_tables.exs")
  Code.require_file("test/support/migrations/2_phase_3_tables.exs")
  Code.require_file("test/support/migrations/3_phase_4_tables.exs")
  Code.require_file("test/support/migrations/4_phase_5_tables.exs")
  Code.require_file("test/support/migrations/5_phase_6_tables.exs")

  {:ok, _} = ObanPowertools.TestRepo.start_link()

  {:ok, _, _} =
    Ecto.Migrator.with_repo(ObanPowertools.TestRepo, fn repo ->
      Ecto.Migrator.run(
        repo,
        Application.app_dir(:oban_powertools, "test/support/migrations"),
        :up, all: true)

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
    end)

  config = Application.get_all_env(:oban)
  {:ok, _} = Oban.start_link(config)
  {:ok, _} = ObanPowertools.TestEndpoint.start_link()

  Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, :manual)
end
