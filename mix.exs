defmodule Pgvector.MixProject do
  use Mix.Project

  def project do
    [
      app: :pgvector,
      version: "0.1.0",
      elixir: "~> 1.10",
      deps: deps(),
      package: package(),
      name: "pgvector",
      description: "pgvector support for Elixir",
      source_url: "https://github.com/pgvector/pgvector-elixir"
    ]
  end

  defp deps do
    [
      {:ecto_sql, ">= 3.0.0", optional: true},
      {:postgrex, ">= 0.0.0", optional: true},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pgvector/pgvector-elixir"}
    ]
  end
end
