defmodule ObanPowertools.Chain do
  @moduledoc """
  Public builder API for strictly linear job chains.
  """

  alias Ecto.Changeset
  alias ObanPowertools.Batch

  defstruct name: nil, steps: []

  defmodule Step do
    @moduledoc false

    defstruct [:name, :index, :worker, :job, :args_builder, :requires_output?]
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
      insert_first_job(chain, batch, opts)
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
    with {:ok, steps} <- validate_steps(steps) do
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

  defp insert_first_job(%__MODULE__{} = chain, %Batch{} = batch, opts) do
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
        {:error, reason}
    end
  end

  defp do_oban_insert(Oban, changeset, opts), do: Oban.insert(changeset, opts)
  defp do_oban_insert(oban, changeset, opts), do: Oban.insert(oban, changeset, opts)

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
end
