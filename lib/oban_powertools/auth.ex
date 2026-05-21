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
  Returns an explicit authorization outcome for the actor, action, and resource.
  """
  @callback authorize(actor :: any(), action :: atom(), resource :: any()) ::
              :ok | {:error, term()}

  @doc """
  Returns the stable principal envelope used for durable audit attribution.
  """
  @callback audit_principal(actor :: any()) :: map() | nil

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
  Returns the explicit authorization outcome from the configured host auth module.
  Falls back to the legacy boolean callback when needed.
  """
  def authorization_outcome(actor, action, resource) do
    module = auth_module!()
    Code.ensure_loaded(module)

    cond do
      function_exported?(module, :authorize, 3) ->
        module.authorize(actor, action, resource)
        |> normalize_authorization_outcome()

      function_exported?(module, :can_perform_action?, 3) ->
        if module.can_perform_action?(actor, action, resource) do
          :ok
        else
          {:error, :unauthorized}
        end

      true ->
        raise ArgumentError,
              "Oban Powertools auth_module #{inspect(module)} must implement authorize/3."
    end
  end

  def auth_module!(opts \\ []), do: RuntimeConfig.auth_module!(opts)

  @doc """
  Compatibility shim for older boolean call sites.
  New code should use `authorization_outcome/3`.
  """
  def authorize(actor, action, resource) do
    authorization_outcome(actor, action, resource) == :ok
  end

  @doc """
  Normalizes the stable principal envelope used for durable audit attribution.
  """
  def audit_principal(actor) do
    module = auth_module!()
    Code.ensure_loaded(module)

    if function_exported?(module, :audit_principal, 1) do
      module.audit_principal(actor)
      |> normalize_audit_principal()
    else
      raise ArgumentError,
            "Oban Powertools auth_module #{inspect(module)} must implement audit_principal/1."
    end
  end

  @doc """
  Compatibility shim for older mutation services that still accept only an actor id.
  """
  def actor_id(nil), do: nil

  def actor_id(actor) do
    module = auth_module()
    if is_atom(module), do: Code.ensure_loaded(module)

    if is_atom(module) and function_exported?(module, :audit_principal, 1) do
      case audit_principal(actor) do
        {:ok, %{id: id}} -> id
        {:error, _reason} -> legacy_actor_id(actor)
      end
    else
      legacy_actor_id(actor)
    end
  end

  defp normalize_authorization_outcome(:ok), do: :ok
  defp normalize_authorization_outcome({:error, reason}), do: {:error, reason}
  defp normalize_authorization_outcome(true), do: :ok
  defp normalize_authorization_outcome(false), do: {:error, :unauthorized}

  defp normalize_authorization_outcome(other) do
    raise ArgumentError,
          "Oban Powertools auth_module returned an invalid authorization outcome: #{inspect(other)}"
  end

  defp normalize_audit_principal(nil), do: {:error, :missing_audit_principal}

  defp normalize_audit_principal(principal) when is_map(principal) do
    id = Map.get(principal, :id, Map.get(principal, "id"))
    type = Map.get(principal, :type, Map.get(principal, "type"))
    label = Map.get(principal, :label, Map.get(principal, "label"))

    with {:ok, normalized_id} <- normalize_principal_id(id),
         :ok <- validate_principal_type(type),
         :ok <- validate_principal_label(label) do
      {:ok, %{id: normalized_id, type: type, label: label}}
    else
      :error -> {:error, :invalid_audit_principal}
    end
  end

  defp normalize_audit_principal(_principal), do: {:error, :invalid_audit_principal}

  defp normalize_principal_id(nil), do: :error
  defp normalize_principal_id(id) when is_binary(id) and byte_size(id) > 0, do: {:ok, id}
  defp normalize_principal_id(id) when is_integer(id), do: {:ok, Integer.to_string(id)}
  defp normalize_principal_id(id) when is_atom(id), do: {:ok, Atom.to_string(id)}
  defp normalize_principal_id(_id), do: :error

  defp validate_principal_type(type) when is_atom(type), do: :ok
  defp validate_principal_type(type) when is_binary(type) and byte_size(type) > 0, do: :ok
  defp validate_principal_type(_type), do: :error

  defp validate_principal_label(nil), do: :ok
  defp validate_principal_label(label) when is_binary(label), do: :ok
  defp validate_principal_label(_label), do: :error

  defp legacy_actor_id(%{id: id}), do: normalize_legacy_id(id)
  defp legacy_actor_id(%{"id" => id}), do: normalize_legacy_id(id)
  defp legacy_actor_id(actor), do: normalize_legacy_id(actor)

  defp normalize_legacy_id(id) when is_binary(id), do: id
  defp normalize_legacy_id(id) when is_integer(id), do: Integer.to_string(id)
  defp normalize_legacy_id(id) when is_atom(id), do: Atom.to_string(id)
  defp normalize_legacy_id(_id), do: nil
end
