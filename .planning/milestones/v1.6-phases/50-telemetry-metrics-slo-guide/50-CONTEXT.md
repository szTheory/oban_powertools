# Phase 50: Telemetry Metrics & SLO Guide - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Give hosts an opt-in, reporter-agnostic metrics surface plus an SLO guide over the **frozen** low-cardinality telemetry contract, with **zero new runtime dependency**. Three deliverables:

- **`ObanPowertools.Telemetry.metrics/0`** (TEL-01) — returns `Telemetry.Metrics` definitions over the 5 frozen event families. Opt-in, reporter-agnostic.
- **Optional-dep gating** (TEL-02) — `telemetry_metrics` + `telemetry_poller` declared `optional: true`, gated exactly like the existing `oban_web` integration; no runtime cost or failure when absent.
- **Parapet/SLO telemetry guide** (TEL-03) — `guides/telemetry-and-slos.md` documenting golden-signals/SLO setup over the metrics surface, no `oban_met` dependency.

**Out of scope:** changing the frozen `@contract` (any new family/measurement/tag); shipping a query-backed poller / live queue counts (v1.9, QRY-06); bundling any telemetry reporter (`telemetry_metrics_prometheus`, etc. — host's choice); a native generic-metrics dashboard or `oban_met` dependency; re-emitting Oban-core job metrics.
</domain>

<decisions>
## Implementation Decisions

### metrics/0 coverage (TEL-01)
- **D-01: Powertools-contract metrics ONLY — never Oban-core job metrics.** `metrics/0` returns `Telemetry.Metrics` definitions for exactly the 5 frozen families (`operator_action`, `limiter`, `cron`, `workflow`, `lifeline`) under the `[:oban_powertools, family, event_suffix]` prefix. Golden-signal latency/throughput/error-rate come from **Oban's own** `[:oban, :job, :stop|:exception]` events (measurements `:duration`, `:queue_time`) — which Parapet and every reporter already instrument out-of-the-box. Re-emitting them here would duplicate and risk drift. Powertools instead contributes the **control-plane SLIs Oban core lacks**: limiter blocks, cron overlaps/run-now, lifeline repair/incident outcomes, workflow terminal causes. Matches Success Criterion #1 ("over the frozen low-cardinality contract") and SC#4 (tags stay within the frozen contract).
- **D-02: One metric definition per documented event; tags = exactly the contract's allowed metadata keys.** Use `Telemetry.Metrics.counter/2` for event-occurrence counters over `:count`; use `sum/2` where a count-bearing measurement is meaningful to aggregate (e.g. lifeline `archived_count`/`pruned_count`). Each metric's `:tags` are drawn ONLY from the family's contract-allowed metadata keys (`telemetry.ex` `@contract`) — low-cardinality by construction, no `job_id`/`args`/reasons. The workflow family is per-event-suffix (the contract nests tags by suffix), so its metrics are defined per documented workflow event, not one generic workflow metric.

### Optional-dep gating (TEL-02)
- **D-03: Gate exactly like `oban_web`.** Both `telemetry_metrics` and `telemetry_poller` added to `mix.exs` deps as `optional: true` (mirroring `{:oban_web, "~> 2.10", optional: true}` at `mix.exs:54`). No runtime cost when the host doesn't pull them.
- **D-04: `metrics/0` guards on `Telemetry.Metrics` being loaded.** Follow the established runtime gate (`Code.ensure_loaded?/1`, as in `application.ex:25` for `Phoenix.PubSub`): if `Telemetry.Metrics` is unavailable, `metrics/0` raises a clear, actionable error telling the host to add `:telemetry_metrics` to their deps — it does not silently return `[]`. This is the bridge pattern: the feature is opt-in, and asking for it without the dep is an honest, helpful failure.
- **D-05: Ship NO query-backed poller measurement this phase.** `telemetry_poller` is declared optional and demonstrated in the guide (so host poller examples compile/run in their app), but Powertools itself emits nothing periodic. Live queue depth / `available`/`executing` counts require querying `oban_jobs` and are explicitly deferred to **v1.9 (QRY-06)** with optional `oban_met`. This phase's `telemetry_poller` role is documentation + the host's own poller wiring only.

### Parapet/SLO guide (TEL-03)
- **D-06: One reporter-agnostic guide — `guides/telemetry-and-slos.md`.** Added to `mix.exs` ExDoc `groups_for_extras` under the **Operations** group (alongside `production-hardening.md`, `troubleshooting.md`, etc.). Reporter choice is the host's — the guide wires `metrics/0` into a host `Telemetry` supervisor with a *generic* reporter, never bundling one.
- **D-07: Guide structure (4 parts).**
  1. **Wire it up** — add `:telemetry_metrics`(+`:telemetry_poller`) to the host, mount `ObanPowertools.Telemetry.metrics/0` in the host's `Telemetry` supervisor child spec with the host's chosen reporter.
  2. **The four golden signals for Oban-backed work** — latency/throughput from Oban-core `[:oban, :job, :stop]` (`duration`, `queue_time`), errors from `[:oban, :job, :exception]`, saturation noted as host/Oban-sourced (live counts → v1.9). These are Oban-core, NOT Powertools metrics — the guide is explicit about the seam.
  3. **Powertools control-plane SLIs** — what `metrics/0` adds that Oban core can't see: limiter saturation (`limiter.blocked` count by `blocker_code`/`resource`/`scope`), repair/incident outcomes (`lifeline` by `incident_class`/`outcome`), workflow terminal failures (`workflow.workflow_terminal` by `outcome`/`terminal_cause`), cron overlap/catch-up.
  4. **Feeding Parapet SLOs** — Powertools telemetry is already a strict, documented, low-cardinality public API (matches Parapet's own "Telemetry as a Strict Public API" + "Cardinality Safety" tenets), so it drops cleanly into burn-rate / `Parapet.SLO.define`-style alerting. Parapet is framed as **one consumer**, not a coupling. Explicit "no `oban_met` dependency" note.

### Claude's Discretion
- Exact metric naming convention strings (e.g. `"oban_powertools.limiter.blocked.count"`), whether any control-plane metric is better expressed as `last_value`/`summary` vs `counter`/`sum`, the precise per-family metric list, and whether a small private helper builds the metric list from `@contract` programmatically vs an explicit hand-written list — planner/executor decide. (A `@contract`-derived list is attractive for drift-safety but the contract's nested workflow shape may make an explicit list clearer; either is acceptable.)
- Exact guide prose, code-sample reporter (Telemetry.Metrics.ConsoleReporter is the safe dependency-free example), and section ordering within the 4-part structure.
- Whether `metrics/0` is `metrics/0` only or also offers an arity/option for tag-prefix customization — only add if a clean, low-surface need emerges; default to plain `metrics/0`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` — Phase 50 goal, requirements (TEL-01/02/03), and the 4 success criteria.
- `.planning/REQUIREMENTS.md` §"Telemetry & SLOs" (TEL-01/02/03) and the Out-of-Scope rows (no `oban_met` hard dep; no bundled reporter).

### The frozen contract — the single source of truth for what metrics/0 may expose
- `lib/oban_powertools/telemetry.ex` — `@contract` (5 families, `:count` measurement, per-family allowed metadata keys; workflow tags nested per event suffix), `contract/0`, and the `execute_*_event/3` emitters. **`metrics/0` must stay strictly within `@contract`. Read in full before planning.**
- `test/oban_powertools/telemetry_test.exs` — existing contract test coverage; new `metrics/0` tests extend this file's posture.

### Optional-dep gating analogs (copy this pattern)
- `mix.exs:54` — `{:oban_web, "~> 2.10", optional: true}` — the exact optional-dep declaration to mirror for `telemetry_metrics` + `telemetry_poller`.
- `lib/oban_powertools/application.ex:25` — `Code.ensure_loaded?/1` runtime-gate pattern (used for `Phoenix.PubSub`) — the model for `metrics/0`'s guard on `Telemetry.Metrics`.
- `lib/oban_powertools/auth.ex:42-97` — additional `Code.ensure_loaded`/`function_exported?` optional-integration precedent.

### Guide home & convention
- `mix.exs:65-92` — ExDoc `extras` + `groups_for_extras`; new guide registers under the **Operations** group.
- `guides/limits-and-explain.md`, `guides/production-hardening.md`, `guides/troubleshooting.md` — tone/structure/length precedent for an Operations guide.
- `guides/optional-oban-web-bridge.md` — precedent for documenting an OPT-IN optional-dep integration (mirrors how the telemetry guide frames the opt-in metrics surface).

### Parapet integration framing (source of the SLO-consumer story)
- `prompts/oban-powertools-deep-research-original-prompt.md` §"parapet overview" (≈ lines 124-200) — Parapet's role (consumes SLIs for SLO alerting + burn-rate Prometheus rules), its "Universal Phoenix Metrics" already instrument **Oban core** (job failure rates + throughput — hence D-01's no-duplication rule), and its tenets ("Telemetry as a Strict Public API", "Cardinality Safety") that the frozen contract already satisfies. **Read before writing the guide's Parapet section.**

### Prior-phase convention donor
- `.planning/phases/49-limiter-explain-simulate-cli/49-CONTEXT.md` — single-source-of-truth doc pattern (glossary fed both code + guide), zero-new-runtime-dep posture, reuse-not-duplicate discipline.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ObanPowertools.Telemetry.@contract` / `contract/0` — the authoritative, machine-readable definition of every family, measurement, and allowed tag. `metrics/0` is a derivation of this; tests can assert `metrics/0` never exceeds `contract/0`'s tag sets.
- The 5 `execute_*_event/3` emitters confirm the live event suffixes actually fired in the codebase (e.g. `limiter :blocked`/`:released`/`:cooled_down`, `lifeline :archive_prune_completed`/`:heartbeat_refresh`, `workflow :step_completed`/`:step_unblocked`/`:cascade_cancelled`/`:workflow_terminal`, `cron :paused`/`:resumed`/`:run_now`/`:slot_claimed`, `operator_action :previewed`/`:complete`) — ground the metric list in what's emitted, not just what's allowed.

### Established Patterns
- Optional integrations are `optional: true` in `mix.exs` + a `Code.ensure_loaded?/1` runtime guard — never a hard require. `telemetry` (non-optional, `~> 1.4`) is already a dep; `telemetry_metrics`/`telemetry_poller` are the new optional siblings.
- Guides live in `guides/*.md`, auto-globbed into ExDoc `extras`, and explicitly grouped via `groups_for_extras`. A new guide must be added to a group or it lands ungrouped.
- Docs/strings that exist in two places use a single source of truth (Phase 49 glossary precedent) — here, the *contract itself* is that source for the metric list.

### Integration Points
- New code is contained to: `lib/oban_powertools/telemetry.ex` (add `metrics/0` + guard), `mix.exs` (2 optional deps + 1 `groups_for_extras` entry), `guides/telemetry-and-slos.md` (new), `test/oban_powertools/telemetry_test.exs` (extend). No changes to any emitter call site or the frozen `@contract`.
- REL-01 `:files` whitelist already ships `lib/` and `guides/` in the published package — confirm the new guide is picked up by the published-package globs (relevant to Phase 51 verification).
</code_context>

<specifics>
## Specific Ideas

- Parapet already instruments Oban core (failure rates + throughput) out-of-the-box — so Powertools' value is the **control-plane SLIs Oban core can't see** (limiter/cron/lifeline/workflow), NOT re-emitting job latency/throughput (D-01).
- The frozen contract already satisfies Parapet's own "Telemetry as a Strict Public API" and "Cardinality Safety" tenets — the guide should say so explicitly; it's why Powertools telemetry drops into Parapet SLOs cleanly.
- `metrics/0` asking-without-the-dep should fail loud and helpful ("add `:telemetry_metrics`"), not silently return `[]` — honesty over magic, consistent with the lib's posture (D-04).
</specifics>

<deferred>
## Deferred Ideas

- Query-backed poller / live queue counts (`available`/`executing`/queue depth) — **v1.9 (QRY-06)**, with `oban_met` as an optional read source only. Out of Phase 50.
- A native generic-metrics dashboard — explicitly out of scope (that's rebuilding Oban Web).
- Bundling a concrete reporter (`telemetry_metrics_prometheus`, StatsD, etc.) — host's choice; the lib only exposes definitions.
- Field-level changes to the frozen `@contract` (new families/measurements/tags) — would be a SemVer-major telemetry break; not this phase.

None of these block Phase 50.
</deferred>

---

*Phase: 50-telemetry-metrics-slo-guide*
*Context gathered: 2026-05-29*
