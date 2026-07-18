defmodule AbotDemo.Tracker.ScholarshipRecord do
  use Ecto.Schema

  import Ecto.Changeset

  schema "scholarship_records" do
    field(:external_id, :string)
    field(:program_name, :string)
    field(:provider, :string)
    field(:status, :string)
    field(:source_url, :string)
    field(:last_verified, :date)
    field(:raw_data, :map)

    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [
      :external_id,
      :program_name,
      :provider,
      :status,
      :source_url,
      :last_verified,
      :raw_data
    ])
    |> validate_required([
      :external_id,
      :program_name,
      :provider,
      :status,
      :source_url,
      :raw_data
    ])
    |> unique_constraint(:external_id)
  end
end
