# Visual Regression And A11y Guardrails

Phase 73 adds a browser guardrail for the dev-only showcase route at
`/ops/jobs/_showcase`. The harness uses the generated showcase manifest, the real
`examples/phoenix_host` route, Chromium projects for `320`, `tablet`, and `wide`, and the
pinned Playwright Docker image `mcr.microsoft.com/playwright:v1.61.0-noble`.

## Normal Gate Run

Run the full local gate with:

```bash
npm run visual:a11y
```

That command regenerates `test/browser/.generated/showcase-manifest.json`, starts the
example host, and runs the Playwright structure, axe, and visual-regression specs in
compare mode. It does not update screenshots.

CI runs the same unfiltered command in the `visual_a11y` lane. The required `ci-gate`
status fans in both that full-showcase lane and the focused `page_quality` lane, so
component, group, and page visual/accessibility regressions all block merges. The scheduled
nightly run is additional evidence, not a substitute for the pull-request gate.

## Visual Baselines

The committed baseline matrix is:

- 163 catalog-backed targets from the seven generated showcase catalogs
- 4 themes: `system`, `light`, `dark`, `high-contrast`
- 3 Chromium viewport projects: `chromium-320`, `chromium-tablet`, `chromium-wide`

That produces 1,956 PNGs under:

```text
test/browser/__screenshots__/chromium-*/showcase/*/*.png
```

Snapshots are target-level crops, not full-page screenshots. The manifest currently covers
scenario, primitive, form, shell, data, group, and page targets.

## Forward-Only Idempotency Contract

The normal quality path is compare-only and unfiltered:

```bash
CI=1 npm run verify:pages
CI=1 npm run visual:a11y
```

Completion requires the generated manifest and exact ARIA/PNG sets to validate,
the repeated asset build to be byte-stable, the component no-raw-values
contracts to pass, and both browser lanes to exit zero without snapshot update
flags. Update mode creates proposed review artifacts only; it never proves the
current baseline matches.

Run the focused token/component/asset contract with:

```bash
mix test \
  test/oban_powertools/web/theme_tokens_test.exs \
  test/oban_powertools/web/assets_test.exs \
  test/oban_powertools/web/components/primitives_test.exs \
  test/oban_powertools/web/components/forms_test.exs \
  test/oban_powertools/web/components/app_shell_test.exs \
  --seed 0
```

See [Contributing To The Design System](design-system-contributing.md) for the
component extension, theming, and no-raw-values workflow.

## Baseline Updates

Update snapshots only when the visual change is intentional; explain the reason in the PR.

Use the Docker-only changed-update path:

```bash
npm run vrt:update
```

That script runs Playwright through `scripts/playwright-docker.sh`.

The default update mode is `--update-snapshots=changed`, so unchanged baselines are left
alone. For a narrow reviewed update, pass Playwright filters through the script:

```bash
npm run vrt:update -- --grep "overview-operational-empty" --project chromium-320
npm run vrt:update -- --grep "high-contrast.*forensics" --project chromium-wide
```

PRs that change PNG baselines should include:

- The user-facing reason the visual change is intentional.
- The command used to update the baseline.
- Whether reviewers should inspect `playwright-report/`, `test-results/`, or the changed PNGs.

Never run snapshot update flags in CI.

## Failure Artifacts

On CI failure, the `visual_a11y` lane uploads only these short-retention artifacts:

- `playwright-report/`
- `test-results/`
- `test/browser/.generated/showcase-manifest.json`

`test-results/axe/**/*.json` contains full axe results, including `violations`, `passes`,
`incomplete`, and `inapplicable`. Visual failures write actual and diff images under
`test-results/`; those are review artifacts, not committed baselines.

## Accessibility Claim Boundary

Automated axe gate passed for critical and serious findings on the captured showcase targets.

Moderate, minor, and incomplete axe results are preserved in JSON artifacts for review, but
they are not merge-blocking in this gate. This automated check does not prove keyboard
traversal, dialog focus management, screen-reader quality, reduced motion behavior, reflow, or
the full manual accessibility contract.
