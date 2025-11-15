defmodule MockS3ClientListObject do
  use Agent

  def start_link do
    Agent.start_link(fn -> {:error, "not set"} end, name: :mock_s3_client_list_object)
  end

  def set_response(response) do
    Agent.update(:mock_s3_client_list_object, fn _ -> response end)
  end

  def s3_request(_endpoint, _region, _config, _bucket) do
    Agent.get(:mock_s3_client_list_object, fn r -> r end)
  end
end

defmodule Bucketixir.Command.ListObjectTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Bucketixir.Command.ListObject

  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")

  setup do
    # Start mock agent
    {:ok, _} = MockS3ClientListObject.start_link()

    # Clean up config file
    on_exit(fn ->
      if File.exists?(@config_file), do: File.rm(@config_file)
    end)

    # Set mock
    Application.put_env(:bucketixir, :s3_client, MockS3ClientListObject)

    :ok
  end

  test "lists objects successfully" do
    # Mock S3 response
    body = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListBucketResult>
      <Contents>
        <Key>file1.txt</Key>
        <Size>1024</Size>
        <LastModified>2023-01-01T00:00:00.000Z</LastModified>
      </Contents>
      <Contents>
        <Key>file2.txt</Key>
        <Size>2048</Size>
        <LastModified>2023-01-02T00:00:00.000Z</LastModified>
      </Contents>
    </ListBucketResult>
    """

    MockS3ClientListObject.set_response({:ok, %{status_code: 200, body: body}})

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
        ListObject.run(%Optimus.ParseResult{args: %{bucket: "test-bucket"}})
      end)

    assert output =~ "Listing objects in bucket test-bucket at https://s3.example.com..."
    assert output =~ "Objects in bucket: 2"
    assert output =~ "- file1.txt (Size: 1024, Last Modified: 2023-01-01T00:00:00.000Z)"
    assert output =~ "- file2.txt (Size: 2048, Last Modified: 2023-01-02T00:00:00.000Z)"
  end

  test "handles empty object list" do
    body = """
    <?xml version="1.0" encoding="UTF-8"?>
    <ListBucketResult>
    </ListBucketResult>
    """

    MockS3ClientListObject.set_response({:ok, %{status_code: 200, body: body}})

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
        ListObject.run(%Optimus.ParseResult{args: %{bucket: "test-bucket"}})
      end)

    assert output =~ "Objects in bucket: 0"
    assert output =~ "No objects found"
  end

  test "handles authentication error" do
    MockS3ClientListObject.set_response({:ok, %{status_code: 403, body: "Forbidden"}})

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
        ListObject.run(%Optimus.ParseResult{args: %{bucket: "test-bucket"}})
      end)

    assert output =~ "Failed to list objects: HTTP 403 (Authentication failed)"
  end

  test "handles config file not found" do
    # Don't create config file
    output =
      capture_io(:stderr, fn ->
        ListObject.run(%Optimus.ParseResult{args: %{bucket: "test-bucket"}})
      end)

    assert output =~ "failed to parse yaml"
  end
end
