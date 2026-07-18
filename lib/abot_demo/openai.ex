defmodule AbotDemo.OpenAI do
  @moduledoc false

  @responses_url "https://api.openai.com/v1/responses"

  def draft_request_letter(context) do
    with {:ok, api_key} <- api_key(),
         {:ok, response} <- request(api_key, context),
         {:ok, letter} <- response_text(response) do
      {:ok, letter}
    end
  end

  defp request(api_key, context) do
    with :ok <- ensure_req_started() do
      payload = %{
        model: env("OPENAI_MODEL") || "gpt-5.6",
        store: false,
        max_output_tokens: 320,
        instructions: """
        Draft a short, formal request letter in plain text for a Philippine barangay office.
        Use only the facts supplied. Do not invent a barangay name, documents, eligibility,
        addresses, or contact details. Include a polite subject line, a concise request, and a
        respectful closing. The letter will be reviewed and edited by the student before use.
        """,
        input: prompt(context)
      }

      try do
        case Req.post(@responses_url,
               headers: [
                 {"authorization", "Bearer #{api_key}"},
                 {"content-type", "application/json"}
               ],
               json: payload,
               receive_timeout: 12_000
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
