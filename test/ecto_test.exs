defmodule Item do
  use Ecto.Schema

  schema "ecto_items" do
    field :embedding, Pgvector.Ecto.Vector
    field :half_embedding, Pgvector.Ecto.HalfVector
  end
end

defmodule EctoTest do
  use ExUnit.Case

  import Ecto.Query
  import Pgvector.Ecto.Query

  setup_all do
    Ecto.Adapters.SQL.query!(Repo, "CREATE EXTENSION IF NOT EXISTS vector", [])
    Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS ecto_items", [])
    Ecto.Adapters.SQL.query!(Repo, "CREATE TABLE ecto_items (id bigserial primary key, embedding vector(3), half_embedding halfvec(3))", [])
    create_items()
    :ok
  end

  defp create_items do
    Repo.insert(%Item{embedding: Pgvector.new([1, 1, 1]), half_embedding: Pgvector.HalfVector.new([1, 1, 1])})
    Repo.insert(%Item{embedding: [2, 2, 3], half_embedding: [2, 2, 3]})
    Repo.insert(%Item{embedding: Nx.tensor([1, 1, 2], type: :f32), half_embedding: Nx.tensor([1, 1, 2], type: :f16)})
  end

  test "vector l2 distance" do
    items = Repo.all(from i in Item, order_by: l2_distance(i.embedding, [1, 1, 1]), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 3, 2]
    assert Enum.map(items, fn v -> v.embedding |> Pgvector.to_list() end) == [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [2.0, 2.0, 3.0]]
  end

  test "vector max inner product" do
    items = Repo.all(from i in Item, order_by: max_inner_product(i.embedding, [1, 1, 1]), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [2, 3, 1]
  end

  test "vector cosine distance" do
    items = Repo.all(from i in Item, order_by: cosine_distance(i.embedding, [1, 1, 1]), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 2, 3]
  end

  test "vector cosine similarity" do
    items = Repo.all(from i in Item, order_by: (1 - cosine_distance(i.embedding, [1, 1, 1])), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [3, 2, 1]
  end

  test "vector l1 distance" do
    items = Repo.all(from i in Item, order_by: l1_distance(i.embedding, [1, 1, 1]), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 3, 2]
  end

  test "halfvec l2 distance" do
    items = Repo.all(from i in Item, order_by: l2_distance(i.half_embedding, Pgvector.HalfVector.new([1, 1, 1])), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 3, 2]
    assert Enum.map(items, fn v -> v.half_embedding |> Pgvector.to_list() end) == [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [2.0, 2.0, 3.0]]
  end

  test "halfvec max inner product" do
    items = Repo.all(from i in Item, order_by: max_inner_product(i.half_embedding, Pgvector.HalfVector.new([1, 1, 1])), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [2, 3, 1]
  end

  test "halfvec cosine distance" do
    items = Repo.all(from i in Item, order_by: cosine_distance(i.half_embedding, Pgvector.HalfVector.new([1, 1, 1])), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 2, 3]
  end

  test "halfvec cosine similarity" do
    items = Repo.all(from i in Item, order_by: (1 - cosine_distance(i.half_embedding, Pgvector.HalfVector.new([1, 1, 1]))), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [3, 2, 1]
  end

  test "halfvec l1 distance" do
    items = Repo.all(from i in Item, order_by: l1_distance(i.half_embedding, Pgvector.HalfVector.new([1, 1, 1])), limit: 5)
    assert Enum.map(items, fn v -> v.id end) == [1, 3, 2]
  end

  test "cast" do
    embedding = [1, 1, 1]
    items = Repo.all(from i in Item, where: i.embedding == ^embedding)
    assert Enum.map(items, fn v -> v.id end) == [1]
  end
end
