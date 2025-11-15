defmodule Bucketixir.Command.List do
  @moduledoc """
  List operations for bucketixir.
  Reads the configuration from ~/.bucketixir.yaml and
  uses Req + ReqS3 for ListBuckets operations
  """
  alias Optimus.ParseResult
  import SweetXml

  @type config :: %{
          access_key_id: String.t(),
          secret_access_key: String.t(),
          endpoint: String.t(),
          region: String.t()
        }
  @doc "lists all buckets for the authenticated user"
  @spec run(ParseResult.t()) :: :ok | {:error, String.t()}
  # "@config_file is the path to the config file inside the filesystem"
  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")

  def run(%ParseResult{}) do
    case load_config() do
      {:ok, config} ->
        case list_buckets(config) do
          :ok ->
            :ok

          {:error, reason} ->
            IO.puts(:standard_error, "Error: #{reason}")
            System.halt(1)
        end

      {:error, reason} ->
        IO.puts(:standard_error, "Error: #{inspect(reason)}")
        System.halt(1)
    end
  end

  # Uses YamlElixir to read the credentials from the config file
  # Then it stores them into a map
  defp load_config do
    case YamlElixir.read_from_file(@config_file, []) do
      {:ok, %{"credentials" => credentials}} when is_map(credentials) ->
        {:ok, credentials |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)}

      {:ok, _} ->
        {:error, "config file found but credentials structure is invalid"}

      {:error, reason} ->
        {:error, "failed to parse yaml: #{inspect(reason)}"}
    end
  end

  @doc "Authenticates and lists buckets using Req + ReqS3"
  @spec list_buckets(config()) :: :ok | {:error, String.t()}
  def list_buckets(config) do
    IO.puts("Connecting to #{config.endpoint}...")

    result = Bucketixir.S3Client.s3_request(config.endpoint, config.region, config, nil)

    case result do
      {:ok, %{status_code: 200, body: body}} ->
        case parse_and_display_buckets(body) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:ok, %{status_code: status, body: body}} when status in [401, 403] ->
        {:error,
         "Failed to list buckets: HTTP #{status} (Authentication failed)\nResponse body: #{body}"}

      {:ok, %{status_code: status}} ->
        {:error, "Failed to list buckets: HTTP #{status}"}

      {:error, reason} ->
        {:error, "Failed to list buckets: #{inspect(reason)}"}
    end
  end

  @spec parse_and_display_buckets(String.t()) :: :ok | {:error, String.t()}
  defp parse_and_display_buckets(xml_body) do
    try do
      buckets = xml_body |> xpath(~x"//Bucket"l)

      IO.puts("Available buckets: #{length(buckets)}")

      if Enum.empty?(buckets) do
        IO.puts("No buckets found")
      else
        Enum.each(buckets, fn bucket ->
          name = bucket |> xpath(~x"./Name/text()"s)
          creation_date = bucket |> xpath(~x"./CreationDate/text()"s)
          IO.puts("- #{name} (Created: #{creation_date})")
        end)
      end

      :ok
    rescue
      e ->
        {:error, "Failed to parse XML response: #{inspect(e)}"}
    end
  end
end
