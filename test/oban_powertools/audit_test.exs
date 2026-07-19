defmodule ObanPowertools.AuditTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Audit, TestRepo}

  @page_fields ~w[events total_count page page_size total_pages previous? next?]a

  @tag phase79_slice: "shared"
  test "page/2 returns fixed reachable 20-row pages with exact navigation metadata" do
    inserted_at = ~N[2026-07-19 12:00:00]

    events =
      for index <- 1..45 do
        insert_audit!(
          "job.reviewed",
          %{type: :job, id: "job-#{index}"},
          inserted_at
        )
      end

    page_1 = page(%{}, page: 1)
    page_2 = page(%{}, page: 2)
    page_3 = page(%{}, page: 3)

    assert Map.keys(page_1) |> Enum.sort() == Enum.sort(@page_fields)
    assert {length(page_1.events), length(page_2.events), length(page_3.events)} == {20, 20, 5}

    assert {page_1.total_count, page_1.page_size, page_1.total_pages} == {45, 20, 3}
    assert {page_1.page, page_1.previous?, page_1.next?} == {1, false, true}
    assert {page_2.page, page_2.previous?, page_2.next?} == {2, true, true}
    assert {page_3.page, page_3.previous?, page_3.next?} == {3, true, false}

    reachable_ids =
      [page_1, page_2, page_3]
      |> Enum.flat_map(& &1.events)
      |> Enum.map(& &1.id)

    assert MapSet.new(reachable_ids) == MapSet.new(events, & &1.id)
    assert length(Enum.uniq(reachable_ids)) == 45
  end

  @tag phase79_slice: "shared"
  test "page/2 orders timestamp ties by descending id on repeat reads" do
    inserted_at = ~N[2026-07-19 12:30:00]

    events =
      for index <- 1..8 do
        insert_audit!(
          "cron.previewed",
          %{type: :cron_entry, id: "entry-#{index}"},
          inserted_at
        )
      end

    expected_ids = events |> Enum.map(& &1.id) |> Enum.sort(:desc)

    assert Enum.map(page(%{}).events, & &1.id) == expected_ids
    assert Enum.map(page(%{}).events, & &1.id) == expected_ids

    assert Audit.list_all(repo: TestRepo) |> Enum.map(& &1.id) == expected_ids

    assert Audit.list_all(%{"event_type" => "cron.previewed"}, repo: TestRepo)
           |> Enum.map(& &1.id) == expected_ids
  end

  @tag phase79_slice: "shared"
  test "page/2 applies the exact existing filters to both count and rows" do
    inserted_at = ~N[2026-07-19 13:00:00]

    matching =
      for index <- 1..3 do
        insert_audit!(
          "lifeline.repair_executed",
          %{type: :job, id: "job-123"},
          inserted_at,
          actor_id: "operator-#{index}"
        )
      end

    insert_audit!(
      "lifeline.repair_executed",
      %{type: :job, id: "job-999"},
      inserted_at
    )

    insert_audit!(
      "lifeline.repair_executed",
      %{type: :workflow, id: "job-123"},
      inserted_at
    )

    insert_audit!("cron.paused", %{type: :job, id: "job-123"}, inserted_at)

    filters = %{
      "resource_type" => "job",
      "resource_id" => "job-123",
      "event_type" => "lifeline.repair_executed",
      "unsupported" => "must-not-change-the-approved-scope"
    }

    result = page(filters)

    assert result.total_count == 3
    assert Enum.map(result.events, & &1.id) == matching |> Enum.map(& &1.id) |> Enum.sort(:desc)

    assert Enum.all?(result.events, fn event ->
             event.resource_type == "job" and event.resource_id == "job-123" and
               event.event_type == "lifeline.repair_executed"
           end)
  end

  @tag phase79_slice: "shared"
  test "page/2 normalizes invalid pages and clamps excessive pages to the last real page" do
    inserted_at = ~N[2026-07-19 13:30:00]

    for index <- 1..21 do
      insert_audit!("job.reviewed", %{type: :job, id: "job-#{index}"}, inserted_at)
    end

    assert page(%{}).page == 1

    for invalid <- [nil, "", "not-a-page", 0, -7] do
      result = page(%{}, page: invalid)

      assert {result.page, length(result.events), result.previous?, result.next?} ==
               {1, 20, false, true}
    end

    excessive = page(%{}, page: 99)
    assert {excessive.page, excessive.total_pages, length(excessive.events)} == {2, 2, 1}
    assert excessive.previous?
    refute excessive.next?

    empty = page(%{"resource_id" => "missing"}, page: 99)
    assert {empty.page, empty.total_count, empty.total_pages, empty.events} == {1, 0, 0, []}
    refute empty.previous?
    refute empty.next?
  end

  @tag phase79_slice: "audit"
  test "fetch_in_scope/3 resolves one id inside every exact filter and fails closed in one query" do
    inserted_at = ~N[2026-07-19 14:00:00]

    matching =
      insert_audit!(
        "lifeline.repair_executed",
        %{type: :job, id: "job-123"},
        inserted_at
      )

    other_resource =
      insert_audit!(
        "lifeline.repair_executed",
        %{type: :job, id: "job-999"},
        inserted_at
      )

    filters = %{
      "resource_type" => "job",
      "resource_id" => "job-123",
      "event_type" => "lifeline.repair_executed"
    }

    assert {{:ok, %Audit{id: id}}, 1} =
             capture_audit_queries(fn -> fetch(filters, matching.id) end)

    assert id == matching.id

    assert {:error, 1} = capture_audit_queries(fn -> fetch(filters, other_resource.id) end)

    for mismatched_filters <- [
          Map.put(filters, "resource_type", "workflow"),
          Map.put(filters, "resource_id", "other-job"),
          Map.put(filters, "event_type", "cron.paused")
        ] do
      assert :error = fetch(mismatched_filters, matching.id)
    end

    for malformed <- [nil, "", 0, -1, "not-an-id", "12.3", %{}] do
      assert :error = fetch(filters, malformed)
    end
  end

  defp page(filters, opts \\ []) do
    assert function_exported?(Audit, :page, 2),
           "Phase 79 requires Audit.page/2 bounded pagination"

    apply(Audit, :page, [filters, Keyword.put(opts, :repo, TestRepo)])
  end

  defp fetch(filters, id) do
    assert function_exported?(Audit, :fetch_in_scope, 3),
           "Phase 79 requires Audit.fetch_in_scope/3 filter-scoped lookup"

    apply(Audit, :fetch_in_scope, [filters, id, [repo: TestRepo]])
  end

  defp capture_audit_queries(fun) do
    handler_id = {__MODULE__, make_ref()}
    event = TestRepo.config() |> Keyword.fetch!(:telemetry_prefix) |> Kernel.++([:query])
    test_pid = self()

    :telemetry.attach(
      handler_id,
      event,
      fn _event, _measurements, metadata, pid ->
        if metadata[:source] == "oban_powertools_audit_events" do
          send(pid, :audit_query)
        end
      end,
      test_pid
    )

    try do
      result = fun.()
      {result, collect_audit_queries(0)}
    after
      :telemetry.detach(handler_id)
    end
  end

  defp collect_audit_queries(count) do
    receive do
      :audit_query -> collect_audit_queries(count + 1)
    after
      0 -> count
    end
  end

  defp insert_audit!(action, resource, inserted_at, opts \\ []) do
    actor_id = Keyword.get(opts, :actor_id, "operator-1")

    {:ok, event} =
      Audit.record(
        action,
        resource,
        %{"event_type" => action, "reason" => "bounded page contract"},
        repo: TestRepo,
        actor_id: actor_id
      )

    event
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> TestRepo.update!()
  end
end
