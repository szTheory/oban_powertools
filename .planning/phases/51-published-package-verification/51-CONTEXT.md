# Phase 51: Published-Package Verification - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the **published** Oban Powertools hex package (v0.5.0 — already live on hex.pm)
actually works for a fresh adopter who installs **from hex**, not from the repo.
This is the REL-04 closure of the v1.6 release: the in-repo install contract is
already proven (`host-contract-proof.yml`), but nothing yet exercises the real
published **tarball** — the `:files` whitelist, the `priv/` migrations, the shipped
guides — as resolved by `mix deps.get` from hex.

Scope is REL-04 only: stand up an isolated hex consumer, run the full
install → first-operator-session flow against it, gate it in the release pipeline,
and document/fix any drift between in-repo and published behavior.

**Explicitly NOT in this phase:** new library capability, changes to the release-please
pipeline mechanics (47), `doctor` (48), limiter CLI (49), or telemetry guide (50). This
phase only *verifies* what those phases shipped — it does not extend them.

</domain>

<decisions>
## Implementation Decisions

### Verification trigger (where/when the check runs)
- **D-01:** Add a `verify-published` job to **`.github/workflows/release.yml`** with
  `needs: [publish-hex]`. It runs **automatically on every release**, after the package
  is published. (User chose the auto post-publish job over scheduled cron or
  workflow_dispatch-only.)
- **D-01a:** **No chicken-and-egg.** `publish-hex` already ends with a polling step that
  blocks until hex.pm confirms the new version is indexed, so `needs: [publish-hex]`
  guarantees the tarball is live and fetchable before `verify-published` starts. No race,
  no sleep/retry needed in the new job.
- **D-01b:** Hex versions are **immutable** — a `verify-published` failure cannot block the
  publish (the version is already out). The correct failure response is a **loud red job on
  the release commit** + fix-forward via a patch release. This is acceptable and expected;
  do not try to make it a pre-publish gate.

### Dependency source (what the consumer proves)
- **D-02:** The consumer pulls a **true hex dep `{:oban_powertools, "~> 0.5"}`** resolved
  via `mix deps.get` from hex.pm. This is the **only** option that exercises the real
  published tarball + the `:files` whitelist — the exact failure class this phase exists to
  catch (a `priv/` migration or guide accidentally excluded from `package/0` `:files`).
- **D-02a:** A `git:`+tag dep was **rejected**: it fetches the whole repo tree, so a broken
  `:files` whitelist passes silently → false confidence. (PITFALLS Pitfall 3.)
- **D-02b:** The `verify-published` job must verify **the version just published**, not
  whatever an older committed `mix.lock`/cache resolves to. Force resolution of the new
  version (e.g. `mix deps.update oban_powertools`, or pin the exact `== <version>` from the
  release-please job output, and/or clear `HEX_HOME` registry cache). Planner: decide the
  exact mechanism — the constraint is "the freshly-published version is what gets tested."

### Consumer shape (the fresh host)
- **D-03:** A **committed `examples/hex_consumer/`** project — a real mini Phoenix app with
  `{:oban_powertools, "~> 0.5"}` in its **own** `mix.exs`, checked into the repo. Distinct
  from `examples/phoenix_host` (which uses a `path:` dep). Matches PITFALLS Pitfall 3
  verbatim and the project's existing committed-example idiom (greppable, locally runnable,
  auditable across releases).
- **D-03a:** `~> 0.5` auto-tracks the latest published `0.x`, so the pin needs **near-zero
  maintenance** — no per-release `mix.exs` edit for patch/minor 0.x bumps.
- **D-03b:** Give it a **`regenerate.sh`** companion, consistent with `examples/phoenix_host`
  and `examples/phoenix_host_upgrade_source`.
- **D-03c:** Rejected: retargeting `fresh_host_contract_test.exs` to hex (conflates the
  in-repo install contract with the published one, forces it post-publish-only) and
  ephemeral `mix phx.new` in a CI script (invisible locally, no audit trail).

### Verification depth (how far "first successful operator session" goes)
- **D-04:** **Full operator session.** Reuse the **existing first-session harness**
  (`examples/phoenix_host/test/.../oban_powertools_first_session_test.exs` pattern) against
  the hex-resolved consumer: install → run generated migration → boot the app → drive a
  LiveView session in `/ops/jobs` → **pause a cron entry** → assert DB state + audit
  evidence. This mirrors the getting-started guide's actual promise (a working operator
  surface), and the cron-pause path is **synchronous** (no Oban async-pickup flakiness).
- **D-04a:** Rejected shallower tiers — install+compile-only and install+boot+route-resolves
  both pass for a package whose `/ops/jobs` mounts but is broken/empty. For a library whose
  value *is* the operator surface, that's false confidence.

### Clean-tree / per-phase verification convention (success criterion 3)
- **D-05:** Carry forward the **v1.5-graduated convention** — the phase verification asserts
  a clean working tree (`git status --porcelain`) / per-phase commit existence, consistent
  with how 43–50 were verified. Not a new decision; just applied here. (Also aligns with the
  publish clean-tree gate D-00e from Phase 47.)

### Drift handling (success criterion 4)
- **D-06:** Policy for any in-repo-vs-published drift found: **fix-forward real bugs** (a
  packaging bug → correct `:files`/`priv` and cut a patch release; a guide path bug → fix the
  guide), and **document** any *intentional* difference. Do not silently absorb drift; every
  divergence is either fixed or explicitly written down (CHANGELOG `[Unreleased]` or a short
  note in the phase verification).

### Claude's Discretion
- Exact mechanism for forcing the just-published version in CI (D-02b): `deps.update` vs
  exact-version pin vs cache-clear — planner/researcher picks the most robust.
- Whether the `verify-published` job needs its own Postgres service block or reuses the
  established `host-contract-proof.yml` service pattern (it will need Postgres for D-04).
- Whether to also expose the verification as a `workflow_dispatch` entry point for the
  `publish-hex.yml` recovery path (nice-to-have; user chose the auto-release-job as the
  primary and only required placement).
- How much of the first-session harness is shared vs copied between `examples/phoenix_host`
  and `examples/hex_consumer` (extract shared support vs duplicate the test) — low stakes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition & requirements
- `.planning/ROADMAP.md` §"Phase 51: Published-Package Verification" — goal + 4 success criteria.
- `.planning/REQUIREMENTS.md` — **REL-04** (the one open requirement); REL-01/02/03 (Phase 47) are done.

### Release pitfalls (this phase exists to catch Pitfall 3)
- `.planning/research/PITFALLS.md` — **Pitfall 3** (getting-started only works in-repo, not
  from the published package) is the direct driver; "Phase to address" line names this work.
  Cross-reference **Pitfall 1** (`:files` whitelist) and **Pitfall 17** (clean-tree gate).

### Prior phase context (release foundation this verifies)
- `.planning/phases/47-hex-release-foundation/47-CONTEXT.md` — D-00b (`:files` whitelist),
  D-00e (clean-tree gate), and its **Deferred Ideas** section which explicitly scoped the
  `examples/hex_consumer/` work to **Phase 51**.

### Project decisions & rationale
- `.planning/PROJECT.md` §"Current Milestone: v1.6" — getting-started-verified-from-published
  is the milestone's stated release bar; zero-new-deps constraint.

### Files to create / edit in this phase
- **CREATE** `examples/hex_consumer/` — new committed mini Phoenix app, own `mix.exs` with
  `{:oban_powertools, "~> 0.5"}`, plus `regenerate.sh`. The verification target.
- **EDIT** `.github/workflows/release.yml` — add `verify-published` job, `needs: [publish-hex]`
  (existing jobs: `release-please` L28 → `gate-ci-green` L44 → `publish-hex` L136, which
  already polls hex.pm for the indexed version).
- `mix.exs` `package/0` `:files` whitelist — the artifact under test (do not loosen it to make
  the test pass; a failure here means a real packaging bug).

### Reusable harness (copy/retarget, don't rebuild)
- `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` — the
  full operator-session flow (boot → `/ops/jobs` LiveView → cron pause → audit assert) to
  reuse against the hex consumer.
- `test/oban_powertools/fresh_host_contract_test.exs` + `test/support/fresh_host_contract.ex`
  — the in-repo install contract (path dep); the published analog of this.
- `.github/workflows/host-contract-proof.yml` — Postgres service + setup-beam + phx_new
  install pattern to mirror in the new job.
- `.github/workflows/publish-hex.yml` — `workflow_dispatch` recovery publish path (optional
  secondary placement for the verification, per D-discretion).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **First-session harness** (`examples/phoenix_host/.../oban_powertools_first_session_test.exs`):
  already boots a host app, drives a LiveView session, pauses a cron entry, and asserts DB +
  audit evidence — synchronously (no Oban async race). Phase 51's depth (D-04) is this exact
  flow, only the dep source changes (path → hex).
- **`FreshHostContract` support** (`test/support/fresh_host_contract.ex`) + its test: the
  phx_new + `mix oban_powertools.install` + artifact-assertion machinery, reusable shape for
  the hex consumer's install step.
- **Committed example-app pattern**: `examples/phoenix_host` and
  `examples/phoenix_host_upgrade_source` each have a `regenerate.sh` — `examples/hex_consumer/`
  follows the same convention.
- **Release pipeline polling**: `release.yml` `publish-hex` already blocks on hex.pm indexing,
  so the new `verify-published` job needs no propagation wait of its own.

### Established Patterns
- CI jobs use `erlef/setup-beam` (Elixir 1.19.5 / OTP 27.3) + a `postgres:16` service with
  `OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"` and a health-checked port 5432 (see
  `host-contract-proof.yml`). The new job mirrors this.
- Example apps use `path:` deps today; `examples/hex_consumer/` is the first to use a **hex**
  dep — that difference is the whole point.

### Integration Points
- The join point is the release tag/version: `release-please` emits the version → `publish-hex`
  publishes + confirms indexing → `verify-published` resolves that exact version from hex and
  runs the first-session flow.
- `mix.exs` `package/0` `:files` is the contract under test; the consumer's `mix deps.get` is
  the assertion.

</code_context>

<specifics>
## Specific Ideas

- User accepted all four researched recommendations as-is (auto post-publish job + true hex
  dep + committed `examples/hex_consumer/` + full operator-session depth) — signal that the
  honest, end-to-end proof is valued over a shallow/cheaper smoke test, consistent with the
  project's support-truth posture.
- The design composes into one coherent artifact: a committed `examples/hex_consumer/` pinned
  to `~> 0.5` from hex, exercised by the existing first-session harness, run as a
  `needs: [publish-hex]` job in `release.yml`.

</specifics>

<deferred>
## Deferred Ideas

- **Scheduled/cron drift monitoring** of the latest published version (catch CDN/Elixir-OTP
  compatibility rot over time) — a different goal than REL-04's release-time verification.
  Note for a future operability concern, not this phase.
- **`workflow_dispatch` re-run entry point** wired into `publish-hex.yml` recovery path — a
  nice-to-have secondary placement; in scope only as Claude's discretion, not required.
- None of the above are scope creep into the phase boundary — they are optional extensions of
  the same verification.

</deferred>

---

*Phase: 51-published-package-verification*
*Context gathered: 2026-05-29*
