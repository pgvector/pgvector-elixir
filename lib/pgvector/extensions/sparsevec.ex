defmodule Pgvector.Extensions.Sparsevec do
  import Postgrex.BinaryUtils, warn: false

  def init(opts), do: Keyword.get(opts, :decode_binary, :copy)

  def matching(_), do: [type: "sparsevec"]

  def format(_), do: :binary

  def encode(_) do
    quote do
      vec ->
        data = vec |> Pgvector.SparseVector.new() |> Pgvector.to_binary()
        [<<IO.iodata_length(data)::int32()>> | data]
    end
  end

  def decode(:copy) do
    quote do
      <<len::int32(), bin::binary-size(len)>> ->
        bin |> :binary.copy() |> Pgvector.SparseVector.from_binary()
    end
  end

  def decode(_) do
    quote do
      <<len::int32(), bin::binary-size(len)>> ->
        bin |> Pgvector.SparseVector.from_binary()
    end
  end
end
