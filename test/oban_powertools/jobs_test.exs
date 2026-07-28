defmodule ObanPowertools.JobsTest do
  use ObanPowertools.DataCase, async: false

  alias ObanPowertools.{Jobs, TestRepo}

  # -------------------------------------------------------------------------
  # list/3
  # -------------------------------------------------------------------------

  test "list/3 filters by active state" do
    available_job = insert_job!(%{}, worker: "MyApp.AvailableWorker", queue: :default)

    _executing_job =
      insert_job!(%{}, worker: "MyApp.ExecutingWorker", queue: :default, state: "executing")

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

  test "list/3 requires every requested tag via @> array containment" do
    tagged_job =
      insert_job!(%{},
        worker: "MyApp.Worker",
        queue: :default,
        tags: ["alpha", "beta", "queue:critical"]
      )

    _partial_job =
      insert_job!(%{}, worker: "MyApp.Worker", queue: :default, tags: ["alpha"])

    result =
      Jobs.list(TestRepo, %Jobs{
        state: :available,
        tags: ["alpha", "beta", "queue:critical"]
      })

    assert Enum.map(result, & &1.id) == [tagged_job.id]
  end

  test "list/3 narrows by args via @> jsonb contains" do
    job_with_args =
      insert_job!(%{"account_id" => 123, "type" => "export"},
        worker: "MyApp.Worker",
        queue: :default
      )

    _job_without_args =
      insert_job!(%{"account_id" => 456, "type" => "export"},
        worker: "MyApp.Worker",
        queue: :default
      )

    result = Jobs.list(TestRepo, %Jobs{state: :available, args: %{"account_id" => 123}})

    assert length(result) == 1
    assert hd(result).id == job_with_args.id
  end

  test "list/3 narrows by meta via @> jsonb contains" do
    job_with_meta =
      %{"id" => 1}
      |> Oban.Job.new(
        worker: "MyApp.Worker",
        queue: :default,
        meta: %{"batch_id" => "b_123", "group" => "a"}
      )
      |> TestRepo.insert!()

    _job_without_meta =
      %{"id" => 2}
      |> Oban.Job.new(
        worker: "MyApp.Worker",
        queue: :default,
        meta: %{"batch_id" => "b_456", "group" => "a"}
      )
      |> TestRepo.insert!()

    result = Jobs.list(TestRepo, %Jobs{state: :available, meta: %{"batch_id" => "b_123"}})

    assert length(result) == 1
    assert hd(result).id == job_with_meta.id
  end

  test "list, count, and ordered ids AND the same optional literal predicates" do
    fixed_time = ~U[2026-07-27 20:00:00.000000Z]

    matching =
      insert_job_at!(
        %{"account_id" => 123, "kind" => "export"},
        fixed_time,
        worker: "MyApp.TargetWorker",
        queue: :default,
        tags: ["alpha", "beta", "worker:other.module"],
        meta: %{"region" => "us", "attempt" => 1}
      )

    _wrong_queue =
      insert_job_at!(
        %{"account_id" => 123, "kind" => "export"},
        fixed_time,
        worker: "MyApp.TargetWorker",
        queue: :other,
        tags: ["alpha", "beta", "worker:other.module"],
        meta: %{"region" => "us", "attempt" => 1}
      )

    _missing_tag =
      insert_job_at!(
        %{"account_id" => 123, "kind" => "export"},
        fixed_time,
        worker: "MyApp.TargetWorker",
        queue: :default,
        tags: ["alpha", "worker:other.module"],
        meta: %{"region" => "us", "attempt" => 1}
      )

    _wrong_args =
      insert_job_at!(
        %{"account_id" => 456, "kind" => "export"},
        fixed_time,
        worker: "MyApp.TargetWorker",
        queue: :default,
        tags: ["alpha", "beta", "worker:other.module"],
        meta: %{"region" => "us", "attempt" => 1}
      )

    _wrong_meta =
      insert_job_at!(
        %{"account_id" => 123, "kind" => "export"},
        fixed_time,
        worker: "MyApp.TargetWorker",
        queue: :default,
        tags: ["alpha", "beta", "worker:other.module"],
        meta: %{"region" => "eu", "attempt" => 1}
      )

    filter = %Jobs{
      state: :available,
      queue: "default",
      worker: "MyApp.TargetWorker",
      tags: ["alpha", "beta", "worker:other.module"],
      args: %{"account_id" => 123},
      meta: %{"region" => "us"}
    }

    assert Enum.map(Jobs.list(TestRepo, filter), & &1.id) == [matching.id]
    assert Jobs.count(TestRepo, filter, []) == 1
    assert Jobs.count_by_state(TestRepo, filter, [])["available"] == 1

    assert Jobs.ordered_ids_window(TestRepo, filter, 20, []) == %{
             ids: [matching.id],
             overflow?: false
           }
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

    assert job_b_pos < job_a_pos,
           "Expected higher id (#{job_b.id}) to appear before lower id (#{job_a.id})"
  end

  test "list/3 keeps fixed non-overlapping 20-row offset pages with stable ties" do
    fixed_time = ~U[2026-07-27 20:30:00.000000Z]

    jobs =
      for _index <- 1..41 do
        insert_job_at!(%{}, fixed_time, worker: "MyApp.Worker", queue: :default)
      end

    expected_ids = jobs |> Enum.map(& &1.id) |> Enum.sort(:desc)

    page1 = Jobs.list(TestRepo, %Jobs{state: :available, page: 1})
    page2 = Jobs.list(TestRepo, %Jobs{state: :available, page: 2})
    page3 = Jobs.list(TestRepo, %Jobs{state: :available, page: 3})

    assert Enum.map(page1, & &1.id) == Enum.slice(expected_ids, 0, 20)
    assert Enum.map(page2, & &1.id) == Enum.slice(expected_ids, 20, 20)
    assert Enum.map(page3, & &1.id) == Enum.slice(expected_ids, 40, 1)

    assert [page1, page2, page3]
           |> Enum.flat_map(&Enum.map(&1, fn job -> job.id end))
           |> Enum.uniq()
           |> length() == 41
  end

  # -------------------------------------------------------------------------
  # count/3 and ordered_ids_window/4
  # -------------------------------------------------------------------------

  test "count/3 returns the exact active-state filtered count" do
    insert_job!(%{"account_id" => 123}, worker: "MyApp.Worker", queue: :default)
    insert_job!(%{"account_id" => 123}, worker: "MyApp.Worker", queue: :default)
    insert_job!(%{"account_id" => 456}, worker: "MyApp.Worker", queue: :default)

    insert_job!(%{"account_id" => 123},
      worker: "MyApp.Worker",
      queue: :default,
      state: "executing"
    )

    filter = %Jobs{state: :available, queue: "default", args: %{"account_id" => 123}}

    assert Jobs.count(TestRepo, filter, []) == 2
  end

  test "ordered_ids_window/4 returns at most limit stable ids plus overflow truth" do
    fixed_time = ~U[2026-07-27 21:00:00.000000Z]

    jobs =
      for _index <- 1..21 do
        insert_job_at!(%{}, fixed_time, worker: "MyApp.Worker", queue: :default)
      end

    expected_ids = jobs |> Enum.map(& &1.id) |> Enum.sort(:desc)

    assert Jobs.ordered_ids_window(TestRepo, %Jobs{state: :available}, 20, []) == %{
             ids: Enum.take(expected_ids, 20),
             overflow?: true
           }

    assert_raise ArgumentError, "limit must be a positive integer", fn ->
      Jobs.ordered_ids_window(TestRepo, %Jobs{}, 0, [])
    end
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
             [
               "available",
               "cancelled",
               "completed",
               "discarded",
               "executing",
               "retryable",
               "scheduled"
             ]

    assert counts["available"] == 2
    assert counts["executing"] == 1
    assert counts["scheduled"] == 0
    assert counts["retryable"] == 0
    assert counts["cancelled"] == 0
    assert counts["discarded"] == 0
    assert counts["completed"] == 0
  end

  test "count_by_state/2 honors non-state filters from base_filter" do
    insert_job!(%{"account_id" => 123}, worker: "MyApp.Worker", queue: :default)
    insert_job!(%{"account_id" => 456}, worker: "MyApp.Worker", queue: :other)

    %{"id" => 1}
    |> Oban.Job.new(worker: "MyApp.Worker", queue: :default, meta: %{"batch_id" => "b_123"})
    |> TestRepo.insert!()

    counts = Jobs.count_by_state(TestRepo, %Jobs{queue: "default"})

    assert counts["available"] == 2
    # state field in base_filter is ignored; other queues not counted
    counts_other = Jobs.count_by_state(TestRepo, %Jobs{queue: "other"})
    assert counts_other["available"] == 1

    counts_args = Jobs.count_by_state(TestRepo, %Jobs{args: %{"account_id" => 123}})
    assert counts_args["available"] == 1

    counts_meta = Jobs.count_by_state(TestRepo, %Jobs{meta: %{"batch_id" => "b_123"}})
    assert counts_meta["available"] == 1
  end

  test "count_by_state/3 executes one grouped count query and fills all seven states" do
    insert_job!(%{}, worker: "MyApp.Worker", queue: :default)
    insert_job!(%{}, worker: "MyApp.Worker", queue: :default, state: "executing")
    insert_job!(%{}, worker: "MyApp.Worker", queue: :other, state: "retryable")

    {counts, queries} =
      capture_job_queries(fn ->
        Jobs.count_by_state(TestRepo, %Jobs{queue: "default"}, [])
      end)

    assert length(queries) == 1
    assert hd(queries) =~ ~r/GROUP BY .*state/
    assert counts["available"] == 1
    assert counts["executing"] == 1
    assert counts["retryable"] == 0

    assert Map.keys(counts) |> Enum.sort() ==
             ~w(available cancelled completed discarded executing retryable scheduled)
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

  defp insert_job_at!(args, scheduled_at, opts) do
    args
    |> Oban.Job.new(opts)
    |> Ecto.Changeset.change(scheduled_at: scheduled_at)
    |> TestRepo.insert!()
  end

  defp capture_job_queries(fun) do
    handler_id = {__MODULE__, make_ref()}
    event = TestRepo.config() |> Keyword.fetch!(:telemetry_prefix) |> Kernel.++([:query])
    test_pid = self()

    :telemetry.attach(
      handler_id,
      event,
      fn _event, _measurements, metadata, pid ->
        if metadata[:source] == "oban_jobs" and
             String.starts_with?(metadata[:query] || "", "SELECT") do
          send(pid, {:job_query, metadata.query})
        end
      end,
      test_pid
    )

    try do
      result = fun.()
      {result, collect_job_queries([])}
    after
      :telemetry.detach(handler_id)
    end
  end

  defp collect_job_queries(queries) do
    receive do
      {:job_query, query} -> collect_job_queries([query | queries])
    after
      0 -> Enum.reverse(queries)
    end
  end
end
