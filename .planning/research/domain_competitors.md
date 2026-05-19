# Domain Competitors & Historical Footguns

**Domain:** Background Job & Queue Ecosystems
**Researched:** 2024
**Confidence:** HIGH

## Executive Summary

This research analyzes four major commercial and OSS background job ecosystems: **Sidekiq Enterprise** (Ruby), **BullMQ Pro** (Node.js), **Celery** (Python), and **GoodJob** (Ruby). The objective is to identify how they implement core primitive features (rate limiting, cron, workflows) and extract the historical "footguns" that developers encounter.

The overarching theme across all ecosystems is that **implicit magic leads to catastrophic failure states in distributed systems**. Systems that try to simulate DAGs through composition (Celery), rely entirely on local memory for worker limits, or fail to differentiate between "failed" and "rate limited" states create massive operational burdens (Day-2 ops). 

These findings directly inform the architecture and UI/UX roadmap for **Oban Powertools**.

---

## 1. Sidekiq Enterprise (Ruby / Redis)

**Architecture:** In-memory Redis data structures, Lua scripts for atomicity, multi-threaded Ruby workers.

*   **Global Rate Limiting:** Uses highly efficient Redis token buckets (Concurrent, Window, Bucket limiters).
*   **Dynamic Cron:** Out of the box, Sidekiq Enterprise cron (`periodic`) is strictly static and loaded at boot. Implementing user-defined, dynamic cron requires a "Fan-Out Ticker" pattern (a single static cron job that queries a Postgres DB and enqueues dynamic jobs).
*   **Batches & Workflows:** Handled via `Sidekiq::Batch`. You can define callbacks for when a batch completes.

### 🔴 Historical Footguns
*   **The "Wait Timeout" Starvation:** By default, if a rate limiter is saturated, Sidekiq sleeps the worker thread until a token frees up. If an external API goes down, all worker threads quickly become stuck sleeping, freezing the entire background processing pipeline. *Fix: Limiters must explicitly raise exceptions (`wait_timeout: 0`) and push jobs back to the queue, rather than locking threads.*
*   **Callback Zombies:** If a job in a `Sidekiq::Batch` silently dies (e.g., worker OOMs and Redis lock expires), the batch completion callback may never fire, leaving workflows in a permanently stuck "zombie" state.
*   **The "Exactly-Once" Myth:** Sidekiq explicitly states it is an "at-least-once" system. Developers mistakenly believe uniqueness locks prevent double execution. If a worker crashes mid-flight after completing a side-effect, the job is redelivered.

---

## 2. BullMQ Pro (Node.js / Redis)

**Architecture:** Redis-backed queue utilizing complex Lua scripts to manage job states (wait, active, completed, failed, delayed).

*   **Global Rate Limiting:** Supports advanced "Group" rate limiting (e.g., rate limiting per `customer_id` or `tenant`). Supports manual rate limiting via `worker.rateLimit(ms)` when a 3rd party API returns a `429 Too Many Requests`.
*   **DAG Workflows:** Uses `FlowProducer` to map parent-child dependencies. A parent job only moves to the wait queue once all children are successful.

### 🔴 Historical Footguns
*   **Rate-Limit Backpressure Explosions:** When handling 429s, BullMQ moves jobs back to a "delayed" state. If the rate limit is long or systemic, the delayed queue can grow infinitely, causing Redis OOM (Out of Memory) crashes because Redis is not a durable disk store.
*   **Silent Child Failures:** In complex `FlowProducer` trees, if a deeply nested child node is paused or permanently fails, the parent node simply hangs indefinitely in the "waiting-children" state. There is often no explicit UI highlighting *why* the parent is stuck.

---

## 3. Celery (Python / RabbitMQ / Redis)

**Architecture:** Broker (RabbitMQ/Redis) + Result Backend (Redis/Postgres). Uses pre-fork multi-processing worker pools.

*   **Global Rate Limiting:** Celery rate limits are natively applied *per-worker*, not globally. 
*   **DAG Workflows:** Celery Canvas (`chains`, `groups`, `chords`). Simulated DAGs via deep dictionary composition.

### 🔴 Historical Footguns
*   **The "Celery Trap" (Per-Worker Limits):** Because limits are per-worker, an API limit set to `100 req/min` turns into `500 req/min` the moment an operator scales up to 5 workers, resulting in immediate API bans.
*   **The Chord Gallery of Horrors:** Chords (parallel groups with a final callback) require a Result Backend to track state. If using the wrong backend (like RPC), chords hang indefinitely. If a worker hard-crashes during a chord, the callback is lost in limbo forever.
*   **Serialization Bloat:** Because Celery Canvas simulates graphs via recursion, a large chain of tasks (e.g., 100+ steps) triggers Python recursion depth limits or bloats the JSON payload into megabytes, crashing the message broker.
*   **`task_acks_late=True` Duplicate Chaos:** Developers turn this on to prevent job loss on crash, but it guarantees duplicate execution. Without strict database-level idempotency keys, this causes duplicate billing and corrupted data.

---

## 4. GoodJob (Ruby / Postgres)

**Architecture:** Postgres-backed, multithreaded ActiveJob backend utilizing Postgres Advisory Locks and SKIP LOCKED for concurrency.

*   **Rate Limiting & Concurrency:** Rule-based interface (`good_job_concurrency_rule`) scoped to labels/arguments. Controls `total_limit` (running jobs) and `enqueue_throttle` (sliding window).
*   **Dynamic Cron:** Postgres-backed polling. Fully dynamic as schedules are just database rows.

### 🔴 Historical Footguns
*   **Postgres Contention & Index Bloat:** Relying on Postgres for high-throughput queueing without partition/pruning strategies leads to massive index bloat, destroying DB cache hit ratios.
*   **Overlap Storms:** If a 1-minute cron schedule takes 5 minutes to run, the queue floods with overlapping jobs unless explicit concurrency rules (`total_limit: 1`) are set on the cron job.
*   **Clock Skew on Polling:** If the primary database and worker clocks drift, dynamic cron schedules can execute erratically. Furthermore, if workers are down during a scheduled window, they might completely miss the firing (lack of a strict "catch-up" policy).

---

## 🎯 Actionable Roadmap Implications for Oban Powertools

Based on the failures of competitors, **Oban Powertools** must strictly adhere to the following architectural mandates:

1.  **Rate Limiting Must Be Explicit & Global:** 
    *   **Do not** block the worker process. Implement `{:snooze, seconds}` or explicit `Ecto.Multi` DB token reservations.
    *   **UI Requirement:** Blocked jobs MUST explicitly state *why* they are blocked (e.g., `{:rate_limit_exhausted, "github_api", resets_at: ~U[...]}`). Never fail silently.
2.  **Idempotency Belongs in the Database:**
    *   Uniqueness at enqueue is not enough. Oban Powertools must offer an **Idempotency Receipts** system (storing deterministic hashes of job args in Postgres) to safely return `{:conflict, existing_job}` on duplicate execution attempts (mitigating the `task_acks_late` Celery footgun).
3.  **DAGs Must Be Persisted State Machines, Not Composed Payloads:**
    *   Do not mimic Celery Canvas. Workflows must be explicit tables (`oban_powertools_workflows`, `oban_powertools_workflow_edges`).
    *   **UI Requirement:** Workflows must visually highlight the exact edge/node causing a halt to prevent the "Callback Zombie" problem. Include a "Dry-Run Repair" feature for stuck graphs.
4.  **Cron Requires Catch-Up Policies:**
    *   Every dynamic schedule must force the developer to declare an `overlap_policy` (e.g., `:skip`, `:queue`) and a `catch_up_policy` (e.g., `:none`, `:last_only`). 
    *   **UI Requirement:** The dashboard must show a "Missed Runs" counter.
5.  **Compile-Time Args Validation:**
    *   To prevent the `#1` issue across all ecosystems (JSON deserialization errors deep in worker logic), Powertools must force inline Ecto schemas for job arguments: `use ObanPowertools.Worker, args: [...]`. Fail fast at `enqueue/1`.