# Contributing To The Design System

Oban Powertools owns its operator UI from tokens through page composition. The
dev-only showcase at `/ops/jobs/_showcase` is the canonical audit surface: every
visual component or page-pattern change must appear there before it is considered
complete.

## Ownership Layers

Work from the lowest shared layer that expresses the change:

1. `assets/oban_powertools/tokens.css` owns primitive and semantic `--obpt-*`
   values, scoped styles, responsive behavior, and motion.
2. `lib/oban_powertools/web/components/` owns reusable Phoenix components.
3. The dev/test story catalogs under `test/support/` own deterministic showcase
   states and stable IDs.
4. `ObanPowertools.Web.Dev.ShowcaseLive` renders those catalogs.
5. Production LiveViews compose the shared components; they do not fork their
   visual rules.

Do not add a component because a generic design system might need it. Add or
extend one only when a shipped Powertools page needs the behavior.

## Token Contract

`--obpt-*` custom properties are a public, semver-protected contract. Components
consume semantic roles such as surface, text, border, accent, status, spacing,
type, radius, elevation, and motion. They do not introduce raw hex colors or
component-local pixel spacing when a token exists.

The checked-in source and packaged assets must remain synchronized:

```bash
mix oban_powertools.assets.build
cmp -s assets/oban_powertools/tokens.css \
  priv/static/oban_powertools/oban_powertools.css
cmp -s assets/oban_powertools/theme.js \
  priv/static/oban_powertools/oban_powertools.js
```

`test/oban_powertools/web/assets_test.exs` runs the asset build twice and rejects
byte drift.

## Theme Rules

Themes are isolated under `.obpt-root`. Theme state belongs on that root through
`data-obpt-theme`; never mutate `<html>`, host Tailwind configuration, or host
selectors. Support all four showcase choices: `system`, `light`, `dark`, and
`high-contrast`. Motion must use the shared duration/easing tokens and remain
safe when `prefers-reduced-motion` is enabled.

Components own their classes and visual variants. Do not add caller `class` or
`style` escape hatches that bypass the library’s visual policy.

## Adding Or Extending A Component

1. Start with a failing focused component contract under
   `test/oban_powertools/web/components/`.
2. Implement the smallest shared component behavior using tokens and native HTML
   semantics.
3. Add deterministic states to the matching catalog in `test/support/`. Keep the
   catalog ID slug stable; it becomes the selector, accessibility target, and
   snapshot name.
4. Render the story through the showcase and regenerate the manifest:

   ```bash
   npm run showcase:manifest
   node test/browser/support/manifest-smoke.mjs
   ```

5. Add or extend keyboard/behavior coverage. Run the focused ExUnit and
   Playwright checks before the full gates.
6. If pixels intentionally change, use the pinned Docker update path and review
   every changed PNG:

   ```bash
   npm run vrt:update -- --grep "stable-story-id"
   ```

7. Finish with compare-only verification:

   ```bash
   CI=1 npm run verify:pages
   CI=1 npm run visual:a11y
   ```

Snapshot update mode creates review input; it is never passing evidence.

## No-Raw-Values Checks

The no-raw-values policy is executable, not a manual convention. The component
source contracts reject raw colors, raw component spacing, host selectors, host
theme mutation, unsafe raw HTML APIs, and visual escape hatches:

```bash
mix test \
  test/oban_powertools/web/components/primitives_test.exs \
  test/oban_powertools/web/components/forms_test.exs \
  test/oban_powertools/web/components/app_shell_test.exs \
  --seed 0
```

When adding a new component module, add the equivalent source-policy assertion
to its focused test rather than relying on an informal grep.

## Forward-Only Quality Contract

A change may move the design system forward only when all applicable evidence is
green:

- the generated manifest remains a closed, deterministic inventory;
- source and packaged assets are byte-stable;
- focused semantic and behavior tests pass;
- committed VRT baselines compare cleanly without update flags;
- axe reports no merge-blocking critical or serious violations;
- page acceptance, ARIA, reflow, keyboard, motion, and confidentiality contracts
  remain green;
- production packaging excludes the dev/test showcase catalogs.

See [Visual Regression And A11y Guardrails](visual-regression-and-a11y.md) for
the complete browser workflow and evidence boundary.

