if Code.ensure_loaded?(Ecto) do
  defmodule Pgvector.Ecto.Vector do
    use Ecto.Type

    def type, do: :vector

    def cast(value) do
      {:ok, value |> Pgvector.new()}
    end

    def load(data) do
      {:ok, data}
    end

    def dump(value) do
      {:ok, value}
    end
  end
end
