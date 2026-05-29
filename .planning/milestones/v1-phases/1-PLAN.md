---
phase: 1
plan: 01
type: execute
wave: 1
depends_on: ["Phase 0"]
files_modified: ["lib/oban_powertools/worker.ex", "lib/oban_powertools/idempotency.ex", "lib/mix/tasks/oban_powertools.install.ex", "test/oban_powertools/worker_test.exs", "test/oban_powertools/idempotency_test.exs"]
autonomous: true
requirements: ["WRK-01", "WRK-02", "WRK-03"]
must_haves:
  truths:
    - "Workers can define typed args using an Ecto-like DSL."
    - "Invalid args during enqueue return a synchronous `{:error, changeset}`."
    - "Duplicate enqueues return `{:conflict, job}` using durable idempotency receipts."
    - "Jobs are inserted atomically with their idempotency receipt."
  artifacts:
    - path: "lib/oban_powertools/worker.ex"
      provides: "Worker macro with typed args support"
      contains: "defmacro __using__"
    - path: "lib/oban_powertools/idempotency.ex"
      provides: "Durable idempotency receipt logic"
      contains: "Ecto.Multi"
  key_links:
    - from: "MyWorker.enqueue/2"
      to: "Oban.insert/2"
      via: "ObanPowertools.Idempotency"
      pattern: "Ecto.Multi"
---

<objective>
Implement Worker Ergonomics and Durable Idempotency. This phase provides developers with typed job arguments, synchronous validation, and a Postgres-backed idempotency layer that guarantees exactly-once business logic execution (at-least-once with conflict detection).

Purpose: Ensure jobs are safe, typed, and deduplicated before they even enter the queue.
Output: `ObanPowertools.Worker` macro, `ObanPowertools.Idempotency` module, and updated installer with the receipts migration.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Idempotency Receipts Migration</name>
  <files>lib/mix/tasks/oban_powertools.install.ex, test/mix/tasks/oban_powertools.install_test.exs</files>
  <behavior>
    - Installer generates the `oban_powertools_idempotency_receipts` table.
    - Table includes worker, fingerprint (unique), job_id, state, and expires_at.
    - Index exists on {worker, fingerprint} for fast conflict detection.
  </behavior>
  <action>
    Update `Mix.Tasks.ObanPowertools.Install` to include the `oban_powertools_idempotency_receipts` table in the generated migration.
    Fields: `id` (uuid), `worker` (string), `fingerprint` (string), `job_id` (bigint), `state` (string), `expires_at` (utc_datetime).
    Add a unique index on `[:worker, :fingerprint]`.
  </action>
  <verify>
    <automated>mix test test/mix/tasks/oban_powertools.install_test.exs</automated>
  </verify>
  <done>The installer generates a migration with the correct schema and index.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Worker Macro & Args Schema</name>
  <files>lib/oban_powertools/worker.ex, test/oban_powertools/worker_test.exs</files>
  <behavior>
    - `use ObanPowertools.Worker` supports an `args` option (list of fields/types).
    - It generates a nested `Args` module with an embedded schema.
    - It generates a `validate/1` function that returns a changeset.
  </behavior>
  <action>
    Implement `ObanPowertools.Worker.__using__/1`.
    Generate `defmodule Args` inside the worker using `Ecto.Schema` and `embedded_schema`.
    Generate a `changeset/2` function in the `Args` module.
    Generate `validate/1` in the worker that casts input to the `Args` schema.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/worker_test.exs</automated>
  </verify>
  <done>Workers can define args and validate them synchronously.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Idempotency Logic & Enqueue API</name>
  <files>lib/oban_powertools/idempotency.ex, lib/oban_powertools/worker.ex, test/oban_powertools/idempotency_test.exs</files>
  <behavior>
    - `enqueue/2` validates args first.
    - If valid, it uses `Ecto.Multi` to insert a receipt and the Oban job.
    - If a receipt exists (conflict), it returns `{:conflict, existing_job}`.
    - Fingerprint is generated from worker + args.
  </behavior>
  <action>
    Create `ObanPowertools.Idempotency` with a `transaction/3` function using `Ecto.Multi`.
    Implement fingerprinting logic (e.g., SHA256 of sorted JSON args).
    Update `ObanPowertools.Worker` to inject `enqueue/1` and `enqueue/2` which call `Idempotency.transaction/3`.
    Ensure `process/1` in the worker automatically casts args to the `Args` struct.
  </action>
  <verify>
    <automated>mix test test/oban_powertools/idempotency_test.exs</automated>
  </verify>
  <done>Full enqueue-with-idempotency flow is functional and tested.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Application -> Database | Idempotency receipts are stored in Postgres. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-1-01 | Denial of Service | oban_powertools_idempotency_receipts | mitigate | Ensure pruning is implemented (Phase 4) and indexes are correct to prevent table bloat from slowing down enqueues. |
| T-1-02 | Information Disclosure | Idempotency Fingerprint | mitigate | Use SHA256 for fingerprints to avoid leaking raw arg data in indexes/logs if fingerprints are ever exposed. |
</threat_model>

<verification>
mix format --check-formatted
mix compile --warnings-as-errors
mix test
</verification>

<success_criteria>
Workers can be defined with typed args, enqueued with synchronous validation, and deduplicated via durable receipts. All tests pass.
</success_criteria>

<output>
After completion, create `.planning/phases/1-01-SUMMARY.md`
</output>
