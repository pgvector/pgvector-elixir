defmodule Pgvector.MixProject do
  use Mix.Project

  @version "0.2.1"

  def project do
    [
      app: :pgvector,
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "pgvector",
      description: "pgvector support for Elixir",
      source_url: "https://github.com/pgvector/pgvector-elixir"
    ]
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 3.0", optional: true},
      {:nx, "~> 0.5", optional: true},
      {:ecto_sql, "~> 3.0", only: :test},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      api_reference: false,
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pgvector/pgvector-elixir"}
    ]
  end
end
