defmodule ObanPowertools.Web.OverviewReadModel do
  @moduledoc false

  import Ecto.Query

  alias ObanPowertools.{Audit, ControlPlane, Explain}
  alias ObanPowertools.Cron.Entry
  alias ObanPowertools.Forensics.{AttentionProjection, CronHistory, LimiterHistory}
  alias ObanPowertools.Lifeline
  alias ObanPowertools.Lifeline.Incident
  alias ObanPowertools.Limits.{Resource, State}
  alias ObanPowertools.Web.ControlPlanePresenter

  def build(opts) do
    repo = Keyword.fetch!(opts, :repo)
    dashboard_path = Keyword.fetch!(opts, :dashboard_path)

    resources = repo.all(from(resource in Resource, order_by: [asc: resource.name]))
    states = repo.all(State)

    explains =
      repo.all(from(explain in Explain, order_by: [desc: explain.captured_at], limit: 12))

    entries = repo.all(from(entry in Entry, order_by: [asc: entry.name]))
    active_incidents = repo.all(from(incident in Incident, where: incident.status == "active"))

    resolved_incidents =
      repo.all(from(incident in Incident, where: incident.status == "resolved"))

    audit_events = Audit.list_all(repo: repo)
    retention = Lifeline.retention_status(repo)

    resource_rows = resource_rows(resources, states, explains)
    blocked_resources = Enum.filter(resource_rows, &(ControlPlane.limiter_status(&1) == :blocked))
    waiting_resources = Enum.filter(resource_rows, &(ControlPlane.limiter_status(&1) == :waiting))

    runnable_resources =
      Enum.filter(resource_rows, &(ControlPlane.limiter_status(&1) == :runnable))

    paused_entries =
      Enum.filter(entries, &(ControlPlane.cron_status(&1).operator_status == :waiting))

    runnable_entries =
      Enum.filter(entries, &(ControlPlane.cron_status(&1).operator_status == :runnable))

    bridge_rows = bridge_rows(explains, dashboard_path)

    [
      %{
        status: "Needs Review",
        count: length(active_incidents),
        diagnosis: needs_review_diagnosis(active_incidents),
        ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
        venue: ControlPlanePresenter.venue_label(:powertools_native),
        posture: ControlPlanePresenter.ownership_posture(:powertools_native),
        next_step_label: "Review Needs Review",
        next_step_path: needs_review_path(active_incidents),
        exemplars: needs_review_exemplars(active_incidents)
      },
      %{
        status: "Blocked",
        count: length(blocked_resources),
        diagnosis: blocked_diagnosis(blocked_resources),
        ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
        venue: ControlPlanePresenter.venue_label(:powertools_native),
        posture: ControlPlanePresenter.ownership_posture(:powertools_native),
        next_step_label: "Review Blocked Limiters",
        next_step_path: first_resource_path(blocked_resources, "/ops/jobs/limiters"),
        exemplars: limiter_exemplars(blocked_resources, repo, "Blocked")
      },
      %{
        status: "Waiting",
        count: length(waiting_resources) + length(paused_entries),
        diagnosis: waiting_diagnosis(waiting_resources, paused_entries),
        ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
        venue: ControlPlanePresenter.venue_label(:powertools_native),
        posture: ControlPlanePresenter.ownership_posture(:powertools_native),
        next_step_label: waiting_next_step_label(waiting_resources, paused_entries),
        next_step_path: waiting_next_step_path(waiting_resources, paused_entries),
        exemplars: waiting_exemplars(waiting_resources, paused_entries, repo)
      },
      %{
        status: "Runnable",
        count: length(runnable_resources) + length(runnable_entries),
        diagnosis: runnable_diagnosis(runnable_resources, runnable_entries),
        ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
        venue: ControlPlanePresenter.venue_label(:powertools_native),
        posture: ControlPlanePresenter.ownership_posture(:powertools_native),
        next_step_label: "Review Runnable Capacity",
        next_step_path: first_resource_path(runnable_resources, "/ops/jobs/limiters"),
        exemplars: runnable_exemplars(runnable_resources, runnable_entries, repo)
      },
      %{
        status: "Bridge-only Follow-up",
        count: length(bridge_rows),
        diagnosis: bridge_diagnosis(bridge_rows),
        ownership: ControlPlanePresenter.ownership_badge(:oban_web_bridge),
        venue: ControlPlanePresenter.venue_label(:oban_web_bridge),
        posture: ControlPlanePresenter.ownership_posture(:oban_web_bridge),
        next_step_label: "Inspect Bridge Follow-up",
        next_step_path: bridge_next_step_path(bridge_rows, dashboard_path),
        exemplars: bridge_exemplars(bridge_rows)
      },
      %{
        status: "Resolved Recently",
        count: length(resolved_incidents),
        diagnosis: resolved_diagnosis(resolved_incidents, retention.archived_repairs),
        ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
        venue: ControlPlanePresenter.venue_label(:powertools_native),
        posture: "Continuity evidence",
        next_step_label: "Review Resolved Continuity",
        next_step_path: resolved_next_step_path(resolved_incidents, audit_events),
        exemplars: resolved_exemplars(resolved_incidents, audit_events)
      }
    ]
  end

  defp resource_rows(resources, states, explains) do
    states_by_resource = Enum.group_by(states, & &1.resource_id)
    explain_by_resource = Map.new(explains, &{&1.scope_id, &1})

    Enum.map(resources, fn resource ->
      resource_states = Map.get(states_by_resource, resource.id, [])

      cooling_down? =
        Enum.any?(resource_states, fn state ->
          match?(%DateTime{}, state.cooldown_until) and
            DateTime.compare(state.cooldown_until, DateTime.utc_now()) == :gt
        end)

      saturated? = Enum.any?(resource_states, &(&1.tokens_used >= resource.bucket_capacity))
      latest_explain = Map.get(explain_by_resource, resource.name)

      Map.merge(resource, %{
        cooling_down?: cooling_down?,
        blocked?: saturated?,
        latest_explain: latest_explain
      })
    end)
  end

  defp bridge_rows(explains, dashboard_path) do
    explains
    |> Enum.filter(& &1.job_id)
    |> Enum.uniq_by(& &1.job_id)
    |> Enum.take(3)
    |> Enum.map(fn explain ->
      %{
        label: "Job #{explain.job_id}",
        fact: List.first(explain.blocker_codes || []) || "generic inspection",
        path: Path.join([dashboard_path, "jobs", Integer.to_string(explain.job_id)])
      }
    end)
  end

  defp needs_review_diagnosis([]),
    do: "No active Lifeline incidents currently need native review."

  defp needs_review_diagnosis(incidents) do
    "#{length(incidents)} active Lifeline incident(s) need review before the next audited repair decision."
  end

  defp blocked_diagnosis([]),
    do: "No limiter resources are currently saturated."

  defp blocked_diagnosis(resources) do
    "#{length(resources)} limiter resource(s) are saturated and need native blocker review."
  end

  defp waiting_diagnosis([], []),
    do: "No cooldown or paused-entry follow-up is currently waiting."

  defp waiting_diagnosis(resources, entries) do
    "#{length(resources)} limiter cooldown(s) and #{length(entries)} paused cron entrie(s) are waiting on native follow-up."
  end

  defp runnable_diagnosis([], []),
    do: "No runnable exemplar is available yet."

  defp runnable_diagnosis(resources, entries) do
    "#{length(resources)} limiter resource(s) and #{length(entries)} cron entrie(s) are currently runnable."
  end

  defp bridge_diagnosis([]),
    do: "No generic job or bridge-owned follow-up is currently highlighted."

  defp bridge_diagnosis(rows) do
    "#{length(rows)} representative generic job follow-up item(s) remain inspection-only in the Oban Web bridge."
  end

  defp resolved_diagnosis([], archived_repairs) do
    "Resolved continuity is quiet right now; archived repairs still total #{archived_repairs}."
  end

  defp resolved_diagnosis(incidents, _archived_repairs) do
    "#{length(incidents)} resolved Lifeline incident(s) remain visible as continuity evidence."
  end

  defp needs_review_path([incident | _]), do: lifeline_incident_path("active", incident)

  defp needs_review_path([]), do: "/ops/jobs/lifeline"

  defp needs_review_exemplars(incidents) do
    candidates =
      Enum.map(incidents, fn incident ->
        %{
          bucket: "Needs Review",
          family: :lifeline,
          label: incident.summary || incident.incident_class,
          fact: incident.health_state || incident.incident_class,
          status: incident.status,
          attention_reason: incident.summary || incident.incident_class,
          evidence_completeness: :complete,
          path: lifeline_incident_path("active", incident),
          evidence_path: forensic_incident_path(incident),
          venue: ControlPlanePresenter.venue_label(:powertools_native),
          ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
          source: "lifeline"
        }
      end)

    AttentionProjection.project_bucket("Needs Review", candidates)
  end

  defp limiter_exemplars(resources, repo, bucket) do
    bucket
    |> limiter_candidates(resources, repo)
    |> then(&AttentionProjection.project_bucket(bucket, &1))
  end

  defp waiting_exemplars(resources, entries, repo) do
    candidates =
      limiter_candidates("Waiting", resources, repo) ++ cron_candidates("Waiting", entries, repo)

    AttentionProjection.project_bucket("Waiting", candidates)
  end

  defp runnable_exemplars(resources, entries, repo) do
    candidates =
      limiter_candidates("Runnable", resources, repo) ++
        cron_candidates("Runnable", entries, repo)

    AttentionProjection.project_bucket("Runnable", candidates)
  end

  defp bridge_exemplars(rows), do: rows

  defp resolved_exemplars(incidents, events) do
    resolved_rows =
      incidents
      |> Enum.map(fn incident ->
        %{
          bucket: "Resolved Recently",
          family: :lifeline,
          label: incident.summary || incident.incident_class,
          fact: "resolved incident",
          status: :resolved,
          attention_reason: "Resolved Lifeline incident remains visible as continuity evidence.",
          evidence_completeness: :complete,
          path: lifeline_incident_path("resolved", incident),
          evidence_path: forensic_incident_path(incident),
          venue: ControlPlanePresenter.venue_label(:powertools_native),
          ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
          source: "lifeline"
        }
      end)

    audit_rows =
      events
      |> Enum.filter(&(&1.event_type == "lifeline.repair_executed"))
      |> Enum.take(1)
      |> Enum.map(fn event ->
        %{
          bucket: "Resolved Recently",
          family: :audit,
          label: ControlPlanePresenter.audit_resource_label(event),
          fact: ControlPlanePresenter.audit_event_label(event),
          status: :resolved,
          attention_reason: ControlPlanePresenter.audit_event_label(event),
          evidence_completeness: :complete,
          path:
            "/ops/jobs/audit?" <>
              URI.encode_query(%{
                "resource_type" => event.resource_type,
                "resource_id" => event.resource_id,
                "event_type" => event.event_type
              }),
          venue: ControlPlanePresenter.venue_label(:powertools_native),
          ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
          source: "audit"
        }
      end)

    AttentionProjection.project_bucket("Resolved Recently", resolved_rows ++ audit_rows)
  end

  defp limiter_candidates(bucket, resources, repo) do
    Enum.map(resources, fn resource ->
      summary = LimiterHistory.summary(repo, resource.name)

      %{
        bucket: bucket,
        family: :limiter,
        label: resource.name,
        fact: limiter_fact(resource),
        status: limiter_projection_status(resource),
        attention_reason: limiter_attention_reason(resource, summary),
        evidence_completeness: summary.completeness.state,
        path: "/ops/jobs/limiters?resource=#{URI.encode_www_form(resource.name)}",
        evidence_path:
          "/ops/jobs/forensics?resource_id=#{URI.encode_www_form(resource.name)}&resource_type=limiter",
        venue: ControlPlanePresenter.venue_label(:powertools_native),
        ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
        source: "limiter-history"
      }
    end)
  end

  defp cron_candidates(bucket, entries, repo) do
    Enum.map(entries, fn entry ->
      summary = CronHistory.summary(repo, entry.name)

      %{
        bucket: bucket,
        family: :cron,
        label: entry.name,
        fact:
          entry
          |> ControlPlane.cron_status()
          |> Map.fetch!(:operator_status)
          |> ControlPlanePresenter.status_label(),
        status: cron_projection_status(summary),
        attention_reason: cron_attention_reason(summary),
        evidence_completeness: summary.completeness.state,
        path: "/ops/jobs/cron?entry=#{URI.encode_www_form(entry.name)}",
        evidence_path:
          "/ops/jobs/forensics?resource_id=#{URI.encode_www_form(entry.name)}&resource_type=cron_entry",
        venue: ControlPlanePresenter.venue_label(:powertools_native),
        ownership: ControlPlanePresenter.ownership_badge(:powertools_native),
        source: "cron-history"
      }
    end)
  end

  defp limiter_projection_status(resource) do
    case ControlPlane.limiter_status(resource) do
      :blocked -> :blocked
      :waiting -> :cooling_down
      status -> status
    end
  end

  defp limiter_attention_reason(_resource, %{detail: detail}) when is_binary(detail), do: detail
  defp limiter_attention_reason(resource, _summary), do: limiter_fact(resource)

  defp cron_projection_status(%{slots: [%{classification: :missed_fire} | _]}), do: :missed_fire
  defp cron_projection_status(%{slots: [%{classification: :unknown} | _]}), do: :unknown
  defp cron_projection_status(%{current: current}) when is_binary(current), do: current
  defp cron_projection_status(_summary), do: :unknown

  defp cron_attention_reason(%{slots: slots}) do
    cond do
      Enum.any?(slots, &(&1.classification == :missed_fire)) ->
        "Recent cron history shows a missed fire while scheduler coverage was healthy."

      Enum.any?(slots, &(&1.classification == :unknown)) ->
        "unknown: retained cron windows cannot prove what happened."

      true ->
        nil
    end
  end

  defp cron_attention_reason(%{detail: detail}) when is_binary(detail), do: detail
  defp cron_attention_reason(_summary), do: nil

  defp limiter_fact(resource) do
    cond do
      resource.cooling_down? ->
        "cooldown in effect"

      resource.latest_explain ->
        List.first(resource.latest_explain.blocker_codes || []) || "blocked"

      resource.blocked? ->
        "bucket saturated"

      true ->
        "capacity available"
    end
  end

  defp first_resource_path([resource | _], _fallback),
    do: "/ops/jobs/limiters?resource=#{URI.encode_www_form(resource.name)}"

  defp first_resource_path([], fallback), do: fallback

  defp waiting_next_step_label([_ | _], _entries), do: "Review Waiting Limiters"
  defp waiting_next_step_label([], [_ | _]), do: "Review Waiting Cron Entries"
  defp waiting_next_step_label([], []), do: "Review Waiting State"

  defp waiting_next_step_path([resource | _], _entries),
    do: "/ops/jobs/limiters?resource=#{URI.encode_www_form(resource.name)}"

  defp waiting_next_step_path([], [entry | _]),
    do: "/ops/jobs/cron?entry=#{URI.encode_www_form(entry.name)}"

  defp waiting_next_step_path([], []), do: "/ops/jobs/cron"

  defp bridge_next_step_path([row | _], _dashboard_path), do: row.path
  defp bridge_next_step_path([], dashboard_path), do: Path.join([dashboard_path, "jobs"])

  defp resolved_next_step_path([incident | _], _events),
    do: lifeline_incident_path("resolved", incident)

  defp resolved_next_step_path([], [event | _]) do
    "/ops/jobs/audit?" <>
      URI.encode_query(%{
        "resource_type" => event.resource_type,
        "resource_id" => event.resource_id,
        "event_type" => event.event_type
      })
  end

  defp resolved_next_step_path([], []), do: "/ops/jobs/audit"

  defp lifeline_incident_path(view, incident) do
    "/ops/jobs/lifeline?" <>
      URI.encode_query([
        {"view", view},
        {"incident_fingerprint", incident.incident_fingerprint}
      ])
  end

  defp forensic_incident_path(incident) do
    "/ops/jobs/forensics?" <>
      URI.encode_query(%{"incident_fingerprint" => incident.incident_fingerprint})
  end
end
