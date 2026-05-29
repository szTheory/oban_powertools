# Stack Research

**Domain:** Elixir/Phoenix hex library — first public release + operability tooling (v1.6)
**Researched:** 2026-05-28
**Confidence:** HIGH — versions verified against mix.lock, hex.pm, and official hexdocs; patterns verified against existing codebase seams

---

## Scope of this document

This is a v1.6-specific stack document. It covers only what changes, is added, or needs explicit config for the four v1.6 deliverables:

1. First hex.pm publish at `0.5.0` with docs
2. `mix oban_powertools.doctor` health-check task
3. `mix oban_powertools.limiter.explain` / `.simulate` CLI tasks
4. Opt-in `ObanPowertools.Telemetry.metrics/0` over the frozen contract

The existing runtime stack (Oban 2.22.1, Phoenix LiveView 1.1.30, Ecto SQL 3.13.5, Postgrex 0.22.2, Telemetry 1.4.2, Jason 1.4.5, Igniter 0.8.0) is UNCHANGED and does not need re-researching.

---

## Recommended Stack

### Core Technologies (No Change in v1.6)

| Technology | Locked Version | Role |
|------------|---------------|------|
| Oban | 2.22.1 | Core dep; doctor reads `oban_jobs` schema |
| Ecto SQL | 3.13.5 | All DB access including `pg_catalog` queries |
| Postgrex | 0.22.2 | Postgres driver; already handles `pg_catalog` tables |
| Telemetry | 1.4.2 | Runtime telemetry; already a hard dep |
| Jason | 1.4.5 | JSON; already a hard dep |
| Phoenix LiveView | 1.1.30 | UI; unchanged |

### Dev/Build Tools

| Tool | Version | Purpose | Why |
|------|---------|---------|-----|
| ex_doc | `~> 0.40` (locked 0.40.3) | Doc generation + hexdocs publishing | Already in mix.exs as `only: :dev, runtime: false`. 0.40.3 is current stable (verified hex.pm 2026-05-21). No change needed to the version constraint — `~> 0.40` already resolves to latest patch. |

### Optional Runtime Dependencies (new gating needed)

| Library | Version | Purpose | Gating |
|---------|---------|---------|--------|
| telemetry_metrics | `~> 1.0` | `Telemetry.Metrics` struct definitions for `metrics/0` | `optional: true` — callers add it only if they use a reporter |
| telemetry_poller | `~> 1.0` | Periodic VM/process measurements (referenced in guide, not required) | NOT added to mix.exs at all — guide tells hosts to add it themselves |

**telemetry_metrics 1.1.0** is the current stable (verified hex.pm, released 2025-01-24). Constraint `~> 1.0` resolves to 1.x.

**telemetry_poller 1.3.0** is current stable (verified hex.pm). Not added as a dep — the Parapet/SLO guide tells adopters to add it themselves if they want VM/queue polling. Zero reason to add it to the library.

---

## What to NOT Add (Anti-Dependencies)

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `oban_met` | Hard dependency on a metrics aggregator would rebuild Oban Web; v1.9 deferred feature; already in lock as transitive via oban_web | Never add as a direct dep; gated optional in v1.9 only |
| Any metrics reporter (`telemetry_metrics_prometheus_ex`, `telemetry_metrics_statsd`, etc.) | Reporters are host-app concerns; adding one forces a choice on all adopters | Guide adopters to add their own reporter and pass `ObanPowertools.Telemetry.metrics/0` |
| `telemetry_poller` as a library dep | The library does not poll; polling is a host-app supervision concern | Mention in the Parapet/SLO guide; let hosts configure it |
| Any new runtime dep | Zero-new-runtime-dep is a hard constraint for v1.6 | Everything builds on existing Ecto/Postgrex/Telemetry |
| `Mix.Ecto` (private API) | Mix.Ecto is internal to the ecto_sql package and may break without notice | Use `Ecto.Migrator.with_repo/2` (public, documented) for repo boot in mix tasks |
| `Application.ensure_all_started` + manual `Repo.start_link` | Fragile, does not handle pool config from host app | Use `Ecto.Migrator.with_repo/2` or `@requirements ["app.start"]` |

---

## Hex Publishing: mix.exs Config Shape

### What is missing from the current mix.exs

The current `mix.exs` has `docs/0` but is missing the `package/0` function and several project-level fields. Here is the complete shape needed:

```elixir
defmodule ObanPowertools.MixProject do
  use Mix.Project

  @version "0.5.0"
  @source_url "https://github.com/szTheory/oban_powertools"

  def project do
    [
      app: :oban_powertools,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      # Hex metadata
      description: description(),
      package: package(),
      # ExDoc
      name: "Oban Powertools",
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs()
    ]
  end

  defp description do
    "A Phoenix-first, Ecto-native, Postgres-only operations layer for Oban: " <>
      "typed workers, rate limiters, dynamic cron, durable workflows, " <>
      "Lifeline repair, job surface, and SRE-ready telemetry."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      # Explicit file list — include only what adopters need
      files: ~w(
        lib priv .formatter.exs mix.exs
        README.md CHANGELOG.md LICENSE guides
      )
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",         # links source links to the exact tag
      extras: ["README.md" | Path.wildcard("guides/*.md")] ++ ["CHANGELOG.md"],
      groups_for_extras: [
        "Day 0": [
          "guides/installation.md",
          "guides/first-operator-session.md",
          "guides/example-app-walkthrough.md"
        ],
        "Builders": [
          "guides/workers-and-idempotency.md",
          "guides/limits-and-explain.md",
          "guides/workflows.md",
          "guides/lifeline-and-repairs.md",
          "guides/policy-integration-patterns.md"
        ],
        "Operations": [
          "guides/optional-oban-web-bridge.md",
          "guides/support-truth-and-ownership-boundaries.md",
          "guides/production-hardening.md",
          "guides/troubleshooting.md",
          "guides/upgrade-and-compatibility.md"
        ],
        # NEW for v1.6:
        "Operability": [
          "guides/doctor.md",
          "guides/limiter-cli.md",
          "guides/telemetry-and-slo.md"
        ]
      ],
      groups_for_modules: [
        "Workers": [~r/ObanPowertools\.Worker/],
        "Limiters": [~r/ObanPowertools\.Limits/, ~r/ObanPowertools\.Explain/],
        "Cron": [~r/ObanPowertools\.Cron/],
        "Workflows": [~r/ObanPowertools\.Workflow/],
        "Lifeline & Repair": [~r/ObanPowertools\.Lifeline/, ~r/ObanPowertools\.Forensics/],
        "Operator API": [ObanPowertools.Operator],
        "Telemetry": [ObanPowertools.Telemetry],
        "Install & Config": [~r/ObanPowertools\.Install/, ~r/ObanPowertools\.Config/]
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
```

**Key decisions:**

- `version: @version` bumped to `"0.5.0"` — deliberate `0.x` that signals pre-1.0 API, documented path to `1.0` after adopter feedback.
- `source_ref: "v#{@version}"` — links all `[Source]` links in hexdocs to the exact git tag, not `main`. Correct because the published hex release corresponds to a tagged commit.
- `licenses: ["MIT"]` — MIT is the project's stated license (verify LICENSE file exists before publish).
- `files:` explicit list — excludes `test/`, `priv/test_support/`, `.planning/`, `prompts/`, `.github/`, `deps/`. The default (no `files:` key) includes everything not gitignored, which would expose internal planning artifacts.
- `groups_for_modules` — organizes the hexdocs sidebar; uses regex patterns to group by namespace prefix. Prevents the sidebar from listing 40+ modules in flat alpha order.
- `CHANGELOG.md` must exist before `mix hex.publish`. Create it if not present; `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` suppresses warnings for version-header links that ex_doc cannot resolve.

### Version and Changelog Convention

Use Keep a Changelog format (`## [0.5.0] - YYYY-MM-DD`) with a `## [Unreleased]` section at top. No automated tooling needed for v1.6 — maintain it manually. The `source_ref` in docs will point to the `v0.5.0` git tag; ensure the tag is pushed before `mix hex.publish docs`.

### Publishing workflow

```bash
# 1. Tag the release
git tag v0.5.0 && git push origin v0.5.0

# 2. Publish package + docs together (recommended)
mix hex.publish

# The command publishes both the package and docs.
# It will show package metadata, deps, and file list — verify before confirming.

# 3. To publish docs only (if docs were wrong on first publish):
mix hex.publish docs
```

Within one hour of publishing, you can re-publish the same version with `mix hex.publish --revert 0.5.0` then republish. After one hour, the version is immutable on hex.pm.

For CI, set `HEX_API_KEY` env var and use `mix hex.publish --yes`.

---

## Mix Tasks: stdlib-only patterns

All three mix tasks (`doctor`, `limiter.explain`, `limiter.simulate`) follow the same structural pattern. No new dependencies.

### Module naming convention

```
Mix.Tasks.ObanPowertools.Doctor        → mix oban_powertools.doctor
Mix.Tasks.ObanPowertools.Limiter.Explain → mix oban_powertools.limiter.explain
Mix.Tasks.ObanPowertools.Limiter.Simulate → mix oban_powertools.limiter.simulate
```

Files live in `lib/mix/tasks/oban_powertools/`:
```
lib/mix/tasks/oban_powertools/doctor.ex
lib/mix/tasks/oban_powertools/limiter/explain.ex
lib/mix/tasks/oban_powertools/limiter/simulate.ex
```

### Repo boot pattern

Use `@requirements ["app.start"]` so the host application's supervision tree (including the repo) is started before the task runs. Do NOT use `Ecto.Migrator.with_repo/2` for these tasks — it is designed for brief ephemeral repo usage (like migrations) and stops the repo on exit. The doctor task may need multiple queries; `app.start` keeps the app running naturally for the task's duration.

```elixir
defmodule Mix.Tasks.ObanPowertools.Doctor do
  use Mix.Task

  @shortdoc "Run read-only health checks against the Oban Powertools schema"
  @moduledoc """
  Checks index presence and validity, uniqueness-timeout settings,
  config sanity, and migration drift over pg_catalog.

  Returns exit code 0 if all checks pass, 1 if any check fails.
  """

  @requirements ["app.start"]

  @impl Mix.Task
  def run(args) do
    repo = repo_from_config!()
    results = ObanPowertools.Doctor.run_checks(repo, parse_opts(args))
    report(results)
    maybe_exit(results)
  end

  defp repo_from_config! do
    case Application.get_env(:oban_powertools, :repo) do
      nil -> Mix.raise("`:repo` must be set in config :oban_powertools")
      repo -> repo
    end
  end

  defp maybe_exit(results) do
    if Enum.any?(results, &(&1.status == :fail)) do
      System.stop(1)
    end
  end
end
```

**Exit code contract:**
- `System.stop(0)` — all checks pass (implicit on normal task exit)
- `System.stop(1)` — one or more checks failed

Use `System.stop/1` (not `System.halt/1`). `System.stop` initiates graceful OTP shutdown; `System.halt` is a hard kill that skips `Application.stop` callbacks and can leave ecto pools dirty.

**Do not use `Mix.raise/1` for check failures** — `Mix.raise` is for task configuration errors (missing required arg, bad config). A doctor check failure is a runtime result, not a task error; use `System.stop(1)` after printing the failure report.

### pg_catalog query pattern

The doctor task queries Postgres system catalogs read-only via existing Ecto + Postgrex. No new dep required — `pg_catalog` tables are standard SQL and Postgrex/Ecto handle them transparently.

```elixir
# Index presence/validity check (example shape)
Ecto.Adapters.SQL.query!(repo, """
  SELECT indexname, indexdef, indisvalid
  FROM pg_catalog.pg_indexes
  JOIN pg_catalog.pg_index ON pg_index.indexrelid = (
    SELECT oid FROM pg_catalog.pg_class WHERE relname = pg_indexes.indexname
  )
  WHERE tablename = $1
""", ["oban_jobs"])
```

Use `Ecto.Adapters.SQL.query!/3` (not `repo.query!`) for raw SQL — it is the documented public API for arbitrary SQL through an Ecto adapter. Returns `%Postgrex.Result{}` with `rows` and `columns`.

### Argument parsing

Use `OptionParser.parse/2` from stdlib. No third-party arg parser needed:

```elixir
defp parse_opts(args) do
  {opts, _, _} = OptionParser.parse(args, switches: [quiet: :boolean, format: :string])
  opts
end
```

### Output

Use `Mix.shell().info/1` and `Mix.shell().error/1` for output — these respect the `--no-color` flag and are testable via `Mix.shell(Mix.Shell.Process)` in tests. Do not use raw `IO.puts`.

---

## Telemetry Metrics: opt-in `Telemetry.metrics/0`

### Where telemetry_metrics goes in mix.exs

Add as an optional dep — not a runtime dep, not a dev-only dep:

```elixir
defp deps do
  [
    {:ex_doc, "~> 0.40", only: :dev, runtime: false},
    {:igniter, "~> 0.8.0"},
    {:telemetry, "~> 1.4"},
    {:jason, "~> 1.4"},
    {:oban, "~> 2.18"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:oban_web, "~> 2.10", optional: true},
    # NEW for v1.6 — optional; only needed if host wants to use metrics/0
    {:telemetry_metrics, "~> 1.0", optional: true},
    {:lazy_html, ">= 0.1.0", only: :test}
  ]
end
```

`optional: true` means:
- `telemetry_metrics` is listed as a dependency of `oban_powertools` on hex.pm (so adopters know it's used)
- But Mix does NOT require host apps to add it to their own deps
- Host apps that want `ObanPowertools.Telemetry.metrics/0` must add `{:telemetry_metrics, "~> 1.0"}` to their own `mix.exs`
- If they do NOT add it, the `metrics/0` function is simply unavailable at compile time (or raises `UndefinedFunctionError`)

This is the same pattern used for `oban_web` in the current mix.exs.

### Runtime gating pattern

Because `telemetry_metrics` is optional, the `metrics/0` function must guard against the module being absent:

```elixir
defmodule ObanPowertools.Telemetry do
  # ... existing frozen @contract and execute_* functions ...

  @doc """
  Returns a list of `Telemetry.Metrics` definitions covering the frozen
  low-cardinality event contract.

  Add these to your application's telemetry reporter in your supervision tree:

      {Telemetry.Metrics.ConsoleReporter, metrics: ObanPowertools.Telemetry.metrics()}

  Requires `{:telemetry_metrics, "~> 1.0"}` in your application's mix.exs.
  This function is undefined if telemetry_metrics is not installed.
  """
  if Code.ensure_loaded?(Telemetry.Metrics) do
    def metrics do
      import Telemetry.Metrics

      [
        # operator_action family
        counter("oban_powertools.operator_action.complete.count",
          tags: [:action, :source]
        ),
        counter("oban_powertools.operator_action.refused.count",
          tags: [:action, :source]
        ),

        # limiter family
        counter("oban_powertools.limiter.blocked.count",
          tags: [:action, :blocker_code, :resource, :scope]
        ),
        counter("oban_powertools.limiter.reserved.count",
          tags: [:resource, :scope]
        ),
        counter("oban_powertools.limiter.released.count",
          tags: [:resource, :scope]
        ),

        # cron family
        counter("oban_powertools.cron.fired.count",
          tags: [:action, :source, :overlap_policy]
        ),
        counter("oban_powertools.cron.skipped.count",
          tags: [:action, :source, :overlap_policy]
        ),

        # workflow family — each event suffix is a separate event name
        counter("oban_powertools.workflow.step_completed.count",
          tags: [:outcome, :terminal_cause, :semantics_version]
        ),
        counter("oban_powertools.workflow.step_unblocked.count",
          tags: [:scope, :state, :semantics_version]
        ),
        counter("oban_powertools.workflow.cascade_cancelled.count",
          tags: [:scope, :outcome, :terminal_cause, :semantics_version]
        ),
        counter("oban_powertools.workflow.workflow_terminal.count",
          tags: [:state, :outcome, :terminal_cause, :semantics_version]
        ),

        # lifeline family
        counter("oban_powertools.lifeline.complete.count",
          tags: [:action, :incident_class, :target_type, :outcome]
        )
      ]
    end
  end
end
```

**Why `Code.ensure_loaded?` and not `Application.ensure_all_started`:** `Code.ensure_loaded?` runs at compile time in the library, producing a conditional module body. The function simply does not exist if `Telemetry.Metrics` is not loaded. This is the idiomatic Elixir pattern for optional-dep gating — it avoids runtime errors and makes the optionality explicit to adopters (they get an `UndefinedFunctionError` if they call `metrics/0` without the dep, which is a clear message).

**Why `import Telemetry.Metrics` inside the function:** The `counter/2`, `last_value/2`, `sum/2` etc. macros are imported per-call rather than at the module level, so the module compiles even without `telemetry_metrics` present.

**The frozen @contract drives the tags:** The tags in each `counter/2` call exactly mirror the low-cardinality metadata keys from `@contract`. This is NOT coincidental — `metrics/0` is a thin projection of `@contract` into `Telemetry.Metrics` structs. Any change to `@contract` (a semver-major event) requires updating `metrics/0`.

**Metric type choice:** Use `counter/2` for all event families. The `:count` measurement key in `@contract` is already a counter semantic (each event increments by 1). `last_value` or `sum` would misrepresent the cardinality contract. The Parapet/SLO guide can instruct adopters to derive rates from counters in their reporter (e.g., Prometheus `rate(counter[5m])`).

### What the Parapet/SLO guide covers

The guide (new `guides/telemetry-and-slo.md`) explains:
1. The frozen event contract — what events fire, what tags exist, what `:count` means
2. How to add `telemetry_metrics` + a reporter to the host app supervision tree
3. Example `Telemetry.Metrics.ConsoleReporter` for dev
4. Example Prometheus (`telemetry_metrics_prometheus_ex`) and StatsD snippets
5. How to wire `ObanPowertools.Telemetry.metrics/0` alongside Phoenix/Ecto metrics
6. SLO recommendations: limiter saturation rate, lifeline repair rate, operator action rate
7. Reference to Parapet for alert wiring (szTheory ecosystem)

The guide does NOT ship a reporter or a Prometheus scrape endpoint — that is the host app's responsibility.

---

## Limiter CLI Tasks: integration with existing modules

Both tasks are read-only CLI surfaces over already-built modules. No new deps, no new schemas.

### `mix oban_powertools.limiter.explain`

Calls `ObanPowertools.Explain.explain/3` with a worker module and args derived from CLI input:

```
mix oban_powertools.limiter.explain MyApp.Workers.SyncAccount '{"account_id":"abc"}'
```

Accepts: worker module name (string → `Module.safe_concat/1`), JSON args string (→ `Jason.decode!/1`). Prints the explain result using `Mix.shell().info/1`.

The task does NOT call `Explain.persist_snapshot/4` — it is explicitly read-only (no side effects in a diagnostic CLI).

### `mix oban_powertools.limiter.simulate`

Calls `ObanPowertools.Limits` to simulate a token reservation without actually mutating state. Options:
- `--worker MyApp.Workers.SyncAccount` — which worker's limiter config to use
- `--args '{"account_id":"abc"}'` — args for partition key derivation
- `--dry-run` (default: always dry-run for simulate)

The simulate task exercises the reservation logic path without writing to the database. Implementation: call `ObanPowertools.Worker.limit_snapshot/2` to get the snapshot, then call `ObanPowertools.Explain.explain/3` (which is already read-only), and report what WOULD happen. No new abstraction needed.

Ships the rate-limit glossary (what "blocked", "cooldown", "limit_reached", "tokens_used" mean) as `--glossary` output or in `@moduledoc`.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `@requirements ["app.start"]` for mix tasks | `Ecto.Migrator.with_repo/2` | `with_repo` stops the repo after the block; `app.start` keeps the normal app lifecycle, easier to reason about for multi-query health checks |
| `System.stop(1)` for check failures | `Mix.raise/1` | `Mix.raise` signals task configuration errors; a doctor check failure is a runtime result that should report before exiting cleanly |
| `Code.ensure_loaded?` guard for `metrics/0` | Always-defined stub | A stub that returns `[]` silently hides misconfiguration; `UndefinedFunctionError` is clearer |
| `telemetry_metrics ~> 1.0` optional | pin to `~> 1.1` | `~> 1.0` allows 1.1.0 (current) and future 1.x without forcing adopters to upgrade immediately |
| `mix hex.publish` (combined) | `mix hex.publish package` then `mix hex.publish docs` | Single command is simpler and keeps package + docs versions in sync |
| Manual CHANGELOG.md | Release Please / keep-a-changelog automation | No CI/CD pipeline is set up yet; automation adds maintenance burden before v1.0 |

---

## Version Compatibility

| Package | Constraint in mix.exs | Locked | Notes |
|---------|----------------------|--------|-------|
| ex_doc | `~> 0.40` | 0.40.3 | Already in mix.exs; no change needed |
| telemetry_metrics | `~> 1.0` (new, optional) | not yet locked | Resolves to 1.1.0 (current); `~> 1.0` allows 1.x |
| telemetry | `~> 1.4` | 1.4.2 | Already present; telemetry_metrics 1.x requires `~> 1.0 or ~> 0.4` — compatible |

---

## Files to Add/Change for v1.6

| File | Action | Purpose |
|------|--------|---------|
| `mix.exs` | Change `version` to `"0.5.0"`, add `@source_url`, `description/0`, `package/0`, update `docs/0` | Hex publish readiness |
| `CHANGELOG.md` | Create | Required by hex publish convention; ex_doc warns without it |
| `LICENSE` | Verify exists | `licenses: ["MIT"]` in package/0 must match LICENSE file |
| `lib/mix/tasks/oban_powertools/doctor.ex` | Create | `mix oban_powertools.doctor` |
| `lib/mix/tasks/oban_powertools/limiter/explain.ex` | Create | `mix oban_powertools.limiter.explain` |
| `lib/mix/tasks/oban_powertools/limiter/simulate.ex` | Create | `mix oban_powertools.limiter.simulate` |
| `lib/oban_powertools/doctor.ex` | Create | Doctor check logic (pure functions, called by task) |
| `lib/oban_powertools/telemetry.ex` | Add `metrics/0` with `Code.ensure_loaded?` guard | Opt-in `Telemetry.Metrics` definitions |
| `guides/doctor.md` | Create | Operability guide for `mix oban_powertools.doctor` |
| `guides/limiter-cli.md` | Create | Guide for `limiter.explain` / `limiter.simulate` + rate-limit glossary |
| `guides/telemetry-and-slo.md` | Create | Parapet/SLO telemetry guide + `metrics/0` usage |

---

## Sources

- [hex.pm/packages/ex_doc](https://hex.pm/packages/ex_doc) — verified 0.40.3 is current (2026-05-21)
- [hex.pm/packages/telemetry_metrics](https://hex.pm/packages/telemetry_metrics) — verified 1.1.0 is current (2025-01-24)
- [hex.pm/packages/telemetry_poller](https://hex.pm/packages/telemetry_poller) — verified 1.3.0 is current (2025-07-09)
- [hexdocs.pm/ex_doc — ExDoc config options](https://hexdocs.pm/ex_doc/ExDoc.html) — source_ref, groups_for_modules, skip_undefined_reference_warnings_on
- [hex.pm/docs/publish](https://hex.pm/docs/publish) — package/0 fields, files defaults, publishing workflow
- [hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html) — metric types, counter/2, tags pattern
- [hexdocs.pm/phoenix/telemetry.html](https://hexdocs.pm/phoenix/telemetry.html) — Phoenix opt-in metrics/0 pattern (library exposes events; host app passes metrics/0 to reporter)
- [jonathanychan.com — Ecto repo in Mix Task](https://www.jonathanychan.com/blog/how-to-access-an-ecto-repo-within-a-mix-task/) — Ecto.Migrator.with_repo pattern
- [hexdocs.pm/mix/Mix.Task.html](https://hexdocs.pm/mix/Mix.Task.html) — @requirements ["app.start"] vs "app.config", library task pattern
- `mix.lock` (this repo) — locked versions for all existing deps (verified 2026-05-28)
- `lib/oban_powertools/telemetry.ex` — frozen @contract; tags/measurements drive metrics/0 design
- `lib/oban_powertools/explain.ex` — Explain.explain/3 signature (what the limiter CLI wraps)

---

*Stack research for: Oban Powertools v1.6 — Release & Operability*
*Researched: 2026-05-28*
