defmodule ObanPowertools.Web.JobsParamsTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Jobs
  alias ObanPowertools.Web.{JobsParams, Selectors}

  @states ~w(available scheduled executing retryable cancelled discarded completed)
  @state_atoms ~w(available scheduled executing retryable cancelled discarded completed)a
  @tag_help "Separate tags with commas. Jobs must contain every listed tag."
  @json_help "Enter a JSON object. Filter values are stored in the URL; do not enter secrets."
  @json_error "Enter a valid JSON object."
  @invalid_url_notice "The invalid filter values were removed. Review the applied filters and try again."

  test "parse_url/1 defaults missing state before a caller can query" do
    assert JobsParams.parse_url(%{}) == %{
             query: %Jobs{state: :available, page: 1, page_size: 20},
             canonical_params: [{"state", "available"}],
             quick_review_id: nil,
             replace?: true,
             notices: []
           }
  end

  test "parse_url/1 accepts all seven compile-time states" do
    for {state, state_atom} <- Enum.zip(@states, @state_atoms) do
      parsed = JobsParams.parse_url(%{"state" => state})

      assert parsed.query.state == state_atom
      assert parsed.canonical_params == [{"state", state}]
      refute parsed.replace?
      assert parsed.notices == []
    end
  end

  test "valid applied URLs round-trip byte-stably in closed order with review separate" do
    params = %{
      "job" => "42",
      "meta" => ~s({"region":"us"}),
      "page" => "3",
      "args" => ~s({"account_id":123}),
      "tags" => "alpha,worker:other.module",
      "worker" => "MyApp.Worker",
      "queue" => "critical",
      "state" => "retryable"
    }

    parsed = JobsParams.parse_url(params)

    assert parsed.query == %Jobs{
             state: :retryable,
             queue: "critical",
             worker: "MyApp.Worker",
             tags: ["alpha", "worker:other.module"],
             args: %{"account_id" => 123},
             meta: %{"region" => "us"},
             page: 3,
             page_size: 20
           }

    assert parsed.canonical_params == [
             {"state", "retryable"},
             {"queue", "critical"},
             {"worker", "MyApp.Worker"},
             {"tags", "alpha,worker:other.module"},
             {"args", ~s({"account_id":123})},
             {"meta", ~s({"region":"us"})},
             {"page", "3"},
             {"job", "42"}
           ]

    assert parsed.quick_review_id == 42
    refute parsed.replace?
    assert parsed.notices == []

    path = Selectors.jobs_path(parsed.canonical_params)
    reparsed = path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

    assert JobsParams.parse_url(reparsed) == parsed
    assert Selectors.jobs_path(JobsParams.parse_url(reparsed).canonical_params) == path
  end

  test "invalid direct values and unknown keys collapse to one safe finite replacement" do
    parsed =
      JobsParams.parse_url(%{
        "state" => "not-a-state",
        "queue" => "",
        "page" => "-2",
        "args" => "[1,2]",
        "meta" => "{broken",
        "job" => "12x",
        "return_to" => "https://evil.example/jobs?job=9",
        "unknown" => "state=executing&job=99"
      })

    assert parsed.query == %Jobs{state: :available, page: 1, page_size: 20}
    assert parsed.canonical_params == [{"state", "available"}]
    assert parsed.quick_review_id == nil
    assert parsed.replace?
    assert parsed.notices == [@invalid_url_notice]
  end

  test "page and job URL integers are bounded by their Postgrex bindings" do
    max_int64 = 9_223_372_036_854_775_807
    max_page = div(max_int64, 20) + 1

    for value <- [max_page, Integer.to_string(max_page)] do
      parsed = JobsParams.parse_url(%{"state" => "available", "page" => value})

      assert parsed.query.page == max_page

      assert parsed.canonical_params == [
               {"state", "available"},
               {"page", Integer.to_string(max_page)}
             ]

      assert parsed.notices == []
    end

    for value <- [max_int64, Integer.to_string(max_int64)] do
      parsed = JobsParams.parse_url(%{"state" => "available", "job" => value})

      assert parsed.quick_review_id == max_int64

      assert parsed.canonical_params == [
               {"state", "available"},
               {"job", Integer.to_string(max_int64)}
             ]

      assert parsed.notices == []
    end

    for params <- [
          %{"page" => max_page + 1},
          %{"page" => Integer.to_string(max_page + 1)},
          %{"page" => "99999999999999999999999999999999999999999999999999"},
          %{"job" => max_int64 + 1},
          %{"job" => Integer.to_string(max_int64 + 1)},
          %{"job" => "88888888888888888888888888888888888888888888888888"}
        ] do
      parsed = JobsParams.parse_url(Map.put(params, "state", "available"))

      assert parsed.query.page == 1
      assert parsed.quick_review_id == nil
      assert parsed.canonical_params == [{"state", "available"}]
      assert parsed.notices == [@invalid_url_notice]
      assert parsed.replace?
    end
  end

  test "JSON arrays, scalars, and null never become applied query values" do
    for invalid_json <- ["[]", ~s("secret"), "12", "true", "null"] do
      parsed =
        JobsParams.parse_url(%{
          "state" => "available",
          "args" => invalid_json,
          "meta" => invalid_json
        })

      assert parsed.query.args == nil
      assert parsed.query.meta == nil
      assert parsed.canonical_params == [{"state", "available"}]
      assert parsed.replace?
      assert parsed.notices == [@invalid_url_notice]
    end
  end

  test "validate_draft/1 retains original invalid strings and has no patch intent" do
    draft = %{
      "queue" => " critical ",
      "worker" => " MyApp.Worker ",
      "tags" => " alpha, queue:critical ",
      "args" => ~s({"account_id":123}),
      "meta" => "[\"not\", \"an\", \"object\"]"
    }

    validation = JobsParams.validate_draft(draft)

    assert validation.draft == draft
    refute validation.valid?
    refute validation.patch?
    assert validation.applied == nil
    assert validation.errors == %{meta: @json_error}
    assert validation.copy == %{tags_help: @tag_help, json_help: @json_help}
  end

  test "validate_draft/1 parses valid optional values without rewriting draft text" do
    draft = %{
      "queue" => " critical ",
      "worker" => " MyApp.Worker ",
      "tags" => " alpha, worker:other.module, beta ",
      "args" => ~s({"account_id":123}),
      "meta" => ~s({"region":"us"})
    }

    validation = JobsParams.validate_draft(draft)

    assert validation.draft == draft
    assert validation.valid?
    refute validation.patch?
    assert validation.errors == %{}

    assert validation.applied == %{
             queue: "critical",
             worker: "MyApp.Worker",
             tags: ["alpha", "worker:other.module", "beta"],
             args: %{"account_id" => 123},
             meta: %{"region" => "us"}
           }

    assert validation.copy == %{tags_help: @tag_help, json_help: @json_help}
  end

  test "filter_identity/1 is deterministic and excludes page and review identity" do
    first =
      JobsParams.parse_url(%{
        "state" => "retryable",
        "queue" => "critical",
        "worker" => "MyApp.Worker",
        "tags" => "alpha,worker:other.module",
        "args" => ~s({"account_id":123}),
        "meta" => ~s({"region":"us"}),
        "page" => "9",
        "job" => "42"
      })

    second =
      JobsParams.parse_url(%{
        "job" => "999",
        "page" => "2",
        "meta" => ~s({"region":"us"}),
        "args" => ~s({"account_id":123}),
        "tags" => "alpha,worker:other.module",
        "worker" => "MyApp.Worker",
        "queue" => "critical",
        "state" => "retryable"
      })

    expected =
      "state=retryable&queue=critical&worker=MyApp.Worker&tags=alpha%2Cworker%3Aother.module&args=%7B%22account_id%22%3A123%7D&meta=%7B%22region%22%3A%22us%22%7D"

    assert JobsParams.filter_identity(first.canonical_params) == expected
    assert JobsParams.filter_identity(second.canonical_params) == expected
    assert JobsParams.filter_identity(first.query) == expected
  end
end
