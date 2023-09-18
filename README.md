# pgvector-elixir

[pgvector](https://github.com/pgvector/pgvector) support for Elixir

Supports [Ecto](https://github.com/elixir-ecto/ecto) and [Postgrex](https://github.com/elixir-ecto/postgrex)

[![Build Status](https://github.com/pgvector/pgvector-elixir/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-elixir/actions)

## Installation

Add this line to your application’s `mix.exs` under `deps`:

```elixir
{:pgvector, "~> 0.2.0"}
```

And follow the instructions for your database library:

- [Ecto](#ecto)
- [Postgrex](#postgrex)

Or check out an example:

- [Embeddings](examples/openai/example.exs) with OpenAI

## Ecto

Create `lib/postgrex_types.ex` with:

```elixir
Postgrex.Types.define(MyApp.PostgrexTypes, [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions(), [])
```

And add to `config/config.exs`:

```elixir
config :my_app, MyApp.Repo, types: MyApp.PostgrexTypes
```

Create a migration

```sh
mix ecto.gen.migration create_vector_extension
```

with:

```elixir
defmodule MyApp.Repo.Migrations.CreateVectorExtension do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS vector"
  end

  def down do
    execute "DROP EXTENSION vector"
  end
end
```

Run the migration

```sh
mix ecto.migrate
```

You can now use the `vector` type in future migrations

```elixir
create table(:items) do
  add :embedding, :vector, size: 3
end
```

Update the model

```elixir
schema "items" do
  field :embedding, Pgvector.Ecto.Vector
end
```

Insert a vector

```elixir
alias MyApp.{Repo, Item}

Repo.insert(%Item{embedding: [1, 2, 3]})
```

Get the nearest neighbors

```elixir
import Ecto.Query
import Pgvector.Ecto.Query

Repo.all(from i in Item, order_by: l2_distance(i.embedding, [1, 2, 3]), limit: 5)
```

Also supports `max_inner_product` and `cosine_distance`

Convert a vector to a list or Nx tensor

```elixir
item.embedding |> Pgvector.to_list()
item.embedding |> Pgvector.to_tensor()
```

Add an approximate index in a migration

```elixir
create index("items", ["embedding vector_l2_ops"], using: :ivfflat)
# or
create index("items", ["embedding vector_l2_ops"], using: :hnsw)
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

## Postgrex

[Register](https://github.com/elixir-ecto/postgrex#extensions) the extension

```elixir
Postgrex.Types.define(MyApp.PostgrexTypes, [Pgvector.Extensions.Vector], [])
```

And pass it to `start_link`

```elixir
{:ok, pid} = Postgrex.start_link(types: MyApp.PostgrexTypes)
```

Enable the extension

```elixir
Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
```

Create a table

```elixir
Postgrex.query!(pid, "CREATE TABLE items (embedding vector(3))", [])
```

Insert a vector

```elixir
Postgrex.query!(pid, "INSERT INTO items (embedding) VALUES ($1)", [[1, 2, 3]])
```

Get the nearest neighbors

```elixir
Postgrex.query!(pid, "SELECT * FROM items ORDER BY embedding <-> $1 LIMIT 5", [[1, 2, 3]])
```

Convert a vector to a list or Nx tensor

```elixir
vector |> Pgvector.to_list()
vector |> Pgvector.to_tensor()
```

Add an approximate index

```elixir
Postgrex.query!(pid, "CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)", [])
# or
Postgrex.query!(pid, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)", [])
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

## Upgrading

### 0.2.0

Vectors are now returned as `Pgvector` structs instead of lists. Get a list with:

```elixir
vector |> Pgvector.to_list()
```

or an Nx tensor with:

```elixir
vector |> Pgvector.to_tensor()
```

## History

View the [changelog](https://github.com/pgvector/pgvector-elixir/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-elixir/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-elixir/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-elixir.git
cd pgvector-elixir
mix deps.get
createdb pgvector_elixir_test
mix test
```
