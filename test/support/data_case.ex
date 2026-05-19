defmodule ObanPowertools.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias ObanPowertools.TestRepo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanPowertools.TestRepo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, {:shared, self()})
    end

    :ok
  end
end
