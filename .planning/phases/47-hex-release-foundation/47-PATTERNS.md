# Phase 47: Hex Release Foundation - Pattern Map

**Mapped:** 2026-05-29
**Files analyzed:** 7 (2 new, 4 greenfield, 1 edit)
**Analogs found:** 3 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/release-please.yml` | config (CI workflow) | event-driven | `.github/workflows/host-contract-proof.yml` | role-match |
| `mix.exs` (edit) | config (build manifest) | transform | `mix.exs` itself (current state) | exact (self-analog) |
| `README.md` (edit, line 25) | docs | — | `README.md` itself (current state) | exact (self-analog) |
| `LICENSE` | docs (legal) | — | none | greenfield |
| `release-please-config.json` | config (release automation) | — | none | greenfield |
| `.release-please-manifest.json` | config (release automation) | — | none | greenfield |
| `CHANGELOG.md` | docs | — | none | greenfield |

---

## Pattern Assignments

### `.github/workflows/release-please.yml` (config, event-driven)

**Analog:** `.github/workflows/host-contract-proof.yml`

**Trigger pattern** (analog lines 1–6) — the new workflow uses `push: branches: [main]` only (no `pull_request`); the existing workflow shows both. Mirror the indentation and `on:` structure, drop `pull_request`:

```yaml
on:
  push:
    branches: ["main"]
```

**Elixir setup step pattern** (analog lines 27–32, repeated across every job) — copy the exact action versions and version pins:

```yaml
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
```

These are the canonical versions already proven in CI. The publish job MUST use these same pins for consistency.

**Secret usage pattern** (analog lines 269, 327) — the existing workflow references `${{ secrets.HEX_API_KEY }}` nowhere (it has no publish step), but shows how GitHub expressions are used inline in `run:` steps and `env:` blocks. The new workflow's publish step follows this same expression style:

```yaml
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

**Multi-job dependency pattern** (analog lines 524–531) — the existing workflow uses `needs:` to sequence jobs and `if: always()` for rollup jobs. The new workflow uses the same `needs:` pattern for the `publish-hex` job that depends on `release-please`:

```yaml
  publish-hex:
    runs-on: ubuntu-latest
    if: ${{ needs.release-please.outputs.release_created }}
    needs: release-please
```

**Full target shape for the new workflow** (from RESEARCH.md Pattern 3 + analog structure):

```yaml
name: Release Please

on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

  publish-hex:
    runs-on: ubuntu-latest
    if: ${{ needs.release-please.outputs.release_created }}
    needs: release-please
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
      - name: Verify clean working tree (Pitfall 17 gate)
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            echo "ERROR: Working tree is dirty. Aborting publish."
            git status --porcelain
            exit 1
          fi
      - name: Install dependencies
        run: mix deps.get
      - name: Publish to Hex
        run: mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

**Key differences from the analog:**
- No `services:` block (no database needed for publishing)
- No `env: OBAN_POWERTOOLS_SKIP_DB_BOOT` (not running tests)
- Requires `permissions: contents: write, pull-requests: write` at the top level (absent in analog — add it)
- The `release-please` job has no `actions/checkout` step; release-please-action handles its own git operations

---

### `mix.exs` (edit — self-analog)

**Analog:** `mix.exs` itself (current state at `/Users/jon/projects/oban_powertools/mix.exs`)

**Current `project/0` shape** (lines 4–14) — the starting point for the edit:

```elixir
def project do
  [
    app: :oban_powertools,
    version: "0.1.0",
    elixir: "~> 1.19",
    start_permanent: Mix.env() == :prod,
    elixirc_paths: elixirc_paths(Mix.env()),
    deps: deps(),
    docs: docs()
  ]
end
```

**Changes required:**
- Add `@version "0.5.0"` and `@source_url "https://github.com/szTheory/oban_powertools"` module attributes above `def project`
- Replace `version: "0.1.0"` with `version: @version`
- Add `package: package()` to the keyword list

**Current `deps/0` shape** (lines 29–39) — shows existing scoping pattern:

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
    {:lazy_html, ">= 0.1.0", only: :test}
  ]
end
```

**Change required:** `igniter` line — add `only: [:dev, :test], runtime: false`:

```elixir
{:igniter, "~> 0.8.0", only: [:dev, :test], runtime: false},
```

Scoping model to copy: `ex_doc` uses `only: :dev, runtime: false`; `lazy_html` uses `only: :test`. Igniter needs both dev and test because the installer task runs in dev and tests exercise it in test env.

**Current `docs/0` shape** (lines 42–68) — the starting point for the edit:

```elixir
defp docs do
  [
    main: "readme",
    extras: ["README.md" | Path.wildcard("guides/*.md")],
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
      ]
    ]
  ]
end
```

**Changes required:**
- Add `source_url: @source_url` key
- Add `source_ref: "v#{@version}"` key
- Add `source_url_pattern: "#{@source_url}/blob/v#{@version}/%{path}#L%{line}"` key
- Change `extras:` from `["README.md" | Path.wildcard("guides/*.md")]` to `["README.md", "CHANGELOG.md" | Path.wildcard("guides/*.md")]`
- Add `"guides/forensics-and-runbook-handoffs.md"` to the `"Operations"` group (fixes orphan-extra; the guide already exists in `guides/` but is not listed in any group)

**New `package/0` function — no current analog in this file** (must be added from scratch):

```elixir
defp package do
  [
    licenses: ["Apache-2.0"],
    links: %{"GitHub" => @source_url},
    files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
  ]
end
```

Note: `priv` is intentionally absent from `:files` — the library has no `priv/` directory at root; migrations are generated inline by Igniter to the host app (RESEARCH.md Pattern 4 verification).

---

### `README.md` (edit — self-analog)

**Analog:** `README.md` itself, line 25

**Current install snippet** (lines 22–29):

```elixir
def deps do
  [
    {:oban_powertools, "~> 0.1.0"},
    {:oban_web, "~> 2.10", optional: true}
  ]
end
```

**Change required:** Replace `"~> 0.1.0"` with `"~> 0.5"`. Use the minor-only pessimistic constraint (`~> 0.5`) rather than patch-level (`~> 0.5.0`) to allow minor bumps within the `0.x` range — standard Elixir library convention for pre-1.0 packages.

A `0.x` stability banner should also be added near the top of README.md (Claude's discretion per CONTEXT.md). Suggested placement: directly under the opening paragraph, before the `## 60-Second Install` heading. Wording is at Claude's discretion per CONTEXT.md.

---

## Shared Patterns

### GitHub Actions Elixir/OTP version pins
**Source:** `.github/workflows/host-contract-proof.yml` (every job's setup-beam step)
**Apply to:** `.github/workflows/release-please.yml` `publish-hex` job
```yaml
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"
```

### GitHub Actions checkout
**Source:** `.github/workflows/host-contract-proof.yml` line 27
**Apply to:** `.github/workflows/release-please.yml` `publish-hex` job
```yaml
      - uses: actions/checkout@v4
```

### mix.exs dep scoping model
**Source:** `mix.exs` lines 30, 38
**Apply to:** `igniter` dep entry
```elixir
# dev-only build tool (no runtime, no prod):
{:ex_doc, "~> 0.40", only: :dev, runtime: false}

# test-only (no runtime):
{:lazy_html, ">= 0.1.0", only: :test}

# Target pattern for igniter (dev + test, no runtime):
{:igniter, "~> 0.8.0", only: [:dev, :test], runtime: false}
```

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason | RESEARCH.md Reference |
|------|------|-----------|--------|----------------------|
| `LICENSE` | docs (legal) | — | No license file exists in the repo yet | D-06/D-07: Apache-2.0 verbatim text; SPDX identifier `Apache-2.0` |
| `release-please-config.json` | config (release automation) | — | No release automation config exists in repo | RESEARCH.md Pattern 1 + Code Examples §`release-please-config.json` |
| `.release-please-manifest.json` | config (release automation) | — | No release automation config exists in repo | RESEARCH.md Code Examples §`.release-please-manifest.json`; seed at `"0.0.0"` not `"0.1.0"` |
| `CHANGELOG.md` | docs | — | No changelog exists in repo; first public release | RESEARCH.md Pattern 5 + Code Examples §CHANGELOG structure; Keep-a-Changelog format, D-10/D-11/D-12/D-13 |

**Critical notes for greenfield files:**

- `.release-please-manifest.json`: Seed value MUST be `{"." : "0.0.0"}`, not `{"." : "0.1.0"}`. Seeding at the current mix.exs version causes release-please to propose 0.1.1 or 0.2.0 instead of 0.5.0.
- `release-please-config.json`: The `bootstrap-sha` field must be set to the output of `git log --reverse --format="%H" | head -1` (the repo's first commit SHA). The deprecated `release-as` config key must NOT be used; use a commit footer `Release-As: 0.5.0` instead.
- `CHANGELOG.md`: Must NOT backfill internal v1.x milestone history as prior entries (D-13). The `changelog:` key in `docs/0` does not exist in ex_doc — include CHANGELOG.md in the `extras` list instead (RESEARCH.md Pitfall 5).
- `LICENSE`: Apache-2.0 full verbatim text. The `licenses: ["Apache-2.0"]` SPDX identifier in `package/0` must match this file.

---

## Metadata

**Analog search scope:** `.github/workflows/`, `mix.exs`, `README.md`
**Files scanned:** 3 source analogs read in full
**Guides confirmed:** 14 files in `guides/` (all exist, `forensics-and-runbook-handoffs.md` is the orphan-extra)
**Pattern extraction date:** 2026-05-29
