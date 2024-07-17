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
      {:bumblebee, "~> 0.5.3"},
      {:exla, ">= 0.0.0"}
    ]
  end
end
