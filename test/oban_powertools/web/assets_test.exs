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

    Mix.Task.rerun("oban_powertools.assets.build", [])
    first = static_sha256s()

    Mix.Task.rerun("oban_powertools.assets.build", [])
    second = static_sha256s()

    assert first == second
  end

  test "compiled assets include primitive and shell CSS plus scoped browser behavior" do
    assert Code.ensure_loaded?(Mix.Tasks.ObanPowertools.Assets.Build),
           "expected mix oban_powertools.assets.build task to be loadable"

    Mix.Task.rerun("oban_powertools.assets.build", [])

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
          ".obpt-root .obpt-breadcrumb [aria-current=\"page\"]"
        ] do
      assert css =~ selector, "expected compiled CSS to include #{selector}"
    end

    assert css =~ "@keyframes obpt-spinner-spin"
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert js =~ "[data-obpt-tooltip-trigger]"
    assert js =~ "data-obpt-tooltip-open"
    assert js =~ "data-obpt-tooltip-dismissed"
    assert js =~ "[data-obpt-app-shell]"
    assert js =~ "[data-obpt-nav-toggle]"
    assert js =~ "[data-obpt-primary-nav]"
    assert js =~ "data-obpt-nav-state"
    assert js =~ "aria-expanded"
    assert js =~ "focusInsideNavDisclosure"
    assert js =~ "Escape"
    assert js =~ "window.ObanPowertoolsTheme"
    refute js =~ "document.documentElement"
    refute js =~ ".classList"
    refute js =~ "eval("
    refute js =~ "new Function"
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
end
