import Config

put_if_present = fn keyword, key, env_name ->
  case System.get_env(env_name) do
    nil -> keyword
    value -> Keyword.put(keyword, key, value)
  end
end

test_repo_config =
  [
    database: System.get_env("OBAN_POWERTOOLS_TEST_DATABASE", "oban_powertools_test"),
    hostname: System.get_env("PGHOST", "localhost"),
    pool: Ecto.Adapters.SQL.Sandbox,
    priv: "test/support"
  ]
  |> put_if_present.(:username, "PGUSER")
  |> put_if_present.(:password, "PGPASSWORD")

config :oban_powertools, ObanPowertools.TestRepo, test_repo_config

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
