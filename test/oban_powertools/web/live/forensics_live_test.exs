defmodule ObanPowertools.Web.ForensicsLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.{Audit, Cron, Workflow}
  alias ObanPowertools.TestRepo
  alias ObanPowertools.Web.ForensicsLive
  alias ObanPowertools.Workflow.Step
  alias ObanPowertools.WorkflowFixtures

  @bare_path "/ops/jobs/forensics"
  @allowed_selector_keys MapSet.new([
                           "resource_type",
                           "resource_id",
                           "workflow_id",
                           "step",
                           "incident_fingerprint",
                           "view"
                         ])

  describe "typed scope chooser and URL state" do
    test "bare route is a genuine four-family chooser and does not inspect evidence", %{
      conn: conn
    } do
      {{:ok, view, html}, queries} =
        capture_select_queries(fn -> live(forensics_conn(conn), @bare_path) end)

      assert queries == []
      assert count(html, "<h1") == 1
      assert html =~ "Forensics"
      assert html =~ "Choose evidence to inspect."

      assert html =~
               "Select Workflow, Lifeline incident, Cron entry, or Limiter, then enter its identifier."

      assert html =~ ~s(data-obpt-filter-bar)
      assert html =~ ~s(phx-change="validate_scope")
      assert html =~ ~s(phx-submit="inspect_evidence")
      assert has_element?(view, "form#forensics-scope-form")

      for {label, value} <- [
            {"Workflow", "workflow"},
            {"Lifeline incident", "incident"},
            {"Cron entry", "cron"},
            {"Limiter", "limiter"}
          ] do
        assert has_element?(
                 view,
                 ~s(select[name="scope[evidence_type]"] option[value="#{value}"]),
                 label
               )
      end

      refute html =~ "Investigation summary"
      refute html =~ "What to do next"
      refute html =~ "Latest remediation evidence"
      refute html =~ "Event log"
      refute html =~ "Evidence limits and sources"
    end

    test "change events validate drafts, reveal only the chosen family, and perform no reads or patches",
         %{conn: conn} do
      {:ok, view, _html} = live(forensics_conn(conn), @bare_path)

      {_html, queries} =
        capture_select_queries(fn ->
          render_change(element(view, "#forensics-scope-form"), %{
            "scope" => %{
              "evidence_type" => "workflow",
              "workflow_id" => "",
              "step" => "billing"
            }
          })
        end)

      assert queries == []
      refute_patch(view)
      assert has_element?(view, ~s(input[name="scope[workflow_id]"][aria-invalid="true"]))
      assert has_element?(view, ~s(input[name="scope[workflow_id]"][aria-describedby]))
      assert has_element?(view, ~s(input[name="scope[step]"]))
      refute has_element?(view, ~s(input[name="scope[incident_fingerprint]"]))
      refute has_element?(view, ~s(input[name="scope[resource_id]"]))

      render_change(element(view, "#forensics-scope-form"), %{
        "scope" => %{
          "evidence_type" => "incident",
          "incident_fingerprint" => "dead_executor:ops-1",
          "view" => "active"
        }
      })

      refute_patch(view)
      assert has_element?(view, ~s(input[name="scope[incident_fingerprint]"]))
      assert has_element?(view, ~s(select[name="scope[view]"]))
      refute has_element?(view, ~s(input[name="scope[workflow_id]"]))
      refute has_element?(view, ~s(input[name="scope[resource_id]"]))

      render_change(element(view, "#forensics-scope-form"), %{
        "scope" => %{"evidence_type" => "cron", "resource_id" => "nightly-export"}
      })

      refute_patch(view)

      assert has_element?(
               view,
               ~s(input[name="scope[resource_id]"][value="nightly-export"])
             )

      refute has_element?(view, ~s(input[name="scope[workflow_id]"]))
      refute has_element?(view, ~s(input[name="scope[incident_fingerprint]"]))

      render_change(element(view, "#forensics-scope-form"), %{
        "scope" => %{"evidence_type" => "limiter", "resource_id" => "billing-api"}
      })

      refute_patch(view)
      assert has_element?(view, ~s(input[name="scope[resource_id]"][value="billing-api"]))
      refute has_element?(view, ~s(input[name="scope[workflow_id]"]))
      refute has_element?(view, ~s(input[name="scope[incident_fingerprint]"]))
    end

    test "valid submit patches only the canonical six-key URL scope", %{conn: conn} do
      cases = [
        {%{
           "evidence_type" => "workflow",
           "workflow_id" => "workflow/alpha",
           "step" => "sync billing"
         }, "/ops/jobs/forensics?workflow_id=workflow%2Falpha&step=sync+billing"},
        {%{
           "evidence_type" => "incident",
           "incident_fingerprint" => "dead_executor:node/1",
           "view" => "resolved"
         }, "/ops/jobs/forensics?incident_fingerprint=dead_executor%3Anode%2F1&view=resolved"},
        {%{"evidence_type" => "cron", "resource_id" => "nightly/export"},
         "/ops/jobs/forensics?resource_type=cron_entry&resource_id=nightly%2Fexport"},
        {%{"evidence_type" => "limiter", "resource_id" => "billing api"},
         "/ops/jobs/forensics?resource_type=limiter&resource_id=billing+api"}
      ]

      Enum.each(cases, fn {params, expected_path} ->
        {:ok, view, _html} = live(forensics_conn(conn), @bare_path)

        view
        |> element("#forensics-scope-form")
        |> render_submit(%{"scope" => params})

        assert_patch(view, expected_path)
        assert_selector_keys_allowed(expected_path)
      end)
    end

    test "invalid submit retains the draft and exposes associated errors without reading or patching",
         %{conn: conn} do
      {:ok, view, _html} = live(forensics_conn(conn), @bare_path)

      {html, queries} =
        capture_select_queries(fn ->
          render_submit(element(view, "#forensics-scope-form"), %{
            "scope" => %{
              "evidence_type" => "workflow",
              "workflow_id" => " ",
              "step" => "billing"
            }
          })
        end)

      assert queries == []
      refute_patch(view)
      assert html =~ "Choose evidence to inspect"
      assert html =~ "Enter a workflow ID."
      assert html =~ ~s(id="forensics-scope-errors")
      assert html =~ ~s(tabindex="-1")
      assert has_element?(view, ~s(input[name="scope[workflow_id]"][aria-invalid="true"]))
      assert has_element?(view, ~s(input[name="scope[workflow_id]"][aria-describedby]))
      assert has_element?(view, ~s(input[name="scope[step]"][value="billing"]))
    end

    test "invalid, conflicting, unknown, and oversized direct scopes replace to bare before reads",
         %{conn: conn} do
      paths = [
        "/ops/jobs/forensics?step=sync",
        "/ops/jobs/forensics?workflow_id=wf-1&incident_fingerprint=incident-1",
        "/ops/jobs/forensics?resource_type=unknown&resource_id=resource-1",
        "/ops/jobs/forensics?workflow_id=wf-1&surprise=true",
        "/ops/jobs/forensics?workflow_id=wf-1&step=sync&resource_type=workflow_step&resource_id=step-1&view=active&incident_fingerprint=incident-1&surprise=true"
      ]

      Enum.each(paths, fn path ->
        {:ok, view, _html} = live(forensics_conn(conn), @bare_path)

        {_html, queries} =
          capture_select_queries(fn -> render_patch(view, path) end)

        assert queries == []
        assert_patch(view, @bare_path)
        assert render(view) =~ "Choose one evidence type"
      end)
    end

    test "authorized-missing and unauthorized scopes have byte-equivalent unavailable output",
         %{conn: conn} do
      id = Ecto.UUID.generate()
      path = "#{@bare_path}?workflow_id=#{id}"

      {{:ok, authorized_view, _html}, authorized_queries} =
        capture_select_queries(fn ->
          live(forensics_conn(conn, [:view_workflows]), path)
        end)

      {{:ok, unauthorized_view, _html}, unauthorized_queries} =
        capture_select_queries(fn -> live(forensics_conn(conn), path) end)

      assert authorized_queries != []
      assert unauthorized_queries == []

      authorized_html = render(element(authorized_view, "#forensics-result-state"))
      unauthorized_html = render(element(unauthorized_view, "#forensics-result-state"))

      assert authorized_html == unauthorized_html
      assert authorized_html =~ "Evidence unavailable"

      assert authorized_html =~
               "It may not exist, may no longer be retained, or you may not have access."

      refute authorized_html =~ "<a "
    end

    test "cross-workflow step selectors match ordinary unavailable output and destinations",
         %{conn: conn} do
      {:ok, workflow_a} =
        WorkflowFixtures.workflow_fixture(name: "live-forensics-authorized-workflow")
        |> Workflow.insert(TestRepo)

      {:ok, workflow_b} =
        WorkflowFixtures.workflow_fixture(name: "live-forensics-foreign-workflow")
        |> Workflow.insert(TestRepo)

      step_a =
        TestRepo.get_by!(Step,
          workflow_id: workflow_a.id,
          step_name: "sync_billing"
        )

      step_b =
        TestRepo.get_by!(Step,
          workflow_id: workflow_b.id,
          step_name: "sync_billing"
        )

      {:ok, foreign_event} =
        Audit.record(
          "workflow.step_unblocked",
          %{type: :workflow_step, id: step_b.id},
          %{
            "event_type" => "workflow.step_unblocked",
            "reason" => "FOREIGN_LIVEVIEW_SENTINEL_NOTE"
          },
          repo: TestRepo,
          actor_id: "foreign-liveview-actor"
        )

      permissions = [:view_workflows, :view_audit, :view_lifeline]

      forged_path =
        "#{@bare_path}?resource_type=workflow_step&resource_id=#{step_b.id}" <>
          "&workflow_id=#{workflow_a.id}&step=#{step_a.step_name}"

      missing_path =
        "#{@bare_path}?resource_type=workflow_step&resource_id=#{Ecto.UUID.generate()}" <>
          "&workflow_id=#{workflow_a.id}&step=#{step_a.step_name}"

      {:ok, forged_view, forged_html} =
        live(forensics_conn(conn, permissions), forged_path)

      {:ok, missing_view, missing_html} =
        live(forensics_conn(conn, permissions), missing_path)

      forged_state = render(element(forged_view, "#forensics-result-state"))
      missing_state = render(element(missing_view, "#forensics-result-state"))

      assert forged_state == missing_state
      assert forged_state =~ "Evidence unavailable"

      assert forged_state =~
               "It may not exist, may no longer be retained, or you may not have access."

      assert destination_hrefs(forged_state) == destination_hrefs(missing_state)
      assert destination_hrefs(forged_state) == []

      for secret <- [
            foreign_event.action,
            foreign_event.actor_id,
            step_b.id,
            "FOREIGN_LIVEVIEW_SENTINEL_NOTE"
          ] do
        refute forged_html =~ secret
      end

      assert missing_html =~ "Evidence unavailable"
    end

    test "unauthorized page viewers are redirected", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, current_actor: %{id: "ops-2", permissions: []})
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, @bare_path)
    end

    test "draft identifiers are never copied into hidden persistence or browser storage", %{
      conn: conn
    } do
      {:ok, view, _html} = live(forensics_conn(conn), @bare_path)

      html =
        render_change(element(view, "#forensics-scope-form"), %{
          "scope" => %{
            "evidence_type" => "incident",
            "incident_fingerprint" => "unsafe-draft-80-07",
            "view" => "active"
          }
        })

      assert html =~ ~s(value="unsafe-draft-80-07")
      refute html =~ ~r/type="hidden"[^>]*unsafe-draft-80-07/
      refute html =~ "localStorage"
      refute html =~ "sessionStorage"
      refute html =~ "data-scope-value"
    end
  end

  describe "diagnosis-first page composition" do
    test "exports a pure closed page composition with exact hierarchy and shared data components" do
      assert function_exported?(ForensicsLive, :page_content, 1)

      {_html, queries} =
        capture_select_queries(fn ->
          html =
            render_component(
              &ForensicsLive.page_content/1,
              Map.put(ready_page_assigns(), :bundle, %{secret: "RAW-BUNDLE-SENTINEL"})
            )

          assert count(html, "<h1") == 1
          assert count(html, ~s(class="obpt-timeline")) == 1
          assert count(html, "<ol") == 1
          assert html =~ ~s(id="forensics-page" class="obpt-page obpt-forensics-page")
          assert html =~ ~s(class="obpt-description-list)
          assert html =~ ~s(<time class="obpt-timeline__time" datetime="#{now_iso()}">)
          assert html =~ "Inspect evidence"
          assert html =~ "Read-only evidence"

          assert_occurs_in_order(html, [
            "Read-only evidence",
            ~s(data-obpt-filter-bar),
            "Investigation summary",
            "What to do next",
            "Latest remediation evidence",
            "Event log",
            "Evidence limits and sources"
          ])

          assert_occurs_in_order(html, [
            "The newest retained event was recorded.",
            "An older retained event was recorded."
          ])

          for label <- [
                "Open workflow",
                "Review incident in Lifeline",
                "Open cron entry",
                "Review limiter blockers",
                "View matching audit evidence"
              ] do
            assert html =~ label
          end

          assert html =~ "Review all guidance"
          assert html =~ "Historical Lifeline repair evidence was recorded."
          assert html =~ "Showing 2 of 7 retained events."
          assert html =~ "Newest retained evidence in this source window."
          refute html =~ "RAW-BUNDLE-SENTINEL"

          for legacy <- [
                "Diagnosis Summary",
                "Related Evidence",
                "Linked Resources",
                "Legal Next Paths",
                "Evidence Completeness",
                "Selectors:"
              ] do
            refute html =~ legacy
          end

          html
        end)

      assert queries == []
    end

    test "pure empty and unavailable states render no diagnosis or event shells" do
      empty_html =
        render_component(
          &ForensicsLive.page_content/1,
          page_assigns(:empty)
        )

      assert empty_html =~ "Choose evidence to inspect."
      refute empty_html =~ "Investigation summary"
      refute empty_html =~ "What to do next"
      refute empty_html =~ "Event log"
      refute empty_html =~ "Evidence limits and sources"

      unavailable_html =
        render_component(
          &ForensicsLive.page_content/1,
          page_assigns(:unavailable)
        )

      assert unavailable_html =~ "Evidence unavailable"

      assert unavailable_html =~
               "It may not exist, may no longer be retained, or you may not have access."

      refute unavailable_html =~ "<a "
      refute unavailable_html =~ "Investigation summary"
      refute unavailable_html =~ "Event log"
    end

    test "ready live evidence renders one bounded timeline and only authorized destinations", %{
      conn: conn
    } do
      {:ok, entry} =
        Cron.sync_entry(TestRepo, %{
          name: "forensics-page-cron",
          source: "runtime",
          worker: "DemoWorker",
          queue: "default",
          expression: "* * * * *"
        })

      slot_at = truncate_minute(DateTime.add(DateTime.utc_now(), -120, :second))
      assert {:ok, _coverage} = Cron.record_coverage(TestRepo, entry, slot_at, status: "healthy")

      path = "#{@bare_path}?resource_type=cron_entry&resource_id=#{entry.name}"

      {:ok, reader_view, reader_html} =
        live(forensics_conn(conn, [:view_cron]), path)

      assert count(reader_html, ~s(class="obpt-timeline")) == 1
      assert has_element?(reader_view, "#forensics-event-log ol")
      assert reader_html =~ "Investigation summary"
      assert reader_html =~ "What to do next"
      assert reader_html =~ "Open cron entry"
      refute reader_html =~ "View matching audit evidence"

      {:ok, audit_view, audit_html} =
        live(forensics_conn(conn, [:view_cron, :view_audit]), path)

      assert has_element?(
               audit_view,
               "#forensics-evidence-coverage a",
               "View matching audit evidence"
             )

      assert audit_html =~ "View matching audit evidence"
      refute audit_html =~ "preview_token"
      refute audit_html =~ "plan_hash"
      refute audit_html =~ "raw_error"
    end
  end

  defp forensics_conn(conn, extra_permissions \\ []) do
    Plug.Test.init_test_session(conn,
      current_actor: %{
        id: "ops-1",
        permissions: [:view_forensics | extra_permissions]
      }
    )
  end

  defp capture_select_queries(fun) do
    handler_id = {__MODULE__, make_ref()}
    event = TestRepo.config() |> Keyword.fetch!(:telemetry_prefix) |> Kernel.++([:query])
    test_pid = self()
    query_ref = make_ref()

    :telemetry.attach(
      handler_id,
      event,
      fn _event, _measurements, metadata, {pid, ref} ->
        if String.starts_with?(metadata[:query] || "", "SELECT") do
          send(pid, {ref, Map.take(metadata, [:source, :query])})
        end
      end,
      {test_pid, query_ref}
    )

    try do
      result = fun.()
      {result, collect_select_queries(query_ref, [])}
    after
      :telemetry.detach(handler_id)
    end
  end

  defp collect_select_queries(query_ref, queries) do
    receive do
      {^query_ref, query} -> collect_select_queries(query_ref, [query | queries])
    after
      0 -> Enum.reverse(queries)
    end
  end

  defp refute_patch(%Phoenix.LiveViewTest.View{proxy: {ref, topic, _}}) do
    refute_receive {^ref, {:patch, ^topic, _}}
  end

  defp ready_page_assigns do
    now = "2026-07-28T16:00:00Z"
    older = "2026-07-28T15:00:00Z"

    page_assigns(:ready)
    |> Map.merge(%{
      summary: %{
        heading: "Investigation summary",
        diagnosis: "Needs review",
        detail: "The retained facts identify a current condition that needs review.",
        provenance: "Durable evidence",
        completeness: "Partial evidence",
        coverage: "Showing 2 of 7 retained events.",
        scope: %{
          type: :incident,
          type_label: "Lifeline incident",
          identity: "dead_executor:node-1",
          subject: "Missing executor node-1",
          ownership: "Powertools-native Lifeline"
        }
      },
      next_steps: [
        %{
          id: "open-workflow",
          label: "Open workflow",
          href: "/ops/jobs/workflows/workflow-1",
          role: :primary,
          support: "Review the current workflow diagnosis before taking any action."
        },
        %{
          id: "review-incident-in-lifeline",
          label: "Review incident in Lifeline",
          href: "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Anode-1",
          role: :additional,
          support:
            "Review current evidence and reauthorize the incident before taking any action."
        },
        %{
          id: "open-cron-entry",
          label: "Open cron entry",
          href: "/ops/jobs/cron?entry=nightly",
          role: :additional,
          support: "Review current schedule evidence before taking any action."
        },
        %{
          id: "review-limiter-blockers",
          label: "Review limiter blockers",
          href: "/ops/jobs/limiters?resource=billing",
          role: :additional,
          support: "Review current blocker evidence before taking any action."
        }
      ],
      latest_remediation: %{
        heading: "Latest remediation evidence",
        historical?: true,
        status: "Recorded",
        summary: "Historical Lifeline repair evidence was recorded.",
        occurred_at: "July 28, 2026 at 15:30 UTC",
        occurred_datetime: "2026-07-28T15:30:00Z",
        provenance: "Durable evidence"
      },
      events: [
        %{
          id: "event-newest",
          timestamp: "July 28, 2026 at 16:00 UTC",
          datetime: now,
          title: "The newest retained event was recorded.",
          source: "Powertools Audit · Durable evidence",
          status: "Needs review",
          domain: :forensics,
          state: :needs_review,
          notes: "Newest retained evidence in this source window.",
          follow_ups: [
            %{label: "Open workflow", href: "/ops/jobs/workflows/workflow-1"}
          ]
        },
        %{
          id: "event-older",
          timestamp: "July 28, 2026 at 15:00 UTC",
          datetime: older,
          title: "An older retained event was recorded.",
          source: "Powertools Lifeline · Supporting evidence",
          status: "Recorded",
          domain: :forensics,
          state: :recorded,
          notes: nil,
          follow_ups: [
            %{
              label: "Review incident in Lifeline",
              href: "/ops/jobs/lifeline?incident_fingerprint=dead_executor%3Anode-1"
            }
          ]
        }
      ],
      coverage: %{
        heading: "Evidence limits and sources",
        summary: "Showing 2 of 7 retained events.",
        shown_count: 2,
        total_count: 7,
        has_more?: false,
        bounded?: true,
        completeness: "Partial evidence",
        retention: "Only the newest retained evidence available to these sources is shown.",
        sources: [
          %{
            id: "audit",
            label: "Powertools Audit",
            shown_count: 2,
            total_count: 7,
            has_more?: false,
            limit: 50,
            provenance: "Durable evidence",
            completeness: "Partial evidence",
            retention: "Newest 50 matching retained events."
          }
        ]
      },
      audit_href: "/ops/jobs/audit?resource_type=incident&resource_id=dead_executor%3Anode-1"
    })
  end

  defp page_assigns(state) do
    %{
      scope_form:
        Phoenix.Component.to_form(
          %{
            "evidence_type" => "",
            "workflow_id" => "",
            "step" => "",
            "incident_fingerprint" => "",
            "view" => "",
            "resource_id" => ""
          },
          as: :scope,
          id: "forensics-scope-form"
        ),
      scope_state: state,
      scope_notice: nil,
      support: %{
        state: :ready,
        heading: "Read-only evidence",
        copy: "Forensics summarizes retained Powertools evidence and does not prove root cause."
      },
      summary: nil,
      next_steps: [],
      latest_remediation: nil,
      events: [],
      coverage: nil,
      audit_href: nil
    }
  end

  defp assert_selector_keys_allowed(path) do
    parsed = URI.parse(path)
    keys = parsed.query |> URI.decode_query() |> Map.keys() |> MapSet.new()

    assert MapSet.subset?(keys, @allowed_selector_keys)
  end

  defp assert_occurs_in_order(text, markers) do
    positions =
      Enum.map(markers, fn marker ->
        case :binary.match(text, marker) do
          {position, _length} -> position
          :nomatch -> flunk("expected #{inspect(marker)} in rendered Forensics HTML")
        end
      end)

    assert positions == Enum.sort(positions)
  end

  defp destination_hrefs(html) do
    Regex.scan(~r/href="([^"]+)"/, html, capture: :all_but_first)
    |> List.flatten()
  end

  defp truncate_minute(%DateTime{} = dt),
    do: %DateTime{dt | second: 0, microsecond: {0, 0}}

  defp now_iso, do: "2026-07-28T16:00:00Z"
  defp count(text, needle), do: length(String.split(text, needle)) - 1
end
