defmodule ObanPowertools.Web.Components.PrimitivesTest do
  use ExUnit.Case, async: true

  @primitive_module ObanPowertools.Web.Components.Primitives
  @primitive_source "lib/oban_powertools/web/components/primitives.ex"

  @components ~w[
    button
    icon_button
    link
    badge
    tag
    status_pill
    surface
    card
    divider
    spinner
    skeleton
    tooltip
    kbd
    stat
  ]a

  @action_attrs ~w[
    phx-click
    phx-submit
    phx-change
    phx-keydown
    phx-keyup
    phx-window-keydown
    phx-window-keyup
    phx-value-id
  ]

  describe "COMP-01 primitive exports" do
    test "all primitives are implemented as function components" do
      assert Code.ensure_loaded?(@primitive_module),
             "D-01/COMP-01 require #{@primitive_module} to exist"

      for component <- @components do
        assert function_exported?(@primitive_module, component, 1),
               "COMP-01 requires #{inspect(@primitive_module)}.#{component}/1"
      end
    end
  end

  describe "button/1" do
    test "renders semantic buttons with closed variants and native disabled state" do
      html =
        render_primitive(:button,
          variant: :primary,
          inner_block: slot("Retry job")
        )

      assert html =~ "<button"
      assert html =~ "Retry job"
      assert html =~ ~s(type="button")
      assert html =~ ~s(class="obpt-button obpt-button--primary obpt-primitive-button")
      assert html =~ ~s(data-obpt-variant="primary")

      disabled_html =
        render_primitive(:button,
          disabled: true,
          inner_block: slot("Cancel job")
        )

      assert_attr(disabled_html, "disabled")
      refute disabled_html =~ ~s(aria-disabled="true")

      assert_raise ArgumentError, ~r/unsupported button variant/i, fn ->
        render_primitive(:button, variant: :rainbow, inner_block: slot("Unsafe"))
      end
    end

    test "disabled-with-reason buttons stay described and suppress action attrs" do
      html =
        render_primitive(:button,
          disabled: true,
          disabled_reason: "Requires operator role",
          type: "submit",
          rest: %{
            "id" => "cancel-job",
            "phx-click" => "cancel",
            "phx-value-id" => "123",
            "aria-label" => "Cancel selected job",
            "data-testid" => "cancel-action",
            "form" => "job-actions",
            "name" => "action",
            "value" => "cancel",
            "class" => "host-visual-class",
            "style" => "color: red"
          },
          inner_block: slot("Cancel job")
        )

      assert html =~ ~s(id="cancel-job")
      assert html =~ ~s(type="button")
      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(aria-describedby="cancel-job-disabled-reason")
      assert html =~ ~s(id="cancel-job-disabled-reason")
      assert html =~ "Requires operator role"
      assert html =~ ~s(aria-label="Cancel selected job")
      assert html =~ ~s(data-testid="cancel-action")
      assert html =~ ~s(form="job-actions")
      assert html =~ ~s(name="action")
      assert html =~ ~s(value="cancel")
      refute_attr(html, "disabled")
      refute html =~ "host-visual-class"
      refute html =~ "color: red"

      for attr <- @action_attrs do
        refute_attr(html, attr)
      end
    end

    test "active buttons preserve caller-owned non-visual and LiveView attrs" do
      html =
        render_primitive(:button,
          rest: %{
            "id" => "retry-job",
            "phx-click" => "retry",
            "phx-value-id" => "123",
            "aria-controls" => "retry-panel",
            "data-testid" => "retry-action",
            "form" => "job-actions",
            "class" => "host-visual-class",
            "style" => "border: 999px solid red"
          },
          inner_block: slot("Retry job")
        )

      assert html =~ ~s(id="retry-job")
      assert html =~ ~s(phx-click="retry")
      assert html =~ ~s(phx-value-id="123")
      assert html =~ ~s(aria-controls="retry-panel")
      assert html =~ ~s(data-testid="retry-action")
      assert html =~ ~s(form="job-actions")
      refute html =~ "host-visual-class"
      refute html =~ "999px"
    end
  end

  describe "icon_button/1" do
    test "requires a non-empty label and hides decorative icon content" do
      assert_raise ArgumentError, ~r/icon_button label/i, fn ->
        render_primitive(:icon_button, label: "", inner_block: slot("!"))
      end

      html =
        render_primitive(:icon_button,
          label: "Retry job",
          tooltip: "Retry the selected job",
          inner_block: slot("↻")
        )

      assert html =~ "<button"
      assert html =~ ~s(aria-label="Retry job")
      assert html =~ ~s(data-obpt-tooltip-text="Retry the selected job")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "↻"
      refute html =~ ~s(aria-label="Retry the selected job")
    end
  end

  describe "link/1" do
    test "renders navigation affordances only" do
      href_html = render_primitive(:link, href: "/ops/jobs", inner_block: slot("Jobs"))

      patch_html =
        render_primitive(:link,
          patch: "/ops/jobs?state=retryable",
          inner_block: slot("Retryable")
        )

      navigate_html =
        render_primitive(:link, navigate: "/ops/jobs/audit", inner_block: slot("Audit log"))

      assert href_html =~ ~s(href="/ops/jobs")
      assert patch_html =~ ~s(data-phx-link="patch")
      assert navigate_html =~ ~s(data-phx-link="redirect")

      for html <- [href_html, patch_html, navigate_html] do
        assert html =~ ~s(class="obpt-link")
        refute_attr(html, "phx-click")
      end

      assert_raise ArgumentError, ~r/link requires href, patch, or navigate/i, fn ->
        render_primitive(:link, rest: %{"phx-click" => "mutate"}, inner_block: slot("Mutate"))
      end
    end

    test "rejects executable or protocol-relative href schemes" do
      for unsafe_href <- [
            "javascript:alert(1)",
            "data:text/html,<script>alert(1)</script>",
            "//evil.example"
          ] do
        assert_raise ArgumentError, ~r/unsupported link href scheme/i, fn ->
          render_primitive(:link, href: unsafe_href, inner_block: slot("Unsafe"))
        end
      end
    end
  end

  describe "metadata primitives" do
    test "badge, tag, and status_pill render visible non-interactive labels and closed tones" do
      badge = render_primitive(:badge, tone: :info, label: "Executing")
      tag = render_primitive(:tag, tone: :neutral, label: "queue: default")

      status =
        render_primitive(:status_pill,
          spec: %{label: "Retryable", tone: :warning, icon: :alert, sr_prefix: "Job state"}
        )

      assert badge =~ ~s(class="obpt-badge")
      assert badge =~ ~s(data-obpt-tone="info")
      assert badge =~ "Executing"

      assert tag =~ ~s(class="obpt-tag")
      assert tag =~ ~s(data-obpt-tone="neutral")
      assert tag =~ "queue: default"

      assert status =~ ~s(class="obpt-status-pill")
      assert status =~ ~s(data-obpt-tone="warning")
      assert status =~ "Job state"
      assert status =~ "Retryable"
      assert status =~ ~s(aria-hidden="true")
      refute status =~ "phx-click"

      assert_raise ArgumentError, ~r/unsupported tone/i, fn ->
        render_primitive(:badge, tone: :rainbow, label: "Unsafe")
      end
    end
  end

  describe "structural primitives" do
    test "surface, card, divider, kbd, and stat expose token-owned structural markup" do
      surface = render_primitive(:surface, variant: :inset, inner_block: slot("Filter summary"))
      card = render_primitive(:card, variant: :elevated, inner_block: slot("Job details"))
      divider = render_primitive(:divider, decorative: true)
      kbd = render_primitive(:kbd, text: "Esc")
      stat = render_primitive(:stat, label: "Retryable jobs", value: "12", trend: "3 blocked")

      assert surface =~ ~s(class="obpt-surface")
      assert surface =~ ~s(data-obpt-variant="inset")
      assert surface =~ "Filter summary"

      assert card =~ ~s(class="obpt-card")
      assert card =~ ~s(data-obpt-variant="elevated")
      assert card =~ "Job details"

      assert divider =~ "<hr"
      assert divider =~ ~s(class="obpt-divider")
      assert divider =~ ~s(aria-hidden="true")

      assert kbd =~ "<kbd"
      assert kbd =~ ~s(class="obpt-kbd")
      assert kbd =~ "Esc"

      assert stat =~ ~s(class="obpt-stat")
      assert stat =~ "Retryable jobs"
      assert stat =~ "12"
      assert stat =~ "3 blocked"
    end
  end

  describe "loading and tooltip primitives" do
    test "spinner and skeleton require named loading context" do
      assert_raise ArgumentError, ~r/loading label/i, fn ->
        render_primitive(:spinner, label: "")
      end

      spinner = render_primitive(:spinner, label: "Loading job history")
      skeleton = render_primitive(:skeleton, label: "Loading job table", lines: 3)

      assert spinner =~ ~s(class="obpt-spinner")
      assert spinner =~ ~s(role="status")
      assert spinner =~ ~s(aria-label="Loading job history")
      assert spinner =~ "Loading job history"

      assert skeleton =~ ~s(class="obpt-skeleton")
      assert skeleton =~ ~s(aria-busy="true")
      assert skeleton =~ "Loading job table"
      assert count(skeleton, ~s(data-obpt-skeleton-line)) == 3
    end

    test "tooltip relates trigger and description with stable ids" do
      html =
        render_primitive(:tooltip,
          id: "retry-tooltip",
          text: "Retries the selected job once",
          inner_block: slot("Retry job")
        )

      assert html =~ ~s(class="obpt-tooltip")
      assert html =~ ~s(id="retry-tooltip-trigger")
      assert html =~ ~s(aria-describedby="retry-tooltip-content")
      assert html =~ ~s(id="retry-tooltip-content")
      assert html =~ ~s(role="tooltip")
      assert html =~ ~s(data-obpt-tooltip-content)
      assert html =~ "Retry job"
      assert html =~ "Retries the selected job once"
    end
  end

  describe "source contract" do
    test "primitive source documents attrs, slots, closed values, and rest filtering" do
      source = read_primitive_source!()

      assert source =~ "use Phoenix.Component"
      assert source =~ "visual_safe_rest"
      assert source =~ ~r/attr\(?\s*:rest,\s*:global/
      assert source =~ ~r/slot\(?\s*:inner_block/
      assert source =~ "@button_variants"
      assert source =~ "@tones"
      assert source =~ "@surface_variants"

      for component <- @components do
        assert source =~ "def #{component}(assigns)",
               "COMP-01 requires #{component}/1 to be defined"

        assert Regex.match?(~r/@doc\s+\"\"\"[\s\S]+?def #{component}\(assigns\)/, source),
               "COMP-02 requires @doc text before #{component}/1"
      end
    end

    test "primitive source has no raw visual values, host selectors, or domain status taxonomy" do
      source = read_primitive_source!()

      refute source =~ ~r/#[0-9a-fA-F]{3,8}/,
             "COMP-02 keeps raw color values in the token layer, not primitive source"

      refute source =~ ~r/\b\d+(?:\.\d+)?px\b/,
             "COMP-02 keeps raw pixel values out of primitive source"

      for forbidden <- [":root", "document.documentElement", "<html", "<body", ".dark"] do
        refute source =~ forbidden, "D-03 forbids host selector leakage: #{forbidden}"
      end

      for domain_state <-
            ~w[available scheduled executing retryable cancelled discarded completed] do
        refute source =~ domain_state,
               "D-15 defers domain-wide status mapping; primitive source included #{domain_state}"
      end
    end
  end

  defp render_primitive(component, assigns) when is_atom(component) do
    assert Code.ensure_loaded?(@primitive_module),
           "D-01/COMP-01 require #{@primitive_module} to exist before rendering #{component}/1"

    assert function_exported?(@primitive_module, component, 1),
           "COMP-01 requires #{inspect(@primitive_module)}.#{component}/1"

    Phoenix.LiveViewTest.__render_component__(
      ObanPowertools.TestEndpoint,
      Function.capture(@primitive_module, component, 1),
      Map.new(assigns),
      []
    )
  end

  defp slot(text) when is_binary(text) do
    [
      %{
        __slot__: :inner_block,
        inner_block: fn _changed, _argument -> Phoenix.HTML.raw(text) end
      }
    ]
  end

  defp read_primitive_source! do
    assert File.exists?(@primitive_source),
           "COMP-01 requires #{@primitive_source} to define primitive components"

    File.read!(@primitive_source)
  end

  defp assert_attr(html, attr) do
    assert attr_present?(html, attr), "expected rendered HTML to include #{attr}: #{html}"
  end

  defp refute_attr(html, attr) do
    refute attr_present?(html, attr), "expected rendered HTML to omit #{attr}: #{html}"
  end

  defp attr_present?(html, attr) do
    Regex.match?(~r/(?:<|\s)#{Regex.escape(attr)}(?:\s*=\s*"[^"]*"|\s|>|\/)/, html)
  end

  defp count(html, needle) do
    html
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
