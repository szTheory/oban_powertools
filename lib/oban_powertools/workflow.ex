defmodule ObanPowertools.Workflow do
  @moduledoc """
  Explicit builder and insert API for durable workflow DAG definitions.
  """

  alias Ecto.Changeset
  alias Ecto.Multi
  alias ObanPowertools.Workflow.Edge
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.Workflow.Workflow, as: WorkflowRecord

  defstruct name: nil,
            workflow_context: %{},
            definition_version: 1,
            steps: [],
            edges: []

  defmodule ResultRef do
    @moduledoc false
    defstruct [:step_name]
  end

  @type t :: %__MODULE__{
          name: String.t() | nil,
          workflow_context: map(),
          definition_version: pos_integer(),
          steps: [map()],
          edges: [map()]
        }

  def new(opts) when is_list(opts) do
    %__MODULE__{
      name: normalize_optional_name(Keyword.get(opts, :name)),
      workflow_context: Keyword.get(opts, :workflow_context, %{}),
      definition_version: Keyword.get(opts, :definition_version, 1)
    }
  end

  def add(%__MODULE__{} = workflow, step_name, job_definition, opts \\ []) do
    base_step =
      job_definition
      |> normalize_job_definition()
      |> Map.merge(%{
        name: normalize_name(step_name),
        context: Keyword.get(opts, :context, %{}),
        deps: Enum.map(Keyword.get(opts, :deps, []), &normalize_name/1)
      })

    dependency_edges =
      Enum.map(base_step.deps, fn dependency ->
        %{from: dependency, to: base_step.name, policy: "cancel"}
      end)

    %{
      workflow
      | steps: workflow.steps ++ [base_step],
        edges: workflow.edges ++ dependency_edges
    }
  end

  def add_many(%__MODULE__{} = workflow, additions, opts \\ []) when is_list(additions) do
    Enum.reduce(additions, workflow, fn
      {step_name, job_definition}, acc ->
        add(acc, step_name, job_definition, opts)

      {step_name, job_definition, step_opts}, acc ->
        add(acc, step_name, job_definition, Keyword.merge(opts, step_opts))
    end)
  end

  def connect(%__MODULE__{} = workflow, from_step, to_step, opts \\ []) do
    edge = %{
      from: normalize_name(from_step),
      to: normalize_name(to_step),
      policy: normalize_policy(Keyword.get(opts, :policy, Keyword.get(opts, :on_failure, :cancel)))
    }

    %{workflow | edges: workflow.edges ++ [edge]}
  end

  def result(step_name), do: %ResultRef{step_name: normalize_name(step_name)}

  def insert(%__MODULE__{} = workflow, repo) do
    with {:ok, normalized} <- normalize(workflow) do
      persist(repo, normalized)
    end
  end

  def insert(repo, %__MODULE__{} = workflow), do: insert(workflow, repo)
  def complete_step(repo, workflow_id, step_name, attrs \\ []),
    do: ObanPowertools.Workflow.Runtime.complete_step(repo, workflow_id, step_name, Enum.into(attrs, %{}))

  defp normalize(%__MODULE__{} = workflow) do
    with {:ok, steps} <- normalize_steps(workflow.steps),
         :ok <- validate_workflow_name(workflow.name),
         :ok <- validate_duplicate_step_names(steps),
         :ok <- validate_edge_targets(steps, workflow.edges),
         :ok <- validate_no_self_loops(workflow.edges),
         :ok <- validate_acyclic(steps, workflow.edges),
         {:ok, workflow_context} <- ensure_json(workflow.workflow_context) do
      edges = Enum.map(workflow.edges, &normalize_edge_definition/1)

      incoming =
        Enum.reduce(edges, %{}, fn edge, acc ->
          Map.update(acc, edge.to, [edge.from], &[edge.from | &1])
        end)

      normalized_steps =
        steps
        |> Enum.with_index()
        |> Enum.map(fn {step, index} ->
          dependencies = Map.get(incoming, step.name, []) |> Enum.sort()

          Map.merge(step, %{
            position: index,
            state: if(dependencies == [], do: "available", else: "pending"),
            dependency_count: length(dependencies),
            dependency_snapshot: %{"dependencies" => dependencies},
            blocker_codes: if(dependencies == [], do: [], else: ["waiting_on_dependencies"]),
            blocker_details: blocker_details(dependencies)
          })
        end)

      {:ok,
       %{
         name: workflow.name,
         workflow_context: workflow_context,
         definition_version: workflow.definition_version,
         steps: normalized_steps,
         edges: edges,
         runnable_step_count: Enum.count(normalized_steps, &(&1.state == "available"))
       }}
    end
  end

  defp persist(repo, normalized) do
    workflow_attrs = %{
      name: normalized.name,
      workflow_context: normalized.workflow_context,
      definition_version: normalized.definition_version,
      state: if(normalized.runnable_step_count > 0, do: "available", else: "pending"),
      step_count: length(normalized.steps),
      runnable_step_count: normalized.runnable_step_count,
      completed_step_count: 0,
      cancelled_step_count: 0,
      failed_step_count: 0
    }

    Multi.new()
    |> Multi.insert(:workflow, WorkflowRecord.changeset(%WorkflowRecord{}, workflow_attrs))
    |> Multi.run(:steps, fn repo, %{workflow: workflow} ->
      insert_steps(repo, workflow, normalized.steps)
    end)
    |> Multi.run(:edges, fn repo, %{workflow: workflow, steps: steps} ->
      insert_edges(repo, workflow, steps, normalized.edges)
    end)
    |> repo.transaction()
    |> case do
      {:ok, %{workflow: workflow}} -> {:ok, workflow}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp insert_steps(repo, workflow, steps) do
    Enum.reduce_while(steps, {:ok, %{}}, fn step, {:ok, acc} ->
      attrs = %{
        workflow_id: workflow.id,
        step_name: step.name,
        worker: step.worker,
        input: step.input,
        context: step.context,
        state: step.state,
        queue: step.queue,
        attempt: 0,
        position: step.position,
        dependency_count: step.dependency_count,
        dependency_snapshot: step.dependency_snapshot,
        blocker_codes: step.blocker_codes,
        blocker_details: step.blocker_details
      }

      case repo.insert(Step.changeset(%Step{}, attrs)) do
        {:ok, record} -> {:cont, {:ok, Map.put(acc, step.name, record)}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp insert_edges(repo, workflow, steps, edges) do
    Enum.reduce_while(edges, {:ok, []}, fn edge, {:ok, acc} ->
      attrs = %{
        workflow_id: workflow.id,
        from_step_id: Map.fetch!(steps, edge.from).id,
        to_step_id: Map.fetch!(steps, edge.to).id,
        policy: edge.policy,
        terminal_snapshot: %{}
      }

      case repo.insert(Edge.changeset(%Edge{}, attrs)) do
        {:ok, record} -> {:cont, {:ok, [record | acc]}}
        {:error, changeset} -> {:halt, {:error, changeset}}
      end
    end)
  end

  defp normalize_steps(steps) do
    Enum.reduce_while(steps, {:ok, []}, fn step, {:ok, acc} ->
      case normalize_step_definition(step) do
        {:ok, normalized} -> {:cont, {:ok, acc ++ [normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_job_definition(%Changeset{} = changeset) do
    worker = Changeset.get_field(changeset, :worker)
    input = Changeset.get_field(changeset, :args) || %{}
    queue = Changeset.get_field(changeset, :queue) || "default"
    meta = Changeset.get_field(changeset, :meta) || %{}

    if is_nil(worker) do
      raise ArgumentError, "workflow steps require a job changeset with a worker"
    end

    %{
      worker: worker,
      input: normalize_payload(input),
      context: normalize_payload(meta),
      queue: to_string(queue)
    }
  end

  defp normalize_job_definition(%Oban.Job{} = job) do
    %{
      worker: job.worker,
      input: normalize_payload(job.args || %{}),
      context: normalize_payload(job.meta || %{}),
      queue: to_string(job.queue || "default")
    }
  end

  defp normalize_job_definition(%{worker: worker, input: input} = step) do
    %{
      worker: to_string(worker),
      input: normalize_payload(input),
      context: normalize_payload(Map.get(step, :context, %{})),
      queue: to_string(Map.get(step, :queue, "default"))
    }
  end

  defp normalize_job_definition(other) do
    raise ArgumentError,
          "workflow steps expect an Oban job changeset, Oban job, or %{worker:, input:} map, got: #{inspect(other)}"
  end

  defp normalize_step_definition(%{name: name, worker: worker, input: input} = step) do
    with {:ok, normalized_input} <- ensure_json(input),
         {:ok, normalized_context} <- ensure_json(Map.get(step, :context, %{})) do
      {:ok,
       %{
         name: normalize_name(name),
         worker: to_string(worker),
         input: normalized_input,
         context: normalized_context,
         queue: to_string(Map.get(step, :queue, "default"))
       }}
    end
  end

  defp normalize_step_definition(_step), do: {:error, {:validation, :invalid_step_definition}}

  defp normalize_edge_definition(%{from: from, to: to} = edge) do
    %{
      from: normalize_name(from),
      to: normalize_name(to),
      policy: normalize_policy(Map.get(edge, :policy, "cancel"))
    }
  end

  defp validate_workflow_name(name) when is_binary(name) and byte_size(name) > 0, do: :ok
  defp validate_workflow_name(_name), do: {:error, {:validation, :workflow_name_required}}

  defp validate_duplicate_step_names(steps) do
    names = Enum.map(steps, & &1.name)

    case Enum.find(names, fn name -> Enum.count(names, &(&1 == name)) > 1 end) do
      nil -> :ok
      name -> {:error, {:validation, {:duplicate_step_name, name}}}
    end
  end

  defp validate_edge_targets(steps, raw_edges) do
    names = MapSet.new(Enum.map(steps, & &1.name))
    edges = Enum.map(raw_edges, &normalize_edge_definition/1)

    case Enum.find(edges, fn edge ->
           not MapSet.member?(names, edge.from) or not MapSet.member?(names, edge.to)
         end) do
      nil -> :ok
      edge -> {:error, {:validation, {:missing_dependency, edge}}}
    end
  end

  defp validate_no_self_loops(raw_edges) do
    edges = Enum.map(raw_edges, &normalize_edge_definition/1)

    case Enum.find(edges, &(&1.from == &1.to)) do
      nil -> :ok
      edge -> {:error, {:validation, {:self_loop, edge.from}}}
    end
  end

  defp validate_acyclic(steps, raw_edges) do
    names = Enum.map(steps, & &1.name)
    edges = Enum.map(raw_edges, &normalize_edge_definition/1)

    adjacency =
      Enum.reduce(names, %{}, fn name, acc -> Map.put(acc, name, []) end)
      |> then(fn acc ->
        Enum.reduce(edges, acc, fn edge, map -> Map.update!(map, edge.from, &[edge.to | &1]) end)
      end)

    case Enum.find_value(names, fn name -> dfs_cycle(name, adjacency, MapSet.new(), MapSet.new()) end) do
      nil -> :ok
      node -> {:error, {:validation, {:cycle_detected, node}}}
    end
  end

  defp dfs_cycle(name, adjacency, visited, stack) do
    cond do
      MapSet.member?(stack, name) ->
        name

      MapSet.member?(visited, name) ->
        nil

      true ->
        visited = MapSet.put(visited, name)
        stack = MapSet.put(stack, name)

        Enum.find_value(Map.get(adjacency, name, []), fn child ->
          dfs_cycle(child, adjacency, visited, stack)
        end)
    end
  end

  defp ensure_json(value) do
    normalized = normalize_payload(value)
    Jason.encode!(normalized)
    {:ok, normalized}
  rescue
    Protocol.UndefinedError ->
      {:error, {:validation, :non_serializable_payload}}
  end

  defp normalize_payload(%ResultRef{step_name: step_name}), do: %{"$result" => step_name}
  defp normalize_payload(%_{} = struct), do: struct |> Map.from_struct() |> normalize_payload()

  defp normalize_payload(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), normalize_payload(value)} end)
  end

  defp normalize_payload(list) when is_list(list), do: Enum.map(list, &normalize_payload/1)
  defp normalize_payload(value), do: value

  defp blocker_details([]), do: %{}
  defp blocker_details(dependencies), do: %{"dependencies" => dependencies}

  defp normalize_name(name) when is_atom(name), do: Atom.to_string(name)
  defp normalize_name(name) when is_binary(name), do: name
  defp normalize_name(name), do: to_string(name)

  defp normalize_optional_name(nil), do: nil
  defp normalize_optional_name(name), do: normalize_name(name)

  defp normalize_policy(policy) when policy in [:cancel, :continue], do: Atom.to_string(policy)
  defp normalize_policy(policy) when policy in ["cancel", "continue"], do: policy
  defp normalize_policy(policy), do: raise(ArgumentError, "invalid workflow edge policy: #{inspect(policy)}")
end
