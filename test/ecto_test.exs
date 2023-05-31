Postgrex.Types.define(EctoApp.PostgrexTypes, [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions(), [])

defmodule Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres
end

defmodule Item do
  use Ecto.Schema

  schema "items" do
    field :embedding, Pgvector.Ecto.Vector
  end
end

defmodule EctoTest do
  use ExUnit.Case

  import Ecto.Query
  import Pgvector.Ecto.Query

  test "works" do
    Repo.start_link(database: "pgvector_elixir_test", types: EctoApp.PostgrexTypes, log: false)

    Ecto.Adapters.SQL.query!(Repo, "CREATE EXTENSION IF NOT EXISTS vector")
    Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS items")
    Ecto.Adapters.SQL.query!(Repo, "CREATE TABLE items (id bigserial primary key, embedding vector(3))")

    Repo.insert(%Item{embedding: [1, 1, 1]})
    Repo.insert(%Item{embedding: [2, 2, 3]})
    Repo.insert(%Item{embedding: Nx.tensor([1, 1, 2], type: :f32)})

    items = Repo.all(from i in Item, order_by: l2_distance(i.embedding, [1, 1, 1]), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 3, 2]
    assert Enum.map(items, fn v -> v.embedding end) == [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [2.0, 2.0, 3.0]]

    items = Repo.all(from i in Item, order_by: max_inner_product(i.embedding, [1, 1, 1]), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [2, 3, 1]

    items = Repo.all(from i in Item, order_by: cosine_distance(i.embedding, [1, 1, 1]), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 2, 3]

    items = Repo.all(from i in Item, order_by: (1 - cosine_distance(i.embedding, [1, 1, 1])), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [3, 2, 1]

    # test cast
    embedding = [1, 1, 1]
    items = Repo.all(from i in Item, where: i.embedding == ^embedding)
    assert Enum.map(items, fn v -> v.id end) == [1]
  end
end
