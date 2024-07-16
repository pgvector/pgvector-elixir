Postgrex.Types.define(Example.PostgrexTypes, Pgvector.extensions(), [])

{:ok, pid} = Postgrex.start_link(database: "pgvector_example", types: Example.PostgrexTypes)

Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
Postgrex.query!(pid, "DROP TABLE IF EXISTS documents", [])

Postgrex.query!(
  pid,
  "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding bit(1024))",
  []
)

defmodule Example do
  def fetch_embeddings(texts, input_type) do
    api_key = System.fetch_env!("CO_API_KEY")
    url = "https://api.cohere.com/v1/embed"

    data = %{
      "texts" => texts,
      "model" => "embed-english-v3.0",
      "input_type" => input_type,
      "embedding_types" => ["ubinary"]
    }

    response =
      %HTTPoison.Response{status_code: 200} =
      HTTPoison.post!(url, Jason.encode!(data), [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ])

    for e <- Jason.decode!(response.body)["embeddings"]["ubinary"] do
      for v <- e, into: "", do: <<v::unsigned-size(8)>>
    end
  end
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]

embeddings = Example.fetch_embeddings(input, "search_document")

for {content, embedding} <- Enum.zip(input, embeddings) do
  Postgrex.query!(pid, "INSERT INTO documents (content, embedding) VALUES ($1, $2)", [
    content,
    embedding
  ])
end

query = "forest"
query_embedding = Example.fetch_embeddings([query], "search_query") |> List.first()

result =
  Postgrex.query!(
    pid,
    "SELECT id, content FROM documents ORDER BY embedding <~> $1 LIMIT 5",
    [query_embedding]
  )

for [id, content] <- result.rows do
  IO.puts("#{id}: #{content}")
end
