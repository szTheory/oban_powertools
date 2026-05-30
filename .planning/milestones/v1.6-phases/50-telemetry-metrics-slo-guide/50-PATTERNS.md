# Phase 50: Telemetry Metrics & SLO Guide - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 4 (2 modify, 1 create, 1 modify-test)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/oban_powertools/telemetry.ex` | utility/module | transform (contract → metric definitions) | `lib/oban_powertools/application.ex` (guard pattern); self (existing `contract/0`) | exact for guard; exact for data model |
| `mix.exs` | config | — | `mix.exs:54` (`oban_web` optional dep) + `mix.exs:79-86` (Operations group) | exact |
| `guides/telemetry-and-slos.md` | docs | — | `guides/optional-oban-web-bridge.md` (opt-in framing); `guides/production-hardening.md` (ops checklist tone) | role-match |
| `test/oban_powertools/telemetry_test.exs` | test | — | existing tests in this same file (contract shape assertion, bounded-metadata pattern) | exact |

---

## Pattern Assignments

### `lib/oban_powertools/telemetry.ex` — add `metrics/0`

**Analog:** `lib/oban_powertools/application.ex` lines 24-29 (the `Code.ensure_loaded?` guard shape) and `lib/oban_powertools/telemetry.ex` lines 32-51 (the `@contract` and `contract/0` that `metrics/0` derives from).

**Critical compile-time constraint (Pitfall 3 in RESEARCH.md):** ALL `Telemetry.Metrics.*` calls must live inside the function body, never at module-attribute level. A `@metrics` module attribute that calls `Telemetry.Metrics.counter(...)` will crash at compile time when the dep is absent.

**Guard pattern** (copy from `application.ex` lines 24-29):
```elixir
defp maybe_add_pubsub(children) do
  if Code.ensure_loaded?(Phoenix.PubSub) do
    children ++ [{Phoenix.PubSub, name: ObanPowertools.PubSub}]
  else
    children
  end
end
```

Apply as `unless` form for `metrics/0` — raise, do not return silent fallback:
```elixir
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
    # metric definitions here — all Telemetry.Metrics.* calls inside this function body
  ]
end
```

**`auth.ex` precedent** for `Code.ensure_loaded` (non-boolean form) — lines 42-44:
```elixir
module = auth_module!()
Code.ensure_loaded(module)

cond do
  function_exported?(module, :authorize, 3) -> ...
```
The `metrics/0` case uses the simpler boolean `Code.ensure_loaded?/1` (with `?`), matching `application.ex` — not the `Code.ensure_loaded/1` + `function_exported?` chain in `auth.ex` (which is for dynamic dispatch, not dep-presence detection).

**Source of truth for metric list** — `@contract` at `telemetry.ex` lines 32-46:
```elixir
@contract %{
  measurement_keys: [:count],
  families: %{
    operator_action: [:action, :source],
    limiter: [:action, :blocker_code, :resource, :scope],
    cron: [:action, :source, :overlap_policy, :catch_up_policy],
    workflow: %{
      step_completed: [:outcome, :terminal_cause, :semantics_version],
      step_unblocked: [:scope, :state, :semantics_version],
      cascade_cancelled: [:scope, :outcome, :terminal_cause, :semantics_version],
      workflow_terminal: [:state, :outcome, :terminal_cause, :semantics_version]
    },
    lifeline: [:action, :incident_class, :target_type, :outcome, :archived_count, :pruned_count]
  }
}
```
The `:tags` list for each metric MUST be a subset of the corresponding family's list above (or per-suffix list for `:workflow`). `:archived_count` and `:pruned_count` are in the lifeline contract as metadata keys — they must NOT appear as metric `:tags` (they would expose variable counts as tag values, breaking cardinality safety).

**Complete `metrics/0` implementation to copy** (derived from RESEARCH.md §Code Examples, cross-checked against `@contract` and actual emitter call sites):
```elixir
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
    # operator_action — action varies across events (pause/resume/run), so :action is useful
    counter("oban_powertools.operator_action.previewed.count",
      tags: [:action, :source],
      description: "Operator previewed a cron action"
    ),
    counter("oban_powertools.operator_action.complete.count",
      tags: [:action, :source],
      description: "Operator action completed (pause_cron_entry, resume_cron_entry, run_cron_entry)"
    ),

    # limiter — :action omitted where it is constant and mirrors event name
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

    # cron — :catch_up_policy only emitted by :slot_claimed
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

    # workflow — per-suffix tags drawn from nested @contract entries
    counter("oban_powertools.workflow.step_completed.count",
      tags: [:outcome, :terminal_cause, :semantics_version],
      description: "Workflow step completed"
    ),
    counter("oban_powertools.workflow.step_unblocked.count",
      tags: [:scope, :state, :semantics_version],
      description: "Workflow step unblocked by dependency"
    ),
    counter("oban_powertools.workflow.cascade_cancelled.count",
      tags: [:scope, :outcome, :terminal_cause, :semantics_version],
      description: "Workflow cascade cancelled"
    ),
    counter("oban_powertools.workflow.workflow_terminal.count",
      tags: [:state, :outcome, :terminal_cause, :semantics_version],
      description: "Workflow reached terminal state"
    ),

    # lifeline — heartbeat/incident have no meaningful tags beyond event name
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
    )
  ]
end
```

**Note on `sum/2` for `archived_count`/`pruned_count`:** These values are in the metadata map (third arg to `:telemetry.execute/3`), not the measurements map (second arg). Using `sum/2` with a simple `measurement: :archived_count` atom will get `nil` from the measurements map and always report 0. The correct form requires `measurement: fn _measurements, metadata -> Map.get(metadata, :archived_count, 0) end`. Given this complexity and the v1.0 scope, the recommendation is to omit these `sum/2` variants and ship `counter/2`-only for event occurrence. Include as a commented-out block if desired for forward-reference.

---

### `mix.exs` — two optional deps + one `groups_for_extras` entry

**Analog:** `mix.exs` line 54 for the dep tuple shape:
```elixir
{:oban_web, "~> 2.10", optional: true},
```

**Exact pattern to replicate** — add after line 54 (`oban_web`):
```elixir
{:oban_web, "~> 2.10", optional: true},
{:telemetry_metrics, "~> 1.0", optional: true},
{:telemetry_poller, "~> 1.0", optional: true},
```

**For test/dev access to `Telemetry.Metrics.*` in tests**, the dep should also include `only: [:test, :dev]` alongside `optional: true`. The research recommends:
```elixir
{:telemetry_metrics, "~> 1.0", only: [:test, :dev], optional: true},
```
This lets the test suite call `ObanPowertools.Telemetry.metrics()` without making `telemetry_metrics` a required runtime dep. Note: `telemetry_poller` is guide-documentation only; no test or lib code calls it, so it needs no `only:` restriction.

**`groups_for_extras` analog** — `mix.exs` lines 79-86:
```elixir
Operations: [
  "guides/optional-oban-web-bridge.md",
  "guides/support-truth-and-ownership-boundaries.md",
  "guides/production-hardening.md",
  "guides/troubleshooting.md",
  "guides/upgrade-and-compatibility.md",
  "guides/forensics-and-runbook-handoffs.md"
]
```

**Exact insertion** — add `"guides/telemetry-and-slos.md"` as the second entry in the Operations list (after `optional-oban-web-bridge.md`, which is the closest thematic neighbor):
```elixir
Operations: [
  "guides/optional-oban-web-bridge.md",
  "guides/telemetry-and-slos.md",
  "guides/support-truth-and-ownership-boundaries.md",
  "guides/production-hardening.md",
  "guides/troubleshooting.md",
  "guides/upgrade-and-compatibility.md",
  "guides/forensics-and-runbook-handoffs.md"
]
```

**Warning (Pitfall 2 in RESEARCH.md):** The guide is auto-globbed via `Path.wildcard("guides/*.md")` at line 65, so it will appear in `extras` automatically. But without the explicit `groups_for_extras` entry above it will land ungrouped in the ExDoc sidebar. The entry above is mandatory.

---

### `guides/telemetry-and-slos.md` — new Operations guide

**Analog tone:** `guides/optional-oban-web-bridge.md` (opt-in framing, short declarative sections with "what it is / what it is not" clarity) and `guides/production-hardening.md` (direct imperative prose, checklist-friendly, no fluff).

**Structural pattern from `optional-oban-web-bridge.md`** (lines 1-32):
- Lead paragraph: state what is opt-in and why
- Flat H2 sections with tight bullet lists
- Explicit "what it is not" section to set scope boundaries
- "Host caveats that matter" section for gotchas

**Structural pattern from `production-hardening.md`** (lines 1-36):
- Imperative checklist (verb-first bullets)
- Dedicated subsection per concern (Telemetry, Policy seams)
- No introductory preamble — jumps straight to content

**Required 4-part guide structure** (from D-07):
1. **Wire it up** — add `:telemetry_metrics` (+`:telemetry_poller`) to host deps, mount `ObanPowertools.Telemetry.metrics()` in the host's `Telemetry` supervisor with a reporter. Use `Telemetry.Metrics.ConsoleReporter` as the safe, zero-extra-dep example reporter.
2. **The four golden signals for Oban-backed work** — latency/throughput from `[:oban, :job, :stop]` (`duration`, `queue_time`), errors from `[:oban, :job, :exception]`, saturation noted as host/Oban-sourced (live counts → v1.9). These are Oban-core, NOT Powertools — the guide must say so explicitly.
3. **Powertools control-plane SLIs** — what `metrics/0` adds: limiter blocks by `blocker_code`/`resource`/`scope`, lifeline repair outcomes by `incident_class`/`outcome`, workflow terminal causes, cron schedule events.
4. **Feeding Parapet SLOs** — explain why Powertools telemetry drops cleanly into Parapet (stable public API, low-cardinality contract satisfies Parapet's "Telemetry as a Strict Public API" + "Cardinality Safety" tenets). Show a burn-rate SLO framing example (e.g. on `oban_powertools.lifeline.repair_executed.count` by `outcome`). Parapet framed as "one consumer", not a coupling. Explicit "no `oban_met` dependency" callout.

**Host wiring code sample to include in section 1** (from RESEARCH.md Pattern 4):
```elixir
defmodule MyApp.Telemetry do
  use Supervisor

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
       measurements: [],
       period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

**Explicit "not bundled" framing** (mirror `optional-oban-web-bridge.md` "what it is not" pattern):
- `metrics/0` returns metric definitions, not a reporter or a process
- Powertools does not start a Telemetry supervisor
- Reporter choice is the host's (`telemetry_metrics_prometheus`, StatsD, Datadog exporter, etc.)
- `oban_met` is not required and not referenced by this feature

---

### `test/oban_powertools/telemetry_test.exs` — extend with `metrics/0` tests

**Analog:** existing tests in the same file.

**File header pattern** (lines 1-2) — reuse as-is; no new module or `use` change needed:
```elixir
defmodule ObanPowertools.TelemetryTest do
  use ExUnit.Case, async: false
```

**Contract assertion pattern** (lines 20-22) — the existing contract test is the model for the structural test:
```elixir
test "publishes the telemetry public contract" do
  assert ObanPowertools.Telemetry.contract() == @expected_contract
end
```

**Bounded-metadata assertion pattern** (lines 86-88 and 115-117) — used in workflow and cron tests; apply the same inversion to verify `metrics/0` tags stay inside the contract:
```elixir
assert Map.keys(metadata) |> Enum.sort() ==
         Enum.sort(@expected_contract.families.workflow.step_completed)
```

**Two tests to add:**

Test 1 — structural: `metrics/0` returns a non-empty list of `Telemetry.Metrics` structs:
```elixir
test "metrics/0 returns a non-empty list of Telemetry.Metrics structs" do
  metrics = ObanPowertools.Telemetry.metrics()
  assert is_list(metrics)
  assert length(metrics) > 0

  valid_types = [Telemetry.Metrics.Counter, Telemetry.Metrics.Sum]
  assert Enum.all?(metrics, fn m -> m.__struct__ in valid_types end)
end
```

Test 2 — tag containment: every tag in every metric is within the contract for that family+suffix:
```elixir
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
             "Tag #{inspect(tag)} for #{inspect(metric.event_name)} not in contract " <>
               "(allowed: #{inspect(allowed_tags)})"
    end
  end
end
```

**Tag-containment test note:** The `metric.tags` field on a `Telemetry.Metrics.Counter` struct is a list of atoms. The `allowed_tags` drawn from `@contract` are also atom lists. The `in` check is a direct atom membership test — no conversion needed.

**Placement:** Add both tests after the existing `test "publishes the telemetry public contract"` block (line 20-22) and before the event-emission tests. They are pure data tests with no telemetry attachment/detachment.

---

## Shared Patterns

### `Code.ensure_loaded?/1` Optional-Dep Guard
**Source:** `lib/oban_powertools/application.ex` lines 24-29
**Apply to:** `metrics/0` in `lib/oban_powertools/telemetry.ex`
```elixir
if Code.ensure_loaded?(Phoenix.PubSub) do
  children ++ [{Phoenix.PubSub, name: ObanPowertools.PubSub}]
else
  children
end
```
For `metrics/0`, the guard uses `unless` + `raise` (not silent fallback) because the function was explicitly called — the user asked for metrics and the dep is missing. The `application.ex` pattern silently skips; `metrics/0` should fail loudly.

### Optional Dep Declaration Tuple
**Source:** `mix.exs` line 54
**Apply to:** two new entries in `mix.exs` `deps/0`
```elixir
{:oban_web, "~> 2.10", optional: true},
```
Exact shape. Add `only: [:test, :dev]` to `telemetry_metrics` so test suite can call `metrics/0`; `telemetry_poller` needs no such restriction (guide-only, no test code calls it).

### ExDoc `groups_for_extras` Group Entry
**Source:** `mix.exs` lines 79-86
**Apply to:** Operations list in `mix.exs`
```elixir
Operations: [
  "guides/optional-oban-web-bridge.md",
  ...
]
```
New guide must be explicitly listed here or it lands ungrouped.

---

## No Analog Found

None. All four files have direct analogs in the codebase.

---

## Metadata

**Analog search scope:** `lib/oban_powertools/`, `test/oban_powertools/`, `guides/`, `mix.exs`
**Files read:** 7 (telemetry.ex, application.ex, auth.ex, mix.exs, telemetry_test.exs, optional-oban-web-bridge.md, production-hardening.md, troubleshooting.md)
**Pattern extraction date:** 2026-05-29
