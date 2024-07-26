defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.1.0",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:pgvector, path: "../.."},
      {:postgrex, "~> 0.17"},
      {:nx, "~> 0.5"}
    ]
  end
end
