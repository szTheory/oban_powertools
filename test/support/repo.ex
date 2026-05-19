defmodule ObanPowertools.TestRepo do
  use Ecto.Repo,
    otp_app: :oban_powertools,
    adapter: Ecto.Adapters.Postgres
end
