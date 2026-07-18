defmodule AbotDemo.OpenAITest do
  use ExUnit.Case, async: true

  alias AbotDemo.OpenAI

  test "minimizes profile data before it is sent to scholarship matching" do
    profile =
      OpenAI.matching_profile(%{
        name: "Ana Reyes",
        level: "Grade 12",
        intake: "Incoming college",
        location: "Quezon City",
        course: "BS Information Technology",
        grade: "94",
        income: "220000",
        school: "Public senior high school",
        situation: "Needs financial support to stay enrolled"
      })

    refute Map.has_key?(profile, "name")
    refute Map.has_key?(profile, "income")
    assert profile["general_average_band"] == "93-100"
    assert profile["household_income_band"] == "PHP 150k-299k/year"
    assert profile["location"] == "Quezon City"
  end
end
