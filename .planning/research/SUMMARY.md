# Research Summary: Oban Powertools

## Executive Summary

Oban Powertools is an "Ultimate Batteries-Included" background job operations layer designed for Phoenix applications within the szTheory ecosystem. Drawing lessons from historical footguns in background job processors like Sidekiq, Celery, and BullMQ, Powertools strictly rejects implicit magic, per-worker limits, and in-memory simulated DAGs. Instead, it relies on an Ecto-native, Postgres-only architecture that enforces transactional safety, durable idempotency receipts, and atomic global state management.

The recommended approach centers on giving developers fully host-owned code generated via Igniter, allowing them to install, inspect, and modify the underlying infrastructure. A hybrid 3-layer Web UI strategy wraps the open-source Oban Web with a bespoke Powertools Native Shell to handle complex Day-2 operations. This ensures that operators can safely observe, explain, and dry-run repair stuck queues and workflows without needing manual console scripts.

Key risks include cascading failures from rate-limit exhaustion, callback "zombies" in complex workflows, and Prometheus cardinality explosions from careless metrics. These are mitigated through explicit `explain/1` blocked states, persisted DAG state machines, and a strict separation between ephemeral low-cardinality telemetry (for Parapet) and durable high-cardinality Ecto audit logs (for Threadline).

## Key Findings

### Technical Architecture (Stack)
*   **Ecto-Native State Management:** All operational actions (retries, rate limits, workflow progression) are modeled as `Ecto.Multi` transactions inside PostgreSQL. No external data stores like Redis.
*   **Idempotency & Concurrency:** Rely on database-layer idempotency receipts and atomic updates for global token bucket rate limiters. Never use app-layer read-modify-write patterns.
*   **OTP/PubSub Integration:** Employ heartbeats for liveness tracking and Phoenix PubSub for rapid DAG workflow step signaling, avoiding slow DB polling where possible.

### Ecosystem DNA (Features)
*   **Host-Owned via Igniter:** Features and configuration are injected directly into the user's host application using AST-aware Igniter patches for maximum transparency and ownership.
*   **Seamless Integration:** Must interface seamlessly with other szTheory libraries: Sigra (Identity/Auth), Threadline (Auditing), Scoria (AI Tracing), and Parapet (Reliability).
*   **Testing Helpers:** Requires first-class testing helpers for deterministic time manipulation and isolated DB sandboxes for confident CI/CD pipelines.

### Operator UX (Architecture)
*   **Hybrid Web Strategy:** Utilize a three-layer architecture: a Powertools Web Shell for advanced operations (Limiters, Workflows, Dry-Run Repair) wrapping the standard Oban Web OSS viewer, with a fallback option.
*   **Explainable UI:** Every blocked job or workflow must explicitly detail the reason (e.g., rate limit exhaustion) to prevent operator guesswork.
*   **Dry-Run Repair Center:** Complex mutations (orphaned jobs, stuck DAGs) require an SRE-grade "Preview -> Reason -> Execute" flow that is auditable via Threadline.

### Domain Competitors (Pitfalls)
*   **The "Celery Trap" & Rate Limiting:** Per-worker limits inevitably cause external API bans when scaling. Global rate limiting must be explicit and avoid blocking worker processes (e.g., use `{:snooze, seconds}`).
*   **Callback Zombies & Simulated DAGs:** Deeply nested payloads and in-memory state cause lost callbacks on worker crash. DAGs must be explicit `oban_powertools_workflows` tables.
*   **Duplicate Execution Chaos:** The "exactly-once" myth causes duplicate billing/actions. Must rely on explicit Idempotency Receipts, compile-time arg validation with Ecto schemas, and cron catch-up policies.

## Implications for Roadmap

The roadmap must sequence foundational DB primitives before building higher-level UI and orchestration features.

1.  **Phase 0: Foundation, Ecosystem integration, & Telemetry Bridge**
    *   *Rationale:* Establishes base schemas, Igniter installers, Sigra Auth, and Parapet telemetry rules, while mounting the Oban Web bridge. 
    *   *Delivers:* Core Ecto schemas, AST-patching, and basic dashboard visibility without custom grids.
    *   *Avoids:* Exploding cardinality in metrics and rebuilding basic data tables.
2.  **Phase 1: Worker Ergonomics & Idempotency**
    *   *Rationale:* Pure application-layer enhancements for job definitions before managing complex state.
    *   *Delivers:* `use ObanPowertools.Worker` macro, compile-time Ecto schema arg validation, and Postgres-backed Idempotency Receipts.
    *   *Avoids:* Duplicate execution chaos and JSON deserialization footguns.
3.  **Phase 2: Smart Engine (Rate Limits & Dynamic Cron)**
    *   *Rationale:* Highly complex SQL logic that needs robust underlying infrastructure and testing helpers first.
    *   *Delivers:* Atomic SQL limiters (token buckets), dynamic cron with catch-up policies, and the `explain/1` capability.
    *   *Avoids:* Per-worker limit scaling traps and cron overlap storms.
4.  **Phase 3: Workflows (DAGs) & Signaling**
    *   *Rationale:* Requires rate limits and idempotency to be fully functional to prevent cascade failures in nested steps.
    *   *Delivers:* Explicit DAG workflow tables, GenServer coordinators, and Phoenix PubSub signaling.
    *   *Avoids:* Callback zombies and simulated in-memory graphs.
5.  **Phase 4: Lifeline & Dry-Run Repair Center**
    *   *Rationale:* Day-2 operations rely on the telemetry, limits, and workflows already existing in the system.
    *   *Delivers:* Heartbeat GenServers, SRE-grade dry-run repairs, and explicit SRE action auditing via Threadline.

### Research Flags

*   **Needs Research:** Phase 3 (Workflows) UI/UX visualization strategies; mobile operator view via Crosswake.
*   **Standard Patterns:** Phase 0 & 1 (Ecto schemas, Igniter installers, Idempotency Receipts) rely on established szTheory and PostgreSQL patterns.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack/Tech | HIGH | Based on direct alignment with Postgres/Ecto/OTP primitives and proven szTheory tenets. |
| Features/DNA | HIGH | Deeply integrated into the well-defined szTheory "SaaS-in-a-Box" model. |
| Architecture/UX | HIGH | Leveraging Oban Web provides ROI while solving critical Day-2 gaps via a Custom Shell. |
| Pitfalls | HIGH | Historical analysis of Sidekiq, Celery, and BullMQ provides explicit failure modes to avoid. |

**Gaps to Address:** 
*   Integration tests needed for the Oban Web Bridge to prevent breakage from upstream changes.
*   Deeper product definition for the Crosswake mobile view.

## Sources
*   .planning/research/tech_architecture.md
*   .planning/research/ecosystem_dna.md
*   .planning/research/operator_ux.md
*   .planning/research/domain_competitors.md