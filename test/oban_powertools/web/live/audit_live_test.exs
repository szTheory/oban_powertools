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
    assert html =~ "lifeline.repair_executed"
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

    {:ok, _view, html} =
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
    assert length(Regex.scan(~r/<tr[^>]+id="audit-record-\d+"/, html)) == 20
    assert has_element?(view, "a[href='/ops/jobs/audit']", "Previous")
    assert has_element?(view, "a[href='/ops/jobs/audit?page=3']", "Next")

    expected_ids =
      events
      |> Enum.map(& &1.id)
      |> Enum.sort(:desc)
      |> Enum.slice(20, 20)

    assert_occurs_in_order(html, Enum.map(expected_ids, &~s(id="audit-record-#{&1}")))
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
end
