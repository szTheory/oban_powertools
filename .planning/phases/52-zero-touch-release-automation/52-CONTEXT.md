# Phase 52: Zero-Touch Release Automation - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver zero-touch release automation: after `git push origin main`, release-please opens a release PR, CI runs on it, `release-pr-automerge.yml` squash-merges the PR once `ci-gate` passes, and the full release pipeline (gate-ci-green → publish-hex → verify-published) fires without human intervention.

**Key finding:** The implementation is already committed (`c14c6f3`). `release-pr-automerge.yml` was transplanted from lattice_stripe with the branch name adapted to `oban_powertools`. The phase directory and PLAN.md do not yet exist — the work was done outside the GSD phase lifecycle.

**Scope:** This phase is verification + formal GSD closure. No new library capability, no changes to the release pipeline mechanics (Phase 47), and no changes to the committed workflow unless inspection reveals a defect.

</domain>

<decisions>
## Implementation Decisions

### Plan scope
- **D-01:** The PLAN.md is **verify-only** — the main deliverable is already committed. No retroactive documentation of the lattice_stripe transplant decisions is needed. Plan tasks are: inspection checklist + add `actionlint` to CI.

### Verification approach
- **D-02:** Verification = **actionlint + inspection checklist** (not a live workflow_dispatch dry-run).
  - Add an `actionlint` job to `.github/workflows/ci.yml` and wire it into `ci-gate`'s `needs:` — this catches YAML correctness issues on all future workflow PRs (permanent shift-left benefit, ~80% of failure mode coverage per ecosystem research).
  - One-time inspection checklist confirms: branch name matches `release-please-config.json`, `ci-gate` name matches `ci.yml`, permissions block is sufficient, stale-SHA guard is present, Bootstrap CI step is present, Trigger release.yml step is present.
  - End-to-end is accepted as "verified on the next actual release cycle" — no open release PR exists to dry-run against, and the ecosystem pattern (release-please, semantic-release, npm changesets) validates that inspection + linting is the idiomatic pre-release check.

### Workflow correctness
- **D-03:** The committed workflow is correct as-is. No tweaks needed.
  - The two major GitHub Actions automerge footguns are already handled:
    1. "GITHUB_TOKEN merges don't emit push events" → handled by the explicit Bootstrap CI dispatch step
    2. Stale SHA from prior `workflow_run` events → handled by the `head_oid != HEAD_SHA` guard
  - Permissions (`contents: write`, `pull-requests: write`, `actions: write`) are sufficient for squash-merge + dispatch.
  - The 12 × 30s retry loop and `--admin` fallback handle branch protection catch-up timing.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Workflow files (the deliverable and its dependencies)
- `.github/workflows/release-pr-automerge.yml` — the committed deliverable; read before any inspection task
- `.github/workflows/ci.yml` — defines `ci-gate` (the job name the automerge checks); read before adding actionlint
- `.github/workflows/release.yml` — downstream pipeline triggered after automerge (release-please → gate-ci-green → publish-hex → verify-published)

### Release configuration
- `release-please-config.json` — defines `package-name: "oban_powertools"` (source of the branch name `release-please--branches--main--components--oban_powertools`)
- `.release-please-manifest.json` — current version manifest

### Project memory
- Memory: `hex-release-pipeline-gotchas.md` — PAT not App, skip provenance, ci-gate aggregator pattern, tag format

</canonical_refs>

<code_context>
## Codebase Context

### Existing workflow shape
- `ci-gate` in `ci.yml` is a fan-in job with `needs: [format, compile, test, docs_package]` and `if: always()` — all lanes must be `success`. Branch protection requires `ci-gate` as a required status check.
- `release-pr-automerge.yml` checks the `ci-gate` job name exactly — any rename to `ci-gate` in `ci.yml` must be reflected here too.
- `actionlint` job should be added to `ci.yml` and added to `ci-gate`'s `needs:` array.

### Branch name derivation
- `release-please-config.json`: `"packages": { ".": { "package-name": "oban_powertools" } }`
- release-please branch format: `release-please--branches--{base-branch}--components--{package-name}`
- Resolved: `release-please--branches--main--components--oban_powertools`
- This exact string appears in `release-pr-automerge.yml` lines 45, 49, 59, 104 — all correct.

### Reusable patterns
- `dependabot-automerge.yml` is a reference for the automerge pattern already used in this repo — same `gh pr merge --squash` approach, different trigger.
- `ci.yml` jobs use `actions/cache` and `erlef/setup-beam` — new `actionlint` job does NOT need Elixir/OTP setup (it's a Go binary or a composite action).

</code_context>
