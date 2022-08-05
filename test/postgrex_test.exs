defmodule PostgrexTest do
  use ExUnit.Case

  test "works" do
    {:ok, pid} = Postgrex.start_link(hostname: "localhost", database: "pgvector_elixir_test", types: TestApp.PostgrexTypes)

    Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
    Postgrex.query!(pid, "DROP TABLE IF EXISTS items", [])
    Postgrex.query!(pid, "CREATE TABLE items (id bigserial primary key, factors vector(3))", [])

    Postgrex.query!(pid, "INSERT INTO items (factors) VALUES ($1), ($2), ($3)", [[1, 1, 1], [2, 2, 2], [1, 1, 2]])

    result = Postgrex.query!(pid, "SELECT * FROM items ORDER BY factors <-> $1 LIMIT 5", [[1, 1, 1]])

    assert ["id", "factors"] == result.columns
    assert Enum.map(result.rows, fn v -> Enum.at(v, 0) end) == [1, 3, 2]
    assert Enum.map(result.rows, fn v -> Enum.at(v, 1) end) == [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [2.0, 2.0, 2.0]]
  end
end
