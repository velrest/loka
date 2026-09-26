{:ok, _} = PhoenixTest.Playwright.Supervisor.start_link()
Application.put_env(:phoenix_test, :base_url, LokaWeb.Endpoint.url())

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Loka.Repo, :manual)
