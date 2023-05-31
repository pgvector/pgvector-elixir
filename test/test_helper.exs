Postgrex.Types.define(EctoApp.PostgrexTypes, [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions(), [])

defmodule Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres
end

Repo.start_link(database: "pgvector_elixir_test", types: EctoApp.PostgrexTypes, log: false)

ExUnit.start()
