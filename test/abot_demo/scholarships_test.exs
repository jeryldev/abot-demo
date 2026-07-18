defmodule AbotDemo.ScholarshipsTest do
  use ExUnit.Case, async: true

  alias AbotDemo.Scholarships

  test "uses the verified tracker instead of a generic open CHED card for Quezon City" do
    recommendations =
      Scholarships.recommendations(%{
        name: "Ana Reyes",
        location: "Quezon City",
        course: "BS Information Technology"
      })

    [ched, dost, qc] = recommendations

    assert ched.status == "2027 announced / verify RO"
    assert ched.source == "https://legacy.ched.gov.ph/merit-scholarship/"
    assert dost.status == "2027 expected / verify"
    assert qc.program == "QC Scholarship Program"
    assert qc.source == "https://quezoncity.gov.ph/qcitizen-guides/qc-scholars-guide/"
  end

  test "keeps the workbook provenance available to the application" do
    assert Scholarships.dataset_metadata() == %{
             "imported_on" => "2026-07-18",
             "source_sheet" => "Scholarships",
             "source_workbook" => "abot-2026-2027-scholarship-opportunities.xlsx"
           }
  end
end
