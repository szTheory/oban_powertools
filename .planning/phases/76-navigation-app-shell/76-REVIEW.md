---
phase: 76-navigation-app-shell
reviewed: 2026-07-12T15:43:52Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - assets/oban_powertools/theme.js
  - assets/oban_powertools/tokens.css
  - lib/oban_powertools/web/components/app_shell.ex
  - lib/oban_powertools/web/dev/showcase_live.ex
  - lib/oban_powertools/web/live_auth.ex
  - lib/oban_powertools/web/theme_shell.ex
  - priv/static/oban_powertools/oban_powertools.css
  - priv/static/oban_powertools/oban_powertools.js
  - scripts/showcase_manifest.exs
  - test/browser/specs/shell.behavior.spec.ts
  - test/browser/specs/showcase.structure.spec.ts
  - test/browser/support/manifest-smoke.mjs
  - test/browser/support/manifest.ts
  - test/browser/support/showcase.ts
  - test/oban_powertools/shell_story_catalog_test.exs
  - test/oban_powertools/web/assets_test.exs
  - test/oban_powertools/web/components/app_shell_test.exs
  - test/oban_powertools/web/live/app_shell_layout_test.exs
  - test/oban_powertools/web/live/showcase_live_test.exs
  - test/oban_powertools/web/theme_tokens_test.exs
  - test/support/shell_story_catalog.ex
findings:
  critical: 0
  warning: 6
  info: 0
  total: 6
status: issues_found
---

# Phase 76: Code Review Report

**Reviewed:** 2026-07-12T15:43:52Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

Reviewed the Phase 76 app shell, theme assets, showcase manifest plumbing, browser support, and ExUnit/Playwright coverage. The checked-in static CSS and JS are byte-identical to their source asset copies, so there is no current generated-asset drift. The implementation still has warning-tier runtime, accessibility, validation, and test-coverage defects that should be fixed before relying on the shell contracts.

## Warnings

### WR-01: WARNING - Theme controls are synchronized before they exist in the DOM

**File:** `lib/oban_powertools/web/theme_shell.ex:27`
**Issue:** The parser-blocking theme script is rendered before `<AppShell.app_shell>` and the showcase content. `assets/oban_powertools/theme.js` immediately calls `applyStoredTheme()` and `syncThemeControls()`, but at that point the `[data-obpt-theme-choice]` buttons have not been parsed yet. A user with a stored non-system theme can get correct root attributes while the visible/accessible button state remains server-default (`System`) or unset until they interact again.
**Fix:** Re-run the control sync after the document is parsed, or move the script after the shell markup. If first-paint theme is a concern, keep only root-attribute initialization early and defer control synchronization.

```javascript
applyStoredTheme();

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", applyStoredTheme, { once: true });
}
```

### WR-02: WARNING - JavaScript asset is not tracked by LiveView static asset tracking

**File:** `lib/oban_powertools/web/theme_shell.ex:27`
**Issue:** The stylesheet link has `phx-track-static`, but the JavaScript asset does not. Phoenix LiveView's static tracking will detect CSS hash changes but not this shell behavior script, so long-lived clients can keep stale navigation/theme behavior after a deploy even though the script path is fingerprinted.
**Fix:**

```heex
<script phx-track-static type="text/javascript" src={Assets.path(:js)}></script>
```

### WR-03: WARNING - Theme choice label is on a generic div with no group semantics

**File:** `lib/oban_powertools/web/components/app_shell.ex:126`
**Issue:** `aria-label="Theme choices"` is placed on a plain `<div>`. A generic div has no useful grouping semantics here, so assistive technologies may expose four independent pressed buttons without a named group. This is an accessibility regression for the new shell controls.
**Fix:**

```heex
<div class="obpt-theme-choices" role="group" aria-label="Theme choices">
```

### WR-04: WARNING - Showcase fixture index uses invalid ARIA row structure

**File:** `lib/oban_powertools/web/dev/showcase_live.ex:326`
**Issue:** The fixture index assigns `role="row"` to standalone divs, but there is no containing `table`, `grid`, `treegrid`, or `rowgroup`, and the child spans are not cells. That produces malformed accessibility semantics in the showcase that browser a11y checks can miss if they only assert visibility.
**Fix:** Use a semantic table for the index, or remove the row roles if this is only visual layout.

```heex
<table class="obpt-showcase-fixture-index">
  <thead>...</thead>
  <tbody>
    <tr :for={scenario <- @catalog_scenarios}>...</tr>
  </tbody>
</table>
```

### WR-05: WARNING - Nav path validation allows sibling routes outside `/ops/jobs`

**File:** `lib/oban_powertools/web/components/app_shell.ex:360`
**Issue:** `require_safe_path!/1` accepts any path that starts with `"/ops/jobs"`, so a caller-provided nav item such as `"/ops/jobs-archive"` or `"/ops/jobs_evil"` passes validation even though it is not the root route or a child route. The error message says paths must stay under `/ops/jobs`, but the boundary check does not enforce that.
**Fix:**

```elixir
path != @root_path and not String.starts_with?(path, @root_path <> "/") ->
  raise ArgumentError, "nav path must stay under #{@root_path}"
```

### WR-06: WARNING - Asset tests can overwrite stale generated files before detecting drift

**File:** `test/oban_powertools/web/assets_test.exs:54`
**Issue:** The asset tests run `Mix.Task.rerun("oban_powertools.assets.build", [])` before taking the first hash or reading the compiled CSS/JS. If the committed `priv/static` assets are stale, the test rewrites them from `assets/` and then passes, masking the generated-asset inconsistency and potentially leaving the worktree dirty.
**Fix:** Capture checked-in static hashes before running the build, and make the content test read the checked-in files without rebuilding first.

```elixir
before = static_sha256s()
Mix.Task.rerun("oban_powertools.assets.build", [])
after_build = static_sha256s()

assert after_build == before
```

---

_Reviewed: 2026-07-12T15:43:52Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
