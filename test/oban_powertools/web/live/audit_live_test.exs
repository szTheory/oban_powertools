defmodule ObanPowertools.Web.AuditLiveTestDisplayPolicy do
  def display(:actor_label, principal, _context) do
    label =
      Map.get(principal, :label) ||
        Map.get(principal, "label") ||
        Map.get(principal, :id) ||
        Map.get(principal, "id") ||
        "system"

    "policy actor: #{label}"
  end

  def display(:reason, nil, _context), do: "policy reason: none provided"
  def display(:reason, "", _context), do: "policy reason: none provided"
  def display(:reason, reason, _context), do: "policy reason: #{String.upcase(to_string(reason))}"
end

defmodule ObanPowertools.Web.AuditLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.Audit
  alias ObanPowertools.Workflow
  alias ObanPowertools.WorkflowFixtures
  alias ObanPowertools.Web.AuditLive

  setup do
    original_display_policy = Application.get_env(:oban_powertools, :display_policy)

    Application.put_env(
      :oban_powertools,
      :display_policy,
      ObanPowertools.Web.AuditLiveTestDisplayPolicy
    )

    on_exit(fn ->
      Application.put_env(:oban_powertools, :display_policy, original_display_policy)
    end)

    :ok
  end

  test "renders audit history", %{conn: conn} do
    Audit.record(
      "lifeline.repair_executed",
      %{type: :job, id: "123"},
      %{
        "source" => "lifeline",
        "reason" => "maintenance window rescue",
        "principal" => %{"id" => "ops-1", "type" => "user", "label" => "Jane Operator"}
      },
      repo: TestRepo,
      actor_id: "ops-1"
    )

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-1", permissions: [:view_audit]})

    {:ok, _view, html} = live(conn, "/ops/jobs/audit")
    assert html =~ "Repair executed"
    assert html =~ "job:123"
    assert html =~ "policy actor: Jane Operator"
    assert html =~ "policy reason: MAINTENANCE WINDOW RESCUE"
    assert html =~ "Repair evidence retention"
    assert html =~ "Recorded at"
    assert html =~ "Event"
    assert html =~ "Target"
    assert html =~ "Permission: read-only."
    assert html =~ "Review recorded operator actions and the evidence available for each record."

    assert html =~
             "Powertools-native pages keep preview, reason, and local audit evidence close to the acted-on resource."

    assert html =~ "Inspection only"
  end

  test "scopes audit history with durable read-only filters", %{conn: conn} do
    Audit.record(
      "lifeline.repair_executed",
      %{type: :job, id: "123"},
      %{"event_type" => "lifeline.repair_executed", "reason" => "maintenance"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    Audit.record(
      "cron.paused",
      %{type: :cron_entry, id: "nightly"},
      %{"event_type" => "cron.paused", "reason" => "maintenance"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    conn =
      Plug.Test.init_test_session(conn, current_actor: %{id: "ops-1", permissions: [:view_audit]})

    {:ok, view, html} =
      live(
        conn,
        "/ops/jobs/audit?resource_type=job&resource_id=123&event_type=lifeline.repair_executed"
      )

    assert html =~ ~s(id="audit-filters")
    assert html =~ "Resource type"
    assert html =~ "job"
    assert html =~ "Resource ID"
    assert html =~ "123"
    assert html =~ "Event type"
    assert html =~ "lifeline.repair_executed"
    assert html =~ "job:123"
    refute html =~ "cron_entry:nightly"

    assert has_element?(
             view,
             "#audit-filters a[href='/ops/jobs/audit?resource_id=123&event_type=lifeline.repair_executed']"
           )

    assert has_element?(
             view,
             "#audit-filters a[href='/ops/jobs/audit?resource_type=job&event_type=lifeline.repair_executed']"
           )

    assert has_element?(
             view,
             "#audit-filters a[href='/ops/jobs/audit?resource_type=job&resource_id=123']"
           )

    assert has_element?(view, "#audit-filters a[href='/ops/jobs/audit']", "Clear filters")
  end

  test "forensic audit follow-up preserves scoped resource and event filters", %{conn: conn} do
    {:ok, workflow} =
      WorkflowFixtures.workflow_fixture(name: "forensic-audit-follow-up")
      |> Workflow.insert(TestRepo)

    Audit.record(
      "workflow.step_completed",
      %{type: :workflow, id: workflow.id},
      %{"event_type" => "workflow.step_completed", "reason" => "follow-up"},
      repo: TestRepo,
      actor_id: "ops-1"
    )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "ops-1", permissions: [:view_audit, :view_forensics]}
      )

    {:ok, _forensic_view, forensic_html} =
      live(conn, "/ops/jobs/forensics?workflow_id=#{workflow.id}")

    assert forensic_html =~
             "/ops/jobs/audit?resource_type=workflow&amp;resource_id=#{workflow.id}&amp;event_type=workflow.step_completed"

    {:ok, _audit_view, audit_html} =
      live(
        conn,
        "/ops/jobs/audit?resource_type=workflow&resource_id=#{workflow.id}&event_type=workflow.step_completed"
      )

    assert audit_html =~ ~s(id="audit-filters")
    assert audit_html =~ "Resource type"
    assert audit_html =~ "workflow"
    assert audit_html =~ "Event type"
    assert audit_html =~ "workflow.step_completed"
  end

  test "redirects unauthorized viewers", %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-3", permissions: []})
    assert {:error, {:redirect, %{to: "/"}}} = live(conn, "/ops/jobs/audit")
  end

  @tag phase79_slice: "audit"
  test "renders stable reachable 20-row pages with exact summary and tie-break order", %{
    conn: conn
  } do
    inserted_at = ~N[2026-07-19 14:00:00]

    events =
      for index <- 1..45 do
        record_audit!(
          "job.reviewed",
          %{type: :job, id: "audit-page-#{index}"},
          %{"reason" => "page contract #{index}"},
          inserted_at: inserted_at
        )
      end

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "audit-reader-79", permissions: [:view_audit]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/audit?page=2")

    assert has_element?(view, "#audit-page")
    assert has_element?(view, "#audit-retention", "Repair evidence retention")
    assert has_element?(view, "#audit-records.obpt-data-table")
    assert has_element?(view, "#audit-records caption", "Audit records")
    assert html =~ "Records 21–40 of 45 · Page 2 of 3"
    assert length(Regex.scan(~r/id="audit-record-\d+"/, html)) == 20
    assert has_element?(view, "a[href='/ops/jobs/audit']", "Previous")
    assert has_element?(view, "a[href='/ops/jobs/audit?page=3']", "Next")

    assigns = live_assigns(view)
    assert length(assigns.event_rows) == 20
    assert assigns.audit_page.page == 2
    assert assigns.audit_page.page_size == 20
    assert assigns.audit_page.total_count == 45
    assert assigns.result_summary == "Records 21–40 of 45 · Page 2 of 3"
    refute Enum.any?(assigns.event_rows, &match?(%Audit{}, &1))

    expected_ids =
      events
      |> Enum.map(& &1.id)
      |> Enum.sort(:desc)
      |> Enum.slice(20, 20)

    assert_occurs_in_order(html, Enum.map(expected_ids, &~s(id="audit-record-#{&1}")))
  end

  @tag phase79_slice: "audit"
  test "keeps only genuine allowlisted evidence in render-intended assigns", %{conn: conn} do
    event =
      record_audit!(
        "lifeline.repair_executed",
        %{type: :job, id: "safe-evidence"},
        %{
          "reason" => "complete operator reason",
          "source" => "lifeline",
          "outcome" => "Repair recorded",
          "outcome_state" => "success",
          "correlation_id" => "request-79",
          "evidence" => %{
            "items" => [%{"label" => "Affected jobs", "value" => "1"}],
            "preview_token" => "AUDIT-NESTED-TOKEN-SENTINEL"
          },
          "principal" => %{
            "id" => "ops-safe",
            "type" => "user",
            "label" => "Safe Operator",
            "credential" => "AUDIT-PRINCIPAL-CREDENTIAL-SENTINEL"
          },
          "command_key" => "AUDIT-COMMAND-SENTINEL",
          "exception" => "AUDIT-RAW-ERROR-SENTINEL"
        }
      )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "audit-safe-79", permissions: [:view_audit]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/audit?event=#{event.id}")

    assert html =~ "policy actor: Safe Operator"
    assert html =~ "policy reason: COMPLETE OPERATOR REASON"
    assert html =~ "Repair recorded"
    assert html =~ "lifeline"
    assert html =~ "request-79"
    assert html =~ "Affected jobs"

    for secret <- [
          "AUDIT-NESTED-TOKEN-SENTINEL",
          "AUDIT-PRINCIPAL-CREDENTIAL-SENTINEL",
          "AUDIT-COMMAND-SENTINEL",
          "AUDIT-RAW-ERROR-SENTINEL"
        ] do
      refute html =~ secret
    end

    assigns = live_assigns(view)

    presentation_assigns =
      Map.take(assigns, [
        :audit_page,
        :event_rows,
        :active_filters,
        :selected_detail,
        :retention_summary
      ])

    refute contains_audit_schema?(presentation_assigns)

    forbidden_keys =
      ~w[metadata command_key preview_token plan_hash principal credential exception stacktrace error]

    assert MapSet.disjoint?(
             nested_keys(presentation_assigns),
             MapSet.new(forbidden_keys)
           )
  end

  @tag phase79_slice: "audit"
  test "filters reset page and event while selection composes with canonical URL history", %{
    conn: conn
  } do
    first =
      record_audit!(
        "cron.paused",
        %{type: :cron_entry, id: "nightly/sync ?&="},
        %{"reason" => "first event"}
      )

    second =
      record_audit!(
        "cron.paused",
        %{type: :cron_entry, id: "nightly/sync ?&="},
        %{"reason" => "second event"}
      )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "audit-filter-79", permissions: [:view_audit]}
      )

    {:ok, view, _html} = live(conn, "/ops/jobs/audit?page=9&event=#{first.id}")

    assert has_element?(view, "#audit-filters-form")

    view
    |> form("#audit-filters-form", %{
      "filters" => %{
        "resource_type" => "cron_entry",
        "resource_id" => "nightly/sync ?&=",
        "event_type" => "cron.paused"
      }
    })
    |> render_submit()

    base =
      "/ops/jobs/audit?resource_type=cron_entry&resource_id=#{URI.encode_www_form("nightly/sync ?&=")}&event_type=cron.paused"

    assert_patch(view, base)

    render_hook(view, "select_event", %{"event" => Integer.to_string(first.id)})
    assert_patch(view, "#{base}&event=#{first.id}")
    assert has_element?(view, "#audit-detail")

    render_hook(view, "select_event", %{"event" => Integer.to_string(second.id)})
    assert_patch(view, "#{base}&event=#{second.id}")

    render_hook(view, "close_detail", %{})
    assert_patch(view, base)
    refute has_element?(view, "#audit-detail")
  end

  @tag phase79_slice: "audit"
  test "direct mismatched event selection fails closed without existence or secret leakage", %{
    conn: conn
  } do
    event =
      record_audit!(
        "lifeline.repair_executed",
        %{type: :job, id: "secret-job"},
        %{
          "reason" => "AUDIT-MISMATCH-SECRET-SENTINEL",
          "preview_token" => "AUDIT-MISMATCH-TOKEN"
        }
      )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "audit-scope-79", permissions: [:view_audit]}
      )

    {:ok, view, html} =
      live(
        conn,
        "/ops/jobs/audit?resource_type=job&resource_id=other-job&event_type=lifeline.repair_executed&event=#{event.id}"
      )

    assert has_element?(view, "#audit-detail[data-obpt-detail-state='unavailable']")
    assert html =~ "Audit evidence is unavailable"
    refute html =~ "secret-job"
    refute html =~ "AUDIT-MISMATCH-SECRET-SENTINEL"
    refute html =~ "AUDIT-MISMATCH-TOKEN"
    refute html =~ "exists outside the current filters"
  end

  @tag phase79_slice: "audit"
  test "selected immutable evidence uses exact absence copy and structural allowlisting", %{
    conn: conn
  } do
    event =
      record_audit!(
        "job.reviewed",
        %{type: :job, id: "123"},
        %{
          "credential" => "AUDIT-CREDENTIAL-SENTINEL",
          "preview_token" => "AUDIT-PREVIEW-TOKEN-SENTINEL",
          "plan_hash" => "AUDIT-PLAN-HASH-SENTINEL",
          "exception" => "AUDIT-EXCEPTION-SENTINEL",
          "stacktrace" => "AUDIT-STACKTRACE-SENTINEL"
        }
      )

    conn =
      Plug.Test.init_test_session(conn,
        current_actor: %{id: "audit-detail-79", permissions: [:view_audit]}
      )

    {:ok, view, html} = live(conn, "/ops/jobs/audit?event=#{event.id}")

    assert has_element?(view, "#audit-detail")
    assert has_element?(view, "#audit-entry-#{event.id}")
    assert html =~ "No operator reason recorded"
    assert html =~ "Outcome not recorded"
    assert html =~ "Source not recorded"
    assert html =~ "Correlation not recorded"
    assert html =~ "Recorded at"
    assert html =~ "/ops/jobs/jobs/123"

    for secret <- [
          "AUDIT-CREDENTIAL-SENTINEL",
          "AUDIT-PREVIEW-TOKEN-SENTINEL",
          "AUDIT-PLAN-HASH-SENTINEL",
          "AUDIT-EXCEPTION-SENTINEL",
          "AUDIT-STACKTRACE-SENTINEL"
        ] do
      refute html =~ secret
    end

    refute html =~ "caused"
    refute html =~ "currently"
    refute html =~ ~s(role="alert")
  end

  @tag phase79_slice: "audit"
  test "Audit remains a bounded read-only review surface with finite event handlers" do
    source = File.read!("lib/oban_powertools/web/audit_live.ex")

    assert source =~ "Audit.page"
    assert source =~ "Audit.fetch_in_scope"
    refute source =~ "Audit.list_all"

    events =
      Regex.scan(~r/def handle_event\("([^"]+)"/, source, capture: :all_but_first)
      |> List.flatten()
      |> MapSet.new()

    assert MapSet.subset?(events, MapSet.new(["apply_filters", "select_event", "close_detail"]))

    for forbidden <- ["pause", "resume", "run_now", "retry", "cancel", "delete", "execute"] do
      refute MapSet.member?(events, forbidden)
    end
  end

  @tag phase79_slice: "audit"
  test "public page_content composes the shared read-only scan tree without repository work" do
    form =
      Phoenix.Component.to_form(
        %{"resource_type" => "", "resource_id" => "", "event_type" => ""},
        as: :filters,
        id: "audit-filters-form"
      )

    html =
      render_component(&AuditLive.page_content/1,
        audit_page: %{
          total_count: 0,
          page: 1,
          page_size: 20,
          total_pages: 0,
          previous?: false,
          next?: false,
          previous_href: nil,
          next_href: nil
        },
        event_rows: [],
        filter_form: form,
        active_filters: [],
        result_summary: "0 records · Page 1 of 1",
        selected_event_id: nil,
        selected_detail: nil,
        detail_state: :empty,
        retention_summary: %{
          title: "Repair evidence retention",
          description:
            "Archived repair evidence is stored separately from the live Audit rows shown here.",
          last_run: "No repair archive run has been recorded."
        }
      )

    assert length(Regex.scan(~r/<h1(?:\s|>)/, html)) == 1
    assert length(Regex.scan(~r/<table(?:\s|>)/, html)) == 1
    assert html =~ ~s(id="audit-filters")
    assert html =~ ~s(id="audit-records")
    assert html =~ "No audit records recorded"
    assert html =~ "Recorded operator actions will appear here when evidence is available."
    refute html =~ ~s(role="alert")
    refute html =~ "obpt-timeline"
    refute html =~ ~s(type="checkbox")

    fields =
      Regex.scan(~r/name="filters\[([^]]+)\]"/, html, capture: :all_but_first)
      |> List.flatten()
      |> MapSet.new()

    assert fields == MapSet.new(~w[resource_type resource_id event_type])

    error_html =
      render_component(&AuditLive.page_content/1,
        audit_page: %{
          total_count: 0,
          page: 1,
          page_size: 20,
          total_pages: 0,
          previous?: false,
          next?: false,
          previous_href: nil,
          next_href: nil
        },
        event_rows: [],
        filter_form: form,
        active_filters: [],
        result_summary: "0 records · Page 1 of 1",
        detail_state: :empty,
        retention_summary: %{
          title: "Repair evidence retention",
          description: "Archived repair evidence is stored separately from live Audit rows.",
          last_run: "No repair archive run has been recorded."
        },
        load_state: :error
      )

    assert error_html =~ "Audit records did not load"
    assert error_html =~ "Retry the request. If the problem continues, check the host logs."
    assert error_html =~ ~s(role="alert")

    source = File.read!("lib/oban_powertools/web/audit_live.ex")
    assert source =~ "def page_content(assigns)"
    assert source =~ "OperatorPatterns.filter_bar"
    assert source =~ "DataDisplay.data_table"
    assert source =~ "OperatorPatterns.detail_surface"
    assert source =~ "OperatorPatterns.audit_entry"

    [composition_source | _rest] =
      source
      |> String.split("def page_content(assigns)", parts: 2)
      |> List.last()
      |> String.split("defp load_audit_state", parts: 2)

    refute composition_source =~ "Audit.page"
    refute composition_source =~ "Audit.fetch_in_scope"
    refute composition_source =~ "Lifeline.retention_status"
    refute composition_source =~ "DateTime.utc_now"
  end

  defp record_audit!(action, resource, metadata, opts \\ []) do
    {:ok, event} =
      Audit.record(
        action,
        resource,
        Map.put_new(metadata, "event_type", action),
        repo: TestRepo,
        actor_id: "audit-fixture-79"
      )

    case Keyword.get(opts, :inserted_at) do
      nil ->
        event

      inserted_at ->
        event |> Ecto.Changeset.change(inserted_at: inserted_at) |> TestRepo.update!()
    end
  end

  defp assert_occurs_in_order(text, markers) do
    indexes =
      Enum.map(markers, fn marker ->
        case :binary.match(text, marker) do
          {index, _length} -> index
          :nomatch -> flunk("expected #{inspect(marker)} in rendered Audit HTML")
        end
      end)

    assert indexes == Enum.sort(indexes)
  end

  defp live_assigns(view) do
    view.pid
    |> :sys.get_state()
    |> find_live_assigns()
    |> case do
      nil -> flunk("expected LiveView socket assigns in process state")
      assigns -> assigns
    end
  end

  defp find_live_assigns(%Phoenix.LiveView.Socket{assigns: assigns}), do: assigns

  defp find_live_assigns(value) when is_tuple(value) do
    value |> Tuple.to_list() |> Enum.find_value(&find_live_assigns/1)
  end

  defp find_live_assigns(value) when is_list(value),
    do: Enum.find_value(value, &find_live_assigns/1)

  defp find_live_assigns(value) when is_map(value) and not is_struct(value) do
    Enum.find_value(value, fn {key, nested} ->
      find_live_assigns(key) || find_live_assigns(nested)
    end)
  end

  defp find_live_assigns(_value), do: nil

  defp contains_audit_schema?(%Audit{}), do: true

  defp contains_audit_schema?(value) when is_map(value) do
    Enum.any?(value, fn {key, nested} ->
      contains_audit_schema?(key) or contains_audit_schema?(nested)
    end)
  end

  defp contains_audit_schema?(value) when is_list(value),
    do: Enum.any?(value, &contains_audit_schema?/1)

  defp contains_audit_schema?(value) when is_tuple(value) do
    value |> Tuple.to_list() |> Enum.any?(&contains_audit_schema?/1)
  end

  defp contains_audit_schema?(_value), do: false

  defp nested_keys(value, keys \\ MapSet.new())

  defp nested_keys(value, keys) when is_map(value) do
    Enum.reduce(value, keys, fn {key, nested}, keys ->
      keys = if is_atom(key) or is_binary(key), do: MapSet.put(keys, to_string(key)), else: keys
      nested_keys(nested, keys)
    end)
  end

  defp nested_keys(value, keys) when is_list(value),
    do: Enum.reduce(value, keys, &nested_keys/2)

  defp nested_keys(value, keys) when is_tuple(value) do
    value |> Tuple.to_list() |> Enum.reduce(keys, &nested_keys/2)
  end

  defp nested_keys(_value, keys), do: keys
end
