# Phase 50: Telemetry Metrics & SLO Guide - Research

**Researched:** 2026-05-29
**Domain:** Elixir telemetry_metrics optional-dep integration + ExDoc guide authoring
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `metrics/0` returns definitions for exactly the 5 frozen families under `[:oban_powertools, family, event_suffix]`. Oban-core job events (`[:oban, :job, *]`) are NOT included — golden-signal latency/throughput/error-rate come from Oban's own events which Parapet already instruments. Powertools contributes control-plane SLIs Oban core lacks.
- **D-02:** One metric definition per documented event. Tags = exactly the contract's allowed metadata keys. `counter/2` for event-occurrence over `:count`; `sum/2` where count-bearing measurement is meaningful to aggregate (e.g. lifeline `archived_count`/`pruned_count`). Workflow metrics are per-event-suffix (contract nests tags by suffix).
- **D-03:** Both `telemetry_metrics` and `telemetry_poller` added to `mix.exs` deps as `optional: true`, mirroring `{:oban_web, "~> 2.10", optional: true}` at `mix.exs:54`.
- **D-04:** `metrics/0` guards on `Code.ensure_loaded?(Telemetry.Metrics)`. If absent, raises a clear, actionable error telling the host to add `:telemetry_metrics` — does NOT silently return `[]`.
- **D-05:** NO query-backed poller emitted by Powertools this phase. `telemetry_poller` is optional and demonstrated in the guide only. Live queue counts deferred to v1.9 (QRY-06).
- **D-06:** One guide: `guides/telemetry-and-slos.md`. Added to ExDoc `groups_for_extras` under the **Operations** group.
- **D-07:** Guide structure — 4 parts: (1) Wire it up, (2) Four golden signals for Oban-backed work, (3) Powertools control-plane SLIs, (4) Feeding Parapet SLOs.

### Claude's Discretion

- Exact metric naming convention strings (e.g. `"oban_powertools.limiter.blocked.count"`).
- Whether any control-plane metric is better expressed as `last_value`/`summary` vs `counter`/`sum`.
- Precise per-family metric list.
- Whether a small private helper builds the metric list from `@contract` programmatically vs an explicit hand-written list.
- Exact guide prose, code-sample reporter (`Telemetry.Metrics.ConsoleReporter` is the safe dependency-free example).
- Section ordering within the 4-part structure.
- Whether `metrics/0` offers arity/option for tag-prefix customization (default: plain `metrics/0` only).

### Deferred Ideas (OUT OF SCOPE)

- Query-backed poller / live queue counts (`available`/`executing`/queue depth) — v1.9 (QRY-06).
- Native generic-metrics dashboard.
- Bundling a concrete reporter (`telemetry_metrics_prometheus`, StatsD, etc.).
- Field-level changes to the frozen `@contract`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEL-01 | Host can call `ObanPowertools.Telemetry.metrics/0` to obtain `Telemetry.Metrics` definitions over the frozen low-cardinality contract — opt-in and reporter-agnostic. | Full `Telemetry.Metrics` API verified; concrete metric list derived from `@contract` + actual call sites. |
| TEL-02 | `telemetry_metrics` and `telemetry_poller` are optional dependencies gated like the existing `oban_web` integration — no runtime cost or failure when absent. | Exact `mix.exs` syntax confirmed; `Code.ensure_loaded?` pattern documented from `application.ex`. |
| TEL-03 | A Parapet/SLO telemetry guide documents golden-signals/SLO setup over the metrics surface, with no `oban_met` dependency. | Parapet tenets read; golden signal seam (Oban-core vs Powertools) confirmed; guide structure locked in D-07. |
</phase_requirements>

---

## Summary

Phase 50 has three discrete deliverables: (1) a `metrics/0` function added to the existing `ObanPowertools.Telemetry` module that returns a list of `Telemetry.Metrics` metric-definition structs covering the 5 frozen event families; (2) two `optional: true` dep declarations in `mix.exs`; (3) a new `guides/telemetry-and-slos.md` Operations guide.

The technical work is contained and low-risk. `Telemetry.Metrics` (v1.1.0, 45M hex downloads) ships `counter/2`, `sum/2`, `last_value/2`, `summary/2`, and `distribution/2`. The metric name parsing convention (`"a.b.c.measurement"` → event `[:a, :b, :c]`, measurement `:measurement`) maps cleanly onto the `[:oban_powertools, family, suffix, :count]` event shape. The frozen `@contract` is the single source of truth for both event names and permitted tag lists — `metrics/0` is a derivation of it, not an independent invention.

The Parapet integration is a framing story in the guide, not a library dependency. Parapet's own "Universal Phoenix Metrics" already instruments Oban-core job failure rates and throughput (`[:oban, :job, :stop|:exception]`), so Powertools' `metrics/0` adds the complementary control-plane SLIs (limiter blocks, lifeline repair outcomes, workflow terminal causes, cron schedule events) that Parapet cannot see without Powertools.

**Primary recommendation:** Implement `metrics/0` as an explicit hand-written list (not `@contract`-derived programmatically) for clarity. The workflow family's nested per-suffix structure makes a programmatic derivation complex; an explicit list is readable, testable, and stable. Add it to `lib/oban_powertools/telemetry.ex` with a `Code.ensure_loaded?` guard. Extend `test/oban_powertools/telemetry_test.exs` with a single structural test that asserts (a) `metrics/0` returns a non-empty list of metric structs and (b) every tag in every metric is within the contract for that family+suffix. Add the guide and wire it into `mix.exs`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `metrics/0` function (metric definitions list) | Library (`lib/`) | — | Pure data derivation from `@contract`; no process, no supervisor |
| Optional-dep gating (`Code.ensure_loaded?`) | Library (`lib/`) | `mix.exs` | Matches existing pattern in `application.ex` and `auth.ex` |
| ExDoc guide | Docs (`guides/`) | `mix.exs` `groups_for_extras` | All guides follow this pattern |
| Test coverage | Test (`test/`) | — | Extends existing `telemetry_test.exs` |
| Reporter (ConsoleReporter example) | Host app | — | Reporter is never bundled; guide shows pattern only |
| Parapet SLO wiring | Host app | Guide docs | Guide shows the framing; no Powertools code change |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `telemetry_metrics` | `~> 1.0` | Provides metric-definition structs (`counter/2`, `sum/2`, etc.) | De-facto standard for Elixir metrics definitions; 45M hex downloads; beam-telemetry/telemetry_metrics official repo; ships `ConsoleReporter` out of the box [VERIFIED: hex.pm] |
| `telemetry_poller` | `~> 1.0` | Periodic measurements (VM memory, CPU); demonstrated in guide for host wiring | beam-telemetry/telemetry_poller; 44M hex downloads; standard companion to telemetry_metrics [VERIFIED: hex.pm] |
| `telemetry` | `~> 1.4` | Core event emission (already a hard dep in `mix.exs`) | Already present; no change needed [VERIFIED: hex.pm] |

**Version constraint rationale:** `~> 1.0` for both optional deps covers the current latest (1.1.0 / 1.3.0) while matching how Phoenix and standard Elixir libraries express this range. The `~> 0.6` range for `telemetry_metrics` is obsolete — v1.0 shipped 2024-03-18.

**No new runtime dependency:** `telemetry_metrics` and `telemetry_poller` are `optional: true`. They are **not** started by `ObanPowertools.Application`. Zero runtime cost when absent.

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Telemetry.Metrics.ConsoleReporter` | (ships with `telemetry_metrics`) | Debug reporter — prints events to terminal | Guide code example only; host uses this for local smoke-testing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `telemetry_metrics ~> 1.0` | `~> 0.6` | `~> 0.6` is obsolete; API is stable across 0.6→1.x but `~> 1.0` signals current posture |
| Explicit metric list | `@contract`-derived programmatic list | Programmatic is drift-safe but the workflow family's nested map makes it complex; explicit list is easier to read, review, and test |
| `counter/2` everywhere | `sum/2` for aggregatable counts | `sum/2` is correct for `archived_count`/`pruned_count` where the measurement value carries semantic quantity |

**Installation (in `mix.exs` only — no `mix deps.get` step in planning):**
```elixir
{:telemetry_metrics, "~> 1.0", optional: true},
{:telemetry_poller, "~> 1.0", optional: true},
```

---

## Package Legitimacy Audit

> slopcheck was unavailable at research time. These are Hex/Elixir packages — npm slopcheck does not apply. Verified against hex.pm directly.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `telemetry_metrics` | hex.pm | ~6 yrs (v0.1 ~2019) | 45.7M all-time | github.com/beam-telemetry/telemetry_metrics | N/A (Hex) | Approved [VERIFIED: hex.pm] |
| `telemetry_poller` | hex.pm | ~6 yrs | 44.2M all-time | github.com/beam-telemetry/telemetry_poller | N/A (Hex) | Approved [VERIFIED: hex.pm] |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*Both packages are maintained by the beam-telemetry GitHub organization (the same org that maintains `:telemetry` itself, which is already a hard dep). Official origin, high download counts, long track record.*

---

## Architecture Patterns

### System Architecture Diagram

```
ObanPowertools.Telemetry.metrics/0
         │
         ▼ (returns list of Telemetry.Metrics structs)
         │
┌────────┴─────────────────────────────────────────┐
│  Host Telemetry Supervisor                        │
│  children: [                                     │
│    {MyReporter, metrics: ObanPowertools.Telemetry.metrics()},  │
│    {:telemetry_poller, measurements: [...]}       │
│  ]                                               │
└──────────────────────────────────────────────────┘
         │
         ▼ (subscribes to telemetry events)
         │
┌────────┴──────────────────────┐
│  :telemetry event bus          │
│  [:oban_powertools, family, suffix]  │
└───────────────────────────────┘
         ▲
         │ (emitted by existing Powertools emitters)
┌────────┴──────────────────────┐
│  Powertools runtime            │
│  execute_limiter_event/3       │
│  execute_cron_event/3          │
│  execute_workflow_event/3      │
│  execute_lifeline_event/3      │
│  execute_operator_action/3     │
└───────────────────────────────┘
```

Note: Powertools emits to `:telemetry`. `metrics/0` returns metric definitions that any reporter can subscribe to. No new process is started by this phase. The host owns the supervision tree.

### Recommended Project Structure

No new files or directories. Changes are confined to:

```
lib/oban_powertools/
└── telemetry.ex          # Add metrics/0 + Code.ensure_loaded? guard

guides/
└── telemetry-and-slos.md # New Operations guide

mix.exs                   # 2 optional deps + 1 groups_for_extras entry

test/oban_powertools/
└── telemetry_test.exs    # Extend with metrics/0 structural tests
```

### Pattern 1: `Telemetry.Metrics` Counter Over `:count` Measurement

The frozen `@contract` emits `%{count: 1}` as measurements for almost every event (exception: `:heartbeat_refresh` emits `%{count: length(heartbeats)}`). The metric name string convention `"oban_powertools.family.suffix.count"` auto-parses to `event_name: [:oban_powertools, :family, :suffix]` and `measurement: :count`.

```elixir
# Source: hexdocs.pm/telemetry_metrics/1.1.0/Telemetry.Metrics.html
import Telemetry.Metrics

counter(
  "oban_powertools.limiter.blocked.count",
  tags: [:blocker_code, :resource, :scope],
  description: "Limiter blocked a job enqueue"
)
```

The `:tags` list must be a subset of the contract's allowed metadata keys for that family. For `limiter`, the contract allows `[:action, :blocker_code, :resource, :scope]`. Tags like `job_id` or `args` are NOT in the contract and must never appear in `:tags`.

### Pattern 2: `sum/2` for Count-Bearing Measurements

`archive_prune_completed` emits both `archived_count` and `pruned_count` in its metadata. These are raw counts of records processed per run — they are meaningful to aggregate over time. Use `sum/2` with an explicit `:measurement` option pointing into the metadata map.

```elixir
# Source: hexdocs.pm/telemetry_metrics/1.1.0/Telemetry.Metrics.html
sum(
  "oban_powertools.lifeline.archive_prune_completed.archived_count",
  event_name: [:oban_powertools, :lifeline, :archive_prune_completed],
  measurement: :archived_count,
  tags: [:outcome],
  description: "Records archived by lifeline prune run"
)
```

Note: When providing explicit `:event_name` and `:measurement`, the metric name string becomes a label only (it no longer drives auto-parsing).

### Pattern 3: `Code.ensure_loaded?` Guard for Optional Dep

Mirrors `application.ex:25` (Phoenix.PubSub guard) exactly.

```elixir
# Source: lib/oban_powertools/application.ex - established pattern in this codebase
def metrics do
  if Code.ensure_loaded?(Telemetry.Metrics) do
    build_metrics()
  else
    raise """
    ObanPowertools.Telemetry.metrics/0 requires :telemetry_metrics.
    Add it to your dependencies:

        {:telemetry_metrics, "~> 1.0"}

    then run `mix deps.get`.
    """
  end
end
```

### Pattern 4: Supervision Tree Wiring (for guide — NOT in Powertools code)

```elixir
# Source: hexdocs.pm/telemetry_metrics/1.1.0/Telemetry.Metrics.html
# This goes in the HOST application, not in Powertools.
defmodule MyApp.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      # Swap ConsoleReporter for your chosen reporter in production
      {Telemetry.Metrics.ConsoleReporter,
       metrics: ObanPowertools.Telemetry.metrics()},
      # Optional: periodic VM measurements
      {:telemetry_poller,
       measurements: periodic_measurements(),
       period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp periodic_measurements do
    [
      {:process_info,
       event: [:my_app, :prom_ex],
       name: MyApp.PromEx,
       keys: [:message_queue_len, :memory]}
    ]
  end
end
```

### Anti-Patterns to Avoid

- **Including Oban-core job metrics in `metrics/0`:** `[:oban, :job, :stop|:exception]` events (`duration`, `queue_time`) are already instrumented by Parapet and every reporter out of the box. Re-emitting them from Powertools would duplicate and risk drift. (D-01 locked this out.)
- **Silent `[]` return when dep is absent:** Returning an empty list hides the misconfiguration. Raise a clear error. (D-04.)
- **Adding high-cardinality tags:** `job_id`, `args`, `reason`, `preview_token` are intentionally excluded from the `@contract`. They must never appear in `:tags`. The contract is the guard.
- **Hard-requiring `telemetry_metrics` in `mix.exs`:** It must stay `optional: true`. Removing `optional: true` breaks the zero-runtime-dep promise for hosts that don't use metrics.
- **Starting a supervisor process from Powertools for the reporter:** Powertools returns definitions only. The host owns the Telemetry supervisor. (This is the reporter-agnostic posture.)
- **Using `last_value` for event counters:** `last_value` is for gauge-style measurements (VM memory, queue depth). Use `counter` for event occurrence.

---

## Concrete Metric List (Derived from `@contract` + Actual Call Sites)

The following is the complete, authoritative list of events actually emitted by the codebase, with the metadata keys each event fires. This is what `metrics/0` must cover.

### operator_action family — tags: `[:action, :source]`

Actual suffixes emitted:
- `:previewed` — `%{action: action, source: entry.source}` (cron_live.ex)
- `:complete` — `%{action: "pause_cron_entry"|"resume_cron_entry"|"run_cron_entry", source: entry.source}` (cron.ex)

Metric: One `counter/2` per suffix, tags `[:action, :source]`.

### limiter family — tags: `[:action, :blocker_code, :resource, :scope]`

Actual suffixes emitted:
- `:blocked` — `%{action: "blocked", blocker_code: blocker.code, resource: snapshot.resource_name, scope: snapshot.scope_kind}`
- `:released` — `%{action: "released", resource: reservation.snapshot.resource_name, scope: reservation.snapshot.scope_kind}` (no `blocker_code`)
- `:cooled_down` — `%{action: "cooled_down", resource: resource.name, scope: resource.scope_kind}` (no `blocker_code`)

Metric: One `counter/2` per suffix. Tags for `:blocked` = `[:blocker_code, :resource, :scope]`; for `:released`/`:cooled_down` = `[:resource, :scope]` (omitting `:action` and `:blocker_code` which are absent or redundant with event name). [ASSUMED — discretion left to planner/executor per context D-02 guidance]

### cron family — tags: `[:action, :source, :overlap_policy, :catch_up_policy]`

Actual suffixes emitted:
- `:paused` — `%{action: "paused", source: entry.source, overlap_policy: entry.overlap_policy}` (no `catch_up_policy`)
- `:resumed` — `%{action: "resumed", source: entry.source, overlap_policy: entry.overlap_policy}` (no `catch_up_policy`)
- `:run_now` — `%{action: "run_now", source: entry.source, overlap_policy: entry.overlap_policy}` (no `catch_up_policy`)
- `:slot_claimed` — `%{action: decision, source: entry.source, overlap_policy: entry.overlap_policy, catch_up_policy: entry.catch_up_policy}` (all 4 keys)

Metric: One `counter/2` per suffix. Tags for `:slot_claimed` = `[:source, :overlap_policy, :catch_up_policy]`; for pause/resume/run_now = `[:source, :overlap_policy]`. [ASSUMED — discretion for final tag list]

### workflow family — nested tags per suffix (contract maps suffix → allowed keys)

Actual suffixes emitted:
- `:step_completed` — `%{outcome: status, terminal_cause: updated_step.terminal_cause, semantics_version: updated_workflow.semantics_version}` — contract: `[:outcome, :terminal_cause, :semantics_version]`
- `:step_unblocked` — `%{scope: "dependency", state: "available", semantics_version: workflow.semantics_version}` — contract: `[:scope, :state, :semantics_version]`
- `:cascade_cancelled` — `%{scope: "dependency", outcome: "cancelled", terminal_cause: "cancelled_by_dependency", semantics_version: workflow.semantics_version}` — contract: `[:scope, :outcome, :terminal_cause, :semantics_version]`
- `:workflow_terminal` — `%{state: new_workflow.state, outcome: "terminal", terminal_cause: new_workflow.terminal_cause, semantics_version: new_workflow.semantics_version}` — contract: `[:state, :outcome, :terminal_cause, :semantics_version]`

Metric: One `counter/2` per suffix with tags drawn from that suffix's contract keys. `:semantics_version` is low-cardinality (integer version number) and is a valid tag.

### lifeline family — tags: `[:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]`

Actual suffixes emitted:
- `:heartbeat_refresh` — `%{action: "heartbeat_refresh"}`, measurement `count: length(heartbeats)` (variable count). This is a gauge-like periodic measurement — the measurement itself carries meaningful quantity. Best expressed as `sum/2` (aggregate refreshed heartbeats over time) or `counter/2` (count refresh events).
- `:incident_projection` — `%{action: "incident_projection"}`, measurement `count: length(active_incidents)`.
- `:repair_previewed` — `%{action: preview.action, incident_class: preview.incident_class, target_type: preview.target_type}` (+ optional telemetry_metadata merge).
- `:archive_prune_completed` — `%{action: "archive_prune", outcome: "ok"|"blocked", archived_count: N, pruned_count: N}`. The `archived_count` and `pruned_count` are in metadata, NOT measurements map — they cannot be directly used as the metric's `:measurement`. Use `counter/2` for event occurrence and separately define `sum/2` with `measurement: fn _measurements, metadata -> metadata.archived_count end` for quantity aggregation. [ASSUMED — this is the key complexity to verify during implementation]
- `:repair_executed` — `%{action: preview.action, incident_class: preview.incident_class, target_type: preview.target_type}`.

**Critical note on `archived_count`/`pruned_count`:** The context document (D-02) says "use `sum/2` where a count-bearing measurement is meaningful to aggregate (e.g. lifeline `archived_count`/`pruned_count`)". However, looking at the actual `execute_lifeline_event/3` call for `:archive_prune_completed`, these values are in the **metadata map**, not the **measurements map**. `Telemetry.Metrics.sum/2` draws from the measurements map by default. To use metadata values as measurements, you need the `:measurement` option with a function: `measurement: fn _measurements, metadata -> metadata.archived_count end`. Alternatively, since the `archived_count` key is in the contract's metadata keys list (not measurement_keys), the planner/executor must decide whether to expose these as `sum/2` with a function measurement or simply as part of the `counter/2` context. This is a discretion item.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Metric definition structs | Custom metric structs | `Telemetry.Metrics.counter/2` etc. | `Telemetry.Metrics` is the ecosystem standard; reporters expect these exact struct types |
| Reporter | Custom telemetry handler that aggregates/ships | Host-provided reporter (Prometheus, StatsD, etc.) | Reporter is host's responsibility; Powertools only provides definitions |
| Optional-dep detection | Custom Mix compilation-time check | `Code.ensure_loaded?/1` at runtime | Established pattern in this codebase; simple and reliable |

**Key insight:** `metrics/0` is a pure function that returns a data structure. It owns no process, no ETS table, no handler attachment. Reporters call it and use the definitions to attach their own handlers.

---

## Common Pitfalls

### Pitfall 1: `archived_count`/`pruned_count` Are Metadata, Not Measurements
**What goes wrong:** Attempting `sum("...archived_count", measurement: :archived_count)` without specifying `:event_name` explicitly. Auto-parsing would set `event_name: [:oban_powertools, :lifeline, :archive_prune_completed]` and `measurement: :archived_count` — but `:archived_count` is in the **metadata** map (third argument to `:telemetry.execute/3`), not the measurements map (second argument). The reporter will get `nil` or 0 for the measurement.
**Why it happens:** The `@contract` lists `archived_count` as an allowed metadata key. The `execute_lifeline_event(:archive_prune_completed, %{count: 1}, %{archived_count: N})` emitter puts it in metadata, not measurements.
**How to avoid:** Either (a) use a `:measurement` function: `measurement: fn _m, metadata -> Map.get(metadata, :archived_count, 0) end`; or (b) simplify to `counter/2` for event occurrence and omit the quantity aggregation metric (acceptable for v1.0 of this feature). The planner/executor should decide which is cleaner.
**Warning signs:** `sum` metric always reports 0 in ConsoleReporter output during testing.

### Pitfall 2: Missing `groups_for_extras` Entry
**What goes wrong:** The new guide auto-globs into `extras` via `Path.wildcard("guides/*.md")` but lands ungrouped in ExDoc output if not added to `groups_for_extras`.
**Why it happens:** The wildcard picks up ALL `.md` files in guides/; grouping is explicit.
**How to avoid:** Add `"guides/telemetry-and-slos.md"` to the `Operations` group in `mix.exs:79-86` alongside existing Operations guides.
**Warning signs:** `mix docs` builds without error but the guide appears outside any group in the sidebar.

### Pitfall 3: Optional Dep Compile Error When Absent
**What goes wrong:** Calling `Telemetry.Metrics.counter(...)` in the function body at module compile time (e.g. as a `@module_attribute`) when the dep is absent causes a compile error.
**Why it happens:** Module-level attribute expansion happens at compile time; if `Telemetry.Metrics` isn't loaded, the reference fails.
**How to avoid:** Keep ALL `Telemetry.Metrics.*` calls inside function bodies guarded by `Code.ensure_loaded?`. Never compute the metrics list at module-attribute level.
**Warning signs:** `** (CompileError) function Telemetry.Metrics.counter/2 is undefined` when trying to compile without the optional dep.

### Pitfall 4: Using `:action` as a Tag When It Mirrors the Event Name
**What goes wrong:** Including `:action` as a tag when the value is always identical to the event suffix (e.g. `:blocked` event always has `action: "blocked"`). This adds cardinality with zero additional information.
**Why it happens:** `:action` is in the contract for most families; developers include it reflexively.
**How to avoid:** Only include `:action` in tags for events where the action value varies (e.g. `operator_action.complete` where action is `"pause_cron_entry"` vs `"resume_cron_entry"` vs `"run_cron_entry"`).

### Pitfall 5: Tag Value Atom vs String
**What goes wrong:** Telemetry metadata typically uses string values (e.g. `scope: "partitioned"`, `outcome: "ok"`) but `:tags` in `Telemetry.Metrics` expects the metadata key as an atom. The tag values flow through as-is. Some reporters may stringify atoms vs strings differently.
**Why it happens:** Elixir telemetry metadata conventions are not enforced; Powertools uses string values for string fields consistently.
**How to avoid:** No action needed in Powertools — the contract already uses string values for string fields (verified from actual call sites). Document in the guide that tag values are strings (e.g. `scope: "partitioned"` not `scope: :partitioned`).

---

## Code Examples

### Complete `metrics/0` Skeleton (for planner reference)

```elixir
# Source: lib/oban_powertools/telemetry.ex (new function)
# Pattern derived from: hexdocs.pm/telemetry_metrics/1.1.0/Telemetry.Metrics.html

import Telemetry.Metrics, only: [counter: 2, sum: 2]

def metrics do
  unless Code.ensure_loaded?(Telemetry.Metrics) do
    raise """
    ObanPowertools.Telemetry.metrics/0 requires the :telemetry_metrics dependency.
    Add it to your mix.exs:

        {:telemetry_metrics, "~> 1.0"}

    then run `mix deps.get` and restart your application.
    """
  end

  [
    # operator_action
    counter("oban_powertools.operator_action.previewed.count",
      tags: [:action, :source],
      description: "Operator previewed a cron action"
    ),
    counter("oban_powertools.operator_action.complete.count",
      tags: [:action, :source],
      description: "Operator action completed"
    ),

    # limiter
    counter("oban_powertools.limiter.blocked.count",
      tags: [:blocker_code, :resource, :scope],
      description: "Job enqueue blocked by limiter"
    ),
    counter("oban_powertools.limiter.released.count",
      tags: [:resource, :scope],
      description: "Limiter reservation released"
    ),
    counter("oban_powertools.limiter.cooled_down.count",
      tags: [:resource, :scope],
      description: "Limiter bucket cooled down"
    ),

    # cron
    counter("oban_powertools.cron.paused.count",
      tags: [:source, :overlap_policy],
      description: "Cron entry paused by operator"
    ),
    counter("oban_powertools.cron.resumed.count",
      tags: [:source, :overlap_policy],
      description: "Cron entry resumed by operator"
    ),
    counter("oban_powertools.cron.run_now.count",
      tags: [:source, :overlap_policy],
      description: "Cron entry triggered run-now by operator"
    ),
    counter("oban_powertools.cron.slot_claimed.count",
      tags: [:source, :overlap_policy, :catch_up_policy],
      description: "Cron slot claimed"
    ),

    # workflow (per-suffix, per-contract nested tags)
    counter("oban_powertools.workflow.step_completed.count",
      tags: [:outcome, :terminal_cause, :semantics_version],
      description: "Workflow step completed"
    ),
    counter("oban_powertools.workflow.step_unblocked.count",
      tags: [:scope, :state, :semantics_version],
      description: "Workflow step unblocked"
    ),
    counter("oban_powertools.workflow.cascade_cancelled.count",
      tags: [:scope, :outcome, :terminal_cause, :semantics_version],
      description: "Workflow cascade cancelled"
    ),
    counter("oban_powertools.workflow.workflow_terminal.count",
      tags: [:state, :outcome, :terminal_cause, :semantics_version],
      description: "Workflow reached terminal state"
    ),

    # lifeline
    counter("oban_powertools.lifeline.heartbeat_refresh.count",
      tags: [],
      description: "Lifeline heartbeat refresh cycle completed"
    ),
    counter("oban_powertools.lifeline.incident_projection.count",
      tags: [],
      description: "Lifeline incident projection cycle completed"
    ),
    counter("oban_powertools.lifeline.repair_previewed.count",
      tags: [:action, :incident_class, :target_type],
      description: "Lifeline repair previewed"
    ),
    counter("oban_powertools.lifeline.repair_executed.count",
      tags: [:action, :incident_class, :target_type],
      description: "Lifeline repair executed"
    ),
    counter("oban_powertools.lifeline.archive_prune_completed.count",
      tags: [:outcome],
      description: "Lifeline archive prune cycle completed"
    ),
    # Optional quantity aggregation metrics — planner/executor to decide inclusion
    # sum for archived_count requires measurement function into metadata
    # sum("oban_powertools.lifeline.archive_prune_completed.archived_records",
    #   event_name: [:oban_powertools, :lifeline, :archive_prune_completed],
    #   measurement: fn _measurements, metadata -> Map.get(metadata, :archived_count, 0) end,
    #   tags: [:outcome],
    #   description: "Records archived by lifeline prune run"
    # ),
  ]
end
```

### mix.exs Changes

```elixir
# In deps/0 — add after {:oban_web, "~> 2.10", optional: true}:
{:telemetry_metrics, "~> 1.0", optional: true},
{:telemetry_poller, "~> 1.0", optional: true},

# In groups_for_extras — add to Operations list:
Operations: [
  "guides/optional-oban-web-bridge.md",
  "guides/telemetry-and-slos.md",          # <-- new
  "guides/support-truth-and-ownership-boundaries.md",
  "guides/production-hardening.md",
  "guides/troubleshooting.md",
  "guides/upgrade-and-compatibility.md",
  "guides/forensics-and-runbook-handoffs.md"
]
```

### Test Pattern for metrics/0

```elixir
# Extends test/oban_powertools/telemetry_test.exs
# Requires telemetry_metrics in test deps (or conditional test)

@tag :requires_telemetry_metrics
test "metrics/0 returns valid Telemetry.Metrics definitions" do
  metrics = ObanPowertools.Telemetry.metrics()
  assert is_list(metrics)
  assert length(metrics) > 0
  assert Enum.all?(metrics, &is_struct(&1, Telemetry.Metrics.Counter))
  # or more generally:
  # assert Enum.all?(metrics, fn m -> m.__struct__ in [
  #   Telemetry.Metrics.Counter, Telemetry.Metrics.Sum
  # ] end)
end

test "metrics/0 tags stay within frozen contract" do
  contract = ObanPowertools.Telemetry.contract()
  metrics = ObanPowertools.Telemetry.metrics()

  for metric <- metrics do
    [_oban_powertools, family, suffix | _] = metric.event_name
    allowed_tags =
      case get_in(contract, [:families, family]) do
        %{} = per_suffix_map -> Map.get(per_suffix_map, suffix, [])
        tag_list when is_list(tag_list) -> tag_list
      end

    for tag <- metric.tags do
      assert tag in allowed_tags,
             "Tag #{inspect(tag)} for #{inspect(metric.event_name)} not in contract"
    end
  end
end
```

---

## Parapet Integration Framing (for guide authoring)

Confirmed from `prompts/oban-powertools-deep-research-original-prompt.md` §"parapet overview":

**Parapet's "Universal Phoenix Metrics" already instruments:**
- Oban job failure rates and throughput (from `[:oban, :job, :stop|:exception]`)
- HTTP latency/error rates, Ecto queue vs query saturation

**Parapet's tenets that the frozen Powertools contract already satisfies:**
- "Telemetry as a Strict Public API" — the `@contract` is versioned, documented, and SemVer-governed
- "Cardinality Safety" — the contract explicitly excludes `job_id`, `args`, `preview_token`, `reason`

**The seam the guide must articulate:**
- Golden signals for Oban-backed work: **latency** and **throughput** from `[:oban, :job, :stop]` (`duration`, `queue_time`); **errors** from `[:oban, :job, :exception]` — these are Oban-core, not Powertools
- **Saturation** (live queue depth) — v1.9 (QRY-06), not this phase
- **Control-plane SLIs** from `ObanPowertools.Telemetry.metrics/0` — what Parapet can't see without Powertools: limiter blocks by `blocker_code`/`resource`/`scope`, lifeline repair outcomes by `incident_class`/`outcome`, workflow terminal causes, cron schedule events

**`Parapet.SLO.define` framing (for guide section 4):**
The guide should show that Powertools telemetry drops cleanly into Parapet SLO alerting because (a) the event names are stable, documented public API, (b) the tag sets are low-cardinality. Example: a burn-rate SLO on `oban_powertools.lifeline.repair_executed.count` by `outcome` to track repair success rate. Parapet is framed as "one consumer" — the guide is reporter-agnostic and works equally with Prometheus + Grafana without Parapet.

**No `oban_met` dependency:** The guide must have an explicit callout that `oban_met` is not required, not mentioned as a dependency, and not needed for the metrics surface described.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `telemetry_metrics ~> 0.6` | `~> 1.0` | March 2024 (v1.0.0) | Breaking changes in metric struct internals; `~> 1.0` is the right constraint for new integrations |
| `telemetry_metrics ~> 0.4` (Phoenix 1.6 era) | `~> 1.0` | 2024 | Phoenix 1.7+ now generates `~> 1.0` |

**Deprecated/outdated:**
- `telemetry_metrics 0.6.x`: Still works for existing integrations but new libraries should use `~> 1.0`. The API surface for `counter/2`, `sum/2`, etc. is stable across versions, but struct internals changed.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Tag subset selection per event (e.g. omitting `:action` for `:released`/`:cooled_down` where it redundantly mirrors event name) | Concrete Metric List | Tags may differ — low impact, easily corrected during implementation |
| A2 | `sum/2` for `archived_count`/`pruned_count` requires `measurement: fn` function form because values are in metadata map not measurements map | Common Pitfalls / Code Examples | If wrong, the simpler `measurement: :archived_count` form may work — implementation to verify |
| A3 | `semantics_version` (integer) is acceptably low-cardinality as a tag | Concrete Metric List | If the integer grows unboundedly, cardinality risk; but it's a semantics version not a job ID — current values are 1 and 2 |

---

## Open Questions (RESOLVED during planning — Phase 50)

> All three resolved by the plan decisions; annotations added for audit trail.

1. **Should `sum/2` variants for `archived_count`/`pruned_count` be included?**
   - **RESOLVED:** No — 50-02 ships `counter/2`-only for v1.0; `sum/2` quantity metrics omitted (those keys are metadata, not measurements, and would be a cardinality/complexity risk). Within Claude's Discretion per D-02.
   - What we know: D-02 mentions them; the values are in metadata not measurements map; requires function form
   - What's unclear: Whether the complexity is worth it for v1.0 of this feature
   - Recommendation: Include the `counter/2` for event occurrence; defer the `sum/2` quantity metrics or include as commented-out examples in code. The planner should decide.

2. **Should `:heartbeat_refresh` and `:incident_projection` be included in `metrics/0`?**
   - **RESOLVED:** Yes — both included in 50-02 as `counter/2` with no tags (useful health-monitoring signal that the cycle is running).

3. **`@tag :requires_telemetry_metrics` test gating:**
   - **RESOLVED:** No skip-tag needed — 50-01 adds `{:telemetry_metrics, "~> 1.0", only: [:test, :dev], optional: true}` so `Telemetry.Metrics` is loadable under `mix test`; `optional: true` retains the no-runtime-dep contract.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` / Elixir | All tasks | ✓ | 1.19 (from mix.exs) | — |
| `telemetry_metrics` | `metrics/0` function, tests | ✗ (not in deps yet) | — | Dep to be added this phase |
| `telemetry_poller` | Guide examples | ✗ (not in deps yet) | — | Dep to be added this phase; not needed for code |
| ExDoc | Guide rendering | ✓ (dev dep) | `~> 0.40` | — |

**Missing dependencies with no fallback:** none — both missing deps are the deliverable of this phase.

---

## Validation Architecture

> `nyquist_validation` is absent from `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `test/test_helper.exs` (exists) |
| Quick run command | `mix test test/oban_powertools/telemetry_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEL-01 | `metrics/0` returns non-empty list of `Telemetry.Metrics` structs | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ Wave 0 (extend existing file) |
| TEL-01 | All metric event names are within frozen `@contract` event families | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ Wave 0 |
| TEL-01 | All metric tags are within contract's per-family allowed metadata keys | unit | `mix test test/oban_powertools/telemetry_test.exs` | ❌ Wave 0 |
| TEL-02 | `metrics/0` raises a clear error when `telemetry_metrics` is absent | unit | manual or conditional compile-guard test | ❌ Wave 0 (may be manual-only) |
| TEL-02 | Optional dep declaration compiles without `telemetry_metrics` in the release tree | smoke | `MIX_ENV=prod mix compile` | ❌ Wave 0 |
| TEL-03 | Guide exists at `guides/telemetry-and-slos.md` | smoke | `test -f guides/telemetry-and-slos.md` | ❌ Wave 0 |
| TEL-03 | Guide code samples are valid Elixir (syntax) | smoke | `mix docs` compiles without error | ❌ Wave 0 |
| SC-4 | No metric tag value is `job_id`, `args`, or other excluded field | unit | tag contract test (same as TEL-01 tag test) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/telemetry_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/oban_powertools/telemetry_test.exs` — extend existing file with `metrics/0` structural tests (TEL-01, SC-4)
- [ ] `{:telemetry_metrics, "~> 1.0", only: [:test, :dev], optional: true}` — add to `mix.exs` deps so tests can call `Telemetry.Metrics.*` + run `mix deps.get`
- [ ] `guides/telemetry-and-slos.md` — Wave 0 stub not needed; this is a Wave 1 deliverable

*(No new test infrastructure needed — ExUnit is already configured)*

---

## Security Domain

> `security_enforcement` is not set to `false` — section required.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | `metrics/0` is a public library function; access is controlled by the host's Telemetry supervisor (not Powertools) |
| V5 Input Validation | no | No user input; metric definitions are compile-time constants |
| V6 Cryptography | no | — |

### Known Threat Patterns for Telemetry Metrics

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| High-cardinality tag injection | Tampering / DoS | Contract enforcement — `metrics/0` only declares contract-defined tags; no dynamic tag generation |
| Metric exfiltration via tags | Information Disclosure | Contract excludes `job_id`, `args`, `reason` — these never appear in tag lists |
| Reporter as side-channel | Information Disclosure | Reporter is host-owned; Powertools returns definitions only, no data |

**Note:** The primary security property of this phase is cardinality safety — the contract is the enforcement mechanism. The test that verifies tags stay within the contract (TEL-01 tag test) is also the security test.

---

## Sources

### Primary (HIGH confidence)
- `lib/oban_powertools/telemetry.ex` — `@contract`, all 5 `execute_*_event/3` definitions [VERIFIED: codebase]
- `lib/oban_powertools/application.ex:25` — `Code.ensure_loaded?` pattern [VERIFIED: codebase]
- `mix.exs:54` — optional dep syntax pattern [VERIFIED: codebase]
- `mix.exs:65-92` — ExDoc extras + groups_for_extras [VERIFIED: codebase]
- hexdocs.pm/telemetry_metrics/1.1.0 — `counter/2`, `sum/2`, metric name parsing, ConsoleReporter [VERIFIED: official docs]
- hex.pm/api/packages/telemetry_metrics — v1.1.0, 45.7M downloads, beam-telemetry org [VERIFIED: hex.pm]
- hex.pm/api/packages/telemetry_poller — v1.3.0, 44.2M downloads, beam-telemetry org [VERIFIED: hex.pm]

### Secondary (MEDIUM confidence)
- `prompts/oban-powertools-deep-research-original-prompt.md` §"parapet overview" — Parapet tenets, Universal Phoenix Metrics, SLO DSL framing [VERIFIED: codebase read]
- All `execute_*_event` call sites across `lib/` — actual event suffixes and metadata shapes emitted in production code [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — hex.pm verified, official docs consulted
- Architecture: HIGH — pattern mirrors existing codebase (`Code.ensure_loaded?`, `optional: true`, ExDoc groups)
- Concrete metric list: HIGH (event names/families) / ASSUMED (tag subset selection per event)
- Pitfalls: HIGH for compile-time pitfall; ASSUMED for metadata-vs-measurements pitfall (needs implementation verification)
- Parapet framing: HIGH — read directly from canonical reference doc

**Research date:** 2026-05-29
**Valid until:** 2026-06-29 (30 days — stable library with slow-moving API)
