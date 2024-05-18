if Code.ensure_loaded?(Ecto) do
  defmodule Pgvector.Ecto.HalfVector do
    use Ecto.Type

    def type, do: :halfvec

    def cast(value) do
      {:ok, value |> Pgvector.HalfVector.new()}
    end

    def load(data) do
      {:ok, data}
    end

    def dump(value) do
      {:ok, value}
    end
  end
end
