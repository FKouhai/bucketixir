defmodule Bucketixir.CLI do
  alias Bucketixir.Command.Auth
  alias Bucketixir.Command.List
  alias Bucketixir.Command.ListObject
  alias Bucketixir.Command.Write

  @moduledoc """
  CLI module for Bucketixir.
  """

  def main(argv) do
    Application.put_env(:elixir, :ansi_enabled, true)

    case Optimus.parse(spec(), argv) do
      :help ->
        IO.puts(Optimus.help(spec()))

      {:help, subcommand_path} ->
        subcommand_atom = :lists.last(subcommand_path)
        subcommand_spec = Enum.find(spec().subcommands, &(&1.subcommand == subcommand_atom))

        if subcommand_spec do
          IO.puts(Optimus.help(subcommand_spec))
        else
          IO.puts(Optimus.help(spec()))
        end

      {:ok, subcommand_path, result} ->
        run_subcommand(subcommand_path, result)

      {:error, reason} ->
        IO.puts(:standard_error, "Error: #{reason}")
        unless System.get_env("MIX_ENV") == "test", do: System.halt(1)
    end
  end

  defp run_subcommand([:auth], result), do: Auth.run(result)
  defp run_subcommand([:list], result), do: List.run(result)
  defp run_subcommand([:list_object], result), do: ListObject.run(result)
  defp run_subcommand([:write], result), do: Write.run(result)

  defp run_subcommand(_, _result) do
    IO.puts(:standard_error, "Error Unknown subcommand structure, run 'bucketixir --help")
    unless System.get_env("MIX_ENV") == "test", do: System.halt(1)
  end

  defp spec do
    Optimus.new!(
      name: "bucketixir",
      description: "cli for s3 compliant object storage apis",
      version: "0.1.0",
      author: "FKouhai",
      allow_unknown_args: false,
      parse_double_dash: true,
      subcommands: [
        auth: [
          name: "auth",
          about: "log authenticate against your s3 provider",
          options: [
            access_key_id: [
              value_name: "access_key_id",
              help: "access key id",
              required: true,
              parser: :string,
              long: "access_key_id",
              short: "a"
            ],
            secret_access_key: [
              value_name: "secret_access_key",
              help: "secret access key",
              required: true,
              parser: :string,
              long: "secret_access_key",
              short: "s"
            ],
            endpoint: [
              value_name: "endpoint",
              help: "s3 api endpoint",
              required: true,
              parser: :string,
              long: "endpoint",
              short: "e"
            ],
            region: [
              value_name: "region",
              help: "bucket's region",
              required: true,
              parser: :string,
              long: "region",
              short: "r"
            ]
          ]
        ],
        list: [
          name: "list",
          about: "lists all the buckets"
        ],
        list_object: [
          name: "list-object",
          about: "lists objects in a given bucket",
          args: [
            bucket: [
              value_name: "bucket",
              help: "bucket name to list objects from",
              required: false,
              parser: :string
            ]
          ]
        ],
        write: [
          name: "write",
          about: "writes a file to a given path inside the bucket",
          args: [
            bucket: [
              value_name: "bucket",
              help: "bucket name",
              required: true,
              parser: :string
            ]
          ],
          options: [
            destination_path: [
              value_name: "destination",
              help: "destination path inside the bucket",
              required: true,
              parser: :string,
              long: "dst",
              short: "d"
            ],
            source_path: [
              value_name: "source",
              help: "source path for your file(s) inside your filesystem",
              required: true,
              parser: :string,
              long: "src",
              short: "s"
            ]
          ]
        ],
        copy: [
          name: "copy",
          about:
            "copies one file inside of the bucket to another location inside of a given location",
          args: [
            destination_path: [
              value_name: "destination",
              help: "destination path inside the bucket",
              required: true,
              parser: :string
            ],
            source_path: [
              value_name: "source",
              help: "source path inside the bucket",
              required: true,
              parser: :string
            ]
          ]
        ],
        read: [
          name: "read",
          about: "prints to stdout the contents of a given file inside the bucket",
          args: [
            file: [
              value_name: "file",
              help: "absolute path inside the bucket",
              required: true,
              parser: :string
            ]
          ]
        ],
        fetch: [
          name: "fetch",
          about: "downloads the given file(s) into the current working directory",
          args: [
            destination_path: [
              value_name: "destination",
              help: "destination path inside the bucket",
              required: true,
              parser: :string
            ],
            source_path: [
              value_name: "source",
              help: "source path for your file(s) inside your filesystem",
              required: true,
              parser: :string
            ]
          ]
        ]
      ]
    )
  end
end
