defmodule HalfVectorTest do
  use ExUnit.Case

  test "half vector" do
    vector = Pgvector.HalfVector.new([1, 2, 3])
    assert vector == vector |> Pgvector.HalfVector.new()
  end

  test "list" do
    list = [1.0, 2.0, 3.0]
    assert list == list |> Pgvector.HalfVector.new() |> Pgvector.to_list()
  end

  test "tensor" do
    tensor = Nx.tensor([1.0, 2.0, 3.0], type: :f16)
    assert tensor == tensor |> Pgvector.HalfVector.new() |> Pgvector.to_tensor()
  end

  test "inspect" do
    vector = Pgvector.HalfVector.new([1, 2, 3])
    assert "Pgvector.HalfVector.new([1.0, 2.0, 3.0])" == inspect(vector)
  end

  test "equals" do
    assert Pgvector.HalfVector.new([1, 2, 3]) == Pgvector.HalfVector.new([1, 2, 3])
    refute Pgvector.HalfVector.new([1, 2, 3]) == Pgvector.HalfVector.new([1, 2, 4])
  end
end
