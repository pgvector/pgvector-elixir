if Code.ensure_loaded?(Ecto) do
  defmodule Pgvector.Ecto.Query do
    @moduledoc """
    Distance functions for Ecto
    """

    @doc """
    Returns the L2 distance
    """
    defmacro l2_distance(left, right) do
      quote do
        fragment("(? <-> ?)", unquote(left), unquote(right))
      end
    end

    @doc """
    Returns the negative inner product
    """
    defmacro max_inner_product(left, right) do
      quote do
        fragment("(? <#> ?)", unquote(left), unquote(right))
      end
    end

    @doc """
    Returns the cosine distance
    """
    defmacro cosine_distance(left, right) do
      quote do
        fragment("(? <=> ?)", unquote(left), unquote(right))
      end
    end

    @doc """
    Returns the L1 distance
    """
    defmacro l1_distance(left, right) do
      quote do
        fragment("(? <+> ?)", unquote(left), unquote(right))
      end
    end

    @doc """
    Returns the Hamming distance
    """
    defmacro hamming_distance(left, right) do
      quote do
        fragment("(? <~> ?)", unquote(left), unquote(right))
      end
    end

    @doc """
    Returns the Jaccard distance
    """
    defmacro jaccard_distance(left, right) do
      quote do
        fragment("(? <%> ?)", unquote(left), unquote(right))
      end
    end
  end
end
