defmodule Pgvector.Vector do
  import Postgrex.BinaryUtils, warn: false

  def init(opts), do: Keyword.get(opts, :decode_binary, :copy)

  def matching(_), do: [type: "vector"]

  def format(_), do: :binary

  def encode(_) do
    quote do
      vec when is_list(vec) ->
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

  def encode_vector(vec) do
    dim = length(vec)
    bin = Enum.map(vec, fn v -> <<v::float32>> end)
    [<<dim::uint16>>, <<0::uint16>> | bin]
  end

  def decode_vector(<<dim::uint16, 0::uint16, bin::binary-size(dim)-unit(32)>>) do
    for <<v::float32 <- bin>>, do: v
  end
end

Postgrex.Types.define(MyApp.PostgrexTypes, [Pgvector.Vector], [])

{:ok, pid} = Postgrex.start_link(hostname: "localhost", database: "pgvector_elixir_test", types: MyApp.PostgrexTypes)

Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
Postgrex.query!(pid, "DROP TABLE IF EXISTS items", [])
Postgrex.query!(pid, "CREATE TABLE items (id bigserial primary key, factors vector(3))", [])

Postgrex.query!(pid, "INSERT INTO items (factors) VALUES ($1), ($2), ($3)", [[1,1,1], [2,2,2], [1,1,2]])

result = Postgrex.query!(pid, "SELECT * FROM items ORDER BY factors <-> $1 LIMIT 5", [[1,1,1]])

IO.inspect(result)
