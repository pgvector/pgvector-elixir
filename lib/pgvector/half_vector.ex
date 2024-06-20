defmodule Pgvector.HalfVector do
  @moduledoc """
  A half vector struct for pgvector
  """

  defstruct [:data]

  @doc """
  Creates a new half vector from a list, tensor, or half vector
  """
  def new(list) when is_list(list) do
    dim = list |> length()
    bin = for v <- list, into: "", do: <<v::float-16>>
    from_binary(<<dim::unsigned-16, 0::unsigned-16, bin::binary>>)
  end

  def new(%Pgvector.HalfVector{} = vector) do
    vector
  end

  if Code.ensure_loaded?(Nx) do
    def new(tensor) when is_struct(tensor, Nx.Tensor) do
      if Nx.rank(tensor) != 1 do
        raise ArgumentError, "expected rank to be 1"
      end

      dim = tensor |> Nx.size()
      bin = tensor |> Nx.as_type(:f16) |> Nx.to_binary() |> f16_native_to_big()
      from_binary(<<dim::unsigned-16, 0::unsigned-16, bin::binary>>)
    end

    defp f16_native_to_big(binary) do
      if System.endianness() == :big do
        binary
      else
        for <<n::float-16-little <- binary>>, into: "", do: <<n::float-16-big>>
      end
    end
  end

  @doc """
  Creates a new half vector from its binary representation
  """
  def from_binary(binary) when is_binary(binary) do
    %Pgvector.HalfVector{data: binary}
  end
end

defimpl Inspect, for: Pgvector.HalfVector do
  import Inspect.Algebra

  def inspect(vector, opts) do
    concat(["Pgvector.HalfVector.new(", Inspect.List.inspect(Pgvector.to_list(vector), opts), ")"])
  end
end
