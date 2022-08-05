Postgrex.Types.define(MyApp.PostgrexTypes, [Pgvector.Extensions.Vector], [])

# needed if postgrex is optional
# Application.ensure_all_started(:postgrex)

ExUnit.start()
