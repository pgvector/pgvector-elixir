defmodule Pgvector do
  @moduledoc """
  A vector struct for pgvector
  """

  defstruct [:data]

  @doc """
  Creates a new vector from a list, tensor, or vector
  """
  def new(list) when is_list(list) do
    dim = list |> length()
    bin = for v <- list, into: "", do: <<v::float-32>>
    from_binary(<<dim::unsigned-16, 0::unsigned-16, bin::binary>>)
  end

  def new(%Pgvector{} = vector) do
    vector
  end

  if Code.ensure_loaded?(Nx) do
    def new(tensor) when is_struct(tensor, Nx.Tensor) do
      if Nx.rank(tensor) != 1 do
        raise ArgumentError, "expected rank to be 1"
      end

      dim = tensor |> Nx.size()
      bin = tensor |> Nx.as_type(:f32) |> Nx.to_binary() |> f32_native_to_big()
      from_binary(<<dim::unsigned-16, 0::unsigned-16, bin::binary>>)
    end

    defp f32_native_to_big(binary) do
      if System.endianness() == :big do
        binary
      else
        for <<n::float-32-little <- binary>>, into: "", do: <<n::float-32-big>>
      end
    end
  end

  @doc """
  Creates a new vector from its binary representation
  """
  def from_binary(binary) when is_binary(binary) do
    %Pgvector{data: binary}
  end

  @doc """
  Converts the vector to its binary representation
  """
  def to_binary(vector) when is_struct(vector, Pgvector) do
    vector.data
  end

  def to_binary(vector) when is_struct(vector, Pgvector.HalfVector) do
    vector.data
  end

  def to_binary(vector) when is_struct(vector, Pgvector.SparseVector) do
    vector.data
  end

  @doc """
  Converts the vector to a list
  """
  def to_list(vector) when is_struct(vector, Pgvector) do
    <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(32)>> = vector.data
    for <<v::float-32 <- bin>>, do: v
  end

  def to_list(vector) when is_struct(vector, Pgvector.HalfVector) do
    <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(16)>> = vector.data
    for <<v::float-16 <- bin>>, do: v
  end

  def to_list(vector) when is_struct(vector, Pgvector.SparseVector) do
    <<dim::signed-32, nnz::signed-32, 0::signed-32, indices::binary-size(nnz)-unit(32),
      values::binary-size(nnz)-unit(32)>> = vector.data

    indices = for <<v::signed-32 <- indices>>, do: v
    values = for <<v::float-32 <- values>>, do: v
    list = List.duplicate(0.0, dim)
    Enum.zip_reduce(indices, values, list, fn x, y, acc -> List.replace_at(acc, x, y) end)
  end

  if Code.ensure_loaded?(Nx) do
    @doc """
    Converts the vector to a tensor
    """
    def to_tensor(vector) when is_struct(vector, Pgvector) do
      <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(32)>> = vector.data
      bin |> f32_big_to_native() |> Nx.from_binary(:f32)
    end

    def to_tensor(vector) when is_struct(vector, Pgvector.HalfVector) do
      <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(16)>> = vector.data
      bin |> f16_big_to_native() |> Nx.from_binary(:f16)
    end

    def to_tensor(vector) when is_struct(vector, Pgvector.SparseVector) do
      # TODO improve
      vector |> to_list() |> Nx.tensor(type: :f32)
    end

    defp f32_big_to_native(binary) do
      if System.endianness() == :big do
        binary
      else
        for <<n::float-32-big <- binary>>, into: "", do: <<n::float-32-little>>
      end
    end

    defp f16_big_to_native(binary) do
      if System.endianness() == :big do
        binary
      else
        for <<n::float-16-big <- binary>>, into: "", do: <<n::float-16-little>>
      end
    end
  end

  @doc """
  Extensions for Postgrex
  """
  def extensions do
    [
      Pgvector.Extensions.Vector,
      Pgvector.Extensions.Halfvec,
      Pgvector.Extensions.Sparsevec
    ]
  end
end

defimpl Inspect, for: Pgvector do
  import Inspect.Algebra

  def inspect(vector, opts) do
    concat(["Pgvector.new(", Inspect.List.inspect(Pgvector.to_list(vector), opts), ")"])
  end
end
