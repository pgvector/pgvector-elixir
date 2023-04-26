defmodule Pgvector do
  def vector(list) when is_list(list) do
    dim = list |> length()
    bin = Enum.map(list, fn v -> <<v::float-32>> end) |> :erlang.list_to_bitstring()
    data = <<dim::unsigned-16, 0::unsigned-16, bin::binary>>
    %Pgvector.Vector{data: data}
  end

  if Code.ensure_loaded?(Nx) do
    def vector(t) when is_struct(t, Nx.Tensor) do
      if Nx.rank(t) != 1 do
        raise ArgumentError, "expected rank to be 1"
      end
      dim = t |> Nx.size()
      bin = t |> Nx.as_type(:f32) |> Nx.to_binary() |> f32_to_big() |> :erlang.list_to_bitstring()
      data = <<dim::unsigned-16, 0::unsigned-16, bin::binary>>
      %Pgvector.Vector{data: data}
    end

    defp f32_to_big(bin) do
      if System.endianness() == :big do
        bin
      else
        for <<n::float-32-little <- bin>>, do: <<n::float-32-big>>
      end
    end
  end

  def from_binary(binary) when is_binary(binary) do
    %Pgvector.Vector{data: binary}
  end

  def to_binary(vector) when is_struct(vector, Pgvector.Vector) do
    vector.data
  end

  def to_list(vector) when is_struct(vector, Pgvector.Vector) do
    <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(32)>> = vector.data
    for <<v::float-32 <- bin>>, do: v
  end

  if Code.ensure_loaded?(Nx) do
    def to_tensor(vector) when is_struct(vector, Pgvector.Vector) do
      <<dim::unsigned-16, 0::unsigned-16, bin::binary-size(dim)-unit(32)>> = vector.data
      bin |> big_to_f32() |> :erlang.list_to_bitstring() |> Nx.from_binary(:f32)
    end

    defp big_to_f32(bin) do
      if System.endianness() == :big do
        bin
      else
        for <<n::float-32-big <- bin>>, do: <<n::float-32-little>>
      end
    end
  end
end
