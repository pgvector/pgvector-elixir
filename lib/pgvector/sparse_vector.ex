defmodule Pgvector.SparseVector do
  @moduledoc """
  A sparse vector struct for pgvector
  """

  defstruct [:data]

  @doc """
  Creates a new sparse vector from a list, tensor or sparse vector
  """
  def new(list) when is_list(list) do
    {values, indices} =
      list
      |> Enum.with_index()
      |> Enum.filter(fn {v, _} -> v != 0 end)
      |> Enum.unzip()

    dim = list |> length()
    new(dim, indices, values)
  end

  def new(%Pgvector.SparseVector{} = vector) do
    vector
  end

  if Code.ensure_loaded?(Nx) do
    def new(tensor) when is_struct(tensor, Nx.Tensor) do
      if Nx.rank(tensor) != 1 do
        raise ArgumentError, "expected rank to be 1"
      end

      # TODO improve
      new(tensor |> Nx.to_list())
    end
  end

  @doc """
  Creates a new sparse vector from a map of non-zero elements
  """
  def new(map, dimensions) when is_map(map) do
    {indices, values} =
      map
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.filter(fn {_, v} -> v != 0 end)
      |> Enum.unzip()

    new(dimensions, indices, values)
  end

  defp new(dim, indices, values) do
    nnz = indices |> length()
    indices = for v <- indices, into: "", do: <<v::signed-32>>
    values = for v <- values, into: "", do: <<v::float-32>>
    from_binary(<<dim::signed-32, nnz::signed-32, 0::signed-32, indices::binary, values::binary>>)
  end

  @doc """
  Creates a new sparse vector from its binary representation
  """
  def from_binary(binary) when is_binary(binary) do
    %Pgvector.SparseVector{data: binary}
  end

  @doc """
  Returns the number of dimensions
  """
  def dimensions(vector) when is_struct(vector, Pgvector.SparseVector) do
    <<dim::signed-32, _::binary>> = vector.data
    dim
  end

  @doc """
  Returns the non-zero indices
  """
  def indices(vector) when is_struct(vector, Pgvector.SparseVector) do
    <<_::signed-32, nnz::signed-32, 0::signed-32, indices::binary-size(nnz)-unit(32),
      _::binary-size(nnz)-unit(32)>> = vector.data

    for <<v::signed-32 <- indices>>, do: v
  end

  @doc """
  Returns the non-zero values
  """
  def values(vector) when is_struct(vector, Pgvector.SparseVector) do
    <<_::signed-32, nnz::signed-32, 0::signed-32, _::binary-size(nnz)-unit(32),
      values::binary-size(nnz)-unit(32)>> = vector.data

    for <<v::float-32 <- values>>, do: v
  end
end

defimpl Inspect, for: Pgvector.SparseVector do
  import Inspect.Algebra

  def inspect(vector, opts) do
    dimensions = vector |> Pgvector.SparseVector.dimensions()
    indices = vector |> Pgvector.SparseVector.indices()
    values = vector |> Pgvector.SparseVector.values()
    elements = Enum.zip(indices, values) |> Enum.into(%{})

    concat([
      "Pgvector.SparseVector.new(",
      Inspect.Map.inspect(elements, opts),
      ", ",
      Inspect.Integer.inspect(dimensions, opts),
      ")"
    ])
  end
end
