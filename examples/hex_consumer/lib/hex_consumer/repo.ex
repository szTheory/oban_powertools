defmodule HexConsumer.Repo do
  use Ecto.Repo,
    otp_app: :hex_consumer,
    adapter: Ecto.Adapters.Postgres
end
