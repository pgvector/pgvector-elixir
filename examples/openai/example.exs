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
  def embed(input) do
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

embeddings = Example.embed(input)

for {content, embedding} <- Enum.zip(input, embeddings) do
  Postgrex.query!(pid, "INSERT INTO documents (content, embedding) VALUES ($1, $2)", [
    content,
    embedding
  ])
end

query = "forest"
query_embedding = Example.embed([query]) |> List.first()

result =
  Postgrex.query!(
    pid,
    "SELECT id, content FROM documents ORDER BY embedding <=> $1 LIMIT 5",
    [query_embedding]
  )

for [id, content] <- result.rows do
  IO.puts("#{id}: #{content}")
end
