defmodule ObanPowertools.Web.Components.AppShellTest do
  use ExUnit.Case, async: true

  @app_shell ObanPowertools.Web.Components.AppShell
  @source_path "lib/oban_powertools/web/components/app_shell.ex"
  @components ~w[app_shell nav_items breadcrumb_items theme_choices actor_label]a
  @nav_items [
    {"Overview", "/ops/jobs"},
    {"Jobs", "/ops/jobs/jobs"},
    {"Batches", "/ops/jobs/batches"},
    {"Workflows", "/ops/jobs/workflows"},
    {"Cron", "/ops/jobs/cron"},
    {"Limiters", "/ops/jobs/limiters"},
    {"Lifeline", "/ops/jobs/lifeline"},
    {"Audit", "/ops/jobs/audit"},
    {"Forensics", "/ops/jobs/forensics"}
  ]
  @theme_choices ["System", "Light", "Dark", "High contrast"]
  @hostile ~s|<script>alert("shell")</script>|

  describe "NAV-01 AppShell exports" do
    test "exports the shell component and closed helper contract" do
      assert Code.ensure_loaded?(@app_shell),
             "NAV-01 requires #{@app_shell} to exist before shell integration lands"

      for component <- @components do
        assert function_exported?(@app_shell, component, 1),
               "NAV-01 requires #{inspect(@app_shell)}.#{component}/1"
      end

      assert function_exported?(@app_shell, :nav_items, 0),
             "NAV-03 requires #{inspect(@app_shell)}.nav_items/0"
    end
  end

  describe "NAV-01/NAV-02/NAV-03 render contract" do
    test "renders the header, deterministic nav, theme choices, actor, and content shell" do
      html = render_shell()

      assert html =~ ~s(data-obpt-app-shell)
      assert html =~ ~s(class="obpt-app-shell)
      assert html =~ "Oban Powertools"
      assert html =~ ~s(id="obpt-main")
      assert html =~ ~s(tabindex="-1")
      assert html =~ "Main content kept page-owned"

      assert html =~ ~s(button)
      assert html =~ ~s(data-obpt-nav-toggle)
      assert html =~ ~s(aria-controls="obpt-primary-nav")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ "Navigation"
      assert html =~ ~s(id="obpt-primary-nav")
      assert html =~ ~s(data-obpt-primary-nav)
      assert html =~ ~s(data-obpt-nav-state="closed")

      assert count(html, ~s(data-obpt-nav-item)) == 9
      assert_in_order(html, Enum.map(@nav_items, &elem(&1, 0)))

      for {label, path} <- @nav_items do
        assert html =~ label
        assert html =~ ~s(href="#{path}")
      end

      refute html =~ ~s(/ops/jobs/oban)

      for choice <- @theme_choices do
        assert html =~ ~s(data-obpt-theme-choice)
        assert html =~ choice
      end

      assert html =~ ~s(class="obpt-theme-choices" role="group" aria-label="Theme choices")
      assert html =~ "Actor: ops@example.test"
    end

    test "marks the active route with programmatic and non-color state" do
      html = render_shell(current_path: "/ops/jobs/jobs/123")

      assert html =~ ~r/<a[^>]+href="\/ops\/jobs\/jobs"[^>]+aria-current="page"/s

      assert html =~
               ~r/(data-obpt-current="true"|data-obpt-active="true"|obpt-primary-nav__link--current|is-current)/,
             "NAV-03/A11Y-02 require a non-color active marker in addition to aria-current"

      assert html =~ ~s(aria-label="Breadcrumb")
      assert html =~ ~s(data-obpt-breadcrumb="root")
      assert html =~ ~s(data-obpt-breadcrumb="current")
      assert html =~ ~r/data-obpt-breadcrumb="root"[^>]*>Overview/s
      assert html =~ ~r/data-obpt-breadcrumb="current"[^>]+aria-current="page"[^>]*>Job detail/s
    end

    test "supports deterministic server-rendered open nav state for stories" do
      html = render_shell(nav_state: :open)

      assert html =~ ~s(data-obpt-nav-state="open")
      assert html =~ ~s(aria-expanded="true")
    end

    test "keeps production ids by default and supports scoped ids for repeated showcase stories" do
      default_html = render_shell()
      scoped_html = render_shell(id_scope: "shell-nine-surface-nav")

      assert default_html =~ ~s(aria-controls="obpt-primary-nav")
      assert default_html =~ ~s(id="obpt-primary-nav")
      assert default_html =~ ~s(id="obpt-main")

      assert scoped_html =~ ~s(aria-controls="obpt-primary-nav-shell-nine-surface-nav")
      assert scoped_html =~ ~s(id="obpt-primary-nav-shell-nine-surface-nav")
      assert scoped_html =~ ~s(href="#obpt-main-shell-nine-surface-nav")
      assert scoped_html =~ ~s(id="obpt-main-shell-nine-surface-nav")
    end

    test "falls back when actor context is unavailable" do
      html = render_shell(current_actor: nil)

      assert html =~ "Actor context unavailable"
    end
  end

  describe "security and caller attribute contract" do
    test "filters caller visual attrs while preserving safe semantic attrs" do
      html =
        render_shell(
          rest: %{
            "id" => "safe-shell",
            "data-testid" => "app-shell-contract",
            "data-obpt-effective-theme" => "dark",
            "data-obpt-motion" => "reduce",
            "data-obpt-theme" => "dark",
            "class" => "host-owned-class",
            "style" => "color: red"
          }
        )

      assert html =~ ~s(id="safe-shell")
      assert html =~ ~s(data-testid="app-shell-contract")
      refute html =~ ~s(data-obpt-effective-theme="dark")
      refute html =~ ~s(data-obpt-motion="reduce")
      refute html =~ ~s(data-obpt-theme="dark")
      refute html =~ "host-owned-class"
      refute html =~ "color: red"
    end

    test "escapes hostile actor and context copy" do
      html =
        render_shell(
          current_actor: %{
            id: "ops-1",
            audit_principal: %{id: "ops-1", type: :user, label: @hostile}
          },
          context_label: @hostile
        )

      assert html =~ "&lt;script&gt;alert(&quot;shell&quot;)&lt;/script&gt;"
      refute html =~ @hostile
    end

    test "does not let callers replace the closed nine-surface navigation" do
      html =
        render_shell(
          nav_items: [
            %{key: "injected", label: "Injected surface", path: "/ops/jobs/injected"}
          ]
        )

      assert count(html, ~s(data-obpt-nav-item)) == 9
      refute html =~ "Injected surface"
      refute html =~ "/ops/jobs/injected"
    end
  end

  describe "helper contracts" do
    test "nav_items/0 returns exactly the closed nine-surface native nav model" do
      assert Code.ensure_loaded?(@app_shell),
             "NAV-03 requires #{@app_shell} to define nav_items/0"

      items = @app_shell.nav_items()

      assert Enum.map(items, &field(&1, :label)) == Enum.map(@nav_items, &elem(&1, 0))
      assert Enum.map(items, &field(&1, :path)) == Enum.map(@nav_items, &elem(&1, 1))
      refute Enum.any?(items, &(field(&1, :path) == "/ops/jobs/oban"))
    end

    test "breadcrumb_items/1 derives root and detail fallbacks from current path" do
      assert Code.ensure_loaded?(@app_shell),
             "NAV-03 requires #{@app_shell} to define breadcrumb_items/1"

      assert breadcrumb_labels("/ops/jobs/jobs/123") == ["Overview", "Jobs", "Job detail"]

      assert breadcrumb_labels("/ops/jobs/batches/batch-1") == [
               "Overview",
               "Batches",
               "Batch detail"
             ]

      assert breadcrumb_labels("/ops/jobs/workflows/workflow-1") == [
               "Overview",
               "Workflows",
               "Workflow detail"
             ]
    end

    test "theme_choices/0 and actor_label/1 pin UI-SPEC copy" do
      assert Code.ensure_loaded?(@app_shell),
             "NAV-01 requires #{@app_shell} to define theme_choices/0 and actor_label/1"

      assert @app_shell.theme_choices() |> Enum.map(&field(&1, :label)) == @theme_choices

      assert @app_shell.actor_label(%{
               id: "ops-1",
               audit_principal: %{id: "ops-1", type: :user, label: "ops@example.test"}
             }) == "Actor: ops@example.test"

      assert @app_shell.actor_label(nil) == "Actor context unavailable"
    end
  end

  describe "source contract" do
    test "source keeps theme, spacing, nav, and escape-hatch ownership in the shell component" do
      source = read_source!()

      assert source =~ "use Phoenix.Component"
      assert source =~ "visual_safe_rest"
      assert source =~ ~r/attr\(?\s*:rest,\s*:global/
      assert source =~ ~r/slot\(?\s*:inner_block/
      assert source =~ "data-obpt-app-shell"
      assert source =~ "data-obpt-nav-toggle"
      assert source =~ "data-obpt-primary-nav"
      assert source =~ "data-obpt-nav-state"
      assert source =~ "data-obpt-nav-item"
      assert source =~ "data-obpt-breadcrumb"

      refute source =~ ~r/#[0-9a-fA-F]{3,8}/,
             "NAV-01 keeps raw colors in the token layer, not AppShell source"

      refute source =~ ~r/\b\d+(?:\.\d+)?px\b/,
             "NAV-02 keeps raw pixel spacing out of AppShell source"

      for forbidden <- [":root", "document.documentElement", "<html", "<body", ".dark"] do
        refute source =~ forbidden, "TOKEN-04 forbids host theme mutation: #{forbidden}"
      end

      refute source =~ ~r/attr\(?\s*:nav_items,\s*:list/,
             "NAV-03 keeps the nine-surface primary navigation closed"

      refute source =~ ~s("/ops/jobs/oban")
      refute source =~ ~s('/ops/jobs/oban')
    end
  end

  defp render_shell(overrides \\ []) do
    assert Code.ensure_loaded?(@app_shell),
           "NAV-01 requires #{@app_shell} before rendering app_shell/1"

    assert function_exported?(@app_shell, :app_shell, 1),
           "NAV-01 requires #{@app_shell}.app_shell/1"

    assigns =
      %{
        current_path: "/ops/jobs/jobs",
        current_uri: "http://localhost/ops/jobs/jobs?state=available",
        current_actor: %{
          id: "ops-1",
          audit_principal: %{id: "ops-1", type: :user, label: "ops@example.test"}
        },
        context_label: "Queue pressure nominal",
        nav_state: :closed,
        rest: %{},
        inner_block: slot("Main content kept page-owned")
      }
      |> Map.merge(Map.new(overrides))

    Phoenix.LiveViewTest.__render_component__(
      ObanPowertools.TestEndpoint,
      Function.capture(@app_shell, :app_shell, 1),
      assigns,
      []
    )
  end

  defp breadcrumb_labels(path) do
    path
    |> @app_shell.breadcrumb_items()
    |> Enum.map(&field(&1, :label))
  end

  defp field(map, key) when is_map(map),
    do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp slot(text) do
    [
      %{
        __slot__: :inner_block,
        inner_block: fn _changed, _argument -> Phoenix.HTML.raw(text) end
      }
    ]
  end

  defp read_source! do
    assert File.exists?(@source_path),
           "NAV-01 requires #{@source_path} to define AppShell"

    File.read!(@source_path)
  end

  defp assert_in_order(html, values) do
    {_tail, positions} =
      Enum.reduce(values, {html, []}, fn value, {remaining, positions} ->
        index = String.contains?(remaining, value) && :binary.match(remaining, value)

        assert index != :nomatch,
               "expected #{inspect(value)} after #{inspect(Enum.reverse(positions))}"

        {start, length} = index

        {binary_part(remaining, start + length, byte_size(remaining) - start - length),
         [value | positions]}
      end)

    assert length(positions) == length(values)
  end

  defp count(html, needle), do: length(String.split(html, needle)) - 1
end
