defmodule ObanPowertools.TestAuth do
  @behaviour ObanPowertools.Auth

  @impl true
  def current_actor(%{"current_actor" => actor}), do: actor
  def current_actor(%{current_actor: actor}), do: actor
  def current_actor(%{assigns: %{current_actor: actor}}), do: actor
  def current_actor(_), do: nil

  @impl true
  def can_perform_action?(nil, _action, _resource), do: false

  def can_perform_action?(actor, action, _resource) do
    permissions = Map.get(actor, :permissions, Map.get(actor, "permissions", []))
    :all in permissions or action in permissions
  end
end
