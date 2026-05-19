ExUnit.start()

{:ok, _} = ObanPowertools.TestRepo.start_link()

config = Application.get_all_env(:oban)
{:ok, _} = Oban.start_link(config)

Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, :manual)
