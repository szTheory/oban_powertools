defmodule ObanPowertools.Forensics.LimiterHistory do
  @moduledoc false

  import Ecto.Query

  alias ObanPowertools.{Audit, Explain}
  alias ObanPowertools.Forensics.{EvidenceBundle, LimiterHistoryFact}
  alias ObanPowertools.Limits.{Resource, State}

  @history_limit 8

  def bundle(repo, resource_name, selectors \\ %{}) do
    case repo.get_by(Resource, name: resource_name) do
      nil ->
        nil

      resource ->
        states = repo.all(from(state in State, where: state.resource_id == ^resource.id))
        facts = recent_facts(repo, resource_name)
        snapshot = latest_snapshot(repo, resource_name)
        audit_events = audit_events(repo, resource_name)
        history = resource_history(resource, states, facts)

        EvidenceBundle.build(%{
          subject: %{
            type: "limiter",
            id: resource.name,
            label: resource.name,
            resource_type: selectors.resource_type || "limiter",
            resource_id: selectors.resource_id || resource.name,
            entry_surface: "Powertools-native limiters"
          },
          diagnosis_summary: %{
            title: "Limiter diagnosis",
            current: history.current,
            detail: history.detail,
            provenance: :durable
          },
          chronology: chronology(facts, audit_events),
          related_evidence: related_evidence(snapshot, facts, history.detail),
          linked_resources: [
            %{
              label: "Limiter detail",
              path: limiter_path(resource.name),
              venue: "Powertools-native"
            },
            %{
              label: "Audit follow-up",
              path: audit_path(resource.name),
              venue: "Inspection only"
            }
          ],
          legal_next_paths: [
            %{
              label: "Return to limiter diagnosis",
              path: limiter_path(resource.name),
              venue: "Powertools-native"
            }
          ],
          completeness: completeness(facts, snapshot)
        })
    end
  end

  def summary(repo, resource_name) do
    case repo.get_by(Resource, name: resource_name) do
      nil ->
        %{
          current: "unknown",
          detail: "No limiter resource exists for this history request.",
          episodes: [],
          completeness: %{state: :unknown, details: "unknown: no limiter resource was found."}
        }

      resource ->
        states = repo.all(from(state in State, where: state.resource_id == ^resource.id))
        facts = recent_facts(repo, resource_name)
        history = resource_history(resource, states, facts)

        %{
          current: history.current,
          detail: history.detail,
          episodes: Enum.map(facts, &episode/1),
          completeness: completeness(facts, latest_snapshot(repo, resource_name))
        }
    end
  end

  def record_fact(repo, attrs) when is_map(attrs) do
    %LimiterHistoryFact{}
    |> LimiterHistoryFact.changeset(attrs)
    |> repo.insert()
  end

  def recent_facts(repo, resource_name) do
    repo.all(
      from(fact in LimiterHistoryFact,
        where: fact.resource_name == ^resource_name,
        order_by: [desc: fact.occurred_at, desc: fact.inserted_at],
        limit: @history_limit
      )
    )
  end

  defp resource_history(resource, states, facts) do
    cooldown_state = Enum.find(states, &cooldown_active?/1)
    pressure_active? = pressure_state?(resource, states)
    latest_fact = List.first(facts)

    cond do
      cooldown_state ->
        %{
          current: "blocked",
          detail:
            "Blocked by policy cooldown for #{resource.name}. Cooldown remains active for partition #{cooldown_state.partition_key}."
        }

      pressure_active? ->
        %{
          current: "blocked",
          detail:
            "Blocked by transient pressure for #{resource.name}. Current limiter state still reports a saturated bucket."
        }

      latest_fact && latest_fact.event_type == "limiter.reconfigured" ->
        %{
          current: "runnable",
          detail:
            "Runnable now, with recent history showing a limiter reconfiguration for #{resource.name}."
        }

      latest_fact &&
          latest_fact.event_type in ["limiter.released", "limiter.pressure_restored_observed"] ->
        %{
          current: "runnable",
          detail:
            "Runnable now. Recent history shows the limiter was restored after earlier pressure."
        }

      latest_fact ->
        %{
          current: "runnable",
          detail:
            "Runnable now. Recent limiter history remains available as supporting operational evidence."
        }

      true ->
        %{
          current: "runnable",
          detail: "Runnable now. No retained limiter history is available yet for this resource."
        }
    end
  end

  defp chronology(facts, audit_events) do
    Enum.map(facts, &chronology_item/1) ++ Enum.map(audit_events, &audit_item/1)
  end

  defp chronology_item(fact) do
    %{
      occurred_at: fact.occurred_at,
      label: chronology_label(fact),
      resource_type: "limiter",
      resource_id: fact.resource_name,
      source_family: "limiter",
      strength: :durable,
      event_type: fact.event_type,
      notes: chronology_notes(fact)
    }
  end

  defp chronology_label(%{event_type: "limiter.blocked", cause_kind: "policy"}),
    do: "Limiter blocked by cooldown"

  defp chronology_label(%{event_type: "limiter.blocked"}), do: "Limiter blocked by pressure"
  defp chronology_label(%{event_type: "limiter.released"}), do: "Limiter restored observed"
  defp chronology_label(%{event_type: "limiter.cooled_down"}), do: "Limiter cooldown started"
  defp chronology_label(%{event_type: "limiter.reconfigured"}), do: "Limiter reconfigured"
  defp chronology_label(fact), do: fact.event_type

  defp chronology_notes(fact) do
    [partition_note(fact.partition_key), metadata_note(fact), eligible_note(fact.eligible_at)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp related_evidence(snapshot, facts, detail) do
    [
      %{title: "Limiter history posture", summary: detail, provenance: :durable},
      snapshot &&
        %{
          title: "Snapshot at block start",
          summary: "Explain snapshots remain supporting evidence for blocked-job context.",
          provenance: :supporting
        },
      if(facts == [],
        do: %{
          title: "Retention boundary",
          summary:
            "Current limiter state is visible, but retained history may still be partial or unavailable.",
          provenance: :missing
        }
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp completeness([], nil) do
    %{
      state: :history_unavailable,
      details:
        "history unavailable: no retained limiter history facts or snapshots are available yet."
    }
  end

  defp completeness([], _snapshot) do
    %{
      state: :partial_evidence,
      details:
        "partial evidence: current limiter state is available, but durable limiter history is still thin."
    }
  end

  defp completeness(_facts, _snapshot) do
    %{
      state: :complete,
      details: "Complete limiter bundle from retained history facts and supporting evidence."
    }
  end

  defp latest_snapshot(repo, resource_name) do
    repo.one(
      from(snapshot in Explain,
        where: snapshot.scope_id == ^resource_name,
        order_by: [desc: snapshot.captured_at],
        limit: 1
      )
    )
  end

  defp audit_events(repo, resource_name) do
    Audit.list_all(%{resource_type: "limiter", resource_id: resource_name}, repo: repo)
  end

  defp audit_item(event) do
    %{
      occurred_at: event.inserted_at,
      label: Audit.event_label(event),
      resource_type: event.resource_type,
      resource_id: event.resource_id,
      source_family: "audit",
      strength: :bridge_only,
      event_type: event.event_type,
      notes: Audit.event_reason(event)
    }
  end

  defp cooldown_active?(state) do
    match?(%DateTime{}, state.cooldown_until) and
      DateTime.compare(state.cooldown_until, DateTime.utc_now()) == :gt
  end

  defp pressure_state?(resource, states) do
    Enum.any?(states, fn state ->
      eligible_at =
        if state.bucket_started_at do
          DateTime.add(state.bucket_started_at, resource.bucket_span_ms, :millisecond)
        end

      state.tokens_used >= resource.bucket_capacity and
        match?(%DateTime{}, eligible_at) and
        DateTime.compare(eligible_at, DateTime.utc_now()) == :gt
    end)
  end

  defp episode(fact) do
    %{
      label: chronology_label(fact),
      occurred_at: fact.occurred_at,
      event_type: fact.event_type,
      notes: chronology_notes(fact)
    }
  end

  defp partition_note(nil), do: nil
  defp partition_note("__global__"), do: "Global scope."
  defp partition_note(key), do: "Partition #{key}."

  defp metadata_note(%{metadata: metadata}) when is_map(metadata) do
    diff = metadata["config_diff"]
    reason = metadata["reason"]

    cond do
      is_map(diff) and map_size(diff) > 0 ->
        "Config changed: #{Enum.join(Map.keys(diff), ", ")}."

      is_binary(reason) and reason != "" ->
        "Reason: #{reason}."

      true ->
        nil
    end
  end

  defp metadata_note(_fact), do: nil

  defp eligible_note(nil), do: nil
  defp eligible_note(%DateTime{} = dt), do: "Eligible again at #{DateTime.to_iso8601(dt)}."

  defp limiter_path(resource_name),
    do: "/ops/jobs/limiters?resource=#{URI.encode_www_form(resource_name)}"

  defp audit_path(resource_name),
    do: "/ops/jobs/audit?resource_type=limiter&resource_id=#{URI.encode_www_form(resource_name)}"
end
