defmodule MockS3ClientForCLITest do
  use Agent

  def start_link do
    Agent.start_link(fn -> {:error, "not set"} end, name: :mock_s3_client_cli)
  end

  def set_response(response) do
    Agent.update(:mock_s3_client_cli, fn _ -> response end)
  end

  def s3_request(_endpoint, _region, _config, _bucket) do
    Agent.get(:mock_s3_client_cli, fn r -> r end)
  end
end

defmodule BucketixirTest do
  use ExUnit.Case
  doctest Bucketixir.CLI
  alias Bucketixir.CLI

  import ExUnit.CaptureIO

  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")

  setup do
    # Start mock agent
    {:ok, _} = MockS3ClientForCLITest.start_link()

    # Clean up config file before and after tests
    on_exit(fn ->
      if File.exists?(@config_file), do: File.rm(@config_file)
    end)

    # Set mock
    Application.put_env(:bucketixir, :s3_client, MockS3ClientForCLITest)

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
    IO.puts("Running test: main with unknown subcommand prints error")
    argv = ["thisdoesnotexist"]

    output = capture_io(:stderr, fn -> CLI.main(argv) end)

    assert output =~ "unrecognized arguments: \"thisdoesnotexist\""
  end

  test "main with list subcommand calls list command" do
    IO.puts("Running test: main with list subcommand calls list command")

    # Mock S3 response
    body = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListAllMyBucketsResult>
      <Buckets>
        <Bucket>
          <Name>test-bucket</Name>
          <CreationDate>2023-01-01T00:00:00.000Z</CreationDate>
        </Bucket>
      </Buckets>
    </ListAllMyBucketsResult>
    """

    MockS3ClientForCLITest.set_response({:ok, %{status_code: 200, body: body}})

    # Create mock config
    config_content = """
    credentials:
      access_key_id: test_key
      secret_access_key: test_secret
      endpoint: https://s3.example.com
      region: us-east-1
    """

    File.write!(@config_file, config_content)

    output = capture_io(fn -> CLI.main(["list"]) end)

    IO.puts("Captured output: #{inspect(output)}")

    assert output =~ "Connecting to https://s3.example.com"
    assert output =~ "Available buckets: 1"
    assert output =~ "- test-bucket"
  end
end
