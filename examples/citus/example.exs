Postgrex.Types.define(Example.PostgrexTypes, Pgvector.extensions(), [])

rows = 100_000
dimensions = 128

IO.puts("Generating data")

key = Nx.Random.key(42)
embeddings = Nx.iota({rows, dimensions})
{categories, new_key} = Nx.Random.randint(key, 1, 100, shape: {rows})
{queries, _new_key} = Nx.Random.choice(new_key, embeddings, samples: 10, axis: 0)

# enable extensions
{:ok, pid} = Postgrex.start_link(database: "pgvector_citus", types: Example.PostgrexTypes)
Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS citus", [])
Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])

# GUC variables set on the session do not propagate to Citus workers
# https://github.com/citusdata/citus/issues/462
# you can either:
# 1. set them on the system, user, or database and reconnect
# 2. set them for a transaction with SET LOCAL
Postgrex.query!(pid, "ALTER DATABASE pgvector_citus SET maintenance_work_mem = '512MB'", [])
Postgrex.query!(pid, "ALTER DATABASE pgvector_citus SET hnsw.ef_search = 20", [])
# TODO close connection

# reconnect for updated GUC variables to take effect
{:ok, pid} = Postgrex.start_link(database: "pgvector_citus", types: Example.PostgrexTypes)

IO.puts("Creating distributed table")

Postgrex.query!(pid, "DROP TABLE IF EXISTS items", [])

Postgrex.query!(
  pid,
  "CREATE TABLE items (id bigserial, embedding vector(#{dimensions}), category_id bigint, PRIMARY KEY (id, category_id))",
  []
)

Postgrex.query!(pid, "SET citus.shard_count = 4", [])
Postgrex.query!(pid, "SELECT create_distributed_table('items', 'category_id')", [])

defmodule Example do
  # https://www.postgresql.org/docs/current/sql-copy.html
  def copy(stream, rows) do
    signature = "PGCOPY\n\xFF\r\n\0"

    Enum.into(
      [
        <<signature::binary, 0::unsigned-32, 0::unsigned-32>>,
        Enum.map(rows, &copy_row(&1)),
        <<-1::unsigned-16>>
      ],
      stream
    )
  end

  defp copy_row(row) do
    count = row |> length()
    data = Enum.join(Enum.map(row, &copy_value(&1)))
    <<count::unsigned-16, data::binary>>
  end

  defp copy_value(value) when is_struct(value, Pgvector) do
    data = value |> Pgvector.to_binary()
    <<IO.iodata_length(data)::unsigned-32, data::binary>>
  end

  defp copy_value(value) when is_integer(value) do
    <<8::unsigned-32, value::64>>
  end
end

IO.puts("Loading data in parallel")

Postgrex.transaction(
  pid,
  fn conn ->
    stream =
      Postgrex.stream(
        conn,
        "COPY items (embedding, category_id) FROM STDIN WITH (FORMAT BINARY)",
        []
      )

    rows =
      Enum.map(Enum.zip(embeddings |> Nx.to_list(), categories |> Nx.to_list()), fn {v, c} ->
        [v |> Pgvector.new(), c]
      end)

    stream |> Example.copy(rows)
  end,
  timeout: 30000
)

IO.puts("Creating index in parallel")

Postgrex.query!(pid, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)", [])

IO.puts("Running distributed queries")

for query <- Nx.to_list(queries) do
  result =
    Postgrex.query!(pid, "SELECT id FROM items ORDER BY embedding <-> $1 LIMIT 10", [
      query |> Pgvector.new()
    ])

  IO.inspect(Enum.map(result.rows, fn v -> List.first(v) end))
end
