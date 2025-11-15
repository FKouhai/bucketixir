defmodule Bucketixir.Command.AuthTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Bucketixir.Command.Auth

  @config_file Path.join(System.user_home!(), ".bucketixir.yaml")

  setup do
    # Clean up before and after
    on_exit(fn ->
      if File.exists?(@config_file), do: File.rm(@config_file)
    end)

    :ok
  end

  test "run stores credentials and prints success messages" do
    IO.puts("run stores credentials and prints success messages")

    parse_result = %Optimus.ParseResult{
      options: %{
        access_key_id: "test_key_id",
        secret_access_key: "test_secret",
        endpoint: "https://s3.example.com",
        region: "us-east-1"
      }
    }

    output = capture_io(fn -> Auth.run(parse_result) end)

    assert output =~ "authenticating against https://s3.example.com in region us-east-1"
    assert output =~ "Target config is: #{@config_file}"
    assert output =~ "authentication parameters read correctly"
    assert output =~ "config saved to : #{@config_file}"
    assert output =~ "succesfully received auth params"

    # Check file was created
    assert File.exists?(@config_file)
    content = File.read!(@config_file)
    assert content =~ "access_key_id: test_key_id"
    assert content =~ "secret_access_key: test_secret"
    assert content =~ "endpoint: https://s3.example.com"
    assert content =~ "region: us-east-1"
  end

  test "run trims whitespace from inputs" do
    IO.puts("run trims whitespace from inputs")

    parse_result = %Optimus.ParseResult{
      options: %{
        access_key_id: "  test_key_id  ",
        secret_access_key: "  test_secret  ",
        endpoint: "  https://s3.example.com  ",
        region: "  us-east-1  "
      }
    }

    capture_io(fn -> Auth.run(parse_result) end)

    content = File.read!(@config_file)
    assert content =~ "access_key_id: test_key_id"
    assert content =~ "secret_access_key: test_secret"
    assert content =~ "endpoint: https://s3.example.com"
    assert content =~ "region: us-east-1"
  end
end
