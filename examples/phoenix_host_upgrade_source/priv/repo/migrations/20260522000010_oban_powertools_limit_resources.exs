defmodule PhoenixHost.Repo.Migrations.ObanPowertoolsLimitResources do
  use Ecto.Migration

  def change do
    create table(:oban_powertools_limit_resources, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:name, :string, null: false)
      add(:scope_kind, :string, null: false)
      add(:algorithm, :string, null: false)
      add(:bucket_span_ms, :bigint, null: false)
      add(:bucket_capacity, :integer, null: false)
      add(:default_weight, :integer, null: false, default: 1)
      add(:partition_strategy, :string, null: false, default: "global")
      add(:partition_config, :map, null: false, default: %{})
      add(:cooldown_enabled, :boolean, null: false, default: true)
      add(:metadata, :map, null: false, default: %{})

      timestamps()
    end

    create(unique_index(:oban_powertools_limit_resources, [:name]))
    create(index(:oban_powertools_limit_resources, [:scope_kind]))
    create(index(:oban_powertools_limit_resources, [:algorithm]))
  end
end
