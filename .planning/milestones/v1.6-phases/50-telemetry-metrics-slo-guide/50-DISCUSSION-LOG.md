# Phase 50: Telemetry Metrics & SLO Guide - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 50-telemetry-metrics-slo-guide
**Areas discussed:** metrics/0 coverage, telemetry_poller role, SLO guide framing

> Advisor mode (USER-PROFILE.md present). Repo Decision Posture is decisive/minimal:
> recommendation-first, escalate only material public-surface choices. Recommendations
> were grounded in the frozen `@contract`, the `oban_web` optional-dep precedent, and the
> Parapet reference in `prompts/`. The user selected all three areas to discuss, reviewed
> the leaning recommendations, and locked all three as written.

---

## metrics/0 coverage

| Option | Description | Selected |
|--------|-------------|----------|
| Powertools-contract counters only | metrics/0 returns definitions for the 5 frozen families only; golden signals (latency/throughput/errors) come from Oban-core events; guide composes both | ✓ |
| Also bundle curated Oban-core job metrics | metrics/0 additionally emits latency/throughput/error-rate from Oban's own job events as a convenience, accepting overlap with reporters/Parapet | |

**User's choice:** Powertools-contract counters only (D-01/D-02).
**Notes:** Decisive factor — Parapet (and reporters generally) already instrument Oban core (failure rates + throughput) out-of-the-box, so re-emitting would duplicate and risk drift. Powertools' unique contribution is the control-plane SLIs Oban core can't see. Matches Success Criterion #1 ("over the frozen low-cardinality contract").

---

## telemetry_poller role

| Option | Description | Selected |
|--------|-------------|----------|
| Documented-only, no shipped poller | telemetry_poller declared optional + shown in guide; Powertools ships no query-backed poller measurement; live counts deferred to v1.9 (QRY-06) | ✓ |
| Ship a query-backed poller now | Powertools ships a poller measurement (e.g. queue-depth gauge) this phase | |

**User's choice:** Documented-only (D-03/D-04/D-05).
**Notes:** Live/queue counts require querying `oban_jobs` and are explicitly the v1.9 (QRY-06, optional `oban_met`) boundary. Both `telemetry_metrics` + `telemetry_poller` declared `optional: true` like `oban_web`; `metrics/0` guards on `Telemetry.Metrics` being loaded and fails loud/helpful when absent.

---

## SLO guide framing

| Option | Description | Selected |
|--------|-------------|----------|
| Reporter-agnostic with Parapet section | Generic Telemetry.Metrics reporter wiring + four golden signals + Powertools control-plane SLIs + a dedicated "Feeding Parapet SLOs" section; no oban_met | ✓ |
| Parapet-first framing | Guide centers on Parapet as the primary path | |

**User's choice:** Reporter-agnostic with Parapet section (D-06/D-07).
**Notes:** Honors TEL-03's reporter-agnostic requirement and "reporter choice is the host's". Parapet framed as one consumer. The frozen contract already satisfies Parapet's own "Telemetry as a Strict Public API" + "Cardinality Safety" tenets, so Powertools telemetry drops into burn-rate / `Parapet.SLO.define`-style alerting cleanly.

## Claude's Discretion

- Exact metric naming strings, per-family metric list, and whether any control-plane metric uses `last_value`/`summary` vs `counter`/`sum`.
- Whether the metric list is `@contract`-derived programmatically or an explicit hand-written list.
- Guide prose, example reporter (ConsoleReporter is the dependency-free default), and section ordering within the 4-part structure.
- Whether `metrics/0` stays plain arity-0 or gains a tag-prefix option (default: plain `metrics/0`).

## Deferred Ideas

- Query-backed poller / live queue counts (`available`/`executing`/queue depth) — v1.9 (QRY-06), `oban_met` optional read source only.
- Native generic-metrics dashboard — out of scope (rebuilds Oban Web).
- Bundling a concrete reporter (Prometheus/StatsD) — host's choice.
- Field-level changes to the frozen `@contract` — would be a SemVer-major telemetry break.
