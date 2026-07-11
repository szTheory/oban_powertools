---
phase: 74-primitives-library
reviewed: 2026-07-11T14:37:23Z
depth: standard
status: issues
files_reviewed: 20
files_reviewed_list:
  - lib/oban_powertools/web/components/primitives.ex
  - test/oban_powertools/web/components/primitives_test.exs
  - assets/oban_powertools/tokens.css
  - assets/oban_powertools/theme.js
  - priv/static/oban_powertools/oban_powertools.css
  - priv/static/oban_powertools/oban_powertools.js
  - test/oban_powertools/web/theme_tokens_test.exs
  - test/oban_powertools/web/assets_test.exs
  - test/support/primitive_story_catalog.ex
  - test/oban_powertools/primitive_story_catalog_test.exs
  - lib/oban_powertools/web/dev/showcase_live.ex
  - test/oban_powertools/web/live/showcase_live_test.exs
  - scripts/showcase_manifest.exs
  - test/browser/support/manifest.ts
  - test/browser/support/manifest-smoke.mjs
  - test/browser/support/showcase.ts
  - test/browser/specs/showcase.structure.spec.ts
  - test/browser/specs/showcase.vrt.spec.ts
  - test/browser/specs/showcase.a11y.spec.ts
  - test/browser/specs/primitives.behavior.spec.ts
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
---

# Phase 74: Code Review Report

**Reviewed:** 2026-07-11T14:37:23Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues

## Summary

Reviewed the Phase 74 primitive component, token/theme assets, showcase catalog/rendering, manifest generation, and browser coverage files. The main blockers are in the primitive button/link API: unsafe `href` schemes can be rendered as links, and aria-disabled buttons can still submit forms when callers pass `type="submit"`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Link href accepts executable URL schemes

**File:** `lib/oban_powertools/web/components/primitives.ex:175`
**Issue:** `link/1` validates that exactly one target is present, but it never validates `href` before passing it to `Phoenix.Component.link`. A caller can render `href="javascript:..."` or another executable scheme, which turns the navigation primitive into an XSS sink when clicked and violates the "navigation-only" contract.
**Fix:**
```elixir
def link(assigns) do
  target_count = Enum.count([assigns.href, assigns.patch, assigns.navigate], &present?/1)

  if target_count != 1 do
    raise ArgumentError, "link requires href, patch, or navigate"
  end

  assigns =
    assigns
    |> assign(:href, safe_href!(assigns.href))
    |> assign(:rest, visual_safe_rest(assigns.rest, suppress_actions?: true))

  ...
end

defp safe_href!(nil), do: nil

defp safe_href!(href) do
  href = href |> require_text!("link href")
  uri = URI.parse(href)

  cond do
    String.starts_with?(href, ["/", "#"]) and not String.starts_with?(href, "//") -> href
    uri.scheme in ["http", "https", "mailto"] -> href
    true -> raise ArgumentError, "unsupported link href scheme: #{inspect(uri.scheme)}"
  end
end
```
Add a render test that rejects `javascript:alert(1)` and any `data:` URL.

### CR-02: Disabled-with-reason buttons can still submit forms

**File:** `lib/oban_powertools/web/components/primitives.ex:62`
**Issue:** When `disabled_reason` is present, the component intentionally avoids native `disabled` and only sets `aria-disabled`, while still rendering caller-controlled `type={@type}` at line 66. If a caller passes `type="submit"`, the button remains clickable/focusable and can submit its form even though it is presented as disabled and LiveView action attrs were suppressed.
**Fix:** Force disabled-with-reason buttons to render as inert buttons, and cover native form-submit attributes in tests.
```elixir
rendered_type =
  if described? do
    "button"
  else
    normalize_button_type!(assigns.type)
  end

assigns =
  assigns
  |> assign(:type, rendered_type)
  |> assign(:native_disabled, assigns.disabled and not described?)
```
Add a regression test for `disabled_reason: "...", type: "submit"` that asserts `type="button"` and that no submit-capable native action remains.

## Warnings

### WR-01: Showcase guard ignores explicit dev_routes opt-out

**File:** `lib/oban_powertools/web/dev/showcase_live.ex:4`
**Issue:** The dev-only module guard is documented as controlled by `:dev_routes`, but the `or System.get_env("MIX_ENV", "dev") == "dev"` branch can define the showcase module even when a host explicitly compiles with `config :oban_powertools, dev_routes: false`. That weakens the dev-only boundary and makes the guard inconsistent with the neighboring brand book module.
**Fix:** Remove the `System.get_env/2` fallback and rely on `Application.compile_env(:oban_powertools, :dev_routes, Mix.env() == :dev)`. Align the route guard in the router in the same fix so module and route availability cannot diverge.

### WR-02: Manifest persona differs from rendered DOM and tests hide it

**File:** `scripts/showcase_manifest.exs:28`, `lib/oban_powertools/web/dev/showcase_live.ex:394`, `test/browser/support/showcase.ts:127`
**Issue:** The manifest exports `scenario.persona`, so `forensics-long-url-stacktrace` is emitted as `incident_response`. The LiveView renders that same scenario as `repair`, and the browser helper special-cases the ID to expect `repair`, so the structure test passes while the manifest target no longer represents the rendered DOM contract.
**Fix:** Pick one source of truth. Prefer updating the catalog data to the intended persona and removing both `story_persona/1` and `renderedPersona()` special cases, then assert `target.persona` directly against `data-obpt-persona` for every scenario.

---

_Reviewed: 2026-07-11T14:37:23Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
