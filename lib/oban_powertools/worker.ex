defmodule ObanPowertools.Worker do
  @moduledoc """
  A wrapper around `Oban.Worker` that provides typed arguments and synchronous validation.
  """

  defmacro __using__(opts) do
    args_config = Keyword.get(opts, :args, [])
    oban_opts = Keyword.delete(opts, :args)
    
    fields = for {name, type} <- args_config do
      quote do
        field(unquote(name), unquote(type))
      end
    end

    quote do
      use Oban.Worker, unquote(oban_opts)
      @behaviour __MODULE__
      import Ecto.Changeset

      @callback process(Oban.Job.t()) :: 
        :ok | 
        {:ok, term()} | 
        {:error, term()} | 
        {:cancel, term()} | 
        {:snooze, integer()} | 
        term()

      defmodule Args do
        @derive Jason.Encoder
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
            # If it's already a map but invalid, we return the error.
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
        ObanPowertools.Idempotency.enqueue(__MODULE__, args, opts)
      end
    end
  end


end
