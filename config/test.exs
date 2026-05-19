import Config

config :oban_powertools, ObanPowertools.TestRepo,
  database: "oban_powertools_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/support"

config :oban_powertools,
  ecto_repos: [ObanPowertools.TestRepo],
  repo: ObanPowertools.TestRepo

config :oban,
  repo: ObanPowertools.TestRepo,
  queues: [default: 10],
  testing: :manual
