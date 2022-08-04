{:ok, pid} = Postgrex.start_link(hostname: "localhost", database: "pgvector_elixir_test")

Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
Postgrex.query!(pid, "DROP TABLE IF EXISTS items", [])
Postgrex.query!(pid, "CREATE TABLE items (id bigserial primary key, factors vector(3))", [])

Postgrex.query!(pid, "INSERT INTO items (factors) VALUES ($1::text::vector), ($2::text::vector), ($3::text::vector)", ["[1,1,1]", "[2,2,2]", "[1,1,2]"])

result = Postgrex.query!(pid, "SELECT id FROM items ORDER BY factors <-> $1::text::vector LIMIT 5", ["[1,1,1]"])

IO.inspect(result.rows)
