# pgvector-elixir

[pgvector](https://github.com/pgvector/pgvector-elixir) examples for Elixir

## Getting Started

Follow the instructions for your database library:

- [Ecto](#ecto)

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
```
