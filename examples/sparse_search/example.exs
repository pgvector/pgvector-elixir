# good resources
# https://opensearch.org/blog/improving-document-retrieval-with-sparse-semantic-encoders/
# https://huggingface.co/opensearch-project/opensearch-neural-sparse-encoding-v1

Postgrex.Types.define(Example.PostgrexTypes, Pgvector.extensions(), [])

{:ok, pid} = Postgrex.start_link(database: "pgvector_example", types: Example.PostgrexTypes)

Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
Postgrex.query!(pid, "DROP TABLE IF EXISTS documents", [])

Postgrex.query!(
  pid,
  "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding sparsevec(30522))",
  []
)

model_id = "opensearch-project/opensearch-neural-sparse-encoding-v1"
{:ok, model_info} = Bumblebee.load_model({:hf, model_id})
{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_id})

defmodule Example do
  def fetch_embeddings(model_info, tokenizer, input) do
    inputs = Bumblebee.apply_tokenizer(tokenizer, input)
    outputs = Axon.predict(model_info.model, model_info.params, inputs)

    values =
      Nx.reduce_max(Nx.multiply(outputs[:logits], Nx.new_axis(inputs["attention_mask"], -1)),
        axes: [1]
      )

    values = Nx.log(Nx.add(1, Nx.max(values, 0)))

    # TODO zero special tokens
    # special_token_ids =
    #   for t <- Bumblebee.Tokenizer.all_special_tokens(tokenizer),
    #       do: Bumblebee.Tokenizer.token_to_id(tokenizer, t)

    # TODO improve
    values |> Nx.to_list()
  end
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]

embeddings = Example.fetch_embeddings(model_info, tokenizer, input)

for {content, embedding} <- Enum.zip(input, embeddings) do
  Postgrex.query!(pid, "INSERT INTO documents (content, embedding) VALUES ($1, $2)", [
    content,
    embedding |> Pgvector.SparseVector.new()
  ])
end

query = "forest"

query_embedding =
  Example.fetch_embeddings(model_info, tokenizer, [query])
  |> List.first()

result =
  Postgrex.query!(pid, "SELECT id, content FROM documents ORDER BY embedding <#> $1 LIMIT 5", [
    query_embedding |> Pgvector.SparseVector.new()
  ])

for [id, content] <- result.rows do
  IO.puts("#{id}: #{content}")
end
