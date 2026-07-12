defmodule ObanPowertools.Web.Components.DataDisplayTest do
  use ExUnit.Case, async: true

  @module ObanPowertools.Web.Components.DataDisplay
  @source_path "lib/oban_powertools/web/components/data_display.ex"
  @hostile "<script>alert('xss')</script>"
  @secret "PHASE77-SECRET-SENTINEL"

  @components ~w[
    data_table status_pill description_list key_value machine_value timeline
    progress_bar metric_card code_block args_viewer redacted_value empty_state
    toast flash_group
  ]a

  test "exports the complete Phase 77 data-display component surface" do
    assert Code.ensure_loaded?(@module), "Phase 77 requires #{@module} to exist"

    for component <- @components do
      assert function_exported?(@module, component, 1),
             "DATA-01 requires #{inspect(@module)}.#{component}/1"
    end
  end

  test "status_pill wraps the taxonomy through the primitive presentation shape" do
    html = render_data(:status_pill, domain: :job, state: :retryable, rest: %{"role" => "button"})

    assert html =~ ~s(class="obpt-status-pill")
    assert html =~ "Job state"
    assert html =~ "Retryable"
    assert html =~ ~s(data-obpt-tone="warning")
    refute html =~ ~s(role="button")
  end

  test "status_pill keeps semantic channels and rejects hostile presentation overrides" do
    html =
      render_data(:status_pill,
        id: "hostile-pill",
        domain: :job,
        state: "<script>alert_status</script>",
        rest: %{
          "aria-describedby" => "status-help",
          "aria-hidden" => "true",
          "aria-label" => @secret,
          "class" => "clickable",
          "data-obpt-tone" => "success",
          "data-testid" => "status-pill",
          "href" => "/mutate",
          "onmouseover" => "steal()",
          "phx-click" => "mutate",
          "role" => "button",
          "style" => "display:none",
          "title" => @secret
        }
      )

    assert html =~ ~s(id="hostile-pill")
    assert html =~ ~s(data-testid="status-pill")
    assert html =~ ~s(aria-describedby="status-help")
    assert html =~ "Job state"
    assert html =~ ~s(data-obpt-icon="dot")
    assert html =~ ~s(data-obpt-tone="neutral")
    assert html =~ "&lt;script&gt;alert status&lt;/script&gt;"
    root_tag = html |> String.split(">", parts: 2) |> hd()
    refute html =~ @secret
    refute html =~ "clickable"
    refute html =~ "/mutate"
    refute html =~ "steal()"
    refute root_tag =~ ~s(aria-hidden="true")
    refute root_tag =~ ~s(role="button")
    refute root_tag =~ ~s(title=)
  end

  test "data_table renders one semantic table with parent-owned sorting and stacked labels" do
    html =
      render_data(:data_table,
        id: "jobs-table",
        caption: "Jobs",
        rows: [%{id: "job-1", worker: @hostile, state: "retryable"}],
        row_id: & &1.id,
        sort_key: "worker",
        sort_direction: :asc,
        sort_event: "sort-data-table",
        col: [
          slot(:col, %{label: "Worker", sort_key: "worker", value_kind: :text}, fn row ->
            row.worker
          end),
          slot(:col, %{label: "State", sort_key: "state", value_kind: :status}, fn row ->
            row.state
          end)
        ],
        selection: [slot(:selection, %{}, fn row -> "Select #{row.id}" end)],
        action: [slot(:action, %{}, fn row -> "Open #{row.id}" end)]
      )

    assert count(html, "<table") == 1
    assert html =~ "<caption"
    assert html =~ "Jobs"
    assert html =~ ~s(<th scope="col")
    assert html =~ ~s(aria-sort="ascending")
    assert html =~ ~s(type="button")
    assert html =~ ~s(phx-click="sort-data-table")
    assert html =~ ~s(data-obpt-mobile-label="Worker")
    assert html =~ ~s(id="jobs-table-row-job-1")
    assert html =~ "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
    refute html =~ @hostile
    refute html =~ ~s(role="grid")
    refute html =~ "obpt-data-table-card"
  end

  test "data_table renders every row seam once and keeps visible mobile labels in the same cells" do
    rows = [%{id: "job-1", worker: "Worker.One"}, %{id: "job-2", worker: "Worker.Two"}]

    html =
      render_data(:data_table,
        id: "jobs-once",
        caption: "Jobs",
        rows: rows,
        row_id: & &1.id,
        col: [
          slot(:col, %{label: "Worker", value_kind: :machine}, fn row -> row.worker end),
          slot(:col, %{label: "Job ID", value_kind: :machine}, fn row -> row.id end)
        ],
        selection: [slot(:selection, %{}, fn row -> "Select #{row.id}" end)],
        action: [slot(:action, %{}, fn row -> "Open #{row.id}" end)]
      )

    assert count(html, "<table") == 1
    assert count(html, ~s(class="obpt-data-table__row")) == 2
    assert count(html, ~s(class="obpt-data-table__mobile-label")) == 8

    for row <- rows do
      assert count(html, "Select #{row.id}") == 1
      assert count(html, "Open #{row.id}") == 1
      assert count(html, row.worker) == 1
      assert html =~ ~s(id="jobs-once-row-#{row.id}")
    end

    assert count(html, ">Worker</span>") == 2
    assert count(html, ">Job ID</span>") == 2
    assert count(html, ">Selection</span>") == 2
    assert count(html, ">Actions</span>") == 2
  end

  test "data_table exposes aria-sort only on the active sortable header and preserves row order" do
    html =
      render_data(:data_table,
        id: "sorted-jobs",
        caption: "Jobs",
        rows: [%{id: "job-b", worker: "Beta"}, %{id: "job-a", worker: "Alpha"}],
        row_id: & &1.id,
        sort_key: "worker",
        sort_direction: :desc,
        sort_event: "sort-data-table",
        col: [
          slot(:col, %{label: "Job ID", sort_key: "id"}, fn row -> row.id end),
          slot(:col, %{label: "Worker", sort_key: "worker"}, fn row -> row.worker end),
          slot(:col, %{label: "State"}, fn _row -> "available" end)
        ]
      )

    assert count(html, ~s(aria-sort="descending")) == 1
    refute html =~ ~s(aria-sort="none")
    assert count(html, ~s(phx-click="sort-data-table")) == 2
    assert count(html, ~s(phx-value-sort-key="id")) == 1
    assert count(html, ~s(phx-value-sort-key="worker")) == 1
    assert index_of(html, "job-b") < index_of(html, "job-a")
  end

  test "data states render honest copy and busy semantics" do
    for {state, copy} <- [
          loading: "Loading jobs",
          empty: "No rows match the current filters",
          error: "Data did not load",
          unavailable: "Data unavailable",
          permission_denied: "Permission denied"
        ] do
      html =
        render_data(:data_table, id: "state-#{state}", caption: "Jobs", rows: [], state: state)

      assert html =~ copy
      assert html =~ ~s(data-obpt-data-state="#{state}")

      if state == :loading do
        assert html =~ ~s(aria-busy="true")
        assert html =~ ~s(class="obpt-skeleton")
        assert html =~ ~s(aria-label="Loading jobs")
      else
        refute html =~ ~s(aria-busy="true")
      end

      if state == :error do
        assert html =~ ~s(role="alert")
      else
        refute html =~ ~s(role="alert")
      end
    end

    ready =
      render_data(:data_table,
        id: "state-ready",
        caption: "Jobs",
        rows: [%{id: "job-1"}],
        row_id: & &1.id,
        state: :ready,
        col: [slot(:col, %{label: "Job ID"}, fn row -> row.id end)]
      )

    assert ready =~ ~s(data-obpt-data-state="ready")
    refute ready =~ ~s(class="obpt-data-state")
  end

  test "data_table filters hostile wrapper overrides while retaining safe descriptive attrs" do
    html =
      render_data(:data_table,
        id: "safe-table",
        caption: @hostile,
        rows: [%{id: "job-1", value: @hostile}],
        row_id: & &1.id,
        col: [slot(:col, %{label: @hostile}, fn row -> row.value end)],
        rest: %{
          "aria-describedby" => "table-help",
          "class" => "host-table",
          "data-testid" => "safe-table",
          "onmouseover" => "steal()",
          "phx-click" => "mutate",
          "role" => "grid",
          "style" => "overflow:auto",
          "title" => @secret
        }
      )

    assert html =~ ~s(aria-describedby="table-help")
    assert html =~ ~s(data-testid="safe-table")
    assert count(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;") == 4
    refute html =~ @hostile
    refute html =~ @secret
    refute html =~ "host-table"
    refute html =~ "steal()"
    refute html =~ ~s(phx-click="mutate")
    refute html =~ ~s(role="grid")
    refute html =~ ~s(style=)
    refute html =~ ~s(title=)
  end

  test "secondary components use native semantics and closed state/value contracts" do
    description =
      render_data(:description_list,
        id: "job-details",
        item: [
          slot(:item, %{label: "Worker", value_kind: :machine}, fn -> "MyApp.Very.Long.Worker" end),
          slot(:item, %{label: "Queue", value_kind: :text}, fn -> "default" end)
        ]
      )

    timeline =
      render_data(:timeline,
        id: "events",
        event: [
          slot(
            :event,
            %{
              timestamp: "2026-07-12T12:00:00Z",
              title: "Callback delivered",
              source: "Oban",
              domain: :callback_outbox,
              state: :delivered
            },
            fn -> @hostile end
          )
        ]
      )

    progress =
      render_data(:progress_bar, id: "progress", label: "Completed", value: 125, max: 100)

    unavailable =
      render_data(:progress_bar, id: "unavailable", label: "Completed", state: :unavailable)

    empty =
      render_data(:empty_state,
        id: "empty",
        heading: "No rows match",
        body: "Clear filters or widen the time window."
      )

    assert description =~ "<dl"
    assert description =~ "<dt"
    assert description =~ "<dd"
    assert timeline =~ "<ol"
    assert timeline =~ "<time"
    refute timeline =~ @hostile
    assert progress =~ "<progress"
    assert progress =~ ~s(value="100")
    assert unavailable =~ "Progress unavailable"
    refute unavailable =~ ~s(aria-valuenow)
    assert empty =~ "<h"
    assert empty =~ "Clear filters"
  end

  test "code, args, and redaction render normalized displays without leaking original sentinels" do
    code =
      render_data(:code_block,
        id: "code",
        label: "Args",
        content: ~s({"safe": "<b>text</b>"}),
        language: "json"
      )

    raw =
      render_data(:args_viewer,
        id: "raw",
        label: "Args",
        display: {:raw_json, ~s({"safe":"visible"})}
      )

    string =
      render_data(:args_viewer,
        id: "string",
        label: "Output",
        display: {:string, "visible sibling"}
      )

    fallback =
      render_data(:args_viewer, id: "fallback", label: "Args", display: {:fallback, "[redacted]"})

    map_redacted =
      render_data(:args_viewer,
        id: "recorded",
        label: "Result",
        display: %{available?: true, redacted?: true, value: @secret, sibling: "safe sibling"}
      )

    assert code =~ "<figure"
    assert code =~ "<figcaption"
    assert code =~ "<pre"
    assert code =~ ~s(tabindex="0")
    assert code =~ "&lt;b&gt;text&lt;/b&gt;"
    assert raw =~ "visible"
    assert string =~ "visible sibling"
    assert fallback =~ "[redacted]"
    assert map_redacted =~ "Hidden by display policy"
    assert map_redacted =~ "safe sibling"

    for html <- [fallback, map_redacted] do
      refute html =~ @secret
      refute html =~ ~s(title=)
      refute html =~ ~s(data-secret)
      refute html =~ "<details"
    end
  end

  test "source forbids unsafe visual, semantic, raw-html, and behavior escape hatches" do
    assert File.exists?(@source_path), "Phase 77 requires #{@source_path}"
    source = File.read!(@source_path)

    for forbidden <- [
          "Phoenix.HTML.raw",
          "raw(",
          "String.to_atom",
          "String.to_existing_atom",
          ~s(role="grid"),
          ~s(style=),
          "JS.push",
          "phx-hook",
          "document.",
          "clipboard",
          "Phoenix.LiveViewTest",
          "ObanPowertools.TestEndpoint",
          "raw_value",
          "original_value"
        ] do
      refute source =~ forbidden, "DataDisplay source must not contain #{forbidden}"
    end

    refute source =~ ~r/#[0-9a-fA-F]{3,8}/
    refute source =~ ~r/\b\d+(?:\.\d+)?px\b/
  end

  defp render_data(component, assigns) do
    assert Code.ensure_loaded?(@module),
           "Phase 77 requires #{@module} before rendering #{component}/1"

    assert function_exported?(@module, component, 1),
           "Phase 77 requires #{@module}.#{component}/1"

    Phoenix.LiveViewTest.__render_component__(
      ObanPowertools.TestEndpoint,
      Function.capture(@module, component, 1),
      Map.new(assigns),
      []
    )
  end

  defp slot(name, attrs, fun) do
    %{__slot__: name, inner_block: fn _changed, argument -> call_slot_fun(fun, argument) end}
    |> Map.merge(attrs)
  end

  defp call_slot_fun(fun, [value]), do: fun.(value)
  defp call_slot_fun(fun, _argument) when is_function(fun, 0), do: fun.()
  defp call_slot_fun(fun, value) when is_function(fun, 1), do: fun.(value)

  defp count(html, needle), do: length(String.split(html, needle)) - 1
  defp index_of(html, needle), do: :binary.match(html, needle) |> elem(0)
end
