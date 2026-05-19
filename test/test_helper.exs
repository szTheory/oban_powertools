ExUnit.start()

Code.require_file("test/support/migrations/1_phase_2_tables.exs")
Code.require_file("test/support/migrations/2_phase_3_tables.exs")
Code.require_file("test/support/migrations/3_phase_4_tables.exs")

{:ok, _} = ObanPowertools.TestRepo.start_link()

{:ok, _, _} =
  Ecto.Migrator.with_repo(ObanPowertools.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, Application.app_dir(:oban_powertools, "test/support/migrations"), :up,
      all: true
    )

    phase_2_tables? =
      repo
      |> Ecto.Adapters.SQL.query!("SELECT to_regclass('public.oban_powertools_limit_resources')")
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
  end)

config = Application.get_all_env(:oban)
{:ok, _} = Oban.start_link(config)
{:ok, _} = ObanPowertools.TestEndpoint.start_link()

Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, :manual)
