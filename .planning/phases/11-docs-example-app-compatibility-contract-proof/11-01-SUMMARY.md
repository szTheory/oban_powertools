---
phase: 11-docs-example-app-compatibility-contract-proof
plan: 01
subsystem: docs
tags: [ex_doc, hexdocs, readme, guides, phoenix, oban]
requires:
  - phase: 10-operator-ux-coherence-mutation-safety
    provides: support-truth for native audited mutations and the read-only oban_web bridge
provides:
  - short README entry contract for day-0 adoption
  - ExDoc extras and grouped guide structure for day-0 and future day-2 docs
  - installation, first-session, and canonical example-host walkthrough guides
affects: [README, HexDocs, adoption, example-host, support-truth]
tech-stack:
  added: [ex_doc]
  patterns: [README-as-entrypoint, wildcard-backed ExDoc guides, temp-copy docs verification]
key-files:
  created:
    - .planning/phases/11-docs-example-app-compatibility-contract-proof/11-01-SUMMARY.md
    - guides/installation.md
    - guides/first-operator-session.md
    - guides/example-app-walkthrough.md
  modified:
    - README.md
    - mix.exs
key-decisions:
  - "Kept README intentionally short and moved day-0 detail into ExDoc-backed guides."
  - "Used Path.wildcard(\"guides/*.md\") plus grouped extras so Wave 2 guides publish automatically when added."
  - "Verified mix docs in a temporary repo copy to avoid mutating unowned files such as mix.lock."
patterns-established:
  - "Public docs pattern: concise README entrypoint backed by versioned guides."
  - "Ownership truth pattern: repeat auth, display_policy, router-scope, and read-only bridge boundaries across docs."
requirements-completed: [DOC-01, HST-03]
duration: 36min
completed: 2026-05-22
---

# Phase 11 Plan 01: Docs Entry Contract Summary

**Short README entry contract, ExDoc guide wiring, and exact day-0 host steps for display policy, router mount, and first operator success**

## Performance

- **Duration:** 36 min
- **Started:** 2026-05-22T00:00:00Z
- **Completed:** 2026-05-22T00:36:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Reworked the public README into a concise day-0 entrypoint with explicit host-owned `display_policy` wiring and support-truth language.
- Added ExDoc configuration in `mix.exs` so `README.md` is the entry page and guide extras are grouped into day-0 and future day-2 lanes.
- Wrote the exact installation, first-operator-session, and canonical example-host walkthrough guides under `guides/`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the canonical docs surface and shrink README to the honest entry contract** - `525c8c3` (feat)
2. **Task 2: Write the exact day-0 guides and close the display_policy gap in docs** - `3bc0118` (docs)

## Files Created/Modified

- `README.md` - short day-0 entrypoint with explicit support truth, guide links, and the `examples/phoenix_host` pointer
- `mix.exs` - adds `{:ex_doc, ...}` and wildcard-backed `docs:` configuration with `groups_for_extras`
- `guides/installation.md` - exact install path for `display_policy`, `auth_module`, router scope, migrations, and optional `oban_web`
- `guides/first-operator-session.md` - first successful `/ops/jobs` walkthrough with one native audited mutation and the read-only bridge note
- `guides/example-app-walkthrough.md` - canonical fixture explanation for `examples/phoenix_host` and the generator-driven host path

## Decisions Made

- Kept the README intentionally short and pushed the operational detail into guides, matching the phase’s HexDocs-first docs architecture.
- Treated `display_policy` as an explicit host-owned step instead of implying the installer scaffolds it.
- Used a temporary repo copy for `mix docs` verification because fetching `ex_doc` in-place would have modified `mix.lock`, which was outside the owned file set for this task.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix docs` required `ex_doc`, which would normally update `mix.lock`. Verification was run in a temporary repo copy to avoid mutating files outside the allowed ownership set.
- `mix docs` still emits a pre-existing warning from `lib/oban_powertools/web/router.ex` about a hidden `ObanPowertools.Web.LiveAuth` module reference. That warning is outside the files owned for this task.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Day-0 docs now point adopters from README into versioned guides without hiding host-owned seams.
- Wave 2 can add more `guides/*.md` files and have them published automatically through the wildcard-backed ExDoc extras.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and requirements/state metadata were intentionally not updated because this execution was constrained to the owned files listed in the request.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/11-docs-example-app-compatibility-contract-proof/11-01-SUMMARY.md`.
- Task commit `525c8c3` exists in git history.
- Task commit `3bc0118` exists in git history.

---
*Phase: 11-docs-example-app-compatibility-contract-proof*
*Completed: 2026-05-22*
