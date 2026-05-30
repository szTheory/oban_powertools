defmodule HexConsumerWeb.ObanPowertoolsAuth do
  @moduledoc """
  Thin host-owned Powertools auth seam for the canonical example host.
  """

  @behaviour ObanPowertools.Auth

  @impl true
  def current_actor(%Plug.Conn{assigns: %{current_actor: actor}}), do: actor
  def current_actor(%Plug.Conn{private: %{plug_session: %{"ops_actor" => actor}}}), do: actor
  def current_actor(%{"ops_actor" => actor}), do: actor
  def current_actor(%{ops_actor: actor}), do: actor
  def current_actor(_), do: demo_actor()

  @impl true
  def authorize(nil, _action, _resource), do: {:error, :unauthorized}

  def authorize(actor, _action, _resource) when is_map(actor) do
    if Map.get(actor, :role, Map.get(actor, "role")) in [:ops, "ops"] do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  def authorize(_actor, _action, _resource), do: {:error, :unauthorized}

  @impl true
  def audit_principal(actor) when is_map(actor) do
    %{
      id: actor[:id] || actor["id"] || "ops-demo",
      type: :user,
      label: actor[:label] || actor["label"] || "ops-demo"
    }
  end

  def audit_principal(_actor), do: audit_principal(demo_actor())

  def demo_actor do
    %{id: "ops-demo", label: "ops-demo", role: :ops}
  end
end
