defmodule ObanPowertools.Batch do
  @moduledoc """
  Durable batch tracking schema.
  """

  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @default_chunk_size 1_000

  defmodule InsertResult do
    @moduledoc """
    Compact result for successful batch stream insertion.
    """

    defstruct [:batch_id, :total_count, :inserted_count, :chunk_count]
  end

  defmodule InsertError do
    @moduledoc """
    Compact error for failed batch stream insertion.
    """

    defstruct [:batch_id, :total_count, :inserted_count, :failed_chunk, :reason]
  end

  schema "oban_powertools_batches" do
    field(:name, :string)
    field(:status, :string, default: "executing")
    field(:total_count, :integer, default: 0)
    field(:success_count, :integer, default: 0)
    field(:discard_count, :integer, default: 0)
    field(:cancelled_count, :integer, default: 0)
    field(:snooze_count, :integer, default: 0)
    field(:inserted_count, :integer, default: 0)
    field(:insert_chunk_count, :integer, default: 0)
    field(:insert_failed_chunk, :integer)
    field(:insert_failure, :map, default: %{})
    field(:insert_failed_at, :utc_datetime_usec)
    field(:completed_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [
      :status,
      :total_count,
      :success_count,
      :discard_count,
      :cancelled_count,
      :snooze_count,
      :name,
      :inserted_count,
      :insert_chunk_count,
      :insert_failed_chunk,
      :insert_failure,
      :insert_failed_at,
      :completed_at
    ])
    |> validate_required([
      :status,
      :total_count,
      :success_count,
      :discard_count,
      :cancelled_count,
      :snooze_count,
      :inserted_count,
      :insert_chunk_count,
      :insert_failure
    ])
    |> validate_number(:total_count, greater_than_or_equal_to: 0)
    |> validate_number(:success_count, greater_than_or_equal_to: 0)
    |> validate_number(:discard_count, greater_than_or_equal_to: 0)
    |> validate_number(:cancelled_count, greater_than_or_equal_to: 0)
    |> validate_number(:snooze_count, greater_than_or_equal_to: 0)
    |> validate_number(:inserted_count, greater_than_or_equal_to: 0)
    |> validate_number(:insert_chunk_count, greater_than_or_equal_to: 0)
    |> validate_number(:insert_failed_chunk, greater_than: 0)
  end

  def insert_stream(stream, opts) when is_list(opts) do
    with {:ok, config} <- validate_insert_stream_opts(opts),
         {:ok, batch} <- create_insert_batch(config) do
      stream
      |> Stream.chunk_every(config.chunk_size)
      |> Enum.reduce_while({:ok, %{inserted_count: 0, chunk_count: 0}}, fn chunk, {:ok, acc} ->
        chunk_number = acc.chunk_count + 1

        case insert_chunk(chunk, batch, config, chunk_number, acc.inserted_count) do
          {:ok, inserted_count} ->
            {:cont,
             {:ok,
              %{
                inserted_count: acc.inserted_count + inserted_count,
                chunk_count: chunk_number
              }}}

          {:error, %InsertError{} = error} ->
            {:halt, {:error, error}}
        end
      end)
      |> finalize_insert_stream(batch, config)
    end
  end

  def insert_stream(_stream, _opts) do
    {:error,
     %InsertError{
       batch_id: nil,
       total_count: nil,
       inserted_count: 0,
       failed_chunk: 0,
       reason: {:invalid_option, :opts}
     }}
  end

  defp validate_insert_stream_opts(opts) do
    cond do
      Keyword.has_key?(opts, :on_conflict) ->
        invalid_option(:on_conflict, opts)

      not Keyword.has_key?(opts, :total_count) ->
        invalid_option(:total_count, opts)

      not positive_integer?(Keyword.get(opts, :total_count)) ->
        invalid_option(:total_count, opts)

      not positive_integer?(Keyword.get(opts, :chunk_size, @default_chunk_size)) ->
        invalid_option(:chunk_size, opts)

      not is_atom(Keyword.get(opts, :repo)) ->
        invalid_option(:repo, opts)

      true ->
        {:ok,
         %{
           repo: Keyword.fetch!(opts, :repo),
           total_count: Keyword.fetch!(opts, :total_count),
           chunk_size: Keyword.get(opts, :chunk_size, @default_chunk_size),
           name: Keyword.get(opts, :name),
           batch_id: Keyword.get(opts, :batch_id),
           oban: Keyword.get(opts, :oban, Oban),
           oban_opts: Keyword.take(opts, [:timeout])
         }}
    end
  end

  defp invalid_option(option, opts) do
    {:error,
     %InsertError{
       batch_id: Keyword.get(opts, :batch_id),
       total_count: Keyword.get(opts, :total_count),
       inserted_count: 0,
       failed_chunk: 0,
       reason: {:invalid_option, option}
     }}
  end

  defp positive_integer?(value), do: is_integer(value) and value > 0

  defp create_insert_batch(%{repo: repo, batch_id: batch_id} = config) do
    if batch_id && repo.get(__MODULE__, batch_id) do
      {:error,
       %InsertError{
         batch_id: batch_id,
         total_count: config.total_count,
         inserted_count: 0,
         failed_chunk: 0,
         reason: :batch_id_exists
       }}
    else
      %__MODULE__{id: batch_id}
      |> changeset(%{
        status: "inserting",
        total_count: config.total_count,
        name: config.name
      })
      |> repo.insert()
      |> case do
        {:ok, batch} ->
          {:ok, batch}

        {:error, _changeset} ->
          {:error,
           %InsertError{
             batch_id: batch_id,
             total_count: config.total_count,
             inserted_count: 0,
             failed_chunk: 0,
             reason: :batch_insert_failed
           }}
      end
    end
  rescue
    _error in [Ecto.ConstraintError, Postgrex.Error] ->
      {:error,
       %InsertError{
         batch_id: batch_id,
         total_count: config.total_count,
         inserted_count: 0,
         failed_chunk: 0,
         reason: :batch_id_exists
       }}
  end

  defp insert_chunk(chunk, batch, config, chunk_number, inserted_so_far) do
    changesets = Enum.map(chunk, &put_batch_meta(&1, batch.id, config.name))

    inserted_jobs =
      case config.oban do
        Oban -> Oban.insert_all(changesets, config.oban_opts)
        oban -> Oban.insert_all(oban, changesets, config.oban_opts)
      end

    inserted_count = length(inserted_jobs)
    increment_insert_counts(config.repo, batch.id, inserted_count)
    {:ok, inserted_count}
  rescue
    error ->
      reason = exception_reason(error)

      fail_insert(
        config.repo,
        batch.id,
        config.total_count,
        inserted_so_far,
        chunk_number,
        reason
      )
  catch
    kind, reason ->
      reason = caught_reason(kind, reason)

      fail_insert(
        config.repo,
        batch.id,
        config.total_count,
        inserted_so_far,
        chunk_number,
        reason
      )
  end

  defp put_batch_meta(%Changeset{} = changeset, batch_id, name) do
    batch_meta =
      if is_nil(name) do
        %{"batch_id" => batch_id}
      else
        %{"batch_id" => batch_id, "batch_name" => name}
      end

    existing_meta = Changeset.get_field(changeset, :meta) || %{}
    Changeset.put_change(changeset, :meta, Map.merge(existing_meta, batch_meta))
  end

  defp increment_insert_counts(repo, batch_id, inserted_count) do
    repo.update_all(
      from(batch in __MODULE__, where: batch.id == ^batch_id),
      inc: [inserted_count: inserted_count, insert_chunk_count: 1],
      set: [updated_at: timestamp()]
    )
  end

  defp finalize_insert_stream({:error, %InsertError{} = error}, _batch, _config),
    do: {:error, error}

  defp finalize_insert_stream({:ok, acc}, batch, config) do
    if acc.inserted_count == config.total_count do
      config.repo.update_all(
        from(candidate in __MODULE__, where: candidate.id == ^batch.id),
        set: [status: "executing", updated_at: timestamp()]
      )

      {:ok,
       %InsertResult{
         batch_id: batch.id,
         total_count: config.total_count,
         inserted_count: acc.inserted_count,
         chunk_count: acc.chunk_count
       }}
    else
      reason = {:count_mismatch, %{expected: config.total_count, actual: acc.inserted_count}}
      failed_chunk = max(acc.chunk_count, 1)

      fail_insert(
        config.repo,
        batch.id,
        config.total_count,
        acc.inserted_count,
        failed_chunk,
        reason
      )
    end
  end

  defp fail_insert(repo, batch_id, total_count, inserted_so_far, chunk_number, reason) do
    repo.update_all(
      from(batch in __MODULE__, where: batch.id == ^batch_id),
      set: [
        status: "insert_failed",
        insert_failed_chunk: chunk_number,
        insert_failure: failure_payload(reason),
        insert_failed_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
        updated_at: timestamp()
      ]
    )

    {:error,
     %InsertError{
       batch_id: batch_id,
       total_count: total_count,
       inserted_count: inserted_so_far,
       failed_chunk: chunk_number,
       reason: reason
     }}
  end

  defp failure_payload({:count_mismatch, _details}) do
    %{
      "reason" => "count_mismatch",
      "kind" => "validation",
      "message" => "stream count did not match total_count"
    }
  end

  defp failure_payload(reason) do
    %{
      "reason" => inspect(reason),
      "kind" => "insert",
      "message" => inspect(reason)
    }
  end

  defp exception_reason(%Ecto.InvalidChangesetError{} = error),
    do: {:invalid_changeset, Exception.message(error)}

  defp exception_reason(%{message: message}) when is_binary(message), do: {:exception, message}
  defp exception_reason(error), do: {:exception, inspect(error)}

  defp caught_reason(kind, reason), do: {:caught, %{kind: kind, reason: inspect(reason)}}

  defp timestamp do
    NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end
end
