defmodule ObanPowertools.Limits do
  @moduledoc """
  Durable smart-engine limiter reservations backed by Postgres state.
  """

  alias ObanPowertools.{Audit, Telemetry}
  alias ObanPowertools.Forensics.LimiterHistory
  alias ObanPowertools.Limits.{Resource, State}

  @global_partition "__global__"
  @global_strategy "global"
  @algorithm "token_bucket"

  def reserve(repo, worker_mod, args, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with {:ok, snapshot} <- ObanPowertools.Worker.limit_snapshot(worker_mod, args) do
      do_reserve(repo, snapshot, now)
    end
  end

  def release(repo, reservation, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    state =
      repo.get_by!(State,
        resource_id: reservation.resource_id,
        partition_key: reservation.partition_key
      )

    normalized = normalize_bucket(state, reservation.bucket_span_ms, now)

    normalized
    |> State.changeset(%{
      tokens_used: max(normalized.tokens_used - reservation.weight, 0),
      reservation_snapshot: reservation.snapshot
    })
    |> repo.update()
    |> case do
      {:ok, updated_state} ->
        eligible_at =
          updated_state.bucket_started_at &&
            DateTime.add(
              updated_state.bucket_started_at,
              reservation.bucket_span_ms,
              :millisecond
            )

        :ok =
          record_history_fact(repo, %{
            resource_name: reservation.snapshot.resource_name,
            partition_key: reservation.partition_key,
            event_type: "limiter.released",
            cause_kind: "pressure",
            occurred_at: now,
            eligible_at: eligible_at,
            metadata: %{"weight" => reservation.weight}
          })

        Telemetry.execute_limiter_event(:released, %{count: 1}, %{
          action: "released",
          resource: reservation.snapshot.resource_name,
          scope: reservation.snapshot.scope_kind
        })

        Audit.record(
          "limiter.released",
          %{type: :limiter, id: reservation.snapshot.resource_name},
          %{"partition_key" => reservation.partition_key, "weight" => reservation.weight},
          repo: repo
        )

        {:ok, %{reservation | state_id: updated_state.id}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def cooldown(repo, resource_name, partition_key, until_at, reason, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now())

    with %Resource{} = resource <- repo.get_by(Resource, name: resource_name),
         %State{} = state <-
           repo.get_by(State, resource_id: resource.id, partition_key: partition_key) do
      normalized = normalize_bucket(state, resource.bucket_span_ms, now)

      normalized
      |> State.changeset(%{cooldown_until: until_at, cooldown_reason: reason})
      |> repo.update()
      |> case do
        {:ok, updated_state} ->
          :ok =
            record_history_fact(repo, %{
              resource_name: resource.name,
              partition_key: partition_key,
              event_type: "limiter.cooled_down",
              cause_kind: "policy",
              occurred_at: now,
              eligible_at: until_at,
              metadata: %{"reason" => reason}
            })

          Telemetry.execute_limiter_event(:cooled_down, %{count: 1}, %{
            action: "cooled_down",
            resource: resource.name,
            scope: resource.scope_kind
          })

          Audit.record(
            "limiter.cooled_down",
            %{type: :limiter, id: resource.name},
            %{"partition_key" => partition_key, "reason" => reason},
            repo: repo
          )

          {:ok, %{resource: resource, state: updated_state}}

        {:error, update_error} ->
          {:error, update_error}
      end
    else
      nil -> {:error, :not_found}
    end
  end

  def partition_defaults do
    %{
      partition_key: @global_partition,
      partition_strategy: @global_strategy,
      partition_config: %{}
    }
  end

  @doc """
  Pure token-bucket reservation decision with zero side effects.

  Takes a limiter state, resource config, request weight, and current time.
  Returns a verdict tuple without touching the database, telemetry, or history.

  This is the single source of truth for the token-bucket decision logic,
  callable from both `reserve/3` (which adds side effects) and
  `mix oban_powertools.limiter.simulate` (which needs zero side effects).
  """
  @spec compute_reservation(State.t(), Resource.t(), non_neg_integer(), DateTime.t()) ::
          {:reserved, tokens_used_after :: non_neg_integer()}
          | {:blocked, code :: String.t(), retry_at :: DateTime.t() | nil, details :: map()}
  def compute_reservation(%State{} = state, %Resource{} = resource, weight, now) do
    normalized = normalize_bucket(state, resource.bucket_span_ms, now)

    cond do
      cooldown_active?(normalized, now) ->
        {:blocked, "cooldown", normalized.cooldown_until, %{reason: normalized.cooldown_reason}}

      normalized.tokens_used + weight > resource.bucket_capacity ->
        retry_at =
          normalized.bucket_started_at
          |> DateTime.add(resource.bucket_span_ms, :millisecond)
          |> max_datetime(now)

        {:blocked, "limit_reached", retry_at,
         %{capacity: resource.bucket_capacity, used: normalized.tokens_used}}

      true ->
        {:reserved, normalized.tokens_used + weight}
    end
  end

  defp do_reserve(_repo, nil, _now), do: {:ok, nil}

  defp do_reserve(repo, snapshot, now) do
    with {:ok, resource} <- upsert_resource(repo, snapshot),
         {:ok, state} <- get_or_create_state(repo, resource, snapshot, now) do
      attempt_reservation(repo, resource, state, snapshot, now)
    end
  end

  defp upsert_resource(repo, snapshot) do
    attrs = %{
      name: snapshot.resource_name,
      scope_kind: snapshot.scope_kind,
      algorithm: @algorithm,
      bucket_span_ms: snapshot.bucket_span_ms,
      bucket_capacity: snapshot.bucket_capacity,
      default_weight: snapshot.default_weight,
      partition_strategy: snapshot.partition_strategy,
      partition_config: snapshot.partition_config,
      cooldown_enabled: true,
      metadata: %{"worker" => snapshot.worker}
    }

    case repo.get_by(Resource, name: snapshot.resource_name) do
      nil ->
        %Resource{}
        |> Resource.changeset(attrs)
        |> repo.insert()

      resource ->
        config_diff = config_diff(resource, attrs)

        resource
        |> Resource.changeset(attrs)
        |> repo.update()
        |> case do
          {:ok, updated_resource} = result ->
            if config_diff != %{} do
              :ok =
                record_history_fact(repo, %{
                  resource_name: updated_resource.name,
                  partition_key: @global_partition,
                  event_type: "limiter.reconfigured",
                  cause_kind: "policy",
                  occurred_at: DateTime.utc_now(),
                  metadata: %{"config_diff" => config_diff}
                })
            end

            result

          error ->
            error
        end
    end
  end

  defp get_or_create_state(repo, resource, snapshot, now) do
    case repo.get_by(State, resource_id: resource.id, partition_key: snapshot.partition_key) do
      nil ->
        %State{}
        |> State.changeset(%{
          resource_id: resource.id,
          partition_key: snapshot.partition_key,
          tokens_used: 0,
          bucket_started_at: now,
          reservation_snapshot: snapshot
        })
        |> repo.insert()

      state ->
        {:ok, state}
    end
  end

  defp attempt_reservation(repo, resource, state, snapshot, now) do
    # Normalize exactly once; pass the pre-normalized state to compute_reservation
    # so that both the verdict and the write/blocker paths use the same state.
    normalized_state = normalize_bucket(state, resource.bucket_span_ms, now)

    case compute_reservation(normalized_state, resource, snapshot.weight, now) do
      {:reserved, new_tokens_used} ->
        normalized_state
        |> State.changeset(%{
          tokens_used: new_tokens_used,
          bucket_started_at: normalized_state.bucket_started_at || now,
          last_reserved_at: now,
          reservation_snapshot: snapshot
        })
        |> repo.update()
        |> case do
          {:ok, updated_state} ->
            {:ok,
             %{
               resource_id: resource.id,
               state_id: updated_state.id,
               partition_key: updated_state.partition_key,
               weight: snapshot.weight,
               bucket_span_ms: resource.bucket_span_ms,
               snapshot: snapshot
             }}

          {:error, reason} ->
            {:error, reason}
        end

      {:blocked, "cooldown", _retry_at, _details} ->
        blocked(repo, snapshot, [cooldown_blocker(resource, normalized_state)], now)

      {:blocked, _code, _retry_at, _details} ->
        blocked(repo, snapshot, [limit_blocker(resource, normalized_state, now)], now)
    end
  end

  defp normalize_bucket(%State{} = state, bucket_span_ms, now) do
    reset_at = DateTime.add(state.bucket_started_at, bucket_span_ms, :millisecond)

    if DateTime.compare(now, reset_at) == :lt do
      state
    else
      %{state | tokens_used: 0, bucket_started_at: now}
    end
  end

  defp cooldown_active?(state, now) do
    match?(%DateTime{}, state.cooldown_until) and
      DateTime.compare(state.cooldown_until, now) == :gt
  end

  defp cooldown_blocker(resource, state) do
    %{
      code: "cooldown",
      scope: %{kind: resource.scope_kind, id: resource.name},
      summary: "resource is in cooldown",
      retry_at: state.cooldown_until,
      details: %{reason: state.cooldown_reason}
    }
  end

  defp limit_blocker(resource, state, now) do
    retry_at =
      state.bucket_started_at
      |> DateTime.add(resource.bucket_span_ms, :millisecond)
      |> max_datetime(now)

    %{
      code: "limit_reached",
      scope: %{kind: resource.scope_kind, id: resource.name},
      summary: "resource bucket is saturated",
      retry_at: retry_at,
      details: %{capacity: resource.bucket_capacity, used: state.tokens_used}
    }
  end

  defp max_datetime(left, right) do
    case DateTime.compare(left, right) do
      :lt -> right
      _ -> left
    end
  end

  defp blocked(repo, snapshot, blockers, now) do
    blocker = hd(blockers)

    Telemetry.execute_limiter_event(:blocked, %{count: 1}, %{
      action: "blocked",
      blocker_code: blocker.code,
      resource: snapshot.resource_name,
      scope: snapshot.scope_kind
    })

    _ =
      record_history_fact(repo, %{
        resource_name: snapshot.resource_name,
        partition_key: snapshot.partition_key,
        event_type: "limiter.blocked",
        cause_kind: blocker_cause_kind(blocker.code),
        occurred_at: now,
        eligible_at: blocker.retry_at,
        metadata: %{
          "blocker_code" => blocker.code,
          "summary" => blocker.summary
        }
      })

    {:blocked, blockers}
  end

  defp config_diff(resource, attrs) do
    tracked = [
      :scope_kind,
      :bucket_span_ms,
      :bucket_capacity,
      :default_weight,
      :partition_strategy,
      :partition_config,
      :cooldown_enabled
    ]

    Enum.reduce(tracked, %{}, fn key, acc ->
      current = Map.get(resource, key)
      next_value = Map.get(attrs, key)

      if current != next_value do
        Map.put(acc, Atom.to_string(key), %{"before" => current, "after" => next_value})
      else
        acc
      end
    end)
  end

  defp blocker_cause_kind("cooldown"), do: "policy"
  defp blocker_cause_kind(_code), do: "pressure"

  defp record_history_fact(nil, _attrs), do: :ok

  defp record_history_fact(repo, attrs) do
    case LimiterHistory.record_fact(repo, attrs) do
      {:ok, _fact} -> :ok
      {:error, _reason} -> :ok
    end
  end
end
