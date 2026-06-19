# Phase 73: visual-regression-a11y-harness - Pattern Map

**Mapped:** 2026-06-19
**Files analyzed:** 22
**Analogs found:** 18 / 22

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `package.json` | config | batch | `mix.exs` | partial |
| `package-lock.json` | config | batch | none | none |
| `playwright.config.ts` | config | batch | none | none |
| `scripts/showcase_manifest.exs` | utility | transform, file-I/O | `test/support/showcase_catalog.ex` | exact |
| `scripts/playwright-docker.sh` | utility | batch | `examples/phoenix_host/regenerate.sh` | role-match |
| `scripts/with-showcase-server.sh` | utility | request-response, batch | `test/support/example_host_contract.ex` | role-match |
| `test/browser/specs/showcase.structure.spec.ts` | test | request-response | `test/oban_powertools/web/live/showcase_live_test.exs` | role-match |
| `test/browser/specs/showcase.vrt.spec.ts` | test | file-I/O | `test/oban_powertools/showcase_catalog_test.exs` | partial |
| `test/browser/specs/showcase.a11y.spec.ts` | test | transform, file-I/O | `test/oban_powertools/web/live/showcase_live_test.exs` | partial |
| `test/browser/support/manifest.ts` | utility | transform, file-I/O | `test/oban_powertools/showcase_catalog_test.exs` | partial |
| `test/browser/support/showcase.ts` | utility | request-response | `assets/oban_powertools/theme.js` | partial |
| `test/browser/support/deterministic.ts` | utility | transform | `test/oban_powertools/web/theme_tokens_test.exs` | partial |
| `test/browser/support/axe.ts` | utility | transform | `test/support/showcase_catalog.ex` | partial |
| `test/browser/styles/screenshot.css` | config | transform | `assets/oban_powertools/tokens.css` | role-match |
| `test/browser/.generated/showcase-manifest.json` | generated artifact | file-I/O | `test/support/showcase_catalog.ex` | partial |
| `test/browser/__screenshots__/**/*.png` | artifact | file-I/O | none | none |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.gitignore` | config | file-I/O | `.gitignore` | exact |
| `guides/visual-regression-and-a11y.md` | docs | batch | `guides/brand-book.md` | role-match |
| `README.md` | docs | batch | `README.md` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `test/oban_powertools/docs_contract_test.exs` | test | file-I/O | `test/oban_powertools/docs_contract_test.exs` | exact |

## Pattern Assignments

### `scripts/showcase_manifest.exs` (utility, transform/file-I-O)

**Analog:** `test/support/showcase_catalog.ex`

**Single source pattern** (lines 416-436):

```elixir
def scenarios, do: @scenarios

def scenario!(id) when is_binary(id) do
  Map.fetch!(@scenarios_by_id, id)
rescue
  KeyError ->
    raise ArgumentError, "unknown showcase scenario: #{inspect(id)}"
end

def snapshot_name(id) when is_binary(id) do
  "showcase/#{scenario!(id).id}"
end

def a11y_target(id) when is_binary(id) do
  ~s([data-obpt-story="#{scenario!(id).id}"])
end
```

**Dependency pattern** (from `mix.exs` lines 20-21, 41-55):

```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]

defp deps do
  [
    {:jason, "~> 1.4"},
    {:oban, "~> 2.18"}
  ]
end
```

**Copy guidance:** Generate JSON by calling `ObanPowertools.ShowcaseCatalog.scenarios/0`, `snapshot_name/1`, and `a11y_target/1`. Do not parse `.ex` source text or duplicate the scenario IDs in JavaScript. Keep generated JSON free of timestamps, absolute paths, and randomized order.

---

### `scripts/playwright-docker.sh` (utility, batch)

**Analog:** `examples/phoenix_host/regenerate.sh`

**Shell entry pattern** (lines 1-6):

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CANONICAL_DIR="${ROOT_DIR}/examples/phoenix_host"
TARGET_DIR="${ROOT_DIR}/examples/.phoenix_host_regen"
```

**Command grouping pattern** (lines 38-42):

```bash
(
  cd "${TARGET_DIR}"
  mix deps.get
  mix oban_powertools.install
)
```

**Copy guidance:** Use the same `#!/usr/bin/env bash` plus `set -euo pipefail` style. Resolve `ROOT_DIR` from the script path, accept/pass through all remaining arguments, and run Docker with the pinned Playwright image from RESEARCH.md. Preserve caller-provided args for narrow `--grep` and `--project` updates.

---

### `scripts/with-showcase-server.sh` (utility, request-response/batch)

**Analogs:** `test/support/example_host_contract.ex`, `examples/phoenix_host/config/dev.exs`, `examples/phoenix_host/lib/phoenix_host_web/router.ex`

**Subprocess error pattern** (`test/support/example_host_contract.ex` lines 48-66):

```elixir
def run!(dir, env, command, args) do
  {output, status} =
    System.cmd(command, args,
      cd: dir,
      env: env,
      stderr_to_stdout: true
    )

  if status != 0 do
    raise """
    command failed: #{command} #{Enum.join(args, " ")}
    status: #{status}

    #{output}
    """
  end

  output
end
```

**Host route pattern** (`examples/phoenix_host/lib/phoenix_host_web/router.ex` lines 25-29):

```elixir
scope "/ops/jobs" do
  pipe_through :browser

  ObanPowertools.Web.Router.oban_powertools_routes("/oban")
end
```

**Dev server config pattern** (`examples/phoenix_host/config/dev.exs` lines 19-27, 65-66):

```elixir
config :phoenix_host, PhoenixHostWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "...",
  watchers: []

config :phoenix_host, dev_routes: true
```

**Copy guidance:** Start `examples/phoenix_host` and wait for `/ops/jobs/_showcase` to respond before running the provided command. Trap exits and clean up the server process. Keep `PLAYWRIGHT_TEST_BASE_URL` configurable for Docker Desktop vs Linux CI networking.

---

### `test/browser/specs/showcase.structure.spec.ts` (test, request-response)

**Analog:** `test/oban_powertools/web/live/showcase_live_test.exs`

**Route and shell assertions** (lines 40-47, 90-103):

```elixir
test "renders the showcase through the Powertools theme shell", %{conn: conn} do
  {:ok, _view, html} = mount_showcase!(conn)

  assert count(html, "obpt-root") == 1
  assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.css|
  assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.js|
  assert html =~ "data-obpt-showcase"
end

defp mount_showcase!(conn) do
  live(conn, "/ops/jobs/_showcase")
end
```

**Stable selector assertions** (lines 49-84):

```elixir
assert_attribute_values(html, "data-obpt-theme-choice", @theme_choices)
assert_attribute_values(html, "data-obpt-viewport", @viewport_choices)
assert_attribute_values(html, "data-obpt-section", @section_ids)
assert_attribute_values(html, "data-obpt-story", Enum.map(@story_contracts, & &1.id))
assert_attribute_values(html, "data-obpt-open-state-target", @open_state_targets)
```

**Copy guidance:** In Playwright, assert the same contracts through browser-visible locators: one `.obpt-root`, md5 CSS/JS asset URLs, all theme choices, all viewport choices, section anchors, and every manifest scenario selector.

---

### `test/browser/specs/showcase.vrt.spec.ts` (test, file-I-O)

**Analogs:** `test/oban_powertools/showcase_catalog_test.exs`, `lib/oban_powertools/web/dev/showcase_live.ex`, `assets/oban_powertools/tokens.css`

**Snapshot/a11y naming contract** (`test/oban_powertools/showcase_catalog_test.exs` lines 111-133):

```elixir
test "snapshot_name/1 and a11y_target/1 derive from scenario ID instead of display copy" do
  Enum.each(ShowcaseCatalog.scenarios(), fn scenario ->
    id = scenario_field!(scenario, :id)
    expected_snapshot_name = "showcase/#{id}"
    expected_a11y_target = ~s([data-obpt-story="#{id}"])

    assert ShowcaseCatalog.snapshot_name(id) == expected_snapshot_name
    assert ShowcaseCatalog.a11y_target(id) == expected_a11y_target
  end)
end
```

**Story cell selector pattern** (`lib/oban_powertools/web/dev/showcase_live.ex` lines 243-272):

```elixir
<article
  :for={scenario <- @catalog_scenarios}
  id={"obpt-story-#{scenario.id}"}
  class="obpt-showcase-story"
  data-obpt-story={scenario.id}
  data-obpt-domain={stringify(scenario.domain)}
  data-obpt-persona={story_persona(scenario)}
  data-obpt-state={state_value(scenario.states)}
>
  <header>
    <p>{stringify(scenario.domain)}</p>
    <h3>{scenario.name}</h3>
  </header>
</article>
```

**Viewport control CSS pattern** (`assets/oban_powertools/tokens.css` lines 634-653):

```css
.obpt-root .obpt-showcase-canvas {
  display: flex;
  flex-direction: column;
  gap: var(--obpt-space-4);
  width: 100%;
  max-width: 100%;
  margin-inline: auto;
}

.obpt-root .obpt-showcase-canvas--320 {
  max-width: 20rem;
}

.obpt-root .obpt-showcase-canvas--tablet {
  max-width: 48rem;
}

.obpt-root .obpt-showcase-canvas--wide {
  max-width: 72rem;
}
```

**Copy guidance:** Use Playwright `toHaveScreenshot()` against the story locator from the manifest, not the whole page. Name snapshots from `scenario.snapshot` plus theme. Do not broad-mask story content.

---

### `test/browser/specs/showcase.a11y.spec.ts` and `test/browser/support/axe.ts` (test/utility, transform/file-I-O)

**Analogs:** `test/support/showcase_catalog.ex`, `lib/oban_powertools/web/dev/showcase_live.ex`

**A11y target pattern** (`test/support/showcase_catalog.ex` lines 431-436):

```elixir
def snapshot_name(id) when is_binary(id) do
  "showcase/#{scenario!(id).id}"
end

def a11y_target(id) when is_binary(id) do
  ~s([data-obpt-story="#{scenario!(id).id}"])
end
```

**Open-state metadata pattern** (`lib/oban_powertools/web/dev/showcase_live.ex` lines 44-48, 184-190):

```elixir
@open_state_targets [
  %{target: "confirm_action_open", owner: "Confirm action dialog"},
  %{target: "tooltip_open", owner: "Tooltip"},
  %{target: "drawer_open", owner: "Drawer"}
]

<div
  :for={entry <- @open_state_targets}
  class="obpt-showcase-open-target"
  data-obpt-open-state-target={entry.target}
>
```

**Copy guidance:** Run axe against `scenario.a11y` selectors from the manifest. Include open-state variants only when a real implemented open DOM/story exists; metadata alone is not a scan target. Fail only serious/critical violations, but attach full JSON results.

---

### `test/browser/support/manifest.ts` (utility, transform/file-I-O)

**Analog:** `test/oban_powertools/showcase_catalog_test.exs`

**Validation/fail-fast pattern** (lines 176-199):

```elixir
defp scenario_field!(scenario, key) do
  scenario
  |> scenario_map()
  |> Map.fetch!(key)
rescue
  KeyError ->
    flunk("D-01 requires every scenario to contain #{inspect(key)}")
end

defp target_field!(targets, key) when is_map(targets) do
  Map.get(targets, key) || Map.get(targets, Atom.to_string(key)) ||
    flunk("D-02 requires test_targets to contain #{inspect(key)}")
end
```

**Copy guidance:** Load `test/browser/.generated/showcase-manifest.json`, validate required fields (`schema_version`, `themes`, `viewports`, `scenarios`, `id`, `snapshot`, `a11y`, `story`), and throw descriptive errors before Playwright defines tests if the manifest is missing or malformed.

---

### `test/browser/support/showcase.ts` (utility, request-response)

**Analogs:** `assets/oban_powertools/theme.js`, `lib/oban_powertools/web/theme_shell.ex`

**Theme controller pattern** (`assets/oban_powertools/theme.js` lines 54-64, 94-107):

```javascript
function setTheme(theme) {
  const requestedTheme = normalizeTheme(theme);

  try {
    window.localStorage.setItem(STORAGE_KEY, requestedTheme);
  } catch (_error) {
    // Browsers can deny storage in private mode; theming remains scoped and usable.
  }

  roots().forEach((root) => apply(root, requestedTheme));
}

document.addEventListener("click", (event) => {
  const control = event.target.closest("[data-obpt-theme-choice]");

  if (control) {
    setTheme(control.getAttribute("data-obpt-theme-choice"));
  }
});

window.ObanPowertoolsTheme = {
  apply,
  setTheme,
  storedTheme,
  effectiveTheme
};
```

**Root shell pattern** (`lib/oban_powertools/web/theme_shell.ex` lines 13-24):

```elixir
<div
  id="oban-powertools"
  class="obpt-root"
  data-obpt-theme="system"
  data-obpt-effective-theme="light"
  data-obpt-motion="safe"
>
  <script type="text/javascript" src={Assets.path(:js)}></script>
  <main class="obpt-shell" data-obpt-shell>
    <%= @inner_content %>
  </main>
</div>
```

**Copy guidance:** `prepareShowcase` should navigate to `/ops/jobs/_showcase`, assert one `.obpt-root`, set theme via `window.ObanPowertoolsTheme.setTheme(theme)` or stable controls, click the matching `[data-obpt-viewport]`, wait for fonts, and assert `data-obpt-theme` plus deterministic `system` effective theme.

---

### `test/browser/support/deterministic.ts` and `test/browser/styles/screenshot.css` (utility/config, transform)

**Analogs:** `test/oban_powertools/web/theme_tokens_test.exs`, `assets/oban_powertools/tokens.css`

**Theme/media contract test pattern** (`test/oban_powertools/web/theme_tokens_test.exs` lines 159-193):

```elixir
test "motion and media preference hooks are centralized in the token layer" do
  css = read_contract_file!(@tokens_path)

  assert css =~ "@media (prefers-color-scheme: dark)"
  assert css =~ "@media (prefers-contrast: more)"
  assert css =~ "@media (prefers-reduced-motion: reduce)"
  assert css =~ ~s([data-obpt-motion="reduce"])
  assert css =~ "--obpt-motion-duration-fast"
  assert css =~ "--obpt-motion-duration-base"
  assert css =~ "--obpt-motion-ease-standard"
end
```

**Reduced motion CSS pattern** (`assets/oban_powertools/tokens.css` lines 353-360):

```css
@media (prefers-reduced-motion: reduce) {
  .obpt-root,
  .obpt-root[data-obpt-motion="reduce"] {
    --obpt-motion-duration-fast: var(--obpt-motion-duration-instant);
    --obpt-motion-duration-base: var(--obpt-motion-duration-instant);
    --obpt-motion-duration-slow: var(--obpt-motion-duration-instant);
  }
}
```

**Focus visibility pattern** (`assets/oban_powertools/tokens.css` lines 479-484):

```css
.obpt-root .obpt-input:focus-visible,
.obpt-root .obpt-button:focus-visible,
.obpt-root .obpt-tab:focus-visible {
  outline: 2px solid var(--obpt-color-focus);
  outline-offset: 2px;
}
```

**Copy guidance:** Keep screenshot CSS scoped and minimal. It may neutralize animation/caret/runtime volatility, but must not hide story text, status colors, focus indicators, long IDs, RTL/non-ASCII content, or severity signals.

---

### `.github/workflows/ci.yml` (config, batch)

**Analog:** `.github/workflows/ci.yml`

**Existing required lane pattern** (lines 71-107):

```yaml
test:
  name: Test
  runs-on: ubuntu-latest
  timeout-minutes: 15
  env:
    MIX_ENV: test
    PGUSER: postgres
    PGPASSWORD: postgres
  services:
    postgres:
      image: postgres:16
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: oban_powertools_test
      ports: ["5432:5432"]
      options: >-
        --health-cmd "pg_isready -U postgres"
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
```

**Fan-in pattern** (lines 138-165):

```yaml
ci-gate:
  name: ci-gate
  runs-on: ubuntu-latest
  needs: [format, compile, test, docs_package, actionlint]
  if: always()
  steps:
    - name: Verify required CI lanes
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
          result="${!lane}"
          if [[ "$result" != "success" ]]; then
            echo "Required lane $lane: $result"
            failed=1
          fi
        done
```

**Artifact upload pattern** (`.github/workflows/host-contract-proof.yml` lines 701-714):

```yaml
- name: Upload continuity proof packet
  id: upload_proof_packet
  if: always()
  uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4
  with:
    name: continuity-proof-packet
    if-no-files-found: error
    path: |
      tmp/ver04/ver04-claim-matrix.md
      tmp/ver04/ver04-claim-matrix.json
      tmp/ver04/run-metadata.json
      tmp/ver04/redaction-report.json
      tmp/ver04/phase40-gate-report.json
      tmp/ver04/logs/*.log
```

**Copy guidance:** Add `visual_a11y` inside this workflow, add it to `ci-gate.needs`, add `VISUAL_A11Y` to the env and verification loop, and upload Playwright reports/results with pinned `actions/upload-artifact` v4. Do not create a separate required workflow.

---

### `.gitignore` (config, file-I-O)

**Analog:** `.gitignore`

**Generated artifact grouping pattern** (lines 1-14, 36-45):

```gitignore
# The directory Mix will write compiled artifacts to.
/_build/

# If you run "mix test --cover", coverage assets end up here.
/cover/

# Temporary files, for example, from tests.
/tmp/

# GSD / agent run scratch artifacts (root-level, never committed).
/audit_uat.json
/discuss_mode.txt
*.patch
```

**Copy guidance:** Add ignored browser-run outputs such as `/playwright-report/`, `/test-results/`, and `/test/browser/.generated/`. Do not ignore `test/browser/__screenshots__/`; expected PNG baselines are committed.

---

### `guides/visual-regression-and-a11y.md`, `README.md`, `mix.exs`, `test/oban_powertools/docs_contract_test.exs` (docs/config/test, batch/file-I-O)

**Analogs:** `README.md`, `mix.exs`, `test/oban_powertools/docs_contract_test.exs`, `guides/brand-book.md`

**README guide index pattern** (`README.md` lines 121-149):

```markdown
## Guides

- [Installation](guides/installation.md) covers the exact host-owned setup path, including
  `ObanPowertoolsAuth`, `ObanPowertoolsDisplayPolicy`, and the compile/migrate/boot threshold.
- [First Operator Session](guides/first-operator-session.md) walks from install to the canonical
  `ops-demo` -> `pause_cron_entry` on `nightly_sync` proof, forensic confirmation, audit follow-up,
  and the read-only bridge.
```

**ExDoc extras registration pattern** (`mix.exs` lines 67-101):

```elixir
defp docs do
  [
    main: "readme",
    source_url: @source_url,
    source_ref: "v#{@version}",
    source_url_pattern: "#{@source_url}/blob/v#{@version}/%{path}#L%{line}",
    extras: ["README.md", "CHANGELOG.md" | Path.wildcard("guides/*.md")],
    groups_for_extras: [
      "Design System": [
        "guides/brand-book.md"
      ]
    ]
  ]
end
```

**Docs contract file list pattern** (`test/oban_powertools/docs_contract_test.exs` lines 4-20):

```elixir
@docs_files [
  "README.md",
  "guides/installation.md",
  "guides/first-operator-session.md",
  "guides/forensics-and-runbook-handoffs.md",
  "guides/example-app-walkthrough.md",
  "guides/workers-and-idempotency.md",
  "guides/limits-and-explain.md",
  "guides/workflows.md",
  "guides/lifeline-and-repairs.md",
  "guides/policy-integration-patterns.md",
  "guides/upgrade-and-compatibility.md",
  "guides/optional-oban-web-bridge.md",
  "guides/support-truth-and-ownership-boundaries.md",
  "guides/production-hardening.md",
  "guides/troubleshooting.md"
]
```

**Brand guardrail source** (`guides/brand-book.md` lines 108-115):

```markdown
1. **Color is information, never decoration.** *(high-leverage)* Roughly 90% of any
   surface is neutral / grayscale; saturated color is *reserved* to mean "look here -
   this is abnormal or operator-relevant" (ISA-101 High-Performance HMI). No decorative
   accent fills, gradients, or brand-color hero blocks.
2. **Color is never the sole signal.** *(high-leverage)* Every status, validation, and
   severity is carried by **>=2 channels**: color **+** (icon | text label | shape |
   position). A grayscale screenshot of any page must remain fully interpretable - make
   this an explicit VRT / accessibility check.
```

**Copy guidance:** If a new guide is created, register it in README and group it in `mix.exs`. Add docs-contract markers for baseline update commands, Docker-only updates, CI artifact paths, and the narrow claim that axe gates automated serious/critical findings only.

## Shared Patterns

### Catalog Single Source

**Source:** `test/support/showcase_catalog.ex`
**Apply to:** manifest script, manifest loader, VRT spec, a11y spec, generated manifest

```elixir
def scenarios, do: @scenarios
def snapshot_name(id) when is_binary(id), do: "showcase/#{scenario!(id).id}"
def a11y_target(id) when is_binary(id), do: ~s([data-obpt-story="#{scenario!(id).id}"])
```

Use catalog helpers. Do not duplicate the nine scenario IDs in TypeScript.

### Showcase Selectors

**Source:** `lib/oban_powertools/web/dev/showcase_live.ex`
**Apply to:** all Playwright specs/support

```elixir
data-obpt-theme-choice={theme.value}
data-obpt-viewport={viewport.value}
data-obpt-section={section.id}
data-obpt-story={scenario.id}
data-obpt-domain={stringify(scenario.domain)}
data-obpt-persona={story_persona(scenario)}
data-obpt-state={state_value(scenario.states)}
```

These are the browser-facing contracts. Prefer locators based on these attributes over text copy.

### Theme Determinism

**Source:** `assets/oban_powertools/theme.js` and `lib/oban_powertools/web/theme_shell.ex`
**Apply to:** `support/showcase.ts`, VRT spec, a11y spec, Playwright config

```javascript
window.ObanPowertoolsTheme = {
  apply,
  setTheme,
  storedTheme,
  effectiveTheme
};
```

Set media preferences in Playwright, then set the root theme through `setTheme`. Assert `system` resolves to deterministic light mode under the configured media.

### CI Fan-In

**Source:** `.github/workflows/ci.yml`
**Apply to:** `.github/workflows/ci.yml`

```yaml
ci-gate:
  needs: [format, compile, test, docs_package, actionlint]
  if: always()
```

Add `visual_a11y` to this fan-in and the shell verification loop. The repo protects `ci-gate`, not separate per-lane statuses.

### Artifact Discipline

**Source:** `.github/workflows/host-contract-proof.yml`
**Apply to:** `visual_a11y` CI job

```yaml
uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4
with:
  if-no-files-found: error
  path: |
    tmp/ver04/ver04-claim-matrix.md
    tmp/ver04/ver04-claim-matrix.json
```

Use the same pinned artifact action style. Upload only Playwright reports, test results, diffs, axe JSON, and generated manifest; avoid broad workspace uploads.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `package.json` | config | batch | Repo has no committed Node workspace pattern; current untracked file is `{}`. Use RESEARCH.md standard stack and exact npm scripts. |
| `package-lock.json` | config | batch | Repo has no committed npm lockfile pattern. Generate with `npm install --save-dev` exact versions, then commit. |
| `playwright.config.ts` | config | batch | No TypeScript or Playwright config exists. Use RESEARCH.md Pattern 2 and official Playwright config APIs. |
| `test/browser/__screenshots__/**/*.png` | artifact | file-I/O | No existing visual baselines. Use Playwright committed snapshot output and keep paths human-readable by project/story/theme. |

## Metadata

**Analog search scope:** `.github/workflows`, `test/support`, `test/oban_powertools`, `lib/oban_powertools/web`, `assets/oban_powertools`, `examples/phoenix_host`, `guides`, root config files.
**Files scanned:** 35 source/config/docs files plus `rg`/`find` discovery.
**Pattern extraction date:** 2026-06-19

