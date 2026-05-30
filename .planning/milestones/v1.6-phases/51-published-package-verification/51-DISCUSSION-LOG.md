# Phase 51: Published-Package Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 51-published-package-verification
**Areas discussed:** Verification trigger, Dependency source, Consumer shape, Verification depth

Mode: advisor (research-backed). Four parallel research agents (sonnet) produced comparison
tables grounded in the actual repo (`release.yml`, `host-contract-proof.yml`, existing
first-session harness). User accepted all four recommendations.

---

## Verification trigger

| Option | Description | Selected |
|--------|-------------|----------|
| release.yml post-publish job | `verify-published` job, `needs: [publish-hex]`; auto every release; tarball already indexed (no race) | ✓ |
| release.yml job + workflow_dispatch | Same auto job plus a manual/recovery-path entry point | |
| Scheduled cron job | Periodic install of latest published version; catches drift but not release-time | |

**User's choice:** release.yml post-publish job
**Notes:** Research surfaced that `publish-hex` already polls hex.pm for the indexed version
before exiting, so `needs: [publish-hex]` has no chicken-and-egg timing race. Hex immutability
means failure can't block publish — fix-forward via patch is the accepted response.

---

## Dependency source

| Option | Description | Selected |
|--------|-------------|----------|
| True hex dep `~> 0.5` | Resolves the real published tarball; proves the `:files` whitelist | ✓ |
| git: + tag dep | Pins tagged source tree; fetches whole repo → masks broken whitelist | |
| Both (hex + git jobs) | Belt-and-suspenders; marginal once v0.5.0 is live | |

**User's choice:** True hex dep `~> 0.5`
**Notes:** Only the hex dep exercises the tarball — the exact PITFALLS Pitfall 3 failure class
(excluded `priv/` migration or guide). git-tag dep gives false confidence. Planner must force
resolution of the just-published version (deps.update / exact pin / cache-clear).

---

## Consumer shape

| Option | Description | Selected |
|--------|-------------|----------|
| Committed examples/hex_consumer/ | Real mini Phoenix app, own mix.exs with hex dep; matches Pitfall 3 + existing example idiom | ✓ |
| Retarget fresh_host_contract_test → hex | Reuse existing test; conflates contracts, forces post-publish-only | |
| Ephemeral mix phx.new in CI | Throwaway app in shell script; invisible locally, no audit trail | |

**User's choice:** Committed examples/hex_consumer/
**Notes:** Consistent with `examples/phoenix_host` + `examples/phoenix_host_upgrade_source`
(both committed, with regenerate.sh). `~> 0.5` auto-tracks latest 0.x → near-zero pin
maintenance. Locally runnable and greppable.

---

## Verification depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full operator session | Reuse first_session! harness: boot → /ops/jobs → cron pause → audit assert | ✓ |
| Install + migrate + boot + route resolves | Structural wiring proof; skeleton LiveView still passes | |
| Install + compile only | Tarball resolves + host compiles; 404 at /ops/jobs still passes | |

**User's choice:** Full operator session
**Notes:** The library's value IS the operator surface, so anything shallower is false
confidence. The first-session harness already runs this depth (cron-pause path is synchronous,
no Oban async flakiness); only the dep source changes (path → hex).

---

## Claude's Discretion

- Exact CI mechanism to force the just-published version (deps.update vs exact-version pin vs
  HEX_HOME cache-clear).
- Whether `verify-published` needs its own Postgres service block or mirrors the
  `host-contract-proof.yml` service pattern.
- Optional secondary `workflow_dispatch` placement on the `publish-hex.yml` recovery path.
- Degree of harness sharing vs duplication between `examples/phoenix_host` and
  `examples/hex_consumer`.
- Clean-tree / per-phase verification convention (D-05) and drift fix-forward-vs-document
  policy (D-06) locked without re-asking, consistent with the user's decisive profile.

## Deferred Ideas

- Scheduled/cron drift monitoring of the latest published version (different goal than REL-04).
- `workflow_dispatch` re-run entry point on the recovery publish path (nice-to-have).
