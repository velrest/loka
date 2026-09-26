import Config
config :loka, Oban, testing: :manual
config :loka, token_signing_secret: "0Nb9TbNJKbW6Jlj/rOkoVyAuEgrmp3qq"
config :bcrypt_elixir, log_rounds: 1
config :ash, policies: [show_policy_breakdowns?: true], disable_async?: true

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :loka, Loka.Repo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database:
    System.get_env(
      "POSTGRES_DB",
      "orangerie_test#{System.get_env("MIX_TEST_PARTITION")}"
    ),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  port: System.get_env("POSTGRES_PORT", "5433")

# The server runs for the Playwright browser tests (test/loka_web/browser)
config :loka, LokaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "DfdJYsJAQkA4qIsQBbo3sGeWVUK/SL67vtC1sMfDcix0a51+LjUIJ0hZhRQ0eKgD",
  server: true

# Lets browser tests share each test's Ecto sandbox (see LokaWeb.LiveAcceptance)
config :loka, sql_sandbox: true

# In test we don't send emails
config :loka, Loka.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :phoenix_test, :endpoint, LokaWeb.Endpoint
config :phoenix_test, otp_app: :loka

# Browser tests never reach the internet (e.g. no map tiles from OpenStreetMap);
# only the test server on localhost resolves
config :phoenix_test,
  playwright: [
    # Default is 2s, too short when the whole suite runs in parallel
    timeout: to_timeout(second: 5),
    browser_launch_opts: [args: ["--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE localhost"]]
  ]

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
