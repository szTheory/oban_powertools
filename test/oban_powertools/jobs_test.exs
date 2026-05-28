defmodule ObanPowertools.JobsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Jobs, TestRepo}

  # -------------------------------------------------------------------------
  # list/3
  # -------------------------------------------------------------------------

  test "list/3 filters by state with state leading the WHERE clause" do
    available_job = insert_job!(%{}, worker: "MyApp.AvailableWorker", queue: :default)
    _executing_job = insert_job!(%{}, worker: "MyApp.ExecutingWorker", queue: :default, state: "executing")

    result = Jobs.list(TestRepo, %Jobs{state: :available})

    assert length(result) == 1
    assert hd(result).id == available_job.id
    assert hd(result).state == "available"
  end

  test "list/3 narrows by queue" do
    default_job = insert_job!(%{}, worker: "MyApp.Worker", queue: :default)
    _other_job = insert_job!(%{}, worker: "MyApp.Worker", queue: :other)

    result = Jobs.list(TestRepo, %Jobs{state: :available, queue: "default"})

    assert length(result) == 1
    assert hd(result).id == default_job.id
  end

  test "list/3 narrows by worker" do
    target_job = insert_job!(%{}, worker: "MyApp.TargetWorker", queue: :default)
    _other_job = insert_job!(%{}, worker: "MyApp.OtherWorker", queue: :default)

    result = Jobs.list(TestRepo, %Jobs{state: :available, worker: "MyApp.TargetWorker"})

    assert length(result) == 1
    assert hd(result).id == target_job.id
  end

  test "list/3 narrows by tags via @> array contains" do
    tagged_job = insert_job!(%{}, worker: "MyApp.Worker", queue: :default, tags: ["alpha", "beta"])
    _untagged_job = insert_job!(%{}, worker: "MyApp.Worker", queue: :default, tags: ["gamma"])

    result = Jobs.list(TestRepo, %Jobs{state: :available, tags: ["alpha"]})

    assert length(result) == 1
    assert hd(result).id == tagged_job.id
  end

  test "list/3 orders by scheduled_at DESC, id DESC" do
    # Insert two jobs with the same scheduled_at; the higher id should come first
    fixed_time = DateTime.truncate(DateTime.utc_now(), :microsecond)

    job_a =
      %{}
      |> Oban.Job.new(worker: "MyApp.Worker", queue: :default)
      |> Ecto.Changeset.change(scheduled_at: fixed_time)
      |> TestRepo.insert!()

    job_b =
      %{}
      |> Oban.Job.new(worker: "MyApp.Worker", queue: :default)
      |> Ecto.Changeset.change(scheduled_at: fixed_time)
      |> TestRepo.insert!()

    # job_b has higher id (inserted second)
    assert job_b.id > job_a.id

    result = Jobs.list(TestRepo, %Jobs{state: :available})

    ids = Enum.map(result, & &1.id)
    job_b_pos = Enum.find_index(ids, &(&1 == job_b.id))
    job_a_pos = Enum.find_index(ids, &(&1 == job_a.id))

    assert job_b_pos < job_a_pos, "Expected higher id (#{job_b.id}) to appear before lower id (#{job_a.id})"
  end

  test "list/3 paginates by page/page_size" do
    _j1 = insert_job!(%{}, worker: "MyApp.Worker", queue: :default)
    _j2 = insert_job!(%{}, worker: "MyApp.Worker", queue: :default)
    _j3 = insert_job!(%{}, worker: "MyApp.Worker", queue: :default)

    page1 = Jobs.list(TestRepo, %Jobs{state: :available, page: 1, page_size: 2})
    page2 = Jobs.list(TestRepo, %Jobs{state: :available, page: 2, page_size: 2})

    assert length(page1) == 2
    assert length(page2) == 1

    page1_ids = MapSet.new(page1, & &1.id)
    page2_ids = MapSet.new(page2, & &1.id)
    assert MapSet.disjoint?(page1_ids, page2_ids), "Pages should not overlap"
  end

  # -------------------------------------------------------------------------
  # get/2
  # -------------------------------------------------------------------------

  test "get/2 returns job by id, nil when not found" do
    job = insert_job!(%{}, worker: "MyApp.Worker", queue: :default)

    found = Jobs.get(TestRepo, job.id)
    assert %Oban.Job{} = found
    assert found.id == job.id

    assert nil == Jobs.get(TestRepo, 999_999_999)
  end

  # -------------------------------------------------------------------------
  # count_by_state/2
  # -------------------------------------------------------------------------

  test "count_by_state/2 returns map with all 7 state keys including zero counts" do
    insert_job!(%{}, worker: "MyApp.Worker", queue: :default)
    insert_job!(%{}, worker: "MyApp.Worker", queue: :default)
    insert_job!(%{}, worker: "MyApp.Worker", queue: :default, state: "executing")

    counts = Jobs.count_by_state(TestRepo, %Jobs{})

    assert Map.keys(counts) |> Enum.sort() ==
             ["available", "cancelled", "completed", "discarded", "executing", "retryable", "scheduled"]

    assert counts["available"] == 2
    assert counts["executing"] == 1
    assert counts["scheduled"] == 0
    assert counts["retryable"] == 0
    assert counts["cancelled"] == 0
    assert counts["discarded"] == 0
    assert counts["completed"] == 0
  end

  test "count_by_state/2 honors non-state filters from base_filter" do
    insert_job!(%{}, worker: "MyApp.Worker", queue: :default)
    insert_job!(%{}, worker: "MyApp.Worker", queue: :other)

    counts = Jobs.count_by_state(TestRepo, %Jobs{queue: "default"})

    assert counts["available"] == 1
    # state field in base_filter is ignored; other queues not counted
    counts_other = Jobs.count_by_state(TestRepo, %Jobs{queue: "other"})
    assert counts_other["available"] == 1
  end

  # -------------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------------

  defp insert_job!(args, opts) do
    {state, opts} = Keyword.pop(opts, :state, "available")

    job =
      args
      |> Oban.Job.new(opts)
      |> TestRepo.insert!()

    if state == "available" do
      job
    else
      job
      |> Ecto.Changeset.change(state: state)
      |> TestRepo.update!()
    end
  end
end
