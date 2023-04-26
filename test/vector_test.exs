defmodule VectorTest do
  use ExUnit.Case

  test "list" do
    list = [1.0, 2.0, 3.0]
    assert list == (list |> Pgvector.vector() |> Pgvector.to_list())
  end

  test "tensor" do
    tensor = Nx.tensor([1.0, 2.0, 3.0])
    assert tensor == (tensor |> Pgvector.vector() |> Pgvector.to_tensor())
  end

  test "inspect" do
    vector = Pgvector.vector([1, 2, 3])
    assert "Vector([1.0, 2.0, 3.0])" == inspect(vector)
  end
end
