# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :phoenix_host,
  ecto_repos: [PhoenixHost.Repo],
  generators: [timestamp_type: :utc_datetime]

config :phoenix_host, Oban,
  repo: PhoenixHost.Repo,
  notifier: Oban.Notifiers.PG,
  queues: [default: 5]

config :oban_powertools,
  repo: PhoenixHost.Repo,
  auth_module: PhoenixHostWeb.ObanPowertoolsAuth,
  display_policy: PhoenixHostWeb.ObanPowertoolsDisplayPolicy

# Configure the endpoint
config :phoenix_host, PhoenixHostWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PhoenixHostWeb.ErrorHTML, json: PhoenixHostWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PhoenixHost.PubSub,
  live_view: [signing_salt: "IjIaQFVP"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
