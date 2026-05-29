---
phase: 47-hex-release-foundation
plan: "01"
subsystem: packaging
tags: [changelog, license, hex-release, apache-2.0, rel-03]
dependency_graph:
  requires: []
  provides: [CHANGELOG.md, LICENSE]
  affects: [47-02-PLAN.md]
tech_stack:
  added: []
  patterns: [keep-a-changelog-1.1.0, spdx-apache-2.0, path-to-1.0-checklist]
key_files:
  created:
    - CHANGELOG.md
    - LICENSE
  modified: []
decisions:
  - "CHANGELOG.md authored with 10 domain-grouped subheadings (D-10), planning milestones prose note (D-11), and per-surface path-to-1.0 checklist for all 4 D-09 surfaces (D-08/D-12)"
  - "LICENSE uses verbatim Apache-2.0 text; copyright line set to 2026 szTheory / Oban Powertools; SPDX id Apache-2.0 matches planned package/0 declaration in plan 02"
  - "No internal v1.x milestones backfilled as prior changelog entries (D-13)"
metrics:
  duration: "145s"
  completed_date: "2026-05-29"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 47 Plan 01: CHANGELOG.md and Apache-2.0 LICENSE Summary

**One-liner:** Hand-authored CHANGELOG.md in Keep-a-Changelog 1.1.0 format with 0.5.0 release notes, planning-vs-Hex clarification, and a four-surface path-to-1.0 checklist; verbatim Apache-2.0 LICENSE file ready for SPDX match in plan 02.

## What Was Built

Two greenfield source files at repo root that plan 02's `mix docs` (extras) and `mix hex.build` (`:files`) both reference:

### CHANGELOG.md

- Keep-a-Changelog 1.1.0 format with SemVer adherence header linking keepachangelog.com and semver.org.
- **"Planning milestones vs Hex releases"** prose note (D-11) clarifying that internal v1.x milestone labels in `.planning/` are NOT Hex version axis and the library stays 0.x until real adopter feedback.
- **`## [Unreleased]`** section with HTML comment noting Phases 48-51 accumulate here.
- **`## [0.5.0] - 2026-05-29`** with a single `### Added` block, feature-grouped into 10 `####` domain subheadings: Workers & Idempotency; Limiters & Explain; Cron; Workflows; Lifeline & Repairs; Native `/ops/jobs` Shell; Operator API (Single + Bulk); Telemetry Contract; Install & Migrations; Optional Oban Web Bridge.
- **`## Path to 1.0`** section (D-08, D-12) with the hybrid per-surface + stability-window gate documented as a per-surface checklist for all four D-09 surfaces: Installer/Migration Contract, Operator Elixir API, Frozen Telemetry `@contract`, Host-Ownership Boundary.
- No `## [1.x.y]` headings; no backfilled internal milestone entries (D-13).

### LICENSE

- Complete verbatim Apache License Version 2.0 text.
- All 9 numbered sections (1. Definitions through 9. Accepting Warranty).
- APPENDIX boilerplate with copyright line: `Copyright 2026 szTheory / Oban Powertools`.
- SPDX identifier `Apache-2.0` — matches the `licenses: ["Apache-2.0"]` declaration that plan 02 adds to `package/0` (D-07).

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author CHANGELOG.md | 2362167 | CHANGELOG.md (created) |
| 2 | Add verbatim Apache-2.0 LICENSE | 4aa85f0 | LICENSE (created) |

## Verification Results

All automated verification gates passed:

- `test -f CHANGELOG.md && grep -q '## \[0.5.0\]' CHANGELOG.md && grep -q '## \[Unreleased\]' CHANGELOG.md && grep -qi 'Path to 1.0' CHANGELOG.md && grep -qi 'keepachangelog' CHANGELOG.md && ! grep -qE '## \[1\.[0-9]+\.[0-9]+\]' CHANGELOG.md` — PASS
- `test -f LICENSE && grep -q 'Apache License' LICENSE && grep -q 'Version 2.0, January 2004' LICENSE && grep -q 'http://www.apache.org/licenses/LICENSE-2.0' LICENSE && grep -q 'APPENDIX' LICENSE` — PASS

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both files are complete, hand-authored artifacts with no placeholder content.

## Threat Flags

No new threat surface introduced beyond what is documented in the plan's threat model. Both files are static content artifacts:
- `CHANGELOG.md`: authored from public roadmap domains only; no internal `.planning/` paths, secrets, or host-specific data included (T-47-01 mitigated).
- `LICENSE`: verbatim Apache-2.0 canonical text; SPDX id `Apache-2.0` (T-47-02 accepted per plan).

## Self-Check: PASSED

- `/Users/jon/projects/oban_powertools/CHANGELOG.md` — FOUND
- `/Users/jon/projects/oban_powertools/LICENSE` — FOUND
- Commit 2362167 — FOUND in git log
- Commit 4aa85f0 — FOUND in git log
