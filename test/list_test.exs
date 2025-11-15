defmodule MockS3Client do
  use Agent

  def start_link do
    Agent.start_link(fn -> {:error, "not set"} end, name: :mock_s3_client)
  end

  def set_response(response) do
    Agent.update(:mock_s3_client, fn _ -> response end)
  end

  def s3_request(_endpoint, _region, _config, _bucket) do
    Agent.get(:mock_s3_client, fn r -> r end)
  end
end

defmodule Bucketixir.Command.ListTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Bucketixir.Command.List

  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")

  setup do
    # Start mock agent
    {:ok, _} = MockS3Client.start_link()

    # Clean up config file
    on_exit(fn ->
      if File.exists?(@config_file), do: File.rm(@config_file)
    end)

    # Set mock
    Application.put_env(:bucketixir, :s3_client, MockS3Client)

    :ok
  end

  test "lists buckets successfully" do
    # Mock S3 response
    body = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListAllMyBucketsResult>
      <Buckets>
        <Bucket>
          <Name>my-bucket-1</Name>
          <CreationDate>2023-01-01T00:00:00.000Z</CreationDate>
        </Bucket>
        <Bucket>
          <Name>my-bucket-2</Name>
          <CreationDate>2023-01-02T00:00:00.000Z</CreationDate>
        </Bucket>
      </Buckets>
    </ListAllMyBucketsResult>
    """

    MockS3Client.set_response({:ok, %{status_code: 200, body: body}})

    # Create mock config
    config_content = """
    credentials:
      access_key_id: test_key
      secret_access_key: test_secret
      endpoint: https://s3.example.com
      region: us-east-1
    """

    File.write!(@config_file, config_content)

    output =
      capture_io(fn ->
        List.run(%Optimus.ParseResult{})
      end)

    assert output =~ "Connecting to https://s3.example.com..."
    assert output =~ "Available buckets: 2"
    assert output =~ "- my-bucket-1 (Created: 2023-01-01T00:00:00.000Z)"
    assert output =~ "- my-bucket-2 (Created: 2023-01-02T00:00:00.000Z)"
  end

  test "handles empty bucket list" do
    body = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListAllMyBucketsResult>
      <Buckets></Buckets>
    </ListAllMyBucketsResult>
    """

    MockS3Client.set_response({:ok, %{status_code: 200, body: body}})

    config_content = """
    credentials:
      access_key_id: test_key
      secret_access_key: test_secret
      endpoint: https://s3.example.com
      region: us-east-1
    """

    File.write!(@config_file, config_content)

    output =
      capture_io(fn ->
        List.run(%Optimus.ParseResult{})
      end)

    assert output =~ "Available buckets: 0"
    assert output =~ "No buckets found"
  end

  test "handles authentication error" do
    MockS3Client.set_response({:ok, %{status_code: 403, body: "Forbidden"}})

    config_content = """
    credentials:
      access_key_id: test_key
      secret_access_key: test_secret
      endpoint: https://s3.example.com
      region: us-east-1
    """

    File.write!(@config_file, config_content)

    output =
      capture_io(:stderr, fn ->
        List.run(%Optimus.ParseResult{})
      end)

    assert output =~ "Failed to list buckets: HTTP 403 (Authentication failed)"
  end

  test "handles config file not found" do
    # Don't create config file
    output =
      capture_io(:stderr, fn ->
        List.run(%Optimus.ParseResult{})
      end)

    assert output =~ "failed to parse yaml"
  end
end
