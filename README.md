# pgvector-elixir

[pgvector](https://github.com/pgvector/pgvector) support for Elixir

Supports [Ecto](https://github.com/elixir-ecto/ecto) and [Postgrex](https://github.com/elixir-ecto/postgrex)

[![Build Status](https://github.com/pgvector/pgvector-elixir/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-elixir/actions)

## Installation

Add this line to your application’s `mix.exs` under `deps`:

```elixir
{:pgvector, "~> 0.3.0"}
```

And follow the instructions for your database library:

- [Ecto](#ecto)
- [Postgrex](#postgrex)

Or check out some examples:

- [Embeddings](https://github.com/pgvector/pgvector-elixir/blob/master/examples/openai/example.exs) with OpenAI
- [Binary embeddings](https://github.com/pgvector/pgvector-elixir/blob/master/examples/cohere/example.exs) with Cohere
- [Sentence embeddings](https://github.com/pgvector/pgvector-elixir/blob/master/examples/bumblebee/example.exs) with Bumblebee
- [Hybrid search](https://github.com/pgvector/pgvector-elixir/blob/master/examples/hybrid_search/example.exs) with Bumblebee (Reciprocal Rank Fusion)
- [Sparse search](https://github.com/pgvector/pgvector-elixir/blob/master/examples/sparse_search/example.exs) with Bumblebee
- [Horizontal scaling](https://github.com/pgvector/pgvector-elixir/blob/master/examples/citus/example.exs) with Citus
- [Bulk loading](https://github.com/pgvector/pgvector-elixir/blob/master/examples/loading/example.exs) with `COPY`

## Ecto

Create `lib/postgrex_types.ex` with:

```elixir
Postgrex.Types.define(MyApp.PostgrexTypes, Pgvector.extensions() ++ Ecto.Adapters.Postgres.extensions(), [])
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

Also supports `:halfvec`, `:bit`, and `:sparsevec`

Update the model

```elixir
schema "items" do
  field :embedding, Pgvector.Ecto.Vector
end
```

Also supports `Pgvector.Ecto.HalfVector`, `Pgvector.Ecto.Bit`, and `Pgvector.Ecto.SparseVector`

Insert a vector

```elixir
alias MyApp.{Repo, Item}

Repo.insert(%Item{embedding: [1, 2, 3]})
```

Get the nearest neighbors

```elixir
import Ecto.Query
import Pgvector.Ecto.Query

Repo.all(from i in Item, order_by: l2_distance(i.embedding, ^Pgvector.new([1, 2, 3])), limit: 5)
```

Also supports `max_inner_product`, `cosine_distance` (and it's complement `cosine_similarity`), `l1_distance`, `hamming_distance`, and `jaccard_distance`

Convert a vector to a list or Nx tensor

```elixir
item.embedding |> Pgvector.to_list()
item.embedding |> Pgvector.to_tensor()
```

Add an approximate index in a migration

```elixir
create index("items", ["embedding vector_l2_ops"], using: :hnsw)
# or
create index("items", ["embedding vector_l2_ops"], using: :ivfflat, options: "lists = 100")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance and cosine similarity

## Postgrex

[Register](https://github.com/elixir-ecto/postgrex#extensions) the extension

```elixir
Postgrex.Types.define(MyApp.PostgrexTypes, Pgvector.extensions(), [])
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
Postgrex.query!(pid, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)", [])
# or
Postgrex.query!(pid, "CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)", [])
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance and cosine similarity

## Reference

### Vectors

Create a vector from a list

```elixir
vec = Pgvector.new([1, 2, 3])
```

Or an Nx tensor

```elixir
vec = Nx.tensor([1.0, 2.0, 3.0]) |> Pgvector.new()
```

Get a list

```elixir
list = vec |> Pgvector.to_list()
```

Get an Nx tensor

```elixir
tensor = vec |> Pgvector.to_tensor()
```

### Half Vectors

Create a half vector from a list

```elixir
vec = Pgvector.HalfVector.new([1, 2, 3])
```

Or an Nx tensor

```elixir
vec = Nx.tensor([1.0, 2.0, 3.0], type: :f16) |>  Pgvector.HalfVector.new()
```

Get a list

```elixir
list = vec |> Pgvector.to_list()
```

Get an Nx tensor

```elixir
tensor = vec |> Pgvector.to_tensor()
```

### Sparse Vectors

Create a sparse vector from a list

```elixir
vec = Pgvector.SparseVector.new([1, 2, 3])
```

Or an Nx tensor

```elixir
vec = Nx.tensor([1.0, 2.0, 3.0]) |> Pgvector.SparseVector.new()
```

Or a map of non-zero elements

```elixir
elements = %{0 => 1.0, 2 => 2.0, 4 => 3.0}
vec = Pgvector.SparseVector.new(elements, 6)
```

Note: Indices start at 0

Get the number of dimensions

```elixir
dim = vec |> Pgvector.SparseVector.dimensions()
```

Get the indices of non-zero elements

```elixir
indices = vec |> Pgvector.SparseVector.indices()
```

Get the values of non-zero elements

```elixir
values = vec |> Pgvector.SparseVector.values()
```

Get a list

```elixir
list = vec |> Pgvector.to_list()
```

Get an Nx tensor

```elixir
tensor = vec |> Pgvector.to_tensor()
```

## Upgrading

### 0.3.0

Lists must be converted to `Pgvector` structs for Ecto distance functions.

```elixir
# before
l2_distance(i.embedding, [1, 2, 3])

# after
l2_distance(i.embedding, ^Pgvector.new([1, 2, 3]))
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

To run an example:

```sh
cd examples/loading
mix deps.get
createdb pgvector_example
mix run example.exs
```
