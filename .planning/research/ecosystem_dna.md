# szTheory Ecosystem DNA & Delivery

**Project:** Oban Powertools
**Focus:** Integration Points, Structural Requirements, SaaS-in-a-Box Model

## 1. szTheory "SaaS-in-a-Box" DNA

The szTheory library ecosystem (Scoria, Parapet, Cairnloop, Threadline, Sigra, and now Oban Powertools) relies on a strict set of architectural tenets aimed at solo developers and small teams operating Phoenix applications.

### Core Principles
* **Host-Owned Over Magical Black Boxes:** Adopters must fully own their operational infrastructure. Rather than hiding complex logic in opaque macros or standalone services, the library injects manageable code and Ecto migrations directly into the host application.
* **Ecto-Native & Postgres-Only:** Application state, configurations (like cron entries and queue limits), and historical context (durable execution receipts) are strictly stored in Postgres. This enforces transactional safety and simplifies the operational stack.
* **Operator-First DX:** The library must be built for Day-2 operations immediately. Embedded LiveView dashboards and CLI diagnostics (`mix oban_powertools.doctor`) are non-negotiable table stakes.
* **Telemetry as a Public Contract:** Clear separation between ephemeral measurements (`:telemetry`) and durable evidence (Ecto rows). Breaking a telemetry event is considered a semver-major breaking change.

---

## 2. Igniter for Host-Owned Code Generation

Oban Powertools will heavily utilize **Igniter** (the AST-aware project patching and code generation tool in Elixir) to achieve the "host-owned" requirement.

* **AST-Aware Patching:** Igniter will parse the host app's AST to safely inject Oban configuration, add children to the supervision tree, and mount the Powertools LiveView dashboard inside the host's `router.ex`.
* **Zero-Friction Installers:** Users will run a single command (`mix igniter.install oban_powertools`) that will:
  1. Generate Ecto migrations for limits, workflows, schedules, and receipts.
  2. Scaffold `ObanPowertools` module stubs inside the user's `lib/` directory so they can customize behaviors.
  3. Wire up telemetry handlers to connect with Parapet and Threadline.
* **Upgradability:** Igniter patches must be idempotent. They should safely detect if the library is already installed and update configuration without destroying user modifications.

---

## 3. Ecosystem Integrations

Oban Powertools is not an island; it serves as the asynchronous execution backbone for the rest of the szTheory ecosystem.

### A. Sigra (Auth & Identity)
* **Dashboard Protection:** Powertools LiveView dashboards must integrate with Sigra to authorize access.
* **Actor Attribution:** Every manual action taken in the Powertools UI (e.g., retrying a job, pausing a queue, skipping a cron fire) must capture the Sigra `actor_id` and attach it to the action for auditability.

### B. Threadline (Audit Logs & Durable Evidence)
* **Durable Action Logs:** While standard job executions emit ephemeral `:telemetry`, **human interventions** require durable evidence.
* **Integration Point:** Powertools will push events to Threadline for HITL (Human-in-the-loop) actions like "Queue Paused by Admin", "Stuck Job Force Cancelled", or "Rate Limit Manually Reset".

### C. Scoria (AI Trace & Governance)
* **Async Tracing Context:** Scoria runs LLM evaluations, tool executions, and RAG pipelines via background jobs. Oban Powertools must support carrying OpenInference span context through job arguments or metadata.
* **Task Isolation:** Jobs executing AI logic via Scoria must be able to fail or be cancelled cleanly by Powertools without poisoning the execution node.

### D. Parapet (Reliability & SLOs)
* **SLI Generation:** Powertools emits strict `:telemetry` events for queue lag, limiter saturation, and retry storms. Parapet will consume these to drive operator-grade alerts and burn-rate calculations.

---

## 4. CI/CD, Testing, and Deployment Standards

To meet the high bar of the szTheory ecosystem, Oban Powertools must enforce strict CI/CD and testing invariants.

### Testing Capabilities (The "Testing Helpers" Suite)
Background jobs are notoriously difficult to test. Powertools must ship with first-class test helpers:
* **Deterministic Time:** Helpers to freeze or fast-forward clocks to strictly test cron overlaps, rate limit windows, and snooze expirations (`with_frozen_time/1`).
* **Sandbox Environments:** Full compatibility with Ecto SQL Sandbox. Tests must not leak state, even when verifying complex concurrent unique constraints or database-backed distributed limiters.
* **Component Fakes:** Helpers to mock limiters, schedulers, and signal buses to unit-test workflow DAGs without actually executing them.

### CI/CD Pipeline Requirements
* **Matrix Validation:** CI must test against the latest stable Elixir/OTP and the previous version, alongside multiple supported Postgres versions.
* **Integration Harness:** CI must spin up a generated Phoenix application (using Igniter) to verify the LiveView dashboard and Ecto migrations compile and render correctly.
* **Automated Quality Checks:** Strict enforcement of `mix format`, `credo --strict`, and `dialyzer`.
* **CD & Release Please:** Commit messages must follow Conventional Commits. Merging to `main` should trigger Release Please to automatically generate changelogs, bump versions, and safely publish to `hex.pm`.

### Deployment Standards
* **Postgres-Only:** Absolute reliance on Postgres. No Redis, no SQLite, no MySQL. Use Postgres advisory locks, atomic updates, and pub/sub for all concurrency and signaling.
* **Phoenix Native:** Designed strictly for Elixir/Phoenix environments running in production (e.g., Fly.io, Gigalixir).
