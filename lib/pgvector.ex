defmodule Pgvector do
  defstruct [:data]

  def new(binary) when is_binary(binary) do
    %Pgvector{data: binary}
  end

  def new(list) when is_list(list) do
    dim = list |> length()
    bin = for v <- list, into: "", do: <<v::float-32>>
    data = <<dim::unsigned-16, 0::unsigned-16, bin::binary>>
    new(data)
  end

  if Code.ensure_loaded?(Nx) do
    def new(t) when is_struct(t, Nx.Tensor) do
      if Nx.rank(t) != 1 do
        raise ArgumentError, "expected rank to be 1"
      end
      dim = t |> Nx.size()
      bin = t |> Nx.as_type(:f32) |> Nx.to_binary() |> f32_native_to_big()
      data = <<dim::unsigned-16, 0::unsigned-16, bin::binary>>
      new(data)
    end

    defp f32_native_to_big(binary) do
      if System.endianness() == :big do
        binary
      else
        for <<n::float-32-little <- binary>>, into: "", do: <<n::float-32-big>>
      end
    end
  end

  def to_binary(vector) when is_struct(vector, Pgvector) do
    vector.data
  end

  def to_list(vector) when is_struct(vector, Pgvector) do
    <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(32)>> = vector.data
    for <<v::float-32 <- bin>>, do: v
  end

  if Code.ensure_loaded?(Nx) do
    def to_tensor(vector) when is_struct(vector, Pgvector) do
      <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(32)>> = vector.data
      bin |> f32_big_to_native() |> Nx.from_binary(:f32)
    end

    defp f32_big_to_native(binary) do
      if System.endianness() == :big do
        binary
      else
        for <<n::float-32-big <- binary>>, into: "", do: <<n::float-32-little>>
      end
    end
  end
end

defimpl Inspect, for: Pgvector do
  import Inspect.Algebra

  def inspect(vec, opts) do
    concat(["Pgvector.new(", Inspect.List.inspect(Pgvector.to_list(vec), opts), ")"])
  end
end
