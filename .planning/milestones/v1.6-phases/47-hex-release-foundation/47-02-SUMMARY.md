---
phase: 47-hex-release-foundation
plan: "02"
subsystem: packaging
tags: [hex, mix-exs, ex-doc, release, packaging]
dependency_graph:
  requires: ["47-01"]
  provides: ["publishable-hex-package", "ex-doc-source-links", "readme-install-version"]
  affects: ["mix.exs", "README.md"]
tech_stack:
  added: []
  patterns: ["hex-package-declaration", "module-attribute-version", "ex-doc-source-links", "file-whitelist"]
key_files:
  created: []
  modified:
    - mix.exs
    - README.md
decisions:
  - "Added description field to package/0 (required by mix hex.build validation — not in plan)"
  - "Used defp package (private function) — correct Elixir convention for mix.exs helpers"
  - "priv intentionally omitted from :files whitelist (no priv/ directory exists; Igniter generates migrations inline to host)"
  - "No changelog: key in docs/0 (does not exist in ex_doc; CHANGELOG.md in extras is the correct mechanism)"
metrics:
  duration: "3m"
  completed_date: "2026-05-29"
  tasks_completed: 3
  files_modified: 2
---

# Phase 47 Plan 02: Hex Package Configuration & ExDoc Source Links Summary

mix.exs now produces a correct publishable 0.5.0 hex package with explicit :files whitelist, igniter scoped to dev/test, ExDoc source links pinned to the v0.5.0 tag, CHANGELOG.md rendered as an extra, and README advertising ~> 0.5 with a 0.x stability banner.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | @version, package/0 :files whitelist, igniter scope; tarball verified | 9def318 | mix.exs |
| 2 | docs/0 source links + CHANGELOG extra; mix docs verified | 4fa16ac | mix.exs |
| 3 | README install snippet ~> 0.5 + 0.x stability banner | b24cebc | README.md |

## What Was Built

**mix.exs changes (Tasks 1 + 2):**
- `@version "0.5.0"` and `@source_url` module attributes added above `def project`
- `version: "0.1.0"` replaced with `version: @version`
- `package: package()` added to `project/0`
- New `defp package/0` with `description:`, `licenses: ["Apache-2.0"]`, `links:`, and `:files` whitelist
- `:files` whitelist: `lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE`
- `priv` omitted from `:files` (RECONCILIATION: no `priv/` directory exists; Igniter generates migrations inline to host)
- `igniter` dep scoped: `only: [:dev, :test], runtime: false` (was unscoped — Pitfall 14 fixed)
- `docs/0` additions: `source_url: @source_url`, `source_ref: "v#{@version}"` (= "v0.5.0"), `source_url_pattern:`
- `extras:` changed from `["README.md" | ...]` to `["README.md", "CHANGELOG.md" | ...]`
- `"guides/forensics-and-runbook-handoffs.md"` added to `"Operations"` group (orphan-extra fixed)
- No `changelog:` key added (RECONCILIATION: key does not exist in ex_doc)

**README.md changes (Task 3):**
- Install snippet updated from `"~> 0.1.0"` to `"~> 0.5"` (minor-only pessimistic constraint)
- 0.x stability callout added below opening paragraph: no API freeze, v1.x planning milestones do not map to Hex versions

## Verification Results

All plan success criteria satisfied:

- `mix hex.build` produces `oban_powertools-0.5.0.tar` — PASS
- Tarball includes: `lib/`, `guides/`, `.formatter.exs`, `mix.exs`, `mix.lock`, `README.md`, `CHANGELOG.md`, `LICENSE` — PASS
- Tarball excludes: `test/`, `.planning/`, `prompts/`, `doc/`, `erl_crash.dump` — PASS
- `igniter` shows with dev/test scope, no runtime — PASS
- `mix docs` builds without error; `doc/changelog.html` exists — PASS
- `source_ref` = `"v0.5.0"` (matches plan 03 tag format) — PASS
- `priv/` does not exist at repo root; `:files` omits `priv` — PASS
- README shows `~> 0.5` + 0.x stability note — PASS

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing] Added required `description` field to `package/0`**
- **Found during:** Task 1 — first `mix hex.build` run
- **Issue:** `mix hex.build` failed with `Missing metadata fields: description`. The plan did not include `description:` in the `package/0` shape.
- **Fix:** Added `description: "A host-owned operations layer for Oban-backed Phoenix applications."` to `package/0`. This is required by hex.pm for a publishable package.
- **Files modified:** `mix.exs`
- **Commit:** 9def318

### Reconciliations (plan-documented)

Both reconciliations pre-documented in the plan objective were applied as specified:

1. **priv/ omission:** No `priv/` directory exists at library root — migrations generated inline by Igniter. `priv` correctly omitted from `:files`.
2. **changelog: key omission:** ExDoc has no `changelog:` key. CHANGELOG.md added to `extras` list instead — correct mechanism for rendering it in hexdocs nav.

## Known Stubs

None. All plan objectives fully satisfied with real implementation.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. This plan modifies only build configuration (`mix.exs`) and documentation (`README.md`). No new threat surface.

## Self-Check: PASSED

All committed files verified:
- `/Users/jon/projects/oban_powertools/mix.exs` — exists, contains @version, package/0, docs/0 with source_ref
- `/Users/jon/projects/oban_powertools/README.md` — exists, contains ~> 0.5 and 0.x banner
- Commits 9def318, 4fa16ac, b24cebc — all present in git log
