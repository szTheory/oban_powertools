defmodule ObanPowertools.Web.ForensicsLiveTest do
  use ObanPowertools.LiveCase, async: false

  alias ObanPowertools.TestRepo

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

  defp assert_selector_keys_allowed(path) do
    parsed = URI.parse(path)
    keys = parsed.query |> URI.decode_query() |> Map.keys() |> MapSet.new()

    assert MapSet.subset?(keys, @allowed_selector_keys)
  end

  defp count(text, needle), do: length(String.split(text, needle)) - 1
end
