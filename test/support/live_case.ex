defmodule ObanPowertools.LiveCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest

      alias ObanPowertools.TestRepo

      @endpoint ObanPowertools.TestEndpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ObanPowertools.TestRepo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ObanPowertools.TestRepo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
