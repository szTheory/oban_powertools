defmodule PhoenixHost.Repo do
  use Ecto.Repo,
    otp_app: :phoenix_host,
    adapter: Ecto.Adapters.Postgres
end
