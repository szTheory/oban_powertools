defmodule ObanPowertools.Web.Components.DataDisplayNilPolicy do
  def display(:job_args, _value, _context), do: nil
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.Components.DataDisplayStringPolicy do
  def display(:job_args, _value, _context), do: "host string sibling"
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.Components.DataDisplayMapPolicy do
  def display(:job_args, _value, _context), do: %{"safe" => "host map sibling"}
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.Components.DataDisplayRaisingPolicy do
  def display(:job_args, _value, _context), do: raise("policy failed")
  def display(_kind, _value, _context), do: nil
end

defmodule ObanPowertools.Web.Components.DataDisplayTest do
  use ExUnit.Case, async: false

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

    assert count(html, ">Worker</span>") == 3
    assert count(html, ">Job ID</span>") == 3
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
        render_data(:data_table,
          id: "state-#{state}",
          caption: "Jobs",
          rows: [],
          row_id: & &1.id,
          state: state
        )

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
    assert count(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;") == 5
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

  test "description_list and timeline render every explicit state in their owning region" do
    for component <- [:description_list, :timeline],
        state <- [:loading, :empty, :error, :unavailable, :permission_denied] do
      html =
        render_data(component,
          id: "#{component}-#{state}",
          resource: "job evidence",
          state: state
        )

      assert html =~ ~s(data-obpt-data-state="#{state}")
      assert html =~ state_copy(state)

      if state == :loading do
        assert html =~ ~s(aria-busy="true")
        assert html =~ ~s(aria-label="Loading job evidence")
      else
        refute html =~ ~s(aria-busy="true")
      end

      if state == :empty do
        assert html =~ ~s(class="obpt-empty-state")
      else
        refute html =~ ~s(class="obpt-empty-state")
      end
    end
  end

  test "timeline keeps ordered event semantics, taxonomy status, and escaped detail" do
    html =
      render_data(:timeline,
        id: "audit-events",
        event: [
          slot(
            :event,
            %{
              timestamp: "2026-07-12T12:00:00Z",
              title: @hostile,
              source: "Oban",
              domain: :callback_outbox,
              state: :delivered
            },
            fn -> @hostile end
          )
        ],
        rest: %{"class" => "host-timeline", "role" => "feed", "phx-click" => "mutate"}
      )

    assert count(html, "<ol") == 1
    assert count(html, "<li") == 1
    assert html =~ ~s(datetime="2026-07-12T12:00:00Z")
    assert html =~ "Callback outbox status"
    assert html =~ "Delivered"
    assert count(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;") == 2
    refute html =~ @hostile
    refute html =~ "host-timeline"
    refute html =~ ~s(role="feed")
    refute html =~ ~s(phx-click="mutate")
  end

  test "progress_bar clamps native values and exposes count plus percentage without inline width" do
    high =
      render_data(:progress_bar,
        id: "high-progress",
        label: "Completed jobs",
        value: 125,
        max: 100
      )

    low =
      render_data(:progress_bar, id: "low-progress", label: "Completed jobs", value: -5, max: 100)

    assert high =~ ~s(<progress id="high-progress-progress")
    assert high =~ ~s(value="100")
    assert high =~ ~s(max="100")
    assert high =~ ~s(aria-labelledby="high-progress-label")
    assert high =~ "100/100"
    assert high =~ "100%"
    refute high =~ ~s(style=)

    assert low =~ ~s(value="0")
    assert low =~ "0/100"
    assert low =~ "0%"

    unavailable =
      render_data(:progress_bar,
        id: "unknown-progress",
        label: "Completed jobs",
        value: 72,
        state: :unavailable
      )

    assert unavailable =~ "Progress unavailable"
    refute unavailable =~ "<progress"
    refute unavailable =~ ~s(value=)
    refute unavailable =~ ~s(aria-valuenow=)
  end

  test "machine_value preserves useful ends and exposes full non-sensitive text only through expansion" do
    long_id = "job_0123456789abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    long_module = "MyApp.Really.Long.Namespace.With.Many.Parts.Workers.SendEmail"

    id_html =
      render_data(:machine_value,
        id: "job-id",
        value: long_id,
        kind: :id,
        expand: true,
        rest: %{"title" => long_id, "style" => "display:none"}
      )

    module_html =
      render_data(:machine_value,
        id: "worker-module",
        value: long_module,
        kind: :module,
        expand: true
      )

    assert id_html =~ "<details"
    assert id_html =~ ">job_0123456789"
    assert id_html =~ "OPQRSTUVWXYZ</summary>"
    assert count(id_html, long_id) == 1
    refute id_html =~ ~s(title=)
    refute id_html =~ ~s(style=)

    assert module_html =~ ">..."
    assert module_html =~ "Workers.SendEmail</summary>"
    assert count(module_html, long_module) == 1
  end

  test "metric, empty, toast, and flash components keep explicit semantics and parent-owned actions" do
    metric =
      render_data(:metric_card,
        id: "throughput",
        label: "Completed jobs",
        value: "1,024",
        trend: "Up 12% over the prior hour",
        tone: :success,
        rest: %{"role" => "button", "phx-click" => "mutate", "class" => "host-metric"}
      )

    assert metric =~ ~s(class="obpt-metric-card")
    assert metric =~ ~s(class="obpt-stat")
    assert metric =~ "Up 12% over the prior hour"
    refute metric =~ ~s(role="button")
    refute metric =~ ~s(phx-click="mutate")
    refute metric =~ "host-metric"

    assert_raise ArgumentError, fn ->
      render_data(:empty_state, id: "invalid-empty", heading: " ", body: "Recovery guidance")
    end

    polite_warning =
      render_data(:toast,
        id: "warning-polite",
        tone: :warning,
        urgency: :polite,
        inner_block: [slot(:inner_block, %{}, fn -> "Retry delayed" end)]
      )

    immediate_warning =
      render_data(:toast,
        id: "warning-now",
        tone: :warning,
        urgency: :assertive,
        dismiss_event: "dismiss-toast",
        inner_block: [slot(:inner_block, %{}, fn -> @hostile end)],
        rest: %{"role" => "button", "phx-click" => "steal", "title" => @secret}
      )

    assert polite_warning =~ ~s(role="status")
    assert immediate_warning =~ ~s(role="alert")
    assert immediate_warning =~ ~s(aria-label="Dismiss notification")
    assert immediate_warning =~ ~s(phx-click="dismiss-toast")
    assert immediate_warning =~ "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
    refute immediate_warning =~ @hostile
    refute immediate_warning =~ @secret
    refute immediate_warning =~ ~s(phx-click="steal")
    refute immediate_warning =~ ~s(role="button")
  end

  test "flash_group preserves canonical Phoenix keys, severity, identity, and dismiss payloads" do
    html =
      render_data(:flash_group,
        id: "operator-flash",
        flash: %{
          "info" => "Refresh complete",
          "error" => "Refresh failed",
          "alpha" => "First neutral",
          "beta" => @hostile
        }
      )

    assert html =~
             ~s(id="operator-flash-aW5mbw" class="obpt-toast" data-obpt-tone="info" role="status")

    assert html =~
             ~s(id="operator-flash-ZXJyb3I" class="obpt-toast" data-obpt-tone="danger" role="alert")

    assert html =~ ~s(id="operator-flash-YWxwaGE")
    assert html =~ ~s(id="operator-flash-YmV0YQ")
    assert count(html, ~s(data-obpt-tone="neutral")) == 2
    assert count(html, ~s(phx-click="lv:clear-flash")) == 4

    for key <- ~w[info error alpha beta] do
      assert count(html, ~s(phx-value-key="#{key}")) == 1
    end

    assert html =~ "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
    refute html =~ @hostile
  end

  test "flash_group normalizes atom aliases without atom creation and prefers binary entries" do
    atom_html =
      render_data(:flash_group,
        id: "atom-flash",
        flash: %{info: "Atom info", error: "Atom error"}
      )

    assert atom_html =~ ~s(id="atom-flash-aW5mbw")
    assert atom_html =~ ~s(data-obpt-tone="info")
    assert atom_html =~ ~s(phx-value-key="info")
    assert atom_html =~ ~s(id="atom-flash-ZXJyb3I")
    assert atom_html =~ ~s(data-obpt-tone="danger")
    assert atom_html =~ ~s(phx-value-key="error")

    duplicate_html =
      render_data(:flash_group,
        id: "duplicate-flash",
        flash: %{:info => "Atom loses", "info" => "Binary wins"}
      )

    assert count(duplicate_html, ~s(id="duplicate-flash-aW5mbw")) == 1
    assert count(duplicate_html, ~s(phx-value-key="info")) == 1
    assert duplicate_html =~ "Binary wins"
    refute duplicate_html =~ "Atom loses"

    assert_raise ArgumentError, ~r/unsupported flash key/, fn ->
      render_data(:flash_group, id: "invalid-flash", flash: %{7 => "Unsupported"})
    end

    source = File.read!(@source_path)
    refute source =~ "String.to_atom"
    refute source =~ "String.to_existing_atom"
  end

  test "standalone toast omits a flash key when none is supplied" do
    html =
      render_data(:toast,
        id: "standalone-toast",
        dismiss_event: "dismiss-toast",
        inner_block: [slot(:inner_block, %{}, fn -> "Standalone" end)]
      )

    assert html =~ ~s(phx-click="dismiss-toast")
    refute html =~ "phx-value-key"
  end

  test "code_block is visibly labelled, focusable, escaped, and filters disclosure attributes" do
    code =
      render_data(:code_block,
        id: "code",
        label: "Args",
        content: ~s({"safe": "<b>text</b>"}),
        language: "json",
        rest: %{
          "aria-describedby" => "code-help",
          "class" => "host-code",
          "data-obpt-language" => "html",
          "data-testid" => "args-code",
          "onclick" => "copySecret()",
          "phx-click" => "copy-secret",
          "role" => "button",
          "style" => "overflow:visible",
          "title" => @secret
        }
      )

    assert code =~ ~s(<figure id="code" class="obpt-code-block" data-obpt-language="json")
    assert code =~ ~s(aria-describedby="code-help")
    assert code =~ ~s(data-testid="args-code")
    assert code =~ "<figcaption>Args</figcaption>"
    assert code =~ ~s(<pre class="obpt-code-block__region" tabindex="0")
    assert code =~ ~s(<code class="obpt-code-block__code")
    assert code =~ "&lt;b&gt;text&lt;/b&gt;"
    refute code =~ @secret
    refute code =~ "host-code"
    refute code =~ "copySecret"
    refute code =~ "copy-secret"
    refute code =~ ~s(role="button")
    refute code =~ ~s(style=)
    refute code =~ ~s(title=)

    assert_raise ArgumentError, fn ->
      render_data(:code_block, id: "blank-code", label: " ", content: "safe")
    end
  end

  test "args_viewer dispatches normalized tuple output without invoking policy callbacks" do
    raw_json = ~s({"safe":"visible","markup":"<script>blocked</script>"})

    raw =
      render_data(:args_viewer,
        id: "raw",
        label: "Args",
        display: {:raw_json, raw_json}
      )

    string =
      render_data(:args_viewer,
        id: "string",
        label: "Output",
        display: {:string, "visible sibling"}
      )

    fallback =
      render_data(:args_viewer, id: "fallback", label: "Args", display: {:fallback, @secret})

    assert raw =~ ~s(data-obpt-language="json")
    assert raw =~ "visible"
    assert raw =~ "&lt;script&gt;blocked&lt;/script&gt;"
    refute raw =~ "<script>"
    assert string =~ ~s(data-obpt-language="text")
    assert string =~ "visible sibling"
    assert fallback =~ "[redacted]"
    assert_no_disclosure(fallback)
  end

  test "args_viewer renders available recorded and workflow maps without inspecting their envelope" do
    recorded =
      render_data(:args_viewer,
        id: "recorded-available",
        label: "Recorded output",
        kind: :recorded_output,
        display: %{
          available?: true,
          redacted?: false,
          summary: "recorded safe summary",
          status: "ok",
          payload: "recorded exact payload <tag>"
        }
      )

    workflow =
      render_data(:args_viewer,
        id: "workflow-available",
        label: "Workflow result",
        kind: :workflow_result,
        display: %{
          "available?" => true,
          "redacted?" => false,
          "summary" => "workflow safe summary",
          "status" => "completed",
          "payload" => "workflow exact payload"
        }
      )

    assert recorded =~ ~s(data-obpt-kind="recorded_output")
    assert recorded =~ ~s(class="obpt-args-viewer__summary")
    assert recorded =~ "recorded safe summary"
    assert recorded =~ ~s(class="obpt-args-viewer__status")
    assert recorded =~ "ok"
    assert recorded =~ "recorded exact payload &lt;tag&gt;"
    refute recorded =~ "%{"
    refute recorded =~ "available?:"

    assert workflow =~ ~s(data-obpt-kind="workflow_result")
    assert workflow =~ "workflow safe summary"
    assert workflow =~ "completed"
    assert workflow =~ "workflow exact payload"
    refute workflow =~ "%{"
  end

  test "args_viewer renders unavailable and redacted maps without exposing payloads" do
    unavailable =
      render_data(:args_viewer,
        id: "recorded-unavailable",
        label: "Recorded output",
        kind: :recorded_output,
        display: %{
          available?: false,
          redacted?: false,
          summary: "No recorded output found",
          status: nil,
          payload: @secret
        }
      )

    recorded_redacted =
      render_data(:args_viewer,
        id: "recorded-redacted",
        label: "Recorded output",
        kind: :recorded_output,
        display: %{
          available?: true,
          redacted?: true,
          summary: "recorded safe sibling",
          status: "redacted",
          payload: %{"nested" => [@secret]}
        }
      )

    workflow_redacted =
      render_data(:args_viewer,
        id: "workflow-redacted",
        label: "Workflow result",
        kind: :workflow_result,
        display: %{
          "available?" => true,
          "redacted?" => true,
          "summary" => "workflow safe sibling",
          "status" => "redacted",
          "payload" => @secret
        }
      )

    assert unavailable =~ ~s(data-obpt-display-state="unavailable")
    assert unavailable =~ "No recorded output found"
    refute unavailable =~ "Hidden by display policy"

    for {html, sibling} <- [
          {recorded_redacted, "recorded safe sibling"},
          {workflow_redacted, "workflow safe sibling"}
        ] do
      assert html =~ "Hidden by display policy"
      assert html =~ sibling
      assert html =~ "redacted"
      assert_no_disclosure(html)
    end

    assert_no_disclosure(unavailable)
  end

  test "normalized DisplayPolicy fixtures preserve safe output and remove original secrets" do
    original = Application.get_env(:oban_powertools, :display_policy)
    on_exit(fn -> Application.put_env(:oban_powertools, :display_policy, original) end)

    job = %Oban.Job{meta: %{"__redacted_fields__" => ["secret"]}}

    fixtures = [
      {ObanPowertools.Web.Components.DataDisplayNilPolicy, "nil-policy", "safe nil sibling",
       "Redacted at enqueue"},
      {ObanPowertools.Web.Components.DataDisplayStringPolicy, "string-policy", "safe nil sibling",
       "host string sibling"},
      {ObanPowertools.Web.Components.DataDisplayMapPolicy, "map-policy", "safe nil sibling",
       "host map sibling"},
      {ObanPowertools.Web.Components.DataDisplayRaisingPolicy, "raising-policy",
       "safe nil sibling", "[redacted]"}
    ]

    for {policy, id, sibling, expected} <- fixtures do
      Application.put_env(:oban_powertools, :display_policy, policy)

      normalized =
        ObanPowertools.DisplayPolicy.render_job_field(
          :job_args,
          %{"safe" => sibling},
          %{job: job}
        )

      html = render_data(:args_viewer, id: id, label: "Args", display: normalized)

      assert html =~ expected

      assert html =~ sibling or
               expected in ["host string sibling", "host map sibling", "[redacted]"]

      assert_no_disclosure(html)
    end
  end

  test "redacted_value uses closed exact copy and exposes no disclosure API" do
    enqueue = render_data(:redacted_value, id: "enqueue", reason: :enqueue)
    policy = render_data(:redacted_value, id: "policy", reason: :policy)
    fallback = render_data(:redacted_value, id: "fallback", reason: :fallback, message: @secret)

    assert enqueue =~ "Redacted at enqueue"
    assert policy =~ "Hidden by display policy"
    assert fallback =~ "[redacted]"

    for html <- [enqueue, policy, fallback] do
      assert html =~ ~s(class="obpt-redacted-value__icon")
      assert_no_disclosure(html)
    end
  end

  test "source keeps ArgsViewer normalized-only and RedactedValue disclosure-free" do
    source = File.read!(@source_path)

    assert source =~ "defp render_normalized_display"
    refute source =~ "DisplayPolicy"

    args_attrs = source |> source_between("attr(:display", "def args_viewer")
    redacted_api = source |> source_between("attr(:reason", "def redacted_value")

    refute args_attrs =~ "raw"
    refute args_attrs =~ "original"

    for forbidden <- ["slot(", "attr(:rest", "attr(:title", "attr(:tooltip", "attr(:value"] do
      refute redacted_api =~ forbidden
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

  defp assert_no_disclosure(html) do
    refute html =~ @secret
    refute html =~ ~s(title=)
    refute html =~ "tooltip"
    refute html =~ "clipboard"
    refute html =~ "copy-buffer"
    refute html =~ "<details"
    refute html =~ "<summary"

    for attribute <- Regex.scan(~r/\s(data-[^=\s]+)=(?:"[^"]*"|'[^']*')/, html) do
      refute Enum.join(attribute, " ") =~ @secret
    end
  end

  defp source_between(source, first, last) do
    [_before, after_first] = String.split(source, first, parts: 2)
    [between, _after] = String.split(after_first, last, parts: 2)
    first <> between
  end

  defp state_copy(:loading), do: "Loading job evidence"
  defp state_copy(:empty), do: "No rows match the current filters"
  defp state_copy(:error), do: "Data did not load"
  defp state_copy(:unavailable), do: "Data unavailable"
  defp state_copy(:permission_denied), do: "Permission denied"
end
