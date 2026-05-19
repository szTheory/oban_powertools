# Technology Stack

**Project:** oban_powertools
**Researched:** 2024

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | 1.14+ | Host Language | Core runtime for concurrent, fault-tolerant background processing. |
| Phoenix LiveView | Latest | Embedded Dashboard | Enables real-time UI without requiring a separate front-end application; standard for Elixir native tooling. |
| Oban (OSS) | 2.17+ | Job Execution | The foundational job execution engine; powertools wraps and extends it. |
| Igniter | Latest | Scaffolding / Code Gen | Allows safe generation of Ecto migrations and config into the host app (host-owned approach). |

### Database
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| PostgreSQL | 12+ | State Management | Ensures ACID compliance, atomic updates for limiters, and `ON CONFLICT` support for idempotency and unique jobs. Excludes MySQL/SQLite entirely. |
| Ecto | 3.10+ | Data Access Layer | Safely interacts with Postgres; `Ecto.Multi` provides required transactional guarantees. |

### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| :telemetry | OTP native | Instrumentation | Event firing for external SRE tools (Parapet) without blocking executors. |
| Phoenix.PubSub | Latest | Workflow Signaling | High-throughput local/distributed signaling for unblocking dependent workflow DAG steps. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| State Store | PostgreSQL | Redis | Split-brain transactions. If job is inserted into DB but limit is tracked in Redis, network partitions will result in drift. |
| Scheduled Jobs | Database-Backed | OS Cron | OS Cron is stateless and duplicates executions across distributed nodes without complex leader election. |
| UI | LiveView | SPA (React/Vue) | Unnecessary complexity; LiveView embeds perfectly into Phoenix host applications. |

## Installation

```bash
# Core package via Mix
mix deps.get

# Install generator
mix igniter.install oban_powertools
```

## Sources

- Oban OSS Documentation
- Context files: `oban_powertools_gsd_research.md`
- Context files: `oban_powertools_context.md`