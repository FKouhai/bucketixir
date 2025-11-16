defmodule Bucketixir.Command.Write do
  @moduledoc """
  Logic for bucketixir write subcommand
  """
  alias Bucketixir.Command.Helpers
  alias ExAws.S3
  alias Optimus.ParseResult

  @type config :: %{
          access_key_id: String.t(),
          secret_access_key: String.t(),
          endpoint: String.t(),
          region: String.t()
        }
  @doc "uploads a file to the given bucket"
  @spec run(ParseResult.t()) :: :ok | {:error, String.t()}
  # "@config_file is the path to the config file inside the filesystem"

  def run(%ParseResult{
        args: %{bucket: bucket},
        options: %{source_path: src, destination_path: dst}
      }) do
    bucket = String.trim(bucket) |> String.trim_trailing("?")

    with {:ok, config} <- Helpers.load_config(),
         :ok <- write_in_bucket(config, bucket, src, dst) do
      :ok
    else
      {:error, reason} ->
        IO.puts(:standard_error, "Error: #{inspect(reason)}")
        unless System.get_env("MIX_ENV") == "test", do: System.halt(1)
    end
  end

  def write_in_bucket(config, bucket, src, dst) do
    ex_aws_config = Bucketixir.S3Client.set_config(config.endpoint, config.region, config)

    case File.read(src) do
      {:ok, body} ->
        case S3.put_object(bucket, dst, body) |> ExAws.request(ex_aws_config) do
          {:ok, response} ->
            IO.puts("File successfully uploaded to #{dst} (status: #{response.status_code})")
            :ok

          {:error, reason} ->
            {:error, "Failed to upload the file: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to read file: #{reason}"}
    end
  end
end
