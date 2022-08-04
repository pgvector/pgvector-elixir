defmodule Pgvector.MixProject do
  use Mix.Project

  def project do
    [
      app: :pgvector,
      version: "0.1.0",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
