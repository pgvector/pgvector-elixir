if Code.ensure_loaded?(Ecto) do
  defmodule Pgvector.Ecto.Bit do
    use Ecto.Type

    def type, do: :bit

    def cast(value) do
      {:ok, value}
    end

    def load(data) do
      {:ok, data}
    end

    def dump(value) do
      {:ok, value}
    end
  end
end
