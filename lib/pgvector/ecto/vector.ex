if Code.ensure_compiled(Ecto) do
  defmodule Pgvector.Ecto.Vector do
    use Ecto.Type
    def type, do: :vector

    def cast(value) when is_list(value) do
      {:ok, value}
    end
    def cast(_), do: :error

    def load(data) do
      {:ok, data}
    end

    def dump(value) when is_list(value) do
      {:ok, value}
    end
    def dump(_), do: :error
  end
end
