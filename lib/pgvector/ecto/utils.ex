# TODO improve pattern
defmodule Pgvector.Ecto.Utils do
  @moduledoc false

  def to_sql(vector) when is_struct(vector, Pgvector.HalfVector) do
    vector
  end

  def to_sql(vector) when is_struct(vector, Pgvector.SparseVector) do
    vector
  end

  def to_sql(vector) do
    vector |> Pgvector.new()
  end

  def to_bit_sql(vector) when is_bitstring(vector) do
    vector
  end
end
