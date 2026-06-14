defmodule ObanPowertools.Chain do
  @moduledoc """
  Public builder API for strictly linear job chains.
  """

  alias Ecto.Changeset
  alias ObanPowertools.Batch
  alias ObanPowertools.JobRecord
  alias ObanPowertools.RuntimeConfig

  defstruct name: nil, steps: []

  defmodule Step do
    @moduledoc false

    defstruct [:name, :index, :worker, :worker_module, :job, :args_builder, :requires_output?]
  end

  defmodule InsertResult do
    @moduledoc """
    Compact result for successful chain insertion.
    """

    defstruct [:chain_id, :batch_id, :first_job_id, :step_count]
  end

  def chain(seed, step_name, next_job_or_worker),
    do: chain(seed, step_name, next_job_or_worker, [])

  def chain({:error, _reason} = error, _step_name, _next_job_or_worker, _opts), do: error

  def chain(%__MODULE__{} = chain, step_name, next_job_or_worker, opts) when is_list(opts) do
    with {:ok, step} <- build_step(step_name, next_job_or_worker, opts, length(chain.steps)),
         {:ok, steps} <- validate_steps(chain.steps ++ [step]) do
      %__MODULE__{chain | steps: steps}
    end
  end

  def chain(%Changeset{} = seed, step_name, next_job_or_worker, opts) when is_list(opts) do
    with {:ok, first_step} <- seed_step(seed),
         {:ok, chain} <- from_steps([first_step]) do
      chain(chain, step_name, next_job_or_worker, opts)
    end
  end

  def chain(%Oban.Job{} = seed, step_name, next_job_or_worker, opts) when is_list(opts) do
    with {:ok, first_step} <- seed_step(seed),
         {:ok, chain} <- from_steps([first_step]) do
      chain(chain, step_name, next_job_or_worker, opts)
    end
  end

  def chain(_seed, _step_name, next_job_or_worker, _opts)
      when is_list(next_job_or_worker) or is_struct(next_job_or_worker, __MODULE__),
      do: {:error, {:validation, :non_linear_chain}}

  def fetch_upstream_result(%Oban.Job{} = job) do
    RuntimeConfig.repo!()
    |> fetch_upstream_result(job)
  end

  def fetch_upstream_result(upstream_job_id) when is_integer(upstream_job_id) do
    RuntimeConfig.repo!()
    |> fetch_upstream_result(upstream_job_id)
  end

  def fetch_upstream_result(repo, %Oban.Job{meta: meta}) do
    case upstream_job_id_from_meta(meta) do
      nil -> {:error, :missing_upstream_job_id}
      upstream_job_id -> fetch_upstream_result(repo, upstream_job_id)
    end
  end

  def fetch_upstream_result(repo, upstream_job_id) when is_integer(upstream_job_id) do
    case JobRecord.fetch_record(repo, upstream_job_id) do
      {:ok, %JobRecord{} = record} -> available_record_result(record)
      {:error, :not_found} -> {:error, :output_unavailable}
    end
  end

  def from_list(entries, opts \\ [])

  def from_list(entries, opts) when is_list(entries) and entries != [] and is_list(opts) do
    entries
    |> Enum.reduce_while({:ok, []}, fn entry, {:ok, acc} ->
      index = length(acc)

      case build_entry_step(entry, index) do
        {:ok, step} -> {:cont, {:ok, acc ++ [step]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, steps} ->
        with {:ok, steps} <- validate_steps(steps) do
          %__MODULE__{name: normalize_optional_name(Keyword.get(opts, :name)), steps: steps}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def from_list(_entries, _opts), do: {:error, {:validation, :non_linear_chain}}

  def insert(%__MODULE__{} = chain, repo), do: insert(chain, repo, [])
  def insert(repo, %__MODULE__{} = chain), do: insert(chain, repo, [])

  def insert(%__MODULE__{} = chain, repo, opts) when is_list(opts) do
    with {:ok, chain} <- normalize_chain(chain, opts),
         {:ok, batch} <- insert_batch(chain, repo) do
      insert_first_job(chain, batch, repo, opts)
    end
  end

  defp from_steps(steps) do
    with {:ok, steps} <- validate_steps(steps) do
      {:ok, %__MODULE__{steps: steps}}
    end
  end

  defp build_entry_step({_step_name, next_jobs}, _index) when is_list(next_jobs),
    do: {:error, {:validation, :non_linear_chain}}

  defp build_entry_step({step_name, next_job_or_worker}, index) do
    build_step(step_name, next_job_or_worker, [], index)
  end

  defp build_entry_step({step_name, next_job_or_worker, opts}, index) when is_list(opts) do
    build_step(step_name, next_job_or_worker, opts, index)
  end

  defp build_entry_step(_entry, _index), do: {:error, {:validation, :non_linear_chain}}

  defp build_step(_step_name, next_jobs, _opts, _index) when is_list(next_jobs),
    do: {:error, {:validation, :non_linear_chain}}

  defp build_step(_step_name, %__MODULE__{}, _opts, _index),
    do: {:error, {:validation, :non_linear_chain}}

  defp build_step(step_name, %Changeset{} = job, opts, index) do
    with {:ok, args_builder} <- normalize_args_builder(Keyword.get(opts, :args)) do
      {:ok,
       %Step{
         name: normalize_name(step_name),
         index: index,
         worker: worker_name(job),
         worker_module: worker_module(job),
         job: job,
         args_builder: args_builder,
         requires_output?: not is_nil(args_builder)
       }}
    end
  end

  defp build_step(step_name, %Oban.Job{} = job, opts, index) do
    build_step(step_name, job_changeset(job), opts, index)
  end

  defp build_step(step_name, worker, opts, index) when is_atom(worker) do
    with {:ok, args_builder} <- normalize_args_builder(Keyword.get(opts, :args)),
         {:ok, job} <- worker_changeset(worker, Keyword.get(opts, :args), args_builder) do
      {:ok,
       %Step{
         name: normalize_name(step_name),
         index: index,
         worker: inspect(worker),
         worker_module: worker,
         job: job,
         args_builder: args_builder,
         requires_output?: not is_nil(args_builder)
       }}
    end
  end

  defp build_step(_step_name, _next_job_or_worker, _opts, _index),
    do: {:error, {:validation, :non_linear_chain}}

  defp seed_step(%Changeset{} = seed) do
    name = seed |> worker_name() |> derived_step_name()

    {:ok,
     %Step{
       name: name,
       index: 0,
       worker: worker_name(seed),
       worker_module: worker_module(seed),
       job: seed,
       args_builder: nil,
       requires_output?: false
     }}
  end

  defp seed_step(%Oban.Job{} = job), do: seed_step(job_changeset(job))

  defp validate_steps([]), do: {:error, {:validation, :non_linear_chain}}

  defp validate_steps(steps) do
    names = Enum.map(steps, & &1.name)

    case Enum.find(names, fn name -> Enum.count(names, &(&1 == name)) > 1 end) do
      nil -> {:ok, Enum.with_index(steps, &%{&1 | index: &2})}
      name -> {:error, {:validation, {:duplicate_step_name, name}}}
    end
  end

  defp normalize_chain(%__MODULE__{steps: steps} = chain, opts) do
    with {:ok, steps} <- validate_steps(steps),
         :ok <- validate_output_dependencies(steps) do
      {:ok,
       %__MODULE__{
         chain
         | name: normalize_optional_name(Keyword.get(opts, :name, chain.name)),
           steps: steps
       }}
    end
  end

  defp insert_batch(%__MODULE__{} = chain, repo) do
    %Batch{}
    |> Batch.changeset(%{
      name: chain.name,
      status: "executing",
      total_count: length(chain.steps)
    })
    |> repo.insert()
  end

  defp insert_first_job(%__MODULE__{} = chain, %Batch{} = batch, repo, opts) do
    [first_step | tail] = chain.steps
    meta = first_job_meta(chain, batch, first_step, tail)
    changeset = put_job_meta(first_step.job, meta)
    oban = Keyword.get(opts, :oban, Oban)
    oban_opts = Keyword.take(opts, [:timeout])

    case do_oban_insert(oban, changeset, oban_opts) do
      {:ok, job} ->
        {:ok,
         %InsertResult{
           chain_id: batch.id,
           batch_id: batch.id,
           first_job_id: job.id,
           step_count: length(chain.steps)
         }}

      {:error, reason} ->
        mark_first_insert_failed(repo, batch, reason)
        {:error, reason}
    end
  rescue
    error ->
      mark_first_insert_failed(repo, batch, error)
      {:error, error}
  catch
    kind, reason ->
      caught = {kind, reason}
      mark_first_insert_failed(repo, batch, caught)
      {:error, caught}
  end

  defp do_oban_insert(Oban, changeset, opts), do: Oban.insert(changeset, opts)
  defp do_oban_insert(oban, changeset, opts), do: Oban.insert(oban, changeset, opts)

  defp mark_first_insert_failed(repo, %Batch{} = batch, reason) do
    batch
    |> Batch.changeset(%{
      status: "insert_failed",
      insert_failed_chunk: 1,
      insert_failure: first_insert_failure_payload(reason),
      insert_failed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    })
    |> repo.update()
  end

  defp first_insert_failure_payload(reason) do
    %{
      "reason" => inspect(reason),
      "kind" => "insert",
      "message" => inspect(reason)
    }
  end

  defp first_job_meta(chain, batch, step, tail) do
    base = %{
      "batch_id" => batch.id,
      "chain_id" => batch.id,
      "chain_step_name" => step.name,
      "chain_step_index" => step.index,
      "chain_step_count" => length(chain.steps)
    }

    base
    |> maybe_put("chain_name", chain.name)
    |> maybe_put("batch_name", chain.name)
    |> maybe_put_next_step(tail)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_next_step(meta, []), do: meta

  defp maybe_put_next_step(meta, [next_step | remaining]) do
    Map.put(meta, "chain_next_step", %{
      "step" => step_descriptor(next_step),
      "remaining" => Enum.map(remaining, &step_descriptor/1)
    })
  end

  defp step_descriptor(%Step{} = step) do
    %{
      "name" => step.name,
      "index" => step.index,
      "worker" => step.worker,
      "args" => Changeset.get_field(step.job, :args) || %{},
      "queue" => Changeset.get_field(step.job, :queue) || "default",
      "meta" => Changeset.get_field(step.job, :meta) || %{},
      "requires_output" => step.requires_output?
    }
    |> maybe_put("args_builder", args_builder_descriptor(step.args_builder))
  end

  defp args_builder_descriptor(nil), do: nil

  defp args_builder_descriptor({module, function, extra_args}) do
    %{
      "module" => inspect(module),
      "function" => Atom.to_string(function),
      "extra_args" => normalize_payload(extra_args)
    }
  end

  defp put_job_meta(%Changeset{} = changeset, meta) do
    existing_meta = Changeset.get_field(changeset, :meta) || %{}
    Changeset.put_change(changeset, :meta, Map.merge(existing_meta, meta))
  end

  defp worker_changeset(worker, _args, {_module, _function, _extra_args}) do
    {:ok, worker.new(%{})}
  end

  defp worker_changeset(worker, args, nil) when is_map(args) do
    {:ok, worker.new(args)}
  end

  defp worker_changeset(worker, nil, nil) do
    {:ok, worker.new(%{})}
  end

  defp worker_changeset(_worker, _args, _args_builder),
    do: {:error, {:validation, :non_linear_chain}}

  defp normalize_args_builder(nil), do: {:ok, nil}

  defp normalize_args_builder({module, function, extra_args} = builder)
       when is_atom(module) and is_atom(function) and is_list(extra_args),
       do: {:ok, builder}

  defp normalize_args_builder(fun) when is_function(fun),
    do: {:error, {:validation, :anonymous_builder_not_allowed}}

  defp normalize_args_builder(args) when is_map(args), do: {:ok, nil}

  defp normalize_args_builder(_args), do: {:error, {:validation, :non_linear_chain}}

  defp worker_name(%Changeset{} = changeset), do: Changeset.get_field(changeset, :worker)

  defp worker_module(%Changeset{} = changeset) do
    changeset
    |> worker_name()
    |> module_from_worker_name()
  end

  defp module_from_worker_name(worker) when is_atom(worker), do: worker

  defp module_from_worker_name(worker) when is_binary(worker) do
    Module.safe_concat([worker])
  rescue
    ArgumentError -> nil
  end

  defp module_from_worker_name(_worker), do: nil

  defp job_changeset(%Oban.Job{} = job) do
    Oban.Job.new(job.args || %{},
      worker: job.worker,
      queue: job.queue || "default",
      meta: job.meta || %{}
    )
  end

  defp derived_step_name(nil), do: "start"

  defp derived_step_name(worker) do
    worker
    |> to_string()
    |> String.split(".")
    |> List.last()
    |> String.replace_suffix("Worker", "")
    |> Macro.underscore()
    |> case do
      "" -> "start"
      name -> name
    end
  end

  defp normalize_name(name) when is_atom(name), do: Atom.to_string(name)
  defp normalize_name(name) when is_binary(name), do: name
  defp normalize_name(name), do: to_string(name)

  defp normalize_optional_name(nil), do: nil
  defp normalize_optional_name(name), do: normalize_name(name)

  defp normalize_payload(%_{} = struct), do: struct |> Map.from_struct() |> normalize_payload()

  defp normalize_payload(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), normalize_payload(value)} end)
  end

  defp normalize_payload(list) when is_list(list), do: Enum.map(list, &normalize_payload/1)
  defp normalize_payload(value), do: value

  defp upstream_job_id_from_meta(meta) when is_map(meta) do
    Map.get(meta, "upstream_job_id") || Map.get(meta, :upstream_job_id)
  end

  defp upstream_job_id_from_meta(_meta), do: nil

  defp available_record_result(%JobRecord{expires_at: expires_at, payload: payload}) do
    case DateTime.compare(expires_at, DateTime.utc_now()) do
      :lt -> {:error, :output_expired}
      _not_expired -> {:ok, payload}
    end
  end

  defp validate_output_dependencies(steps) do
    steps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find_value(:ok, fn [previous, current] ->
      if current.args_builder do
        with :ok <- validate_args_builder(current.args_builder),
             :ok <- validate_record_output(previous) do
          false
        else
          {:error, reason} -> {:error, {:validation, reason}}
        end
      else
        false
      end
    end)
  end

  defp validate_args_builder({module, function, extra_args}) when is_list(extra_args) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         true <- function_exported?(module, :__powertools_chain_args_builder__, 0),
         true <- module.__powertools_chain_args_builder__(),
         true <- function_exported?(module, function, 2) do
      :ok
    else
      {:error, _reason} -> {:error, {:unsafe_args_builder, module}}
      false -> {:error, {:unsafe_args_builder, module}}
    end
    |> case do
      :ok -> :ok
      {:error, {:unsafe_args_builder, ^module}} = error -> error
    end
    |> validate_args_builder_function(module, function)
  end

  defp validate_args_builder({module, function, _extra_args}),
    do: {:error, {:invalid_args_builder, {module, function}}}

  defp validate_args_builder_function(:ok, _module, _function), do: :ok

  defp validate_args_builder_function(
         {:error, {:unsafe_args_builder, module}} = error,
         module,
         function
       ) do
    if Code.ensure_loaded?(module) and
         function_exported?(module, :__powertools_chain_args_builder__, 0) and
         module.__powertools_chain_args_builder__() == true and
         not function_exported?(module, function, 2) do
      {:error, {:invalid_args_builder, {module, function}}}
    else
      error
    end
  end

  defp validate_record_output(%Step{worker_module: worker}) when is_atom(worker) do
    if function_exported?(worker, :__powertools_output_recording__, 0) and
         match?(%{record_output: true}, worker.__powertools_output_recording__()) do
      :ok
    else
      {:error, {:record_output_required, worker}}
    end
  end

  defp validate_record_output(%Step{worker: worker}) do
    {:error, {:record_output_required, worker}}
  end
end
