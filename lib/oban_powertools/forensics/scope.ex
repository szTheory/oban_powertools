defmodule ObanPowertools.Forensics.Scope do
  @moduledoc """
  Closed typed grammar for the Forensics URL scope.

  Parsing is pure and accepts only the six public Forensics selector keys. A
  valid scope belongs to exactly one workflow, Lifeline incident, Cron entry, or
  limiter family. Invalid input is reduced to an empty canonical destination
  before any source context is consulted.
  """

  @keys ~w(resource_type resource_id workflow_id step incident_fingerprint view)
  @empty_notice "Choose evidence to inspect."
  @invalid_notice "Choose one evidence type"

  defstruct kind: nil,
            resource_type: nil,
            resource_id: nil,
            workflow_id: nil,
            step: nil,
            incident_fingerprint: nil,
            view: nil

  @type kind :: :workflow | :incident | :cron_entry | :limiter

  @type t :: %__MODULE__{
          kind: kind(),
          resource_type: String.t() | nil,
          resource_id: String.t() | nil,
          workflow_id: String.t() | nil,
          step: String.t() | nil,
          incident_fingerprint: String.t() | nil,
          view: String.t() | nil
        }

  @type parse_result ::
          {:empty, [], String.t()}
          | {:ok, t(), [{String.t(), String.t()}]}
          | {:invalid, [], String.t()}

  @doc """
  Parses one untrusted selector collection into a closed typed scope.

  Blank values for the six known keys are treated as absent. Unknown keys,
  duplicate aliases, non-string values, mixed families, and structurally
  inconsistent context pairs are invalid.
  """
  @spec parse(map() | Enumerable.t()) :: parse_result()
  def parse(params) when is_map(params) or is_list(params) do
    with {:ok, values} <- normalize(params) do
      classify(values)
    else
      :error -> invalid()
    end
  end

  def parse(_params), do: invalid()

  @doc "Returns the nonblank selector fields in the fixed six-key URL order."
  @spec canonical_params(t()) :: [{String.t(), String.t()}]
  def canonical_params(%__MODULE__{} = scope) do
    @keys
    |> Enum.map(&{&1, Map.fetch!(scope, String.to_existing_atom(&1))})
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp normalize(params) do
    params
    |> Enum.reduce_while({:ok, %{}}, fn
      {raw_key, raw_value}, {:ok, acc} ->
        with {:ok, key} <- normalize_key(raw_key),
             false <- Map.has_key?(acc, key),
             {:ok, value} <- normalize_value(raw_value) do
          {:cont, {:ok, Map.put(acc, key, value)}}
        else
          _invalid -> {:halt, :error}
        end

      _invalid, _acc ->
        {:halt, :error}
    end)
    |> case do
      {:ok, values} -> {:ok, Map.merge(Map.new(@keys, &{&1, nil}), values)}
      :error -> :error
    end
  end

  defp normalize_key(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> normalize_key()
  end

  defp normalize_key(key) when key in @keys, do: {:ok, key}
  defp normalize_key(_key), do: :error

  defp normalize_value(nil), do: {:ok, nil}

  defp normalize_value(value) when is_binary(value) do
    if String.trim(value) == "", do: {:ok, nil}, else: {:ok, value}
  end

  defp normalize_value(_value), do: :error

  defp classify(values) do
    cond do
      Enum.all?(@keys, &is_nil(values[&1])) ->
        {:empty, [], @empty_notice}

      values["incident_fingerprint"] ->
        incident(values)

      values["workflow_id"] ->
        workflow(values)

      values["resource_type"] == "cron_entry" ->
        standalone(values, :cron_entry)

      values["resource_type"] == "limiter" ->
        standalone(values, :limiter)

      true ->
        invalid()
    end
  end

  defp workflow(values) do
    context =
      case {values["resource_type"], values["resource_id"], values["step"]} do
        {nil, nil, _step} ->
          true

        {"workflow", resource_id, _step} ->
          resource_id == values["workflow_id"]

        {"workflow_step", resource_id, step} ->
          not is_nil(resource_id) and not is_nil(step)

        _other ->
          false
      end

    if is_nil(values["incident_fingerprint"]) and is_nil(values["view"]) and context do
      ok(:workflow, values)
    else
      invalid()
    end
  end

  defp incident(values) do
    valid_view? = is_nil(values["view"]) or values["view"] in ~w(active resolved)

    context =
      case {
        values["resource_type"],
        values["resource_id"],
        values["workflow_id"],
        values["step"]
      } do
        {nil, nil, nil, nil} ->
          true

        {"job", resource_id, nil, nil} ->
          not is_nil(resource_id)

        {"workflow", resource_id, workflow_id, nil} ->
          not is_nil(workflow_id) and resource_id == workflow_id

        {"workflow_step", resource_id, workflow_id, step} ->
          not is_nil(resource_id) and not is_nil(workflow_id) and not is_nil(step)

        _other ->
          false
      end

    if valid_view? and context do
      ok(:incident, values)
    else
      invalid()
    end
  end

  defp standalone(values, kind) do
    expected_type = Atom.to_string(kind)

    only_resource_pair? =
      Enum.all?(
        ~w(workflow_id step incident_fingerprint view),
        &is_nil(values[&1])
      )

    if values["resource_type"] == expected_type and not is_nil(values["resource_id"]) and
         only_resource_pair? do
      ok(kind, values)
    else
      invalid()
    end
  end

  defp ok(kind, values) do
    scope = %__MODULE__{
      kind: kind,
      resource_type: values["resource_type"],
      resource_id: values["resource_id"],
      workflow_id: values["workflow_id"],
      step: values["step"],
      incident_fingerprint: values["incident_fingerprint"],
      view: values["view"]
    }

    {:ok, scope, canonical_params(scope)}
  end

  defp invalid, do: {:invalid, [], @invalid_notice}
end
