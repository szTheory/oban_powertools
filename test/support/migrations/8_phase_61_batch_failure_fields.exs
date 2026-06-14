defmodule ObanPowertools.TestRepo.Migrations.Phase61BatchFailureFields do
  use Ecto.Migration

  def change do
    alter table(:oban_powertools_batches) do
      add(:name, :string)
      add(:inserted_count, :integer, null: false, default: 0)
      add(:insert_chunk_count, :integer, null: false, default: 0)
      add(:insert_failed_chunk, :integer)
      add(:insert_failure, :map, null: false, default: %{})
      add(:insert_failed_at, :utc_datetime_usec)
    end

    create(index(:oban_powertools_batches, [:status]))
    create(index(:oban_powertools_batches, [:name]))
  end
end
