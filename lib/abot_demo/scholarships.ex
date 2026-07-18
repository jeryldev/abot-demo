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

  # These compact records are the only scholarship facts sent to the ranking model.
  # Their IDs are validated before a model response can affect the student-facing plan.
  def matching_candidates do
    records()
    |> Enum.reject(&closed_without_next_cycle?/1)
    |> Enum.sort_by(fn record ->
      {record["provider"], record["program_name"], record["location_coverage"]}
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {record, index} ->
      %{
        id: "tracker-#{index}",
        record: record,
        summary: %{
          "candidate_id" => "tracker-#{index}",
          "provider" => record["provider"],
          "program" => record["program_name"],
          "coverage" => record["location_coverage"],
          "target_applicants" => record["target_applicants"],
          "key_eligibility" => record["key_eligibility"],
          "requirements" => record["requirements"],
          "status" => record["status_as_of_2026_07_18"],
          "application_start" => record["application_start"],
          "application_end" => record["application_end"]
        }
      }
    end)
  end

  def recommendations_from_match(student, candidates, %{"recommendations" => rankings})
      when is_list(rankings) do
    candidates_by_id = Map.new(candidates, &{&1.id, &1.record})

    rankings
    |> Enum.reduce({[], MapSet.new()}, fn ranking, {opportunities, seen_ids} ->
      candidate_id = ranking["candidate_id"]

      cond do
        not is_binary(candidate_id) ->
          {opportunities, seen_ids}

        MapSet.member?(seen_ids, candidate_id) ->
          {opportunities, seen_ids}

        record = candidates_by_id[candidate_id] ->
          opportunity =
            to_opportunity(
              record,
              candidate_id,
              length(opportunities) + 1,
              student,
              ranking
            )

          {[opportunity | opportunities], MapSet.put(seen_ids, candidate_id)}

        true ->
          {opportunities, seen_ids}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
    |> case do
      [] -> {:error, :no_valid_recommendations}
      opportunities -> {:ok, opportunities}
    end
  end

  def recommendations_from_match(_student, _candidates, _match), do: {:error, :invalid_match}

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

  defp to_opportunity(record, id, rank, student, match \\ nil) do
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
      fit: match_reason(match) || fit(record, student),
      match_caution: match_caution(match),
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

  defp match_reason(%{"fit_reason" => reason}) when is_binary(reason) and byte_size(reason) > 0,
    do: reason

  defp match_reason(_match), do: nil

  defp match_caution(%{"caution" => caution}) when is_binary(caution) and byte_size(caution) > 0,
    do: caution

  defp match_caution(_match), do: nil

  defp closed_without_next_cycle?(record) do
    status = String.downcase(record["status_as_of_2026_07_18"] || "")
    String.starts_with?(status, "closed") and not String.contains?(status, "2027")
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
