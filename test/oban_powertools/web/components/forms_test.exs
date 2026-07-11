defmodule ObanPowertools.Web.Components.FormsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component, only: [to_form: 2]

  @forms ObanPowertools.Web.Components.Forms
  @source_path "lib/oban_powertools/web/components/forms.ex"
  @components ~w[input textarea select checkbox radio_group switch field_group label hint error]a
  @hostile "<script>alert(1)</script>"

  describe "FORM-01 component API" do
    test "exports the complete field-first component surface" do
      assert Code.ensure_loaded?(@forms), "FORM-01 requires #{@forms} to exist"

      for component <- @components do
        assert function_exported?(@forms, component, 1),
               "FORM-01 requires #{inspect(@forms)}.#{component}/1"
      end
    end

    test "input derives identity and permits explicit id, name, and value overrides" do
      field = field(:worker, "MyApp.Worker")
      html = render_form(:input, field: field, label: "Worker name")

      assert html =~ ~s(id="filter_worker")
      assert html =~ ~s(name="filter[worker]")
      assert html =~ ~s(value="MyApp.Worker")
      assert html =~ ~s(<label)
      assert html =~ ~s(for="filter_worker")
      assert html =~ "Worker name"

      overridden =
        render_form(:input,
          field: field,
          id: "worker-override",
          name: "query[worker]",
          value: "Other.Worker",
          label: "Worker name"
        )

      assert overridden =~ ~s(id="worker-override")
      assert overridden =~ ~s(name="query[worker]")
      assert overridden =~ ~s(value="Other.Worker")
      assert overridden =~ ~s(for="worker-override")
    end

    test "textarea and select derive field values and keep visible labels" do
      textarea =
        render_form(:textarea, field: field(:reason, "operator context"), label: "Reason")

      select =
        render_form(:select,
          field: field(:state, "retryable"),
          label: "Job state",
          options: [{"Any state", ""}, {"Retryable", "retryable"}]
        )

      assert textarea =~ ~s(id="filter_reason")
      assert textarea =~ ~s(name="filter[reason]")
      assert textarea =~ ">operator context</textarea>"
      assert textarea =~ ~s(for="filter_reason")

      assert select =~ ~s(id="filter_state")
      assert select =~ ~s(name="filter[state]")
      assert select =~ ~r/<option[^>]+value="retryable"[^>]+selected/
      assert select =~ "Any state"
      assert select =~ ~s(for="filter_state")
    end
  end

  describe "FORM-02 descriptions and validation" do
    test "merges caller descriptions first with deterministic hint and error ids" do
      html =
        render_form(:input,
          field: used_error_field(:worker, "can't be blank"),
          label: "Worker name",
          hint: "Enter a full or partial worker module name.",
          rest: %{"aria-describedby" => "external-help filter_worker-hint external-help"}
        )

      assert html =~ ~s(id="filter_worker-hint")
      assert html =~ ~s(id="filter_worker-error")
      assert html =~ ~s(aria-describedby="external-help filter_worker-hint filter_worker-error")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ "Error:"
      assert html =~ "can&#39;t be blank"
    end

    test "keeps unused field errors quiet while explicit action errors render truthfully" do
      quiet =
        render_form(:input,
          field: unused_error_field(:worker, "can't be blank"),
          label: "Worker name"
        )

      refute quiet =~ "Error:"
      refute quiet =~ "filter_worker-error"
      refute_attr(quiet, "aria-invalid")

      explicit =
        render_form(:input,
          field: field(:reason, "short"),
          label: "Reason",
          errors: ["Reason must be at least 10 characters. Add more detail and try again."]
        )

      assert explicit =~ "Error:"
      assert explicit =~ "Reason must be at least 10 characters"
      assert explicit =~ ~s(id="filter_reason-error")
      assert explicit =~ ~s(aria-invalid="true")
    end

    test "standalone label, hint, and error keep exact associations and escaped text" do
      label = render_form(:label, for: "worker", label: @hostile)
      hint = render_form(:hint, id: "worker-hint", text: @hostile)
      error = render_form(:error, id: "worker-error", error: @hostile)

      assert label =~ ~s(for="worker")
      assert hint =~ ~s(id="worker-hint")
      assert error =~ ~s(id="worker-error")

      for html <- [label, hint, error] do
        assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
        refute html =~ @hostile
      end

      assert error =~ "Error:"
    end
  end

  describe "native field states and caller attribute safety" do
    test "preserves native disabled and readonly as distinct states" do
      disabled =
        render_form(:input,
          field: field(:queue, "default"),
          label: "Queue",
          disabled: true,
          hint: "Queue selection is unavailable while this job is running."
        )

      readonly =
        render_form(:input,
          field: field(:job_id, "123"),
          label: "Job ID",
          readonly: true,
          hint: "Job ID is assigned when the job is inserted and cannot be changed."
        )

      assert_attr(disabled, "disabled")
      refute_attr(disabled, "readonly")
      assert disabled =~ "Queue selection is unavailable"

      assert_attr(readonly, "readonly")
      refute_attr(readonly, "disabled")
      assert readonly =~ ~s(value="123")
      assert readonly =~ "cannot be changed"
    end

    test "allows semantic, LiveView, aria, data, and native attrs but filters class and style" do
      html =
        render_form(:input,
          field: field(:worker, ""),
          label: "Worker name",
          rest: %{
            "id" => "safe-worker",
            "phx-change" => "filter",
            "phx-debounce" => "250",
            "aria-label" => "Worker filter",
            "data-testid" => "worker-filter",
            "autocomplete" => "off",
            "placeholder" => "All workers",
            "required" => true,
            "class" => "host-visual-class",
            "style" => "color: red"
          }
        )

      assert html =~ ~s(id="safe-worker")
      assert html =~ ~s(for="safe-worker")
      assert html =~ ~s(phx-change="filter")
      assert html =~ ~s(phx-debounce="250")
      assert html =~ ~s(aria-label="Worker filter")
      assert html =~ ~s(data-testid="worker-filter")
      assert html =~ ~s(autocomplete="off")
      assert html =~ ~s(placeholder="All workers")
      assert_attr(html, "required")
      refute html =~ "host-visual-class"
      refute html =~ "color: red"
    end

    test "plain filter inputs keep native search semantics without fake combobox state" do
      html =
        render_form(:input,
          field: field(:search, "retry"),
          label: "Search jobs",
          type: "search",
          variant: :filter
        )

      assert html =~ ~s(type="search")

      for forbidden <- [
            "role=\"combobox\"",
            "aria-expanded",
            "aria-controls",
            "aria-activedescendant"
          ] do
        refute html =~ forbidden
      end
    end
  end

  describe "native choice semantics" do
    test "named boolean checkbox emits an unchecked value but event-driven selection does not" do
      named = render_form(:checkbox, field: field(:enabled, true), label: "Enable retries")

      event_driven =
        render_form(:checkbox,
          field: field(:selected, false),
          label: "Select job 123",
          rest: %{"phx-click" => "toggle_job", "phx-value-id" => "123"}
        )

      assert named =~ ~r/<input[^>]+type="hidden"[^>]+name="filter\[enabled\]"[^>]+value="false"/
      assert named =~ ~r/<input[^>]+type="checkbox"[^>]+name="filter\[enabled\]"[^>]+value="true"/
      assert named =~ ~s(for="filter_enabled")

      assert event_driven =~ ~s(type="checkbox")
      assert event_driven =~ ~s(phx-click="toggle_job")
      assert event_driven =~ ~s(phx-value-id="123")
      refute event_driven =~ ~s(type="hidden")
    end

    test "disabled named checkbox and switch disable their hidden unchecked values" do
      checkbox =
        render_form(:checkbox,
          field: field(:enabled, true),
          label: "Enable retries",
          disabled: true
        )

      switch =
        render_form(:switch,
          field: field(:paused, true),
          label: "Pause queue processing",
          disabled: true
        )

      assert checkbox =~
               ~r/<input[^>]+type="hidden"[^>]+name="filter\[enabled\]"[^>]+value="false"[^>]+disabled/

      assert switch =~
               ~r/<input[^>]+type="hidden"[^>]+name="filter\[paused\]"[^>]+value="false"[^>]+disabled/

      assert count(checkbox, ~s(type="hidden")) == 1
      assert count(switch, ~s(type="hidden")) == 1
    end

    test "radio groups use fieldset and legend with native, escaped options" do
      html =
        render_form(:radio_group,
          field: field(:state, "retryable"),
          label: "Job state",
          hint: "Choose one state.",
          options: [{"Any state", ""}, {@hostile, "hostile"}, {"Retryable", "retryable"}]
        )

      assert html =~ "<fieldset"
      assert html =~ "<legend"
      assert html =~ "Job state"
      assert html =~ ~s(type="radio")
      assert html =~ ~s(name="filter[state]")
      assert html =~ "&lt;script&gt;alert(1)&lt;/script&gt;"
      refute html =~ @hostile
      refute html =~ ~s(role="radio")
    end

    test "switch remains a checkbox-backed named field with CSS-synchronized visible state labels" do
      html =
        render_form(:switch,
          field: field(:paused, false),
          label: "Pause queue processing"
        )

      assert html =~ ~s(type="checkbox")
      assert html =~ ~s(name="filter[paused]")
      assert html =~ "Pause queue processing"
      assert html =~ ~s(class="obpt-switch__state")
      assert html =~ ~s(class="obpt-switch__state-label obpt-switch__state-label--off")
      assert html =~ ~s(class="obpt-switch__state-label obpt-switch__state-label--on")
      assert html =~ "Off"
      assert html =~ "On"
      refute html =~ ~s(role="switch")
    end

    test "field groups use fieldset and legend for related controls" do
      html =
        render_form(:field_group,
          id: "job-filters",
          label: "Job filters",
          hint: "Narrow the visible jobs.",
          inner_block: slot("Grouped fields")
        )

      assert html =~ "<fieldset"
      assert html =~ "<legend"
      assert html =~ "Job filters"
      assert html =~ "Grouped fields"
      assert html =~ ~s(id="job-filters-hint")
      assert html =~ ~s(aria-describedby="job-filters-hint")
    end
  end

  describe "hostile content and source contract" do
    test "labels, hints, errors, values, and option labels are escaped with no raw HTML API" do
      html =
        render_form(:select,
          field: field(:state, @hostile),
          label: @hostile,
          hint: @hostile,
          errors: [@hostile],
          options: [{@hostile, @hostile}]
        )

      assert count(html, "&lt;script&gt;alert(1)&lt;/script&gt;") >= 4
      refute html =~ @hostile
      refute function_exported?(@forms, :raw, 1)
    end

    test "source forbids visual literals, host theme mutation, raw HTML, and invented widget behavior" do
      source = read_source!()

      assert source =~ "use Phoenix.Component"
      assert source =~ "used_input?"
      assert source =~ "visual_safe_rest"
      refute source =~ ~s({if @checked, do: "On", else: "Off"})

      refute source =~ ~r/#[0-9a-fA-F]{3,8}/
      refute source =~ ~r/\b\d+(?:\.\d+)?px\b/

      for forbidden <- [
            ":root",
            "document.documentElement",
            "<html",
            "<body",
            ".dark",
            "Phoenix.HTML.raw",
            "raw(",
            ~s(role="combobox"),
            "aria-activedescendant",
            "JS.push",
            "Phoenix.LiveView.JS"
          ] do
        refute source =~ forbidden, "form components must not contain #{forbidden}"
      end
    end
  end

  defp render_form(component, assigns) do
    assert Code.ensure_loaded?(@forms),
           "FORM-01 requires #{@forms} before rendering #{component}/1"

    assert function_exported?(@forms, component, 1), "FORM-01 requires #{@forms}.#{component}/1"

    Phoenix.LiveViewTest.__render_component__(
      ObanPowertools.TestEndpoint,
      Function.capture(@forms, component, 1),
      Map.new(assigns),
      []
    )
  end

  defp field(name, value) do
    to_form(%{Atom.to_string(name) => value}, as: "filter")[name]
  end

  defp used_error_field(name, message) do
    to_form(%{Atom.to_string(name) => ""}, as: "filter", errors: [{name, {message, []}}])[name]
  end

  defp unused_error_field(name, message) do
    to_form(
      %{Atom.to_string(name) => "", "_unused_#{name}" => ""},
      as: "filter",
      errors: [{name, {message, []}}]
    )[name]
  end

  defp slot(text) do
    [%{__slot__: :inner_block, inner_block: fn _changed, _argument -> text end}]
  end

  defp read_source! do
    assert File.exists?(@source_path), "FORM-01 requires #{@source_path}"
    File.read!(@source_path)
  end

  defp assert_attr(html, attr), do: assert(attr_present?(html, attr), "expected #{attr}: #{html}")

  defp refute_attr(html, attr),
    do: refute(attr_present?(html, attr), "expected no #{attr}: #{html}")

  defp attr_present?(html, attr) do
    Regex.match?(~r/(?:<|\s)#{Regex.escape(attr)}(?:\s*=\s*"[^"]*"|\s|>|\/)/, html)
  end

  defp count(html, needle), do: length(String.split(html, needle)) - 1
end
