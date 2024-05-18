if Code.ensure_loaded?(Ecto) do
  defmodule Pgvector.Ecto.SparseVector do
    use Ecto.Type

    def type, do: :sparsevec

    def cast(value) do
      {:ok, value |> Pgvector.SparseVector.new()}
    end

    def load(data) do
      {:ok, data}
    end

    def dump(value) do
      {:ok, value}
    end
  end
end
