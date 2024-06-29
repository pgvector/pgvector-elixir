Postgrex.Types.define(Example.PostgrexTypes, Pgvector.extensions(), [])

{:ok, pid} = Postgrex.start_link(database: "pgvector_example", types: Example.PostgrexTypes)

Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
Postgrex.query!(pid, "DROP TABLE IF EXISTS documents", [])

Postgrex.query!(
  pid,
  "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))",
  []
)

defmodule Example do
  def fetch_embeddings(input) do
    api_key = System.fetch_env!("OPENAI_API_KEY")
    url = "https://api.openai.com/v1/embeddings"

    data = %{
      "input" => input,
      "model" => "text-embedding-3-small"
    }

    response =
      %HTTPoison.Response{status_code: 200} =
      HTTPoison.post!(url, Jason.encode!(data), [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ])

    for v <- Jason.decode!(response.body)["data"], do: v["embedding"]
  end
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]

embeddings = Example.fetch_embeddings(input)

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
