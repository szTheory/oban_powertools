defmodule ObanPowertools.Web.ThemeTokensTest do
  use ExUnit.Case, async: true

  @tokens_path "assets/oban_powertools/tokens.css"
  @theme_path "assets/oban_powertools/theme.js"

  @primitive_prefixes ~w[
    --obpt-palette-slate-
    --obpt-palette-indigo-
    --obpt-palette-cyan-
    --obpt-palette-emerald-
    --obpt-palette-amber-
    --obpt-palette-red-
  ]

  @semantic_prefixes ~w[
    --obpt-color-accent-
    --obpt-color-info-
    --obpt-color-success-
    --obpt-color-warning-
    --obpt-color-danger-
  ]

  @semantic_roles ~w[
    --obpt-color-surface
    --obpt-color-elevated
    --obpt-color-overlay
    --obpt-color-border
    --obpt-color-border-strong
    --obpt-color-text
    --obpt-color-muted
    --obpt-color-focus
  ]

  @foundation_prefixes ~w[
    --obpt-font-size-
    --obpt-line-height-
    --obpt-font-weight-
    --obpt-space-
    --obpt-radius-
    --obpt-shadow-
    --obpt-motion-duration-
    --obpt-motion-ease-
  ]

  @primitive_classes ~w[
    .obpt-button
    .obpt-icon-button
    .obpt-link
    .obpt-badge
    .obpt-tag
    .obpt-status-pill
    .obpt-surface
    .obpt-card
    .obpt-divider
    .obpt-spinner
    .obpt-skeleton
    .obpt-tooltip
    .obpt-kbd
    .obpt-stat
    .obpt-sr-only
  ]

  @shell_classes ~w[
    .obpt-app-shell
    .obpt-app-shell__skip
    .obpt-app-shell__header
    .obpt-app-shell__brand
    .obpt-app-shell__nav-toggle
    .obpt-primary-nav
    .obpt-primary-nav__list
    .obpt-primary-nav__link
    .obpt-breadcrumb
    .obpt-breadcrumb__list
    .obpt-theme-choices
    .obpt-theme-choice
    .obpt-actor-context
    .obpt-shell-main
  ]

  @data_classes ~w[
    .obpt-data-table
    .obpt-data-table__table
    .obpt-data-table__toolbar
    .obpt-data-table__summary
    .obpt-data-table__header
    .obpt-data-table__row
    .obpt-data-table__cell
    .obpt-data-table__cell-value
    .obpt-data-table__mobile-label
    .obpt-data-table__state-row
    .obpt-data-table__state-cell
    .obpt-data-state
    .obpt-data-state__copy
    .obpt-data-state__heading
    .obpt-data-state__body
    .obpt-description-list
    .obpt-description-list__list
    .obpt-description-list__item
    .obpt-description-list__term
    .obpt-description-list__value
    .obpt-key-value
    .obpt-key-value__term
    .obpt-key-value__value
    .obpt-machine-value
    .obpt-machine-value__details
    .obpt-machine-value__summary
    .obpt-machine-value__full
    .obpt-machine-value__display
    .obpt-timeline
    .obpt-timeline__list
    .obpt-timeline__item
    .obpt-timeline__time
    .obpt-timeline__title
    .obpt-timeline__source
    .obpt-timeline__detail
    .obpt-progress
    .obpt-progress__label
    .obpt-progress__value
    .obpt-progress__count
    .obpt-progress__percent
    .obpt-progress__unavailable
    .obpt-metric-card
    .obpt-metric-card__status
    .obpt-metric-card__action
    .obpt-code-block
    .obpt-code-block__region
    .obpt-code-block__code
    .obpt-args-viewer
    .obpt-args-viewer__context
    .obpt-args-viewer__summary
    .obpt-args-viewer__status
    .obpt-args-viewer__unavailable
    .obpt-redacted-value
    .obpt-redacted-value__icon
    .obpt-redacted-value__copy
    .obpt-empty-state
    .obpt-empty-state__heading
    .obpt-empty-state__body
    .obpt-empty-state__action
    .obpt-toast
    .obpt-toast__icon
    .obpt-toast__content
    .obpt-toast__dismiss
    .obpt-flash-group
  ]

  @proof_seam_classes ~w[
    .obpt-tab
    .obpt-modal
    .obpt-form-label
    .obpt-input
    .obpt-alert
  ]

  @token_backed_primitive_properties ~w[
    animation
    background
    border
    border-block-start
    border-block-start-color
    border-color
    border-radius
    box-shadow
    color
    font-family
    font-size
    font-weight
    gap
    inline-size
    block-size
    line-height
    margin
    max-inline-size
    min-block-size
    min-inline-size
    outline
    outline-offset
    padding
    text-decoration-color
    text-decoration-thickness
    text-underline-offset
    transition
  ]

  @token_backed_shell_properties ~w[
    background
    border
    border-block-end
    border-color
    border-radius
    box-shadow
    color
    font-family
    font-size
    font-weight
    gap
    line-height
    margin
    min-block-size
    outline
    outline-offset
    padding
    text-decoration-color
    transition
  ]

  @allowed_literal_primitive_values ~w[
    0
    none
    transparent
    hidden
  ]

  @forbidden_theme_properties ~w[
    width height min-width max-width min-height max-height
    padding padding-top padding-right padding-bottom padding-left
    margin margin-top margin-right margin-bottom margin-left
    gap row-gap column-gap display position inset top right bottom left
    transform translate scale rotate grid flex flex-basis line-height
    font-size border-radius
  ]

  test "token source exists and declares the Phase 70 primitive and semantic contract" do
    css = read_contract_file!(@tokens_path)
    vars = variables_for(css, ".obpt-root")

    for prefix <- @primitive_prefixes do
      assert has_variable_prefix?(vars, prefix), "missing primitive token category #{prefix}"
    end

    assert Map.has_key?(vars, "--obpt-palette-white")
    assert Map.has_key?(vars, "--obpt-palette-black")

    for role <- @semantic_roles do
      assert Map.has_key?(vars, role), "missing semantic token #{role}"
    end

    for prefix <- @semantic_prefixes do
      assert has_variable_prefix?(vars, prefix),
             "missing semantic status/accent category #{prefix}"
    end

    for prefix <- @foundation_prefixes do
      assert has_variable_prefix?(vars, prefix), "missing foundation token category #{prefix}"
    end

    assert Map.has_key?(vars, "--obpt-font-sans")
    assert Map.has_key?(vars, "--obpt-font-mono")
    assert Map.has_key?(vars, "--obpt-numeric-tabular")
  end

  test "token source is scoped to Powertools and rejects host-root leakage" do
    css = read_contract_file!(@tokens_path)

    assert css =~ ".obpt-root"
    assert css =~ ".obpt-shell"
    assert css =~ ".obpt-tab"
    assert css =~ ".obpt-tab--active"
    assert css =~ ".obpt-badge"
    assert css =~ ".obpt-modal-backdrop"
    assert css =~ ".obpt-modal"

    refute css =~ ~r/(^|})\s*:root\s*[{,]/m
    refute css =~ ~r/(^|})\s*html(\s|\.|#|\[|:|,|\{)/m
    refute css =~ ~r/(^|})\s*body(\s|\.|#|\[|:|,|\{)/m
    refute css =~ ~r/(^|})\s*\.dark(\s|\.|#|\[|:|,|\{)/m
    refute css =~ "document.documentElement"
    refute css =~ "localStorage.theme"
    refute css =~ ~s(localStorage["theme"])
    refute css =~ ~s(localStorage['theme'])
  end

  test "primitive class families are root-scoped, token-backed, and responsive" do
    css = read_contract_file!(@tokens_path)
    primitive_blocks = primitive_blocks(css)

    for class <- @primitive_classes do
      assert css =~ ".obpt-root #{class}", "missing root-scoped primitive selector #{class}"
    end

    for class <- @proof_seam_classes do
      assert css =~ ".obpt-root #{class}", "Phase 71 proof-seam class drifted: #{class}"
    end

    assert css =~ "@media (max-width: 24rem)"
    assert css =~ ".obpt-root .obpt-primitive-matrix"
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ ~s(.obpt-root[data-obpt-motion="reduce"])

    assert primitive_blocks != [], "expected primitive CSS blocks to be present"

    for {selector, body} <- primitive_blocks do
      for part <- selector_parts(selector) do
        assert String.starts_with?(part, ".obpt-root"),
               "primitive selector is not scoped below .obpt-root: #{part}"
      end

      refute body =~ ~r/#[0-9a-fA-F]{3,8}/,
             "primitive selector #{selector} contains a raw color value"

      for {property, value} <- declarations(body),
          primitive_visual_property?(property),
          not allowed_literal_primitive_value?(value) do
        assert String.contains?(value, "var(--obpt-"),
               "primitive selector #{selector} property #{property} is not token-backed: #{value}"
      end
    end
  end

  test "app shell selectors are root-scoped, token-backed, responsive, and stateful" do
    css = read_contract_file!(@tokens_path)
    shell_blocks = shell_blocks(css)

    for class <- @shell_classes do
      assert css =~ ".obpt-root #{class}", "missing root-scoped shell selector #{class}"
    end

    assert css =~ ~s([data-obpt-nav-state="closed"])
    assert css =~ ~s([data-obpt-nav-state="open"])

    assert css =~
             ~s(.obpt-app-shell[data-obpt-nav-state="closed"] > .obpt-app-shell__header > .obpt-primary-nav)

    assert css =~ ~s([data-obpt-section="app-shell"] .obpt-showcase-story-grid)
    assert css =~ "@media (max-width: 48rem)"
    assert css =~ "@media (min-width: 48rem)"

    assert css =~ ~s(.obpt-primary-nav__link[aria-current="page"])
    assert css =~ ~s(.obpt-theme-choice[aria-pressed="true"])
    assert css =~ ~s(.obpt-breadcrumb [aria-current="page"])
    assert css =~ ".obpt-app-shell__nav-toggle:focus-visible"
    assert css =~ ".obpt-primary-nav__link:focus-visible"
    assert css =~ ".obpt-theme-choice:focus-visible"
    assert css =~ ".obpt-breadcrumb a:focus-visible"
    assert css =~ "var(--obpt-color-focus)"
    assert css =~ "var(--obpt-font-weight-semibold)"
    assert css =~ "var(--obpt-color-accent-bg)"
    assert css =~ "var(--obpt-color-accent-border)"

    assert shell_blocks != [], "expected AppShell CSS blocks to be present"

    for {selector, body} <- shell_blocks do
      for part <- selector_parts(selector) do
        assert String.starts_with?(part, ".obpt-root"),
               "shell selector is not scoped below .obpt-root: #{part}"
      end

      refute body =~ ~r/#[0-9a-fA-F]{3,8}/,
             "shell selector #{selector} contains a raw color value"

      for {property, value} <- declarations(body),
          shell_visual_property?(property),
          not allowed_literal_shell_value?(value) do
        assert String.contains?(value, "var(--obpt-"),
               "shell selector #{selector} property #{property} is not token-backed: #{value}"
      end
    end
  end

  test "data table selectors are root-scoped, token-backed, focusable, and reflow one DOM at 24rem" do
    css = read_contract_file!(@tokens_path)
    data_blocks = data_blocks(css)

    for class <- @data_classes do
      assert css =~ ".obpt-root #{class}", "missing root-scoped data selector #{class}"
    end

    assert css =~ "@media (max-width: 24rem)"
    assert css =~ ".obpt-root .obpt-data-table__header button:focus-visible"
    assert css =~ ".obpt-root .obpt-data-table__mobile-label"

    assert css =~
             ~s(.obpt-root .obpt-data-table__cell[data-obpt-mobile-label="Selection"] .obpt-choice)

    assert css =~ "min-block-size: calc(var(--obpt-space-7) - var(--obpt-space-1))"
    assert css =~ "display: table"
    assert css =~ "display: grid"
    assert css =~ "var(--obpt-motion-duration-fast)"
    assert css =~ "var(--obpt-motion-duration-instant)"

    assert data_blocks != [], "expected DataTable CSS blocks to be present"

    for {selector, body} <- data_blocks do
      for part <- selector_parts(selector) do
        assert String.starts_with?(part, ".obpt-root"),
               "data selector is not scoped below .obpt-root: #{part}"
      end

      refute body =~ ~r/#[0-9a-fA-F]{3,8}/,
             "data selector #{selector} contains a raw color value"

      refute body =~ ~r/overflow-x\s*:\s*(auto|scroll)/,
             "ordinary data selector #{selector} introduces horizontal scrolling"

      for {property, value} <- declarations(body),
          data_visual_property?(property),
          not allowed_literal_data_value?(value) do
        assert String.contains?(value, "var(--obpt-"),
               "data selector #{selector} property #{property} is not token-backed: #{value}"
      end
    end
  end

  test "secondary data selectors wrap, preserve native progress, expose focus, and reduce motion" do
    css = read_contract_file!(@tokens_path)

    assert css =~ ".obpt-root .obpt-machine-value__summary:focus-visible"
    assert css =~ ".obpt-root .obpt-toast__dismiss:focus-visible"
    assert css =~ ".obpt-root .obpt-progress progress"
    assert css =~ "accent-color: var(--obpt-color-accent-solid)"
    assert css =~ ".obpt-root .obpt-toast[data-obpt-tone=\"success\"]"
    assert css =~ ".obpt-root .obpt-toast[data-obpt-tone=\"warning\"]"
    assert css =~ ".obpt-root .obpt-toast[data-obpt-tone=\"danger\"]"
    assert css =~ "min-inline-size: calc(var(--obpt-space-7) - var(--obpt-space-1))"
    assert css =~ "min-block-size: calc(var(--obpt-space-7) - var(--obpt-space-1))"
    assert css =~ "font-family: var(--obpt-font-mono)"
    assert css =~ "font-variant-numeric: var(--obpt-numeric-tabular)"
    assert css =~ "@media (max-width: 24rem)"
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ ~s(.obpt-root[data-obpt-motion="reduce"] .obpt-toast__dismiss)

    for {selector, body} <- blocks_for(css, ".obpt-progress") do
      refute body =~ ~r/(animation|transition)\s*:/,
             "progress selector #{selector} must not animate value or layout"

      refute body =~ ~r/overflow-x\s*:\s*(auto|scroll)/,
             "progress selector #{selector} must not introduce horizontal scrolling"
    end
  end

  test "code args and redaction are bounded, token-backed, and use the sole data overflow region" do
    css = read_contract_file!(@tokens_path)
    data_blocks = data_blocks(css)

    assert css =~ ".obpt-root .obpt-code-block"
    assert css =~ ".obpt-root .obpt-code-block__region"
    assert css =~ ".obpt-root .obpt-code-block__code"
    assert css =~ ".obpt-root .obpt-args-viewer"
    assert css =~ ".obpt-root .obpt-redacted-value"
    assert css =~ ".obpt-root .obpt-code-block__region:focus-visible"
    assert css =~ "font-family: var(--obpt-font-mono)"
    assert css =~ "max-width: 100%"
    assert css =~ "max-block-size: calc(var(--obpt-space-7)"
    assert css =~ "overflow: auto"
    assert css =~ "outline: calc(var(--obpt-space-1) / 2) solid var(--obpt-color-focus)"

    overflow_selectors =
      for {selector, body} <- data_blocks,
          body =~ ~r/overflow(?:-x)?\s*:\s*(auto|scroll)/,
          do: selector

    assert overflow_selectors != []

    assert Enum.all?(overflow_selectors, fn selector ->
             String.contains?(selector, ".obpt-code-block__region")
           end),
           "only the bounded code region may scroll internally, got #{inspect(overflow_selectors)}"

    redaction_blocks = blocks_for(css, ".obpt-redacted-value")
    assert redaction_blocks != []

    assert Enum.any?(redaction_blocks, fn {_selector, body} ->
             body =~ "var(--obpt-color-warning-border)" and
               body =~ "var(--obpt-color-warning-bg)" and
               body =~ "var(--obpt-color-warning-fg)"
           end)

    assert Enum.any?(redaction_blocks, fn {selector, body} ->
             String.contains?(selector, ".obpt-redacted-value__icon") and
               body =~ "border:" and body =~ "border-radius:"
           end)

    for {selector, body} <- redaction_blocks do
      refute body =~ ~r/(^|;)\s*content\s*:/,
             "redaction selector #{selector} must not generate hidden content"
    end

    assert css =~ "@media (max-width: 24rem)"
    assert css =~ ~s(.obpt-root[data-obpt-motion="reduce"] .obpt-redacted-value)
    assert css =~ "@media (prefers-reduced-motion: reduce)"
  end

  test "theme selector blocks only remap semantic color/focus variables" do
    css = read_contract_file!(@tokens_path)
    blocks = theme_blocks(css)

    assert blocks != [], "expected theme selector blocks for light, dark, and high contrast"

    for {selector, body} <- blocks do
      declarations = declarations(body)

      for {property, _value} <- declarations do
        cond do
          property == "color-scheme" ->
            :ok

          String.starts_with?(property, "--obpt-color-") ->
            :ok

          true ->
            flunk("theme selector #{selector} redefines non-color property #{property}")
        end

        refute property in @forbidden_theme_properties,
               "theme selector #{selector} redefines layout-affecting property #{property}"

        refute String.starts_with?(property, "--obpt-space-")
        refute String.starts_with?(property, "--obpt-font-size-")
        refute String.starts_with?(property, "--obpt-line-height-")
        refute String.starts_with?(property, "--obpt-radius-")
      end
    end
  end

  test "representative semantic color pairs satisfy contrast floors" do
    css = read_contract_file!(@tokens_path)

    light = merged_variables(css, ".obpt-root[data-obpt-effective-theme=\"light\"]")
    dark = merged_variables(css, ".obpt-root[data-obpt-effective-theme=\"dark\"]")
    high = merged_variables(css, ".obpt-root[data-obpt-effective-theme=\"high-contrast\"]")

    for {name, vars} <- [{"light", light}, {"dark", dark}, {"high-contrast", high}] do
      assert contrast(vars, "--obpt-color-text", "--obpt-color-surface") >= 7.0,
             "#{name} body text contrast is below 7.0"

      assert contrast(vars, "--obpt-color-muted", "--obpt-color-surface") >= 4.5,
             "#{name} muted text contrast is below 4.5"

      assert contrast(vars, "--obpt-color-border-strong", "--obpt-color-surface") >= 3.0,
             "#{name} strong border contrast is below 3.0"

      assert contrast(vars, "--obpt-color-focus", "--obpt-color-surface") >= 3.0,
             "#{name} focus contrast is below 3.0"
    end
  end

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

  test "theme controller is root scoped, system-first, and namespaced" do
    js = read_contract_file!(@theme_path)

    assert js =~ "window.ObanPowertoolsTheme"
    assert js =~ "oban_powertools:theme"
    assert js =~ "data-obpt-theme"
    assert js =~ "data-obpt-effective-theme"
    assert js =~ "data-obpt-motion"
    assert js =~ "prefers-color-scheme"
    assert js =~ "prefers-contrast"
    assert js =~ "prefers-reduced-motion"
    assert js =~ "system"
    assert js =~ "light"
    assert js =~ "dark"
    assert js =~ "high-contrast"
    assert js =~ "[data-obpt-tooltip]"
    assert js =~ "[data-obpt-tooltip-trigger]"
    assert js =~ "data-obpt-tooltip-open"
    assert js =~ "data-obpt-tooltip-dismissed"
    assert js =~ "[data-obpt-app-shell]"
    assert js =~ "[data-obpt-nav-toggle]"
    assert js =~ "[data-obpt-primary-nav]"
    assert js =~ "data-obpt-nav-state"
    assert js =~ "aria-expanded"
    assert js =~ "Escape"

    refute js =~ "document.documentElement"
    refute js =~ ".classList"
    refute js =~ "oban:theme"
    refute js =~ "localStorage.theme"
    refute js =~ ~s(localStorage["theme"])
    refute js =~ ~s(localStorage['theme'])
  end

  defp read_contract_file!(path) do
    assert File.exists?(path),
           "expected #{path} to exist so Phase 71 token/theme contract can be validated"

    File.read!(path)
  end

  defp variables_for(css, selector_fragment) do
    css
    |> blocks_for(selector_fragment)
    |> Enum.flat_map(fn {_selector, body} -> declarations(body) end)
    |> Enum.filter(fn {property, _value} -> String.starts_with?(property, "--obpt-") end)
    |> Map.new()
  end

  defp merged_variables(css, selector_fragment) do
    Map.merge(variables_for(css, ".obpt-root"), variables_for(css, selector_fragment))
  end

  defp blocks_for(css, selector_fragment) do
    Regex.scan(~r/([^{}]+)\{([^{}]+)\}/m, css, capture: :all_but_first)
    |> Enum.map(fn [selector, body] -> {String.trim(selector), body} end)
    |> Enum.filter(fn {selector, _body} -> String.contains?(selector, selector_fragment) end)
  end

  defp primitive_blocks(css) do
    Regex.scan(~r/([^{}]+)\{([^{}]+)\}/m, css, capture: :all_but_first)
    |> Enum.map(fn [selector, body] -> {String.trim(selector), body} end)
    |> Enum.filter(fn {selector, _body} ->
      Enum.any?(@primitive_classes, &String.contains?(selector, &1))
    end)
  end

  defp shell_blocks(css) do
    Regex.scan(~r/([^{}]+)\{([^{}]+)\}/m, css, capture: :all_but_first)
    |> Enum.map(fn [selector, body] -> {String.trim(selector), body} end)
    |> Enum.filter(fn {selector, _body} ->
      Enum.any?(@shell_classes, &String.contains?(selector, &1))
    end)
  end

  defp data_blocks(css) do
    Regex.scan(~r/([^{}]+)\{([^{}]+)\}/m, css, capture: :all_but_first)
    |> Enum.map(fn [selector, body] -> {String.trim(selector), body} end)
    |> Enum.filter(fn {selector, _body} ->
      Enum.any?(@data_classes, &String.contains?(selector, &1))
    end)
  end

  defp selector_parts(selector) do
    selector
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp theme_blocks(css) do
    css
    |> blocks_for("data-obpt-")
    |> Enum.filter(fn {selector, _body} ->
      String.contains?(selector, "data-obpt-theme") or
        String.contains?(selector, "data-obpt-effective-theme")
    end)
  end

  defp declarations(body) do
    Regex.scan(~r/([A-Za-z0-9_-]+|--obpt-[A-Za-z0-9_-]+)\s*:\s*([^;]+);/, body)
    |> Enum.map(fn [_match, property, value] -> {String.trim(property), String.trim(value)} end)
  end

  defp has_variable_prefix?(vars, prefix) do
    vars |> Map.keys() |> Enum.any?(&String.starts_with?(&1, prefix))
  end

  defp primitive_visual_property?(property) do
    property in @token_backed_primitive_properties or String.starts_with?(property, "--obpt-")
  end

  defp shell_visual_property?(property) do
    property in @token_backed_shell_properties or String.starts_with?(property, "--obpt-")
  end

  defp data_visual_property?(property) do
    property in ~w[
      background background-color border border-block-end border-block-start border-color
      border-radius box-shadow color font-family font-size font-weight gap line-height
      margin min-block-size min-inline-size outline outline-offset padding transition
      transition-duration
    ]
  end

  defp allowed_literal_data_value?(value) do
    value in ~w[0 inherit none transparent] or String.starts_with?(value, "1px solid var(--obpt-")
  end

  defp allowed_literal_primitive_value?(value) do
    value in @allowed_literal_primitive_values or
      String.starts_with?(value, "1px solid var(--obpt-")
  end

  defp allowed_literal_shell_value?(value) do
    value in @allowed_literal_primitive_values or
      String.starts_with?(value, "1px solid var(--obpt-")
  end

  defp contrast(vars, foreground, background) do
    fg = resolve_hex!(vars, foreground)
    bg = resolve_hex!(vars, background)
    contrast_ratio(fg, bg)
  end

  defp resolve_hex!(vars, name, seen \\ MapSet.new()) do
    value = Map.fetch!(vars, name)

    cond do
      value =~ ~r/^#[0-9a-fA-F]{6}$/ ->
        value

      match = Regex.run(~r/^var\((--obpt-[A-Za-z0-9_-]+)\)$/, value) ->
        [_all, next] = match

        if MapSet.member?(seen, next) do
          flunk("cyclic CSS variable reference while resolving #{name}")
        else
          resolve_hex!(vars, next, MapSet.put(seen, next))
        end

      true ->
        flunk("expected #{name} to resolve to a hex color, got #{inspect(value)}")
    end
  end

  defp contrast_ratio(foreground, background) do
    [l1, l2] =
      [relative_luminance(foreground), relative_luminance(background)]
      |> Enum.sort(:desc)

    Float.round((l1 + 0.05) / (l2 + 0.05), 2)
  end

  defp relative_luminance("#" <> hex) do
    [r, g, b] =
      hex
      |> String.downcase()
      |> String.graphemes()
      |> Enum.chunk_every(2)
      |> Enum.map(fn pair -> pair |> Enum.join() |> String.to_integer(16) |> Kernel./(255) end)
      |> Enum.map(&linear_channel/1)

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp linear_channel(value) when value <= 0.03928, do: value / 12.92
  defp linear_channel(value), do: :math.pow((value + 0.055) / 1.055, 2.4)
end
