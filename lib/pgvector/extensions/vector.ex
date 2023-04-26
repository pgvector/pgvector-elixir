defmodule Pgvector.Extensions.Vector do
  import Postgrex.BinaryUtils, warn: false

  def init(opts), do: Keyword.get(opts, :decode_binary, :copy)

  def matching(_), do: [type: "vector"]

  def format(_), do: :binary

  def encode(_) do
    quote do
      vec ->
        data = unquote(__MODULE__).encode_vector(vec)
        [<<IO.iodata_length(data)::int32()>> | data]
    end
  end

  def decode(_) do
    quote do
      <<_len::int32(), dim::uint16, 0::uint16, bin::binary-size(dim)-unit(32)>> ->
        for <<v::float32 <- bin>>, do: v
    end
  end

  def encode_vector(list) when is_list(list) do
    dim = list |> length()
    bin = for v <- list, into: "", do: <<v::float32>>
    [<<dim::uint16, 0::uint16>> | bin]
  end

  if Code.ensure_loaded?(Nx) do
    def encode_vector(tensor) when is_struct(tensor, Nx.Tensor) do
      if Nx.rank(tensor) != 1 do
        raise ArgumentError, "expected rank to be 1"
      end
      dim = tensor |> Nx.size()
      bin = tensor |> Nx.as_type(:f32) |> Nx.to_binary() |> f32_native_to_big()
      [<<dim::uint16, 0::uint16>> | bin]
    end

    defp f32_native_to_big(bin) do
      if System.endianness() == :big do
        bin
      else
        for <<n::float-32-little <- bin>>, into: "", do: <<n::float-32-big>>
      end
    end
  end
end
