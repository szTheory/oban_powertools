defmodule ObanPowertools.Auth do
  @moduledoc """
  Defines the strict Auth behaviour for Oban Powertools.
  """

  @doc """
  Returns the current actor from the connection or socket.
  """
  @callback current_actor(Plug.Conn.t() | map()) :: any()

  @doc """
  Determines if the actor can perform the given action on the resource.
  """
  @callback can_perform_action?(actor :: any(), action :: atom(), resource :: any()) :: boolean()
end