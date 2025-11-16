defmodule Bucketixir.S3Client do
  @moduledoc """
  S3 client using ExAws for making authenticated requests.
  """

  @doc """
  Makes an S3 request using ExAws.

  For list buckets, bucket is nil.
  For list objects, bucket is not nil.
  """
  @spec s3_request(String.t(), String.t(), map(), String.t() | nil) ::
          {:ok, map()} | {:error, term()}
  def s3_request(endpoint, region, config, bucket) do
    # Set ExAws config globally for this request
    Application.put_env(:ex_aws, :debug_requests, true)
    ex_aws_config = set_config(endpoint, region, config)

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

  @doc """
  set_config auxiliary setter for configuration
  returns the ex_aws_config
  """
  def set_config(endpoint, region, config) do
    Application.put_env(:ex_aws, :access_key_id, config.access_key_id)
    Application.put_env(:ex_aws, :secret_access_key, config.secret_access_key)
    uri = URI.parse(endpoint)

    ex_aws_config =
      ExAws.Config.new(:s3)
      |> Map.put(:endpoint, %{
        host: uri.host,
        scheme: uri.scheme,
        port: uri.port,
        path: uri.path
      })
      |> Map.put(:region, region)
      |> Map.put(:signature_version, :v4)
      |> Map.put(:aws_signing_region, region)

    Application.put_env(:ex_aws, :config, ex_aws_config)
    ex_aws_config
  end
end
