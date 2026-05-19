# Research Summary: Oban Powertools Operator UX & Admin Dashboard

**Domain:** Operations, SRE, and Admin DX
**Researched:** 2024
**Overall confidence:** HIGH

## Executive Summary

Day-2 operations require tools for observability, safe remediation, and explication of complex distributed job states. Oban Powertools must bridge the gap between "what went wrong" and "how do I safely fix it." This research establishes a Hybrid Web Strategy that leverages the now open-source Oban Web for baseline operations while introducing a bespoke Powertools Native Shell for advanced capabilities like the Dry-Run Repair Center, workflow tracking, and limiter explication. Furthermore, a strict separation between cardinality-safe telemetry (for metrics via Parapet) and durable audit logs (for evidence via Threadline) ensures SRE-grade reliability without crashing monitoring infrastructure.

## Key Findings

**Architecture:** A 3-layer Web UI adopting Oban Web for generic job tables and a Powertools Shell for complex domain concepts (Limiters, Workflows, Repair).
**Feature:** SRE-grade "Explainability" for blocked jobs and a Dry-Run Repair Center for safe mutations.
**Critical Pitfall:** Cardinality explosion in metrics; strict separation between telemetry (low-cardinality) and audit events (high-cardinality evidence).

---

## 1. The Hybrid Web Strategy

Instead of boiling the ocean by rebuilding generic job lists, filtering, and charts, Powertools will utilize a tiered Web UI architecture:

1. **Powertools Web Shell (Layer A):** A Phoenix LiveView shell owning advanced Day-2 concepts (Limiters, Partitions, Dedupe, Idempotency Receipts, Dynamic Cron, Workflows, Lifeline Repair, Doctor, and Audit).
2. **Oban Web Bridge (Layer B):** An embedded instance of the OSS Oban Web (v2.11+ Apache 2.0) using shared auth, redaction, and telemetry for basic queue and job inspection.
3. **Fallback UI (Layer C):** A minimal job view for installations explicitly rejecting `oban_web`.

**Rationale:** Rebuilding paginated, real-time job searches and charts is a massive, low-leverage effort. The highest-value operations lie in managing Powertools-specific state machines (workflows, batches, limiters) that Oban Web does not comprehend. By wrapping Oban Web in a unified UI shell with shared policies (auth, redaction, audit), users get the "batteries-included" feel of a paid-tier offering on Day 0.

## 2. Operator Explainability for Blocked Jobs

A defining Day-2 capability is the explicit answer to: *"Why isn't this job running?"* 
Instead of operators guessing if it's a paused queue, saturated limiter, or workflow dependency, Powertools introduces an `explain/1` interface.

* **Mechanism:** Every blocked job explicitly returns tagged tuples like `{:blocked, {:rate_limit_exhausted, limiter: "github_api", resets_at: ~U[...]}}` or `{:blocked, {:workflow_dependency_incomplete, step: :fetch_user}}`.
* **UI Representation:** A dedicated "Why Blocked?" explanation card on the job or workflow detail page to turn confusing queue behavior into actionable operator context. This prevents wasted hours debugging external API throttles or DAG misconfigurations.

## 3. The Day-2 Dry-Run Repair Center

Orphaned jobs and stuck workflows can create retry storms or corrupt data if naively restarted. The Dry-Run Repair Center provides an SRE-grade remediation flow.

* **Orphan & Stuck Detection:** Automatically surfaces stale heartbeats, missing dependencies, and stuck chunks.
* **Operator Flow:** 
  1. Select Repair Action
  2. **Dry-Run Preview:** Show the exact SQL state transitions and affected scope without mutation.
  3. Require a written reason.
  4. Execute & Audit (logging to `oban_powertools_audit_events`).
* **Why:** This flow replaces ad-hoc console scripts (`iex`) with a safe, auditable UI, drastically reducing the blast radius of manual interventions. "Explain, then act" is the core tenet of the operator UI.

## 4. Cardinality-Safe Erlang Telemetry (Parapet Integration)

Metrics servers (Prometheus) crash when injected with high-cardinality labels (like `job_id`, `user_email`, or raw args). 

* **Strict Separation of Concerns:**
  * **Metrics (Erlang `:telemetry`):** Only low-cardinality dimensions are emitted (e.g., `queue`, `worker`, `limiter_name`, `error_kind`, `state`). Emits SLIs like `queue_latency_seconds`, `limiter_saturation_ratio`, and `job_failure_ratio` for Parapet consumption.
  * **Evidence (Audit Logs/Spans):** High-cardinality data belongs strictly in durable Ecto tables (`oban_powertools_audit_events`) or OpenInference span metadata for tools like Threadline and Scoria.
* **Result:** Operators get robust alerting rules (burn rates, latency SLOs) via Parapet without risking metric cardinality explosions, alongside rich audit logs for deep forensic debugging.

---

## Implications for Roadmap

Based on the research, the recommended phase structure:

1. **Phase 0.1: Foundation + Bridge**
   - Addresses: Establishing `ObanPowertools.Auth`, `ObanPowertools.Redaction`, and Telemetry rules. Mounts Oban Web via bridge.
   - Avoids: Rebuilding complex data grids and real-time metric polling from scratch.
2. **Phase 0.2-0.5: Native Powertools Capabilities**
   - Addresses: Native LiveView pages for Dedupe, Idempotency, Dynamic Cron, Queues, and Limiters. Implement Explainability (`explain/1`).
3. **Phase 0.6-0.7: Workflows & Lifeline Repair**
   - Addresses: Workflow DAG visualization and the Dry-Run Repair Center with the auditable "Preview -> Reason -> Execute" flow.
4. **Phase 0.8+: Parapet / SRE Observability Integration**
   - Addresses: Refine cardinality-safe telemetry metrics for seamless Parapet SLO and Grafana artifact generation.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Web Strategy | HIGH | Leveraging open-source Oban Web provides immediate ROI while custom LiveViews hit critical Day-2 gaps. |
| Explainability | HIGH | Explicit blocked tuples remove the biggest pain point of distributed job systems. |
| Repair Center | HIGH | Dry-run SRE workflows align perfectly with operator needs and prevent incident exacerbation. |
| Telemetry Safety | HIGH | Cardinality strictness is an established Prometheus/SRE best practice. |

## Gaps to Address

- **Mobile View:** Crosswake integration for a mobile operator view (Phase 1.x) needs deeper product definition.
- **Oban Web Breakages:** Need integration tests to ensure that changes in upstream Oban Web's internal formats don't break the Powertools Bridge resolver formatting and redaction.