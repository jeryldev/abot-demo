alias AbotDemo.Repo
alias AbotDemo.Tracker.ScholarshipRecord

dataset_path = Path.expand("../data/verified_scholarships.json", __DIR__)
records = dataset_path |> File.read!() |> Jason.decode!() |> Map.fetch!("records")
now = DateTime.utc_now() |> DateTime.truncate(:second)

rows =
  records
  |> Enum.with_index(1)
  |> Enum.map(fn {record, index} ->
    %{
      external_id: "verified-tracker-#{index}",
      provider: record["provider"],
      program_name: record["program_name"],
      status: record["status_as_of_2026_07_18"],
      source_url: record["source_url"],
      last_verified: Date.from_iso8601!(record["last_verified"]),
      raw_data: record,
      inserted_at: now,
      updated_at: now
    }
  end)

{count, _} =
  Repo.insert_all(ScholarshipRecord, rows,
    conflict_target: :external_id,
    on_conflict:
      {:replace,
       [:provider, :program_name, :status, :source_url, :last_verified, :raw_data, :updated_at]}
  )

IO.puts("Seeded #{count} verified scholarship records.")
