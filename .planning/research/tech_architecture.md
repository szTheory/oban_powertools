# Technical Architecture & Elixir/Oban Idioms Blueprint

**Project:** oban_powertools
**Researched Focus:** Technical Architecture and Elixir/Oban Idioms
**Confidence:** HIGH (Based on direct alignment with Postgres/Ecto/OTP primitives and Oban ecosystem realities)

This document provides a highly actionable blueprint for the optimal Elixir implementations of the core `oban_powertools` features. It translates the product requirements into idiomatic Phoenix/Ecto/OTP code architectures, serving as the technical foundation for the roadmapping phase.

---

## 1. Ecto-Native State Management

**The Goal:** 
Keep all state transitions strictly transactional, auditable, and co-located with the job data in PostgreSQL. Do not rely on external stores like Redis.

**Architectural Blueprint:**
*   **Database First, Ecto.Multi Everywhere:** Every operational action (e.g., job retry, queue pause, rate limit consumption, workflow step completion) must be modeled as an `Ecto.Multi`. This ensures that if a workflow step completes, the transaction that marks it complete can atomically insert the telemetry audit event and release rate-limit tokens.
*   **State Separation:** Do not arbitrarily mutate the core `oban_jobs` table beyond its supported state transitions. Instead, create related tables (e.g., `oban_powertools_limiters`, `oban_powertools_audit_events`, `oban_powertools_workflow_edges`) that hold the operational metadata and reference the `oban_jobs.id`.
*   **Advisory Locks for Critical Sections:** For operations where multiple concurrent nodes might try to mutate a singleton state (e.g., dynamic cron firing, orphan rescue, or queue config syncing), use PostgreSQL advisory locks (`pg_try_advisory_xact_lock`) within the transaction to serialize access and avoid race conditions or deadlock storms.

**Code Idiom Example:**
```elixir
Ecto.Multi.new()
|> Ecto.Multi.update(:job, Oban.Job.changeset(job, %{state: "retryable"}))
|> Ecto.Multi.insert(:audit, Audit.changeset(%Audit{}, %{action: :retry, job_id: job.id, actor: user}))
|> Ecto.Multi.update_all(:release_token, fn _ -> from(l in Limiter, update: [inc: [tokens: 1]]) end)
|> Repo.transaction()
```

---

## 2. Concurrency and Rate Limiters

**The Goal:** 
Implement token-bucket, sliding-window, and partition-based rate limiters directly in Postgres without massive write amplification, avoiding the "Celery Trap" of per-worker limits and race conditions.

**Architectural Blueprint:**
*   **Atomic Updates (UPDATE ... RETURNING):** To consume a rate limit token without needing a heavy read-modify-write cycle that is prone to race conditions, leverage atomic Postgres statements.
*   **Local vs. Global Separation:** Local concurrency is managed purely in-memory (via Erlang's `GenStage` or standard Oban capabilities). Global/Rate limits are enforced at the database layer.
*   **Token Bucket in SQL:** A token bucket can be implemented by storing `tokens`, `capacity`, and `last_refilled_at`. Upon job execution, the `reserve` function atomically calculates the elapsed time, adds accrued tokens, and decrements if enough tokens exist.
*   **Explicit Explainability:** The limiter module must expose an `explain/1` function that does not mutate state but clearly returns why a job would be blocked: `{:blocked, {:rate_limit_exhausted, "github_api", resets_at: ~U[...]}}`.

**Code Idiom Example:**
```sql
-- Conceptual Atomic Token Bucket Reservation
UPDATE oban_powertools_limiters
SET tokens = LEAST(capacity, tokens + extract(epoch from (now() - last_refilled_at)) * refill_rate) - :weight,
    last_refilled_at = now()
WHERE id = :limiter_id 
  AND LEAST(capacity, tokens + extract(epoch from (now() - last_refilled_at)) * refill_rate) >= :weight
RETURNING *;
```

---

## 3. Transactional Unique Jobs

**The Goal:**
Prevent duplicate work durably without falling victim to network partitions or "exactly-once" myths.

**Architectural Blueprint:**
*   **DB-Layer Uniqueness over App-Layer Checks:** Never do a `Repo.get` followed by a `Repo.insert`. This is inherently racy.
*   **Postgres Upserts:** Use `ON CONFLICT DO NOTHING` (or `DO UPDATE`) utilizing PostgreSQL unique indexes (potentially partial indexes filtering by incomplete job states). 
*   **Explicit Tuples on API:** Expose job insertion as a strict API that returns tagged tuples. Never swallow uniqueness conflicts silently.
*   **Determinism:** Rely on deterministic fingerprinting (e.g., hashing the arguments) inserted into a `unique_key` column on the job or a sidecar table, governed by a DB unique constraint.

**Code Idiom Example:**
```elixir
# In the Enqueue API
case Repo.insert(job, on_conflict: :nothing, returning: true) do
  {:ok, %{id: nil}} -> 
    # Because ON CONFLICT DO NOTHING returns a struct without an ID if conflict occurred
    {:conflict, Repo.get_by(Job, unique_key: job.unique_key)}
  {:ok, inserted_job} -> 
    {:ok, inserted_job}
end
```

---

## 4. Idempotency Receipts

**The Goal:**
Since at-least-once execution is the distributed system reality, provide a framework that guarantees side-effects are skipped if a job runs twice.

**Architectural Blueprint:**
*   **The Receipt Pattern:** Create an `oban_powertools_receipts` table. Before executing critical side-effects, the worker queries/attempts to insert a receipt using an `idempotency_key` (derived from args).
*   **Transactionality:** The receipt insertion and the resulting data mutations must occur in the same transaction. If the transaction commits, the receipt is durable.
*   **Early Exit:** If a job starts, finds a receipt for its idempotency key, it safely returns `{:ok, :already_processed}` without crashing or running side effects.

**Code Idiom Example:**
```elixir
def process(%Oban.Job{args: args}) do
  key = hash_args(args)
  
  Ecto.Multi.new()
  |> Ecto.Multi.insert(:receipt, %Receipt{idempotency_key: key}, on_conflict: :nothing)
  |> Ecto.Multi.run(:check_receipt, fn _, %{receipt: receipt} ->
       if receipt.id == nil, do: {:error, :already_processed}, else: {:ok, :continue}
     end)
  |> Ecto.Multi.run(:side_effect, fn _, _ -> do_business_logic(args) end)
  |> Repo.transaction()
  |> case do
       {:ok, _} -> :ok
       {:error, :check_receipt, :already_processed, _} -> :ok # Safe skip
       {:error, _, reason, _} -> {:error, reason}
     end
end
```

---

## 5. OTP / GenServer Integrations (Telemetry & Heartbeats)

**The Goal:**
Enable SRE-level observability and day-2 operations (stuck job repair, lifeline, telemetry) without adding significant load or blocking job execution.

**Architectural Blueprint:**
*   **Heartbeat GenServers:** Executors/Producers shouldn't do complex DB updates in their main execution loop. Instead, a dedicated node-local `Powertools.Heartbeat` GenServer periodically (e.g., every 30s) bulk-upserts liveness pings to an `oban_powertools_heartbeats` table.
*   **Lifeline & Orphan Rescue:** A cluster-singleton GenServer (using Oban's peer leadership or Postgres advisory locks) polls `heartbeats`. If a node's heartbeat is > 2 minutes stale, the lifeline transitions its executing jobs to `orphaned` or `retryable` (with a dry-run capability for safety).
*   **PubSub / GenServer Signaling for Workflows:** When a DAG workflow step completes, relying purely on DB polling is too slow. The completing worker should use `Postgres PubSub` or `Phoenix.PubSub` to broadcast a signal. A coordinating GenServer catches the signal and immediately evaluates the DAG to unblock dependent steps.
*   **Erlang `:telemetry` Standards:** Adhere strictly to Erlang `:telemetry` and OpenInference standards. Spans for jobs (started, failed, completed) should be emitted asynchronously. Metrics should never include high-cardinality data like `job_id` in their labels.

**Code Idiom Example:**
```elixir
# Emitting Telemetry (Non-Blocking)
:telemetry.execute(
  [:oban_powertools, :job, :completed],
  %{duration_ms: duration},
  %{queue: queue_name, worker: worker_name, status: "ok"} # No Job ID in metadata for prometheus safety
)

# Workflow Signaling
Phoenix.PubSub.broadcast(MyApp.PubSub, "workflow:#{workflow_id}", {:step_completed, step_id})
```

---

## 6. Actionable Roadmap Implications

Based on these technical realities, the engineering roadmap must sequence features to respect architectural dependencies:

1.  **Phase 0: Foundation & Telemetry:** Establish the Ecto schemas, migrations, and `:telemetry` emission contracts. Set up the `Audit` behavior. (Do not build limits or workflows yet).
2.  **Phase 1: Dashboard & Observation:** Build the LiveView UI on top of the Phase 0 telemetry and standard Oban jobs. Enable safe, audited `Ecto.Multi` based bulk-actions (retry, cancel).
3.  **Phase 2: Worker Ergonomics & Idempotency:** Introduce the `use ObanPowertools.Worker` macro, Changeset validation, and the Idempotency Receipts pattern. This is a pure application-layer enhancement.
4.  **Phase 3: Smart Engine (Rate Limits):** Implement the atomic SQL limiters and token buckets. This is high-risk and requires extensive property and concurrency testing.
5.  **Phase 4: Composition & Signaling:** Build the DAG workflow tables, GenServer coordinator, and PubSub signaling.
6.  **Phase 5: Lifeline & Repair:** Build the heartbeat GenServers and the dry-run repair center for orphaned jobs, relying on the telemetry and audit primitives from earlier phases.