# Phase 81 Deferred Items — Dependency Advisory Follow-up

## Deferred Items

### Merge the audited lockfile update

- **Status:** pending
- **Item:** Merge the tested dependency update from `fix/security-advisory-closeout` into `main` through a green PR.
- **Reason:** The current remote `main` lockfile still contains the affected versions; the isolated branch evidence does not close the repository's live advisory status until merged.
- **Release:** No package release is required; these are development, test, and optional dependency lock updates, and compatibility ranges are unchanged.

## Resolved Package Versions

On 2026-09-25, `mix hex.audit` identified advisories in the repository's locked
dependency graph. `mix.lock` was updated in the isolated branch
`fix/security-advisory-closeout` to these non-vulnerable releases:

| Package | Before | After | Advisory disposition |
| --- | --- | --- | --- |
| Mint | 1.9.3 | 1.10.1 | Resolves CVE-2026-82728 (High), CVE-2026-82729 (Medium), and CVE-2026-82672 (Medium). |
| Postgrex | 0.22.3 | 0.22.4 | Resolves CVE-2026-66838 (Medium); no `Postgrex.stream/4` call or untrusted `:comment` forwarding was found in this repository. |
| Phoenix LiveView | 1.2.8 | 1.2.12 | Includes the CVE-2026-64941 redirect fix. |
| Igniter | 0.8.3 | 0.8.4 | Resolves CVE-2026-82584 in the install confirmation prompt. |
| LazyHTML | 0.1.12 | 0.1.13 | `mix hex.audit` no longer reports CVE-2026-92106. |

The advisory scope was the committed repository lockfile. Mint is reached by
the development/install-tool dependency path through Igniter → Req → Finch;
Igniter is `runtime: false`. LazyHTML is test-only. LiveView is optional for
the native UI. The project's existing dependency compatibility ranges were
left unchanged to avoid silently narrowing the supported host contract.
Adopter applications must still audit their own lockfiles; this lock update
does not rewrite downstream application locks.

## Verification Evidence

- Before: `mix hex.audit` reported seven CVEs across five package entries,
  including a High Mint advisory.
- After: `HEX_HOME=/private/tmp/oban-powertools-hex-home mix hex.audit` reported
  `No retired or security advisory packages found`.
- `mix compile --warnings-as-errors` passed on the updated lockfile.
- `HEX_HOME=/private/tmp/oban-powertools-hex-home ELIXIR_MAKE_CACHE_DIR=/private/tmp/oban-powertools-elixir-make-cache mix test --exclude host_contract --seed 0`
  passed: 966 tests, 0 failures, 7 excluded. LazyHTML's precompiled NIF was
  fetched from the official release asset and matched the checksum recorded
  in the package's `checksum.exs`.
- Advisory sources: [Mint](https://hex.pm/packages/mint/advisories),
  [Postgrex](https://hex.pm/packages/postgrex/advisories),
  [Phoenix LiveView](https://hex.pm/packages/phoenix_live_view/advisories),
  [Igniter](https://github.com/ash-project/igniter/security/advisories/GHSA-cj7w-j579-gc42),
  and [LazyHTML](https://hex.pm/packages/lazy_html/advisories).
- Evidence source: `mix hex.audit` and `mix hex.outdated` on the pre-update
  lockfile, recorded on 2026-09-25; package versions and checksums are in
  `mix.lock`.
