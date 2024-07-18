Postgrex.Types.define(Example.PostgrexTypes, Pgvector.extensions(), [])

{:ok, pid} = Postgrex.start_link(database: "pgvector_example", types: Example.PostgrexTypes)

Postgrex.query!(pid, "CREATE EXTENSION IF NOT EXISTS vector", [])
Postgrex.query!(pid, "DROP TABLE IF EXISTS documents", [])

Postgrex.query!(
  pid,
  "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(384))",
  []
)

Postgrex.query!(pid, "CREATE INDEX ON documents USING GIN (to_tsvector('english', content))", [])

{:ok, model_info} = Bumblebee.load_model({:hf, "sentence-transformers/multi-qa-MiniLM-L6-cos-v1"})

{:ok, tokenizer} =
  Bumblebee.load_tokenizer({:hf, "sentence-transformers/multi-qa-MiniLM-L6-cos-v1"})

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

sql = """
WITH semantic_search AS (
    SELECT id, RANK () OVER (ORDER BY embedding <=> $2) AS rank
    FROM documents
    ORDER BY embedding <=> $2
    LIMIT 20
),
keyword_search AS (
    SELECT id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC)
    FROM documents, plainto_tsquery('english', $1) query
    WHERE to_tsvector('english', content) @@ query
    ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC
    LIMIT 20
)
SELECT
    COALESCE(semantic_search.id, keyword_search.id) AS id,
    COALESCE(1.0 / ($3 + semantic_search.rank), 0.0) +
    COALESCE(1.0 / ($3 + keyword_search.rank), 0.0) AS score
FROM semantic_search
FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
ORDER BY score DESC
LIMIT 5
"""

query = "growling bear"
query_embedding = Example.fetch_embeddings(model_info, tokenizer, [query]) |> List.first()
k = 60

result = Postgrex.query!(pid, sql, [query, query_embedding, k])

for [id, rrf_score] <- result.rows do
  IO.puts("document: #{id}, RRF score: #{rrf_score}")
end
