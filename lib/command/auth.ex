defmodule Bucketixir.Command.Auth do
  @moduledoc """
  Logic for bucketixir auth subcommand
  """
  alias Optimus.ParseResult
  @doc "authenticates the user and stores the credentials"
  @spec run(ParseResult.t()) :: :ok | {:error, String.t()}
  # "@config_file is the path to the config file inside the filesystem"
  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")

  def run(%ParseResult{
        options: %{
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          endpoint: endpoint,
          region: region
        }
      }) do
    access_key_id = String.trim(access_key_id)
    secret_access_key = String.trim(secret_access_key)
    endpoint = String.trim(endpoint)
    region = String.trim(region)

    IO.puts("authenticating against #{endpoint} in region #{region}")

    IO.puts("Target config is: #{@config_file}")

    yaml_template = """
    credentials:
      access_key_id: #{access_key_id}
      secret_access_key: #{secret_access_key}
      endpoint: #{endpoint}
      region: #{region}
    """

    case authenticate_and_store(yaml_template) do
      :ok ->
        IO.puts("authentication parameters read correctly")
        IO.puts("config saved to : #{@config_file}")

      {:error, reason} ->
        IO.puts(:standard_error, "unable to create file: #{reason}")
        unless System.get_env("MIX_ENV") == "test", do: System.halt(1)
    end

    IO.puts("succesfully received auth params")
  end

  defp authenticate_and_store(config_data) do
    case File.write(@config_file, config_data) do
      :ok -> :ok
      {:error, reason} -> {:error, "unable to write file: #{inspect(reason)}"}
    end
  end
end
