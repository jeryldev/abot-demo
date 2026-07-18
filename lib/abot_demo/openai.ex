defmodule AbotDemo.OpenAI do
  @moduledoc false

  @responses_url "https://api.openai.com/v1/responses"

  def draft_request_letter(context) do
    with {:ok, api_key} <- api_key(),
         {:ok, response} <- request(api_key, letter_payload(context)),
         {:ok, letter} <- response_text(response) do
      {:ok, letter}
    end
  end

  def rank_scholarships(profile, candidates) when is_list(candidates) do
    with {:ok, api_key} <- api_key(),
         {:ok, response} <- request(api_key, ranking_payload(profile, candidates), 30_000),
         {:ok, json} <- response_text(response),
         {:ok, match} <- Jason.decode(json),
         :ok <- validate_match(match) do
      {:ok, match}
    end
  end

  # This is intentionally a minimized profile: no name, email, phone, address, or raw income.
  def matching_profile(student) do
    %{
      "location" => student.location,
      "level" => student.level,
      "intake" => student.intake,
      "intended_course" => student.course,
      "general_average_band" => general_average_band(student.grade),
      "household_income_band" => household_income_band(student.income),
      "school_type" => student.school,
      "financial_context" => student.situation
    }
  end

  defp letter_payload(context) do
    %{
      model: env("OPENAI_MODEL") || "gpt-5.6",
      store: false,
      max_output_tokens: 320,
      instructions: """
      Draft a short, formal request letter in plain text for the relevant Philippine public,
      school, or records office. Use only the facts supplied. Do not invent a recipient,
      office name, documents, eligibility, addresses, or contact details. Use "To whom it may
      concern" when no recipient is supplied. Include a polite subject line, a concise request,
      and a respectful closing. The letter will be reviewed and edited by the student before use.
      """,
      input: prompt(context)
    }
  end

  defp ranking_payload(profile, candidates) do
    %{
      model: env("OPENAI_MODEL") || "gpt-5.6",
      store: false,
      max_output_tokens: 1_200,
      instructions: """
      Rank up to three verified Philippine scholarship records for the applicant profile.
      You are a conservative decision-support assistant, not an eligibility authority. Use only
      the supplied profile and candidate facts. Do not invent scholarships, dates, requirements,
      locations, or eligibility facts. Return only candidate IDs supplied in the input. Prefer
      records whose status is open or has a stated next cycle, then explain relevant uncertainty
      in caution. Keep fit_reason and caution under 180 characters each, and keep summary under
      180 characters. A fit_reason must connect only profile facts to the candidate's stated
      criteria. Never state that the applicant is eligible or guaranteed funding.
      """,
      input:
        Jason.encode!(%{
          "privacy_minimized_applicant" => profile,
          "verified_candidates" => candidates
        }),
      text: %{
        format: %{
          type: "json_schema",
          name: "scholarship_ranking",
          strict: true,
          schema: ranking_schema()
        }
      }
    }
  end

  defp ranking_schema do
    %{
      type: "object",
      additionalProperties: false,
      required: ["recommendations", "summary"],
      properties: %{
        "recommendations" => %{
          type: "array",
          minItems: 1,
          maxItems: 3,
          items: %{
            type: "object",
            additionalProperties: false,
            required: ["candidate_id", "fit_reason", "caution"],
            properties: %{
              "candidate_id" => %{type: "string"},
              "fit_reason" => %{type: "string"},
              "caution" => %{type: "string"}
            }
          }
        },
        "summary" => %{type: "string"}
      }
    }
  end

  defp request(api_key, payload, receive_timeout \\ 12_000) do
    with :ok <- ensure_req_started() do
      try do
        case Req.post(@responses_url,
               headers: [
                 {"authorization", "Bearer #{api_key}"},
                 {"content-type", "application/json"}
               ],
               json: payload,
               receive_timeout: receive_timeout
             ) do
          {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
          {:ok, %{status: status}} -> {:error, {:api_error, status}}
          {:error, reason} -> {:error, {:network_error, reason}}
        end
      rescue
        error -> {:error, {:request_exception, Exception.message(error)}}
      end
    end
  end

  defp ensure_req_started do
    case Application.ensure_all_started(:req) do
      {:ok, _apps} -> :ok
      {:error, reason} -> {:error, {:client_start_error, reason}}
    end
  end

  defp prompt(context) do
    """
    Student name: #{context.student.name}
    Student level: #{context.student.level}
    Location: #{context.student.location}
    Scholarship: #{context.scholarship}
    Missing document: #{context.document}
    Deadline: #{context.deadline}
    """
  end

  defp validate_match(%{"recommendations" => recommendations, "summary" => summary})
       when is_list(recommendations) and is_binary(summary),
       do: :ok

  defp validate_match(_match), do: {:error, :invalid_match}

  defp general_average_band(grade) do
    case Float.parse(to_string(grade)) do
      {score, _rest} when score >= 93 -> "93-100"
      {score, _rest} when score >= 90 -> "90-92.99"
      {score, _rest} when score >= 85 -> "85-89.99"
      {_score, _rest} -> "below 85"
      :error -> "not provided"
    end
  end

  defp household_income_band(income) do
    case Integer.parse(to_string(income)) do
      {amount, _rest} when amount < 150_000 -> "below PHP 150k/year"
      {amount, _rest} when amount < 300_000 -> "PHP 150k-299k/year"
      {amount, _rest} when amount < 500_000 -> "PHP 300k-499k/year"
      {_, _rest} -> "PHP 500k+/year"
      :error -> "not provided"
    end
  end

  defp response_text(%{"output_text" => text}) when is_binary(text) and byte_size(text) > 0,
    do: {:ok, String.trim(text)}

  defp response_text(%{"output" => output}) when is_list(output) do
    output
    |> Enum.flat_map(&Map.get(&1, "content", []))
    |> Enum.find_value(fn
      %{"type" => "output_text", "text" => text} when is_binary(text) -> String.trim(text)
      _ -> nil
    end)
    |> case do
      nil -> {:error, :empty_response}
      "" -> {:error, :empty_response}
      text -> {:ok, text}
    end
  end

  defp response_text(_), do: {:error, :unexpected_response}

  defp api_key do
    case env("OPENAI_API_KEY") do
      nil -> {:error, :missing_api_key}
      "" -> {:error, :missing_api_key}
      api_key -> {:ok, api_key}
    end
  end

  defp env(key), do: System.get_env(key) || dotenv_value(key)

  # `.env` is for the local demo only; Fly and other hosts should set real environment variables.
  defp dotenv_value(key) do
    case File.read(Path.join(File.cwd!(), ".env")) do
      {:ok, contents} ->
        Enum.find_value(String.split(contents, ~r/\R/, trim: true), fn line ->
          case String.split(line, "=", parts: 2) do
            [^key, value] -> value |> String.trim() |> String.trim("\"")
            _ -> nil
          end
        end)

      {:error, _reason} ->
        nil
    end
  end
end
