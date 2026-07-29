import Config

phase79_browser_fixtures? = System.get_env("PHASE79_BROWSER_FIXTURES") == "1"
phase80_browser_fixtures? = System.get_env("PHASE80_BROWSER_FIXTURES") == "1"
phase81_browser_fixtures? = System.get_env("PHASE81_BROWSER_FIXTURES") == "1"

browser_fixtures? =
  phase79_browser_fixtures? or phase80_browser_fixtures? or phase81_browser_fixtures?

browser_fixture_server? = browser_fixtures? and not is_nil(System.get_env("PHX_SERVER"))

repo_pool =
  if browser_fixture_server?,
    do: DBConnection.ConnectionPool,
    else: Ecto.Adapters.SQL.Sandbox

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :phoenix_host, PhoenixHost.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "phoenix_host_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: repo_pool,
  pool_size: if(browser_fixture_server?, do: 10, else: System.schedulers_online() * 2)

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :phoenix_host, PhoenixHostWeb.Endpoint,
  http: [ip: if(browser_fixture_server?, do: {0, 0, 0, 0}, else: {127, 0, 0, 1}), port: 4002],
  check_origin: not browser_fixture_server?,
  render_errors: [
    formats: [
      html: PhoenixHostWeb.Phase80BrowserFixtureErrorHTML,
      json: PhoenixHostWeb.ErrorJSON
    ],
    layout: false
  ],
  secret_key_base: "fsGe826sUc4hrzHxHNi2Zl6/OywWnUeE7cyo2e69+6AeaKQ7WmQEEBUk5NhkBx73",
  server: browser_fixture_server?

config :phoenix_host, dev_routes: browser_fixtures?

config :oban_powertools, dev_routes: browser_fixtures?

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
