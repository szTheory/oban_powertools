# Phase 12: Fresh Host Install Path & Example Fixture Repair - Research

**Researched:** 2026-05-22
**Domain:** Phoenix host installation contract, Igniter-backed code generation, canonical fixture provenance, and first-session proof repair. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Shift decision defaults left for this project and within GSD where possible. Downstream agents should prefer decisive recommendations over reopening choices unless a decision would materially change public contract shape, support truth, or maintainer burden.
- **D-02:** Phase 12 should optimize for least surprise and honest host-owned seams over demo polish or maximal installer magic.
- **D-03:** Phase 12 should repair the installer to a strong paved-road standard: after `mix phx.new` plus `mix oban_powertools.install`, a fresh host should be able to compile, migrate, and boot once the adopter completes only the true host-owned policy seams.
- **D-04:** The installer should own obvious library-side wiring and scaffolding:
  config insertion,
  router mount shape,
  Powertools migrations,
  and thin starter host seam modules where needed.
- **D-05:** The installer must not cross into fake business logic or app-template behavior. Real auth/session policy, production redaction rules, and domain-specific operator setup remain host-owned.
- **D-06:** Avoid maximal scaffolding that blurs host-vs-library ownership or generates misleading “works in demo, unsafe in production” defaults.
- **D-07:** Optional dependency behavior must remain explicit and bounded. Phase 12 should not preserve any compile-time or docs path that silently assumes `oban_web` is present.
- **D-08:** For Phase 12, the canonical fixture should follow an honest curated-fixture standard, not a showcase-demo standard.
- **D-09:** `examples/phoenix_host` must stay thin, real, and support-truth aligned:
  explicit auth seam,
  explicit display-policy seam,
  explicit host-owned router scope,
  explicit runtime wiring,
  and narrow seeded operator assumptions.
- **D-10:** The fixture README and regeneration path must clearly distinguish:
  what comes from `mix phx.new`,
  what comes from `mix oban_powertools.install`,
  and what remains irreducibly host-owned manual follow-up.
- **D-11:** The long-term direction is stricter generator provenance, but Phase 12 should not overclaim that standard until the installer and generated migration story are actually end-to-end trustworthy.
- **D-12:** Do not evolve the canonical fixture into a polished showcase app or second product. If richer demos ever exist later, they should be clearly non-canonical.
- **D-13:** Phase 12 should prove a functional paved road, not mere structural green checks and not broad browser parity.
- **D-14:** The minimum honest proof for `DOC-01` is:
  a fresh or fixture host can compile,
  run the required migrations/reset path,
  seed operator-visible data,
  and complete one real native operator flow that writes durable audit evidence.
- **D-15:** The single native proof flow should reinforce existing project support truth:
  native Powertools pages own audited mutations,
  and the optional `/ops/jobs/oban` bridge remains a bounded read-only inspection surface.
- **D-16:** Prefer idiomatic Phoenix/LiveView integration proof for the operator flow over expensive browser-E2E parity.
  The proof should be deterministic, CI-friendly, and focused on the exact day-0/day-1 contract this phase claims.
- **D-17:** Broad UI/E2E coverage across multiple native pages and the bridge is explicitly out of scope for Phase 12 unless required to close a concrete broken contract claim.

### Claude's Discretion
- Exact installer shape for starter host seam modules, provided generated code stays thin, explicit, and visibly host-owned.
- Exact audited mutation used for the first-session proof, provided it is native, deterministic, and representative of the public operator contract.
- Exact fixture diff/rebuild mechanism, provided maintainers can clearly compare generated output against the checked-in canonical host.

### Deferred Ideas (OUT OF SCOPE)
- Broad browser-E2E or multi-page UI parity across native and bridge surfaces — not needed to close the Phase 12 contract truthfully.
- Turning Powertools into a near-app-template with maximal generated business logic — outside the intended library posture.
- Shipping a polished showcase/demo host separate from the canonical contract fixture — future optional artifact only if clearly non-canonical.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | A Phoenix host app can install Oban Powertools through a documented, host-owned generator path that produces deterministic wiring for config, supervision, routes, and migrations. [VERIFIED: .planning/REQUIREMENTS.md] | Repair the real installer path in a fresh `mix phx.new` host, keep Igniter for AST-safe edits, generate or preserve thin host seams, and add proof that exercises task discovery, config insertion, route insertion, migration generation, compile, migrate, and boot. [VERIFIED: current session fresh-host repro] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/readme.html] |
| DOC-01 | A developer can complete a day-0 install and first successful operator session by following a concise documented path and example app. [VERIFIED: .planning/REQUIREMENTS.md] | Align README/guides/example fixture/regeneration script to one honest story, ensure the fixture carries Powertools migrations, and replace compile-reset-only proof with one native audited mutation plus durable audit evidence. [VERIFIED: README.md] [VERIFIED: guides/installation.md] [VERIFIED: guides/first-operator-session.md] [VERIFIED: guides/example-app-walkthrough.md] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: test/support/example_host_contract.ex] [VERIFIED: test/oban_powertools/example_host_contract_test.exs] |
</phase_requirements>

## Summary

Phase 12 is a contract-repair phase, not a feature-expansion phase. The repo already has the intended host-owned seams, docs surface, fixture host, and proof workflow, but the public day-0 claim is currently broken in two concrete ways: a fresh host running `mix oban_powertools.install` crashes inside `Igniter.Project.Config.configure_group/6`, and the canonical fixture does not contain Powertools migrations, so `ecto.reset` cannot prove native Powertools tables or a real first operator session. [VERIFIED: current session fresh-host repro] [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs] [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]

The current proof harness also stops too early for `DOC-01`. `test/support/example_host_contract.ex` copies the checked-in fixture, runs `deps.get`, `compile`, `ecto.reset`, and `seeds`, but it never exercises a true fresh-host install and never completes a native audited mutation. The existing CI workflow mirrors that limitation with `native-only`, `bridge-enabled`, and `upgrade-proof` lanes that still stop short of a real first-session mutation proof. [VERIFIED: test/support/example_host_contract.ex] [VERIFIED: test/oban_powertools/example_host_contract_test.exs] [VERIFIED: .github/workflows/host-contract-proof.yml]

The planning implication is straightforward: use the existing stack and architecture, repair the installer instead of replacing it, make fixture provenance explicit and minimal, and add one deterministic Phoenix/LiveView-backed native mutation proof that writes auditable state. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: test/oban_powertools/docs_contract_test.exs]

**Primary recommendation:** plan Phase 12 as four linked deliverables: fix installer runtime/config insertion, repair the canonical fixture migration and provenance story, add a real first-session proof lane, and then update docs/tests so every public claim is backed by that repaired path. [VERIFIED: current session fresh-host repro] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: test/support/example_host_contract.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Host install scaffolding (`mix oban_powertools.install`) | API / Backend | Frontend Server (SSR) | The installer edits backend config and Ecto migrations first, then patches Phoenix router code inside the host app. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |
| Powertools migration generation and replay | Database / Storage | API / Backend | Migration files define the durable contract, while the mix task is only the emitter. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs] [CITED: https://hexdocs.pm/oban/Oban.Migration.html] |
| Native `/ops/jobs` mount contract | Frontend Server (SSR) | API / Backend | Phoenix router ownership lives in the host web layer, but the route macro is provided by the library. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/router.ex] |
| Example fixture provenance and host-owned seams | Frontend Server (SSR) | API / Backend | The checked-in Phoenix host proves router/auth/display ownership, while backend config and migrations make that host bootable. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: examples/phoenix_host/config/config.exs] [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex] [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/oban_powertools_display_policy.ex] |
| First-session audited mutation proof | Frontend Server (SSR) | Database / Storage | The mutation is initiated through native LiveView pages and must leave durable audit evidence in storage. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] [VERIFIED: lib/oban_powertools/web/router.ex] |
| Docs and support-truth wording | Frontend Server (SSR) | — | The user-facing contract is published through README/guides/example docs rather than runtime APIs. [VERIFIED: README.md] [VERIFIED: guides/installation.md] [VERIFIED: guides/example-app-walkthrough.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.7` released 2026-05-06. [VERIFIED: mix hex.info phoenix] | Fresh host generation and router/LiveView integration surface. [VERIFIED: current session `mix phx.new --version`] | The documented install path begins from `mix phx.new`, and the fixture is a Phoenix host. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: examples/phoenix_host/mix.exs] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Igniter | `0.8.0` released 2026-05-09. [VERIFIED: mix hex.info igniter] | AST-safe project patching for config, router, and generated files. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] | The repo already uses `Igniter.Mix.Task`; fixing the current crash is lower risk than replacing it with string edits. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/readme.html] |
| Oban | `2.22.1` released 2026-04-30. [VERIFIED: mix hex.info oban] | Host job runtime and base Oban migration contract. [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs] | The canonical fixture already uses real Oban configuration and migrations. [VERIFIED: examples/phoenix_host/config/config.exs] [CITED: https://hexdocs.pm/oban/Oban.Migration.html] |
| Ecto SQL | Repo locked `3.13.5`; Hex current `3.14.0` released 2026-05-19. [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql] | Migration generation and `ecto.reset`/`ecto.migrate` proof commands. [VERIFIED: examples/phoenix_host/mix.exs] | Phase 12 should stay on the repo lock and fix proof fidelity rather than bundle a dependency upgrade. [VERIFIED: mix.lock] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban Web | `2.12.4` released 2026-05-11. [VERIFIED: mix hex.info oban_web] | Optional nested read-only bridge at `/ops/jobs/oban`. [VERIFIED: lib/oban_powertools/web/router.ex] | Keep it for the bridge-enabled lane only; do not let Phase 12 silently depend on it for native proof. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] [VERIFIED: .github/workflows/host-contract-proof.yml] |
| Phoenix LiveView | Repo locked `1.1.30`. [VERIFIED: mix.lock] | Native operator surfaces and deterministic SSR/integration proof. [VERIFIED: lib/oban_powertools/web/router.ex] | Use it for the one real first-session mutation proof instead of browser E2E. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] |
| ExUnit | Bundled with Elixir `1.19.5`. [VERIFIED: current session `mix --version`] | Structural, docs, and fixture-host proof lanes. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/example_host_contract_test.exs] | Keep using focused test files and proof helpers; the repo already has that shape. [VERIFIED: test file inventory] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Igniter-backed installer repair | Ad-hoc string/regex file editing | Faster to hack, but it abandons the repo’s existing generator model and reintroduces brittle edits for config/router insertion. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/readme.html] |
| Fixture-backed native mutation proof | Browser E2E | Browser coverage is broader, but the phase explicitly prefers deterministic Phoenix/LiveView proof over expensive parity coverage. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] |
| Synthetic fixture copy-only proof | Fresh-host generation plus real installer run | Copy-only proof is cheaper, but it misses the public day-0 contract break that the audit already found. [VERIFIED: test/support/example_host_contract.ex] [VERIFIED: current session fresh-host repro] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** The current repo and Hex state relevant to this phase were verified in-session with `mix hex.info phoenix`, `mix hex.info igniter`, `mix hex.info oban`, `mix hex.info oban_web`, and `mix hex.info ecto_sql`. [VERIFIED: current session hex version checks]

## Architecture Patterns

### System Architecture Diagram

```text
Developer
  -> `mix phx.new`
  -> add dependency
  -> `mix oban_powertools.install`
       -> Igniter patches `config/config.exs`
       -> Igniter patches host router
       -> Igniter creates thin host seam modules
       -> Igniter generates Powertools migrations
  -> host adds true host-owned policy seams only
       -> auth/session policy
       -> display/redaction policy
  -> `mix ecto.migrate` / `mix ecto.reset`
       -> Oban tables
       -> Powertools tables
  -> `mix phx.server`
       -> native `/ops/jobs`
       -> optional read-only `/ops/jobs/oban`
  -> first operator session
       -> one native audited mutation
       -> durable audit evidence
       -> docs + fixture + proof lanes stay in sync
```

### Recommended Project Structure

```text
lib/
├── mix/tasks/                 # public installer entrypoint and generation pipeline
├── oban_powertools/           # runtime config, router macro, native operator surfaces
└── oban_powertools/web/       # route macro, LiveView auth, optional bridge adapter

examples/
└── phoenix_host/              # canonical thin host fixture and provenance docs

test/
├── mix/tasks/                 # structural installer contract tests
├── oban_powertools/           # docs and proof lane tests
└── support/                   # fresh-host/fixture proof helpers
```

### Pattern 1: Thin Host-Owned Seam Generation
**What:** Generate only the seams the library can own honestly: config insertion, route mount, Powertools migrations, and starter host seam modules with obvious TODO ownership. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]
**When to use:** For every install-path repair in this phase. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
// Source: https://hexdocs.pm/igniter/readme.html
mix igniter.install package
```
[CITED: https://hexdocs.pm/igniter/readme.html]

### Pattern 2: Fixture As Public Contract, Not Showcase App
**What:** Keep `examples/phoenix_host` as a thin, diffable host that matches the public docs and can be regenerated from `mix phx.new` plus the installer plus explicit manual host seams. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: guides/example-app-walkthrough.md]
**When to use:** For every fixture edit, README update, or regeneration script change in this phase. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]
**Example:**
```elixir
// Source: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html
mix phx.new PATH --app APP --module MODULE --database postgres
```
[CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]

### Pattern 3: Layered Proof With One Real Native Mutation
**What:** Keep cheap structural tests, then add a real host proof lane that runs migrations, seeds data, and performs one native audited mutation with durable evidence. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/docs_contract_test.exs] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]
**When to use:** For Phase 12 validation and CI updates. [VERIFIED: .github/workflows/host-contract-proof.yml]
**Example:**
```elixir
// Source: https://hexdocs.pm/oban/Oban.Migration.html
def up, do: Oban.Migrations.up()
def down, do: Oban.Migrations.down()
```
[CITED: https://hexdocs.pm/oban/Oban.Migration.html]

### Anti-Patterns to Avoid
- **Source-only contract proof:** Structural grep tests alone can pass while the fresh-host install path is broken. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: current session fresh-host repro]
- **Fixture provenance overclaim:** Do not present the fixture as purely generated while `regenerate.sh` still requires manual seam reapplication. [VERIFIED: guides/example-app-walkthrough.md] [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: examples/phoenix_host/regenerate.sh]
- **Silent optional dependency assumptions:** Do not let the installer, router, or docs path imply that `oban_web` is required for native pages. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Config/router source rewriting | Regex-based patching | Igniter project config and Phoenix helpers | Igniter is already the repo’s generator mechanism and is designed for semantic project patching. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [CITED: https://hexdocs.pm/igniter/readme.html] |
| Oban table bootstrap | Custom SQL for base Oban setup | `Oban.Migrations.up/0` in Ecto migrations | The official Oban contract already defines the correct migration wrapper and upgrade path. [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs] [CITED: https://hexdocs.pm/oban/Oban.Migration.html] |
| Broad browser parity for Phase 12 proof | New Playwright/Cypress stack | ExUnit + fixture-host proof helper + one native audited mutation lane | The phase scope prefers deterministic LiveView-backed proof over broad UI automation. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] |
| Hand-maintained example prose drift checks | Manual doc review only | Docs contract tests and fixture proof lanes | The repo already has docs contract and proof workflow scaffolding; Phase 12 should extend it rather than add a human-only loop. [VERIFIED: test/oban_powertools/docs_contract_test.exs] [VERIFIED: .github/workflows/host-contract-proof.yml] |

**Key insight:** the repo’s failure is not missing infrastructure; it is that the existing installer, fixture, docs, and proof layers are not yet wired to the same executable truth. [VERIFIED: current session fresh-host repro] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: test/support/example_host_contract.ex]

## Common Pitfalls

### Pitfall 1: Treating task discovery as proof of installer health
**What goes wrong:** The direct mix task can compile and become callable, but it still crashes before writing the host contract. [VERIFIED: current session fresh-host repro]
**Why it happens:** The failure is inside `Igniter.Project.Config.configure_group/6` during runtime config insertion, not task registration. [VERIFIED: current session fresh-host repro]
**How to avoid:** Add a real fresh-host proof lane that runs the installer and then validates the emitted host files, instead of only testing the installer source file. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: current session fresh-host repro]
**Warning signs:** `mix help` may not tell you much, but `mix oban_powertools.install` crashes with `CaseClauseError` from Igniter before any real host wiring is complete. [VERIFIED: current session fresh-host repro]

### Pitfall 2: Overstating fixture provenance
**What goes wrong:** Docs and fixture README present `examples/phoenix_host` as the paved road, while `regenerate.sh` still instructs maintainers to reapply manual seams and preserve generated trees when the installer fails. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: guides/example-app-walkthrough.md]
**Why it happens:** Phase 11 documented the intended story before the installer and migration path were fully trustworthy again. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]
**How to avoid:** Make provenance explicit in both the fixture README and the walkthrough, and ensure the checked-in fixture actually carries the migrations and seams claimed by the docs. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs]
**Warning signs:** Any wording that says “generated” without naming which files are still manual host follow-up is support-truth drift. [VERIFIED: examples/phoenix_host/regenerate.sh]

### Pitfall 3: Calling compile/reset/seed a “first successful operator session”
**What goes wrong:** The proof harness can pass basic setup markers without proving a native audited mutation or durable audit evidence. [VERIFIED: test/support/example_host_contract.ex] [VERIFIED: test/oban_powertools/example_host_contract_test.exs]
**Why it happens:** The current test only checks compile/reset/seed outputs and never drives a native operator action. [VERIFIED: test/oban_powertools/example_host_contract_test.exs]
**How to avoid:** Add one deterministic native operator action and assert the durable evidence it writes. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]
**Warning signs:** Tests that only assert `"Migrated"` or a seeded actor string are not enough for `DOC-01`. [VERIFIED: test/oban_powertools/example_host_contract_test.exs]

### Pitfall 4: Forgetting the fixture migration gap
**What goes wrong:** `ecto.reset` in the fixture only installs Oban tables today, not Powertools tables. [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs]
**Why it happens:** The checked-in fixture has only the base Oban migration file. [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs]
**How to avoid:** Ensure the canonical fixture includes the Powertools migration set or a faithful generated equivalent before relying on it for native proof. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]
**Warning signs:** Missing Powertools tables after `ecto.reset`, especially `oban_powertools_cron_entries`, means the public proof host is incomplete. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]

## Code Examples

Verified patterns from official sources:

### Fresh Phoenix host baseline
```bash
# Source: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html
mix phx.new my_app --app my_app --module MyApp --database postgres
```
[CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]

### Oban migration wrapper
```elixir
// Source: https://hexdocs.pm/oban/Oban.Migration.html
defmodule MyApp.Repo.Migrations.AddOban do
  use Ecto.Migration

  def up, do: Oban.Migrations.up()
  def down, do: Oban.Migrations.down()
end
```
[CITED: https://hexdocs.pm/oban/Oban.Migration.html]

### Igniter package install entrypoint
```bash
# Source: https://hexdocs.pm/igniter_new/Mix.Tasks.Igniter.Install.html
mix igniter.install package1
```
[CITED: https://hexdocs.pm/igniter_new/Mix.Tasks.Igniter.Install.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Structural installer contract only | Structural contract plus real fresh-host execution proof | Needed by the 2026-05-22 milestone audit. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md] | Prevents docs from claiming a paved road that the real installer cannot traverse. [VERIFIED: current session fresh-host repro] |
| Canonical fixture as mostly prose-backed reference | Canonical fixture as provenance-explicit, migration-complete proof host | Direction locked by Phase 12 context on 2026-05-22. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] | Makes example-host drift visible and testable. [VERIFIED: examples/phoenix_host/regenerate.sh] |
| Compile/reset/seed as first-session proxy | One real native audited mutation with durable evidence | Required by Phase 12 locked decisions on 2026-05-22. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] | Raises `DOC-01` proof from structural setup to operator-contract truth. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**
- Treating `examples/phoenix_host` as purely generated is outdated until the installer and migration story are end-to-end trustworthy. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]
- Treating `test/support/example_host_contract.ex` as sufficient proof for the public day-0 contract is outdated because it never runs the installer in a fresh host. [VERIFIED: test/support/example_host_contract.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited — no user confirmation needed.

## Open Questions (RESOLVED)

1. **Which native audited mutation should become the canonical first-session proof?**
   - What we know: The phase requires exactly one deterministic native mutation with durable audit evidence, and broad E2E parity is out of scope. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]
   - Resolved choice: Use the native cron operator flow for seeded actor `ops-demo` to preview and execute `pause_cron_entry` against seeded cron resource `nightly_sync`. This stays on a Powertools-native page, already has strong repo precedent, and produces durable audit evidence that is easy to assert in ExUnit. [VERIFIED: test/oban_powertools/web/live/cron_live_test.exs] [VERIFIED: lib/oban_powertools/cron.ex]

2. **Should the fixture carry generated Powertools migrations verbatim or regenerate them during proof setup?**
   - What we know: The checked-in fixture currently lacks Powertools migrations, and the audit reopened the requirement because of that gap. [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs] [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]
   - Resolved choice: Keep the canonical Powertools migrations checked into `examples/phoenix_host/priv/repo/migrations/` and make `regenerate.sh` reproduce that committed tree. The fixture is a diffable public contract artifact, so `ecto.reset` must succeed from the checked-in host alone rather than relying on proof-time migration generation. [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix task compile, proof lanes, docs/tests | ✓ | `1.19.5` [VERIFIED: current session `elixir --version`] | — |
| OTP | Phoenix/Oban runtime and tests | ✓ | `28` locally. [VERIFIED: current session `elixir --version`] | CI uses OTP `27.3`, so keep proof version-tolerant. [VERIFIED: .github/workflows/host-contract-proof.yml] |
| Mix | Installer, tests, docs | ✓ | `1.19.5` [VERIFIED: current session `mix --version`] | — |
| Phoenix installer | Fresh-host repro path | ✓ | `1.8.7` [VERIFIED: current session `mix phx.new --version`] | — |
| PostgreSQL server | `ecto.reset` / host proof | ✓ | server accepting connections on `:5432`; CLI tools `14.17`. [VERIFIED: current session `pg_isready`] [VERIFIED: current session `psql --version`] | Dockerized Postgres also available. [VERIFIED: current session `docker --version`] |
| Docker | CI/service parity experiments | ✓ | `29.4.1` [VERIFIED: current session `docker --version`] | Local Postgres is already available. [VERIFIED: current session `pg_isready`] |
| Node/npm | Phoenix asset/toolchain parity if needed | ✓ | Node `22.14.0`, npm `11.1.0`. [VERIFIED: current session `node --version`] [VERIFIED: current session `npm --version`] | Not required for the minimal proof path because `phx.new` can be generated with `--no-assets`. [VERIFIED: current session fresh-host repro] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: current session environment audit]

**Missing dependencies with fallback:**
- None. [VERIFIED: current session environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`, plus Phoenix router/LiveView integration tests and docs contract tests. [VERIFIED: current session `mix --version`] [VERIFIED: test/oban_powertools/web/router_test.exs] [VERIFIED: test/oban_powertools/docs_contract_test.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test file inventory] |
| Quick run command | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs`. [VERIFIED: file existence] |
| Full suite command | `mix test && mix docs`. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-VALIDATION.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PKG-01 | Fresh `phx.new` host discovers and runs the installer, emits deterministic host wiring, and carries Powertools migrations into a bootable host. [VERIFIED: .planning/REQUIREMENTS.md] | unit + integration | `mix test test/mix/tasks/oban_powertools.install_test.exs` plus a new fresh-host proof lane that runs the installer for real. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: current session fresh-host repro] | `install_test.exs` ✅; fresh-host execution lane ❌ Wave 0 |
| DOC-01 | Canonical fixture and docs lead to compile, reset/migrate, seed, and one native audited mutation with durable evidence. [VERIFIED: .planning/REQUIREMENTS.md] | integration + docs | `mix test test/oban_powertools/docs_contract_test.exs` plus an expanded `test/oban_powertools/example_host_contract_test.exs` that asserts the native audited mutation and evidence. [VERIFIED: test/oban_powertools/docs_contract_test.exs] [VERIFIED: test/oban_powertools/example_host_contract_test.exs] | docs contract ✅; mutation proof ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs`. [VERIFIED: file existence]
- **Per wave merge:** `mix test && mix docs`. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-VALIDATION.md]
- **Phase gate:** Full suite green plus the repaired fresh-host and first-session proof lanes before `/gsd-verify-work`. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md]

### Wave 0 Gaps

- [ ] Add a fresh-host execution proof helper and test that start from `mix phx.new`, add the dependency, run `mix oban_powertools.install`, then compile/migrate/boot. The current proof helper only copies the fixture. [VERIFIED: test/support/example_host_contract.ex] [VERIFIED: current session fresh-host repro]
- [ ] Extend `test/oban_powertools/example_host_contract_test.exs` to assert one native audited mutation and durable audit evidence. The current assertions stop at compile/reset/seed output markers. [VERIFIED: test/oban_powertools/example_host_contract_test.exs]
- [ ] Update the fixture migration set so `examples/phoenix_host` actually provisions Powertools tables during `ecto.reset`. [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs] [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host auth/session policy stays host-owned in this phase; the library only scaffolds thin seams. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex] |
| V3 Session Management | no | Session mechanics remain host-owned and should not be templated into fake business logic. [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] |
| V4 Access Control | yes | Native audited mutations must keep flowing through the host-owned auth seam and the bridge must remain read-only. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: README.md] |
| V5 Input Validation | yes | Installer config insertion, runtime seam checks, and proof-lane assertions must fail fast on missing host wiring. [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: current session fresh-host repro] |
| V6 Cryptography | no | This phase does not introduce new cryptographic primitives. [VERIFIED: current phase scope] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs/support-truth drift | Tampering | Keep docs contract tests and fixture proof lanes tied to executable commands, not prose alone. [VERIFIED: test/oban_powertools/docs_contract_test.exs] [VERIFIED: .github/workflows/host-contract-proof.yml] |
| Unauthorized native mutation in example host | Elevation of Privilege | Keep explicit host auth seam and prove the selected mutation through that seam instead of bypassing it in tests. [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/oban_powertools_auth.ex] [VERIFIED: .planning/phases/12-fresh-host-install-path-example-fixture-repair/12-CONTEXT.md] |
| Silent optional bridge expansion | Elevation of Privilege | Preserve the bounded read-only `/ops/jobs/oban` contract in router/docs/proof. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: README.md] |
| Missing Powertools tables during first session | Denial of Service | Make fixture migrations complete and assert them through reset/proof lanes before claiming a successful operator session. [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs] [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md] |

## Sources

### Primary (HIGH confidence)
- `lib/mix/tasks/oban_powertools.install.ex` - current installer pipeline, Igniter usage, config insertion, router scope insertion, and migration generation. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]
- `test/support/example_host_contract.ex` and `test/oban_powertools/example_host_contract_test.exs` - current proof helper behavior and proof gaps. [VERIFIED: test/support/example_host_contract.ex] [VERIFIED: test/oban_powertools/example_host_contract_test.exs]
- `examples/phoenix_host/README.md`, `examples/phoenix_host/regenerate.sh`, and `examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs` - current fixture provenance, regeneration steps, and migration gap. [VERIFIED: examples/phoenix_host/README.md] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: examples/phoenix_host/priv/repo/migrations/20260522000000_install_oban.exs]
- `.planning/milestones/v1.1-MILESTONE-AUDIT.md` - reopened gaps, broken-flow evidence, and requirement mapping. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md]
- Current-session fresh-host reproduction on 2026-05-22 - verified direct installer crash in a new Phoenix host with the dependency present. [VERIFIED: current session fresh-host repro]
- `mix hex.info phoenix`, `mix hex.info igniter`, `mix hex.info oban`, `mix hex.info oban_web`, `mix hex.info ecto_sql` - current Hex versions and release dates. [VERIFIED: current session hex version checks]

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html - official Phoenix project generator contract. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]
- https://hexdocs.pm/igniter/readme.html - official Igniter end-user and library-author install model. [CITED: https://hexdocs.pm/igniter/readme.html]
- https://hexdocs.pm/igniter_new/Mix.Tasks.Igniter.Install.html - official `mix igniter.install` task syntax. [CITED: https://hexdocs.pm/igniter_new/Mix.Tasks.Igniter.Install.html]
- https://hexdocs.pm/oban/Oban.Migration.html - official Oban migration wrapper and versioned migration guidance. [CITED: https://hexdocs.pm/oban/Oban.Migration.html]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - repo lock state, Hex version data, and official docs were all verified in-session. [VERIFIED: mix.lock] [VERIFIED: current session hex version checks] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]
- Architecture: HIGH - the relevant installer, router, fixture, docs, and proof files were inspected directly, and the core failure was reproduced in a fresh host. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: examples/phoenix_host/lib/phoenix_host_web/router.ex] [VERIFIED: current session fresh-host repro]
- Pitfalls: HIGH - each pitfall is backed by current repo code, docs, audit evidence, or a direct repro. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md] [VERIFIED: examples/phoenix_host/regenerate.sh] [VERIFIED: test/oban_powertools/example_host_contract_test.exs]

**Research date:** 2026-05-22
**Valid until:** 2026-06-21 for repo-local findings; refresh Hex/package facts sooner if dependencies are upgraded. [VERIFIED: current session hex version checks]
