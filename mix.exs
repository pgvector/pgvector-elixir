defmodule Pgvector.MixProject do
  use Mix.Project

  @source_url "https://github.com/pgvector/pgvector-elixir"
  @version "0.1.1"

  def project do
    [
      app: :pgvector,
      version: @version,
      elixir: "~> 1.10",
      deps: deps(),
      docs: docs(),
      package: package(),
      name: "pgvector",
      description: "pgvector support for Elixir",
    ]
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 3.0", optional: true},
      {:ecto_sql, "~> 3.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"],
      api_reference: false
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end
end
