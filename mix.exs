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
      applications: [:logger, :optimus]
    ]
  end

  defp deps do
    [
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},
      {:optimus, "~> 0.2"},
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
