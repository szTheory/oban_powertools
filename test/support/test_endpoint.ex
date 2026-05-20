defmodule ObanPowertools.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :oban_powertools

  @session_options [
    store: :cookie,
    key: "_oban_powertools_key",
    signing_salt: "test-signing-salt"
  ]

  plug(Plug.Session, @session_options)
  plug(ObanPowertools.TestRouter)
end
