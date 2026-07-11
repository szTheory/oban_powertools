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

  defp allowed_literal_primitive_value?(value) do
    value in @allowed_literal_primitive_values or String.starts_with?(value, "1px solid var(--obpt-")
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
