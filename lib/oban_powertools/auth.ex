defmodule ObanPowertools.Auth do
  @moduledoc """
  Defines the strict Auth behaviour for Oban Powertools.
  """

  alias ObanPowertools.RuntimeConfig

  @doc """
  Returns the current actor from the connection or socket.
  """
  @callback current_actor(Plug.Conn.t() | map()) :: any()

  @doc """
  Determines if the actor can perform the given action on the resource.
  """
  @callback can_perform_action?(actor :: any(), action :: atom(), resource :: any()) :: boolean()

  @doc """
  Returns the configured host auth module, if any.
  """
  def auth_module(opts \\ []), do: RuntimeConfig.auth_module(opts)

  @doc """
  Resolves the current actor through the configured host auth module.
  """
  def current_actor(conn_or_socket_or_session) do
    auth_module!().current_actor(conn_or_socket_or_session)
  end

  @doc """
  Delegates authorization to the configured host auth module.
  """
  def authorize(actor, action, resource) do
    auth_module!().can_perform_action?(actor, action, resource)
  end

  def auth_module!(opts \\ []), do: RuntimeConfig.auth_module!(opts)

  @doc """
  Normalizes an actor identifier for audit writes.
  """
  def actor_id(nil), do: nil
  def actor_id(%{id: id}), do: to_string(id)
  def actor_id(%{"id" => id}), do: to_string(id)
  def actor_id(actor) when is_binary(actor), do: actor
  def actor_id(actor) when is_atom(actor), do: Atom.to_string(actor)
  def actor_id(actor) when is_integer(actor), do: Integer.to_string(actor)
  def actor_id(actor), do: inspect(actor)
end
