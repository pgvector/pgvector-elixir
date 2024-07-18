Postgrex.Types.define(Example.PostgrexTypes, Pgvector.extensions(), [])

{:ok, pid} = Postgrex.start_link(database: "pgvector_example", types: Example.PostgrexTypes)

Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
Postgrex.query!(pid, "DROP TABLE IF EXISTS documents", [])

Postgrex.query!(
  pid,
  "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(384))",
  []
)

model_id = "sentence-transformers/all-MiniLM-L6-v2"
{:ok, model_info} = Bumblebee.load_model({:hf, model_id})
{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_id})

defmodule Example do
  def fetch_embeddings(model_info, tokenizer, input) do
    serving =
      Bumblebee.Text.text_embedding(model_info, tokenizer,
        output_attribute: :hidden_state,
        output_pool: :mean_pooling,
        embedding_processor: :l2_norm
      )

    for v <- Nx.Serving.run(serving, input), do: v[:embedding]
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
    embedding
  ])
end

document_id = 1

result =
  Postgrex.query!(
    pid,
    "SELECT id, content FROM documents WHERE id != $1 ORDER BY embedding <=> (SELECT embedding FROM documents WHERE id = $1) LIMIT 5",
    [document_id]
  )

for [id, content] <- result.rows do
  IO.puts("#{id}: #{content}")
end
