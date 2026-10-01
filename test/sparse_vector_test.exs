defmodule SparseVectorTest do
  use ExUnit.Case

  test "sparse vector" do
    vector = Pgvector.SparseVector.new([1, 0, 2, 0, 3, 0])
    assert vector == vector |> Pgvector.SparseVector.new()
  end

  test "list" do
    list = [1.0, 0.0, 2.0, 0.0, 3.0, 0.0]
    assert list == list |> Pgvector.SparseVector.new() |> Pgvector.to_list()
  end

  test "tensor" do
    tensor = Nx.tensor([1.0, 0.0, 2.0, 0.0, 3.0, 0.0], type: :f32)
    assert tensor == tensor |> Pgvector.SparseVector.new() |> Pgvector.to_tensor()
  end

  test "to_list with non-zero at last index" do
    assert [0.0, 0.0, 1.5] == Pgvector.SparseVector.new(%{2 => 1.5}, 3) |> Pgvector.to_list()
  end

  test "to_list with zero dimensions" do
    assert [] == Pgvector.SparseVector.new(%{}, 0) |> Pgvector.to_list()
  end

  test "to_list with no non-zero elements" do
    assert [0.0, 0.0, 0.0] == Pgvector.SparseVector.new(%{}, 3) |> Pgvector.to_list()
  end

  test "to_tensor with non-zero at last index" do
    tensor = Pgvector.SparseVector.new(%{2 => 1.5}, 3) |> Pgvector.to_tensor()
    assert Nx.tensor([0.0, 0.0, 1.5], type: :f32) == tensor
  end

  test "map" do
    map = %{2 => 2.0, 4 => 3.0, 0 => 1.0, 3 => 0.0}
    vector = Pgvector.SparseVector.new(map, 6)
    assert [1.0, 0.0, 2.0, 0.0, 3.0, 0.0] == vector |> Pgvector.to_list()
    assert [0, 2, 4] == vector |> Pgvector.SparseVector.indices()
  end

  test "dimensions" do
    vector = Pgvector.SparseVector.new([1, 0, 2, 0, 3, 0])
    assert 6 == vector |> Pgvector.SparseVector.dimensions()
  end

  test "indices" do
    vector = Pgvector.SparseVector.new([1, 0, 2, 0, 3, 0])
    assert [0, 2, 4] == vector |> Pgvector.SparseVector.indices()
  end

  test "values" do
    vector = Pgvector.SparseVector.new([1, 0, 2, 0, 3, 0])
    assert [1.0, 2.0, 3.0] == vector |> Pgvector.SparseVector.values()
  end

  test "inspect" do
    vector = Pgvector.SparseVector.new([1, 0, 2, 0, 3, 0])
    assert "Pgvector.SparseVector.new(%{0 => 1.0, 2 => 2.0, 4 => 3.0}, 6)" == inspect(vector)
  end

  test "equals" do
    assert Pgvector.SparseVector.new([1, 2, 3]) == Pgvector.SparseVector.new([1, 2, 3])
    refute Pgvector.SparseVector.new([1, 2, 3]) == Pgvector.SparseVector.new([1, 2, 4])
  end
end
