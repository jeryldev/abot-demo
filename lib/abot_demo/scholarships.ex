defmodule AbotDemo.Scholarships do
  @moduledoc false

  alias AbotDemo.Repo
  alias AbotDemo.Tracker.ScholarshipRecord

  @dataset_path Path.expand("../../priv/data/verified_scholarships.json", __DIR__)
  @dataset @dataset_path |> File.read!() |> Jason.decode!()
  @records @dataset["records"]

  def recommendations(student) do
    records = records()

    [
      {"ched", ched_for(records, student), 1},
      {"dost", dost_for(records), 2},
      {"local", local_for(records, student), 3}
    ]
    |> Enum.map(fn {id, record, rank} -> to_opportunity(record, id, rank, student) end)
  end

  def dataset_metadata do
    Map.take(@dataset, ["source_workbook", "source_sheet", "imported_on"])
  end

  defp ched_for(records, student) do
    regional_open =
      find_record(records, fn record ->
        record["program_name"] == "CHED Merit Scholarship Program (CMSP)" and
          record["status_as_of_2026_07_18"] == "Open" and
          location_matches?(record, student.location)
      end)

    regional_open ||
      find_record(records, fn record ->
        record["provider"] == "CHED" and
          record["program_name"] == "CHED Merit Scholarship Program (CMSP)" and
          String.contains?(record["status_as_of_2026_07_18"], "2027")
      end)
  end

  defp dost_for(records) do
    find_record(records, fn record ->
      record["provider"] == "DOST-SEI" and
        record["program_name"] == "S&T Undergraduate Scholarships" and
        String.contains?(record["status_as_of_2026_07_18"], "2027")
    end)
  end

  defp local_for(records, student) do
    find_record(records, fn record ->
      record["provider"] not in ["CHED", "DOST-SEI"] and
        location_matches?(record, student.location) and
        not String.starts_with?(record["status_as_of_2026_07_18"], "Closed")
    end) ||
      find_record(records, fn record ->
        record["provider"] == "UniFAST / CHED" and
          record["program_name"] == "Tertiary Education Subsidy (TES)"
      end)
  end

  defp records do
    if Application.get_env(:abot_demo, :database_enabled, false) do
      Repo.all(ScholarshipRecord)
      |> Enum.map(& &1.raw_data)
    else
      @records
    end
  end

  defp find_record(records, predicate), do: Enum.find(records, predicate)

  defp location_matches?(record, location) do
    location = String.downcase(location)
    coverage = String.downcase(record["location_coverage"])
    String.contains?(coverage, location)
  end

  defp to_opportunity(record, id, rank, student) do
    status = record["status_as_of_2026_07_18"]
    status_group = status_group(status)

    %{
      id: id,
      rank: Integer.to_string(rank),
      program: record["program_name"],
      full_name: record["program_name"],
      kind: "Official scholarship",
      provider: record["provider"],
      chip: chip(status_group, record["application_end"]),
      chip_style: chip_style(status_group),
      status: status,
      status_group: status_group,
      verification: "official source tracker",
      checked: format_date(record["last_verified"]),
      source: record["source_url"],
      fit: fit(record, student),
      blocker: record["key_eligibility"],
      detail_blockers: [
        record["key_eligibility"],
        record["requirements"],
        record["how_to_apply"]
      ],
      requirements: record["requirements"],
      how_to_apply: record["how_to_apply"],
      note: record["notes_data_quality"],
      action: action(status_group),
      deadline: record["application_end"]
    }
  end

  defp fit(record, student) do
    "For #{student.course}: #{record["target_applicants"]} Check every provider criterion before applying."
  end

  defp status_group(status) do
    normalized = String.downcase(status)

    cond do
      String.starts_with?(normalized, "open") -> :open
      String.contains?(normalized, "2027") -> :next_cycle
      true -> :verify
    end
  end

  defp chip(:open, deadline),
    do: if(deadline, do: "Open · #{compact_date(deadline)}", else: "Open now")

  defp chip(:next_cycle, _deadline), do: "Next cycle"
  defp chip(:verify, _deadline), do: "Confirm window"

  defp chip_style(:open), do: "chip chip-green"
  defp chip_style(:next_cycle), do: "chip chip-blue"
  defp chip_style(:verify), do: "chip chip-amber"

  defp action(:open), do: "Prepare application"
  defp action(:next_cycle), do: "Plan for next cycle"
  defp action(:verify), do: "Check official window"

  defp format_date(nil), do: "Not dated"

  defp format_date(date), do: Calendar.strftime(Date.from_iso8601!(date), "%d %b %Y")

  defp compact_date(date), do: Calendar.strftime(Date.from_iso8601!(date), "%d %b")
end
