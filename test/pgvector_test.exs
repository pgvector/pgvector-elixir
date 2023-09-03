defmodule PgvectorTest do
  use ExUnit.Case

  test "pgvector" do
    pgvector = Pgvector.new([1, 2, 3])
    assert pgvector == pgvector |> Pgvector.new()
  end

  test "list" do
    list = [1.0, 2.0, 3.0]
    assert list == list |> Pgvector.new() |> Pgvector.to_list()
  end

  test "tensor" do
    tensor = Nx.tensor([1.0, 2.0, 3.0])
    assert tensor == tensor |> Pgvector.new() |> Pgvector.to_tensor()
  end

  test "inspect" do
    vector = Pgvector.new([1, 2, 3])
    assert "Pgvector.new([1.0, 2.0, 3.0])" == inspect(vector)
  end

  test "equals" do
    assert Pgvector.new([1, 2, 3]) == Pgvector.new([1, 2, 3])
    refute Pgvector.new([1, 2, 3]) == Pgvector.new([1, 2, 4])
  end
end
