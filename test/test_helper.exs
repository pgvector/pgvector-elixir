Postgrex.Types.define(TestApp.PostgrexTypes, [Pgvector.Extensions.Vector], [])

Application.ensure_all_started(:postgrex)

ExUnit.start()
