---
phase: 51
slug: published-package-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in, no additional install) |
| **Config file** | `examples/hex_consumer/test/test_helper.exs` (to be created in Wave 0) |
| **Quick run command** | `cd examples/hex_consumer && mix compile --warnings-as-errors` |
| **Full suite command** | `cd examples/hex_consumer && MIX_ENV=test mix test test/hex_consumer_web/oban_powertools_first_session_test.exs` |
| **Estimated runtime** | ~60–120 seconds (deps.get from hex + compile + LiveView session) |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/hex_consumer && mix compile --warnings-as-errors`
- **After every plan wave:** Run the full first-session test
- **Before `/gsd-verify-work`:** Full suite must be green AND `git status --porcelain` empty
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 51-01-* | 01 | 0 | REL-04 | — | N/A | scaffold | `cd examples/hex_consumer && mix deps.get` | ❌ W0 | ⬜ pending |
| 51-02-* | 02 | 1 | REL-04 | — | N/A | integration | `cd examples/hex_consumer && MIX_ENV=test mix test test/hex_consumer_web/oban_powertools_first_session_test.exs` | ❌ W0 | ⬜ pending |
| 51-03-* | 03 | 2 | REL-04 | — | CI must fail loud on packaging/guide drift | integration (CI) | `verify-published` job in `.github/workflows/release.yml` (`needs: [release-please, publish-hex]`) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/hex_consumer/` — entire directory does not exist yet
- [ ] `examples/hex_consumer/mix.exs` — `{:oban_powertools, "~> 0.5"}` hex dep, `oban` explicit, no `oban_web`
- [ ] `examples/hex_consumer/test/test_helper.exs`
- [ ] `examples/hex_consumer/test/support/conn_case.ex` — shared fixture
- [ ] `examples/hex_consumer/test/support/data_case.ex` — shared fixture
- [ ] `examples/hex_consumer/priv/repo/seeds.exs` — `nightly_sync` cron fixture
- [ ] `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` — covers REL-04

*Wave 0 is scaffolding the consumer app + its test infra. ExUnit itself ships with Elixir — no framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `verify-published` actually runs post-publish on hex.pm | REL-04 | Only observable on a real release where hex.pm has the new version indexed | After next release, confirm the `verify-published` job ran green on the release commit in GitHub Actions |

*The local first-session test depends on hex.pm reachability (true hex dep). A network-isolated run cannot resolve `{:oban_powertools, "~> 0.5"}` — this is by design (the whole point is exercising the published tarball).*

---

## Phase Gate (Definition of Done)

- [ ] `cd examples/hex_consumer && mix deps.get` resolves the published version from hex.pm
- [ ] First-session test green: install → migrate → boot → `/ops/jobs` LiveView → pause cron entry → assert DB state + audit evidence
- [ ] `verify-published` job added to `release.yml` with `needs: [release-please, publish-hex]`
- [ ] `:files` whitelist NOT loosened to pass (a failure there = a real packaging bug to fix-forward)
- [ ] Any in-repo-vs-published drift fixed-forward or explicitly documented (D-06)
- [ ] `git status --porcelain` empty (v1.5-graduated clean-tree convention, D-05)
