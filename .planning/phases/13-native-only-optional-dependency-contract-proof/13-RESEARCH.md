# Phase 13: native-only-optional-dependency-contract-proof - Research

**Researched:** 2026-05-23
**Domain:** Phoenix host-contract proof for optional `oban_web` support
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

All bullets in this section are copied verbatim from `.planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md`. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md]

### Locked Decisions
- **D-01:** Shift recommendations left by default for this project and within GSD. Downstream agents should treat the recommendations here as locked defaults unless a later choice would materially change public contract shape, support truth, or maintainer burden.
- **D-02:** Phase 13 should optimize for least surprise, support-truth honesty, and host-owned explicitness over proof theatrics or broader bridge ambition.

### Native-Only Proof Strictness
- **D-03:** `native-only` must mean `oban_web` is actually absent from the proof host for that lane, not merely present-but-unused.
- **D-04:** The canonical native-only proof should remove `oban_web` from the copied proof host before `mix deps.get`, then run the normal compile/reset/native-proof flow.
- **D-05:** A supplemental `--no-optional-deps` style compile check is welcome later as an extra guard, but it is not the primary definition of native-only truth.
- **D-06:** Do not redefine Phase 13 around “native screens do not call bridge code.” The requirement is stronger: host apps that omit `oban_web` entirely must still compile and verify cleanly.

### Proof Host Shape
- **D-07:** Keep one canonical curated fixture host as the primary proof host for Phase 13.
- **D-08:** Preserve the separate fresh-host installer lane as the day-0 generator backstop, but do not replace the canonical fixture with generated-per-lane hosts for this phase.
- **D-09:** Allow only narrow, auditable lane rewrites in the proof harness:
  dependency presence/absence,
  and similarly small contract toggles if needed.
  Do not let the harness evolve into a hidden second fixture generator.
- **D-10:** Do not introduce separate checked-in native-only and bridge-enabled fixture trees unless a future phase intentionally changes the public host contract into multiple supported host shapes.

### Bridge-Enabled Regression Scope
- **D-11:** The bridge-enabled lane should prove a bounded host contract plus one render smoke, not parity with native Powertools pages and not broad upstream-UI behavior.
- **D-12:** The bridge lane should cover only Powertools-owned seams that materially affect host trust:
  dependency-gated nested mount shape,
  resolver wiring,
  shared `on_mount`/auth path,
  enforced read-only access,
  shared display-policy formatting hooks,
  and one successful bridge render under the fixture host.
- **D-13:** Do not add richer bridge interaction assertions that would couple the suite to Oban Web internals, upstream UI churn, or a broader support promise than the project intends.

### Docs and Support-Truth Posture
- **D-14:** Native `/ops/jobs` is the default paved road and the supported mutation surface.
- **D-15:** The optional `/ops/jobs/oban` bridge should be documented as an additive read-only inspection annex, not as a co-equal product surface and not as the default mental model.
- **D-16:** Docs should still acknowledge two tested lanes, but the wording should not imply equal semantic weight between them.
- **D-17:** Recommended default wording:
  Oban Powertools ships a native, host-owned operator shell at `/ops/jobs`.
  `oban_web` is optional; when installed, Powertools mounts a nested read-only Oban Web bridge at `/ops/jobs/oban` for additional inspection.
  Native Powertools pages are the supported mutation surface.
  The host owns router scope, browser pipeline, auth, display policy, and runtime config.

### the agent's Discretion
- Exact proof-harness implementation for removing `oban_web` from the copied host, provided the behavior is narrow, obvious, and documented.
- Exact smoke-proof shape for the bridge-enabled lane, provided it proves a real render without asserting broad Oban Web internals.
- Exact docs section edits and test-marker wording, provided the native-first support truth above remains intact everywhere.

### Deferred Ideas (OUT OF SCOPE)
- Adding a second checked-in native-only fixture tree — defer unless a future phase intentionally broadens the support matrix.
- Broad bridge parity tests or browser-E2E coverage over Oban Web internals — out of scope for Phase 13.
- Reframing the bridge as the default operator plane — conflicts with the native mutation ownership contract and belongs in a future strategic pivot, not this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `PKG-03` | A host app can run Oban Powertools with or without `oban_web` installed, with the optional-path behavior documented and continuously verifiable. [VERIFIED: .planning/REQUIREMENTS.md] | Remove `oban_web` from the copied fixture before `mix deps.get`, keep router gating as-is, add an optional `mix compile --no-optional-deps --warnings-as-errors` supplemental check, and keep a separate bridge-enabled lane with one real render smoke. [VERIFIED: test/support/example_host_contract.ex; lib/oban_powertools/web/router.ex] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |
| `DOC-03` | Maintainers can verify the public host contract with automated proof that covers optional dependency paths, route/auth integration, and support-truth regressions. [VERIFIED: .planning/REQUIREMENTS.md] | Align docs markers, docs-contract assertions, and workflow lane names to a native-first story; preserve `fresh-host` as a separate installer proof; extend bridge proof only to one real render smoke plus existing resolver/read-only assertions. [VERIFIED: test/oban_powertools/docs_contract_test.exs; .github/workflows/host-contract-proof.yml; test/oban_powertools/web/router_test.exs] |
</phase_requirements>

## Summary

Phase 13 is a proof-contract cleanup phase, not a new product-surface phase. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] The current router and bridge modules already implement the bounded optional bridge contract at compile time, but the current proof harness does not yet prove a host with `oban_web` actually removed before dependency resolution. [VERIFIED: lib/oban_powertools/web/router.ex; lib/oban_powertools/web/oban_web_bridge.ex; test/support/example_host_contract.ex]

Today the `native-only` lane copies `examples/phoenix_host`, leaves `{:oban_web, "~> 2.10", optional: true}` in the copied `mix.exs`, runs `mix deps.get`, and still passes its test, so the lane proves "present but optional" rather than "absent from the host." [VERIFIED: examples/phoenix_host/mix.exs; test/support/example_host_contract.ex; test/oban_powertools/example_host_contract_test.exs; `MIX_ENV=test mix run -e ... prepare_host!(\"native-only\")`; `mix test test/oban_powertools/example_host_contract_test.exs --only native-only`] Mix's official docs state that an `:optional` dependency is still included by the current project and recommend `mix compile --no-optional-deps --warnings-as-errors` as an extra guard when you want to ensure compilation without optional dependencies. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] That makes the planning answer straightforward: Phase 13 must physically mutate the copied fixture for the native lane before `mix deps.get`, and it may add the `--no-optional-deps` compile as a secondary check, not the primary proof. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

The other half of the phase is support-truth alignment. The repo already has strong route, resolver, and read-only assertions plus a separate `fresh-host` installer lane. [VERIFIED: test/oban_powertools/web/router_test.exs; test/support/fresh_host_contract.ex; .github/workflows/host-contract-proof.yml] What is missing is one real bridge-enabled render under the canonical fixture and consistent native-first wording across README, guides, docs-contract markers, and workflow lane naming. [VERIFIED: test/oban_powertools/example_host_contract_test.exs; README.md; guides/installation.md; guides/first-operator-session.md; guides/optional-oban-web-bridge.md; guides/upgrade-and-compatibility.md; test/oban_powertools/docs_contract_test.exs]

**Primary recommendation:** Mutate only the copied fixture host for the `native-only` lane by removing `oban_web` before `mix deps.get`, then run `mix deps.unlock --unused` in that temp dir as the Phase 13 default lock cleanup, add one fixture-backed bridge render smoke, and tighten docs/CI wording around a native-first, bridge-optional support story. [VERIFIED: test/support/example_host_contract.ex; examples/phoenix_host/mix.exs; .github/workflows/host-contract-proof.yml] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Loadpaths.html]

## Project Constraints

- No repo-root `AGENTS.md` is present. [VERIFIED: filesystem]
- No repo-root `CLAUDE.md` is present. [VERIFIED: filesystem]
- No project-local `.claude/skills/` or `.agents/skills/` directory is present at the repo root. [VERIFIED: filesystem]
- `examples/phoenix_host/AGENTS.md` requires `mix precommit` after code changes in the proof host and prefers the already included `Req` client over `:httpoison`, `:tesla`, and `:httpc`. [VERIFIED: examples/phoenix_host/AGENTS.md]
- `examples/phoenix_host/AGENTS.md` also carries Phoenix 1.8 / Elixir testing and routing rules that matter if Phase 13 touches the example host or its tests, including host-owned router scope discipline and `start_supervised!/1` for tests. [VERIFIED: examples/phoenix_host/AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Remove `oban_web` before native-lane dependency resolution | API / Backend | Frontend Server (SSR) | The proof harness in `test/support/example_host_contract.ex` owns temp-fixture preparation and Mix command orchestration, while the resulting compile path exercises the Phoenix host. [VERIFIED: test/support/example_host_contract.ex] |
| Keep Powertools routes compiling when `oban_web` is absent | Frontend Server (SSR) | — | The compile-time route macro in `ObanPowertools.Web.Router` decides whether the nested bridge mount exists by checking whether `Oban.Web.Router` is loaded. [VERIFIED: lib/oban_powertools/web/router.ex] |
| Prove one real bridge-enabled render | Frontend Server (SSR) | Database / Storage | A realistic smoke proof should render `/ops/jobs/oban` through the example host and shared auth session, using seeded state where needed. [VERIFIED: test/oban_powertools/web/router_test.exs; examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs] |
| Preserve read-only, shared auth, and display-policy seams | Frontend Server (SSR) | API / Backend | The bridge contract is implemented through `ObanPowertools.Web.ObanWebBridge` and `on_mount` wiring, not through host-specific UI code. [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex; lib/oban_powertools/web/router.ex; test/oban_powertools/web/router_test.exs] |
| Align docs, docs-contract tests, and CI lane names | API / Backend | — | The contract markers live in Markdown, ExUnit docs checks, and GitHub Actions job names, so the planner should treat this as automation and public-contract work, not app runtime work. [VERIFIED: README.md; guides/installation.md; guides/upgrade-and-compatibility.md; test/oban_powertools/docs_contract_test.exs; .github/workflows/host-contract-proof.yml] |
| Preserve the separate fresh-host installer proof | API / Backend | — | The fresh-host path is already isolated in `test/support/fresh_host_contract.ex` and a dedicated workflow job, and the phase context explicitly says not to fold it into the canonical fixture proof. [VERIFIED: test/support/fresh_host_contract.ex; .github/workflows/host-contract-proof.yml; .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | `1.19.5` locally; project requires `~> 1.19` | Dependency resolution, compile flags, and test orchestration for the proof lanes. [VERIFIED: `elixir --version`; `mix --version`; mix.exs] | Phase 13 depends directly on Mix optional-dependency semantics and compile flags. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Loadpaths.html] |
| Phoenix | `1.8.7` | Host router scope and mounted LiveView/bridge routing. [VERIFIED: `mix deps`; examples/phoenix_host/mix.exs] | The public contract is a Phoenix-mounted host shell at `/ops/jobs`. [VERIFIED: README.md; guides/installation.md] |
| Phoenix LiveView | `1.1.30` | Native page proof and the recommended low-cost way to assert one real bridge render. [VERIFIED: `mix deps`; examples/phoenix_host/mix.exs] | The repo already uses `Phoenix.LiveViewTest.live/2` for real fixture-backed operator proof instead of browser E2E. [VERIFIED: examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs] |
| Oban | `2.22.1` | Host runtime surface the library augments. [VERIFIED: `mix deps`] | The optional bridge is explicitly a bounded adapter over Oban Web, not a replacement runtime. [VERIFIED: .planning/MILESTONE-ARC.md; .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md] |
| Oban Web | `2.12.4` in the repo lock; dependency remains optional | Optional nested inspection bridge under `/ops/jobs/oban`. [VERIFIED: `mix deps`; examples/phoenix_host/mix.exs; examples/phoenix_host/mix.lock] | Phase 13 must prove the library works both with the dependency present and absent. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled with Elixir | Primary proof framework for lane and docs contract tests. [VERIFIED: test/oban_powertools/example_host_contract_test.exs; test/oban_powertools/docs_contract_test.exs] | Use for all Phase 13 verification; no new test framework is needed. [VERIFIED: repo test layout] |
| PostgreSQL / Ecto reset path | local client `14.17`; host uses `ecto.reset` | Required by the current proof harness because the fixture proof includes reset and seed commands. [VERIFIED: `psql --version`; `pg_isready --version`; test/support/example_host_contract.ex] | Keep this for native-only and bridge-enabled lanes; it proves the host contract past compile. [VERIFIED: test/support/example_host_contract.ex] |
| GitHub Actions matrix jobs | current workflow `Host Contract Proof` | CI source of truth for lane names and support-truth automation. [VERIFIED: .github/workflows/host-contract-proof.yml] | Use existing jobs; rename or reword only enough to reflect the native-first story honestly. [VERIFIED: test/oban_powertools/docs_contract_test.exs; .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Mutating the copied fixture `mix.exs` for `native-only` | Rely only on `mix compile --no-optional-deps` | This is a useful guard but not the primary proof, because Mix still includes optional deps in the current project unless they are absent from the host dependency list. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |
| One canonical fixture with narrow lane rewrites | Separate checked-in native-only and bridge-enabled fixtures | This would overfit the proof infrastructure and violate the locked phase decision to avoid multiple canonical hosts. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] |
| LiveView render smoke for the bridge | Browser E2E around Oban Web internals | Browser E2E would broaden the support promise and couple the suite to upstream UI churn. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] |

**Installation:** The repo already carries the required stack in `mix.exs` and `examples/phoenix_host/mix.exs`; Phase 13 should not add dependencies. [VERIFIED: mix.exs; examples/phoenix_host/mix.exs]

**Version verification:** Current repo-resolved versions are `phoenix 1.8.7`, `phoenix_live_view 1.1.30`, `oban 2.22.1`, and `oban_web 2.12.4`. [VERIFIED: `mix deps`] Hex package pages also show `oban 2.22.1` updated on 2026-04-30, `phoenix_live_view 1.1.30` updated on 2026-05-05, and `oban_web 2.12.4` updated on 2026-05-11. [CITED: https://hex.pm/packages/oban] [CITED: https://hex.pm/packages/phoenix_live_view] [CITED: https://hex.pm/packages/oban_web]

## Architecture Patterns

### System Architecture Diagram

```text
Native-only lane
example fixture copy
  -> narrow lane rewrite removes `oban_web` from copied `mix.exs`
  -> temp-dir lock cleanup with `mix deps.unlock --unused`
  -> `mix deps.get`
  -> `mix compile`
  -> `MIX_ENV=test mix ecto.reset`
  -> native proof test or existing compile/reset assertions
  -> result proves host compiles without the optional dependency present

Bridge-enabled lane
example fixture copy
  -> preserve `oban_web` dependency
  -> `mix deps.get`
  -> `mix compile`
  -> `MIX_ENV=test mix ecto.reset`
  -> fixture-backed render smoke at `/ops/jobs/oban`
  -> existing router/resolver/read-only assertions
  -> result proves bounded bridge contract when dependency is installed

Cross-cutting contract lane
README + guides + workflow names
  -> docs contract test
  -> CI job labels
  -> native-first public support story stays aligned with proof behavior
```

### Recommended Project Structure
```text
test/
├── support/
│   ├── example_host_contract.ex      # Canonical fixture lane preparation and command orchestration
│   └── fresh_host_contract.ex        # Separate installer-backed fresh-host proof
├── oban_powertools/
│   ├── example_host_contract_test.exs # Native-only, bridge-enabled, upgrade, first-session lanes
│   ├── docs_contract_test.exs         # Public wording and workflow markers
│   └── web/router_test.exs            # Route, resolver, and read-only bridge contract
examples/
└── phoenix_host/
    ├── mix.exs                        # Canonical fixture dependency list
    └── test/phoenix_host_web/         # Fixture-backed LiveView proof
```

### Pattern 1: Narrow Temp-Fixture Lane Mutation
**What:** Mutate only the copied fixture host for lane-specific dependency truth, keeping the checked-in fixture canonical. [VERIFIED: test/support/example_host_contract.ex; .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md]
**When to use:** Use for `native-only` to remove `oban_web` before dependency resolution, then run `mix deps.unlock --unused` in the temp copy as the default stale-lock cleanup; do not use it as a general-purpose generator. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html]
**Example:**
```elixir
# Source pattern: test/support/example_host_contract.ex
defp prepare_host!(lane) do
  target = copy_fixture_to_temp!()
  rewrite_powertools_path!(target)

  case lane do
    "native-only" ->
      remove_optional_oban_web_dependency!(target)
      unlock_unused_dep!(target, "oban_web")

    "upgrade" ->
      simulate_upgrade_source!(target)

    _ ->
      :ok
  end

  target
end
```

### Pattern 2: Compile-Time Bridge Gating In The Router Macro
**What:** Keep the current compile-time `Code.ensure_loaded?` gate in `ObanPowertools.Web.Router` as the authoritative runtime contract. [VERIFIED: lib/oban_powertools/web/router.ex]
**When to use:** Use whenever the proof needs to assert behavior with `oban_web` absent or present; do not duplicate the logic elsewhere. [VERIFIED: lib/oban_powertools/web/router.ex]
**Example:**
```elixir
# Source: lib/oban_powertools/web/router.ex
oban_web_router = Module.concat([Oban, Web, Router])

bridge_routes =
  if Code.ensure_loaded?(oban_web_router) do
    quote do
      import unquote(oban_web_router), only: [oban_dashboard: 2]

      oban_dashboard(path,
        resolver: ObanPowertools.Web.ObanWebBridge,
        on_mount: [ObanPowertools.Web.LiveAuth]
      )
    end
  else
    quote(do: nil)
  end
```

### Pattern 3: Real Render Smoke Without Broadening The Promise
**What:** Reuse the existing fixture-backed `Phoenix.LiveViewTest` approach to prove exactly one successful bridge render with a real host session. [VERIFIED: examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs]
**When to use:** Use only in the `bridge-enabled` lane; keep assertions to mount success, auth/session continuity, and read-only framing. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md]
**Example:**
```elixir
# Source pattern: examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs
actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()
conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

{:ok, _view, html} = live(conn, "/ops/jobs/oban")

assert html =~ "Oban Web"
assert html =~ "read-only"
```

### Anti-Patterns to Avoid
- **Lane name theater:** A `native-only` tag without physically removing `oban_web` from the copied host is not native-only proof. [VERIFIED: test/support/example_host_contract.ex; examples/phoenix_host/mix.exs]
- **Harness creep:** Adding many lane-specific rewrites or generating host structure inside `ExampleHostContract` would create a second generator and violate the phase boundary. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md]
- **Bridge parity assertions:** Testing broad Oban Web UI behavior or mutations would widen the support promise beyond what the docs intend. [VERIFIED: .planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md; .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md]
- **Fresh-host conflation:** Replacing the dedicated `fresh-host` lane with more fixture mutations would erase the distinction between installer proof and canonical-host proof. [VERIFIED: test/support/fresh_host_contract.ex; .github/workflows/host-contract-proof.yml]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Proving optional dependency absence | A second checked-in host fixture or a hidden mini-generator | A single, explicit temp-dir rewrite of the copied fixture plus existing Mix commands. [VERIFIED: test/support/example_host_contract.ex; .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] | The repo already has the right proof boundary; more infrastructure would create divergence and maintenance drag. [VERIFIED: Phase 13 context + existing harness] |
| Handling stale lock entries after removing `oban_web` | Custom lockfile parsers | `mix deps.unlock --unused` or equivalent temp-dir cleanup. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html] [VERIFIED: `mix help deps.unlock`] | Mix already exposes a first-party way to remove unused lock entries in CI or pre-commit flows. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html] |
| Proving no optional deps at compile time | Ad hoc shell checks around compiled beam artifacts | `mix compile --no-optional-deps --warnings-as-errors` as a supplemental guard. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Loadpaths.html] | Mix already documents the intended flag for this exact concern. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |
| Bridge-enabled smoke proof | Browser automation over Oban Web internals | Existing `Phoenix.LiveViewTest` fixture-backed render assertions. [VERIFIED: examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs] | LiveViewTest is already the repo’s proven, low-cost integration proof style. [VERIFIED: repo tests] |
| Docs drift protection | Manual review only | `test/oban_powertools/docs_contract_test.exs` plus workflow job-name assertions. [VERIFIED: test/oban_powertools/docs_contract_test.exs] | The repo already has an automated wording guardrail; Phase 13 should extend it, not replace it. [VERIFIED: docs contract test] |

**Key insight:** The cheapest truthful Phase 13 plan reuses the existing router gate, fixture harness, LiveView proof style, and docs contract tests; it only tightens what each lane actually means. [VERIFIED: lib/oban_powertools/web/router.ex; test/support/example_host_contract.ex; test/oban_powertools/docs_contract_test.exs]

## Common Pitfalls

### Pitfall 1: Removing `oban_web` Too Late
**What goes wrong:** The proof lane still resolves `oban_web` because the copied host keeps the dependency declaration through `mix deps.get`. [VERIFIED: test/support/example_host_contract.ex; examples/phoenix_host/mix.exs]
**Why it happens:** Mix treats an `:optional` dependency as included in the current project; optional only affects downstream dependents. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]
**How to avoid:** Remove the dependency from the copied fixture before `mix deps.get`, then run `mix deps.unlock --unused` in that temp dir so the proof host and lockfile both reflect the lane truth. [VERIFIED: local temp-fixture experiment removing `:oban_web` from copied `mix.exs` followed by `MIX_ENV=test mix deps.get && MIX_ENV=test mix deps`] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html]
**Warning signs:** The copied `mix.exs` still contains `:oban_web`, or `mix deps` in the temp host still lists `oban_web`. [VERIFIED: `MIX_ENV=test mix run -e ... prepare_host!(\"native-only\")`; local temp-fixture experiment]

### Pitfall 2: Letting `ExampleHostContract` Become A Generator
**What goes wrong:** Lane setup starts writing auth modules, router code, or broad config rewrites, duplicating the role of the installer and fresh-host lane. [VERIFIED: contrast between test/support/example_host_contract.ex and test/support/fresh_host_contract.ex]
**Why it happens:** The proof harness already owns temp-dir file mutation, so it is easy to keep adding "just one more rewrite." [VERIFIED: test/support/example_host_contract.ex]
**How to avoid:** Restrict Phase 13 edits to dependency presence/absence and similarly tiny contract toggles only. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md]
**Warning signs:** New helpers start writing multiple source files or reproducing `fresh_host_contract.ex` behavior. [VERIFIED: current harness shapes]

### Pitfall 3: Broadening Bridge Support By Accident
**What goes wrong:** The proof suite starts asserting Oban Web UI details or interactions that Powertools does not own. [VERIFIED: .planning/phases/9-policy-boundaries-optional-bridge-contracts/9-CONTEXT.md; .planning/phases/10-operator-ux-coherence-mutation-safety/10-CONTEXT.md]
**Why it happens:** Once one real render smoke exists, it is tempting to add more assertions from the rendered HTML. [ASSUMED]
**How to avoid:** Keep the smoke to mount success, shared auth/session continuity, shared display-policy path, and explicit read-only framing. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md; test/oban_powertools/web/router_test.exs]
**Warning signs:** Assertions mention unsupported mutations, generic Oban Web nav structure, or broad table semantics. [VERIFIED: Phase 13 bridge scope decisions]

### Pitfall 4: Docs And Workflow Labels Staying Symmetric
**What goes wrong:** README, guides, and job names keep implying that `native-only` and `bridge-enabled` are co-equal product surfaces. [VERIFIED: guides/upgrade-and-compatibility.md; .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md]
**Why it happens:** The current docs correctly mention two tested lanes, but some wording is still lane-symmetric rather than native-first. [VERIFIED: guides/upgrade-and-compatibility.md; README.md]
**How to avoid:** Lead with `/ops/jobs` as the default paved road, describe `/ops/jobs/oban` as an additive inspection annex, and update docs-contract markers to enforce that wording. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md; test/oban_powertools/docs_contract_test.exs]
**Warning signs:** Phrases like "tested native-only lane and tested bridge-enabled lane are the only lanes this phase proves directly" remain the top-level support message without native-first framing around them. [VERIFIED: guides/upgrade-and-compatibility.md]

## Code Examples

Verified patterns from official sources and the current codebase:

### Remove An Unused Optional Dependency From The Temp Fixture
```elixir
# Source pattern: test/support/example_host_contract.ex
defp remove_optional_oban_web_dependency!(dir) do
  mix_path = Path.join(dir, "mix.exs")
  source = File.read!(mix_path)

  updated =
    String.replace(source, ~r/\n\s*\{:oban_web,\s*"~> 2\.10",\s*optional:\s*true\},?/, "")

  if updated == source do
    raise "failed to remove oban_web dependency from native-only fixture"
  end

  File.write!(mix_path, updated)
  _ = run!(dir, [], "mix", ["deps.unlock", "--unused"])
end
```

### Supplemental Compile Guard For Missing Optional Deps
```bash
# Source: Mix docs
mix compile --no-optional-deps --warnings-as-errors
```

### Real Bridge Render Smoke In The Fixture Host
```elixir
# Source pattern: examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs
actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()
conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

{:ok, _view, html} = live(conn, "/ops/jobs/oban")

assert html =~ "Oban Web"
assert html =~ "read-only"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Native-only meant "do not use the bridge" while still shipping `oban_web` in the copied host. [VERIFIED: current `native-only` lane code and fixture] | Native-only should mean the copied host omits `oban_web` before dependency resolution. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] | Locked in Phase 13 context on 2026-05-23. [VERIFIED: 13-CONTEXT.md] | This closes the audit gap on `PKG-03` and makes the lane name truthful. [VERIFIED: .planning/milestones/v1.1-MILESTONE-AUDIT.md] |
| Source-level route/resolver assertions only. [VERIFIED: test/oban_powertools/web/router_test.exs] | Source-level assertions plus one real bridge render smoke under the canonical fixture. [VERIFIED: Phase 13 context] | Required by Phase 13 planning. [VERIFIED: 13-CONTEXT.md] | This proves the bounded bridge contract without implying parity support. [VERIFIED: Phase 13 context + Phase 10 context] |
| Symmetric language about tested lanes. [VERIFIED: guides/upgrade-and-compatibility.md] | Native-first wording with the bridge described as additive and narrower. [VERIFIED: 13-CONTEXT.md] | Locked in Phase 13 context on 2026-05-23. [VERIFIED: 13-CONTEXT.md] | Docs, docs tests, and CI names all need alignment. [VERIFIED: README.md; guides/*.md; test/oban_powertools/docs_contract_test.exs; workflow] |

**Deprecated/outdated:**
- Treating `native-only` as satisfied by the current `ExampleHostContract.proof!("native-only")` flow is outdated because that flow keeps `:oban_web` in the copied fixture and runs `mix deps.get` unchanged. [VERIFIED: test/support/example_host_contract.ex; examples/phoenix_host/mix.exs]
- Treating `mix compile --no-optional-deps` as the whole proof would be incomplete for this phase because the locked decision explicitly makes it a secondary guard rather than the primary definition. [VERIFIED: .planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Once one bridge render smoke exists, future contributors may be tempted to add broader Oban Web assertions. [ASSUMED] | Common Pitfalls | Low; this affects plan guardrails, not code correctness. |

## Open Questions (RESOLVED)

1. **Should the native-only temp fixture also remove the stale `oban_web` lock entry? RESOLVED: yes.**
   - What we know: Removing `:oban_web` from the copied `mix.exs` before `mix deps.get` is enough for `mix deps` in the temp host to omit `oban_web`, even if the copied fixture started with a lockfile. [VERIFIED: local temp-fixture experiment]
   - Resolution: Phase 13 uses `mix deps.unlock --unused` in the temp dir as the default lock-cleanup step after the dependency rewrite. This keeps the proof narrow, uses the documented Mix behavior, and leaves clearer temporary proof artifacts without changing the checked-in fixture. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, tests, fixture proof | ✓ | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | `deps.get`, `compile`, `ecto.reset`, test lanes | ✓ | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL client tools | Local proof debugging and parity with CI reset path | ✓ | `psql 14.17`, `pg_isready 14.17` [VERIFIED: command output] | CI uses service containers if local DB setup differs. [VERIFIED: workflow] |
| Docker | Mirrors CI service-container posture when reproducing workflow behavior locally | ✓ | `29.4.1` [VERIFIED: `docker --version`] | Native local Postgres also works for repo tests. [VERIFIED: existing local test pass + workflow services] |
| GitHub CLI | Optional for CI inspection only | ✓ | `2.89.0` [VERIFIED: `gh --version`] | Use GitHub UI or raw workflow file. [VERIFIED: workflow file exists locally] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- None found. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix test. [VERIFIED: mix.exs; test files] |
| Config file | none dedicated; test support is loaded via `elixirc_paths(:test)` and `test/test_helper.exs`. [VERIFIED: mix.exs; examples/phoenix_host/test/test_helper.exs] |
| Quick run command | `mix test test/oban_powertools/example_host_contract_test.exs --only native-only` for the narrowest lane check. [VERIFIED: workflow; local test pass] |
| Full suite command | `mix test`. [VERIFIED: Mix project layout] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `PKG-03` | Native-only host compiles/resets with `oban_web` absent, and bridge-enabled host still renders the bounded bridge when present. [VERIFIED: requirements + phase context] | integration | `mix test test/oban_powertools/example_host_contract_test.exs --only native-only` and `mix test test/oban_powertools/example_host_contract_test.exs --only bridge-enabled` plus a new fixture bridge smoke assertion. [VERIFIED: workflow; existing test file] | ✅ existing file, bridge smoke expansion needed |
| `DOC-03` | Public docs, workflow names, route/auth integration, and support-truth markers stay aligned with the tested contract. [VERIFIED: requirements + docs contract test] | unit/integration | `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs` [VERIFIED: workflow] | ✅ |

### Sampling Rate
- **Per task commit:** `mix test test/oban_powertools/docs_contract_test.exs test/oban_powertools/web/router_test.exs`
- **Per wave merge:** `mix test test/oban_powertools/example_host_contract_test.exs test/oban_powertools/fresh_host_contract_test.exs`
- **Phase gate:** `mix test` and the `Host Contract Proof` workflow lanes green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] Extend `test/oban_powertools/example_host_contract_test.exs` or the fixture host test it invokes to assert one real `/ops/jobs/oban` render in the `bridge-enabled` lane. [VERIFIED: current file lacks a render smoke]
- [ ] Extend `test/oban_powertools/docs_contract_test.exs` markers so native-first wording is enforced instead of only generic lane presence. [VERIFIED: current assertions check lane/job names and broad support markers only]
- [ ] Decide and implement one narrow temp-dir lock cleanup step for `native-only` if the planner wants lockfile truth in addition to dependency-list truth. [VERIFIED: open question above]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep bridge and native proofs behind the shared host-owned actor/session seam via `ObanPowertools.Web.LiveAuth` and example-host auth modules. [VERIFIED: lib/oban_powertools/web/router.ex; examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs] |
| V3 Session Management | yes | Use real session initialization in fixture tests instead of bypassing host session/auth flow. [VERIFIED: examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs] |
| V4 Access Control | yes | Preserve `ObanPowertools.Web.ObanWebBridge.resolve_access/1` returning `:read_only` or redirect-forbidden outcomes only. [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex; test/oban_powertools/web/router_test.exs] |
| V5 Input Validation | yes | Keep fixture rewrites narrow and deterministic; avoid free-form generator behavior in the harness. [VERIFIED: test/support/example_host_contract.ex; Phase 13 context] |
| V6 Cryptography | no | Phase 13 does not add or modify cryptographic behavior. [VERIFIED: phase scope and current target files] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Bridge accidentally grants write access when `oban_web` is present | Elevation of privilege | Keep resolver mapping to `:read_only` only and assert it in router tests plus render smoke. [VERIFIED: lib/oban_powertools/web/oban_web_bridge.ex; test/oban_powertools/web/router_test.exs] |
| Native-only lane silently keeps the optional dependency installed | Tampering | Remove `oban_web` before `mix deps.get`, and optionally add `mix compile --no-optional-deps --warnings-as-errors`. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [VERIFIED: Phase 13 context] |
| Docs overstate supported behavior compared with CI | Repudiation | Keep docs-contract assertions and workflow lane names aligned to the exact public claims. [VERIFIED: test/oban_powertools/docs_contract_test.exs; workflow; guides] |

## Sources

### Primary (HIGH confidence)
- Repo-local planning context:
  - `.planning/phases/13-native-only-optional-dependency-contract-proof/13-CONTEXT.md`
  - `.planning/REQUIREMENTS.md`
  - `.planning/ROADMAP.md`
  - `.planning/MILESTONE-ARC.md`
  - `.planning/milestones/v1.1-MILESTONE-AUDIT.md`
- Repo-local implementation and proof files:
  - `lib/oban_powertools/web/router.ex`
  - `lib/oban_powertools/web/oban_web_bridge.ex`
  - `test/support/example_host_contract.ex`
  - `test/support/fresh_host_contract.ex`
  - `test/oban_powertools/example_host_contract_test.exs`
  - `test/oban_powertools/web/router_test.exs`
  - `test/oban_powertools/docs_contract_test.exs`
  - `.github/workflows/host-contract-proof.yml`
  - `examples/phoenix_host/mix.exs`
  - `README.md`
  - `guides/installation.md`
  - `guides/first-operator-session.md`
  - `guides/optional-oban-web-bridge.md`
  - `guides/upgrade-and-compatibility.md`
- Official Mix docs:
  - https://hexdocs.pm/mix/Mix.Tasks.Deps.html - optional dependency semantics and recommended `--no-optional-deps` compile guard
  - https://hexdocs.pm/mix/Mix.Tasks.Loadpaths.html - `--no-optional-deps` load/compile behavior
  - https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html - `--unused` lock cleanup

### Secondary (MEDIUM confidence)
- Hex package pages:
  - https://hex.pm/packages/oban
  - https://hex.pm/packages/phoenix_live_view
  - https://hex.pm/packages/oban_web

### Tertiary (LOW confidence)
- None. [VERIFIED: all substantive claims above are repo-local or official-doc sourced]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended components are either already in the repo or verified against official Hex/Mix sources.
- Architecture: HIGH - the critical boundaries are explicit in Phase 13 context, the router macro, the bridge adapter, and the existing harness/tests.
- Pitfalls: HIGH - the main failure modes are directly observable in current code, workflow wiring, and Mix docs.

**Research date:** 2026-05-23
**Valid until:** 2026-06-22
