defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsCronEntries do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_cron_entries, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :source, :string, null: false
      add :worker, :string, null: false
      add :queue, :string, null: false, default: "default"
      add :expression, :string, null: false
      add :timezone, :string, null: false, default: "Etc/UTC"
      add :args, :map, null: false, default: %{}
      add :opts, :map, null: false, default: %{}
      add :overlap_policy, :string, null: false, default: "queue_one"
      add :catch_up_policy, :string, null: false, default: "latest"
      add :max_catch_up, :integer, null: false, default: 1
      add :paused_at, :utc_datetime_usec
      add :last_run_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps()
    end

    create unique_index(:oban_powertools_cron_entries, [:name])
    create index(:oban_powertools_cron_entries, [:source])
    create index(:oban_powertools_cron_entries, [:paused_at])
  end
end
