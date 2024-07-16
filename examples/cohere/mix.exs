defmodule Cohere.MixProject do
  use Mix.Project

  def project do
    [
      app: :cohere,
      version: "0.1.0",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:pgvector, path: "../.."},
      {:postgrex, "~> 0.17"},
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
