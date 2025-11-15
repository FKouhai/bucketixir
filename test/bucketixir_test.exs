defmodule BucketixirTest do
  use ExUnit.Case
  doctest Bucketixir.CLI
  alias Bucketixir.CLI

  import ExUnit.CaptureIO

  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")

  setup do
    # Clean up config file before and after tests
    on_exit(fn ->
      if File.exists?(@config_file), do: File.rm(@config_file)
    end)

    :ok
  end

  test "main with auth subcommand runs authentication" do
    IO.puts("Running test: main with auth subcommand runs authentication")

    argv = [
      "auth",
      "--access_key_id",
      "test_key",
      "--secret_access_key",
      "test_secret",
      "--endpoint",
      "https://s3.test.com",
      "--region",
      "test-region"
    ]

    output = capture_io(fn -> CLI.main(argv) end)

    assert output =~ "authenticating against https://s3.test.com in region test-region"
    assert output =~ "succesfully received auth params"
    refute output =~ "test_secret"

    # Check config file was created
    assert File.exists?(@config_file)
  end

  test "main with unknown subcommand prints error" do
    IO.puts("Running test: main with unknown subcommand runs authentication")
    argv = ["list"]

    output = capture_io(:stderr, fn -> CLI.main(argv) end)

    assert output =~ "Error Unknown subcommand structure"
  end
end
