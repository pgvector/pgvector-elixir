defmodule Pgvector.Vector do
  defstruct [:data]
end

defimpl Inspect, for: Pgvector.Vector do
  import Inspect.Algebra

  def inspect(vec, opts) do
    concat(["Vector(", Inspect.List.inspect(Pgvector.to_list(vec), opts), ")"])
  end
end
