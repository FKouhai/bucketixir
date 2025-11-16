defmodule Bucketixir.Command.ListObject do
  @moduledoc """
  List objects in a bucket for bucketixir.
  Reads the configuration from ~/.bucketixir.yaml
  """
  alias Bucketixir.Command.Helpers
  alias Optimus.ParseResult
  import SweetXml

  defp s3_client do
    Application.get_env(:bucketixir, :s3_client, Bucketixir.S3Client)
  end

  @type config :: %{
          access_key_id: String.t(),
          secret_access_key: String.t(),
          endpoint: String.t(),
          region: String.t()
        }
  @doc "lists all objects in the given bucket"
  @spec run(ParseResult.t()) :: :ok | {:error, String.t()}
  # "@config_file is the path to the config file inside the filesystem"

  def run(%ParseResult{args: %{bucket: bucket}}) do
    bucket = String.trim(bucket)

    with {:ok, config} <- Helpers.load_config(),
         :ok <- list_objects(config, bucket) do
      :ok
    else
      {:error, reason} ->
        IO.puts(:standard_error, "Error: #{reason}")
        unless System.get_env("MIX_ENV") == "test", do: System.halt(1)
    end
  end

  @doc "Authenticates and lists objects in bucket using ExAws"
  @spec list_objects(config(), String.t()) :: :ok | {:error, String.t()}
  def list_objects(config, bucket) do
    IO.puts("Listing objects in bucket #{bucket} at #{config.endpoint}...")

    result = s3_client().s3_request(config.endpoint, config.region, config, bucket)

    case result do
      {:ok, %{status_code: 200, body: body}} ->
        case parse_and_display_objects(body) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:ok, %{status_code: status, body: body}} when status in [401, 403] ->
        {:error,
         "Failed to list objects: HTTP #{status} (Authentication failed)\nResponse body: #{body}"}

      {:ok, %{status_code: status}} ->
        {:error, "Failed to list objects: HTTP #{status}"}

      {:error, reason} ->
        {:error, "Failed to list objects: #{inspect(reason)}"}
    end
  end

  @spec parse_and_display_objects(list() | String.t() | nil) :: :ok | {:error, String.t()}
  defp parse_and_display_objects(body) do
    objects =
      cond do
        body in [nil, ""] -> []
        is_list(body) -> body
        true -> body |> xpath(~x"//Contents"l)
      end

    IO.puts("Objects in bucket: #{length(objects)}")

    Enum.each(objects, fn object ->
      if is_map(object) and Map.has_key?(object, :key) do
        # ExAws parsed object
        IO.puts("- #{object.key} (Size: #{object.size}, Last Modified: #{object.last_modified})")
      else
        # XML object
        key = object |> xpath(~x"./Key/text()"s)
        size = object |> xpath(~x"./Size/text()"s)
        last_modified = object |> xpath(~x"./LastModified/text()"s)
        IO.puts("- #{key} (Size: #{size}, Last Modified: #{last_modified})")
      end
    end)

    if Enum.empty?(objects) do
      IO.puts("No objects found")
    end

    :ok
  rescue
    e ->
      {:error, "Failed to parse response: #{inspect(e)}"}
  end
end
