# Phase 59: Schemas & Foundation - Research

**Researched:** $(date +%Y-%m-%d)
**Domain:** Elixir/Ecto Database Modeling
**Confidence:** HIGH

## Summary
This phase establishes the core Ecto data model for dedicated batch tracking and generalizes the workflow callback outbox. The goal is to provide durable, Ecto-native primitives without relying on heavy Oban metadata, enabling exact-once progress tracking and scalable recovery operations. 

**Primary recommendation:** Implement `ObanPowertools.Batch` and `ObanPowertools.BatchJob` schemas with explicit counters, and generate an Ecto migration to rename `oban_powertools_workflow_callback_outbox` to `oban_powertools_callbacks` while making `workflow_id` nullable and adding a nullable `batch_id`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Database Schema Definitions | Database / Storage | API / Backend | The phase focuses on defining Ecto schemas and migrations for Batches and Callbacks. |
| Progress Tracking State | Database / Storage | - | Explicit integer counters on the `batches` row ensure O(1) reads for UI without querying jobs. |
| Generalized Outbox | Database / Storage | API / Backend | A unified outbox handles recovery/execution across Workflows and Batches transparently. |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Callback Outbox Evolution:** Rename and generalize the existing `oban_powertools_workflow_callback_outbox` to `oban_powertools_callbacks`. Rationale: A single generalized outbox adheres to the principle of least surprise and ensures uniform Lifeline recovery.
- **Progress Tracking Structure:** Explicit integer counters on the `batches` row (`total_count`, `success_count`, `discard_count`, `cancelled_count`, `snooze_count`), updated atomically via `Repo.update_all(inc: [...])`.
- **Chain Representation:** No separate `chains` table. Model Chains as syntactic sugar over the `callbacks` outbox and `batches` schema.

### the agent's Discretion
None explicitly listed.

### Deferred Ideas (OUT OF SCOPE)
- Dynamic / Growable Batches.
- Chunking (size/timeout based batches).
- Implicit Workflow Callbacks.
- Complex fan-in/fan-out DAGs.
- External Dependencies (No `libgraph` or Redis).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAT-01 | Dedicated Ecto schemas and migrations for `batches`, `batch_jobs`, and a `callbacks` outbox. | Defines the exact schemas and structural changes necessary for `ObanPowertools.Batch`, `ObanPowertools.BatchJob`, and `ObanPowertools.Callback` to fulfill the requirement. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | ~> 3.10 | Database querying and migrations | Core framework of the project. |
| `oban` | existing | Job processing engine | Standard background job processor used in the project. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Postgres table `oban_powertools_workflow_callback_outbox` exists in databases using v1.8 or earlier. | Data migration: `rename table(:oban_powertools_workflow_callback_outbox), to: table(:oban_powertools_callbacks)`. Alter `workflow_id` to be nullable. Add `batch_id` as nullable UUID. |
| Live service config | None — verified via codebase scan. | None |
| OS-registered state | None — verified via codebase scan. | None |
| Secrets/env vars | None — verified via codebase scan. | None |
| Build artifacts | Compiled BEAM module: `Elixir.ObanPowertools.Workflow.CallbackOutbox.beam` | Standard `mix clean` / recompilation. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/oban_powertools/
├── batch.ex                 # New: Batch schema with explicit counters
├── batch_job.ex             # New: BatchJob join schema
├── callback.ex              # Renamed/Refactored: Generalized Callback schema
```

**Required Dependency Updates:**
- Rename the reference in `lib/oban_powertools/doctor/checks.ex` (`oban_powertools_workflow_callback_outbox` -> `oban_powertools_callbacks`).
- Update the generation step in `lib/mix/tasks/oban_powertools.install.ex` to produce the updated `oban_powertools_callbacks` and new `oban_powertools_batches` & `oban_powertools_batch_jobs` tables.
- Update `has_many` reference in `lib/oban_powertools/workflow/workflow.ex` to point to `ObanPowertools.Callback`.

### Pattern 1: Explicit Integer Counters
**What:** Instead of querying `SELECT count(*)`, explicitly maintain state on the parent `batches` row.
**When to use:** When high read performance is needed for UI dashboards (e.g. LiveView) and preventing database locks.
**Example:**
```elixir
defmodule ObanPowertools.Batch do
  use Ecto.Schema
  
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "oban_powertools_batches" do
    field :status, :string, default: "executing"
    field :total_count, :integer, default: 0
    field :success_count, :integer, default: 0
    field :discard_count, :integer, default: 0
    field :cancelled_count, :integer, default: 0
    field :snooze_count, :integer, default: 0
    # timestamps etc.
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic Counter Updates | Ecto Changeset after `Repo.get` | `Repo.update_all(inc: [success_count: 1])` | Prevents lock starvation during massive concurrent job completions (BAT-03). |
| Chains table | `oban_powertools_chains` schema | Callback Outbox | A chain is just a linear sequence mapping sequentially to the Outbox. Reusing Outbox prevents schema bloat. |

## Common Pitfalls

### Pitfall 1: Breaking Existing Workflow Outbox
**What goes wrong:** Existing `workflow_id` references become invalid or data is lost.
**Why it happens:** Dropping and recreating the table instead of renaming and altering.
**How to avoid:** Create a migration that uses `rename table(:oban_powertools_workflow_callback_outbox), to: table(:oban_powertools_callbacks)` and `alter table` to make `workflow_id` nullable and add `batch_id`. In `oban_powertools.install` task, update the schema generation step directly.

### Pitfall 2: Overloading Oban Job Meta
**What goes wrong:** Oban metadata becomes bloated, slowing down background execution.
**Why it happens:** Storing batch configuration directly in the `oban_jobs` table.
**How to avoid:** Maintain isolated `oban_powertools_batches` and `oban_powertools_batch_jobs` tables, keeping Oban lean.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond the project's own codebase: Elixir, Ecto, Postgres).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/oban_powertools/batch_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| BAT-01 | Ecto schemas compile | unit | `mix compile` | ❌ Wave 0 |
| BAT-01 | DB migrations apply and schemas map correctly | integration | `mix test test/oban_powertools/install_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/batch_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/oban_powertools/batch_test.exs` — schema unit test.
- [ ] `test/oban_powertools/batch_job_test.exs` — schema unit test.
- [ ] `test/oban_powertools/callback_test.exs` — generalized callback schema unit test.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | - |
| V3 Session Management | no | - |
| V4 Access Control | no | - |
| V5 Input Validation | yes | Ecto Changesets for type casting and structural validation. |
| V6 Cryptography | no | - |

### Known Threat Patterns for Elixir/Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Denial of Service (DB Lock Starvation) | Denial of Service | `Repo.update_all` with `inc` instead of row locking (Optimistic locking). |

## Sources
### Primary (HIGH confidence)
- `.planning/phases/59-schemas-foundation/59-CONTEXT.md` - Locked architectural decisions.
- `.planning/REQUIREMENTS.md` - Phase constraints and requirement mapping.

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - Follows project's core stack (Ecto, Oban).
- Architecture: HIGH - Adheres to explicit project decisions in CONTEXT.md.
- Pitfalls: HIGH - Documented via roadmap/context constraints.
