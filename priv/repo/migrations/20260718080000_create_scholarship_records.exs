defmodule AbotDemo.Repo.Migrations.CreateScholarshipRecords do
  use Ecto.Migration

  def change do
    create table(:scholarship_records) do
      add :external_id, :string, null: false
      add :program_name, :string, null: false
      add :provider, :string, null: false
      add :status, :string, null: false
      add :source_url, :text, null: false
      add :last_verified, :date
      add :raw_data, :map, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:scholarship_records, [:external_id])
    create index(:scholarship_records, [:provider])
    create index(:scholarship_records, [:status])
  end
end
