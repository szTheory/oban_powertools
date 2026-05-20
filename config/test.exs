import Config

config :oban_powertools, ObanPowertools.TestRepo,
  database: "oban_powertools_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support"

config :oban_powertools,
  ecto_repos: [ObanPowertools.TestRepo],
  repo: ObanPowertools.TestRepo,
  auth_module: ObanPowertools.TestAuth

config :oban_powertools, ObanPowertools.TestEndpoint,
  url: [host: "localhost"],
  secret_key_base: String.duplicate("a", 64),
  server: false,
  live_view: [signing_salt: "oban-powertools-live"],
  pubsub_server: ObanPowertools.PubSub

config :phoenix, :json_library, Jason

config :oban,
  repo: ObanPowertools.TestRepo,
  queues: [default: 10],
  testing: :manual
