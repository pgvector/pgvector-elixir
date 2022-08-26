if Code.ensure_loaded?(Ecto) do
  defmodule Pgvector.Ecto.Query do
    defmacro l2_distance(column, value) do
      quote do
        fragment("? <-> ?::vector", unquote(column), unquote(value))
      end
    end

    defmacro max_inner_product(column, value) do
      quote do
        fragment("? <#> ?::vector", unquote(column), unquote(value))
      end
    end

    defmacro cosine_distance(column, value) do
      quote do
        fragment("? <=> ?::vector", unquote(column), unquote(value))
      end
    end
  end
end
