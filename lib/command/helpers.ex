defmodule Bucketixir.Command.Helpers do
  @moduledoc """
  Helper functions and methods to remove code duplication
  """
  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")
  # Uses YamlElixir to read the credentials from the config file
  # Then it stores them into a map
  @doc """
  load_config public helper that reads the config file and stores it into memory
  """
  def load_config do
    case YamlElixir.read_from_file(@config_file, []) do
      {:ok, %{"credentials" => credentials}} when is_map(credentials) ->
        config = credentials |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
        # Trim trailing / from endpoint to avoid double slashes in URL
        config = Map.update!(config, :endpoint, &String.trim_trailing(&1, "/"))
        {:ok, config}

      {:ok, _} ->
        {:error, "config file found but credentials structure is invalid"}

      {:error, reason} ->
        {:error, "failed to parse yaml: #{inspect(reason)}"}
    end
  end
end
