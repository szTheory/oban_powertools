defmodule ObanPowertools.Web.CopyContractTest do
  use ExUnit.Case, async: true

  alias ObanPowertools.Web.Copy

  @concepts [
    :cancel_job,
    :discard_changes,
    :delete,
    :retry,
    :pause,
    :resume,
    :preview,
    :repair,
    :reason,
    :audit_log,
    :event_log,
    :limiter
  ]

  @states [:empty, :loading, :unavailable, :permission_denied, :stale, :partial, :error]
  @receipt_verbs ["requested", "recorded", "changed", "audited"]
  @confirmation_order [
    :object,
    :scope,
    :consequence,
    :reversibility,
    :support_boundary,
    :reason,
    :actions
  ]

  test "D-14/D-15/D-18 expose one deterministic finite copy contract" do
    contract = Copy.contract()

    assert contract == Copy.contract()

    assert Map.keys(contract) |> Enum.sort() ==
             [
               :canonical_terms,
               :confirmation_order,
               :exclusions,
               :forbidden_phrases,
               :receipt_verbs,
               :source_roots,
               :state_requirements
             ]

    assert Map.keys(contract.canonical_terms) |> Enum.sort() == Enum.sort(@concepts)
    assert Map.keys(contract.state_requirements) |> Enum.sort() == Enum.sort(@states)
    assert contract.confirmation_order == @confirmation_order
    assert contract.receipt_verbs == @receipt_verbs

    assert Enum.uniq(contract.source_roots) == contract.source_roots
    assert contract.source_roots == Enum.sort(contract.source_roots)
    assert Enum.all?(contract.source_roots, &production_root?/1)

    assert Enum.uniq(contract.exclusions) == contract.exclusions
    assert Enum.all?(contract.exclusions, &exact_exclusion?/1)

    assert_finite!(contract)
  end

  test "D-15 assigns one distinct canonical term to every operator concept" do
    terms = Copy.contract().canonical_terms

    assert terms.cancel_job.term == "Cancel job"
    assert terms.discard_changes.term == "Discard changes"
    assert terms.delete.term == "Delete"
    assert terms.retry.term == "Retry"
    assert terms.pause.term == "Pause"
    assert terms.resume.term == "Resume"
    assert terms.preview.term == "Preview"
    assert terms.repair.term == "Repair"
    assert terms.reason.term == "Reason"
    assert terms.audit_log.term == "Audit log"
    assert terms.event_log.term == "Event log"
    assert terms.limiter.term == "Limiter"

    canonical = Enum.map(@concepts, &Map.fetch!(terms, &1).term)
    assert Enum.uniq(canonical) == canonical

    for concept <- @concepts do
      %{term: term, forbidden: forbidden} = Map.fetch!(terms, concept)
      assert is_binary(term) and term != ""
      assert is_list(forbidden) and forbidden != []
      refute term in forbidden
      assert Enum.all?(forbidden, &(is_binary(&1) and &1 != ""))
    end
  end

  test "D-14/D-18 source policy rejects forbidden phrases with bounded path:line diagnostics" do
    contract = Copy.contract()

    cases = [
      {"lib/oban_powertools/web/live/jobs_live.ex", ~s(<p>Are you sure?</p>), "Are you sure?"},
      {"lib/oban_powertools/web/live/audit_live.ex", ~s(<p>Something went wrong</p>),
       "Something went wrong"},
      {"lib/oban_powertools/web/components/operator_patterns.ex", ~s(label="Confirm"), "Confirm"},
      {"lib/oban_powertools/web/live/lifeline_live.ex", ~s(<p>Repair completed.</p>),
       "completed"},
      {"lib/oban_powertools/web/control_plane_presenter.ex", "message: inspect(error)",
       "inspect("},
      {"lib/oban_powertools/web/live/workflows_live.ex", ~s(<p>code: :not_found</p>),
       ":not_found"}
    ]

    for {path, source, phrase} <- cases do
      assert {:error, [diagnostic]} = audit_source(contract, path, source)
      assert diagnostic.path == path
      assert diagnostic.line == 1
      assert diagnostic.phrase == phrase
      assert is_binary(diagnostic.rule)
      assert Map.keys(diagnostic) |> Enum.sort() == [:line, :path, :phrase, :replacement, :rule]
      refute inspect(diagnostic) =~ "preview_token"
      refute inspect(diagnostic) =~ "reason="
      refute inspect(diagnostic) =~ "payload"
    end
  end

  test "D-15 distinguishes synonym drift and ambiguous dismissal from action-specific Cancel job" do
    contract = Copy.contract()

    for {source, phrase, replacement} <- [
          {~s(<button>Try again</button>), "Try again", "Retry"},
          {~s(<button>Stop</button>), "Stop", "Pause"},
          {~s(<button>Fix</button>), "Fix", "Repair"},
          {~s(<button>Cancel</button>), "Cancel", "a safe-state dismissal label"}
        ] do
      assert {:error, [diagnostic]} =
               audit_source(contract, "lib/oban_powertools/web/live/jobs_live.ex", source)

      assert diagnostic.phrase == phrase
      assert diagnostic.replacement == replacement
    end

    assert :ok =
             audit_source(
               contract,
               "lib/oban_powertools/web/live/jobs_live.ex",
               ~s(<button>Cancel job</button><button>Keep current state</button>)
             )
  end

  test "D-17 keeps state categories distinct and requires truthful recovery facts" do
    requirements = Copy.contract().state_requirements

    assert requirements.empty == [:fact, :next_action]
    assert requirements.loading == [:resource]
    assert requirements.unavailable == [:resource, :recovery]
    assert requirements.permission_denied == [:resource, :next_action]
    assert requirements.stale == [:fact, :recovery]
    assert requirements.partial == [:fact, :recovery]
    assert requirements.error == [:fact, :recovery]
    assert Enum.uniq(Map.values(requirements)) |> length() > 1

    for {state, fixture, missing} <- [
          {:empty, %{fact: "No jobs match."}, :next_action},
          {:loading, %{}, :resource},
          {:unavailable, %{resource: "job details"}, :recovery},
          {:permission_denied, %{resource: "audit evidence"}, :next_action},
          {:stale, %{fact: "This preview is out of date."}, :recovery},
          {:partial, %{fact: "8 of 12 retry requests were recorded."}, :recovery},
          {:error, %{fact: "The retry request was not recorded."}, :recovery}
        ] do
      assert {:error, diagnostic} = validate_state(requirements, state, fixture)
      assert diagnostic == "#{state} copy requires #{missing}"
    end
  end

  test "D-17 receipts permit only Powertools-owned outcomes" do
    contract = Copy.contract()

    for receipt <- [
          "Retry requested.",
          "Operator reason recorded.",
          "Cron entry changed.",
          "Action audited."
        ] do
      assert :ok = validate_receipt(contract, receipt)
    end

    for {receipt, phrase} <- [
          {"Job completed.", "completed"},
          {"Alert delivered.", "delivered"},
          {"Remediation succeeded.", "succeeded"},
          {"Workflow fixed.", "fixed"}
        ] do
      assert {:error, diagnostic} = validate_receipt(contract, receipt)
      assert diagnostic == "receipt overclaims host-owned outcome: #{phrase}"
    end
  end

  test "D-18 rejects broad, stale, and unused exclusions while allowing exact used scopes" do
    contract = Copy.contract()

    for exclusion <- ["lib/**", "lib/oban_powertools/web/live", "*.ex", "test/**"] do
      refute exact_exclusion?(exclusion)
    end

    stale = "lib/oban_powertools/web/live/removed_fixture.ex:1:Cancel"

    assert {:error, diagnostic} =
             validate_exclusions(contract.source_roots, contract.exclusions ++ [stale], [])

    assert diagnostic == "unused copy exclusion: #{stale}"

    exact = "lib/oban_powertools/web/live/jobs_live.ex:4:Cancel"
    source = "<p>safe</p>\n<p>safe</p>\n<p>safe</p>\n<button>Cancel</button>"

    assert :ok =
             validate_exclusions(
               contract.source_roots,
               [exact],
               [{"lib/oban_powertools/web/live/jobs_live.ex", source}]
             )
  end

  test "D-18 declared production roots are closed and unique consequences remain page-owned" do
    contract = Copy.contract()
    serialized = inspect(contract)

    for prohibited <- [
          "preview_token",
          "plan_hash",
          "raw_error",
          "provider",
          "payload",
          "Incident response",
          "Completion remains host-owned.",
          "Powertools requests a retry for each selected job."
        ] do
      refute serialized =~ prohibited
    end

    assert Enum.any?(contract.source_roots, &String.ends_with?(&1, "/components"))
    assert Enum.any?(contract.source_roots, &String.ends_with?(&1, "/live"))
    assert "lib/oban_powertools/web/copy.ex" in contract.exclusions
  end

  defp audit_source(contract, path, source) do
    findings =
      source
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, number} ->
        forbidden_findings(contract, path, line, number) ++
          synonym_findings(contract, path, line, number) ++
          raw_findings(path, line, number)
      end)

    case findings do
      [] -> :ok
      values -> {:error, values}
    end
  end

  defp forbidden_findings(contract, path, line, number) do
    for %{phrase: phrase, replacement: replacement, rule: rule} <- contract.forbidden_phrases,
        String.contains?(line, phrase) do
      diagnostic(path, number, rule, phrase, replacement)
    end
  end

  defp synonym_findings(contract, path, line, number) do
    canonical =
      for {_concept, %{term: term, forbidden: forbidden}} <- contract.canonical_terms,
          phrase <- forbidden,
          into: %{},
          do: {phrase, term}

    canonical = Map.put(canonical, "Cancel", "a safe-state dismissal label")

    for {phrase, replacement} <- canonical,
        String.contains?(line, phrase),
        not (phrase == "Cancel" and String.contains?(line, "Cancel job")) do
      diagnostic(path, number, "canonical-term", phrase, replacement)
    end
  end

  defp raw_findings(path, line, number) do
    raw_markers = [
      {"inspect(", "present a bounded operator-safe fact"},
      {":not_found", "present human-readable recovery copy"}
    ]

    for {phrase, replacement} <- raw_markers, String.contains?(line, phrase) do
      diagnostic(path, number, "raw-provider-copy", phrase, replacement)
    end
  end

  defp diagnostic(path, line, rule, phrase, replacement) do
    %{path: path, line: line, rule: rule, phrase: phrase, replacement: replacement}
  end

  defp validate_state(requirements, state, fixture) do
    missing = Enum.find(Map.fetch!(requirements, state), &(not present?(fixture, &1)))
    if missing, do: {:error, "#{state} copy requires #{missing}"}, else: :ok
  end

  defp present?(fixture, key),
    do: is_binary(Map.get(fixture, key)) and Map.get(fixture, key) != ""

  defp validate_receipt(contract, receipt) do
    allowed? =
      Enum.any?(contract.receipt_verbs, fn verb ->
        String.contains?(String.downcase(receipt), verb)
      end)

    if allowed? do
      :ok
    else
      phrase =
        ["completed", "delivered", "succeeded", "fixed"]
        |> Enum.find(&String.contains?(String.downcase(receipt), &1))

      {:error, "receipt overclaims host-owned outcome: #{phrase}"}
    end
  end

  defp validate_exclusions(roots, exclusions, sources) do
    unused =
      Enum.find(exclusions, fn exclusion ->
        case String.split(exclusion, ":", parts: 3) do
          [path, line, phrase] ->
            Enum.any?(sources, fn
              {^path, source} ->
                source
                |> String.split("\n")
                |> Enum.at(String.to_integer(line) - 1, "")
                |> String.contains?(phrase)

              _ ->
                false
            end)

          [path] ->
            path != "lib/oban_powertools/web/copy.ex" and
              not Enum.any?(roots, &String.starts_with?(path, &1))
        end
      end)

    if unused, do: {:error, "unused copy exclusion: #{unused}"}, else: :ok
  end

  defp production_root?(root) do
    String.starts_with?(root, "lib/oban_powertools/web/") and
      not String.contains?(root, ["*", ".."])
  end

  defp exact_exclusion?(exclusion) do
    String.starts_with?(exclusion, "lib/oban_powertools/web/") and
      not String.contains?(exclusion, ["*", ".."]) and
      (String.ends_with?(exclusion, ".ex") or
         Regex.match?(~r/\.ex:\d+:[^:]+$/, exclusion))
  end

  defp assert_finite!(value) when is_atom(value) or is_binary(value), do: :ok

  defp assert_finite!(value) when is_list(value) do
    Enum.each(value, &assert_finite!/1)
  end

  defp assert_finite!(value) when is_map(value) do
    Enum.each(value, fn {key, nested} ->
      assert_finite!(key)
      assert_finite!(nested)
    end)
  end

  defp assert_finite!(value),
    do: flunk("copy contract contains non-finite value: #{inspect(value)}")
end
