defmodule ObanPowertools.Web.AssetsTest do
  use ObanPowertools.LiveCase, async: false

  @css_static "priv/static/oban_powertools/oban_powertools.css"
  @js_static "priv/static/oban_powertools/oban_powertools.js"

  test "asset module exposes content hashes and scoped route paths" do
    assert_assets_module_loaded!()

    css_hash = apply(ObanPowertools.Web.Assets, :current_hash, [:css])
    js_hash = apply(ObanPowertools.Web.Assets, :current_hash, [:js])

    assert css_hash =~ ~r/^[a-f0-9]{32}$/
    assert js_hash =~ ~r/^[a-f0-9]{32}$/

    assert apply(ObanPowertools.Web.Assets, :path, [:css]) ==
             "/ops/jobs/_assets/oban_powertools-#{css_hash}.css"

    assert apply(ObanPowertools.Web.Assets, :path, [:js]) ==
             "/ops/jobs/_assets/oban_powertools-#{js_hash}.js"
  end

  test "valid asset routes serve immutable css and javascript", %{conn: conn} do
    assert_assets_module_loaded!()

    css_path = apply(ObanPowertools.Web.Assets, :path, [:css])
    js_path = apply(ObanPowertools.Web.Assets, :path, [:js])

    css_conn = get(conn, css_path)
    assert response(css_conn, 200) =~ ".obpt-root"
    assert get_resp_header(css_conn, "cache-control") == ["public, max-age=31536000, immutable"]
    assert css_conn.resp_headers |> List.keyfind("content-type", 0) |> elem(1) =~ "text/css"

    js_conn = get(conn, js_path)
    assert response(js_conn, 200) =~ "ObanPowertoolsTheme"
    assert get_resp_header(js_conn, "cache-control") == ["public, max-age=31536000, immutable"]
    assert js_conn.resp_headers |> List.keyfind("content-type", 0) |> elem(1) =~ "javascript"
  end

  test "mismatched asset hashes return 404", %{conn: conn} do
    assert_assets_module_loaded!()

    css_conn = get(conn, "/ops/jobs/_assets/oban_powertools-00000000000000000000000000000000.css")
    assert response(css_conn, 404) == "not found"

    js_conn = get(conn, "/ops/jobs/_assets/oban_powertools-00000000000000000000000000000000.js")
    assert response(js_conn, 404) == "not found"
  end

  test "compiled assets are byte stable across repeated build task runs" do
    assert Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Assets.Build),
           "expected mix oban_powertools.assets.build task to be loadable"

    checked_in = static_sha256s()

    Mix.Task.rerun("oban_powertools.assets.build", [])
    first_build = static_sha256s()

    Mix.Task.rerun("oban_powertools.assets.build", [])
    second_build = static_sha256s()

    assert first_build == checked_in
    assert second_build == first_build
  end

  test "checked-in compiled assets include component and production page CSS plus scoped browser behavior" do
    assert Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Assets.Build),
           "expected mix oban_powertools.assets.build task to be loadable"

    css = File.read!(@css_static)
    js = File.read!(@js_static)

    for selector <- [
          ".obpt-root .obpt-icon-button",
          ".obpt-root .obpt-link",
          ".obpt-root .obpt-status-pill",
          ".obpt-root .obpt-surface",
          ".obpt-root .obpt-spinner",
          ".obpt-root .obpt-tooltip",
          ".obpt-root .obpt-kbd",
          ".obpt-root .obpt-stat",
          ".obpt-root .obpt-sr-only",
          ".obpt-root .obpt-app-shell",
          ".obpt-root .obpt-app-shell__nav-toggle",
          ".obpt-root .obpt-primary-nav__link[aria-current=\"page\"]",
          ".obpt-root .obpt-theme-choice[aria-pressed=\"true\"]",
          ".obpt-root .obpt-app-shell[data-obpt-nav-state=\"closed\"] > .obpt-app-shell__header > .obpt-primary-nav",
          ".obpt-root [data-obpt-section=\"app-shell\"] .obpt-showcase-story-grid",
          ".obpt-root .obpt-breadcrumb [aria-current=\"page\"]",
          ".obpt-root .obpt-data-table",
          ".obpt-root .obpt-data-table__header button:focus-visible",
          ".obpt-root .obpt-data-table__mobile-label",
          ".obpt-root .obpt-data-table__cell[data-obpt-mobile-label=\"Selection\"] .obpt-choice",
          ".obpt-root .obpt-data-state",
          ".obpt-root .obpt-description-list",
          ".obpt-root .obpt-machine-value__summary:focus-visible",
          ".obpt-root .obpt-timeline__item",
          ".obpt-root .obpt-progress progress",
          ".obpt-root .obpt-metric-card",
          ".obpt-root .obpt-code-block__region:focus-visible",
          ".obpt-root .obpt-args-viewer__unavailable",
          ".obpt-root .obpt-redacted-value__icon",
          ".obpt-root .obpt-empty-state",
          ".obpt-root .obpt-toast[data-obpt-tone=\"danger\"]",
          ".obpt-root .obpt-toast__dismiss:focus-visible",
          ".obpt-root .obpt-flash-group",
          ".obpt-root .obpt-attention-card",
          ".obpt-root .obpt-why-blocked",
          ".obpt-root .obpt-audit-entry",
          ".obpt-root .obpt-filter-bar",
          ".obpt-root .obpt-filter-bar__toggle[aria-expanded=\"true\"]",
          ".obpt-root .obpt-filter-bar__active-filter .obpt-link",
          ".obpt-root .obpt-confirm-action",
          ".obpt-root .obpt-confirm-action__busy",
          ".obpt-root .obpt-confirm-action__result-row[data-obpt-result=\"failed\"]",
          ".obpt-root[data-obpt-motion=\"reduce\"] .obpt-confirm-action__dialog",
          ".obpt-root .obpt-detail-surface",
          ".obpt-root .obpt-detail-surface[data-obpt-detail-mode=\"drawer\"]::backdrop",
          ".obpt-root[data-obpt-motion=\"reduce\"] .obpt-detail-surface",
          ".obpt-root .obpt-page",
          ".obpt-root .obpt-page__header",
          ".obpt-root .obpt-page__title",
          ".obpt-root .obpt-page__master-detail",
          ".obpt-root .obpt-page__pagination",
          ".obpt-root .obpt-page__long-value",
          ".obpt-root .obpt-overview__current-grid",
          ".obpt-root .obpt-overview__exemplars",
          ".obpt-root .obpt-page-story",
          ".obpt-root #overview-page",
          ".obpt-root .obpt-cron-page",
          ".obpt-root .obpt-limiters-page",
          ".obpt-root .obpt-audit-page",
          ".obpt-root .obpt-jobs-page",
          ".obpt-root .obpt-jobs-page__states",
          ".obpt-root .obpt-jobs-page__selection-summary",
          ".obpt-root .obpt-jobs-page__selection-actions",
          ".obpt-root .obpt-jobs-page__pagination",
          ".obpt-root .obpt-forensics-page",
          ".obpt-root .obpt-forensics-results",
          ".obpt-root .obpt-forensics-guidance",
          ".obpt-root .obpt-forensics-guidance-disclosure",
          ".obpt-root .obpt-forensics-sources",
          ".obpt-root #overview-title",
          ".obpt-root #cron-page-title",
          ".obpt-root #limiters-page-title",
          ".obpt-root #audit-page-title",
          ".obpt-root #jobs-page-title",
          ".obpt-root #job-detail-title",
          ".obpt-root #jobs-results",
          ".obpt-root #jobs-results-region",
          ".obpt-root #jobs-results-region:focus-visible",
          ".obpt-root #jobs-results-region > #jobs-results > table",
          ".obpt-root #jobs-page:not(:has(> #job-quick-review)) > #jobs-results-region",
          ".obpt-root #job-quick-review",
          ".obpt-root .obpt-forensics-page > .obpt-page-header > h1",
          ".obpt-root[data-obpt-motion=\"reduce\"] .obpt-page"
        ] do
      assert css =~ selector, "expected compiled CSS to include #{selector}"
    end

    assert css =~ "@keyframes obpt-spinner-spin"
    assert css =~ "--obpt-font-size-page-title: 1.75rem"
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ "@media (min-width: 64rem)"
    assert css =~ "@media (max-width: 24rem)"
    assert js =~ "[data-obpt-tooltip-trigger]"
    assert js =~ "data-obpt-tooltip-open"
    assert js =~ "data-obpt-tooltip-dismissed"
    assert js =~ "[data-obpt-app-shell]"
    assert js =~ "[data-obpt-nav-toggle]"
    assert js =~ "[data-obpt-primary-nav]"
    assert js =~ "data-obpt-nav-state"
    assert js =~ "aria-expanded"
    assert js =~ "focusInsideNavDisclosure"
    assert js =~ "[data-obpt-filter-bar]"
    assert js =~ "[data-obpt-filter-toggle]"
    assert js =~ "[data-obpt-filter-fields]"
    assert js =~ "data-obpt-filter-state"
    assert js =~ "setFilterState"
    assert js =~ "syncFilterDisclosures"
    assert js =~ "toggleAttribute(\"hidden\", collapsedAtNarrowWidth)"
    assert js =~ "toggleAttribute(\"inert\", collapsedAtNarrowWidth)"
    assert js =~ "filterBarForElement"
    assert js =~ "root.contains(filterBar)"
    assert js =~ "[data-obpt-detail-surface]"
    assert js =~ "[data-obpt-detail-body]"
    assert js =~ "[data-obpt-detail-close]"
    assert js =~ "[data-obpt-focus-fallback]"
    assert js =~ "(min-width: 64rem)"
    assert js =~ "DETAIL_WIDE_QUERY"
    assert js =~ "effectiveDetailMode"
    assert js =~ "syncDetailSurface"
    assert js =~ "syncDetailSurfaces"
    assert js =~ "restoreOwnedFocus"
    assert js =~ "pendingControlledInvokers"
    assert js =~ "ownedInvokers"
    assert js =~ "new WeakMap()"
    assert js =~ "surface.close()"
    assert js =~ "surface.show()"
    assert js =~ "surface.showModal()"
    assert js =~ "surface.setAttribute(\"aria-modal\", \"true\")"
    assert js =~ "surface.removeAttribute(\"aria-modal\")"
    assert js =~ "body.setAttribute(\"tabindex\", \"0\")"
    assert js =~ "body.removeAttribute(\"tabindex\")"
    assert js =~ "surface.addEventListener(\"cancel\""
    assert js =~ "surface.addEventListener(\"close\""
    assert js =~ "requestParentDetailClose"
    assert js =~ "restoreRemovedOwners"
    assert js =~ "attributeFilter"
    assert js =~ "MutationObserver"
    assert js =~ "addedNodes"
    assert js =~ "Escape"
    assert js =~ "DOMContentLoaded"
    assert js =~ "window.ObanPowertoolsTheme"
    refute js =~ "document.documentElement"
    refute js =~ ".classList"
    refute js =~ "eval("
    refute js =~ "new Function"
    refute js =~ "phx-hook"
    refute js =~ "LiveSocket"
    refute js =~ "sessionStorage"
    refute js =~ "console."
    refute js =~ "oban_powertools:filters"
    refute js =~ "filter_values"
    refute js =~ "result_data"
    refute js =~ "preview_data"
    refute js =~ "dialogPolyfill"
    refute js =~ "oban_powertools:detail"
    refute js =~ "detail_reason"
    refute js =~ "detail_token"
    refute js =~ "detail_result"
  end

  test "checked-in CSS and JavaScript are byte-equal to their normalized sources" do
    assert File.read!(@css_static) == normalized_source("assets/oban_powertools/tokens.css")
    assert File.read!(@js_static) == normalized_source("assets/oban_powertools/theme.js")
  end

  test "hex package contract includes priv static assets" do
    package = ObanPowertools.MixProject.project() |> Keyword.fetch!(:package)
    files = Keyword.fetch!(package, :files)

    assert "priv" in files, "expected package files to include priv for compiled assets"
  end

  defp assert_assets_module_loaded! do
    assert Code.ensure_loaded?(ObanPowertools.Web.Assets),
           "expected ObanPowertools.Web.Assets to be defined"
  end

  defp static_sha256s do
    for path <- [@css_static, @js_static], into: %{} do
      assert File.exists?(path), "expected #{path} to exist after asset build"
      {path, :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)}
    end
  end

  defp normalized_source(path) do
    path
    |> File.read!()
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> String.trim_trailing()
    |> Kernel.<>("\n")
  end
end
