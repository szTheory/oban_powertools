---
phase: 52
slug: zero-touch-release-automation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-30
---

# Phase 52 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub `workflow_run` event → automerge runner | `head_branch`/`head_sha` from a prior CI run are attacker-influenceable inputs that decide whether a PR is merged | PR metadata (branch name, SHA, title) — untrusted |
| Release PR contents → squash-merge into `main` | An untrusted PR body/title crosses into a privileged merge + dispatch action | PR title string, commit SHA — untrusted |
| New workflow YAML on any PR → CI runners | Malformed or malicious workflow YAML could change CI behavior if not statically checked | Workflow YAML source — untrusted |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-52-01 | Tampering | `release-pr-automerge.yml` stale `workflow_run` SHA | mitigate | `head_oid != HEAD_SHA` guard (line 119) exits 0 on stale events — verified present in committed workflow | closed |
| T-52-02 | Tampering | Untrusted PR title used in bash merge decision | mitigate | Title validated against `^chore\(main\):\ release\ ` regex (line 124) before any `gh pr merge`; mismatch exits without merging — verified present | closed |
| T-52-03 | Elevation of Privilege | `--admin` squash-merge fallback | accept | `--admin` is fallback-only after branch-protection catch-up loop (12×30s); release automation requires it. Permissions scoped to `contents/pull-requests/actions: write` only — no `id-token`/`packages` | closed |
| T-52-04 | Tampering | Malformed/malicious workflow YAML reaching `main` | mitigate | actionlint lane (`raven-actions/actionlint@205b530c5d9fa8f44ae9ed59f341a0db994aa6f8 # v2.1.2`) statically validates all `.github/workflows/*.yml` on every PR; enforced by `ci-gate` via `needs:`, `env:`, and `for` loop — verified present in ci.yml lines 131–150 | closed |
| T-52-SC | Tampering | GitHub Action supply chain (`raven-actions/actionlint`) | mitigate | Action SHA-pinned to `205b530c5d9fa8f44ae9ed59f341a0db994aa6f8 # v2.1.2` (verified via GitHub API in RESEARCH); consistent with all-actions-SHA-pinned convention in this repo | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-52-01 | T-52-03 | `--admin` squash-merge fallback is required for the zero-touch release pipeline because GITHUB_TOKEN merges don't emit push events and branch-protection rules can lag behind the merge window. The blast radius is constrained: it only triggers after a 12×30s wait loop following a successful ci-gate pass on a release-please PR matching the exact branch name pattern. Permissions are least-privilege (`contents/pull-requests/actions: write` only). | szTheory | 2026-05-30 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-30 | 5 | 5 | 0 | gsd-secure-phase (automated) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-30
