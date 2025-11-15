defmodule Bucketixir.CLI do
  alias Bucketixir.Command.Auth

  @moduledoc """
  CLI module for Bucketixir.
  """

  def main(argv) do
    Application.put_env(:elixir, :ansi_enabled, true)
    {subcommand_path, result} = Optimus.parse!(spec(), argv)

    case subcommand_path do
      [:auth] ->
        Auth.run(result)

      _ ->
        IO.puts(:standard_error, "Error Unknown subcommand structure, run 'bucketixir --help")
        unless Mix.env() == :test, do: System.halt(1)
    end
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
          about: "lists all the objects inside the bucket"
        ],
        write: [
          name: "write",
          about: "writes a file to a given path inside the bucket",
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
