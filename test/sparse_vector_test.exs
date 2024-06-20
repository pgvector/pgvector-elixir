defmodule SparseVectorTest do
  use ExUnit.Case

  test "sparse vector" do
    vector = Pgvector.SparseVector.new([1, 2, 3])
    assert vector == vector |> Pgvector.SparseVector.new()
  end

  test "list" do
    list = [1.0, 2.0, 3.0]
    assert list == list |> Pgvector.SparseVector.new() |> Pgvector.to_list()
  end

  test "tensor" do
    tensor = Nx.tensor([1.0, 2.0, 3.0], type: :f32)
    assert tensor == tensor |> Pgvector.SparseVector.new() |> Pgvector.to_tensor()
  end

  test "inspect" do
    vector = Pgvector.SparseVector.new([1, 2, 3])
    assert "Pgvector.SparseVector.new([1.0, 2.0, 3.0])" == inspect(vector)
  end

  test "equals" do
    assert Pgvector.SparseVector.new([1, 2, 3]) == Pgvector.SparseVector.new([1, 2, 3])
    refute Pgvector.SparseVector.new([1, 2, 3]) == Pgvector.SparseVector.new([1, 2, 4])
  end
end