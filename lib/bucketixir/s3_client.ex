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
    Application.put_env(:ex_aws, :debug_requests, true)
    Application.put_env(:ex_aws, :access_key_id, config.access_key_id)
    Application.put_env(:ex_aws, :secret_access_key, config.secret_access_key)
    # Application.put_env(:ex_aws, :region, region)

    uri = URI.parse(endpoint)

    ex_aws_config =
      ExAws.Config.new(:s3)
      # 2. Configure the custom endpoint for connection
      |> Map.put(:endpoint, %{
        host: uri.host,
        scheme: uri.scheme,
        port: uri.port
        # path_style: true
      })
      |> Map.put(:region, region)
      |> Map.put(:signature_version, :v4)
      # Use the argument region for signing
      |> Map.put(:aws_signing_region, region)

    # For list buckets, bucket is nil
    if bucket == nil do
      ExAws.S3.list_buckets()
      |> Map.put(:parser, fn body -> body end)
      |> ExAws.request(ex_aws_config)
    else
      ExAws.S3.list_objects(bucket <> "?")
      |> Map.put(:parser, fn body -> body end)
      |> ExAws.request(ex_aws_config)
    end
  end
end
