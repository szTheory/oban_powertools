defmodule ObanPowertools.Web.SelectorsTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Web.Selectors

  test "maps each named destination to its canonical path" do
    assert Selectors.lifeline_path([]) == "/ops/jobs/lifeline"
    assert Selectors.forensic_path([]) == "/ops/jobs/forensics"
    assert Selectors.audit_path([]) == "/ops/jobs/audit"
    assert Selectors.limiter_path([]) == "/ops/jobs/limiters"
    assert Selectors.cron_path([]) == "/ops/jobs/cron"
    assert Selectors.jobs_path([]) == "/ops/jobs/jobs"
    assert Selectors.job_detail_path(42) == "/ops/jobs/jobs/42"
    assert Selectors.batches_path([]) == "/ops/jobs/batches"
    assert Selectors.batch_detail_path("batch-1") == "/ops/jobs/batches/batch-1"
  end

  test "drops nil and empty string values before encoding" do
    result =
      Selectors.lifeline_path([{"view", "active"}, {"incident_fingerprint", nil}, {"step", ""}])

    assert result == "/ops/jobs/lifeline?view=active"

    assert Selectors.batches_path([{"status", "callback_failed"}, {"query", ""}]) ==
             "/ops/jobs/batches?status=callback_failed"
  end

  test "returns bare path when no params survive filtering" do
    assert Selectors.forensic_path([{"incident_fingerprint", nil}]) == "/ops/jobs/forensics"
    assert Selectors.forensic_path([]) == "/ops/jobs/forensics"
  end

  test "Forensics URLs use exactly the six-key allowlist in canonical order" do
    path =
      Selectors.forensic_path(%{
        "view" => "resolved",
        "incident_fingerprint" => "incident:α/path?mode=full#one&two=three",
        "step" => "sync",
        "workflow_id" => "workflow-7",
        "resource_id" => "step-row-9",
        "resource_type" => "workflow_step",
        "seventh" => "discarded"
      })

    assert path ==
             "/ops/jobs/forensics?resource_type=workflow_step&resource_id=step-row-9&workflow_id=workflow-7&step=sync&incident_fingerprint=incident%3A%CE%B1%2Fpath%3Fmode%3Dfull%23one%26two%3Dthree&view=resolved"

    decoded = path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

    assert Map.keys(decoded) |> MapSet.new() ==
             MapSet.new(~w(resource_type resource_id workflow_id step incident_fingerprint view))

    refute path =~ "seventh"
  end

  test "Forensics URLs drop unknown and empty keys without retaining invalid selector values" do
    assert Selectors.forensic_path([
             {"resource_type", ""},
             {"resource_id", nil},
             {"workflow_id", ""},
             {"incident_fingerprint", ""},
             {"view", ""},
             {"conflicting_secret", "do-not-retain"}
           ]) == "/ops/jobs/forensics"
  end

  test "preserves keyword-list ordering in the encoded query" do
    result = Selectors.lifeline_path([{"view", "active"}, {"incident_fingerprint", "fp-123"}])
    assert result == "/ops/jobs/lifeline?view=active&incident_fingerprint=fp-123"

    # Reversed order
    result2 = Selectors.lifeline_path([{"incident_fingerprint", "fp-123"}, {"view", "active"}])
    assert result2 == "/ops/jobs/lifeline?incident_fingerprint=fp-123&view=active"

    result3 =
      Selectors.batches_path([
        {"status", "callback_failed"},
        {"query", "billing"},
        {"chain_only", "true"}
      ])

    assert result3 ==
             "/ops/jobs/batches?status=callback_failed&query=billing&chain_only=true"
  end

  test "encodes delimiter-heavy values (: / ? # % space & =) so they decode back to the original binary" do
    fingerprint = "dead_executor:exec/path?frag#tag with%20space&query=value"
    result = Selectors.lifeline_path([{"view", "active"}, {"incident_fingerprint", fingerprint}])

    assert String.starts_with?(result, "/ops/jobs/lifeline?")
    query_string = result |> String.split("?", parts: 2) |> List.last()
    decoded = URI.decode_query(query_string)
    assert decoded["incident_fingerprint"] == fingerprint
    assert decoded["view"] == "active"

    # Raw fingerprint must NOT appear unencoded
    refute result =~ "incident_fingerprint=dead_executor:exec/path"
  end

  test "accepts permissive non-canonical keys (row-id, action, entry, resource, event_type)" do
    result =
      Selectors.lifeline_path([
        {"view", "active"},
        {"incident_fingerprint", "fp-1"},
        {"row-id", "row-42"},
        {"action", "job_rescue"},
        {"entry", "nightly"},
        {"resource", "payments-api"},
        {"event_type", "lifeline.repair_executed"}
      ])

    assert result =~ "row-id="
    assert result =~ "action=job_rescue"
    assert result =~ "entry=nightly"
    assert result =~ "resource="
    assert result =~ "event_type="
  end

  @tag phase79_slice: "shared"
  test "keeps Cron entry and Limiter resource selectors first and delimiter-safe" do
    entry = "nightly:eu/west?attempt=1#manual%slot"
    resource = "tenant:alpha/billing?region=us east&mode=strict"

    assert Selectors.cron_path([{"entry", entry}]) ==
             "/ops/jobs/cron?entry=nightly%3Aeu%2Fwest%3Fattempt%3D1%23manual%25slot"

    assert Selectors.limiter_path([{"resource", resource}]) ==
             "/ops/jobs/limiters?resource=tenant%3Aalpha%2Fbilling%3Fregion%3Dus+east%26mode%3Dstrict"

    assert URI.decode_query(URI.parse(Selectors.cron_path([{"entry", entry}])).query) == %{
             "entry" => entry
           }

    assert URI.decode_query(URI.parse(Selectors.limiter_path([{"resource", resource}])).query) ==
             %{"resource" => resource}
  end

  @tag phase79_slice: "shared"
  test "keeps Audit filters, page, and selected event in literal canonical order" do
    resource_id = "job:123/attempt?view=full#evidence"
    event_id = "audit:41/selected?panel=detail"

    path =
      Selectors.audit_path([
        {"resource_type", "job"},
        {"resource_id", resource_id},
        {"event_type", "lifeline.repair_executed"},
        {"page", 3},
        {"event", event_id}
      ])

    assert path ==
             "/ops/jobs/audit?resource_type=job&resource_id=job%3A123%2Fattempt%3Fview%3Dfull%23evidence&event_type=lifeline.repair_executed&page=3&event=audit%3A41%2Fselected%3Fpanel%3Ddetail"

    assert URI.decode_query(URI.parse(path).query) == %{
             "resource_type" => "job",
             "resource_id" => resource_id,
             "event_type" => "lifeline.repair_executed",
             "page" => "3",
             "event" => event_id
           }
  end

  @tag phase79_slice: "shared"
  test "Audit selection removal and pagination links preserve the active exact filters" do
    filters = [
      {"resource_type", "workflow"},
      {"resource_id", "wf:alpha/beta"},
      {"event_type", "workflow.step_completed"}
    ]

    selected = Selectors.audit_path(filters ++ [{"page", 2}, {"event", "73"}])
    closed = Selectors.audit_path(filters ++ [{"page", 2}])
    previous = Selectors.audit_path(filters ++ [{"page", 1}])
    next = Selectors.audit_path(filters ++ [{"page", 3}])

    assert selected ==
             "/ops/jobs/audit?resource_type=workflow&resource_id=wf%3Aalpha%2Fbeta&event_type=workflow.step_completed&page=2&event=73"

    assert closed ==
             "/ops/jobs/audit?resource_type=workflow&resource_id=wf%3Aalpha%2Fbeta&event_type=workflow.step_completed&page=2"

    assert previous ==
             "/ops/jobs/audit?resource_type=workflow&resource_id=wf%3Aalpha%2Fbeta&event_type=workflow.step_completed&page=1"

    assert next ==
             "/ops/jobs/audit?resource_type=workflow&resource_id=wf%3Aalpha%2Fbeta&event_type=workflow.step_completed&page=3"

    refute closed =~ "event="
    refute previous =~ "event="
    refute next =~ "event="
  end

  test "Jobs list URLs emit only the closed allowlist in canonical order" do
    path =
      Selectors.jobs_path(%{
        "job" => "42",
        "page" => "3",
        "meta" => ~s({"region":"us"}),
        "args" => ~s({"account_id":123}),
        "tags" => "alpha,beta",
        "worker" => "MyApp.Worker",
        "queue" => "critical",
        "state" => "retryable",
        "return_to" => "/ops/jobs/audit",
        "unknown" => "discarded"
      })

    assert path ==
             "/ops/jobs/jobs?state=retryable&queue=critical&worker=MyApp.Worker&tags=alpha%2Cbeta&args=%7B%22account_id%22%3A123%7D&meta=%7B%22region%22%3A%22us%22%7D&page=3&job=42"

    refute path =~ "return_to"
    refute path =~ "unknown"
  end

  test "Jobs values remain literal and delimiter-safe without injecting selector keys" do
    literal = "critical&job=999&return_to=/evil?state=executing#fragment"
    path = Selectors.jobs_path([{"state", "available"}, {"queue", literal}])
    decoded = path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

    assert decoded == %{"state" => "available", "queue" => literal}
    refute Map.has_key?(decoded, "job")
    refute Map.has_key?(decoded, "return_to")
  end

  test "job detail return context drops review, opaque return targets, and unknown keys" do
    path =
      Selectors.job_detail_path(42, [
        {"job", "41"},
        {"unknown", "value"},
        {"meta", ~s({"region":"us"})},
        {"state", "retryable"},
        {"return_to", "/ops/jobs/audit"},
        {"page", "3"},
        {"queue", "critical"}
      ])

    assert path ==
             "/ops/jobs/jobs/42?state=retryable&queue=critical&meta=%7B%22region%22%3A%22us%22%7D&page=3"

    refute path =~ "job="
    refute path =~ "return_to"
    refute path =~ "unknown"
  end
end
