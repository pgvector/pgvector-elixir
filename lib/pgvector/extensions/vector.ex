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
      <<len::int32(), data::binary-size(len)>> ->
        unquote(__MODULE__).decode_vector(data)
    end
  end

  def encode_vector(vec) when is_list(vec) do
    dim = vec |> length()
    bin = for v <- vec, do: <<v::float32>>
    [<<dim::uint16, 0::uint16>> | bin]
  end

  if Code.ensure_loaded?(Nx) do
    def encode_vector(t) when is_struct(t, Nx.Tensor) do
      if Nx.rank(t) != 1 do
        raise ArgumentError, "expected rank to be 1"
      end
      dim = t |> Nx.size()
      bin = t |> Nx.as_type(:f32) |> Nx.to_binary() |> f32_to_big()
      [<<dim::uint16, 0::uint16>> | bin]
    end

    defp f32_to_big(bin) do
      if System.endianness() == :big do
        bin
      else
        for <<n::float-32-little <- bin>>, do: <<n::float-32-big>>
      end
    end
  end

  def decode_vector(<<dim::uint16, 0::uint16, bin::binary-size(dim)-unit(32)>>) do
    for <<v::float32 <- bin>>, do: v
  end
end
