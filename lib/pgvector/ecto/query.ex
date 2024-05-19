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
        fragment("(? <-> ?)", unquote(column), ^Pgvector.Ecto.Utils.to_sql(unquote(value)))
      end
    end

    @doc """
    Returns the negative inner product
    """
    defmacro max_inner_product(column, value) do
      quote do
        fragment("(? <#> ?)", unquote(column), ^Pgvector.Ecto.Utils.to_sql(unquote(value)))
      end
    end

    @doc """
    Returns the cosine distance
    """
    defmacro cosine_distance(column, value) do
      quote do
        fragment("(? <=> ?)", unquote(column), ^Pgvector.Ecto.Utils.to_sql(unquote(value)))
      end
    end

    @doc """
    Returns the L1 distance
    """
    defmacro l1_distance(column, value) do
      quote do
        fragment("(? <+> ?)", unquote(column), ^Pgvector.Ecto.Utils.to_sql(unquote(value)))
      end
    end

    @doc """
    Returns the Hamming distance
    """
    defmacro hamming_distance(column, value) do
      quote do
        fragment("(? <~> ?)", unquote(column), unquote(value))
      end
    end

    @doc """
    Returns the Jaccard distance
    """
    defmacro jaccard_distance(column, value) do
      quote do
        fragment("(? <%> ?)", unquote(column), unquote(value))
      end
    end
  end
end
