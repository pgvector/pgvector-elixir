Postgrex.Types.define(Example.PostgrexTypes, Pgvector.extensions(), [])

rows = 100_000
dimensions = 128

IO.puts("Generating data")
embeddings = Nx.broadcast(1, {rows, dimensions})

# enable extension
{:ok, pid} = Postgrex.start_link(database: "pgvector_example", types: Example.PostgrexTypes)
Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])

# create table
Postgrex.query!(pid, "DROP TABLE IF EXISTS items", [])
Postgrex.query!(pid, "CREATE TABLE items (id bigserial, embedding vector(#{dimensions}))", [])

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
    # TODO use extension and support other types
    data = value |> Pgvector.to_binary()
    <<IO.iodata_length(data)::unsigned-32, data::binary>>
  end
end

# load data
IO.puts("Loading #{rows} rows")

Postgrex.transaction(
  pid,
  fn conn ->
    stream = Postgrex.stream(conn, "COPY items (embedding) FROM STDIN WITH (FORMAT BINARY)", [])
    rows = Enum.map(embeddings |> Nx.to_list(), fn v -> [v |> Pgvector.new()] end)
    stream |> Example.copy(rows)
  end,
  timeout: 30000
)

IO.puts("Success!")

# create any indexes *after* loading initial data (skipping for this example)
create_index = false

if create_index do
  IO.puts("Creating index")
  Postgrex.query!(pid, "SET maintenance_work_mem = '8GB'", [])
  Postgrex.query!(pid, "SET max_parallel_maintenance_workers = 7", [])
  Postgrex.query!(pid, "CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops)", [])
end

# update planner statistics for good measure
Postgrex.query!(pid, "ANALYZE items", [])
