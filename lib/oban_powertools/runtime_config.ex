defmodule ObanPowertools.RuntimeConfig do
  @moduledoc """
  Centralized runtime configuration contract for required host wiring.
  """

  @app :oban_powertools

  def repo(opts \\ []) do
    Keyword.get(opts, :repo) || configured(:repo, opts)
  end

  def repo!(opts \\ []) do
    repo(opts ++ [required: true])
  end

  def auth_module(opts \\ []) do
    Keyword.get(opts, :auth_module) || configured(:auth_module, opts)
  end

  def auth_module!(opts \\ []) do
    auth_module(opts ++ [required: true])
  end

  def display_policy(opts \\ []) do
    Keyword.get(opts, :display_policy) || configured(:display_policy, opts)
  end

  def display_policy!(opts \\ []) do
    display_policy(opts ++ [required: true])
  end

  def workflow_callback_handler(opts \\ []) do
    Keyword.get(opts, :workflow_callback_handler) || configured(:workflow_callback_handler, opts)
  end

  def workflow_callback_handler!(opts \\ []) do
    workflow_callback_handler(opts ++ [required: true])
  end

  def host_escalation_handler(opts \\ []) do
    Keyword.get(opts, :host_escalation_handler) || configured(:host_escalation_handler, opts)
  end

  defp configured(key, opts) do
    case Application.get_env(@app, key) do
      nil ->
        if Keyword.get(opts, :required, false) do
          raise setup_error(key)
        end

      value ->
        value
    end
  end

  defp setup_error(:repo) do
    "Oban Powertools requires :repo in config :oban_powertools, repo: MyApp.Repo " <>
      "before using persistence-backed features."
  end

  defp setup_error(:auth_module) do
    "Oban Powertools requires :auth_module in config :oban_powertools, " <>
      "auth_module: MyAppWeb.ObanPowertoolsAuth before mounting native operator pages."
  end

  defp setup_error(:display_policy) do
    "Oban Powertools requires :display_policy in config :oban_powertools, " <>
      "display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy before mounting policy-sensitive native operator pages."
  end

  defp setup_error(:workflow_callback_handler) do
    "Oban Powertools requires :workflow_callback_handler in config :oban_powertools, " <>
      "workflow_callback_handler: MyApp.ObanPowertoolsWorkflowCallbacks before dispatching " <>
      "the post-commit, at-least-once workflow callbacks. Handlers must be idempotent."
  end

  defp setup_error(:host_escalation_handler) do
    "Oban Powertools requires :host_escalation_handler in config :oban_powertools, " <>
      "host_escalation_handler: MyApp.ObanPowertoolsEscalationHandler before dispatching " <>
      "host escalation callbacks."
  end
end

defmodule ObanPowertools.DisplayPolicy do
  @moduledoc false

  alias ObanPowertools.RuntimeConfig

  def assert_configured! do
    _ = policy_module!()
    :ok
  end

  def actor_label(principal, context \\ %{}) do
    normalized_principal = normalize_principal(principal)

    render_text(:actor_label, normalized_principal, context, fn ->
      normalized_principal.label || normalized_principal.id || "system"
    end)
  end

  def reason(reason, context \\ %{}) do
    normalized_reason = normalize_reason(reason)

    render_text(:reason, normalized_reason, context, fn ->
      normalized_reason || "No reason recorded"
    end)
  end

  def workflow_result(result_input, context \\ %{})

  def workflow_result(nil, _context) do
    %{
      available?: false,
      summary: "No result recorded",
      payload: "No result recorded",
      redacted?: false,
      status: nil
    }
  end

  def workflow_result(result_input, context) do
    default = default_workflow_result(result_input)

    case apply_policy(:workflow_result, result_input, context) do
      nil ->
        default

      %{} = rendered ->
        %{
          available?: read_key_or_default(rendered, :available?, default.available?),
          summary: read_key_or_default(rendered, :summary, default.summary),
          payload: read_key_or_default(rendered, :payload, default.payload),
          redacted?:
            read_key_or_default(
              rendered,
              :redacted?,
              read_key_or_default(rendered, :redacted, default.redacted?)
            ),
          status: read_key_or_default(rendered, :status, default.status)
        }

      other ->
        raise ArgumentError,
              "Oban Powertools display_policy returned an invalid workflow_result display: #{inspect(other)}"
    end
  end

  def job_recorded(record_input, context \\ %{}) do
    default = default_job_recorded(record_input)

    case apply_policy(:job_recorded, record_input, context) do
      nil ->
        default

      text when is_binary(text) ->
        %{default | payload: text}

      %{} = rendered ->
        %{
          available?: read_key_or_default(rendered, :available?, default.available?),
          summary: read_key_or_default(rendered, :summary, default.summary),
          status: read_key_or_default(rendered, :status, default.status),
          attempt: read_key_or_default(rendered, :attempt, default.attempt),
          payload_bytes: read_key_or_default(rendered, :payload_bytes, default.payload_bytes),
          recorded_at: read_key_or_default(rendered, :recorded_at, default.recorded_at),
          retention: read_key_or_default(rendered, :retention, default.retention),
          expires_at: read_key_or_default(rendered, :expires_at, default.expires_at),
          payload: read_key_or_default(rendered, :payload, default.payload),
          redacted?:
            read_key_or_default(
              rendered,
              :redacted?,
              read_key_or_default(rendered, :redacted, default.redacted?)
            )
        }

      other ->
        raise ArgumentError,
              "Oban Powertools display_policy returned an invalid job_recorded display: #{inspect(other)}"
    end
  rescue
    _ ->
      if is_nil(record_input) do
        default_job_recorded(nil)
      else
        %{
          available?: true,
          summary: "Recorded output hidden by display policy fallback.",
          status: read_key(record_input, :status),
          attempt: read_key(record_input, :attempt),
          payload_bytes: read_key(record_input, :payload_bytes),
          recorded_at: read_key(record_input, :recorded_at),
          retention: read_key(record_input, :retention),
          expires_at: read_key(record_input, :expires_at),
          payload: "Recorded output hidden by display policy fallback.",
          redacted?: !!(read_key(record_input, :redacted?) || read_key(record_input, :redacted))
        }
      end
  end

  def render_job_field(:job_recorded, value, context) do
    job_recorded(value, context)
  end

  def render_job_field(:job_args, value, context) do
    redacted_fields = get_redacted_fields(context)

    case {redacted_fields, apply_policy(:job_args, value, context)} do
      {[], nil} ->
        {:raw_json, Jason.encode!(value || %{}, pretty: true)}

      {[], text} when is_binary(text) ->
        {:string, text}

      {[], %{} = custom_map} ->
        {:raw_json, Jason.encode!(custom_map, pretty: true)}

      {[], other} ->
        raise ArgumentError, invalid_return_message(:job_args, other)

      {_fields, nil} ->
        # Default path: overlay "Redacted at enqueue" for each redacted field
        annotated = build_redacted_args_map(value || %{}, redacted_fields)
        {:raw_json, Jason.encode!(annotated, pretty: true)}

      {_fields, text} when is_binary(text) ->
        # Host policy returned custom string — do NOT overlay (OQ3 RESOLVED)
        {:string, text}

      {_fields, %{} = custom_map} ->
        # Host policy returned custom map — do NOT overlay (OQ3 RESOLVED)
        {:raw_json, Jason.encode!(custom_map, pretty: true)}

      {_fields, other} ->
        raise ArgumentError, invalid_return_message(:job_args, other)
    end
  rescue
    _ -> {:fallback, "[redacted]"}
  end

  def render_job_field(kind, value, context) do
    case apply_policy(kind, value, context) do
      nil -> {:raw_json, Jason.encode!(value || %{}, pretty: true)}
      text when is_binary(text) -> {:string, text}
      %{} = redacted_map -> {:raw_json, Jason.encode!(redacted_map, pretty: true)}
      other -> raise ArgumentError, invalid_return_message(kind, other)
    end
  rescue
    _ -> {:fallback, "[redacted]"}
  end

  defp render_text(kind, value, context, fallback) do
    case apply_policy(kind, value, context) do
      nil -> fallback.()
      text when is_binary(text) -> text
      other -> raise ArgumentError, invalid_return_message(kind, other)
    end
  end

  defp apply_policy(kind, value, context) do
    module = policy_module!()

    case module.display(kind, value, context) do
      nil -> nil
      rendered -> rendered
    end
  end

  defp policy_module! do
    module = RuntimeConfig.display_policy!()
    Code.ensure_loaded(module)

    if function_exported?(module, :display, 3) do
      module
    else
      raise ArgumentError,
            "Oban Powertools display_policy #{inspect(module)} must implement display/3."
    end
  end

  # Extracts __redacted_fields__ from job meta in context for the :job_args overlay.
  # Returns a list of field name strings, or [] when absent/unknown context shape.
  defp get_redacted_fields(%{job: %Oban.Job{meta: meta}}) do
    Map.get(meta || %{}, "__redacted_fields__", [])
  end

  defp get_redacted_fields(_), do: []

  # Merges "Redacted at enqueue" overlay for each redacted field (string key, D-17/D-14).
  # Does NOT remove the user_id or other non-redacted fields.
  defp build_redacted_args_map(args, redacted_fields) do
    overlay = Map.new(redacted_fields, fn field -> {field, "Redacted at enqueue"} end)
    Map.merge(args, overlay)
  end

  defp normalize_principal(nil), do: %{id: "system", type: :system, label: nil}

  defp normalize_principal(principal) when is_map(principal) do
    %{
      id: read_key(principal, :id) || "system",
      type: read_key(principal, :type) || :user,
      label: read_key(principal, :label)
    }
  end

  defp normalize_principal(principal) do
    %{id: to_string(principal), type: :user, label: nil}
  end

  defp normalize_reason(nil), do: nil

  defp normalize_reason(reason) do
    reason
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp default_workflow_result(result_input) do
    payload_value = read_key_or_default(result_input, :payload, %{})

    summary =
      read_key(result_input, :summary) ||
        if(read_key(result_input, :redacted),
          do: "Result stored with redaction metadata",
          else: "Result available"
        )

    payload =
      if read_key(result_input, :redacted) do
        "Hidden by display policy"
      else
        inspect(payload_value)
      end

    %{
      available?: true,
      summary: summary,
      payload: payload,
      redacted?: !!read_key(result_input, :redacted),
      status: read_key(result_input, :status)
    }
  end

  defp default_job_recorded(nil) do
    %{
      available?: false,
      summary: "No recorded output found for this job.",
      status: nil,
      attempt: nil,
      payload_bytes: nil,
      recorded_at: nil,
      retention: nil,
      expires_at: nil,
      payload: "No recorded output found for this job.",
      redacted?: false
    }
  end

  defp default_job_recorded(record_input) do
    payload = read_key(record_input, :payload) || %{}

    summary =
      read_key(record_input, :summary) ||
        if(read_key(record_input, :redacted),
          do: "Recorded output stored with redaction metadata",
          else: "Recorded output available"
        )

    %{
      available?: true,
      summary: summary,
      status: read_key(record_input, :status),
      attempt: read_key(record_input, :attempt),
      payload_bytes: read_key(record_input, :payload_bytes),
      recorded_at: read_key(record_input, :recorded_at),
      retention: read_key(record_input, :retention),
      expires_at: read_key(record_input, :expires_at),
      payload: payload,
      redacted?: !!read_key(record_input, :redacted)
    }
  end

  defp read_key(map, key) when is_map(map) do
    if Map.has_key?(map, key) do
      Map.get(map, key)
    else
      Map.get(map, Atom.to_string(key))
    end
  end

  defp read_key(_value, _key), do: nil

  defp read_key_or_default(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) ->
        Map.get(map, key)

      Map.has_key?(map, Atom.to_string(key)) ->
        Map.get(map, Atom.to_string(key))

      true ->
        default
    end
  end

  defp read_key_or_default(_value, _key, default), do: default

  defp invalid_return_message(kind, other) do
    "Oban Powertools display_policy returned an invalid #{kind} display: #{inspect(other)}"
  end
end
