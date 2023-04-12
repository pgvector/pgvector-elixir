Postgrex.Types.define(PostgrexApp.PostgrexTypes, [Pgvector.Extensions.Vector], [])

# needed if postgrex is optional
# Application.ensure_all_started(:postgrex)

defmodule PostgrexTest do
  use ExUnit.Case

  test "works" do
    {:ok, pid} = Postgrex.start_link(database: "pgvector_elixir_test", types: PostgrexApp.PostgrexTypes)

    Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
    Postgrex.query!(pid, "DROP TABLE IF EXISTS items", [])
    Postgrex.query!(pid, "CREATE TABLE items (id bigserial primary key, embedding vector(3))", [])

    Postgrex.query!(pid, "INSERT INTO items (embedding) VALUES ($1), ($2), ($3)", [[1, 1, 1], [2, 2, 2], Nx.tensor([1, 1, 2], type: :f32)])

    result = Postgrex.query!(pid, "SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", [[1, 1, 1]])

    assert ["id", "embedding"] == result.columns
    assert Enum.map(result.rows, fn v -> Enum.at(v, 0) end) == [1, 3, 2]
    assert Enum.map(result.rows, fn v -> Enum.at(v, 1) end) == [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [2.0, 2.0, 2.0]]

    Postgrex.query!(pid, "CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)", [])
  end
end
