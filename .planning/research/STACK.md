# Technology Stack

**Project:** Oban Powertools
**Researched:** 2026-06-14

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir / OTP | ~> 1.19 | Core runtime | Existing project standard, no version bumps needed. |
| Ecto SQL | ~> 3.10 | Database abstraction | Ecto-native approach to state, atomic `Ecto.Multi` inserts for batches and chains. |
| Oban | ~> 2.18 | Core job engine | Powertools builds directly on OSS Oban (`Oban.insert_all`, `Oban.Job`). |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | ~> 0.17 | State persistence | Strict Postgres-only constraint; no Redis or alternative DB support allowed. |

### Infrastructure & UI
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Phoenix LiveView | ~> 1.0 (Optional) | Native Ops Console | Already established for Powertools shell; native Batches and Workflow pages will live here. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| *None* | N/A | Strict mandate | **Zero new runtime dependencies** is a strict project rule (proven by v1.6 and v1.7). Do not add `libgraph` or any other external orchestration/graph library. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| DAG Resolution | **Pure Elixir + Ecto tables** | `libgraph` library | Introduces a third-party dependency. Linear chains and simple DAG composition can be natively modeled via `oban_powertools_workflows` and `_edges` tables, resolved with native recursive Elixir logic. |
| Batch State Storage | **Dedicated Powertools tables** | Modifying `oban_jobs` | We do not own `oban_jobs` and Oban might prune it. Dedicated `oban_powertools_batches` and `oban_powertools_batch_jobs` tables ensure honest host ownership, clear support boundaries, and explicit FKs. |
| Job Insertion | **`Oban.insert_all/2` in `Ecto.Multi`** | Iterative `Oban.insert` | Enqueueing thousands of jobs iteratively causes DB strain. `Oban.insert_all/2` batches Postgres queries efficiently. |

## Core Integration Points

1. **Worker Lifecycle Hooks (v1.7):** 
   Batches will reuse the existing `on_success`, `on_failure`, and `on_discard` worker hooks. The hook will update the `oban_powertools_batch_jobs` row, evaluate if the overall batch is now `completed` or `exhausted`, and dispatch callbacks if true.
2. **Generalized Callback Outbox:** 
   Instead of unreliable in-memory callback resolution, use a durable Ecto-backed outbox (e.g., `oban_powertools_callbacks`) or an internal Oban job to atomically enqueue the user-defined callback jobs. This guarantees callback dispatch even if a node crashes exactly as the final batch job finishes.
3. **Lifeline Repair Pipeline:**
   Batches and workflows must integrate natively with `ObanPowertools.Lifeline`. Bulk-retrying an exhausted batch must flow through the same preview → reason → execute → audit pipeline as single jobs, emitting `source: "api"` telemetry.
4. **Native ObanWeb Bridge:**
   The Batches UI will live natively in the Powertools shell (`/ops/jobs/batches`), linking deeply to Oban Web for generic job inspection.

## What NOT to Add

- **Do NOT add Redis** or any non-Postgres coordination layers.
- **Do NOT add graph calculation libraries** (`libgraph`). DAG mapping must remain an Ecto-native exercise.
- **Do NOT add new runtime telemetry dependencies** (e.g., `oban_met`). Powertools uses native `telemetry` hooks and optional `telemetry_metrics`.

## Installation

No new dependencies to install.

```bash
# Core
mix deps.get
```

## Sources

- `.planning/PROJECT.md` (Zero new dependencies mandate, v1.7 worker hooks, Batches milestone)
- `prompts/oban_powertools_ultimate_ui_strategy_brief.md` (Native UI / Fallback UI architecture)
- Oban HexDocs (`Oban.insert_all` capabilities)
