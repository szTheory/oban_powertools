defmodule ObanPowertools.TestAuth do
  @behaviour ObanPowertools.Auth

  @impl true
  def current_actor(%{"current_actor" => actor}), do: actor
  def current_actor(%{current_actor: actor}), do: actor
  def current_actor(%{assigns: %{current_actor: actor}}), do: actor
  def current_actor(_), do: nil

  @impl true
  def authorize(nil, _action, _resource), do: {:error, :unauthorized}

  def authorize(actor, action, _resource) do
    permissions = Map.get(actor, :permissions, Map.get(actor, "permissions", []))

    cond do
      custom_result =
          Map.get(actor, :authorization_result, Map.get(actor, "authorization_result")) ->
        custom_result

      :all in permissions or action in permissions ->
        :ok

      true ->
        {:error, :unauthorized}
    end
  end

  @impl true
  def audit_principal(nil), do: nil

  def audit_principal(actor) do
    cond do
      is_map(actor) and Map.has_key?(actor, :audit_principal) ->
        Map.get(actor, :audit_principal)

      is_map(actor) and Map.has_key?(actor, "audit_principal") ->
        Map.get(actor, "audit_principal")

      true ->
        default_principal(actor)
    end
  end

  defp default_principal(actor) do
    id = Map.get(actor, :id, Map.get(actor, "id"))

    if id do
      %{id: id, type: :user, label: "operator:#{id}"}
    end
  end
end
