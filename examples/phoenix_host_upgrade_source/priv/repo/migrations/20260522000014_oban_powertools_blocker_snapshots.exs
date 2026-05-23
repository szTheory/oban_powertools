defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsBlockerSnapshots do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_blocker_snapshots, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :job_id, :bigint, null: false
      add :worker, :string, null: false
      add :status, :string, null: false, default: "blocked"
      add :scope_kind, :string, null: false
      add :scope_id, :string, null: false
      add :blocker_codes, {:array, :string}, null: false, default: []
      add :details, :map, null: false, default: %{}
      add :captured_at, :utc_datetime_usec, null: false

      timestamps(updated_at: false)
    end

    create index(:oban_powertools_blocker_snapshots, [:job_id])
    create index(:oban_powertools_blocker_snapshots, [:worker])
    create index(:oban_powertools_blocker_snapshots, [:scope_kind, :scope_id])
  end
end
