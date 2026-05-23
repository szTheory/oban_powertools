# Phase 15: Upgrade Lane, Support Truth & Public Docs Integrity - Research

**Researched:** 2026-05-23
**Domain:** Phoenix host-fixture upgrade proof, support-truth documentation, and docs-to-proof contract alignment for Oban Powertools. [VERIFIED: .planning/ROADMAP.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md`. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]

### Locked Decisions
- **D-01:** Shift recommendation burden left by default for this phase and downstream GSD work. Planners and implementers should treat the decisions below as locked defaults unless a later choice would materially widen the public support promise or create a new maintainer burden.
- **D-02:** Optimize for support-truth honesty, least surprise, and maintainer DX over broader but weaker upgrade or compatibility claims.
- **D-03:** Keep the native `/ops/jobs` shell as the primary public surface. The optional `/ops/jobs/oban` bridge remains additive and narrower everywhere in docs and proof.

### Supported Upgrade Source Lane
- **D-04:** Support one explicit upgrade source lane, not a fuzzy family of historical hosts.
- **D-05:** The supported source lane is a real native-first Phoenix host generated from `mix phx.new`, using Postgres/Ecto, with Powertools already installed, `repo` and `auth_module` configured, the host-owned `/ops/jobs` scope already mounted, and Powertools migrations already present.
- **D-06:** The supported source lane intentionally starts before the explicit `display_policy` contract is in place. The core upgrade step is moving that host shape onto the required `display_policy` posture and current support-truth docs.
- **D-07:** Public docs must describe this lane in host-shape terms, not internal phase-number terms like “Phase 8/9/10.”
- **D-08:** Bridge-enabled source hosts, manually diverged hosts, partially adopted hosts, and hosts missing `repo`, `auth_module`, or `/ops/jobs` are best-effort rather than supported.

### Upgrade Proof Architecture
- **D-09:** Replace the current synthetic in-place config rewrite with one archived historical upgrade-source fixture generated once from an exact pre-`display_policy` commit.
- **D-10:** Keep the current canonical fixture for current-state native-first, first-session, and optional-bridge proof. Add a second, frozen historical fixture only for the upgrade lane.
- **D-11:** The upgrade lane should point the historical fixture at the current library, apply only the documented upgrade actions, run dependency/install steps and migrations, then prove one meaningful post-upgrade native behavior.
- **D-12:** Do not use full historical generator replay in normal CI. Toolchain drift, network drift, and old installer behavior would create noise unrelated to the host contract being claimed.
- **D-13:** If provenance insurance is needed, use a maintainer-only regeneration script from the exact historical commit, but keep that out of the hot PR proof path.

### Support-Truth Messaging
- **D-14:** Use a sharp layered support-truth contract across README and guides: precise, repeated, and confidence-building, not soft ambiguity and not fatalistic “as-is” nihilism.
- **D-15:** Public docs must distinguish five buckets explicitly:
  supported,
  tested,
  best-effort,
  host-owned,
  and intentionally unsupported.
- **D-16:** `Supported` covers the native `/ops/jobs` shell, the host-owned integration contract, the canonical upgrade lane, and the optional `/ops/jobs/oban` bridge only as a read-only inspection annex.
- **D-17:** `Tested` covers the fresh-host install path, the canonical first-session proof, the native-first fixture lane, the optional-bridge render lane, docs contract assertions, and the real supported upgrade lane.
- **D-18:** `Best-effort` covers semver-allowed combinations outside the tested matrix, bespoke host shells beyond the documented mount shape, unusual reverse-proxy/session setups, and bridge behavior beyond the bounded contract.
- **D-19:** `Host-owned` must stay explicit: auth policy, actor/session lookup, display/redaction policy, outer route scope, browser pipeline, reverse-proxy and WebSocket/session behavior, seeded operator data, and whether to expose the bridge in production.
- **D-20:** `Intentionally unsupported` includes bridge write parity, hidden fallback behavior when required config is missing, non-Postgres support, and broad compatibility claims outside verified lanes.
- **D-21:** Separate product-support posture from support-truth posture. It is acceptable to state there is no commercial support, but docs must not collapse that into “nothing here is dependable.”

### Docs-To-Proof Enforcement Boundary
- **D-22:** Use layered claim-based enforcement as the steady-state posture.
- **D-23:** Executable contract should cover:
  installer-backed host setup,
  required config keys,
  router mount shape,
  missing-config fail-fast behavior,
  native-first compile/reset behavior,
  the canonical first native audited mutation,
  optional bridge read-only render,
  and the real supported upgrade lane.
- **D-24:** Docs contract checks should stay narrow and stable: canonical commands, paths, seam names, tested-lane names, support-truth bullets, and “best-effort outside tested lanes” language.
- **D-25:** Do not treat most guide prose as exact-string spec. Hardening checklists, troubleshooting advice, and operational caveats should remain narrative guidance unless the library actually guarantees or rejects the condition at runtime.
- **D-26:** Do not expand into broad browser-E2E proof for this phase. Compile, migrate/reset, mount, and one meaningful native post-upgrade action are the right proof depth.

### the agent's Discretion
- Exact naming of the historical upgrade fixture and workflow lane, provided the source lane remains singular and explicit.
- Exact post-upgrade proof action, provided it is native, meaningful, deterministic, and aligned with the existing first-session/operator contract.
- Exact docs section structure and marker placement, provided the five support-truth buckets remain explicit and consistently enforced.

### Deferred Ideas (OUT OF SCOPE)
- Supporting multiple historical upgrade source lanes in CI — defer unless real adopter volume justifies a permanently wider proof matrix.
- Full historical generator replay on every PR — defer to a maintainer-only regeneration check if provenance reassurance becomes necessary.
- Broad browser-E2E coverage for upgrade proof — outside the proof depth required for this phase.
- Expanding docs contract checks into full prose snapshots — explicitly rejected unless docs become the primary product surface rather than a support-truth layer.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement descriptions copied from `.planning/REQUIREMENTS.md`. [VERIFIED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| `PKG-02` | A maintainer can upgrade an existing host app between supported milestone versions using an explicit migration and compatibility guide without guessing hidden contract changes. | Use one frozen historical source fixture plus one real upgrade-proof lane that applies only documented steps, then prove a meaningful native post-upgrade behavior. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs] |
| `HST-03` | A host app can understand support-truth boundaries for what Powertools guarantees versus what remains host-owned or intentionally unsupported. | Rewrite README plus support-truth and upgrade guides around the five explicit buckets, and lock only those public claims in `docs_contract_test.exs`. [VERIFIED: .planning/REQUIREMENTS.md; README.md; guides/support-truth-and-ownership-boundaries.md; guides/upgrade-and-compatibility.md; test/oban_powertools/docs_contract_test.exs] |
| `DOC-02` | A developer can apply a production-hardening checklist for auth, telemetry, optional dependencies, and troubleshooting without reading internal implementation code. | Align `guides/production-hardening.md` and `guides/troubleshooting.md` to the verified host-owned seams, fail-fast config checks, and bounded bridge posture already exercised by the test suite. [VERIFIED: .planning/REQUIREMENTS.md; guides/production-hardening.md; guides/troubleshooting.md; lib/oban_powertools/runtime_config.ex; test/oban_powertools/auth_test.exs; test/oban_powertools/docs_contract_test.exs] |
</phase_requirements>

## Summary

Phase 15 should be planned as a contract-honesty repair, not as a new runtime capability phase. The repo already has the right proof skeleton: one fresh-host lane, one canonical current-state fixture, one first-session native proof, one optional-bridge proof, one docs-contract test, and one named upgrade lane in CI. The gap is that the current upgrade lane is synthetic and the public docs still describe a broader source family than the proof actually establishes. [VERIFIED: .github/workflows/host-contract-proof.yml; test/support/fresh_host_contract.ex; test/support/example_host_contract.ex; test/oban_powertools/fresh_host_contract_test.exs; test/oban_powertools/example_host_contract_test.exs; guides/upgrade-and-compatibility.md]

The current `upgrade` path in `test/support/example_host_contract.ex` copies the modern `examples/phoenix_host` fixture, deletes the `display_policy` line, and immediately adds it back before proof commands run. The matching test only asserts that `display_policy` is present again and that `ecto.reset` migrates successfully, so it does not prove a real historical host can be upgraded through documented steps. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs]

The most defensible plan is three slices. First, add one frozen historical upgrade-source fixture with explicit provenance and keep the current `examples/phoenix_host` fixture untouched for native-first, first-session, and bridge proof. Second, rework the `upgrade-proof` lane to point that historical source at the current library, perform only the guide-documented upgrade actions, and then prove one native post-upgrade operator action such as the existing `ops-demo` -> `pause_cron_entry` on `nightly_sync`. Third, tighten README and guide language around the five support-truth buckets and extend docs-contract assertions only for those stable claims. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; examples/phoenix_host/README.md; guides/first-operator-session.md; test/oban_powertools/docs_contract_test.exs]

**Primary recommendation:** Plan Phase 15 as three execute plans: `historical fixture + upgrade harness`, `public support-truth doc realignment`, and `docs/workflow regression guardrails`. [VERIFIED: .planning/ROADMAP.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Historical upgrade-source provenance | Frozen fixture under `examples/` | Maintainer-only regen script | Provenance has to live in versioned artifacts, while regeneration can stay off the hot CI path. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; examples/phoenix_host/regenerate.sh] |
| Executable supported upgrade proof | ExUnit host-contract harness | GitHub Actions lane | The upgrade claim is only credible if `test/support/example_host_contract.ex` and `example_host_contract_test.exs` prove it locally and the workflow keeps a dedicated `upgrade-proof` lane. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs; .github/workflows/host-contract-proof.yml] |
| Public support-truth contract | README and guides | `docs_contract_test.exs` | Docs own the wording, but only the stable claims should be locked in tests. [VERIFIED: README.md; guides/support-truth-and-ownership-boundaries.md; guides/upgrade-and-compatibility.md; test/oban_powertools/docs_contract_test.exs] |
| Host-owned hardening and troubleshooting guidance | Guides | Runtime fail-fast checks | Hardening and troubleshooting are mostly narrative, but they should point directly at the real runtime seams and fail-fast errors already enforced in code. [VERIFIED: guides/production-hardening.md; guides/troubleshooting.md; lib/oban_powertools/runtime_config.ex] |
| Canonical post-upgrade behavior proof | Native `/ops/jobs` contract test | Shared seed fixture | The native shell is the supported mutation surface, and the existing first-session values already define the repo’s meaningful deterministic proof threshold. [VERIFIED: README.md; guides/first-operator-session.md; examples/phoenix_host/README.md; test/oban_powertools/example_host_contract_test.exs] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` | Test/runtime toolchain for the repo and fixture proofs. | The workflow pins Elixir `1.19.5`, and the local environment matches it, which keeps proof commands aligned between CI and local planning. [VERIFIED: .github/workflows/host-contract-proof.yml; mix --version] |
| Phoenix | `1.8.7` released `2026-05-06` | Generates the supported host shape and runs the canonical example fixture. | `mix phx.new` is the upstream-supported host generator, and both the docs and fresh-host harness depend on that shape. [VERIFIED: examples/phoenix_host/mix.exs; test/support/fresh_host_contract.ex; mix.lock; mix hex.info phoenix] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |
| Oban Powertools installer (`Igniter`) | `0.8.0` | Generates config, router scope, host seams, and migrations. | The supported lane is explicitly “Phoenix host + `mix oban_powertools.install`”, so the installer remains the public contract boundary. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; mix.lock] |
| Ecto SQL | `3.13.5` locked, latest `3.14.0` released `2026-05-19` | Powers migrations and reset/migrate proof commands. | This phase is not a dependency-upgrade phase, so the planner should preserve the locked version while using its migration commands as proof surfaces. [VERIFIED: mix.exs; mix.lock; mix hex.info ecto_sql] |
| Oban | `2.22.1` released `2026-04-30` | Current job/runtime dependency used by the library and example fixture. | The upgrade lane proves host-contract adoption against the current library dependency set, not against a legacy Oban matrix. [VERIFIED: mix.exs; mix.lock; mix hex.info oban] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban Web | `2.12.4` released `2026-05-11` | Optional read-only bridge at `/ops/jobs/oban`. | Keep it only for the bounded bridge lane and for docs that describe inspection-only behavior. [VERIFIED: README.md; examples/phoenix_host/mix.exs; mix.lock; mix hex.info oban_web] |
| ExDoc | `0.40.3` released `2026-05-21` | Builds README plus guide extras into the public docs surface. | Use it for doc publication, but keep docs-contract enforcement at the markdown source layer. [VERIFIED: mix.exs; mix.lock; mix hex.info ex_doc] |
| ExUnit | `1.19.5` | Runs docs-contract and host-contract proof lanes. | Use tags and single-file runs for targeted contract proof instead of broad browser E2E. [VERIFIED: test/test_helper.exs; test/oban_powertools/example_host_contract_test.exs; test/oban_powertools/docs_contract_test.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Frozen historical fixture checked into `examples/` | Replay `mix phx.new` and old installer behavior on every CI run | Replaying old generators would reintroduce toolchain and network drift into the hot proof path, which the locked decisions explicitly reject. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |
| Narrow claim-based docs contract | Full README/guide prose snapshots | Snapshotting whole guides would create brittle test churn around narrative hardening and troubleshooting advice that the library does not guarantee at runtime. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; test/oban_powertools/docs_contract_test.exs] |
| One supported upgrade lane | Multi-host or multi-era compatibility matrix | More lanes would widen the public promise and maintainer burden faster than the current CI proof model can sustain. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Current locked and release metadata above were verified with `mix.lock`, `mix deps`, and `mix hex.info`. [VERIFIED: mix.lock; mix deps; mix hex.info phoenix; mix hex.info oban; mix hex.info oban_web; mix hex.info ecto_sql; mix hex.info ex_doc]

## Architecture Patterns

### System Architecture Diagram

```text
historical source fixture
  -> copy into temp proof host
  -> rewrite local oban_powertools path to current repo
  -> apply documented upgrade actions only
     -> config: add display_policy
     -> docs-aligned checks: keep repo/auth_module/router scope
  -> mix deps.get
  -> mix compile
  -> MIX_ENV=test mix ecto.reset
  -> native post-upgrade proof action
     -> ExUnit assertion
        -> upgrade-proof CI lane

README + guides
  -> support-truth buckets
  -> docs_contract_test.exs
     -> stable claim assertions only
```

The repo already follows a “fixture/harness/tests/workflow/docs” split, so the planner should preserve that split and add the historical source fixture as a new input artifact rather than overloading the canonical current-state fixture. [VERIFIED: examples/phoenix_host/README.md; test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs; .github/workflows/host-contract-proof.yml]

### Recommended Project Structure
```text
examples/
├── phoenix_host/                     # Canonical current-state native-first fixture
└── phoenix_host_upgrade_source/      # Frozen historical source fixture for the one supported lane
test/
├── support/example_host_contract.ex  # Lane harness and fixture preparation
└── oban_powertools/example_host_contract_test.exs
guides/
├── upgrade-and-compatibility.md
├── support-truth-and-ownership-boundaries.md
├── production-hardening.md
└── troubleshooting.md
```

The suggested `phoenix_host_upgrade_source` name is a recommendation, not a locked requirement. [ASSUMED]

### Pattern 1: Frozen Historical Source Fixture
**What:** Check in one archived host tree that represents the exact supported source lane before the explicit `display_policy` contract, and never “manufacture” that starting point by mutating the current fixture during the proof run. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; test/support/example_host_contract.ex]
**When to use:** Use for `upgrade-proof` only; keep `examples/phoenix_host` as the current-state fixture for native-first, first-session, and optional-bridge lanes. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; .github/workflows/host-contract-proof.yml]
**Example:**
```elixir
# Source: test/support/example_host_contract.ex (recommended shape)
source_dir = historical_upgrade_fixture_dir()
target = copy_fixture!(source_dir)
rewrite_powertools_path!(target)
apply_documented_upgrade_steps!(target)
```

### Pattern 2: Reuse the Existing Native Proof Threshold After Upgrade
**What:** After the historical host is upgraded, prove one meaningful native behavior instead of stopping at config inspection or migration success. [VERIFIED: guides/first-operator-session.md; test/oban_powertools/example_host_contract_test.exs]
**When to use:** Use the existing deterministic first-session values unless the planner finds a simpler native action that is equally meaningful and already seeded. [VERIFIED: guides/first-operator-session.md; examples/phoenix_host/README.md]
**Example:**
```elixir
# Source: guides/first-operator-session.md
assert output =~ "ops-demo"
assert output =~ "nightly_sync"
assert output =~ "pause_cron_entry"
```

### Pattern 3: Claim-Based Docs Contract
**What:** Lock the stable public claims, not the whole guide prose. The current docs-contract test already follows this pattern for install commands, route paths, seam names, and support-truth bullets. [VERIFIED: test/oban_powertools/docs_contract_test.exs]
**When to use:** Extend it for lane names, five support-truth buckets, and “best-effort outside tested lanes” wording; do not use it for checklist phrasing or narrative troubleshooting paragraphs. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; test/oban_powertools/docs_contract_test.exs]
**Example:**
```elixir
# Source: test/oban_powertools/docs_contract_test.exs (pattern)
assert source =~ "supported"
assert source =~ "tested"
assert source =~ "best-effort"
```

### Anti-Patterns to Avoid
- **Synthetic upgrade proof:** Deleting and restoring `display_policy` in the current fixture proves a rewrite helper, not a supported upgrade source lane. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs]
- **Phase-number public language:** Docs that tell users to think in “Phase 8/9/10” terms leak internal milestone history instead of describing a host shape they can recognize. [VERIFIED: guides/upgrade-and-compatibility.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
- **Prose snapshot testing:** Hardening and troubleshooting checklists should stay narrative unless a specific runtime guarantee or rejection exists in code. [VERIFIED: guides/production-hardening.md; guides/troubleshooting.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Supported upgrade proof | Ad hoc string surgery against `examples/phoenix_host` | Frozen historical fixture plus documented upgrade steps in the harness | String surgery hides provenance and makes the proof say more than it proves. [VERIFIED: test/support/example_host_contract.ex; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |
| Public support-truth enforcement | Full-guide snapshots | Focused `docs_contract_test.exs` markers | Marker assertions survive editorial improvements while still guarding the contract. [VERIFIED: test/oban_powertools/docs_contract_test.exs; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |
| Historical provenance insurance | Per-PR replay of old generators/installers | Maintainer-only regeneration script tied to an exact commit | Generator replay adds noise from external drift and slows the hot path without strengthening the steady-state contract. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; examples/phoenix_host/regenerate.sh] |

**Key insight:** This phase closes truth gaps by narrowing the promise to exactly one source lane and proving that one lane well; any plan that broadens the matrix or snapshots whole prose guides is working against the locked decisions. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating config restoration as upgrade coverage
**What goes wrong:** The test goes green after re-inserting one config line, but no real historical host shape was exercised. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs]
**Why it happens:** The current helper starts from the already-modern fixture and mutates it in place. [VERIFIED: test/support/example_host_contract.ex]
**How to avoid:** Copy a frozen historical fixture, then apply the same steps the public guide tells maintainers to apply. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
**Warning signs:** The assertions mention `display_policy` presence and migration success but no native operator action. [VERIFIED: test/oban_powertools/example_host_contract_test.exs]

### Pitfall 2: Letting the archived source fixture drift forward
**What goes wrong:** Maintainers “clean up” the historical fixture until it silently becomes a second modern fixture. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
**Why it happens:** Historical fixtures are easy to normalize unless provenance is explicit and regeneration is separated from CI. [VERIFIED: examples/phoenix_host/README.md; examples/phoenix_host/regenerate.sh]
**How to avoid:** Store provenance in the fixture README, name the exact source commit, and keep regeneration as a maintainer-only script. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; examples/phoenix_host/README.md; examples/phoenix_host/regenerate.sh]
**Warning signs:** The archived fixture begins to advertise current support-truth wording or current seam modules without an upgrade step. [ASSUMED]

### Pitfall 3: Over-specifying narrative docs
**What goes wrong:** Small wording edits in hardening or troubleshooting guides break tests and discourage useful documentation improvements. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
**Why it happens:** Docs tests move from claim checking to paragraph snapshots. [VERIFIED: test/oban_powertools/docs_contract_test.exs]
**How to avoid:** Assert the stable nouns and promises: commands, paths, seam names, lane names, support buckets, and best-effort boundaries. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; test/oban_powertools/docs_contract_test.exs]
**Warning signs:** The test starts asserting entire sentences from `production-hardening.md` or `troubleshooting.md`. [ASSUMED]

## Code Examples

Verified patterns from codebase and official docs:

### Phoenix host generation without eager install
```bash
# Source: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html
mix phx.new my_app --database postgres --no-install
```

This is the upstream-supported way to create the host baseline that both the fresh-host proof and the recommended historical provenance story rely on. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] [VERIFIED: test/support/fresh_host_contract.ex]

### Installer-owned config and router contract
```elixir
# Source: lib/mix/tasks/oban_powertools.install.ex
config :oban_powertools,
  repo: MyApp.Repo,
  auth_module: MyAppWeb.ObanPowertoolsAuth,
  display_policy: MyAppWeb.ObanPowertoolsDisplayPolicy
```

```elixir
# Source: lib/mix/tasks/oban_powertools.install.ex
scope "/ops/jobs" do
  pipe_through :browser
  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

These are the exact host-shape claims the upgrade source lane must already satisfy except for the historical absence of `display_policy`. [VERIFIED: lib/mix/tasks/oban_powertools.install.ex; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]

### Tagged ExUnit lane execution
```elixir
# Source: test/oban_powertools/example_host_contract_test.exs
@tag :"upgrade-proof"
test "upgrade lane ..." do
  result = ExampleHostContract.proof!("upgrade")
  assert result.reset_output =~ "Migrated"
end
```

```bash
# Source: https://hexdocs.pm/ex_unit/ExUnit.Case.html
mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof
```

The repo already uses ExUnit tags to keep proof lanes targeted, and that should continue for the rebuilt upgrade lane. [VERIFIED: test/oban_powertools/example_host_contract_test.exs] [CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Synthetic config rewrite against the modern fixture | Frozen historical source fixture plus real post-upgrade native proof | Recommended for Phase 15 because the current synthetic helper is inadequate | This makes `PKG-02` credible without expanding CI into multi-era replay. [VERIFIED: test/support/example_host_contract.ex; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |
| Broad upgrade-source wording tied to internal phase history | One explicit host-shape lane described in public docs | Recommended for Phase 15 because the current guide still says “Phase 8, Phase 9, or Phase 10 contract” | Users can map the promise to their host shape instead of guessing milestone archaeology. [VERIFIED: guides/upgrade-and-compatibility.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |
| Narrow support bullets limited to README/install docs | Five-bucket support-truth language repeated across README and guides | Recommended for Phase 15 by locked decision | This directly closes `HST-03` and keeps `DOC-02` aligned with actual proof depth. [VERIFIED: README.md; guides/support-truth-and-ownership-boundaries.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |

**Deprecated/outdated:**
- “A host installed on the shipped Phase 8, Phase 9, or Phase 10 contract” is outdated public wording because it describes an internal chronology, not the singular supported source lane the phase now requires. [VERIFIED: guides/upgrade-and-compatibility.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `examples/phoenix_host_upgrade_source/` is a suitable name for the archived fixture. [ASSUMED] | Architecture Patterns | Low; the planner can rename the path without changing the architecture. |
| A2 | The archived fixture can still reuse the existing `ops-demo` / `nightly_sync` / `pause_cron_entry` seed lane after upgrade. [ASSUMED] | Summary; Pattern 2 | Medium; if the historical host shape cannot support that seed path cleanly, the planner must choose a different native proof action. |
| A3 | Two future docs-contract warning signs mention exact sentence assertions in `production-hardening.md` and `troubleshooting.md`. [ASSUMED] | Common Pitfalls | Low; this is a planning guardrail, not a product constraint. |

## Open Questions

1. **Which exact commit should define the archived source fixture?**
   - What we know: The fixture must represent a real native-first host before explicit `display_policy` support-truth, and the current repo does not already contain that archived tree. [VERIFIED: test/support/example_host_contract.ex; examples/phoenix_host/README.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
   - What's unclear: The exact historical commit SHA is not recorded yet in repo docs. [VERIFIED: examples/phoenix_host/README.md; git log --oneline --decorate --all --grep='display_policy\\|Phase 11\\|upgrade']
   - Recommendation: Make “choose and document source commit SHA” the first task in the fixture slice, then bake that SHA into the archived fixture README and any maintainer-only regeneration script. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]

2. **Which native action should the rebuilt upgrade lane prove?**
   - What we know: The action must be native, meaningful, deterministic, and aligned with the existing first-session/operator contract. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; guides/first-operator-session.md]
   - What's unclear: The context intentionally leaves the exact action to discretion. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
   - Recommendation: Prefer reusing the existing first-session proof if the upgraded historical fixture can support it without extra seed complexity. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `mix test`, fixture generation, installer, migrations | ✓ | `1.19.5` | — [VERIFIED: elixir --version] |
| Mix | All proof commands and installer task | ✓ | `1.19.5` | — [VERIFIED: mix --version] |
| Erlang/OTP | Underlying runtime for Elixir and Phoenix proofs | ✓ | `28` | — [VERIFIED: erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell] |
| PostgreSQL | `ecto.reset`, migration proof lanes, host-contract tests | ✓ | `14.17`; local server accepting connections on `:5432` | Docker service container in CI [VERIFIED: psql --version; pg_isready] |
| Docker | Optional local reproduction of workflow service topology | ✓ | `29.4.1` | Use the already-running local PostgreSQL instance [VERIFIED: docker --version; pg_isready] |
| Phoenix generator (`mix phx.new`) | Fresh-host proof and historical fixture provenance workflow | ✓ | Available through current toolchain and exercised by `fresh_host_contract_test.exs` | None [VERIFIED: test/support/fresh_host_contract.ex; mix test test/oban_powertools/fresh_host_contract_test.exs] [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: elixir --version; mix --version; pg_isready; docker --version]

**Missing dependencies with fallback:**
- None. [VERIFIED: elixir --version; mix --version; pg_isready; docker --version]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: test/test_helper.exs; mix --version] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/oban_powertools/docs_contract_test.exs`. [VERIFIED: mix test test/oban_powertools/docs_contract_test.exs] |
| Full suite command | `mix test`. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `PKG-02` | Supported upgrade lane starts from a real historical host and proves a native post-upgrade behavior. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof` [VERIFIED: mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof] | ✅ [VERIFIED: test/oban_powertools/example_host_contract_test.exs] |
| `HST-03` | Public docs state supported/tested/best-effort/host-owned/intentionally-unsupported boundaries consistently. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] | integration | `mix test test/oban_powertools/docs_contract_test.exs` [VERIFIED: mix test test/oban_powertools/docs_contract_test.exs] | ✅ [VERIFIED: test/oban_powertools/docs_contract_test.exs] |
| `DOC-02` | Production-hardening and troubleshooting docs reflect real host-owned seams and fail-fast errors without overclaiming runtime guarantees. [VERIFIED: .planning/REQUIREMENTS.md; guides/production-hardening.md; guides/troubleshooting.md] | integration + manual editorial review | `mix test test/oban_powertools/docs_contract_test.exs` [VERIFIED: mix test test/oban_powertools/docs_contract_test.exs] | ✅ [VERIFIED: test/oban_powertools/docs_contract_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/docs_contract_test.exs` or the touched host-contract lane. [VERIFIED: test/oban_powertools/docs_contract_test.exs; test/oban_powertools/example_host_contract_test.exs]
- **Per wave merge:** `mix test test/oban_powertools/example_host_contract_test.exs test/oban_powertools/fresh_host_contract_test.exs test/oban_powertools/docs_contract_test.exs`. [VERIFIED: test/oban_powertools/example_host_contract_test.exs; test/oban_powertools/fresh_host_contract_test.exs; test/oban_powertools/docs_contract_test.exs]
- **Phase gate:** Run the full host-contract proof stack or its local equivalent before `/gsd-verify-work`. [VERIFIED: .github/workflows/host-contract-proof.yml]

### Wave 0 Gaps
- [ ] `test/oban_powertools/docs_contract_test.exs` needs new assertions for the five support-truth buckets and the singular supported upgrade-lane language. [VERIFIED: test/oban_powertools/docs_contract_test.exs; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
- [ ] `test/support/example_host_contract.ex` needs a real historical fixture input instead of `simulate_upgrade_source!/1`. [VERIFIED: test/support/example_host_contract.ex]
- [ ] `test/oban_powertools/example_host_contract_test.exs` needs a stronger post-upgrade native behavior assertion than “`display_policy` restored” plus migration success. [VERIFIED: test/oban_powertools/example_host_contract_test.exs]
- [ ] `.github/workflows/host-contract-proof.yml` may need lane-name or command adjustments if the upgrade fixture path changes. [VERIFIED: .github/workflows/host-contract-proof.yml]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep `auth_module` explicitly host-owned in docs and fixture seams. [VERIFIED: README.md; guides/installation.md; lib/mix/tasks/oban_powertools.install.ex] |
| V3 Session Management | yes | Keep session and browser-pipeline ownership in the host-owned bucket and troubleshooting guide. [VERIFIED: README.md; guides/support-truth-and-ownership-boundaries.md; guides/troubleshooting.md] |
| V4 Access Control | yes | Native pages remain the supported mutation surface, and the bridge stays read-only. [VERIFIED: README.md; guides/first-operator-session.md; guides/optional-oban-web-bridge.md] |
| V5 Input Validation | yes | Missing `repo`, `auth_module`, and `display_policy` already fail fast through runtime config checks. [VERIFIED: lib/oban_powertools/runtime_config.ex; guides/troubleshooting.md] |
| V6 Cryptography | no | No crypto surface is introduced by this phase; do not expand the docs into cryptographic guarantees. [ASSUMED] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Hidden fallback assumptions when required config is missing | Tampering / Elevation | Keep explicit fail-fast runtime errors and repeat them in troubleshooting docs. [VERIFIED: lib/oban_powertools/runtime_config.ex; guides/troubleshooting.md] |
| Bridge presented as a co-equal write surface | Elevation | Keep the bridge read-only in README, guides, and docs-contract assertions. [VERIFIED: README.md; guides/optional-oban-web-bridge.md; test/oban_powertools/docs_contract_test.exs] |
| Host auth/session ownership blurred into library responsibility | Spoofing / Elevation | Repeat host-owned auth, router, browser pipeline, and session boundaries across README and guides. [VERIFIED: README.md; guides/support-truth-and-ownership-boundaries.md; guides/production-hardening.md] |
| Overstated compatibility promise beyond tested lanes | Repudiation | Name only one supported upgrade lane and mark the rest best-effort. [VERIFIED: guides/upgrade-and-compatibility.md; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md` - locked decisions, proof architecture, support-truth buckets, and scope boundaries. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - phase requirement ownership and milestone posture. [VERIFIED: .planning/REQUIREMENTS.md; .planning/ROADMAP.md; .planning/STATE.md]
- `test/support/example_host_contract.ex`, `test/oban_powertools/example_host_contract_test.exs`, `test/oban_powertools/docs_contract_test.exs`, `.github/workflows/host-contract-proof.yml` - current proof mechanics and present upgrade/docs gaps. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs; test/oban_powertools/docs_contract_test.exs; .github/workflows/host-contract-proof.yml]
- `README.md`, `guides/*.md`, `examples/phoenix_host/README.md`, `lib/mix/tasks/oban_powertools.install.ex`, `lib/oban_powertools/runtime_config.ex` - public contract language, installer-owned seams, and fail-fast runtime boundaries. [VERIFIED: README.md; guides/installation.md; guides/first-operator-session.md; guides/upgrade-and-compatibility.md; guides/support-truth-and-ownership-boundaries.md; guides/production-hardening.md; guides/troubleshooting.md; guides/example-app-walkthrough.md; examples/phoenix_host/README.md; lib/mix/tasks/oban_powertools.install.ex; lib/oban_powertools/runtime_config.ex]
- Local toolchain and proof runs - `mix test test/oban_powertools/docs_contract_test.exs`, `mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof`, `mix test test/oban_powertools/fresh_host_contract_test.exs`, `mix --version`, `elixir --version`, `pg_isready`, `docker --version`, `mix hex.info *`. [VERIFIED: mix test test/oban_powertools/docs_contract_test.exs; mix test test/oban_powertools/example_host_contract_test.exs --only upgrade-proof; mix test test/oban_powertools/fresh_host_contract_test.exs; mix --version; elixir --version; pg_isready; docker --version; mix hex.info phoenix; mix hex.info oban; mix hex.info oban_web; mix hex.info ecto_sql; mix hex.info ex_doc]
- Phoenix and ExUnit official docs - `mix phx.new` options and ExUnit tag behavior. [CITED: https://hexdocs.pm/phoenix/Mix.Tasks.Phx.New.html; CITED: https://hexdocs.pm/ex_unit/ExUnit.Case.html]

### Secondary (MEDIUM confidence)
- None. [VERIFIED: research session]

### Tertiary (LOW confidence)
- None beyond the explicit assumptions logged above. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - locked versions, local environment, and current Hex release metadata were all verified directly. [VERIFIED: mix.lock; mix deps; mix --version; elixir --version; mix hex.info phoenix; mix hex.info oban; mix hex.info oban_web; mix hex.info ecto_sql; mix hex.info ex_doc]
- Architecture: HIGH - the current harness, workflow, and guide surfaces make the synthetic gap and the required replacement pattern explicit. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs; .github/workflows/host-contract-proof.yml; .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md]
- Pitfalls: MEDIUM - the present synthetic helper and narrow docs assertions are verified, but a couple of future warning-sign examples are intentionally marked assumed. [VERIFIED: test/support/example_host_contract.ex; test/oban_powertools/docs_contract_test.exs; ASSUMED]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 for repo-internal architecture, 2026-05-30 for Hex release metadata. [VERIFIED: .planning/phases/15-upgrade-lane-support-truth-public-docs-integrity/15-CONTEXT.md; mix hex.info phoenix; mix hex.info oban; mix hex.info oban_web; mix hex.info ecto_sql; mix hex.info ex_doc]
