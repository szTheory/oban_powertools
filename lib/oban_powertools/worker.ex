defmodule ObanPowertools.Worker do
  @moduledoc """
  A wrapper around `Oban.Worker` that provides typed arguments and synchronous validation.
  """

  defmacro __using__(opts) do
    args_config = Keyword.get(opts, :args, [])
    limits_config = Keyword.get(opts, :limits, [])
    oban_opts = opts |> Keyword.delete(:args) |> Keyword.delete(:limits)
    validate_args_config!(args_config)
    normalized_limits = normalize_limits_config!(limits_config, __CALLER__.module)

    fields =
      for {name, type} <- args_config do
        quote do
          field(unquote(name), unquote(type))
        end
      end

    quote do
      use Oban.Worker, unquote(oban_opts)
      @behaviour __MODULE__
      import Ecto.Changeset
      @powertools_limits unquote(Macro.escape(normalized_limits))

      @callback process(Oban.Job.t()) ::
                  :ok
                  | {:ok, term()}
                  | {:error, term()}
                  | {:cancel, term()}
                  | {:snooze, integer()}
                  | term()

      def __powertools_limits__, do: @powertools_limits

      defmodule Args do
        use Ecto.Schema
        @primary_key false

        embedded_schema do
          unquote(fields)
        end

        def changeset(struct, params) do
          fields = unquote(Keyword.keys(args_config))

          struct
          |> cast(params, fields)
          |> validate_required(fields)
        end
      end

      @doc """
      Validates the given arguments against the worker's schema.
      """
      def validate(params) do
        %Args{}
        |> Args.changeset(params)
        |> case do
          %{valid?: true} = changeset -> {:ok, apply_changes(changeset)}
          changeset -> {:error, changeset}
        end
      end

      @impl Oban.Worker
      def perform(%Oban.Job{args: args} = job) when is_map(args) do
        case validate(args) do
          {:ok, casted_args} ->
            process(%{job | args: casted_args})

          {:error, changeset} ->
            {:error, changeset}
        end
      end

      def perform(%Oban.Job{args: %Args{}} = job) do
        process(job)
      end

      @doc """
      Enqueues a job with the given arguments, validating them synchronously.
      """
      def enqueue(args, opts \\ []) do
        ObanPowertools.Idempotency.transaction(__MODULE__, args, opts)
      end
    end
  end

  def limit_snapshot(worker_mod, args) do
    limits =
      if function_exported?(worker_mod, :__powertools_limits__, 0) do
        worker_mod.__powertools_limits__()
      else
        []
      end

    args_map = if is_struct(args), do: Map.from_struct(args), else: args

    if limits == [] do
      {:ok, nil}
    else
      partition_key = resolve_partition(limits[:partition_by], args_map, worker_mod)
      weight = resolve_weight(limits[:weight_by], limits[:default_weight], args_map, worker_mod)

      {:ok,
       %{
         worker: inspect(worker_mod),
         resource_name: limits[:name],
         scope_kind: Atom.to_string(limits[:scope]),
         bucket_capacity: limits[:bucket_capacity],
         bucket_span_ms: limits[:bucket_span_ms],
         default_weight: limits[:default_weight],
         partition_strategy: limits[:partition_strategy],
         partition_config: limits[:partition_config],
         partition_key: partition_key,
         weight: weight,
         binding: %{
           "resource" => limits[:name],
           "scope" => Atom.to_string(limits[:scope]),
           "partition_key" => partition_key,
           "weight" => weight
         }
       }}
    end
  end

  defp validate_args_config!(args_config) when is_list(args_config) do
    Enum.each(args_config, fn
      {name, type} ->
        validate_arg_field!(name, type)

      invalid_entry ->
        raise ArgumentError,
              "expected :args to be a keyword list of {field, type} entries, got: #{inspect(invalid_entry)}"
    end)
  end

  defp validate_args_config!(args_config) do
    raise ArgumentError,
          "expected :args to be a keyword list, got: #{inspect(args_config)}"
  end

  defp valid_field_type?(type) when is_atom(type), do: true
  defp valid_field_type?({:array, inner_type}), do: valid_field_type?(inner_type)
  defp valid_field_type?({:map, inner_type}), do: valid_field_type?(inner_type)
  defp valid_field_type?({:parameterized, _module, _params}), do: true
  defp valid_field_type?(_type), do: false

  defp validate_arg_field!(name, type) when is_atom(name) do
    if valid_field_type?(type) do
      :ok
    else
      raise ArgumentError,
            "expected :args field types to be Ecto-compatible atoms or container tuples, got: #{inspect(type)} for #{inspect(name)}"
    end
  end

  defp validate_arg_field!(name, _type) do
    raise ArgumentError,
          "expected :args fields to use atom names, got: #{inspect(name)}"
  end

  defp normalize_limits_config!([], _module), do: []

  defp normalize_limits_config!(limits_config, module) when is_list(limits_config) do
    name = fetch_limit!(limits_config, :name)
    scope = fetch_limit!(limits_config, :scope)
    bucket_capacity = fetch_limit!(limits_config, :bucket_capacity)
    bucket_span_ms = fetch_limit!(limits_config, :bucket_span_ms)
    default_weight = Keyword.get(limits_config, :default_weight, 1)
    partition_by = Keyword.get(limits_config, :partition_by)
    weight_by = Keyword.get(limits_config, :weight_by)

    unless is_binary(name) and byte_size(name) > 0 do
      raise ArgumentError, "expected :limits name to be a non-empty string"
    end

    unless scope in [:global, :partitioned] do
      raise ArgumentError, "expected :limits scope to be :global or :partitioned"
    end

    validate_positive_integer!(bucket_capacity, ":limits bucket_capacity")
    validate_positive_integer!(bucket_span_ms, ":limits bucket_span_ms")
    validate_positive_integer!(default_weight, ":limits default_weight")
    validate_resolver!(partition_by, module, :partition_by)
    validate_resolver!(weight_by, module, :weight_by)

    if scope == :partitioned and is_nil(partition_by) do
      raise ArgumentError, "expected partitioned :limits to declare :partition_by"
    end

    if scope == :global and not is_nil(partition_by) do
      raise ArgumentError, "expected global :limits to omit :partition_by"
    end

    defaults = ObanPowertools.Limits.partition_defaults()

    [
      name: name,
      scope: scope,
      bucket_capacity: bucket_capacity,
      bucket_span_ms: bucket_span_ms,
      default_weight: default_weight,
      partition_by: partition_by,
      weight_by: weight_by,
      partition_strategy:
        if(scope == :global, do: defaults.partition_strategy, else: "partitioned"),
      partition_config:
        if(scope == :global,
          do: defaults.partition_config,
          else: %{resolver: resolver_name(partition_by)}
        )
    ]
  end

  defp normalize_limits_config!(limits_config, _module) do
    raise ArgumentError,
          "expected :limits to be a keyword list, got: #{inspect(limits_config)}"
  end

  defp fetch_limit!(limits_config, key) do
    case Keyword.fetch(limits_config, key) do
      {:ok, value} -> value
      :error -> raise ArgumentError, "expected :limits to include #{inspect(key)}"
    end
  end

  defp validate_positive_integer!(value, _label) when is_integer(value) and value > 0, do: :ok

  defp validate_positive_integer!(value, label) do
    raise ArgumentError, "expected #{label} to be a positive integer, got: #{inspect(value)}"
  end

  defp validate_resolver!(nil, _module, _field), do: :ok
  defp validate_resolver!({:args, key}, _module, _field) when is_atom(key), do: :ok

  defp validate_resolver!({module, function}, _owner_module, _field)
       when is_atom(module) and is_atom(function),
       do: :ok

  defp validate_resolver!({:worker, function}, owner_module, _field) when is_atom(function) do
    validate_resolver!({owner_module, function}, owner_module, nil)
  end

  defp validate_resolver!(resolver, _module, field) do
    raise ArgumentError,
          "expected #{inspect(field)} to be {:args, atom}, {:worker, atom}, or {Module, function}, got: #{inspect(resolver)}"
  end

  defp resolve_partition(nil, _args, _worker_mod),
    do: ObanPowertools.Limits.partition_defaults().partition_key

  defp resolve_partition(resolver, args, worker_mod) do
    resolver
    |> resolve_binding(args, worker_mod)
    |> normalize_partition_key()
  end

  defp resolve_weight(nil, default_weight, _args, _worker_mod), do: default_weight

  defp resolve_weight(resolver, _default_weight, args, worker_mod) do
    case resolve_binding(resolver, args, worker_mod) do
      weight when is_integer(weight) and weight > 0 ->
        weight

      invalid ->
        raise ArgumentError,
              "expected resolved limit weight to be a positive integer, got: #{inspect(invalid)}"
    end
  end

  defp resolve_binding({:args, key}, args, _worker_mod), do: Map.get(args, key)

  defp resolve_binding({:worker, function}, args, worker_mod),
    do: apply(worker_mod, function, [args])

  defp resolve_binding({module, function}, args, _worker_mod), do: apply(module, function, [args])

  defp normalize_partition_key(nil),
    do: raise(ArgumentError, "expected partition resolver to return a value")

  defp normalize_partition_key(value) when is_binary(value), do: value
  defp normalize_partition_key(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_partition_key(value) when is_integer(value), do: Integer.to_string(value)
  defp normalize_partition_key(value), do: inspect(value)

  defp resolver_name(nil), do: "global"
  defp resolver_name({:args, key}), do: "args:#{key}"
  defp resolver_name({:worker, function}), do: "worker:#{function}"
  defp resolver_name({module, function}), do: "#{inspect(module)}.#{function}"
end
