# Phase 52: Zero-Touch Release Automation - Research

**Researched:** 2026-05-30
**Domain:** GitHub Actions workflow verification + actionlint CI integration
**Confidence:** HIGH

## Summary

Phase 52 is verify-only. The deliverable (`release-pr-automerge.yml`) was committed in `c14c6f3` outside the GSD lifecycle. The plan has two tasks: (1) run an inspection checklist against the committed workflow to confirm all footguns are handled, and (2) add an `actionlint` job to `ci.yml` wired into `ci-gate`'s `needs:` array — a permanent shift-left benefit that catches YAML correctness issues on all future workflow PRs.

All six inspection checklist items have been pre-verified during research and pass. The workflow is correct as-is (D-03). The only code change in this phase is adding the `actionlint` job to `ci.yml`.

**Primary recommendation:** Add `raven-actions/actionlint@205b530c5d9fa8f44ae9ed59f341a0db994aa6f8 # v2.1.2` as a job in `ci.yml`, then add `actionlint` to `ci-gate`'s `needs:` array and its lane verification loop. No changes to `release-pr-automerge.yml`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01: Plan scope** — The PLAN.md is verify-only — the main deliverable is already committed. No retroactive documentation of the lattice_stripe transplant decisions is needed. Plan tasks are: inspection checklist + add `actionlint` to CI.

**D-02: Verification approach** — Verification = actionlint + inspection checklist (not a live workflow_dispatch dry-run).
- Add an `actionlint` job to `.github/workflows/ci.yml` and wire it into `ci-gate`'s `needs:` — this catches YAML correctness issues on all future workflow PRs (permanent shift-left benefit, ~80% of failure mode coverage per ecosystem research).
- One-time inspection checklist confirms: branch name matches `release-please-config.json`, `ci-gate` name matches `ci.yml`, permissions block is sufficient, stale-SHA guard is present, Bootstrap CI step is present, Trigger release.yml step is present.
- End-to-end is accepted as "verified on the next actual release cycle" — no open release PR exists to dry-run against.

**D-03: Workflow correctness** — The committed workflow is correct as-is. No tweaks needed.
- "GITHUB_TOKEN merges don't emit push events" → handled by the explicit Bootstrap CI dispatch step.
- Stale SHA from prior `workflow_run` events → handled by the `head_oid != HEAD_SHA` guard.
- Permissions (`contents: write`, `pull-requests: write`, `actions: write`) are sufficient.
- The 12 × 30s retry loop and `--admin` fallback handle branch protection catch-up timing.

### Claude's Discretion

None stated.

### Deferred Ideas (OUT OF SCOPE)

None stated.
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release PR automerge | CI/CD layer (GitHub Actions) | — | Triggered by `workflow_run` from CI; logic lives entirely in the runner |
| Workflow YAML linting | CI/CD layer (GitHub Actions) | — | actionlint runs as a CI job; no application code involved |
| ci-gate fan-in aggregation | CI/CD layer (GitHub Actions) | — | Branch protection required status check; all lanes feed into it |

## Inspection Checklist: Pre-Verified Findings

All six items from D-02 were verified against the committed file during research.

| Check | Finding | Status |
|-------|---------|--------|
| Branch name matches `release-please-config.json` derivation | Hardcoded on lines 45, 48, 59 as `release-please--branches--main--components--oban_powertools`; `package-name: "oban_powertools"` in config confirms derivation | PASS |
| `ci-gate` job name in automerge matches `ci.yml` | `release-pr-automerge.yml` filters `run.name === 'ci-gate'`; `ci.yml` job is `name: ci-gate` | PASS |
| Permissions block sufficient | `contents: write`, `pull-requests: write`, `actions: write` — covers squash-merge, PR label reads, `gh workflow run` dispatch | PASS |
| Stale-SHA guard present | Line 119: `if [ "$head_oid" != "$HEAD_SHA" ]` exits 0 on stale `workflow_run` events | PASS |
| Bootstrap CI step present | "Bootstrap CI on merge commit" step dispatches `ci.yml --ref main` after merge (workaround for GITHUB_TOKEN not emitting push events) | PASS |
| Trigger release.yml step present | "Trigger release workflow after merge" step dispatches `release.yml` after merge | PASS |

Additional correctness observations verified during research:

- `workflow_run: workflows: [CI]` matches `ci.yml`'s `name: CI` exactly [VERIFIED: read source]
- Title guard pattern `^chore\(main\):\ release\ ` matches release-please's elixir PR title format [VERIFIED: read source]
- 12 × 30s retry loop (`seq 1 12`) + `--admin` fallback confirmed present [VERIFIED: read source]
- `autorelease: pending` label guard present [VERIFIED: read source]

## Standard Stack

### Core (actionlint integration only)

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `raven-actions/actionlint` | v2.1.2 (SHA: `205b530c5d9fa8f44ae9ed59f341a0db994aa6f8`) | Run actionlint in GitHub Actions CI | SHA-pinnable composite action; consistent with project's all-actions-SHA-pinned convention; auto-installs actionlint binary + shellcheck + pyflakes; no Elixir/OTP setup required |
| `rhysd/actionlint` (binary) | v1.7.12 (latest as of 2026-05-30) | Underlying static checker | De facto standard for GitHub Actions YAML linting; 3.9k stars; active (last release 2026-04-19) |

[VERIFIED: GitHub API] `raven-actions/actionlint` v2.1.2 tag SHA `205b530c5d9fa8f44ae9ed59f341a0db994aa6f8` confirmed via `gh api`.
[VERIFIED: GitHub API] `rhysd/actionlint` latest release is v1.7.12 (tag SHA `914e7df21a07ef503a81201c76d2b11c789d3fca`).

### Why `raven-actions/actionlint` over alternatives

| Alternative | Problem | Verdict |
|-------------|---------|---------|
| `docker://rhysd/actionlint:latest` | Docker `latest` tag cannot be SHA-pinned; inconsistent with project convention | Rejected |
| `bash <(curl ...)` download script | `curl \| bash` anti-pattern; no integrity guarantee; no pinning | Rejected |
| `uses: docker://rhysd/actionlint:1.7.12` | Digest-pinned Docker not supported by GitHub Actions runner in `uses:` | Rejected |
| `raven-actions/actionlint@v2.1.2` | Mutable tag pointer — project uses full SHA pins for all actions | Use SHA form instead |

**Recommended form:**
```yaml
- uses: raven-actions/actionlint@205b530c5d9fa8f44ae9ed59f341a0db994aa6f8 # v2.1.2
```

## Architecture Patterns

### System Architecture Diagram

```
git push origin main
        │
        ▼
  release.yml (workflow_dispatch / push: main)
        │
        ▼
  release-please-action ──────────► opens/updates Release PR
                                              │
                         CI runs on PR branch │ (RELEASE_PLEASE_TOKEN enables this)
                                              ▼
                                         ci.yml jobs
                                    ┌────────────────────┐
                                    │ format             │
                                    │ compile            │
                                    │ test               │
                                    │ docs_package       │
                                    │ actionlint  ◄──── (NEW)
                                    └────────┬───────────┘
                                             │ all lanes success
                                             ▼
                                          ci-gate ──► GitHub check: "ci-gate"
                                             │
                              workflow_run (CI) completed
                                             │
                                             ▼
                              release-pr-automerge.yml
                                    │
                                    ├─ Verify: branch starts with release-please--
                                    ├─ Verify: ci-gate == success on head SHA
                                    ├─ Verify: PR title matches ^chore(main): release
                                    ├─ Verify: autorelease: pending label present
                                    ├─ Verify: head_oid == HEAD_SHA (stale-SHA guard)
                                    ├─ gh pr merge --squash (12× retry + --admin fallback)
                                    ├─ Bootstrap CI: gh workflow run ci.yml --ref main
                                    └─ gh workflow run release.yml
                                                   │
                                                   ▼
                                           release.yml (dispatch)
                                    ┌─────────────────────────┐
                                    │ release-please-action   │ (creates tag + GH Release)
                                    │ gate-ci-green           │ (polls ci-gate on release SHA)
                                    │ publish-hex             │ (mix hex.publish)
                                    │ verify-published        │ (REL-04 proof)
                                    └─────────────────────────┘
```

### Actionlint Job Pattern (for ci.yml)

```yaml
# Source: raven-actions/actionlint README + project SHA-pinning convention
actionlint:
  name: Lint workflows
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
    - uses: raven-actions/actionlint@205b530c5d9fa8f44ae9ed59f341a0db994aa6f8 # v2.1.2
```

No `with:` inputs needed — defaults are correct:
- `fail-on-error: true` (default) — fail the job on any actionlint error
- `shellcheck: true` (default) — catches shell script issues in `run:` blocks
- `cache: true` (default) — caches actionlint binary across runs

### ci-gate Update Pattern

The `ci-gate` job needs two edits:

1. Add `actionlint` to the `needs:` array:
```yaml
needs: [format, compile, test, docs_package, actionlint]
```

2. Add `ACTIONLINT` to the environment block and lane loop in the verification step:
```yaml
env:
  FORMAT: ${{ needs.format.result }}
  COMPILE: ${{ needs.compile.result }}
  TEST: ${{ needs.test.result }}
  DOCS_PACKAGE: ${{ needs.docs_package.result }}
  ACTIONLINT: ${{ needs.actionlint.result }}
run: |
  set -euo pipefail
  failed=0
  for lane in FORMAT COMPILE TEST DOCS_PACKAGE ACTIONLINT; do
```

### Anti-Patterns to Avoid

- **Modifying `release-pr-automerge.yml`:** D-03 locks this as correct. Any edit requires discovering a genuine defect first.
- **Using `uses: raven-actions/actionlint@v2` (mutable tag):** All other actions in `ci.yml` use full SHA pins. Use `@205b530c5d9fa8f44ae9ed59f341a0db994aa6f8 # v2.1.2`.
- **Adding Elixir/OTP setup to actionlint job:** actionlint is a Go binary; it does not need `erlef/setup-beam`. The job only needs checkout + the action.
- **Forgetting the lane variable in the ci-gate loop:** If `ACTIONLINT` is added to `env:` but not to the `for lane in ...` loop, the gate won't actually enforce it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GitHub Actions YAML syntax validation | Custom linter / regex checks | `rhysd/actionlint` via `raven-actions/actionlint` | actionlint understands the full GitHub Actions expression syntax, matrix expansion, reusable workflow inputs/outputs — regex can't |
| SHA-pinning lookups | Manual `git ls-remote` | `gh api repos/{owner}/{repo}/git/refs/tags/{tag}` | Reliable, scriptable, no local clone needed |

## Common Pitfalls

### Pitfall 1: ci-gate env block out of sync with needs array

**What goes wrong:** Adding `actionlint` to `needs:` but forgetting to add `ACTIONLINT` to the `env:` block (or the `for lane in` loop) means `ci-gate` succeeds even when actionlint fails — silently defeating the gate.

**Why it happens:** The env variables and the loop variable list are written separately and are not structurally linked.

**How to avoid:** Edit both in the same task. The canonical pattern: `needs:` array, `env:` block, and `for lane in` loop must all be kept in sync.

**Warning signs:** actionlint job shows red in the PR checks list, but ci-gate still shows green.

### Pitfall 2: actionlint flags its own job definition

**What goes wrong:** actionlint checks all `.github/workflows/*.yml` including `ci.yml` itself. If the newly added actionlint job has a YAML error, actionlint will flag it on the next run.

**Why it happens:** Self-referential linting.

**How to avoid:** The job pattern above (no complex expressions, no shell scripts) is safe. Paste exactly as specified.

### Pitfall 3: Docker approach cannot be SHA-pinned

**What goes wrong:** Using `docker://rhysd/actionlint:latest` instead of the action — `latest` is a mutable tag and cannot be pinned to a digest in the GitHub Actions `uses:` field.

**Why it happens:** rhysd/actionlint's official docs show the Docker approach as one option without emphasizing the security tradeoff for repos with SHA-pinning discipline.

**How to avoid:** Use `raven-actions/actionlint@SHA` as documented above.

## Package Legitimacy Audit

> This phase installs a GitHub Action (not an npm/pip/cargo package). The slopcheck tool applies to package registries, not GitHub Actions. Legitimacy is assessed by repository metrics instead.

| Action | Source | Age | Stars | Forks | Last Push | Disposition |
|--------|--------|-----|-------|-------|-----------|-------------|
| `raven-actions/actionlint` | github.com/raven-actions/actionlint | ~3 yrs (created 2023-05-01) | 44 | 11 | 2026-05-29 | Approved — actively maintained wrapper for rhysd/actionlint; no npm/pip equivalent |
| `rhysd/actionlint` (binary) | github.com/rhysd/actionlint | ~5 yrs (created 2021-05-25) | 3,910 | 227 | 2026-04-19 | Approved — de facto standard; used by super-linter, reviewdog ecosystem |

[VERIFIED: GitHub API] Star counts, fork counts, creation dates, and push dates confirmed via `gh api`.

**slopcheck:** N/A — GitHub Actions are not registry packages. No npm/pip/cargo install occurs.

## Runtime State Inventory

> This phase does not rename, refactor, or migrate anything. No runtime state is affected.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by inspection | None |
| Live service config | None — GitHub Actions workflow files are in git | None |
| OS-registered state | None | None |
| Secrets/env vars | None — no new secrets; `GITHUB_TOKEN` already in scope | None |
| Build artifacts | None | None |

## Environment Availability

> This phase runs entirely in GitHub Actions CI runners. No local tool installs are required.

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| GitHub Actions runner (ubuntu-latest) | actionlint job | ✓ | Provided by GitHub |
| `raven-actions/actionlint@v2.1.2` | actionlint job | ✓ | Action auto-installs binary on runner |
| `GITHUB_TOKEN` | release-pr-automerge.yml | ✓ | Auto-provided by GitHub Actions |
| `RELEASE_PLEASE_TOKEN` | release.yml (pre-existing) | ✓ | Already set as repo secret (Phase 47) |

**Missing dependencies with no fallback:** None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (existing) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test --exclude host_contract` |
| Full suite command | `mix test --exclude host_contract` |

### Phase Requirements → Test Map

This phase is process automation (no REQ-ID). The verification deliverables are:

| Deliverable | Behavior | Test Type | Automated Command | File Exists? |
|-------------|----------|-----------|-------------------|-------------|
| Inspection checklist | Six checklist items pass against `release-pr-automerge.yml` | Manual inspection (CI YAML, not Elixir code) | N/A — manual-only; verified during research | N/A |
| actionlint job added | `actionlint` job exists in `ci.yml` and is wired into `ci-gate` | Structural inspection | N/A — no unit test for CI YAML; actionlint itself validates CI YAML on the PR | N/A |
| actionlint runs | actionlint job passes when `ci.yml` edit is opened as a PR | CI integration | Verified when PR is opened (workflow_run) | CI — not file |

**Manual-only justification:** Workflow YAML files cannot be tested with `mix test`. actionlint itself is the automated validator — running it on the PR that adds the actionlint job completes the feedback loop.

### Wave 0 Gaps

None — no new test files needed. The existing test suite is unchanged.

## Security Domain

> `security_enforcement` is absent in config (treated as enabled). ASVS categories assessed for this phase.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | N/A — workflow uses GITHUB_TOKEN (GitHub-managed) |
| V3 Session Management | No | N/A |
| V4 Access Control | Yes (minimal) | Permissions scoped to minimum required: `contents: write`, `pull-requests: write`, `actions: write` — no `id-token: write`, no `packages: write` |
| V5 Input Validation | Yes (minimal) | Workflow validates: branch name prefix, PR title regex, `autorelease: pending` label, stale-SHA guard, ci-gate success before merge |
| V6 Cryptography | No | N/A |

### Known Threat Patterns for GitHub Actions

| Pattern | STRIDE | Standard Mitigation | Phase Status |
|---------|--------|---------------------|--------------|
| SHA injection via stale `workflow_run` | Tampering | `head_oid != HEAD_SHA` stale-SHA guard | Present in committed workflow |
| Privilege escalation via `--admin` merge | Elevation | `--admin` is fallback only, only reached after branch protection timing delay | Acceptable — release automation requires it |
| Untrusted PR title in bash | Tampering | Title regex validated before any action taken; `gh pr merge` not called on mismatch | Present in committed workflow |
| Workflow YAML injection | Tampering | actionlint (once added) statically validates all workflow files on every PR | Will be added by this phase |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual merge of release PRs | `workflow_run` → automerge on `ci-gate` success | Phase 52 | Zero-touch: no human merge step |
| No workflow YAML linting | `actionlint` in `ci-gate` | Phase 52 | Catches workflow errors before they reach main |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `raven-actions/actionlint` v2.1.2 is the current latest release | Standard Stack | Planner should verify via `gh api repos/raven-actions/actionlint/releases/latest` before writing the step |

**Note:** A1 is LOW risk — even if a newer patch is released between research and planning, v2.1.2 is correct. The SHA `205b530c5d9fa8f44ae9ed59f341a0db994aa6f8` uniquely identifies the commit regardless of tag movement.

## Open Questions

None. All CONTEXT.md decisions are locked. All inspection items pre-verified. The only open item is end-to-end smoke test, which D-02 explicitly defers to "the next actual release cycle."

## Sources

### Primary (HIGH confidence)
- [VERIFIED: GitHub API] `gh api repos/raven-actions/actionlint/git/refs/tags/v2.1.2` — SHA `205b530c5d9fa8f44ae9ed59f341a0db994aa6f8`, type `commit`
- [VERIFIED: GitHub API] `gh api repos/rhysd/actionlint/releases/latest` — v1.7.12
- [VERIFIED: read source] `.github/workflows/release-pr-automerge.yml` — all six inspection items verified
- [VERIFIED: read source] `.github/workflows/ci.yml` — `ci-gate` job name, `needs:` array structure, SHA-pinning pattern
- [VERIFIED: read source] `release-please-config.json` — `package-name: "oban_powertools"` confirming branch derivation

### Secondary (MEDIUM confidence)
- [CITED: github.com/rhysd/actionlint/blob/main/docs/usage.md] — integration approaches (Docker, download script, action wrapper)
- [CITED: github.com/marketplace/actions/actionlint] — raven-actions/actionlint v2.1.2 current release, inputs documentation

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Inspection checklist: HIGH — all items verified by reading source files
- actionlint integration pattern: HIGH — verified via GitHub API + official docs
- Workflow correctness assessment: HIGH — all footguns addressed in committed code

**Research date:** 2026-05-30
**Valid until:** 2026-07-01 (SHA pins are permanent; raven-actions/actionlint version may update but the researched SHA remains valid)
