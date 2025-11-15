defmodule Bucketixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :bucketixir,
      version: "0.1.0",
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Bucketixir.CLI]
    ]
  end

  def application do
    [
      applications: [:logger, :optimus, :yaml_elixir, :ex_aws, :ex_aws_s3, :req, :req_s3]
    ]
  end

  defp deps do
    [
      {:ex_aws, "~> 2.6"},
      {:ex_aws_s3, "~> 2.5"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:optimus, "~> 0.2"},
      {:yaml_elixir, "~> 2.12"},
      {:req, "~> 0.5.0"},
      {:req_s3, "~> 0.2.3"},
      # test dependencies
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
