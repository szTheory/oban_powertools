# Phase 11: Docs, Example App, Compatibility & Contract Proof - Research

**Researched:** 2026-05-21 [VERIFIED: current session date]  
**Domain:** Documentation architecture, generator-backed Phoenix host proof, compatibility/support-truth posture, and automated contract verification for Oban Powertools. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]  
**Confidence:** MEDIUM [VERIFIED: repo inspection plus official docs; exact fixture layout and CI wiring still require maintainer choice]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Downstream agents should treat the recommendations in this context as locked defaults and avoid reopening them unless a later choice would materially affect public contract shape, upgrade/support truth, or maintainer cost.
- **D-02:** Shift docs/adoption/support-truth hardening left by default in GSD and downstream planning for this project.
  Prefer decisive recommendations over re-asking unless the choice would materially change the public host contract or support guarantee.
- **D-03:** Phase 11 should optimize for least surprise over maximum demo polish.
  If a choice improves honesty, cohesion, and long-term maintainability at the cost of a flashier showcase, choose the honest/maintainable path.

### Example App Strategy
- **D-04:** Use one generator-driven fixture app as the supported example app.
  It should be produced from the real paved road:
  `mix phx.new` plus `mix oban_powertools.install`,
  then kept intentionally thin.
- **D-05:** Do not make the primary example a handcrafted “full product” demo app.
  That becomes a second product, drifts from the install contract, and creates support-truth ambiguity.
- **D-06:** Do not ship multiple public example apps for install/auth/bridge permutations as the default docs path.
  One canonical host shape is easier to understand and maintain.
- **D-07:** The example app must prove real host-owned seams rather than faking them:
  real router scope,
  real browser pipeline protection,
  real `auth_module`,
  real `display_policy`,
  and real optional `oban_web` behavior.
- **D-08:** The example app should include seeded operator data so docs can walk through a first successful operator session without requiring readers to infer setup steps.
- **D-09:** Support both `oban_web` enabled and disabled modes through the same canonical example path rather than through separate divergent examples.

### Documentation Architecture
- **D-10:** Use a short README backed by versioned HexDocs/ExDoc guides and the example app.
  HexDocs should be the canonical documentation surface, not a bespoke docs site.
- **D-11:** README should stay intentionally concise:
  project positioning,
  support-truth summary,
  60-second install,
  one router example,
  one optional `oban_web` note,
  and links to guides/example app.
- **D-12:** Split the rest of the docs into focused guides rather than growing the README into a wall of prose.
- **D-13:** Recommended guide structure:
  `Installation`,
  `First Operator Session`,
  `Upgrade & Compatibility`,
  `Production Hardening`,
  `Optional Oban Web Bridge`,
  `Troubleshooting`,
  `Support Truth / Ownership Boundaries`,
  and `Example App Walkthrough`.
- **D-14:** Upgrade guidance must be guide-shaped, not changelog-shaped.
  Translate version-to-version changes into concrete host actions:
  config changes,
  migration steps,
  optional dependency changes,
  and proof/verification expectations.
- **D-15:** Optional dependency guidance for `oban_web` must be first-class and explicit, not a footnote.
- **D-16:** Support-truth statements should be repeated deliberately across README, guides, and example app walkthrough where needed.
  Repetition is preferable to accidental ambiguity for this public contract.

### Compatibility Promise
- **D-17:** Publish a tested compatibility matrix plus best-effort tiers outside that matrix.
  Do not rely on vague narrative support language alone.
- **D-18:** The public promise should distinguish:
  tested/supported host combinations,
  tested native-only path,
  tested optional `oban_web` path,
  and best-effort/unproven combinations outside those lanes.
- **D-19:** Do not publish a broad exhaustive matrix that implies more support breadth than CI can prove.
- **D-20:** Do not use an overly narrow pinned-only compatibility posture unless future maintenance pressure forces it.
  That would be unidiomatic for this ecosystem and would unnecessarily slow adoption.
- **D-21:** Native Powertools support and optional `oban_web` bridge support must be documented as separate support surfaces.
  The bridge remains narrower and must not inherit broader promises by implication.
- **D-22:** Version/support truth should align with actual dependency declarations in `mix.exs`, but docs must still spell out which combinations are actively tested versus merely semver-allowed.

### Contract Proof Strategy
- **D-23:** Use a layered proof stack rather than relying on source-level contract tests alone or building a giant demo app.
- **D-24:** Keep the existing fast unit/contract suite as the base layer for installer shape, route shape, and bridge policy invariants.
- **D-25:** Add one minimal Phoenix host fixture app that proves the real generator-backed install path end-to-end:
  install,
  compile,
  migrate,
  mount,
  and first operator-session behavior.
- **D-26:** Add two CI lanes for the fixture app:
  native-only (`oban_web` absent),
  and optional bridge enabled (`oban_web` present).
- **D-27:** Add narrow docs verification for canonical snippets and support-truth markers.
  Verify the install/router/config examples and key promises such as:
  bridge is read-only,
  host owns the outer `/ops/jobs` shell,
  native Powertools pages own audited mutations.
- **D-28:** Add an upgrade-proof lane for the documented supported upgrade path(s) in this milestone.
  Phase 11 should prove the path it documents rather than hand-wave upgrade confidence.
- **D-29:** Keep the fixture small and purpose-built.
  It is proof infrastructure and example infrastructure, not a second app to grow indefinitely.
- **D-30:** Proof should bias toward real host integration and optional-dependency truth,
  not toward expensive browser-E2E parity for every UI surface.

### Day-0 vs Day-2 Emphasis
- **D-31:** Use a balanced documentation posture with a strong day-0 lead-in and immediate day-2 follow-through.
- **D-32:** Concretely, Phase 11 should feel roughly `60/40` toward day-0 first success vs day-2 hardening/troubleshooting.
- **D-33:** README and the example app should optimize for first successful install and first successful operator session.
- **D-34:** The next docs hop after that initial success must be hardening and troubleshooting, not source-diving or issue archaeology.
- **D-35:** Do not let day-0 simplification hide the real host-owned seams:
  auth,
  display policy,
  telemetry boundaries,
  optional bridge posture,
  supervision/runtime wiring,
  and support-truth boundaries.

### Support-Truth and Ownership Messaging
- **D-36:** Keep Phase 10’s support-truth intact:
  native Powertools pages own audited mutations;
  the optional `/ops/jobs/oban` bridge stays a bounded read-only inspection surface.
- **D-37:** Documentation must make host-owned versus library-owned responsibilities explicit:
  host owns router scope, browser pipeline, auth policy implementation, and runtime config;
  library owns internal runtime helpers, pages, adapters, and the nested bridge plumbing.
- **D-38:** The example app and docs should show the real contract with reverse-proxy/WebSocket/auth caveats where they materially affect mounted operator UI behavior.
- **D-39:** Do not let the example app or docs imply broader bridge parity, hidden fallback behavior, or enterprise-style support commitments.

### the agent's Discretion
- Exact file layout for guides and example-fixture directories, provided the information architecture stays layered and the example stays generator-driven.
- Exact tested lane naming and CI wiring, provided the public docs distinguish tested support from best-effort support.
- Exact seed data and walkthrough steps for the first operator session, provided they exercise real host-owned seams and at least one native audited mutation plus bridge read-only behavior.
- Exact snippet/doc verification technique, provided canonical examples and support-truth markers cannot silently drift.

### Deferred Ideas (OUT OF SCOPE)
- A handcrafted, productized showcase demo app with broader domain behavior than the host contract requires.
- Multiple public example apps for every configuration permutation.
- A bespoke documentation website separate from HexDocs/ExDoc.
- A wide compatibility cross-product matrix across many Elixir/Phoenix/Oban/`oban_web` versions beyond what CI can realistically prove.
- Browser-E2E parity proof for every native page and bridge surface.
- Any expansion of the bridge into a write-capable surface or pseudo-native mutation equivalent.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-02 | A maintainer can upgrade an existing host app between supported milestone versions using an explicit migration and compatibility guide without guessing hidden contract changes. [VERIFIED: .planning/REQUIREMENTS.md] | Add one guide-shaped upgrade document plus an upgrade-proof lane that applies the documented host changes against the canonical example app. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [VERIFIED: README.md] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |
| HST-03 | A host app can understand support-truth boundaries for what Powertools guarantees versus what remains host-owned or intentionally unsupported. [VERIFIED: .planning/REQUIREMENTS.md] | Repeat the same ownership/support-truth markers across README, ExDoc guides, router proof, and docs contract tests. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: test/oban_powertools/web/router_test.exs] |
| DOC-01 | A developer can complete a day-0 install and first successful operator session by following a concise documented path and example app. [VERIFIED: .planning/REQUIREMENTS.md] | Use one committed generated Phoenix host app with seed data, plus a short README and a `First Operator Session` guide linked to that app. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [VERIFIED: mix help phx.new] |
| DOC-02 | A developer can apply a production-hardening checklist for auth, telemetry, optional dependencies, and troubleshooting without reading internal implementation code. [VERIFIED: .planning/REQUIREMENTS.md] | Split day-2 guidance into focused ExDoc pages and prove key support-truth strings so hardening guidance does not drift. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| DOC-03 | Maintainers can verify the public host contract with automated proof that covers optional dependency paths, route/auth integration, and support-truth regressions. [VERIFIED: .planning/REQUIREMENTS.md] | Keep the existing structural tests, add a native-only compile lane, add a bridge-enabled fixture-host lane, and add docs contract tests for canonical snippets and promises. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/web/router_test.exs] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] |
</phase_requirements>

## Summary

Phase 11 is mostly an evidence and packaging phase, not a feature-expansion phase. The repo already has the public seams that need to be taught and proven: the installer task, host-owned runtime config, the mounted router contract, the read-only `oban_web` bridge posture, and structural tests around installer and route shape. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/web/router_test.exs]

The biggest planning insight is that one generated Phoenix host app should serve three jobs at once: public example app, fixture-backed proof target, and upgrade-path proving ground. A checked-in thin host app keeps docs linkable and CI deterministic, while a small regeneration script preserves fidelity to `mix phx.new` plus `mix oban_powertools.install`. That recommendation is strong, but the exact directory choice is still a maintainer decision. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] [ASSUMED]

The main repo-local sharp edge is that the README and runtime contract already require `display_policy`, but the installer only scaffolds `repo` and `auth_module`. Planning must therefore treat the example app and docs as the place where the real day-0 path is made explicit: a first successful session currently requires a real host `auth_module`, a real host `display_policy`, router mount, migrations, and seeded operator data. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]

**Primary recommendation:** Plan Phase 11 as four slices: add ExDoc-backed guides and a short README, add one thin committed generated Phoenix host app, add layered native-only/bridge-enabled/upgrade proof lanes, and add docs contract tests that lock canonical snippets plus support-truth copy. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| README and HexDocs information architecture | CDN / Static | API / Backend | The delivered contract is static documentation, but the content must stay grounded in actual host/runtime seams defined by library code. [VERIFIED: README.md] [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] |
| Canonical Phoenix example host | Frontend Server (SSR) | Database / Storage | The proof target is a real Phoenix app with router scope, browser pipeline, LiveView mount, migrations, and seeded data. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Installer and upgrade contract proof | API / Backend | Database / Storage | The installer, migration application, runtime config, and upgrade sequencing are backend-owned contract surfaces. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] [VERIFIED: lib/oban_powertools/runtime_config.ex] |
| Optional `oban_web` bridge proof | Frontend Server (SSR) | API / Backend | The bridge contract is mounted in the Phoenix router and shares LiveView auth hooks, but its support-truth depends on backend policy seams. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] |
| Docs drift detection | API / Backend | CDN / Static | Narrow automated checks should parse README/guides and assert canonical strings and snippets before published docs drift from code. [VERIFIED: test/oban_powertools/web/router_test.exs] [ASSUMED] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExDoc | `0.40.3` latest on Hex, published `2026-05-21`. [VERIFIED: mix hex.info ex_doc] | Generate HexDocs/ExDoc guides from repo-local Markdown extras. | Official ExDoc supports `:docs`, `:extras`, and `:groups_for_extras`, which fits the locked guide-based docs IA without a custom site. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Phoenix generator (`phx_new`) | Local archive `1.8.7`. [VERIFIED: mix help phx.new] | Create the canonical example host from the real paved road. | The phase context explicitly locks `mix phx.new` as the generator base, and Phoenix documents `--install`, `--no-install`, and `PHX_NEW_CACHE_DIR` for reproducible generation flows. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| ExUnit / `mix test` | Elixir `1.19.5` locally. [VERIFIED: mix --version] | Docs contract tests, fixture-host smoke tests, and tagged proof lanes. | The repo already uses ExUnit broadly, and Mix officially supports tag-filtered runs with `--only`/`--exclude` for focused lanes. [VERIFIED: test/test_helper.exs] [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban Powertools installer via Igniter | `igniter 0.8.0` locked. [VERIFIED: mix deps] | Source of truth for the host install contract that the example app must follow. | Use the real installer task; do not recreate its edits manually in docs or the example host. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex] |
| Oban | `2.22.1` locked. [VERIFIED: mix deps] | Real runtime dependency for the example host and compatibility guidance. | Use the locked repo dependency as the tested baseline and document broader support only where `mix.exs` semver ranges and CI evidence agree. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| Oban Web | `2.12.4` locked, optional path. [VERIFIED: mix deps] | Bridge-enabled support lane and optional docs path. | Use only in the bridge-enabled lane and in the dedicated bridge guide; keep native-only proof separate. [VERIFIED: mix.exs] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] |
| PostgreSQL | Local `14.17`; server accepting connections on `5432`. [VERIFIED: psql --version] [VERIFIED: pg_isready] | Fixture-host migrations, seeds, and integration proof. | Use the same Postgres-backed posture as the repo’s current tests and host contract. [VERIFIED: config/test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One committed generated host app | Generate a fresh host app inside every CI run | Fresh generation maximizes purity but makes docs harder to link to, slows CI, and widens drift to Phoenix archive version changes. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] [ASSUMED] |
| ExDoc extras plus grouped guides | README-only documentation | README-only contradicts the locked docs architecture and makes day-2 guidance harder to version and verify. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Narrow ExUnit docs/fixture proof | Browser E2E for every operator page | Browser E2E would over-invest in UI parity when the context explicitly wants contract proof biased toward real host integration and optional dependency truth. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] |

**Installation:**
```bash
# add docs support
mix deps.get

# ensure Phoenix generator is present for fixture regeneration
mix archive.install hex phx_new 1.8.7
```

**Version verification:** Current repo-locked versions were verified with `mix deps` and `mix.lock`; current ExDoc release metadata was verified with `mix hex.info ex_doc`; local Phoenix generator version was verified with `mix help phx.new`. [VERIFIED: mix deps] [VERIFIED: mix.lock] [VERIFIED: mix hex.info ex_doc] [VERIFIED: mix help phx.new]

## Architecture Patterns

### System Architecture Diagram

```text
README / HexDocs entrypoint
  -> 60-second install
  -> links to focused guides
  -> links to canonical example host

Canonical example host (generated Phoenix app)
  -> mix phx.new
  -> add oban_powertools (+ optional oban_web lane)
  -> mix oban_powertools.install
  -> add thin host auth/display_policy/seeds
  -> run migrations
  -> mount /ops/jobs scope
  -> prove first operator session

Automated proof
  -> fast structural tests
     -> installer source contract
     -> router / bridge contract
  -> docs contract tests
     -> README snippets
     -> guide markers
     -> support-truth language
  -> fixture host lanes
     -> native-only compile/test
     -> bridge-enabled compile/test
     -> documented upgrade path smoke

Published support truth
  -> tested matrix
  -> best-effort outside matrix
  -> separate native and bridge promises
```

The core pattern is layered proof: cheap structural tests remain the base, then docs drift tests, then one real host app for end-to-end contract proof. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [VERIFIED: test/oban_powertools/web/router_test.exs]

### Recommended Project Structure
```text
README.md
guides/
├── installation.md
├── first-operator-session.md
├── upgrade-and-compatibility.md
├── production-hardening.md
├── optional-oban-web-bridge.md
├── troubleshooting.md
├── support-truth-and-ownership-boundaries.md
└── example-app-walkthrough.md

examples/
└── phoenix_host/
    ├── mix.exs
    ├── config/
    ├── lib/
    ├── priv/repo/seeds.exs
    └── README.md

test/
├── oban_powertools/docs_contract_test.exs
├── oban_powertools/example_app_contract_test.exs
└── mix/tasks/oban_powertools.install_test.exs
```

`examples/phoenix_host/` is the recommended location because the same app is public-facing and test-facing. If the maintainer prefers `test/fixtures/`, keep a stable public pointer to it from the guides. [ASSUMED]

### Pattern 1: One Canonical Generated Host, Thin and Checked In
**What:** Keep a single Phoenix host app in-repo, generated from `mix phx.new`, then patched only with the minimum host-owned seams needed to prove the Powertools contract. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html]  
**When to use:** For docs walkthroughs, native-only proof, bridge-enabled proof, and the documented upgrade path. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**
```bash
# Source: Phoenix docs + Phase 11 context
mix phx.new examples/phoenix_host --install
cd examples/phoenix_host
# add oban_powertools dependency
mix oban_powertools.install
# add thin host auth/display policy modules and seeds
mix ecto.migrate
mix run priv/repo/seeds.exs
```

### Pattern 2: ExDoc as the Canonical Guide Surface
**What:** Configure ExDoc with `README.md` plus grouped Markdown extras under `guides/`, keeping the README short and all operational guidance versioned with the code. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**When to use:** For all non-trivial docs in this phase, especially support-truth, upgrade, hardening, and troubleshooting. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]  
**Example:**
```elixir
# Source: ExDoc docs
docs: [
  main: "readme",
  extras: [
    "README.md",
    "guides/installation.md",
    "guides/first-operator-session.md",
    "guides/upgrade-and-compatibility.md",
    "guides/production-hardening.md",
    "guides/optional-oban-web-bridge.md",
    "guides/troubleshooting.md",
    "guides/support-truth-and-ownership-boundaries.md",
    "guides/example-app-walkthrough.md"
  ],
  groups_for_extras: [
    "Day 0": ~r/guides\/(installation|first-operator-session|example-app-walkthrough)/,
    "Day 2": ~r/guides\/(upgrade-and-compatibility|production-hardening|optional-oban-web-bridge|troubleshooting|support-truth-and-ownership-boundaries)/
  ]
]
```

### Pattern 3: Separate Native-Only and Bridge-Enabled Proof Lanes
**What:** Treat native-only and bridge-enabled support as separate lanes, with native-only proving the optional dependency can be absent and bridge-enabled proving the bounded read-only integration path. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]  
**When to use:** In CI, local smoke runs, and the published compatibility matrix. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]  
**Example:**
```bash
# Source: Mix optional dependency docs
mix compile --no-optional-deps --warnings-as-errors
mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/web/router_test.exs

# bridge-enabled lane runs with locked deps present
mix test test/oban_powertools/web/router_test.exs --only oban_web_bridge
```

### Pattern 4: Docs Drift Tests for Snippets and Support-Truth Markers
**What:** Parse README and guide files in ExUnit and assert canonical snippets, route paths, config keys, and support-truth strings so docs cannot silently widen the contract. [VERIFIED: test/oban_powertools/web/router_test.exs] [ASSUMED]  
**When to use:** On every docs edit and every release candidate. [ASSUMED]  
**Example:**
```elixir
# Source: repo pattern from router_test + Phase 11 context
readme = File.read!("README.md")
guide = File.read!("guides/optional-oban-web-bridge.md")

assert readme =~ "auth_module:"
assert readme =~ "display_policy:"
assert readme =~ "/ops/jobs/oban"
assert guide =~ "read-only"
assert guide =~ "Native Powertools pages own audited mutations"
```

### Anti-Patterns to Avoid
- **Handcrafted demo app:** It becomes a second product and breaks the “real paved road” requirement. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]
- **Docs that promise semver breadth without tested lanes:** `mix.exs` ranges alone are not a support matrix. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]
- **One proof lane with `oban_web` always present:** That hides native-only regressions for an explicitly optional dependency. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]
- **Expanding the example host into product UX:** Seed only what is needed to prove install, auth, display policy, and one native mutation plus bridge inspection. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Public docs site | Custom static docs framework | ExDoc with extras/groups | ExDoc already provides versioned docs, grouped extras, main-page control, and warnings-as-errors support. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Generator fidelity | Manual “pretend generated” host tree | Real `mix phx.new` + real installer task | The context explicitly wants the example path to come from the real paved road, not a hand-maintained facsimile. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Optional dependency proof | Ad hoc shell assumptions about `oban_web` | `mix compile --no-optional-deps --warnings-as-errors` plus a separate bridge lane | Mix documents the native-only compilation check for optional dependencies, which directly matches PKG-03/DOC-03 needs. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |
| Snippet regression detection | Homegrown markdown parser or browser scraper | Small ExUnit file-content assertions | The repo already uses source-level contract assertions, and ExUnit tags make narrow docs checks cheap to run. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] |

**Key insight:** The phase should not invent new infrastructure categories. The right move is to reuse Phoenix generation, ExDoc publication, Mix optional-dependency checks, and ExUnit contract tests in one coherent proof stack. [VERIFIED: repo inspection] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

## Common Pitfalls

### Pitfall 1: The example app stops matching the installer contract
**What goes wrong:** The example host is edited by hand until it no longer reflects what `mix oban_powertools.install` actually produces. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]  
**Why it happens:** The repo currently proves installer output structurally, not through a real generated host. [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs]  
**How to avoid:** Keep the example host intentionally thin and add a regeneration script or checklist that starts from `mix phx.new` plus the installer task. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] [ASSUMED]  
**Warning signs:** Guide text says “generated by the installer” but the committed host contains extra undocumented wiring or renamed seams. [ASSUMED]

### Pitfall 2: Docs imply the installer does more than it currently does
**What goes wrong:** README/guides make day-0 sound like a one-command flow even though policy-sensitive pages also require a host `display_policy` and the installer does not scaffold that module today. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]  
**Why it happens:** The public docs already mention `display_policy`, but the generated host path currently only creates `auth_module` wiring. [VERIFIED: README.md] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]  
**How to avoid:** Make the docs and example host explicit about the minimal manual host additions required for a first successful session, or deliberately include a tiny installer enhancement in scope if the maintainer wants to shorten the path. [ASSUMED]  
**Warning signs:** Example host boots but policy-sensitive pages fail with `display_policy` setup errors. [VERIFIED: lib/oban_powertools/runtime_config.ex]

### Pitfall 3: Compatibility language outruns tested evidence
**What goes wrong:** Docs publish a broad support story based on semver ranges instead of actual tested lanes. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]  
**Why it happens:** `mix.exs` can allow more combinations than the repo actually proves in automation. [VERIFIED: mix.exs]  
**How to avoid:** Publish a small matrix with “tested native-only,” “tested bridge-enabled,” and “best-effort outside tested lanes,” then keep docs aligned with those lane names. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]  
**Warning signs:** README says “supports Oban Web” without distinguishing read-only bridge scope or whether that path is actively tested. [VERIFIED: README.md]

### Pitfall 4: Native-only support silently regresses
**What goes wrong:** Local development always has `oban_web` installed, so the optional path looks fine while the native-only compilation path breaks. [VERIFIED: mix.exs] [VERIFIED: mix deps]  
**Why it happens:** Optional dependencies are easy to accidentally reference from core code unless a no-optional-deps lane exists. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]  
**How to avoid:** Run `mix compile --no-optional-deps --warnings-as-errors` in the native-only lane and keep bridge-specific assertions separately tagged. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html]  
**Warning signs:** Bridge modules compile or import cleanly only when `oban_web` is present in the current dev environment. [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex]

## Code Examples

Verified patterns from official sources:

### ExDoc Guide Configuration
```elixir
# Source: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
def project do
  [
    app: :oban_powertools,
    version: "0.1.0",
    deps: deps(),
    docs: [
      main: "readme",
      extras: ["README.md", "guides/installation.md"],
      groups_for_extras: [
        "Guides": Path.wildcard("guides/*.md")
      ]
    ]
  ]
end
```

### Native-Only Optional Dependency Proof
```bash
# Source: https://hexdocs.pm/mix/Mix.Tasks.Deps.html
mix compile --no-optional-deps --warnings-as-errors
```

### Focused Tagged Test Lane
```bash
# Source: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html
mix test --only oban_web_bridge
```

### Cached Phoenix Generator Flow
```bash
# Source: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html
mix phx.new mycache --no-install
cd mycache
mix deps.get
mix deps.compile
mix assets.setup
rm -rf assets config lib priv test mix.exs README.md
PHX_NEW_CACHE_DIR=/path/to/mycache mix phx.new myapp
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| README as the main long-form contract | Short README plus grouped ExDoc guides | Current ExDoc docs as of `2026-05-21`. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | Keeps day-0 short while letting day-2 guidance stay versioned and testable. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] |
| Source-only installer assertions | Structural tests plus one real generated host app | Phase 11 target state. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] | Moves proof from “installer text looks right” to “host app actually boots, migrates, mounts, and serves the documented path.” [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs] [ASSUMED] |
| Vague optional dependency support | Separate native-only and bridge-enabled tested lanes | Current Mix guidance plus Phase 11 locked decisions. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] | Prevents `oban_web` from silently becoming de facto required while keeping the bridge promise honest. [VERIFIED: mix.exs] |
| Narrative compatibility promises | Small tested matrix plus best-effort outside matrix | Phase 11 locked decisions. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] | Aligns support language with what CI can actually prove. [VERIFIED: mix.exs] |

**Deprecated/outdated:**
- README-only operational guidance for install, upgrade, and troubleshooting is outdated for this milestone. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]
- Treating the bridge as implied full support whenever `oban_web` is installed is explicitly unsupported. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/web/router.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The best implementation is a checked-in canonical example app reused by docs and proof, rather than generating a fresh app inside every automated run. [ASSUMED] | Architecture Patterns | If the maintainer prefers ephemeral generation, file layout and CI tasks will change substantially. |
| A2 | There is no repo-local CI workflow yet for this proof stack because no `.github/workflows/` files exist in the repository. [ASSUMED] | Validation Architecture | If CI exists outside the repo, planning can wire into that system instead of adding repo-local workflow files. |

## Open Questions (Resolved)

1. **Installer scope vs docs/proof scope for `display_policy`**
   - Resolved decision: Phase 11 remains docs/proof-first. The phase may touch installer-adjacent proof or docs, but it does not depend on adding new installer scaffolding for `display_policy`. Instead, the README, guides, canonical example host, and upgrade lane must teach the explicit host-owned `display_policy` step honestly. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: lib/mix/tasks/oban_powertools.install.ex]

2. **Exact upgrade source lane for `PKG-02`**
   - Resolved decision: The single supported upgrade proof lane for Phase 11 starts from the shipped Phase 8 through Phase 10 host contract baseline: a host with `repo` and `auth_module` wiring already present, but without the explicit Phase 11 docs/proof additions around `display_policy`, example-host walkthrough, compatibility matrix, and proof commands. This keeps the upgrade lane narrow and honest. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]

3. **Canonical example host location**
   - Resolved decision: Use `examples/phoenix_host/` as the single public and proof-facing host tree. It stays discoverable from the docs while still serving fixture-proof needs. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | ExUnit, Mix tasks, docs/test authoring | ✓ [VERIFIED: elixir --version] | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | Build, tests, installer proof | ✓ [VERIFIED: mix --version] | `1.19.5` [VERIFIED: mix --version] | — |
| Phoenix generator archive | Regenerating canonical example host | ✓ [VERIFIED: mix help phx.new] | `1.8.7` [VERIFIED: mix help phx.new] | Document manual archive install if another machine lacks it. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| PostgreSQL | Example-host migrations and integration proof | ✓ [VERIFIED: pg_isready] | `14.17` client; server reachable on `5432`. [VERIFIED: psql --version] [VERIFIED: pg_isready] | None for this phase’s real host proof. |
| Node.js / npm | Phoenix asset tooling if example host uses default assets setup | ✓ [VERIFIED: node --version] [VERIFIED: npm --version] | `v22.14.0` / `11.1.0` [VERIFIED: node --version] [VERIFIED: npm --version] | Could avoid asset build in proof if tests only require server compile, but docs path should still use the standard generator output. [ASSUMED] |
| ExDoc task | Generating HexDocs locally | ✗ [VERIFIED: `mix docs`] | — | Add `{:ex_doc, "~> 0.40", only: :dev, runtime: false}` to enable `mix docs`. [VERIFIED: `mix docs`] [VERIFIED: mix hex.info ex_doc] |

**Missing dependencies with no fallback:**
- ExDoc is not currently configured in this repo, so HexDocs generation is blocked until the dependency and `docs:` config are added. [VERIFIED: `mix docs`] [VERIFIED: mix.exs]

**Missing dependencies with fallback:**
- None beyond ExDoc; all other required local tooling for proof research is present. [VERIFIED: current session]

## Validation Architecture

`.planning/config.json` is absent, so Nyquist validation is treated as enabled by default. [VERIFIED: `.planning/config.json` missing in current session]

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: mix --version] [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/mix/tasks/oban_powertools.install_test.exs test/oban_powertools/web/router_test.exs`. [VERIFIED: current session command] |
| Full suite command | `mix test`. [CITED: https://hexdocs.pm/elixir/1.19.3/introduction-to-mix.html] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOC-01 | Example host reaches first successful operator session with seeded data and real host seams. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only first_session -x` [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] | ❌ Wave 0 |
| DOC-02 | Guides cover hardening and troubleshooting without source-diving. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/oban_powertools/docs_contract_test.exs --only hardening -x` [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] | ❌ Wave 0 |
| DOC-03 | Native-only path compiles and keeps router/install contract intact without `oban_web`. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix compile --no-optional-deps --warnings-as-errors && mix test test/oban_powertools/example_host_contract_test.exs --only native_only -x` [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] | ❌ Wave 0 |
| DOC-03 | Bridge-enabled path proves bounded read-only bridge behavior in the canonical host. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only oban_web_bridge -x` [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] | ❌ Wave 0 |
| HST-03 | README/guides repeat the same support-truth and ownership markers. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/oban_powertools/docs_contract_test.exs --only support_truth -x` [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] | ❌ Wave 0 |
| PKG-02 | Documented upgrade path executes against the canonical host without hidden changes. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade -x` [CITED: https://hexdocs.pm/mix/main/Mix.Tasks.Test.html] | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/example_host_contract_test.exs -x` once those files exist. [ASSUMED]
- **Per wave merge:** `mix test` plus the native-only compile command. [CITED: https://hexdocs.pm/elixir/1.19.3/introduction-to-mix.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]
- **Phase gate:** Full suite green, docs build green, native-only lane green, bridge-enabled lane green, upgrade lane green before `/gsd-verify-work`. [ASSUMED]

### Wave 0 Gaps
- [ ] Add `{:ex_doc, "~> 0.40", only: :dev, runtime: false}` and `docs:` configuration to [mix.exs](/Users/jon/projects/oban_powertools/mix.exs). [VERIFIED: mix.exs] [VERIFIED: `mix docs`] [VERIFIED: mix hex.info ex_doc]
- [ ] Create guide files under `guides/` and link them from [README.md](/Users/jon/projects/oban_powertools/README.md). [VERIFIED: repo file listing]
- [ ] Add one canonical example host directory at `examples/phoenix_host/`. [RESOLVED]
- [ ] Add `test/oban_powertools/docs_contract_test.exs` for snippet/support-truth drift checks. [ASSUMED]
- [ ] Add `test/oban_powertools/example_host_contract_test.exs` for first-session, native-only, bridge-enabled, and upgrade proof. [RESOLVED]
- [ ] Add repo-local CI wiring if automated proof is expected in-repo; no `.github/workflows/` files are present today. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: HST/DOC scope] | Host `auth_module` remains the authority, and docs/example host must show that seam honestly. [VERIFIED: lib/oban_powertools/auth.ex] [VERIFIED: README.md] |
| V3 Session Management | yes [VERIFIED: mounted browser scope] | Example host must use a real browser pipeline and session-backed LiveView mount path, not a fake bypass. [VERIFIED: README.md] [VERIFIED: test/support/test_router.ex] |
| V4 Access Control | yes [VERIFIED: bridge/native contract] | Native pages keep audited mutations; the bridge remains read-only under shared auth hooks. [VERIFIED: lib/oban_powertools/web/router.ex] [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex] |
| V5 Input Validation | yes [VERIFIED: policy/config seam docs] | Docs/example host must reflect required runtime config and explicit host-owned seams so users do not mount pages with partial wiring. [VERIFIED: lib/oban_powertools/runtime_config.ex] |
| V6 Cryptography | no [VERIFIED: phase scope] | No new crypto surface should be introduced in this phase. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mounted operator UI reachable without host browser protections | Spoofing / Elevation of privilege | Repeat that the host owns the outer browser scope and pipeline; prove it in the example host and route tests. [VERIFIED: README.md] [VERIFIED: test/support/test_router.ex] |
| Bridge support-truth widened beyond read-only inspection | Tampering | Keep bridge docs/tests asserting read-only posture and native mutation ownership. [VERIFIED: README.md] [VERIFIED: test/oban_powertools/web/router_test.exs] |
| Docs drift hides required host seams like `display_policy` | Repudiation / Misconfiguration | Add docs contract tests for config snippets and first-session prerequisites. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/runtime_config.ex] [ASSUMED] |
| Reverse-proxy or WebSocket caveats omitted from mounted LiveView docs | Denial of service / Availability | Include a troubleshooting/hardening guide with reverse-proxy and WebSocket notes where they materially affect the mounted ops UI. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- [README.md](/Users/jon/projects/oban_powertools/README.md) - current public install, router, bridge, and telemetry contract.
- [mix.exs](/Users/jon/projects/oban_powertools/mix.exs) - dependency ranges and current lack of docs config.
- [lib/mix/tasks/oban_powertools.install.ex](/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex) - real installer-backed host path.
- [lib/oban_powertools/runtime_config.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/runtime_config.ex) - required host config seams and fail-fast messages.
- [lib/oban_powertools/web/router.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/router.ex) - mounted route and optional bridge contract.
- [lib/oban_powertools/web/oban_web_bridge.ex](/Users/jon/projects/oban_powertools/lib/oban_powertools/web/oban_web_bridge.ex) - bounded read-only bridge posture.
- [test/mix/tasks/oban_powertools.install_test.exs](/Users/jon/projects/oban_powertools/test/mix/tasks/oban_powertools.install_test.exs) - current structural installer proof.
- [test/oban_powertools/web/router_test.exs](/Users/jon/projects/oban_powertools/test/oban_powertools/web/router_test.exs) - current route and support-truth proof pattern.
- [test/support/test_router.ex](/Users/jon/projects/oban_powertools/test/support/test_router.ex) - real browser pipeline example.
- [test/test_helper.exs](/Users/jon/projects/oban_powertools/test/test_helper.exs) - current ExUnit and DB-backed test harness.
- [11-CONTEXT.md](/Users/jon/projects/oban_powertools/.planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md) - locked Phase 11 decisions.
- [REQUIREMENTS.md](/Users/jon/projects/oban_powertools/.planning/REQUIREMENTS.md) - PKG-02, HST-03, DOC-01, DOC-02, DOC-03.

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html - ExDoc project config and `mix docs`.
- https://hexdocs.pm/ex_doc/ExDoc.html - `:extras` and `:groups_for_extras`.
- https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html - canonical Phoenix generator behavior, `--install`, and `PHX_NEW_CACHE_DIR`.
- https://hexdocs.pm/mix/Mix.Tasks.Deps.html - optional dependency semantics and native-only compile guidance.
- https://hexdocs.pm/mix/main/Mix.Tasks.Test.html - `--only` / `--exclude` tag-filtered test lanes.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and capabilities were verified from repo-local tooling plus official docs. [VERIFIED: mix deps] [VERIFIED: mix hex.info ex_doc] [VERIFIED: mix help phx.new]
- Architecture: MEDIUM - the layered proof strategy is well supported by repo-local constraints, but the exact example-host placement and CI wiring still need maintainer choice. [VERIFIED: .planning/phases/11-docs-example-app-compatibility-contract-proof/11-CONTEXT.md] [ASSUMED]
- Pitfalls: HIGH - the main failure modes are already visible in current repo state, especially `display_policy` drift, optional dependency truth, and source-only installer proof. [VERIFIED: README.md] [VERIFIED: lib/oban_powertools/runtime_config.ex] [VERIFIED: test/mix/tasks/oban_powertools.install_test.exs]

**Research date:** 2026-05-21 [VERIFIED: current session date]  
**Valid until:** 2026-06-20 for repo-local findings; re-check package/doc versions sooner if dependency ranges or support lanes change. [ASSUMED]
