defmodule Bucketixir.S3Client do
  @moduledoc """
  S3 client using ExAws for making authenticated requests.
  """

  @doc """
  Makes an S3 request using ExAws.

  For list buckets, bucket is nil.
  """
  @spec s3_request(String.t(), String.t(), map(), String.t() | nil) ::
          {:ok, map()} | {:error, term()}
  def s3_request(endpoint, region, config, bucket) do
    # Set ExAws config globally for this request
    Application.put_env(:ex_aws, :access_key_id, config.access_key_id)
    Application.put_env(:ex_aws, :secret_access_key, config.secret_access_key)
    Application.put_env(:ex_aws, :region, region)

    uri = URI.parse(endpoint)

    ex_aws_config =
      ExAws.Config.new(:s3)
      |> Map.put(:host, uri.host)
      |> Map.put(:scheme, uri.scheme)
      |> Map.put(:port, uri.port)

    # For list buckets, bucket is nil
    if bucket == nil do
      operation = ExAws.S3.list_buckets()
      operation = %{operation | parser: fn body -> body end}
      ExAws.request(operation, ex_aws_config)
    else
      # For other operations, not implemented yet
      {:error, "Not implemented"}
    end
  end
end
