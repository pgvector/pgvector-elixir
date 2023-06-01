if Code.ensure_loaded?(Ecto) do
  defmodule Pgvector.Ecto.Query do
    @moduledoc """
    Distance functions for Ecto
    """

    @doc """
    Returns the L2 distance
    """
    defmacro l2_distance(column, value) do
      quote do
        fragment("(? <-> ?::vector)", unquote(column), unquote(value))
      end
    end

    @doc """
    Returns the negative inner product
    """
    defmacro max_inner_product(column, value) do
      quote do
        fragment("(? <#> ?::vector)", unquote(column), unquote(value))
      end
    end

    @doc """
    Returns the cosine distance
    """
    defmacro cosine_distance(column, value) do
      quote do
        fragment("(? <=> ?::vector)", unquote(column), unquote(value))
      end
    end
  end
end
