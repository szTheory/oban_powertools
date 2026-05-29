# Phase 47: Hex Release Foundation - Research

**Researched:** 2026-05-29
**Domain:** Elixir hex package publication, release-please automation, ExDoc configuration
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-00a:** Version is `0.5.0`. The `0.x` range honestly signals "no API freeze yet." Do not bump toward 1.0 in this phase.
**D-00b:** `mix.exs` gets a `package/0` with an explicit `:files` whitelist that ships `lib`, `guides`, `.formatter.exs`, `mix.exs`, `mix.lock`, `README.md`, `CHANGELOG.md`, `LICENSE` — and excludes `.planning/`, `test/`, `examples/`, `prompts/`, `doc/`, `erl_crash.dump`. Verify by `mix hex.build` + `tar tf`.
**D-00c:** Scope `igniter` to `only: [:dev, :test], runtime: false` so adopters don't ship code-gen machinery to prod. Confirm `ex_doc`/`lazy_html` scopes stay correct.
**D-00d:** ExDoc `docs/0` gets `source_url`, `source_ref: "v#{@version}"`, and `source_url_pattern` pointing at `github.com/szTheory/oban_powertools` at the tag — plus a `@version` module attribute.
**D-00e:** A `git status --porcelain` clean-tree gate must pass before any publish. `mix hex.publish` ships the working tree, not the last commit.
**D-01:** Stand up the full release-please pipeline now — `release-please-config.json` + `.release-please-manifest.json` + a GitHub Actions publish workflow.
**D-02:** release-please cuts the 0.5.0 release itself. Seed the pipeline so release-please opens the release PR, tags `v0.5.0`, and the workflow publishes. Requires deliberate manifest seeding + a `Release-As: 0.5.0` mechanism so the first release lands at 0.5.0.
**D-03:** Use a standard, upstream release-please setup (`googleapis/release-please-action`) per release-please's own docs. Do NOT couple to the `bootstrap-elixir-hex-lib` skill's layout.
**D-04:** Publish auth uses a `HEX_API_KEY` GitHub Actions secret (publish-scoped). Must be provisioned before the publish workflow can succeed.
**D-05:** The git tag is `v0.5.0` and MUST match the ExDoc `source_ref`.
**D-06:** Ship Apache-2.0. Matches every direct infra dependency's license.
**D-07:** Add a verbatim `LICENSE` file at repo root (Apache-2.0 text), include it in `:files`, set `licenses: ["Apache-2.0"]` (SPDX) in `package/0`.
**D-08:** Hybrid per-surface + stability-window gate for the path to 1.0, documented in `CHANGELOG.md`.
**D-09:** 1.0 surfaces: installer/migration contract, Operator Elixir API, frozen Telemetry `@contract`, host-ownership boundary.
**D-10:** First CHANGELOG entry is `## [0.5.0]` with a feature-grouped `### Added` block grouped by domain. Keep-a-Changelog format.
**D-11:** Include a top `## [Unreleased]` section and a short prose note about the `0.x` instability window and that internal v1.x milestone numbers do NOT map to public 0.x hex versions.
**D-12:** Path-to-1.0 gate (D-08/D-09) lives in `CHANGELOG.md`. Add CHANGELOG.md to the ExDoc `extras` list so hexdocs renders it.
**D-13:** Do NOT backfill internal v1.x milestones as prior changelog entries.

### Claude's Discretion

- Exact `:files` list ordering and whether to add `.formatter.exs`/`priv` conditionally — follow PITFALLS Pitfall 1 recommendation as baseline.
- Wording of the CHANGELOG capability bullets and the README `0.x` stability banner.
- Whether to fix the orphan-extra hygiene issue (forensics guide ungrouped) in this phase — low stakes.

### Deferred Ideas (OUT OF SCOPE)

- Isolated hex-consumer verification — REL-04 / Phase 51.
- Automated CHANGELOG generation via conventional commits — future concern (0.6.0+); 0.5.0 entry is hand-authored.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Library publishes to hex.pm at `0.5.0` with a strict `:files` whitelist that ships `priv/` migration generators and excludes `.planning/`, tests, and dev cruft. | `package/0` with explicit `:files`, `mix hex.build --unpack` verification, `tar tf` audit |
| REL-02 | ExDoc API documentation builds with `source_ref` pinned to the release tag and renders correctly on hexdocs (guides included as `extras`). | `docs/0` with `source_ref`, `source_url`, `source_url_pattern`, CHANGELOG.md in `extras` |
| REL-03 | `CHANGELOG.md` (Keep a Changelog format) documents the `0.5.0` release and the explicit, documented path to `1.0`. | CHANGELOG.md created at root, included in `:files` and ExDoc `extras` |

</phase_requirements>

---

## Summary

Phase 47 packages and publishes Oban Powertools to hex.pm for the first time. The scope covers three mutually dependent concerns: (1) correct hex tarball contents via an explicit `package/0` `:files` whitelist, (2) ExDoc documentation with source links pinned to the release tag, and (3) an automated release-please pipeline that opens a Release PR, tags `v0.5.0`, and triggers a publish workflow.

The highest-risk item is release-please bootstrapping. The library has 5 milestones of commit history but has never been released. The `release-as` config key is officially deprecated; the current idiomatic mechanism to force the first release at exactly 0.5.0 is to push a commit whose message body contains `Release-As: 0.5.0` — this opens a Release PR at that version. The `.release-please-manifest.json` must be seeded to `{"." : "0.0.0"}` (not the current `0.1.0` in `mix.exs`) so release-please treats this as an unreleased baseline. The bootstrap-sha should be set to the SHA of the very first commit to avoid pulling the full history into the changelog.

The release-please `elixir` release type (`release-type: "elixir"`) is mature and recommended. It updates `mix.exs` correctly for both `version: "x.y.z"` and `@version "x.y.z"` patterns (the `@version` support was added in commit 1af59a1). It tags with a `v` prefix by default (`include-v-in-tag` defaults to `true`), which aligns with ExDoc's `source_ref: "v#{@version}"` requirement.

**Primary recommendation:** Seed manifest at `"0.0.0"`, set `bootstrap-sha` to the repo's first commit, push a `chore: bootstrap release-please` commit with `Release-As: 0.5.0` in the body, then merge the resulting Release PR. After the tag is created, the publish workflow runs `mix hex.publish --yes`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tarball content control (`package/0` `:files`) | Build/packaging config | — | Pure mix.exs declaration; no runtime impact |
| ExDoc source links (`source_ref`, `source_url_pattern`) | Build/packaging config | CI validation | Configured in mix.exs `docs/0`; verified by `mix docs` locally |
| release-please PR + tag creation | CI (GitHub Actions) | — | `googleapis/release-please-action@v4` on push to `main` |
| Hex publish | CI (GitHub Actions) | Local fallback | Triggered by `release_created` output; `mix hex.publish --yes` |
| CHANGELOG authoring | Source file | CI validation | Hand-authored for 0.5.0; release-please auto-updates for future versions |
| `igniter` dep scoping | mix.exs deps | — | `only: [:dev, :test], runtime: false` — fix before tarball |
| Apache-2.0 license | Source file + mix.exs | — | `LICENSE` at root + `licenses: ["Apache-2.0"]` in `package/0` |

---

## Standard Stack

### Core (no new runtime deps — all pre-existing or config-only)

| Component | Version / Spec | Purpose | Why Standard |
|-----------|---------------|---------|--------------|
| `ex_doc` | `~> 0.40` (locked 0.40.3) [VERIFIED: mix.lock] | ExDoc documentation generation | Already in mix.exs as `only: :dev, runtime: false` |
| `googleapis/release-please-action` | `@v4` [VERIFIED: official README] | Automated Release PR + tag creation | Canonical upstream action; v4 is stable release |
| `mix hex.publish` | Hex built-in | Publishes tarball + docs to hex.pm | Standard Elixir tooling |

### No new packages are installed in this phase

This phase creates configuration files and modifies existing source files. No `mix.exs` deps additions, no npm installs. The `googleapis/release-please-action@v4` GitHub Action is consumed via workflow YAML — it is not an installed package.

---

## Package Legitimacy Audit

> No new packages are installed in this phase. `slopcheck` not applicable.

This phase modifies `mix.exs` configuration only and creates workflow YAML files. The existing deps (`ex_doc 0.40.3`, `igniter 0.8.0`) are already present and locked. No new registry installs occur.

| Component | Source | Status |
|-----------|--------|--------|
| `googleapis/release-please-action@v4` | Official Google/googleapis GitHub Action | Pinned to `@v4` tag from the canonical org |
| `ex_doc ~> 0.40` | hex.pm, already locked | Existing dep, no change |
| `igniter ~> 0.8.0` | hex.pm, already locked | Dep scoping fix only (no version change) |

---

## Architecture Patterns

### System Architecture Diagram

```
Developer pushes commit with
"Release-As: 0.5.0" in body
         |
         v
  main branch (GitHub)
         |
   [on: push to main]
         |
         v
  release-please-action@v4
  (reads manifest "0.0.0",
   sees Release-As footer,
   proposes 0.5.0)
         |
         v
  Release PR opened:
  - Updates mix.exs version: "0.5.0"
  - Updates CHANGELOG.md [0.5.0] section
  - Updates .release-please-manifest.json → "0.5.0"
         |
    [merge PR]
         |
         v
  release-please-action@v4
  (detects merged Release PR → creates tag v0.5.0)
         |
   release_created=true
         |
         v
  publish-hex job (needs: release-please)
  - actions/checkout@v4
  - erlef/setup-beam@v1
  - git status --porcelain (clean-tree gate)
  - mix deps.get
  - mix hex.publish --yes
    (env: HEX_API_KEY)
         |
         v
  oban_powertools 0.5.0 live on hex.pm
  hexdocs auto-published
```

### Recommended Project Structure (files created/modified in this phase)

```
.
├── .github/
│   └── workflows/
│       ├── host-contract-proof.yml   # existing — unchanged
│       └── release-please.yml        # NEW: release PR + conditional hex publish
├── .release-please-manifest.json     # NEW: {"." : "0.0.0"}  (seeded baseline)
├── release-please-config.json        # NEW: elixir release type, bootstrap-sha, include-v-in-tag
├── CHANGELOG.md                      # NEW: hand-authored 0.5.0 + path-to-1.0
├── LICENSE                           # NEW: Apache-2.0 verbatim text
└── mix.exs                           # EDIT: version→0.5.0, @version attr, package/0, docs/0 update
```

### Pattern 1: release-please Bootstrap for First Release at Non-Default Version

**What:** Seed the manifest at the version BEFORE your intended first release. Push a commit with `Release-As: 0.5.0` in the commit body. Release-please reads the footer and opens a Release PR at exactly that version.

**When to use:** Any repo with prior commit history that has never been released and needs a specific first version.

**Why `Release-As` commit footer instead of `release-as` config key:**
The `release-as` field in `release-please-config.json` is officially `[DEPRECATED]` with a schema description of "Override the next version of this package. Consider using a `Release-As` commit instead." [VERIFIED: release-please schemas/config.json]

**Seeding mechanics:**
```json
// .release-please-manifest.json — MUST be "0.0.0", not the mix.exs version "0.1.0"
// If you seed with "0.1.0", release-please thinks 0.1.0 is already released
// and bumps to 0.1.1 or 0.2.0 — not 0.5.0.
{"." : "0.0.0"}
```

```json
// release-please-config.json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bootstrap-sha": "<SHA_OF_FIRST_REPO_COMMIT>",
  "include-v-in-tag": true,
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "package-name": "oban_powertools"
    }
  }
}
```

**The `Release-As: 0.5.0` commit (the trigger commit):**
```
chore: bootstrap release-please for 0.5.0

Release-As: 0.5.0
```

This commit pushed to `main` triggers release-please to open a Release PR at exactly 0.5.0. The `Release-As:` footer in the commit **body** (not the subject line) overrides conventional-commit version inference for this one release. [VERIFIED: release-please manifest-releaser docs]

**After the Release PR merges:** remove the `Release-As` pin if you had put it in config (N/A here since we use the commit footer). Future releases auto-bump from conventional commits.

### Pattern 2: mix.exs `@version` Module Attribute + release-please Update

**What:** Define `@version` as a module attribute in mix.exs, reference it in `version:`, `docs/0`, and `package/0`. Release-please will update `@version` when it updates mix.exs.

**Release-please elixir strategy update behavior (verified):**
The `ElixirMixExs` updater (release-please) now supports BOTH patterns [VERIFIED: release-please commit 1af59a1]:
1. `@version "x.y.z"` — module attribute (checked first)
2. `version: "x.y.z",` — inline in `project/0` (fallback)

If `@version` exists in the file, it is updated. Otherwise the inline form is updated. They are NOT both updated simultaneously in a single file.

**Implication for this phase:** Since D-00d requires a `@version` module attribute for `source_ref: "v#{@version}"` to work, and release-please will correctly update `@version "x.y.z"` — use the module attribute pattern. Do NOT keep the bare `version: "0.1.0"` in `project/0`; replace it with `version: @version`.

```elixir
# Source: release-please commit 1af59a1 + PITFALLS.md Pitfall 15
@version "0.5.0"
@source_url "https://github.com/szTheory/oban_powertools"

def project do
  [
    app: :oban_powertools,
    version: @version,
    # ...
    package: package()
  ]
end

defp package do
  [
    licenses: ["Apache-2.0"],
    links: %{"GitHub" => @source_url},
    files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
  ]
end

defp docs do
  [
    main: "readme",
    source_url: @source_url,
    source_ref: "v#{@version}",
    source_url_pattern: "#{@source_url}/blob/v#{@version}/%{path}#L%{line}",
    extras: ["README.md", "CHANGELOG.md" | Path.wildcard("guides/*.md")],
    groups_for_extras: [
      "Day 0": [ ... ],
      ...
    ]
  ]
end
```

### Pattern 3: GitHub Actions release-please Workflow

**What:** Single workflow file that (a) runs release-please on every push to main, and (b) runs `mix hex.publish --yes` only when a release is actually created.

**GITHUB_TOKEN limitation:** The default `secrets.GITHUB_TOKEN` cannot trigger subsequent workflow runs from PRs it creates. However, for a single-workflow file where publish is a `needs: release-please` job in the SAME workflow, the `release_created` output is sufficient — no PAT is required for the publish step itself. [CITED: googleapis/release-please-action README]

The limitation matters only if CI checks (e.g., `host-contract-proof.yml`) need to run on the Release PR. Since `host-contract-proof.yml` triggers on `push` and `pull_request`, a Release PR created by `GITHUB_TOKEN` will NOT trigger CI checks on that PR unless a PAT or GitHub App token is used. This is an operator-awareness item, not a blocker for publishing.

```yaml
# Source: elixirschool.com/blog/managing-releases-with-release-please + official action README
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
      - name: Verify clean working tree
        run: |
          if ! git status --porcelain | grep -q '^$'; then
            echo "ERROR: Working tree is not clean. Aborting publish."
            exit 1
          fi
      - name: Install dependencies
        run: mix deps.get
      - name: Publish to Hex
        run: mix hex.publish --yes
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

**Note on erlef/setup-beam version:** Match the existing `host-contract-proof.yml` (elixir `1.19.5`, otp `27.3`) for consistency.

### Pattern 4: `package/0` `:files` Whitelist

**What:** Explicit list of files/globs to include in the hex tarball. Without this, `mix hex.publish` defaults include `lib`, `priv`, `test/`, `examples/`, etc. — shipping dev cruft.

**No `priv/` directory exists at the library root.** The installer (`mix oban_powertools.install`) generates migrations inline via `Igniter.Libs.Ecto.gen_migration/4` — directly to the host's `priv/repo/migrations/`. There are no migration template files to ship in `priv/`. Omit `priv` from the `:files` whitelist. [VERIFIED: direct code inspection of lib/mix/tasks/oban_powertools.install.ex]

```elixir
# Source: PITFALLS.md Pitfall 1 + hex.pm/docs/publish
defp package do
  [
    licenses: ["Apache-2.0"],
    links: %{"GitHub" => @source_url},
    files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
  ]
end
```

**Verification command:**
```bash
mix hex.build && tar tf oban_powertools-0.5.0.tar
# Must NOT contain: test/ examples/ prompts/ .planning/ doc/ erl_crash.dump _build/
# Must contain: lib/ guides/ .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE
```

The `tar tf` command lists the tarball without extracting. There is also a `mix hex.build --unpack` flag that extracts to a temp directory for inspection. [CITED: hex.pm/docs/publish]

### Pattern 5: CHANGELOG.md Structure for First Release

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **Semantic Versioning** headings like **`[0.5.0]`** for **published
Hex releases**. The maintainer tracks internal planning milestones (v1.x, v1.1, etc.)
in `.planning/` — those labels describe shipped tranches of work, **not** a second
installable version axis on Hex. This library remains **0.x** on Hex until a real
**1.0.0** after real adopter feedback. Do not map planning milestones to Hex versions.

## [Unreleased]

<!-- Phases 48-51 accumulate entries here -->

## [0.5.0] - 2026-05-29

### Added

#### Workers & Idempotency
- ...

(etc. per D-10 grouped domains)

---

## Path to 1.0

(per D-08/D-09 — surfaces checklist)
```

### Anti-Patterns to Avoid

- **Manifest seeded at `"0.1.0"` (the current mix.exs version):** Release-please treats this as "already released at 0.1.0" and proposes 0.1.1 or 0.2.0 on the next conventional commit run. Always seed at the version BEFORE the intended first release. For this phase: `"0.0.0"`. [VERIFIED: release-please manifest-releaser docs]
- **Using deprecated `release-as` config key in config.json:** Marked `[DEPRECATED]` in the official schema. Use the `Release-As: 0.5.0` commit footer instead. [VERIFIED: release-please schemas/config.json]
- **Leaving `version: "0.1.0"` bare in `project/0` without `@version`:** release-please can update it, but `docs/0` needs `source_ref: "v#{@version}"` which requires the module attribute. Define `@version` at the top of mix.exs and reference it everywhere.
- **Including `priv` in `:files` when no `priv/` directory exists:** The library has no `priv/` at root. Including it in `:files` does nothing harmful but is misleading. Migrations are generated directly to the host by Igniter, not shipped as template files. Omit `priv` from `:files`.
- **`changelog:` key in `docs/0`:** This key does not exist in ex_doc. The correct mechanism to render CHANGELOG.md on hexdocs is to include it in the `extras` list. [VERIFIED: ex_doc ExDoc.generate/4 docs, ex_doc/mix.exs]
- **`release-please-action@v4` without `permissions: contents: write, pull-requests: write`:** The action requires explicit permissions to create PRs and tags. Missing permissions cause silent failures. [CITED: googleapis/release-please-action README]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hex package publication | Custom `curl` API calls | `mix hex.publish --yes` | Built-in hex client; handles retries, auth, docs upload |
| Release PR + tag creation | Custom GH Actions tag scripts | `googleapis/release-please-action@v4` | Handles conventional commit parsing, CHANGELOG updates, manifest tracking |
| Version detection in `mix.exs` update | Custom sed/awk on mix.exs | release-please `elixir` strategy updater | Handles both `@version` and `version:` patterns; well-tested |
| CHANGELOG formatting | Custom templating | Keep-a-Changelog hand-authored `## [0.5.0]` section | Standard format, readable by hex.pm and release-please |

**Key insight:** This phase is almost entirely configuration and file creation. No new runtime code is written.

---

## Common Pitfalls

### Pitfall 1: Manifest seeded at the current mix.exs version (`0.1.0`)
**What goes wrong:** Release-please sees `"0.1.0"` in the manifest and assumes 0.1.0 was the last published release. It then proposes `0.1.1` (for `fix:` commits) or `0.2.0` (for `feat:` commits) — not `0.5.0`.
**Why it happens:** The bootstrap-elixir-hex-lib skill seeds at `"0.0.0"` for new projects; for retrofits you must seed at CURRENT_VERSION_MINUS_ONE-ish. The simplest universal approach: seed at `"0.0.0"` AND use `Release-As: 0.5.0` commit footer.
**How to avoid:** Always seed at `"0.0.0"` plus add the `Release-As: 0.5.0` footer. The footer overrides version inference entirely for the first run.
**Warning signs:** Release PR proposes 0.1.1 or 0.2.0 instead of 0.5.0.

### Pitfall 2: `release-as` config key left in after first release
**What goes wrong:** If you use the config key (deprecated but still functional), and forget to remove it after the Release PR merges, subsequent release runs propose 0.5.0 indefinitely — no auto-bumping.
**Why it happens:** The key persists in config until manually removed.
**How to avoid:** Use the commit footer mechanism instead. The footer is a one-time signal that applies only to the Release PR it triggers. No cleanup required.
**Warning signs:** Subsequent release PRs after 0.5.0 are still proposing 0.5.0.

### Pitfall 3: GITHUB_TOKEN cannot trigger CI on the Release PR
**What goes wrong:** When release-please uses `secrets.GITHUB_TOKEN` to create the Release PR, GitHub's security model prevents that PR from triggering subsequent `on: pull_request` workflows. The `host-contract-proof.yml` CI will NOT run on the Release PR automatically.
**Why it happens:** GitHub prevents token-created events from triggering further automated workflows to avoid infinite loops.
**How to avoid:** For the 0.5.0 release, manually trigger CI on the Release PR (e.g., push an empty `git commit --allow-empty` to the release branch, or use the GitHub UI "Re-run" button). Future releases: consider a GitHub App token or PAT if CI-on-release-PRs is required. For now, document this as an operator awareness item.
**Warning signs:** Release PR shows no CI checks, or CI shows as "skipped."

### Pitfall 4: `mix hex.publish` ships working tree, not last commit
**What goes wrong:** If there are uncommitted changes in the working tree when `mix hex.publish` runs, those changes ship to hex.pm. In CI this is rare, but if the workflow does any pre-publish transformations that leave files dirty, the tarball is wrong.
**Why it happens:** `mix hex.publish` builds the tarball from the filesystem, not from git history. [CITED: PITFALLS.md Pitfall 17]
**How to avoid:** Run `git status --porcelain` as the FIRST step of the `publish-hex` job and fail if non-empty. The workflow template above includes this gate.
**Warning signs:** `git status --porcelain` output is non-empty before publish.

### Pitfall 5: `docs/0` `changelog:` key (does not exist)
**What goes wrong:** D-12 references a `changelog:` key in `docs/0`. This key does NOT exist in ex_doc. If you add it, ExDoc silently ignores it (or raises if strict validation is enabled).
**Why it happens:** The CONTEXT.md decision was written before verifying the exact ExDoc API.
**How to avoid:** Add `CHANGELOG.md` to the `extras` list in `docs/0`. This causes hexdocs to render it as a navigable documentation page — which is what D-12 intends.

```elixir
extras: ["README.md", "CHANGELOG.md" | Path.wildcard("guides/*.md")]
```

**Warning signs:** CHANGELOG.md not appearing in hexdocs navigation sidebar.

### Pitfall 6: `include-v-in-tag` default and ExDoc `source_ref` mismatch
**What goes wrong:** If `include-v-in-tag` is false, the release tag is `0.5.0` not `v0.5.0`. But `source_ref: "v#{@version}"` constructs `"v0.5.0"`. The tag and the source_ref would mismatch, breaking source links.
**Why it happens:** `include-v-in-tag` defaults to `true` in release-please, so the tag is `v0.5.0` by default. But if it were explicitly set to `false`, the tag would be `0.5.0`.
**How to avoid:** Explicitly set `"include-v-in-tag": true` in `release-please-config.json`. This is a belt-and-suspenders assertion that the default will not be changed accidentally. `source_ref: "v#{@version}"` then matches `v0.5.0`. [CITED: release-please schemas/config.json]

### Pitfall 7: `igniter` unscoped — ships as runtime dep in hex tarball
**What goes wrong:** Without `only: [:dev, :test], runtime: false`, igniter appears as a runtime dependency in the hex package manifest. Every host that adds `oban_powertools` also pulls igniter into their production release.
**Why it happens:** Current `mix.exs` has `{:igniter, "~> 0.8.0"}` with no scope. [VERIFIED: direct inspection]
**How to avoid:** Change to `{:igniter, "~> 0.8.0", only: [:dev, :test], runtime: false}` in the same `mix.exs` edit that adds `package/0`. [CITED: PITFALLS.md Pitfall 14]
**Warning signs:** `mix hex.build` output shows igniter without a `(dev)` qualifier.

---

## Code Examples

### Complete `mix.exs` target state

```elixir
# Source: PITFALLS.md Pitfall 1, 14, 15 + hex.pm/docs/publish + ExDoc.generate/4 docs
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
      docs: docs(),
      package: package()
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      source_url_pattern: "#{@source_url}/blob/v#{@version}/%{path}#L%{line}",
      extras: ["README.md", "CHANGELOG.md" | Path.wildcard("guides/*.md")],
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
          "guides/upgrade-and-compatibility.md",
          "guides/forensics-and-runbook-handoffs.md"  # Fix orphan-extra: add to Operations
        ]
      ]
    ]
  end

  # ... application/0 unchanged ...

  defp deps do
    [
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:igniter, "~> 0.8.0", only: [:dev, :test], runtime: false},  # FIX: was unscoped
      {:telemetry, "~> 1.4"},
      {:jason, "~> 1.4"},
      {:oban, "~> 2.18"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17"},
      {:oban_web, "~> 2.10", optional: true},
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end
end
```

### `release-please-config.json`

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bootstrap-sha": "REPLACE_WITH_FIRST_COMMIT_SHA",
  "include-v-in-tag": true,
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "package-name": "oban_powertools"
    }
  }
}
```

**Note:** `bootstrap-sha` should be set to the output of `git log --reverse --format="%H" | head -1`.

### `.release-please-manifest.json`

```json
{
  ".": "0.0.0"
}
```

**Critical:** Must be `"0.0.0"` — not `"0.1.0"` (the current mix.exs version). If seeded at `"0.1.0"`, release-please proposes `0.1.1` or `0.2.0` next.

### The bootstrap trigger commit

```
chore: bootstrap release-please for public hex release

Release-As: 0.5.0
```

This commit must be pushed to `main` AFTER both config files exist in the repo. Release-please reads the `Release-As:` footer in the commit body and opens a Release PR at 0.5.0.

### `.github/workflows/release-please.yml`

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

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `release-as:` key in config.json | `Release-As: 0.5.0` commit footer | Config key is `[DEPRECATED]` in schemas/config.json |
| Manifest seeded at current version | Manifest seeded at `"0.0.0"` | Current version causes off-by-one; use `"0.0.0"` + `Release-As` footer |
| ExDoc `docs/0` lacks `source_ref` | `source_ref: "v#{@version}"` with `@version` module attribute | `source_ref` defaults to `"main"` without this |
| No `package/0` in mix.exs | Explicit `package/0` with `:files` whitelist | Default includes test/examples/prompts cruft |
| `igniter` as runtime dep | `{:igniter, "~> 0.8.0", only: [:dev, :test], runtime: false}` | Fixes Pitfall 14 |
| CHANGELOG.md absent | CHANGELOG.md at root in Keep-a-Changelog format | Required for hex.pm package page and hexdocs |
| `changelog:` key in docs/0 | CHANGELOG.md in `extras` list | `changelog:` key does not exist in ex_doc |

**Deprecated/outdated:**
- `release-as` config key: deprecated, prefer `Release-As:` commit footer
- ExDoc `docs/0` without `source_ref`: source links default to `main` branch

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `googleapis/release-please-action@v4` is the current stable version. The WebFetch content referenced both v4 and v5; the README explicitly documents v4. | Standard Stack | If v5 is current, the `with:` inputs may differ; verify action version before use |
| A2 | `include-v-in-tag` defaults to `true` (producing `v0.5.0` tags) | Architecture Patterns Pitfall 6 | If default is false, tags would be `0.5.0` without `v` prefix, breaking `source_ref: "v#{@version}"` alignment |
| A3 | `bootstrap-sha` should be the first repo commit SHA | Code Examples | If first commit predates Igniter/release-please support, it may include too much; functionally fine since `Release-As` overrides version anyway |
| A4 | `mix hex.publish --yes` is the correct non-interactive flag | Code Examples | Confirmed from hex docs; `--yes` skips confirmation prompts |

---

## Open Questions

1. **`googleapis/release-please-action` exact current version (v4 vs v5)**
   - What we know: The GitHub repo README documents v4. One WebFetch result mentioned v5.0.0 released April 2026.
   - What's unclear: Whether `@v4` or `@v5` is the correct pin for new setups.
   - Recommendation: Before writing the workflow YAML, check `github.com/googleapis/release-please-action/releases` to confirm the current latest tag. If v5 exists, check whether its inputs changed. If in doubt, pin to `@v4` (the documented stable version) and note for future upgrade.

2. **CI checks on the Release PR**
   - What we know: `GITHUB_TOKEN`-created PRs do not trigger `on: pull_request` workflows. The Release PR will not have `host-contract-proof.yml` checks.
   - What's unclear: Whether this is acceptable for the first release.
   - Recommendation: Document as a known limitation for 0.5.0. The operator should manually verify CI is green on `main` before merging the Release PR. If CI-on-release-PR becomes a requirement, upgrade to a GitHub App token (out of scope for this phase).

3. **`HEX_API_KEY` secret provisioning**
   - What we know: The secret must be created in the GitHub repo settings before the workflow can publish.
   - What's unclear: Whether the user has an existing hex.pm account / API key.
   - Recommendation: Flag as a pre-flight operator step. The publish workflow will fail silently (or with an auth error) if this secret is absent.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | mix.exs editing, `mix hex.build` | ✓ | 1.19.5 | — |
| Mix | `mix hex.build`, `mix docs` | ✓ | bundled with Elixir 1.19.5 | — |
| git | `git status --porcelain`, `git log` for bootstrap-sha | ✓ | (available in CI ubuntu-latest) | — |
| `HEX_API_KEY` GitHub secret | `mix hex.publish` in CI | ✗ (must be provisioned) | — | Manual publish: `mix hex.publish --yes` locally with env set |
| GitHub Actions permissions (contents: write, pull-requests: write) | release-please-action | Must be set in workflow | n/a | — |

**Missing dependencies with no fallback:**
- `HEX_API_KEY` secret must be created in the GitHub repo settings before the publish workflow can succeed. This is a pre-flight operator step.

**Missing dependencies with fallback:**
- If the automated publish workflow fails, `mix hex.publish --yes` can be run locally with `HEX_API_KEY` set in the shell environment, after verifying a clean working tree.

---

## Sources

### Primary (HIGH confidence)
- [googleapis/release-please manifest-releaser docs](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — bootstrap-sha, manifest seeding, release-as, Release-As commit footer
- [googleapis/release-please schemas/config.json](https://github.com/googleapis/release-please/blob/main/schemas/config.json) — `release-as` marked `[DEPRECATED]`
- [googleapis/release-please elixir.ts strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/elixir.ts) — elixir release type confirmed
- [googleapis/release-please commit 1af59a1](https://github.com/googleapis/release-please/commit/1af59a162bc6b858c696a3cb4eee1ed9a47f4256) — `@version` module attribute support confirmed
- [googleapis/release-please-action README](https://github.com/googleapis/release-please-action/blob/main/README.md) — v4 action inputs, outputs, workflow patterns
- [ExDoc ExDoc.generate/4 docs](https://hexdocs.pm/ex_doc/ExDoc.html#generate/4) — `source_url`, `source_ref`, `source_url_pattern` confirmed; no `changelog:` key
- [hex.pm/docs/publish](https://hex.pm/docs/publish) — `package/0` format, `licenses:` SPDX, `:files` whitelist, default files
- [mix hex.publish docs](https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html) — `--yes` flag confirmed
- [ex_doc/mix.exs](https://github.com/elixir-lang/ex_doc/blob/main/mix.exs) — CHANGELOG.md in `extras` pattern confirmed
- Direct code inspection: `/Users/jon/projects/oban_powertools/mix.exs` — current state: no `package/0`, `igniter` unscoped, `version: "0.1.0"` inline, no `@version`, no `source_ref`
- Direct code inspection: `/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex` — migrations generated inline via Igniter, no `priv/` files to ship

### Secondary (MEDIUM confidence)
- [Automating Elixir Releases with Release Please — Elixir School](https://elixirschool.com/blog/managing-releases-with-release-please) — complete release-please workflow for Elixir with hex publish job; manifest approach; `release-type: "elixir"` confirmed

### Tertiary (LOW confidence / training data)
- Release-please `include-v-in-tag` defaults to `true` — not explicitly confirmed from official docs in this session, only from schema description [ASSUMED]
- `googleapis/release-please-action` current stable version is v4 (not v5) — one WebFetch indicated v5.0.0 was released April 2026; README documents v4; treat as A1 open question

---

## Metadata

**Confidence breakdown:**
- Release-please bootstrap mechanism: HIGH — verified from official docs + schema; `release-as` deprecated confirmed
- `@version` update support: HIGH — verified from commit 1af59a1
- `changelog:` key absence: HIGH — verified from ExDoc.generate/4 docs + ex_doc/mix.exs
- No `priv/` to ship: HIGH — verified from direct code inspection of installer
- `include-v-in-tag` default: MEDIUM — schema confirms key exists, default value [ASSUMED] true
- release-please-action version: MEDIUM — README confirms v4; v5 may exist (open question A1)

**Research date:** 2026-05-29
**Valid until:** 2026-06-29 (release-please-action version; fast-moving tooling)
