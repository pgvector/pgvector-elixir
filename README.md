# pgvector-elixir

[pgvector](https://github.com/pgvector/pgvector) support for Elixir

Supports [Ecto](https://github.com/elixir-ecto/ecto) and [Postgrex](https://github.com/elixir-ecto/postgrex)

[![Build Status](https://github.com/pgvector/pgvector-elixir/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-elixir/actions)

## Getting Started

Follow the instructions for your database library:

- [Ecto](#ecto)
- [Postgrex](#postgrex)

## Ecto

Create a migration

```sh
mix ecto.gen.migration create_vector_extension
```

with:

```elixir
defmodule App.Repo.Migrations.CreateVectorExtension do
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
  add :factors, :vector, size: 3
end
```

Insert a vector

```elixir
Ecto.Adapters.SQL.query!(App.Repo, "INSERT INTO items (factors) VALUES ('[1,2,3]')")
```

Get the nearest neighbors

```elixir
import Ecto.Query

App.Repo.all(from i in "items", order_by: fragment("factors <-> ?", "[1,2,3]"), limit: 5, select: i.id)
```

Add an approximate index in a migration

```elixir
create index("items", ["factors vector_l2_ops"], using: :ivfflat)
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

## Postgrex

Add this line to your application’s `mix.exs` under `deps`:

```elixir
{:pgvector, "~> 0.1"}
```

[Register](https://github.com/elixir-ecto/postgrex#extensions) the extension

```elixir
Postgrex.Types.define(MyApp.PostgrexTypes, [Pgvector.Extensions.Vector], [])
```

And pass it to `start_link`

```elixir
{:ok, pid} = Postgrex.start_link(types: MyApp.PostgrexTypes)
```

Create a table

```elixir
Postgrex.query!(pid, "CREATE TABLE items (factors vector(3))", [])
```

Insert a vector

```elixir
Postgrex.query!(pid, "INSERT INTO items (factors) VALUES ($1)", [[1, 2, 3]])
```

Get the nearest neighbors

```elixir
Postgrex.query!(pid, "SELECT * FROM items ORDER BY factors <-> $1 LIMIT 5", [[1, 2, 3]])
```

Add an approximate index

```elixir
Postgrex.query!(pid, "CREATE INDEX my_index ON items USING ivfflat (factors vector_l2_ops)")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

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
