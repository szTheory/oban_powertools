# Phase 51: Published-Package Verification — Research

**Researched:** 2026-05-29
**Domain:** CI/release-pipeline verification, Hex tarball contract, Phoenix/Ecto first-session harness
**Confidence:** HIGH — every recommendation is grounded in direct inspection of the actual files

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `verify-published` job in `.github/workflows/release.yml`, `needs: [publish-hex]`. Auto post-publish on every release.
- **D-01a:** No race: `publish-hex` already polls until hex.pm confirms indexing. No sleep/retry needed in the new job.
- **D-01b:** Failure = loud red job on release commit + fix-forward via patch release. Not a pre-publish gate.
- **D-02:** True hex dep `{:oban_powertools, "~> 0.5"}`, resolved via `mix deps.get` from hex.pm.
- **D-02a:** `git:` + tag dep rejected (bypasses `:files` whitelist).
- **D-02b:** Must verify the just-published version, not a stale cached resolution. Mechanism is Claude's discretion.
- **D-03:** Committed `examples/hex_consumer/` — own `mix.exs`, own `mix.lock` (or no lock committed). Distinct from `examples/phoenix_host`.
- **D-03a:** `~> 0.5` auto-tracks latest 0.x, near-zero maintenance.
- **D-03b:** Include `regenerate.sh` companion consistent with existing examples.
- **D-03c:** Rejected: retargeting `fresh_host_contract_test.exs` to hex; ephemeral `mix phx.new` in CI script.
- **D-04:** Full operator session: install → run generated migration → boot → drive `/ops/jobs` LiveView → pause a cron entry → assert DB state + audit evidence.
- **D-05:** `git status --porcelain` clean-tree assertion in phase verification (v1.5-graduated convention).
- **D-06:** Fix-forward real bugs; document intentional differences.

### Claude's Discretion

- Exact mechanism for forcing the just-published version in CI (D-02b).
- Whether the `verify-published` job needs its own Postgres service block (answer: yes, it does for D-04).
- Whether to expose verification as a `workflow_dispatch` entry point (nice-to-have, not required).
- How much of the first-session harness is shared vs copied (low stakes).

### Deferred Ideas (OUT OF SCOPE)

- Scheduled/cron drift monitoring of the latest published version.
- `workflow_dispatch` re-run entry point wired into `publish-hex.yml` recovery path (optional, not required).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-04 | The getting-started quickstart is verified working from the **published** package — a fresh host installs from hex and reaches a first successful operator session (not just in-repo). | All six focus questions below directly support this requirement. |

</phase_requirements>

---

## Summary

Phase 51 is a CI/verification phase, not a feature phase. The work is: (1) stand up a committed
`examples/hex_consumer/` mini Phoenix app using a true hex dep, (2) port the existing
`examples/phoenix_host` first-session harness into it so the cron-pause flow exercises the
published tarball, and (3) add a `verify-published` job to `release.yml` chained after
`publish-hex`.

**The most important pre-research discovery:** The published tarball (`oban_powertools-0.5.0.tar`)
was inspected directly. Migrations are **embedded as strings in `lib/mix/tasks/oban_powertools.install.ex`**
— there is no `priv/` directory in the library root, and none is needed. The `:files` whitelist
`~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]` is already
correct and verified against the real tarball. The whole D-04 flow (install → migration →
boot → LiveView → cron pause) exercises the installer's embedded migration bodies from the
shipped `lib/`, not a `priv/` path — which means a `:files` omission of `lib/` (the only
real risk) would produce an immediate compile failure, not a subtle runtime failure.

**Primary recommendation:** Use `needs.release-please.outputs.version` piped into the
`verify-published` job as an exact `== <version>` pin in the consumer's `mix.exs`, combined
with a fresh `mix deps.get` in a clean checkout (no committed `mix.lock`). This is the single
most robust forcing function available from within the release pipeline.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Published tarball contract (`lib/`, `guides/`) | Library (`oban_powertools`) | — | The `:files` whitelist controls what ships; the tarball is the artifact under test |
| Installer execution (`mix oban_powertools.install`) | Hex consumer app | Library (Igniter task) | Consumer's shell runs the task; task code comes from the resolved tarball |
| Postgres schema (migrations) | Hex consumer app (generated files) | Library (embedded migration bodies) | `Igniter.Libs.Ecto.gen_migration` writes migration files into the consumer; bodies come from `lib/` |
| First-session LiveView drive | Hex consumer app (`test/`) | Library (LiveView modules) | The test lives in the consumer; the LiveView modules come from the resolved tarball |
| CI orchestration | `release.yml` (`verify-published` job) | `publish-hex` job outputs | Job chaining through `needs:` + `outputs:` |
| Version forcing (D-02b) | `verify-published` job steps | `release-please` job outputs | `version` output from `release-please` feeds the exact pin |

---

## Focus Question Answers

### 1. Forcing the Just-Published Version in CI (D-02b) [VERIFIED: direct inspection of release.yml]

**The version is available as a job output.**

`release-please` already declares (release.yml L31–35):
```yaml
outputs:
  release_created: ${{ steps.release.outputs.release_created }}
  tag_name:        ${{ steps.release.outputs.tag_name }}
  version:         ${{ steps.release.outputs.version }}
  sha:             ${{ steps.release.outputs.sha }}
```

`publish-hex` already consumes `needs.release-please.outputs.version` as `RELEASE_VERSION`
(release.yml L144) and uses it throughout. The same pattern is directly available to
`verify-published`.

**Candidate mechanisms evaluated:**

| Mechanism | Verdict | Reason |
|-----------|---------|--------|
| Committed `mix.lock` with stale resolution | REJECT | Defeats the purpose — old cached version tested |
| `mix deps.update oban_powertools` against committed `mix.lock` | WEAK | Updates within the `~> 0.5` range but does not guarantee the exact just-published version if two releases happen in quick succession |
| Clear `HEX_HOME` registry cache alone | INSUFFICIENT | Removes local cache but `mix deps.get` still resolves to whatever `mix.lock` (or `~> 0.5` floats to) |
| Exact `== <version>` pin in `mix.exs` + no committed `mix.lock` | RECOMMENDED | Guarantees the exact version from the `release-please` output is resolved; a missing or unpublished version fails immediately |

**Recommended approach: exact `== <version>` pin, no committed `mix.lock`.**

In the `verify-published` CI job, before calling `mix deps.get`, rewrite the consumer's
`mix.exs` dep line to use the exact version from the pipeline:

```yaml
- name: Pin exact published version
  run: |
    VERSION="${{ needs.release-please.outputs.version }}"
    sed -i "s|{:oban_powertools, \"~> 0.5\"}|{:oban_powertools, \"== ${VERSION}\"}|" \
      examples/hex_consumer/mix.exs
```

Then `mix deps.get` inside `examples/hex_consumer/` will either resolve that exact version
from hex.pm (success — it was indexed, job succeeded before this step per D-01a) or fail with
a resolution error (which itself is a useful signal).

The `examples/hex_consumer/mix.exs` committed to the repo uses `~> 0.5` (for local/dev
runs). The CI job patches it to `== <version>` purely in the runner workspace — no commit
needed. The no-committed-`mix.lock` design means there is no lock file to regenerate or
invalidate.

**Why not commit a `mix.lock`?** The hex consumer `mix.lock` would pin specific transitive
dep versions at time-of-commit. On the next release, those pinned transitive versions may
have been superseded. Omitting the lock lets `mix deps.get` resolve fresh each time, which
is correct for a verification fixture (it mirrors what an adopter does).

**Full CI step sequence for the version-forcing section:**
```yaml
- name: Checkout at release tag
  uses: actions/checkout@...
  with:
    ref: ${{ needs.release-please.outputs.tag_name }}

- name: Pin consumer to exact published version
  run: |
    VERSION="${{ needs.release-please.outputs.version }}"
    sed -i "s|{:oban_powertools, \"~> 0.5\"}|{:oban_powertools, \"== ${VERSION}\"}|" \
      examples/hex_consumer/mix.exs

- name: Fetch hex consumer deps
  run: mix deps.get
  working-directory: examples/hex_consumer
```

No `HEX_HOME` cache-clear needed when using `== <version>` — the exact version either
exists at hex.pm or `mix deps.get` fails.

---

### 2. CI Service / Runner Setup [VERIFIED: direct inspection of host-contract-proof.yml + release.yml]

**The exact pattern to mirror:**

The `native-first`, `first-session`, `doctor`, `control-plane`, `optional-bridge`, and
`upgrade-proof` jobs in `host-contract-proof.yml` (L127–229) all use this identical block:

```yaml
env:
  OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"
services:
  postgres:
    image: postgres:16
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: phoenix_host_test
    ports: ["5432:5432"]
    options: >-
      --health-cmd "pg_isready -U postgres"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
steps:
  - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
  - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
    with:
      elixir-version: "1.19.5"
      otp-version: "27.3"
```

[VERIFIED: host-contract-proof.yml L79–155 and L127–155]

**For `verify-published` specifically:**

- Use `POSTGRES_DB: hex_consumer_test` to name the database distinctly (avoids any
  potential collision if `host-contract-proof` and `release.yml` run on the same runner,
  though this is unlikely given `release.yml` runs post-publish on a release tag only).
- `OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"` must be set — this env var is used by the test suite
  to suppress DB bootstrap; confirm the hex consumer's test suite inherits it.

**How `needs: [publish-hex]` chains:**

```yaml
verify-published:
  name: Verify published package (REL-04)
  runs-on: ubuntu-latest
  needs: [release-please, publish-hex]
  if: ${{ needs.release-please.outputs.release_created == 'true' }}
```

`needs: [publish-hex]` already implies `needs: [release-please, gate-ci-green]` (because
`publish-hex` depends on them), so `release-please` only needs to be listed explicitly to
access its `outputs.version` in `verify-published`'s steps.

**No propagation-wait needed:** `publish-hex` already ends with a polling loop
(release.yml L201–213) that blocks until `curl -fsS "https://hex.pm/api/packages/oban_powertools/releases/${RELEASE_VERSION}"` returns `"version"`. So by the time `verify-published` starts,
the tarball is confirmed live.

**`publish-hex` does NOT expose `version` as a job output.** It consumes
`needs.release-please.outputs.version` as an env var (`RELEASE_VERSION`) but does not
re-export it. `verify-published` should pull `version` directly from
`needs.release-please.outputs.version` (same as `publish-hex` does). [VERIFIED: release.yml L144]

**Actions cache:** The `verify-published` job runs in `examples/hex_consumer/` (a separate
Mix project), so it uses a different `hashFiles('mix.lock')` key than `publish-hex`. Since
`hex_consumer` has no committed `mix.lock`, the cache key should be based on the version
or tag to keep runs distinct:

```yaml
- uses: actions/cache@...
  with:
    path: |
      examples/hex_consumer/deps
      examples/hex_consumer/_build
    key: ${{ runner.os }}-hex-consumer-${{ needs.release-please.outputs.version }}
```

---

### 3. First-Session Harness Reuse (D-04) [VERIFIED: direct inspection of all referenced files]

**What the existing harness does** (`examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs`):

The test (91 lines) does exactly what D-04 specifies:
1. Injects `ops-demo` actor into session via `Plug.Test.init_test_session`
2. Opens `/ops/jobs/cron` via `live(conn, "/ops/jobs/cron")`
3. Asserts UI content including `"nightly_sync"`, `"Runtime"`, `"Queue One"`, `"Latest Only"`
4. Clicks `pause_cron_entry` button for `nightly_sync`
5. Asserts preview modal content
6. DB-queries `RepairPreview` row (asserts `status == "ready"` and metadata)
7. Submits reason `"fixture maintenance"` and confirms
8. Asserts cron page shows `"Resume Cron Entry"`, `"Recent Audit Evidence"`, `"cron.paused"`
9. DB-queries `Entry` (asserts `paused_at` is non-nil)
10. DB-queries `RepairPreview` (asserts `status == "consumed"`)
11. DB-queries `Audit.list/2` (asserts event action, resource, actor, metadata, preview_token)

All assertions are synchronous — no Oban async job pickup, no polling. [VERIFIED: oban_powertools_first_session_test.exs]

**The seed dependency:** The test requires `"nightly_sync"` to be a seeded `Cron.Entry`. In
`examples/phoenix_host`, this comes from `priv/repo/seeds.exs` (which upserts `nightly_sync`
with `source: "fixture"`, `overlap_policy: "queue_one"`, etc.). The hex consumer needs the
same seed row. [VERIFIED: phoenix_host/priv/repo/seeds.exs]

**What must change for the hex consumer:**

| Item | phoenix_host | hex_consumer | Change needed |
|------|-------------|--------------|---------------|
| `ObanPowertoolsAuth` module | `PhoenixHostWeb.ObanPowertoolsAuth` (has `demo_actor/0`) | `HexConsumerWeb.ObanPowertoolsAuth` | Copy + rename module |
| `ConnCase` / `DataCase` | `PhoenixHostWeb.ConnCase` | `HexConsumerWeb.ConnCase` | Copy + rename |
| `Repo` alias | `PhoenixHost.Repo` | `HexConsumer.Repo` | Update alias in test |
| Module namespace | `PhoenixHostWeb.*` | `HexConsumerWeb.*` | Update `use` and `alias` |
| Dep source | `path: "../.."` in mix.exs | `{:oban_powertools, "~> 0.5"}` | **The whole point** |
| `priv/repo/seeds.exs` | ships `nightly_sync` cron entry | same, module-renamed | Copy + rename |
| `elixir: "~> 1.15"` | `phoenix_host/mix.exs` L7 | should be `"~> 1.19"` | Update to match library |

**Recommendation: copy, don't share.** The CONTEXT.md already calls this "low stakes." The
test file is 91 lines and the changes are purely namespace substitutions. A shared module
(e.g., a `test/support` helper extracted to a hex package) would add indirection without
value. Copy the test into `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs`
with `HexConsumerWeb.*` / `HexConsumer.Repo` substitutions applied. This is the same
pattern used by `ExampleHostContract`, which copies the fixture dir to `/tmp` and applies
path rewrites at runtime.

**The full D-04 flow in the hex consumer context:**

```
mix oban_powertools.install           # runs Igniter installer from resolved hex tarball
  → generates priv/repo/migrations/   # migration bodies come from lib/mix/tasks/oban_powertools.install.ex in tarball
  → writes config/config.exs additions
  → writes auth module + display policy stubs
  → patches router.ex

mix ecto.create && mix ecto.migrate   # or mix ecto.reset
mix run priv/repo/seeds.exs           # inserts nightly_sync Cron.Entry

mix test test/hex_consumer_web/oban_powertools_first_session_test.exs
  → opens /ops/jobs/cron via LiveView
  → clicks pause_cron_entry for nightly_sync
  → asserts DB state + audit evidence
```

**The tarball content is the assertion:** If `lib/mix/tasks/oban_powertools.install.ex` is
missing from the tarball, `mix oban_powertools.install` will fail. If any migration body
is truncated, `mix ecto.migrate` will fail. If the LiveView modules are absent from `lib/`,
the `/ops/jobs/cron` route won't render. The D-04 flow naturally catches all of these.

---

### 4. `examples/hex_consumer/` Shape + `regenerate.sh` [VERIFIED: direct inspection of phoenix_host/ structure and both existing regenerate.sh scripts]

**Recommended directory layout:**

```
examples/hex_consumer/
├── mix.exs                           # {:oban_powertools, "~> 0.5"} hex dep
├── mix.lock                          # NOT committed (per D-02b analysis above)
├── README.md                         # brief note: "hex dep consumer, see regenerate.sh"
├── regenerate.sh                     # mirrors phoenix_host/regenerate.sh conventions
├── config/
│   ├── config.exs                    # :oban_powertools config (after install)
│   ├── dev.exs
│   ├── test.exs                      # postgres password: "postgres", sandbox pool
│   └── runtime.exs
├── lib/
│   └── hex_consumer/
│   │   ├── application.ex
│   │   └── repo.ex
│   └── hex_consumer_web/
│       ├── endpoint.ex
│       ├── router.ex                 # /ops/jobs scope (after install)
│       ├── oban_powertools_auth.ex   # host-owned auth seam
│       └── oban_powertools_display_policy.ex
├── priv/
│   └── repo/
│       ├── migrations/               # generated by mix oban_powertools.install
│       └── seeds.exs                 # inserts nightly_sync Cron.Entry
└── test/
    ├── test_helper.exs
    ├── support/
    │   ├── conn_case.ex
    │   └── data_case.ex
    └── hex_consumer_web/
        └── oban_powertools_first_session_test.exs
```

**Key `mix.exs` differences vs `examples/phoenix_host/mix.exs`:**

```elixir
# examples/hex_consumer/mix.exs
defmodule HexConsumer.MixProject do
  use Mix.Project

  def project do
    [
      app: :hex_consumer,
      version: "0.1.0",
      elixir: "~> 1.19",   # match library minimum, not phoenix_host's "~> 1.15"
      ...
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:oban, "~> 2.18"},
      {:oban_powertools, "~> 0.5"},   # HEX DEP — the whole point
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.1"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.5"}
    ]
  end
end
```

Note: `oban_web` is intentionally absent from the hex consumer's deps — the first-session
test asserts `refute html =~ "Oban Web"` (oban_powertools_first_session_test.exs L27),
so the native-only path is the correct verification target.

**`regenerate.sh` design:**

The hex consumer's `regenerate.sh` must differ from `phoenix_host/regenerate.sh` in one
critical way: it must insert `{:oban_powertools, "~> 0.5"}` as a hex dep, not a `path:`
dep. The script is a maintainer convenience, not part of CI. Unlike the `path:` examples,
it requires hex.pm reachability to run:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_DIR="${ROOT_DIR}/examples/hex_consumer"
TARGET_DIR="${ROOT_DIR}/examples/.hex_consumer_regen"

# ... same replace_once helper as phoenix_host/regenerate.sh ...

rm -rf "${TARGET_DIR}"

mix phx.new "${TARGET_DIR}" \
  --app hex_consumer \
  --module HexConsumer \
  --database postgres \
  --no-assets \
  --no-dashboard \
  --no-mailer \
  --no-gettext \
  --no-install

replace_once \
  "${TARGET_DIR}/mix.exs" \
  "{:postgrex, \">= 0.0.0\"}," \
  "{:postgrex, \">= 0.0.0\"},\n      {:oban, \"~> 2.18\"},\n      {:oban_powertools, \"~> 0.5\"},"

(
  cd "${TARGET_DIR}"
  mix deps.get          # requires hex.pm reachability
  mix oban_powertools.install
)

# ... copy curated files from CANONICAL_DIR into TARGET_DIR ...
# ... diff instructions for maintainer ...
cat <<EOF

NOTE: This regenerate.sh requires hex.pm to be reachable (hex dep, not path dep).
Run only when oban_powertools is live on hex.pm.

Regenerated fixture tree: ${TARGET_DIR}
...
EOF
```

**Implications of hex dep for local dev:** Unlike `phoenix_host`, a developer cannot run
`examples/hex_consumer` locally without internet access. They also cannot test against a
locally-modified `oban_powertools` without temporarily switching to `path:`. This is
intentional and correct — the hex consumer's purpose is to verify the published package,
not local changes. Document this in the `README.md`.

**No committed `mix.lock`:** Add `examples/hex_consumer/mix.lock` to `.gitignore` (or just
don't commit it). [ASSUMED — this is the recommended pattern; confirm .gitignore scope]

---

### 5. `:files` Whitelist Contract [VERIFIED: direct tarball inspection of oban_powertools-0.5.0.tar]

**Current `:files` list** (mix.exs L36):
```elixir
files: ~w[lib guides .formatter.exs mix.exs mix.lock README.md CHANGELOG.md LICENSE]
```

**Tarball contents verified** by `tar tzf /tmp/contents.tar.gz` on the actual built tarball:

| Category | Files in tarball | Expected |
|----------|-----------------|----------|
| `lib/` | All `.ex` files including `lib/mix/tasks/oban_powertools.install.ex` | YES |
| `guides/` | All 14 `.md` files (installation, first-operator-session, etc.) | YES |
| Root files | `.formatter.exs`, `mix.exs`, `mix.lock`, `README.md`, `CHANGELOG.md`, `LICENSE` | YES |
| `priv/` | ABSENT | CORRECT — no `priv/` exists in the library root |
| `test/` | ABSENT | CORRECT |
| `examples/` | ABSENT | CORRECT |
| `.planning/` | ABSENT | CORRECT |

**Critical insight: migrations are embedded in `lib/`, not `priv/`.**

`lib/mix/tasks/oban_powertools.install.ex` uses `Igniter.Libs.Ecto.gen_migration/4` with
inline `body:` strings for every migration (confirmed by grep of the install task). The
installer writes migration files **into the host app's `priv/repo/migrations/`** at install
time, with migration bodies coming from the published `lib/` source. There is no `priv/`
directory in the library itself.

**What does the harness assert is present from the resolved tarball?**

The D-04 flow is itself the assertion:
1. `mix deps.get` must succeed (package exists on hex at the requested version)
2. `mix oban_powertools.install` must compile and run (requires `lib/mix/tasks/` present)
3. `mix compile` must succeed after install (requires all `lib/oban_powertools/**/*.ex` present)
4. `mix ecto.migrate` must succeed (requires migration bodies in install task to be correct)
5. LiveView render of `/ops/jobs/cron` must succeed (requires `lib/oban_powertools/web/cron_live.ex`)
6. `Audit.list/2` must return the expected event (requires `lib/oban_powertools/audit.ex`)

A missing `lib/` file → compile error at step 2 or 3. A missing `guides/` file → does not
affect the test (guides are ExDoc-only), but the test could additionally assert that
`Path.join(Mix.Project.deps_path(), "oban_powertools/guides/installation.md")` exists if
explicit whitelist verification is desired. [RECOMMENDED: add a simple guides-present assertion
in the install step or a separate test]

**Do not loosen `:files` to make tests pass** (per D-02, PITFALLS Pitfall 1, and 47-CONTEXT.md D-00b). A failure here means a real packaging bug. The existing whitelist passes verification for 0.5.0.

---

### 6. Clean-Tree / Drift Conventions (D-05 + D-06) [VERIFIED: REQUIREMENTS.md Process Convention; PITFALLS.md Pitfall 17]

**D-05 pattern (v1.5-graduated):** Every phase verification asserts `git status --porcelain`
returns empty output before declaring the phase complete. This is the standing convention
for v1.6 (REQUIREMENTS.md "Process Convention" section, L77–79).

In Phase 51 specifically, the verification step is:
```bash
git status --porcelain
# must output nothing — if not, phase is not done regardless of test results
```

Additionally, per Phase 47 (D-00e): `mix hex.publish` was gated on a clean tree. The
`verify-published` job runs after publishing, so tree cleanliness is not a blocking concern
for the publish — but the phase verification (local, pre-commit) still applies.

**D-06 drift handling:**

| Drift category | Example | Response |
|---------------|---------|----------|
| Packaging bug | A guide file missing from tarball | Fix `:files` whitelist, cut patch release, document in CHANGELOG `[Unreleased]` |
| Installer bug | Migration body wrong in published lib | Fix in `lib/mix/tasks/oban_powertools.install.ex`, patch release |
| Intentional difference | hex consumer has no `oban_web` dep | Document in `examples/hex_consumer/README.md` — intentional, not a bug |

The D-06 policy means: the `verify-published` job failing is expected behavior on a
packaging regression; the response is a patch release, not a rollback (hex versions are
immutable per D-01b).

---

## Standard Stack

This phase introduces no new library dependencies. All tools are already in the repo:

| Tool | Version | Where used |
|------|---------|------------|
| `erlef/setup-beam` | `fc68ffb...` (v1.24.0) [VERIFIED: release.yml L149] | Elixir 1.19.5 / OTP 27.3 |
| `actions/checkout` | `de0fac2...` (v6) [VERIFIED: host-contract-proof.yml L27] | Checkout at release tag |
| `actions/cache` | `27d5ce7...` (v5) [VERIFIED: release.yml L153] | Cache hex_consumer deps/_build |
| `postgres:16` | docker image [VERIFIED: host-contract-proof.yml L14] | Postgres service in verify-published job |
| `mix oban_powertools.install` | from published hex tarball | Installer run inside hex_consumer |
| `mix test` | standard | First-session test execution |

**No new packages to install.** Package Legitimacy Audit: not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
release.yml trigger (push to main / merge of Release PR)
     │
     ▼
release-please job
  outputs: release_created, tag_name, version, sha
     │
     ▼ (if release_created == true)
gate-ci-green job
  polls ci.yml for ci-gate success on release SHA
     │
     ▼
publish-hex job
  checkout at tag_name → compile → mix hex.publish → poll hex.pm API until indexed
     │
     ▼ (NEW: needs: [release-please, publish-hex])
verify-published job
  checkout at tag_name
  pin: sed mix.exs oban_powertools dep to == <version from release-please.outputs.version>
  mix deps.get                        ← resolves from hex.pm (tarball confirmed live)
  mix oban_powertools.install         ← exercises lib/mix/tasks/ from tarball
  mix ecto.create && mix ecto.migrate ← exercises embedded migration bodies
  mix run priv/repo/seeds.exs         ← inserts nightly_sync
  mix test first_session_test.exs     ← drives LiveView, pauses cron, asserts audit
```

### Recommended Project Structure (hex_consumer)

```
examples/hex_consumer/
├── mix.exs              # {:oban_powertools, "~> 0.5"} — hex dep
├── README.md            # explains hex dep requirement + regenerate.sh
├── regenerate.sh        # maintainer tool, requires hex.pm
├── config/
│   ├── config.exs       # :oban_powertools config block (post-install)
│   ├── dev.exs
│   ├── test.exs         # sandbox pool, postgres password: "postgres"
│   └── runtime.exs
├── lib/
│   ├── hex_consumer/
│   │   ├── application.ex
│   │   └── repo.ex
│   └── hex_consumer_web/
│       ├── endpoint.ex
│       ├── router.ex                        # /ops/jobs scope
│       ├── oban_powertools_auth.ex          # host-owned auth seam
│       └── oban_powertools_display_policy.ex
├── priv/
│   └── repo/
│       ├── migrations/   # generated by mix oban_powertools.install (not committed)
│       └── seeds.exs     # nightly_sync Cron.Entry
└── test/
    ├── test_helper.exs
    ├── support/
    │   ├── conn_case.ex
    │   └── data_case.ex
    └── hex_consumer_web/
        └── oban_powertools_first_session_test.exs
```

**Files NOT committed:** `mix.lock`, `priv/repo/migrations/` (generated by installer),
`_build/`, `deps/`.

Add to `.gitignore` for the hex_consumer (either repo-root `.gitignore` or a local
`examples/hex_consumer/.gitignore`):
```
examples/hex_consumer/mix.lock
examples/hex_consumer/priv/repo/migrations/
examples/hex_consumer/_build/
examples/hex_consumer/deps/
```

### Pattern: verify-published job in release.yml

The full job YAML to add after the existing `publish-hex` job:

```yaml
  verify-published:
    name: Verify published package (REL-04)
    runs-on: ubuntu-latest
    needs: [release-please, publish-hex]
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    permissions:
      contents: read
    env:
      OBAN_POWERTOOLS_SKIP_DB_BOOT: "1"
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: hex_consumer_test
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U postgres"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}

      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        with:
          elixir-version: "1.19.5"
          otp-version: "27.3"

      - uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae # v5
        with:
          path: |
            examples/hex_consumer/deps
            examples/hex_consumer/_build
          key: ${{ runner.os }}-hex-consumer-${{ needs.release-please.outputs.version }}

      - name: Install Hex + Rebar
        run: |
          mix local.hex --force
          mix local.rebar --force

      - name: Pin consumer to exact published version
        run: |
          VERSION="${{ needs.release-please.outputs.version }}"
          sed -i "s|{:oban_powertools, \"~> 0.5\"}|{:oban_powertools, \"== ${VERSION}\"}|" \
            examples/hex_consumer/mix.exs

      - name: Fetch hex consumer deps (from hex.pm)
        run: mix deps.get
        working-directory: examples/hex_consumer

      - name: Run installer from published tarball
        run: mix oban_powertools.install
        working-directory: examples/hex_consumer

      - name: Compile hex consumer
        run: mix compile --warnings-as-errors
        working-directory: examples/hex_consumer

      - name: Create and migrate database
        env:
          MIX_ENV: test
        run: mix ecto.create && mix ecto.migrate
        working-directory: examples/hex_consumer

      - name: Seed nightly_sync cron entry
        env:
          MIX_ENV: test
        run: mix run priv/repo/seeds.exs
        working-directory: examples/hex_consumer

      - name: Run first-session proof (REL-04)
        env:
          MIX_ENV: test
        run: mix test test/hex_consumer_web/oban_powertools_first_session_test.exs --trace
        working-directory: examples/hex_consumer
```

**Caveats on `working-directory`:** GitHub Actions `working-directory` on `run` steps
works correctly. However, `mix oban_powertools.install` (Igniter) runs interactively and
may prompt; ensure `--yes` flag is passed or the task is non-interactive by default.
[ASSUMED — verify Igniter task accepts `--yes` or equivalent for non-interactive CI]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version propagation | Parse `mix.exs` from git | `needs.release-please.outputs.version` | Already available as a job output (release.yml L34) |
| Hex indexing wait | Custom polling loop | Already in `publish-hex` job (release.yml L201-213) | `needs: [publish-hex]` provides the guarantee |
| Postgres health check | Custom retry loop | `--health-cmd "pg_isready"` options block | Established pattern in every existing CI job |
| Migration generation | Custom migration files in `priv/` | `mix oban_powertools.install` (Igniter) | Migrations are embedded in the installer |
| First-session test | New test logic | Copy from `examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` with namespace substitution | 91 lines, already proven synchronous |

---

## Common Pitfalls

### Pitfall A: Committing `mix.lock` in `examples/hex_consumer/`
**What goes wrong:** The locked lock pins specific transitive dep versions at commit time. On
the next 0.x release, CI resolves stale transitive versions rather than fresh ones.
**How to avoid:** Do not commit `hex_consumer/mix.lock`. Add to `.gitignore`. Let
`mix deps.get` resolve fresh on each CI run.

### Pitfall B: Using `mix deps.update oban_powertools` instead of `== <version>` pin
**What goes wrong:** `mix deps.update` updates within the `~> 0.5` range but if two releases
publish in quick succession, CI might test the wrong one.
**How to avoid:** Patch the `mix.exs` dep to `== ${VERSION}` using the exact version from
`needs.release-please.outputs.version` before running `mix deps.get`.

### Pitfall C: Missing `working-directory:` on `mix` steps
**What goes wrong:** `mix deps.get` runs in the repo root instead of `examples/hex_consumer/`,
pulling deps into the wrong project.
**How to avoid:** Every `run:` step that runs a Mix command for the hex consumer must specify
`working-directory: examples/hex_consumer`.

### Pitfall D: `mix oban_powertools.install` requiring interactive input in CI
**What goes wrong:** Igniter-based tasks sometimes prompt the user. In non-interactive CI,
this stalls the job.
**How to avoid:** Pass `--yes` to the install task, or confirm that `oban_powertools.install`
has no interactive prompts. [ASSUMED — inspect the Igniter task's `@info.schema` for
confirmation. The existing `fresh-host` CI lane in `host-contract-proof.yml` runs `mix oban_powertools.install` non-interactively without `--yes`, suggesting it is already non-interactive.]

Actually: the `host-contract-proof.yml` `fresh-host` lane already runs
`mix oban_powertools.install` non-interactively via `ObanPowertools.FreshHostContract.proof!/0`
(which uses `System.cmd/3`). The installer is confirmed non-interactive in CI context.
[VERIFIED: fresh_host_contract.ex L18, host-contract-proof.yml L59-60]

### Pitfall E: The `nightly_sync` seed not running before the test
**What goes wrong:** The first-session test asserts the cron page shows `"nightly_sync"`.
If seeds haven't run, the page renders empty and the test fails on `assert html =~ "nightly_sync"`.
**How to avoid:** Ensure `mix run priv/repo/seeds.exs` step runs and succeeds before
`mix test`.

### Pitfall F: `POSTGRES_DB` collision with other jobs
**What goes wrong:** If `host-contract-proof.yml` and `release.yml` happen to run on the
same runner simultaneously (unlikely but possible), both jobs creating `phoenix_host_test`
could interfere.
**How to avoid:** Use `POSTGRES_DB: hex_consumer_test` (distinct name) in the
`verify-published` service block.

### Pitfall G: Assuming `priv/` migrations must exist in the tarball
**What goes wrong:** Implementer adds `priv` to the `:files` whitelist unnecessarily (or
creates a `priv/` directory in the library root for the hex consumer to copy).
**How to avoid:** There is no `priv/` directory in `oban_powertools`. Migrations are
generated by `mix oban_powertools.install` from embedded bodies in `lib/`. The `:files`
whitelist is correct as-is. Do not add `priv` to it.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, no additional install) |
| Config file | `examples/hex_consumer/test/test_helper.exs` (to be created) |
| Quick run command | `cd examples/hex_consumer && mix test --trace test/hex_consumer_web/oban_powertools_first_session_test.exs` |
| Full suite command | Same (there is only one test file in the hex consumer) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-04 | Fresh hex install reaches first operator session (cron pause + audit) | Integration | `cd examples/hex_consumer && MIX_ENV=test mix test test/hex_consumer_web/oban_powertools_first_session_test.exs` | No — Wave 0 |

### Sampling Rate
- **Per task commit:** `cd examples/hex_consumer && mix compile --warnings-as-errors`
- **Per wave merge:** Full first-session test
- **Phase gate:** `git status --porcelain` (empty), then full first-session test green

### Wave 0 Gaps

- [ ] `examples/hex_consumer/` — entire directory does not exist yet
- [ ] `examples/hex_consumer/test/hex_consumer_web/oban_powertools_first_session_test.exs` — covers REL-04
- [ ] `examples/hex_consumer/test/support/conn_case.ex` — shared fixture
- [ ] `examples/hex_consumer/test/support/data_case.ex` — shared fixture
- [ ] `examples/hex_consumer/test/test_helper.exs`
- [ ] `examples/hex_consumer/priv/repo/seeds.exs` — nightly_sync fixture
- [ ] `.github/workflows/release.yml` edit — add `verify-published` job

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `examples/hex_consumer/mix.lock` should not be committed | Focus Q4 | Committed lock causes stale version testing; low risk because `== <version>` pin handles the critical case |
| A2 | `examples/hex_consumer/priv/repo/migrations/` should not be committed | Focus Q4 | If committed, they may drift from what the installer generates from the published tarball — better to regenerate from installer each time |
| A3 | `mix oban_powertools.install` is non-interactive (no `--yes` flag needed) | Pitfall D | If interactive, CI job hangs; but existing `host-contract-proof.yml` `fresh-host` lane confirms non-interactive behavior |
| A4 | Igniter does not require the app to be listed in `only: [:dev, :test]` in adopter's mix.exs | General | mix.exs already has `{:igniter, "~> 0.8.0", runtime: false}` which means it IS available for compilation everywhere; adopters who run the installer need it compilable in their dev env |
| A5 | `.gitignore` addition for `examples/hex_consumer/mix.lock` is sufficient; no special gitignore file needed | Focus Q4 | Repo-root `.gitignore` may already cover `mix.lock` entries; confirm before adding duplicate entries |

---

## Open Questions

1. **Does `mix oban_powertools.install` require Oban to already be in the host's `mix.exs`?**
   - What we know: `examples/phoenix_host/mix.exs` includes `{:oban, "~> 2.18"}` as an explicit dep alongside `oban_powertools`.
   - What's unclear: Whether the installer task assumes Oban is a dep of the host, or whether it adds it.
   - Recommendation: Check `oban_powertools.install.ex` for any Oban dep injection. If Oban must be pre-declared, add it to `hex_consumer/mix.exs` explicitly (as `phoenix_host` does).

2. **Should `verify-published` be added to `host-contract-gate` in `host-contract-proof.yml`?**
   - What we know: `host-contract-gate` aggregates all lanes in that workflow. `verify-published` lives in `release.yml`, a separate workflow.
   - What's unclear: Whether the release pipeline should have its own aggregate gate.
   - Recommendation: No — `verify-published` is a leaf job in `release.yml`. A red `verify-published` job is visible on the release commit and on the workflow run. No aggregator needed.

3. **What database name should `test.exs` use for `hex_consumer`?**
   - Recommendation: `hex_consumer_test` to distinguish from `phoenix_host_test` used by all other CI jobs.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir 1.19.5 | All mix steps | Provided by `erlef/setup-beam` in CI | 1.19.5 | — |
| OTP 27.3 | All mix steps | Provided by `erlef/setup-beam` in CI | 27.3 | — |
| postgres:16 | `mix ecto.create`, tests | Docker service in CI | 16 | — |
| hex.pm | `mix deps.get` for hex dep | Required (internet access) | — | No fallback — `verify-published` is an internet-facing job by design |
| `oban_powertools` 0.5.0 on hex.pm | `mix deps.get` | Confirmed live (v0.5.0 already published) | 0.5.0 | — |

**Note for local `regenerate.sh` use:** hex.pm reachability is required. Document in README.md.

---

## Security Domain

Security enforcement is not applicable to this phase. This is a CI verification job adding
no new library surface, no new user-facing routes, and no new auth flows. The
`verify-published` job runs with `permissions: contents: read` (read-only, same as
`publish-hex`).

The only secret used is `HEX_API_KEY` in `publish-hex` (already in the pipeline). The new
`verify-published` job needs no secrets — it only reads from hex.pm.

---

## Sources

### Primary (HIGH confidence)
- Direct inspection: `/Users/jon/projects/oban_powertools/.github/workflows/release.yml` — job outputs, `publish-hex` structure, version propagation
- Direct inspection: `/Users/jon/projects/oban_powertools/.github/workflows/host-contract-proof.yml` — Postgres service block, setup-beam versions, first-session job pattern
- Direct inspection: `/Users/jon/projects/oban_powertools/examples/phoenix_host/test/phoenix_host_web/oban_powertools_first_session_test.exs` — exact first-session test flow (91 lines)
- Direct inspection: `/Users/jon/projects/oban_powertools/test/support/example_host_contract.ex` — `first_session!` flow, `rewrite_powertools_path!` pattern
- Direct inspection: `/Users/jon/projects/oban_powertools/test/support/fresh_host_contract.ex` — install harness structure
- Direct inspection: `/Users/jon/projects/oban_powertools/examples/phoenix_host/regenerate.sh` — `regenerate.sh` conventions
- Direct inspection: `/Users/jon/projects/oban_powertools/examples/phoenix_host/mix.exs` — example app structure, dep declarations
- Direct inspection: `/Users/jon/projects/oban_powertools/mix.exs` — `:files` whitelist, version, `@source_url`
- Direct tarball inspection: `oban_powertools-0.5.0.tar` contents via `tar tzf /tmp/contents.tar.gz` — confirmed `:files` whitelist correctness, no `priv/` in tarball
- Direct inspection: `/Users/jon/projects/oban_powertools/lib/mix/tasks/oban_powertools.install.ex` — migrations embedded as strings, no `priv/` needed
- Direct inspection: `/Users/jon/projects/oban_powertools/examples/phoenix_host/priv/repo/seeds.exs` — `nightly_sync` fixture
- Direct inspection: `/Users/jon/projects/oban_powertools/.planning/phases/51-published-package-verification/51-CONTEXT.md` — locked decisions

### Secondary (MEDIUM confidence)
- `.planning/research/PITFALLS.md` — Pitfall 1 (`:files`), Pitfall 3 (hex consumer), Pitfall 17 (clean-tree) — high-quality in-repo research derived from direct code inspection

---

## Metadata

**Confidence breakdown:**
- D-02b version forcing mechanism: HIGH — derived from direct inspection of release.yml job outputs, which are an established pattern in the existing pipeline
- CI service/runner setup: HIGH — copied from verified host-contract-proof.yml pattern
- Harness reuse vs copy: HIGH — test file inspected directly; namespace substitution is the only required change
- `:files` whitelist correctness: HIGH — verified against actual built tarball contents
- `hex_consumer/` shape: HIGH — directly mirrors `phoenix_host/` with documented differences
- `regenerate.sh` design: HIGH — mirrors existing scripts with one key change (hex dep instead of path dep)

**Research date:** 2026-05-29
**Valid until:** 2026-07-01 (stable release pipeline; only invalidated by upstream changes to `erlef/setup-beam` versions or release-please output schema)
