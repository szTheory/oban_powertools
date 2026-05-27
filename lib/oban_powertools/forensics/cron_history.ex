defmodule ObanPowertools.Forensics.CronHistory do
  @moduledoc false

  import Ecto.Query

  alias ObanPowertools.{Audit, ControlPlane}
  alias ObanPowertools.Cron.{Entry, Slot}
  alias ObanPowertools.Forensics.{CronCoverage, EvidenceBundle, RunbookEntry}

  @history_limit 8

  def bundle(repo, entry_name, selectors \\ %{}) do
    case repo.get_by(Entry, name: entry_name) do
      nil ->
        nil

      entry ->
        views = slot_views(repo, entry)
        completeness = completeness(views)
        current = current_diagnosis(entry, views)

        %{
          subject: %{
            type: "cron_entry",
            id: entry.name,
            label: entry.name,
            resource_type: selectors.resource_type || "cron_entry",
            resource_id: selectors.resource_id || entry.name,
            entry_surface: "Powertools-native cron"
          },
          diagnosis_summary: %{
            title: "Cron diagnosis",
            current: current.current,
            detail: current.detail,
            provenance: :durable
          },
          chronology:
            Enum.map(views, &chronology_item/1) ++
              Enum.map(audit_events(repo, entry.name), &audit_item/1),
          related_evidence: related_evidence(entry, views),
          linked_resources: [
            %{label: "Cron detail", path: cron_path(entry.name), venue: "Powertools-native"},
            %{label: "Audit follow-up", path: audit_path(entry.name), venue: "Inspection only"}
          ],
          legal_next_paths: [
            %{
              label: "Return to cron diagnosis",
              path: cron_path(entry.name),
              venue: "Powertools-native"
            },
            %{
              label: "Inspect audit trail",
              path: audit_path(entry.name),
              venue: "Inspection only"
            },
            %{
              label: "Coordinate schedule owner follow-up",
              path: nil,
              venue: "External runbook"
            }
          ],
          completeness: completeness
        }
        |> EvidenceBundle.build()
        |> enrich_runbook_entry()
    end
  end

  def summary(repo, entry_name) do
    case repo.get_by(Entry, name: entry_name) do
      nil ->
        %{
          current: "unknown",
          detail: "No cron entry exists for this history request.",
          slots: [],
          completeness: %{state: :unknown, details: "unknown: no cron entry was found."}
        }

      entry ->
        views = slot_views(repo, entry)
        current = current_diagnosis(entry, views)

        Map.merge(current, %{slots: views, completeness: completeness(views)})
    end
  end

  def record_coverage(repo, %Entry{} = entry, slot_at, opts \\ []) do
    status = Keyword.get(opts, :status, "healthy")
    metadata = Keyword.get(opts, :metadata, %{})

    %CronCoverage{}
    |> CronCoverage.changeset(%{
      entry_id: entry.id,
      slot_at: slot_at,
      status: status,
      metadata: metadata
    })
    |> repo.insert(
      on_conflict: [set: [status: status, metadata: metadata]],
      conflict_target: [:entry_id, :slot_at]
    )
  end

  def slot_views(repo, %Entry{} = entry) do
    slots =
      repo.all(
        from(slot in Slot,
          where: slot.entry_id == ^entry.id,
          order_by: [desc: slot.slot_at],
          limit: @history_limit
        )
      )

    coverages =
      repo.all(
        from(coverage in CronCoverage,
          where: coverage.entry_id == ^entry.id,
          order_by: [desc: coverage.slot_at],
          limit: @history_limit
        )
      )

    times =
      (Enum.map(slots, & &1.slot_at) ++ Enum.map(coverages, & &1.slot_at))
      |> Enum.uniq_by(&DateTime.to_iso8601/1)
      |> Enum.sort(&(DateTime.compare(&1, &2) == :gt))
      |> Enum.take(@history_limit)

    slot_map = Map.new(slots, &{DateTime.to_iso8601(&1.slot_at), &1})
    coverage_map = Map.new(coverages, &{DateTime.to_iso8601(&1.slot_at), &1})

    Enum.map(times, fn slot_at ->
      slot = Map.get(slot_map, DateTime.to_iso8601(slot_at))
      coverage = Map.get(coverage_map, DateTime.to_iso8601(slot_at))
      classify_slot(entry, slot_at, slot, coverage)
    end)
  end

  defp classify_slot(entry, slot_at, slot, coverage) do
    cond do
      manual_slot?(slot) ->
        base_view(
          entry,
          slot_at,
          :manual_run,
          :complete,
          "Manual run recorded without changing schedule truth.",
          slot,
          coverage
        )

      (is_nil(slot) and coverage) && coverage.status == "healthy" ->
        base_view(
          entry,
          slot_at,
          :missed_fire,
          :complete,
          "No slot claim was recorded while scheduler coverage was healthy.",
          slot,
          coverage
        )

      is_nil(slot) and coverage ->
        base_view(
          entry,
          slot_at,
          :partial_evidence,
          :partial_evidence,
          "Scheduler coverage exists, but the retained cron slot evidence is incomplete.",
          slot,
          coverage
        )

      is_nil(slot) ->
        base_view(
          entry,
          slot_at,
          :unknown,
          :unknown,
          "No retained slot or scheduler coverage proves what happened at this scheduled minute.",
          slot,
          coverage
        )

      slot.state in ["queued_follow_up", "skipped"] ->
        base_view(
          entry,
          slot_at,
          :overlap_relevant,
          :complete,
          overlap_detail(slot),
          slot,
          coverage
        )

      delayed_claim?(slot) ->
        base_view(
          entry,
          slot_at,
          :delayed_claim,
          completeness_for(slot, coverage),
          "A durable slot claim exists, but it was recorded after the scheduled slot minute.",
          slot,
          coverage
        )

      true ->
        base_view(
          entry,
          slot_at,
          :on_time,
          completeness_for(slot, coverage),
          on_time_detail(entry, coverage),
          slot,
          coverage
        )
    end
  end

  defp current_diagnosis(entry, [latest | _]) do
    paused? = match?(%DateTime{}, entry.paused_at)
    status = ControlPlane.cron_status(entry)

    cond do
      paused? ->
        %{
          current: Atom.to_string(status.diagnosis),
          detail:
            "Paused now. Recent slot history remains available for missed-fire and overlap diagnosis."
        }

      latest.classification == :missed_fire ->
        %{
          current: "needs_review",
          detail: "Recent cron history shows a missed fire while scheduler coverage was healthy."
        }

      latest.classification == :overlap_relevant ->
        %{
          current: "waiting",
          detail: "Recent cron history shows overlap policy affecting scheduled execution."
        }

      latest.classification == :unknown ->
        %{
          current: "unknown",
          detail:
            "Runnable now, but recent cron history includes unknown windows without enough retained evidence."
        }

      true ->
        %{
          current: Atom.to_string(status.operator_status),
          detail:
            "Runnable now. Recent cron history stays available as a diagnosis-first timeline."
        }
    end
  end

  defp current_diagnosis(entry, []) do
    status = ControlPlane.cron_status(entry)

    %{
      current: Atom.to_string(status.operator_status),
      detail: "Current cron state is available, but no retained slot history is available yet."
    }
  end

  defp chronology_item(view) do
    %{
      occurred_at: view.slot_at,
      label: chronology_label(view.classification),
      resource_type: "cron_entry",
      resource_id: view.entry_name,
      source_family: "cron",
      strength: :durable,
      event_type: "cron.#{view.classification}",
      notes: view.detail
    }
  end

  defp related_evidence(entry, views) do
    [
      %{
        title: "Cron policy context",
        summary:
          "Overlap #{entry.overlap_policy} and catch-up #{entry.catch_up_policy} remain part of every missed-fire explanation.",
        provenance: :durable
      },
      if(Enum.any?(views, &(&1.completeness == :unknown)),
        do: %{
          title: "Coverage boundary",
          summary:
            "Unknown windows stay explicit until scheduler coverage proves what should have happened.",
          provenance: :missing
        }
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp completeness([]) do
    %{
      state: :history_unavailable,
      details:
        "history unavailable: no retained cron slot or scheduler coverage history is available yet."
    }
  end

  defp completeness(views) do
    cond do
      Enum.any?(views, &(&1.completeness == :unknown)) ->
        %{
          state: :partial_evidence,
          details:
            "partial evidence: some recent cron windows are unknown because scheduler coverage was not retained."
        }

      Enum.any?(views, &(&1.completeness == :partial_evidence)) ->
        %{
          state: :partial_evidence,
          details:
            "partial evidence: cron slot history is available, but some explanation details remain incomplete."
        }

      true ->
        %{
          state: :complete,
          details:
            "Complete cron bundle from retained slot, policy, and scheduler coverage evidence."
        }
    end
  end

  defp base_view(entry, slot_at, classification, completeness, detail, slot, coverage) do
    %{
      entry_name: entry.name,
      slot_at: slot_at,
      classification: classification,
      completeness: completeness,
      detail: detail,
      slot: slot,
      coverage: coverage
    }
  end

  defp overlap_detail(slot) do
    active_job_id = get_in(slot.metadata || %{}, ["active_job_id"])
    suffix = if active_job_id, do: " Active job #{active_job_id} held the overlap lane.", else: ""
    "Overlap policy prevented an immediate enqueue at this scheduled minute." <> suffix
  end

  defp on_time_detail(entry, nil),
    do:
      "A durable cron slot was claimed for #{entry.name}, but scheduler coverage for the minute was not retained."

  defp on_time_detail(_entry, _coverage),
    do: "A durable cron slot was claimed while scheduler coverage was healthy."

  defp chronology_label(:manual_run), do: "Manual run recorded"
  defp chronology_label(:missed_fire), do: "Missed fire"
  defp chronology_label(:delayed_claim), do: "Delayed claim"
  defp chronology_label(:overlap_relevant), do: "Overlap-relevant decision"
  defp chronology_label(:partial_evidence), do: "Partial cron evidence"
  defp chronology_label(:unknown), do: "Unknown cron window"
  defp chronology_label(:on_time), do: "On-time slot claim"

  defp audit_events(repo, entry_name) do
    Audit.list_all(%{resource_type: "cron_entry", resource_id: entry_name}, repo: repo)
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

  defp manual_slot?(nil), do: false
  defp manual_slot?(slot), do: get_in(slot.metadata || %{}, ["manual"]) == true

  defp delayed_claim?(nil), do: false

  defp delayed_claim?(slot) do
    DateTime.compare(slot.claimed_at || slot.slot_at, slot.slot_at) == :gt
  end

  defp completeness_for(_slot, nil), do: :partial_evidence
  defp completeness_for(_slot, _coverage), do: :complete

  defp cron_path(entry_name), do: "/ops/jobs/cron?entry=#{URI.encode_www_form(entry_name)}"

  defp audit_path(entry_name),
    do: "/ops/jobs/audit?resource_type=cron_entry&resource_id=#{URI.encode_www_form(entry_name)}"

  defp enrich_runbook_entry(bundle) do
    Map.put(bundle, :runbook_entry, RunbookEntry.from_bundle(bundle))
  end
end
