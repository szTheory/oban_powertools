---
phase: 47-hex-release-foundation
plan: 03
type: summary
wave: 3
status: complete-pending-operator
requirements: [REL-01]
commit: ad2ba53
---

# 47-03 Summary — Release-Please Pipeline

## What was built

Stood up the full upstream release-please pipeline so release-please itself cuts and publishes the 0.5.0 release (REL-01, D-01/D-02/D-03). Three files created and committed (ad2ba53):

- **`release-please-config.json`** — `release-type: elixir`, `bootstrap-sha` at the first repo commit (`ced2a92`), `include-v-in-tag: true` (produces `v0.5.0`, matching mix.exs `source_ref`), `bump-minor-pre-major: false` / `bump-patch-for-minor-pre-major: true`, `packages["."]` with `changelog-path` + `package-name`. No deprecated `release-as` key.
- **`.release-please-manifest.json`** — seeded at exactly `{".": "0.0.0"}` (not 0.1.0) so the `Release-As: 0.5.0` footer commit resolves the first release to 0.5.0 (Pitfall 1).
- **`.github/workflows/release-please.yml`** — `release-please` job (Release PR + tag) wiring `release_created`/`tag_name` outputs; `publish-hex` job gated on `needs.release-please.outputs.release_created`, with a `git status --porcelain` clean-tree gate before `mix hex.publish --yes` (D-00e, Pitfall 4/17), least-privilege `permissions` (contents+pull-requests write only), and BEAM pins (1.19.5 / 27.3) matching the host-contract-proof analog. YAML comment documents the GITHUB_TOKEN Release-PR-CI limitation (Pitfall 3).

## Task 1 decision (resume from crash)

Pinned **`googleapis/release-please-action@v5`**. Re-verified the upstream releases page: v5.0.0 (2026-04-22) is latest stable; its only breaking change is an internal node24 runtime bump (fine on `ubuntu-latest`), and the `with:` inputs are unchanged from v4 — we use only `token:`. Per the plan's Task-1 rule (adopt the current new major when inputs are unchanged), v5 qualifies. No input differences to note.

## Verification

- config.json gate (release-type/include-v-in-tag/bootstrap-sha present, release-as absent, packages["."]) — PASS
- manifest gate (`"."` == `0.0.0`) — PASS
- workflow YAML valid (python yaml.safe_load) + content gate (action@v5, permissions, release_created gate, clean-tree, hex.publish, HEX_API_KEY, setup-beam, 1.19.5) — PASS
- All three files tracked, none stray-ignored; working tree clean after commit.

## Operator handoff — Task 5 (BLOCKING, not automatable)

These require hex.pm account access, a push to main, and a human merge — the executor did NOT perform them:

1. Generate a **publish-scoped** hex key (`mix hex.user key generate --permission api:write`) → add as GitHub Actions repo secret `HEX_API_KEY`.
2. Confirm a clean tree with all phase-47 changes on `main`.
3. Push a commit to `main` with a `Release-As: 0.5.0` footer in the body.
4. Verify release-please opens a Release PR proposing **exactly 0.5.0** (not 0.1.1/0.2.0). Confirm host-contract-proof CI is green on `main` first (GITHUB_TOKEN won't auto-trigger it on the Release PR).
5. Merge the Release PR → tag `v0.5.0` → `publish-hex` runs `mix hex.publish --yes`.
6. Confirm 0.5.0 is live on hex.pm and hexdocs renders (guides as extras, CHANGELOG page, source links at v0.5.0).

## Status

Files complete and committed. Plan 47-03 is **complete pending the operator-only Task 5**. Phase 47 closes once 0.5.0 is live on hex.pm.
