# Powertools vs. Oban Pro

When scaling background jobs in Elixir, teams eventually hit the limits of basic queueing and need advanced orchestration: **Batches, Workflows/Chains, Rate Limiting, Dynamic Cron, and operational UI**. 

The standard upgrade path has historically been [Oban Pro](https://oban.dev/pro), a fantastic, commercially supported extension to the OSS Oban engine. **Oban Powertools** provides an alternative path for teams that want these capabilities natively modeled in Ecto, free and open-source, with a radical focus on the **Operator/SRE user experience**.

This guide outlines how Powertools approaches these advanced features compared to Oban Pro.

---

## 1. Batches & Workflows

### The Oban Pro Approach
Oban Pro implements Batches, Workflows, and Chunks primarily by injecting state into the `meta` JSONB column of the standard `oban_jobs` table. Dependencies and callbacks are handled via triggers and plugins monitoring this metadata.
- **Pros:** Keeps the schema footprint small (reuses `oban_jobs`).
- **Cons:** Inspecting a batch requires parsing JSON. Querying for "all failed jobs in Batch X" can be slow without custom JSONB indexes.

### The Powertools Approach: Dedicated State Machines
Powertools believes that composition is a first-class domain concept. We use **dedicated Ecto schemas** (`oban_powertools_batches`, `oban_powertools_workflows`, etc.) instead of shoving DAG state into metadata.
- **Explicit Tables:** Operators can write standard SQL/Ecto queries (`Repo.all(from b in Batch, where: b.state == :exhausted)`) to find stuck batches.
- **Linear Chains:** Ergonomic DSL for `JobA |> chain(JobB)` that compiles down to explicitly linked rows, avoiding the serialization bloat and "zombie callbacks" common in simulated DAGs.
- **Generalized Callback Outbox:** Callbacks are transactionally isolated, guaranteeing that `completed` or `exhausted` hooks fire even if a worker crashes right after a job finishes.

---

## 2. Global & Smart Limiters

### The Oban Pro Approach
Pro offers sophisticated concurrency controls, including Global, Rate, and Partitioned limits. These are managed internally by Oban plugins and often use Postgres or Redis under the hood.

### The Powertools Approach: Explainable Blocked State
Powertools limits are globally enforced via database primitives, but our focus is on **Explainability**.
- **No Silent Sleeping:** Limits explicitly push jobs back rather than locking threads (preventing "Wait Timeout" starvation).
- **Explainable UI:** In the Native Control Plane, operators don't just see a job as "pending." They see **exactly why** it's blocked (e.g., `{:rate_limit_exhausted, "github_api", resets_at: ~U[...]}`).

---

## 3. Dynamic Cron

### The Oban Pro Approach
Pro's `DynamicCron` allows schedules to be updated at runtime, storing cron entries in the database and periodically syncing them to workers.

### The Powertools Approach: Operator-First Dynamic Cron
Powertools treats Dynamic Cron as a critical operational interface.
- **Catch-up & Overlap Policies:** Powertools forces developers to declare strict overlap and catch-up policies, preventing queue storms or missed executions during outages.
- **Pause & Audit:** Operators can pause specific dynamic cron entries directly from the Powertools shell, with every action logged in the audit trail.

---

## 4. Lifeline vs. Web Actions

### The Oban Pro Approach
Oban Web provides a slick interface for retrying, cancelling, or deleting jobs. It executes these actions directly.

### The Powertools Approach: Audited Bulk Recovery
Powertools assumes a zero-trust, compliance-heavy environment.
- **Lifeline Pipeline:** "Retry all failed" doesn't just arbitrarily update rows. It routes through the **Lifeline pipeline**, ensuring a durable audit trail.
- **Dry-Run Repairs:** Operators can preview a repair before applying it, eliminating the anxiety of bulk mutating production state.
- **Idempotency Receipts:** Deeply integrated idempotency ensures that manual retries don't result in duplicate side effects.

---

## 5. Native Control Plane UI

### The Oban Pro Approach
Requires a paid subscription to **Oban Web**, a separate dashboard application that must be mounted and configured.

### The Powertools Approach: Ecto-Native `/ops/jobs` Shell
Powertools includes a free, fully native **Control Plane UI** that mounts directly in your Phoenix router.
- **Honest Host Ownership:** The UI is designed as an annex to your app, natively integrating with your existing `powertools_auth` and display policies.
- **Forensics & Runbooks:** Built specifically for Day-2 Ops. It prioritizes finding *why* things failed (Forensics) and securely fixing them (Audit & Lifeline) over just showing pretty charts.

---

## Summary

Choose **Oban Pro** if you want a battle-tested, commercially supported, turnkey solution that requires minimal configuration and no new tables.

Choose **Oban Powertools** if you:
- Want all advanced orchestration features backed by explicit Ecto tables.
- Require extreme observability and "Explainable" job states.
- Need a built-in, Operator/SRE-first control plane.
- Prefer a fully open-source, community-driven stack.
