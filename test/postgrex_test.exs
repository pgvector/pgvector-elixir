Postgrex.Types.define(PostgrexApp.PostgrexTypes, Pgvector.extensions(), [])

# needed if postgrex is optional
# Application.ensure_all_started(:postgrex)

defmodule PostgrexTest do
  use ExUnit.Case

  setup_all do
    {:ok, pid} = Postgrex.start_link(database: "pgvector_elixir_test", types: PostgrexApp.PostgrexTypes)
    Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
    Postgrex.query!(pid, "DROP TABLE IF EXISTS postgrex_items", [])
    Postgrex.query!(pid, "CREATE TABLE postgrex_items (id bigserial primary key, embedding vector(3), half_embedding halfvec(3), binary_embedding bit(3))", [])
    {:ok, pid: pid}
  end

  setup context do
    Postgrex.query!(context[:pid], "TRUNCATE postgrex_items RESTART IDENTITY", [])
    context
  end

  test "vector l2 distance", %{pid: pid} = _context do
    embeddings = [Pgvector.new([1, 1, 1]), [2, 2, 2], Nx.tensor([1, 1, 2], type: :f32)]
    Postgrex.query!(pid, "INSERT INTO postgrex_items (embedding) VALUES ($1), ($2), ($3)", embeddings)

    result = Postgrex.query!(pid, "SELECT id, embedding FROM postgrex_items ORDER BY embedding <-> $1 LIMIT 5", [[1, 1, 1]])

    assert ["id", "embedding"] == result.columns
    assert Enum.map(result.rows, fn v -> Enum.at(v, 0) end) == [1, 3, 2]
    assert Enum.map(result.rows, fn v -> Enum.at(v, 1) |> Pgvector.to_list() end) == [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [2.0, 2.0, 2.0]]
  end

  test "halfvec l2 distance", %{pid: pid} = _context do
    embeddings = [Pgvector.HalfVector.new([1, 1, 1]), [2, 2, 2], Nx.tensor([1, 1, 2], type: :f16)]
    Postgrex.query!(pid, "INSERT INTO postgrex_items (half_embedding) VALUES ($1), ($2), ($3)", embeddings)

    result = Postgrex.query!(pid, "SELECT id, half_embedding FROM postgrex_items ORDER BY half_embedding <-> $1 LIMIT 5", [[1, 1, 1]])

    assert ["id", "half_embedding"] == result.columns
    assert Enum.map(result.rows, fn v -> Enum.at(v, 0) end) == [1, 3, 2]
    assert Enum.map(result.rows, fn v -> Enum.at(v, 1) |> Pgvector.to_list() end) == [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [2.0, 2.0, 2.0]]
  end

  test "create index", %{pid: pid} = _context do
    Postgrex.query!(pid, "CREATE INDEX my_index ON postgrex_items USING ivfflat (embedding vector_l2_ops) WITH (lists = 1)", [])
  end

  test "copy", %{pid: pid} = _context do
    Postgrex.transaction(pid, fn(conn) ->
      data = Pgvector.new([1, 2, 3]) |> Pgvector.to_binary()
      # https://www.postgresql.org/docs/current/sql-copy.html
      signature = "PGCOPY\n\xFF\r\n\0"
      stream = Postgrex.stream(conn, "COPY postgrex_items (embedding) FROM STDIN WITH (FORMAT BINARY)", [])
      Enum.into([<<signature::binary, 0::unsigned-32, 0::unsigned-32>>, <<1::unsigned-16, IO.iodata_length(data)::unsigned-32, data::binary>>, <<-1::unsigned-16>>], stream)
    end)
  end

  test "tensor", %{pid: pid} = _context do
    embedding = Nx.tensor([1.0, 2.0, 3.0])
    result = Postgrex.query!(pid, "SELECT $1::vector", [embedding])
    assert result.rows == [[embedding |> Pgvector.new()]]
  end

  test "tensor rank", %{pid: pid} = _context do
    assert_raise ArgumentError, "expected rank to be 1", fn ->
      Postgrex.query!(pid, "SELECT $1::vector", [Nx.tensor([[1, 2, 3]])])
    end
  end

  test "hamming distance", %{pid: pid} = _context do
    embeddings = [<<0::1, 0::1, 0::1>>, <<1::1, 1::1, 1::1>>, <<1::1, 0::1, 1::1>>]
    Postgrex.query!(pid, "INSERT INTO postgrex_items (binary_embedding) VALUES ($1), ($2), ($3)", embeddings)

    result = Postgrex.query!(pid, "SELECT id, binary_embedding FROM postgrex_items ORDER BY bit_count(binary_embedding # $1) LIMIT 5", [<<0::1, 0::1, 0::1>>])
    assert Enum.map(result.rows, fn v -> Enum.at(v, 0) end) == [1, 3, 2]
    assert Enum.map(result.rows, fn v -> Enum.at(v, 1) end) == [<<0::1, 0::1, 0::1>>, <<1::1, 0::1, 1::1>>, <<1::1, 1::1, 1::1>>]
  end
end
