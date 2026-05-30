---
phase: 47
slug: hex-release-foundation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Reconstructed retroactively (State B) — the phase shipped with one-time bash
> execution gates but no committed repeatable tests. This file records the
> durable automated coverage added by `/gsd-validate-phase`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19) |
| **Config file** | `test/test_helper.exs` (DB boot guarded by `OBAN_POWERTOOLS_SKIP_DB_BOOT`) |
| **Quick run command** | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~0.04 seconds (release test file is DB-free, `async: true`) |

The release/packaging test is pure file + `Mix.Project.config()` introspection — it
needs no Postgres or Oban boot, so `OBAN_POWERTOOLS_SKIP_DB_BOOT=1` lets it run in
isolation without provisioning a database.

---

## Sampling Rate

- **After every task commit:** Run the quick command above
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~1 second (release test alone)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 1 | REL-03 | T-47-01 | CHANGELOG ships only public roadmap content; `[0.5.0]`/`[Unreleased]`/`Path to 1.0` present, no backfilled `[1.x.y]` headings | config | `OBAN_POWERTOOLS_SKIP_DB_BOOT=1 mix test test/oban_powertools/hex_release_test.exs` | ✅ | ✅ green |
| 47-01-02 | 01 | 1 | REL-03 | T-47-02 | LICENSE is verbatim Apache-2.0 (header, canonical URL, APPENDIX) matching SPDX id | config | same | ✅ | ✅ green |
| 47-02-01 | 02 | 2 | REL-01 | T-47-03 / T-47-04 | `package/0` SPDX `["Apache-2.0"]`; `:files` whitelist includes lib/guides/docs, excludes `priv`/`test`/`.planning`; igniter `runtime: false` | config | same | ✅ | ✅ green |
| 47-02-02 | 02 | 2 | REL-02 | T-47-05 | docs `source_ref: "v0.5.0"`, `source_url_pattern` pinned to `/blob/v0.5.0/`, CHANGELOG+README in `extras`, no bogus `changelog:` key | config | same | ✅ | ✅ green |
| 47-02-03 | 02 | 2 | REL-01 | — | README advertises `~> 0.5` (not `~> 0.1.0`) with a 0.x stability note | config | same | ✅ | ✅ green |
| 47-03-02 | 03 | 3 | REL-01 | T-47-10 | `release-please-config.json`: `release-type elixir`, `include-v-in-tag`, `bootstrap-sha`, no deprecated `release-as`, `packages["."]` wired | config | same | ✅ | ✅ green |
| 47-03-03 | 03 | 3 | REL-01 | T-47-10 | `.release-please-manifest.json` `.` tracks the released `@version` (`0.5.0`) | config | same | ✅ | ✅ green |
| 47-03-04 | 03 | 3 | REL-01 | T-47-07/08/09 | live `release.yml`: release-please-action, `release_created` gate, `mix hex.publish` + `HEX_API_KEY`, BEAM pins `1.19.5`/`27.3` | config | same | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Reconciliations (current reality ≠ original plan)

The phase evolved after execution; the test asserts the **current** durable contract:

1. **Manifest `0.0.0` → `0.5.0`** — seeded at `0.0.0` for bootstrap; release-please bumped it to `0.5.0` after the release actually cut. Test asserts the manifest equals `@version`.
2. **igniter `only: [:dev,:test]` removed** — current dep is `{:igniter, "~> 0.8.0", runtime: false}` (the install task `use`s `Igniter.Mix.Task`, so igniter must be loadable to compile). Test asserts `runtime: false` only.
3. **`release-please.yml` → `release.yml`** — commit `96a5cca` superseded the single-file workflow with the canonical szTheory pipeline (`release.yml` + `publish-hex.yml` recovery). Test targets `release.yml`.
4. **Clean-tree gate → CI-green gate** — the literal `git status --porcelain` gate was replaced by `gate-ci-green` + checkout-at-tag in `release.yml` (a stronger control). Test does not assert the porcelain text.

---

## Wave 0 Requirements

- [x] `test/oban_powertools/hex_release_test.exs` — 35 tests covering REL-01/02/03 config + file-content contracts

ExUnit infrastructure already existed (24 sibling test files); only the new release-contract file was added.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm current stable `googleapis/release-please-action` major before pinning | REL-01 (47-03 Task 1) | Upstream version check against GitHub releases page — external state, not a repo invariant | Open https://github.com/googleapis/release-please-action/releases; confirm the SHA-pinned `# v5.0.0` comment in `release.yml` still maps to a current stable major before bumping |
| Provision `HEX_API_KEY` secret, push `Release-As` footer, merge Release PR, confirm `0.5.0` live on hex.pm + hexdocs | REL-01 (47-03 Task 5) | Operator-only: requires hex.pm account access, a push to `main`, and a human merge decision — no autonomous fallback | hex.pm account → publish-scoped key → GitHub Actions secret; merge the Release PR; verify `https://hex.pm/api/packages/oban_powertools/releases/0.5.0` resolves and hexdocs renders with source links at `v0.5.0` |

These are inherently non-automatable (external service + human gate); they do not count
as Nyquist gaps. The manifest test (47-03-03) asserting `0.5.0` is indirect evidence the
operator publish flow completed.

---

## Validation Sign-Off

- [x] All automatable tasks have `<automated>` verify (8/8 covered by `hex_release_test.exs`)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 1s
- [x] `nyquist_compliant: true` set in frontmatter (all automatable requirements covered; 2 inherently-manual operator checkpoints documented above)

**Approval:** approved 2026-05-29
