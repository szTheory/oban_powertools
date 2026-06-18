defmodule PhoenixHostWeb.ObanPowertoolsThemeIsolationTest do
  use PhoenixHostWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias PhoenixHost.Repo

  test "host home page stays free of Powertools theme root and assets", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "Peace of mind from prototype to production"
    refute html =~ "obpt-root"
    refute html =~ "/ops/jobs/_assets/"
    refute html =~ "oban_powertools:theme"
    refute html =~ "_showcase"
    refute html =~ "data-obpt-showcase"
    refute html =~ "data-obpt-theme-choice"
    refute html =~ "data-obpt-viewport"
    refute html =~ "data-obpt-open-state-target"
  end

  test "Powertools jobs page owns the scoped theme root and md5 assets", %{conn: conn} do
    insert_job!()

    actor = PhoenixHostWeb.ObanPowertoolsAuth.demo_actor()
    conn = Plug.Test.init_test_session(conn, %{"ops_actor" => actor})

    {:ok, _view, html} = live(conn, "/ops/jobs/jobs?state=available")

    assert count(html, "obpt-root") == 1
    assert html =~ ~s(data-obpt-theme="system")
    assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.css|
    assert html =~ ~r|/ops/jobs/_assets/oban_powertools-[a-f0-9]{32}\.js|
    assert html =~ "obpt-tab"
    assert html =~ "obpt-tab--active"
    assert html =~ "obpt-badge"
    assert html =~ ~s(data-obpt-tone="neutral")
    refute html =~ ~s(<html class="dark")
    refute html =~ ~s(data-theme=)
    refute html =~ "localStorage.theme"
  end

  defp count(html, needle) do
    html
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end

  defp insert_job! do
    %{}
    |> Oban.Job.new(worker: "PhoenixHost.Worker", queue: :default)
    |> Repo.insert!()
  end
end
