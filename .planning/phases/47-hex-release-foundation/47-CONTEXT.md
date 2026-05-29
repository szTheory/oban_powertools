# Phase 47: Hex Release Foundation - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Package and publish Oban Powertools to hex.pm at a deliberate **0.5.0**, with correctly rendering ExDoc documentation on hexdocs and a `CHANGELOG.md` that documents the release and the path to 1.0. This is the **first public release** of a library that has lived internally at `0.1.0` through five milestones (v1–v1.5).

Scope is REL-01 (publish at 0.5.0 with a strict `:files` whitelist), REL-02 (ExDoc `source_ref` pinned to the release tag, hexdocs renders with guides as `extras`), and REL-03 (CHANGELOG in Keep-a-Changelog format documenting 0.5.0 + the explicit path to 1.0).

**Explicitly NOT in this phase:** REL-04 (verifying getting-started from the *published* package via an isolated hex consumer) is **Phase 51**. The `doctor` task (48), limiter CLI (49), and telemetry guide (50) are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Locked upstream (carry forward — do NOT re-litigate)
These were settled by PROJECT.md and the v1.6 PITFALLS research before this discussion:
- **D-00a:** Version is **`0.5.0`**. The `0.x` range honestly signals "no API freeze yet." Do not bump toward 1.0 in this phase (PITFALLS Pitfall 2).
- **D-00b:** `mix.exs` gets a `package/0` with an **explicit `:files` whitelist** that ships `lib`, `guides`, `priv`, `.formatter.exs`, `mix.exs`, `mix.lock`, `README.md`, `CHANGELOG.md`, `LICENSE` — and excludes `.planning/`, `test/`, `examples/`, `prompts/`, `doc/`, `erl_crash.dump` (PITFALLS Pitfall 1). Verify by `mix hex.build` + `tar tf`.
- **D-00c:** Scope `igniter` to `only: [:dev, :test], runtime: false` so adopters don't ship code-gen machinery to prod (PITFALLS Pitfall 14). Confirm `ex_doc`/`lazy_html` scopes stay correct.
- **D-00d:** ExDoc `docs/0` gets `source_url`, `source_ref: "v#{@version}"`, and `source_url_pattern` pointing at `github.com/szTheory/oban_powertools` at the tag — plus a `@version` module attribute (REL-02, PITFALLS Pitfall 15).
- **D-00e:** A `git status --porcelain` **clean-tree gate must pass before any publish** (PITFALLS Pitfall 17). `mix hex.publish` ships the working tree, not the last commit.

### Publish mechanism
- **D-01:** Stand up the **full release-please pipeline now** — `release-please-config.json` + `.release-please-manifest.json` + a GitHub Actions publish workflow. Automated, auditable releases from day one. (User chose the heavier canonical path over a manual-first hybrid.)
- **D-02:** **release-please cuts the 0.5.0 release itself.** Seed the pipeline so release-please opens the release PR, tags `v0.5.0`, and the workflow publishes — rather than a manual first publish. Requires deliberate manifest seeding + a `Release-As: 0.5.0` mechanism (commit footer or bootstrap-sha) so the first release lands at 0.5.0 and NOT 0.1.0 or an auto-1.0.0. This is the known-risky part of release-please bootstrapping — research the exact seeding approach (see Open Questions).
- **D-03:** Use a **standard, upstream release-please setup** (e.g. `googleapis/release-please-action`) per release-please's own docs. Do **NOT** couple to the `bootstrap-elixir-hex-lib` skill's specific config/layout — that skill is for greenfield libs; this one predates it and is being retrofitted. Idiomatic upstream conventions only.
- **D-04:** Publish auth uses a **`HEX_API_KEY` GitHub Actions secret** (publish-scoped). The secret must be provisioned in the repo before the publish workflow can succeed — flag as an operator prerequisite.
- **D-05:** The git tag is `v0.5.0` and MUST match the ExDoc `source_ref` (D-00d). The release-please tag format and the `source_ref` string must be kept consistent.

### License
- **D-06:** Ship **Apache-2.0**. Matches every direct infra dependency Oban Powertools wraps (oban, oban_web, ecto, ecto_sql, telemetry, ex_doc are all Apache-2.0) → uniform license audit for adopters; adds an explicit patent grant MIT lacks; no contributor-agreement overhead for a single-vendor project.
- **D-07:** Add a verbatim `LICENSE` file at repo root (Apache-2.0 text), include it in `:files`, and set `licenses: ["Apache-2.0"]` (SPDX) in `package/0`.

### Path to 1.0 (documented per REL-03)
- **D-08:** Use a **hybrid per-surface + stability-window gate**, documented as a per-surface checklist in `CHANGELOG.md` using the project's existing support-truth vocabulary. Each named public surface freezes only after it is (i) explicitly enumerated, (ii) exercised by **≥1 non-szTheory host**, and (iii) free of any known breaking change — AND has survived **≥2 consecutive 0.x minor releases** without a breaking change.
- **D-09:** The enumerated 1.0 surfaces are: the **installer / migration contract**, the **Operator Elixir API (single + bulk)**, the **frozen Telemetry `@contract`**, and the **host-ownership boundary**. This lets the already-frozen Telemetry contract graduate earliest while keeping migration internals and Lifeline in a longer observation window. No single binary 1.0 cliff.

### CHANGELOG framing
- **D-10:** First entry is **`## [0.5.0]` with a feature-grouped `### Added`** block (grouped by domain: workers & idempotency, limiters & explain, cron, workflows, lifeline/repairs, native `/ops/jobs` shell, Operator API, telemetry contract, install/migrations, optional oban_web bridge). Keep-a-Changelog format (REL-03).
- **D-11:** Include a top **`## [Unreleased]`** section so Phases 48–51 accumulate entries cleanly, and a short prose note stating the **`0.x` instability window** and that internal **v1.x milestone numbers do NOT map to the public 0.x hex version** (heads off PITFALLS Pitfall 2 confusion in the public artifact).
- **D-12:** The path-to-1.0 gate (D-08/D-09) lives **in `CHANGELOG.md`** (satisfies REL-03 in the same file). Add a `changelog:` key to `docs/0` so hexdocs renders it.
- **D-13:** Do **NOT** backfill internal v1.x milestones as prior changelog entries — that would permanently bake the version confusion in and imply hex releases that never existed.

### Claude's Discretion
- Exact `:files` list ordering and whether to add `.formatter.exs`/`priv` conditionally — follow the PITFALLS Pitfall 1 recommendation as the baseline.
- Wording of the CHANGELOG capability bullets and the README `0.x` stability banner.
- Whether to fix the orphan-extra hygiene issue (see code_context) in this phase or note it — low stakes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase definition & requirements
- `.planning/ROADMAP.md` §"Phase 47: Hex Release Foundation" — goal + 4 success criteria.
- `.planning/REQUIREMENTS.md` — REL-01, REL-02, REL-03 (lines ~12-14); REL-04 is Phase 51, not here.

### Release pitfalls (directly drive every task in this phase)
- `.planning/research/PITFALLS.md` — **Pitfall 1** (`package`/`:files`), **Pitfall 2** (0.5.0 not 1.0), **Pitfall 3** (in-repo vs published — context for Phase 51), **Pitfall 14** (igniter dev-only), **Pitfall 15** (`source_ref`), **Pitfall 16** (CHANGELOG), **Pitfall 17** (clean-tree-before-publish). See also "Looks Done But Isn't" checklist and Pitfall-to-Phase mapping.
- `.planning/research/SUMMARY.md`, `.planning/research/STACK.md`, `.planning/research/ARCHITECTURE.md`, `.planning/research/FEATURES.md` — v1.6 milestone research context.

### Project decisions & rationale
- `.planning/PROJECT.md` §"Current Milestone: v1.6" — 0.5.0 rationale, zero-new-deps constraint, phase numbering.
- `.planning/threads/2026-05-28-post-v1.5-next-milestone.md` — post-v1.5 assessment that set the 0.5.0-first / publish-the-gap direction.

### Files to edit / create in this phase
- `mix.exs` — currently NO `package/0`; `docs/0` lacks `source_ref`/`source_url`; `igniter` unscoped; version `0.1.0`. All change here.
- `README.md` §"60-Second Install" (line 25: `{:oban_powertools, "~> 0.1.0"}`) — bump to `~> 0.5` + add `0.x` stability note.
- `guides/` (14 `.md` files) — shipped via `:files` and ExDoc `extras`.
- `lib/oban_powertools/telemetry.ex` — the frozen `@contract`; a named 1.0 surface (do not edit here, just referenced by D-09).
- `.github/workflows/host-contract-proof.yml` — existing CI; the new release/publish workflow is added alongside it.

### External (release-please)
- release-please-action upstream docs (`github.com/googleapis/release-please-action`) — config + manifest + `Release-As:` bootstrapping. Standard setup, NOT the `bootstrap-elixir-hex-lib` skill.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix.exs` `docs/0` already wires `extras` (`README.md` + `Path.wildcard("guides/*.md")`) and `groups_for_extras` (Day 0 / Builders / Operations). Only needs `source_*` keys, `@version`, and a `changelog:` key added — not a rewrite.
- `elixirc_paths(:test)` already adds `test/support` only in test env — correct guard so test-only modules don't reach the published tarball (verify against the actual tarball per Pitfall 1).
- 14 guides already exist under `guides/` and are battle-tested as ExDoc extras in-repo.

### Established Patterns
- Dep scoping is already partially correct: `ex_doc` is `only: :dev, runtime: false`; `lazy_html` is `only: :test`. `igniter` is the lone unscoped outlier (D-00c).
- `oban_web` is already `optional: true` — correct for the optional bridge.

### Integration Points
- New `release-please` config + publish workflow join the existing single workflow `.github/workflows/host-contract-proof.yml`.
- The release tag `v0.5.0` is the join point between three things that must agree: release-please's tag, ExDoc `source_ref`, and the published hex docs version.

### Hygiene note (low stakes)
- `guides/forensics-and-runbook-handoffs.md` exists and is picked up by `Path.wildcard("guides/*.md")` as an extra, but is NOT listed in any `groups_for_extras` group → it renders as an ungrouped extra. Optional to fix while editing `docs/0`.

</code_context>

<specifics>
## Specific Ideas

- User deliberately chose the **heavier full-release-please path** over a manual-first hybrid, and chose to have **release-please cut 0.5.0 itself** — signal that automation completeness/auditability is valued over shortest-path-to-publish here.
- User chose **standard upstream release-please** over the szTheory `bootstrap-elixir-hex-lib` skill layout — keep the setup idiomatic to release-please's own docs, not coupled to the bootstrap skill.

</specifics>

<deferred>
## Deferred Ideas

- **Isolated hex-consumer verification** (`examples/hex_consumer/` installing `{:oban_powertools, "~> 0.5"}` from hex and running the full install + first-session flow) — this is REL-04 / **Phase 51**, not Phase 47. (PITFALLS Pitfall 3.)
- **Automated CHANGELOG generation via conventional commits** — release-please can generate changelog sections from commit messages going forward (0.6.0+). For 0.5.0 the entry is hand-authored (D-10). Whether to lean on auto-generation later is a future concern.
- None of the above are scope creep into this phase — they are correctly downstream.

</deferred>

---

*Phase: 47-hex-release-foundation*
*Context gathered: 2026-05-29*
