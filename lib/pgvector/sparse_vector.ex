defmodule Pgvector.SparseVector do
  @moduledoc """
  A sparse vector struct for pgvector
  """

  defstruct [:data]

  @doc """
  Creates a new sparse vector from a list, tensor or sparse vector
  """
  def new(list) when is_list(list) do
    indices =
      list
      |> Enum.with_index()
      |> Enum.filter(fn {v, _} -> v != 0 end)
      |> Enum.map(fn {_, i} -> i end)

    values = list |> Enum.filter(fn v -> v != 0 end)
    dim = list |> length()
    nnz = indices |> length()
    indices = for v <- indices, into: "", do: <<v::signed-32>>
    values = for v <- values, into: "", do: <<v::float-32>>
    from_binary(<<dim::signed-32, nnz::signed-32, 0::signed-32, indices::binary, values::binary>>)
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
  Creates a new sparse vector from its binary representation
  """
  def from_binary(binary) when is_binary(binary) do
    %Pgvector.SparseVector{data: binary}
  end
end

defimpl Inspect, for: Pgvector.SparseVector do
  import Inspect.Algebra

  def inspect(vec, opts) do
    # TODO improve
    concat(["Pgvector.SparseVector.new(", Inspect.List.inspect(Pgvector.to_list(vec), opts), ")"])
  end
end
