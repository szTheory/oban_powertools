defmodule ObanPowertools.Forensics.Chronology do
  @moduledoc """
  Closes source facts into stable, newest-first forensic chronology items.

  Only the finite chronology fields returned by `item/1` survive normalization.
  Audit notes and limiter metadata notes are excluded structurally, while other
  source notes are bounded to 1,000 characters.
  """

  alias ObanPowertools.Forensics.Provenance

  @note_limit 1_000
  @source_families ~w(workflow lifeline cron limiter audit)
  @statuses ~w(
    available scheduled executing retryable cancelled discarded completed
    needs_review blocked waiting runnable resolved success succeeded skipped failed
    previewed attempted drifted expired consumed recorded on_time manual_run
    partial_evidence unknown
  )a

  def sort(items) when is_list(items) do
    items
    |> Enum.sort(&newer_or_stable?/2)
    |> Enum.uniq_by(& &1.id)
  end

  def item(attrs) when is_map(attrs) do
    occurred_at = field(attrs, :occurred_at)
    label = finite_text(field(attrs, :label), "Unknown event")
    resource_type = optional_text(field(attrs, :resource_type))
    resource_id = optional_text(field(attrs, :resource_id))
    source_family = normalize_source_family(field(attrs, :source_family))
    event_type = optional_text(field(attrs, :event_type))
    strength = attrs |> field(:strength) |> Provenance.normalize_provenance()
    status = normalize_status(field(attrs, :status) || inferred_status(event_type))
    notes = safe_notes(source_family, field(attrs, :notes))

    %{
      id:
        normalize_identity(
          field(attrs, :id),
          occurred_at,
          label,
          resource_type,
          resource_id,
          source_family,
          event_type
        ),
      occurred_at: occurred_at,
      label: label,
      resource_type: resource_type,
      resource_id: resource_id,
      source_family: source_family,
      strength: strength,
      event_type: event_type,
      status: status,
      notes: notes
    }
  end

  defp newer_or_stable?(left, right) do
    left_time = left |> Map.get(:occurred_at) |> unix_microseconds()
    right_time = right |> Map.get(:occurred_at) |> unix_microseconds()

    if left_time == right_time,
      do: (Map.get(left, :id) || "") >= (Map.get(right, :id) || ""),
      else: left_time > right_time
  end

  defp normalize_identity(value, _occurred_at, _label, _type, _resource_id, _source, _event)
       when is_binary(value) and value != "" do
    value
  end

  defp normalize_identity(_value, occurred_at, label, type, resource_id, source, event) do
    digest =
      [occurred_at, label, type, resource_id, source, event]
      |> :erlang.term_to_binary()
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 20)

    "forensic-event-#{digest}"
  end

  defp safe_notes(source_family, _notes) when source_family in ["audit", "limiter"], do: nil
  defp safe_notes(_source_family, nil), do: nil

  defp safe_notes(_source_family, notes) when is_binary(notes) do
    notes
    |> String.trim()
    |> case do
      "" -> nil
      text -> if sensitive_text?(text), do: nil, else: bound_text(text)
    end
  end

  defp safe_notes(_source_family, _notes), do: nil

  defp bound_text(text) do
    if String.length(text) > @note_limit do
      String.slice(text, 0, @note_limit - 1) <> "…"
    else
      text
    end
  end

  defp sensitive_text?(text) do
    Regex.match?(
      ~r/(?:https?|ftp):\/\/\S*[?&]|(?:token|secret|password|passwd|credential|authorization|cookie|headers?|payload|stacktrace|raw[_ -]?error|operator[_ -]?reason)\s*[:=_-]/i,
      text
    )
  end

  defp normalize_source_family(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_source_family()

  defp normalize_source_family(value) when value in @source_families, do: value
  defp normalize_source_family(_value), do: "unknown"

  defp normalize_status(value) when is_binary(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "_")
    |> String.trim("_")
    |> then(fn normalized ->
      Enum.find(@statuses, :unknown, &(Atom.to_string(&1) == normalized))
    end)
  end

  defp normalize_status(value) when value in @statuses, do: value
  defp normalize_status(_value), do: :unknown

  defp inferred_status("workflow.step_completed"), do: :succeeded
  defp inferred_status("workflow.recovery_completed"), do: :succeeded
  defp inferred_status("workflow.step_unblocked"), do: :runnable
  defp inferred_status("workflow.cancel_requested"), do: :waiting
  defp inferred_status("lifeline.repair_executed"), do: :recorded
  defp inferred_status("lifeline.incident_opened"), do: :blocked
  defp inferred_status("lifeline.incident_diagnosis"), do: :needs_review
  defp inferred_status("cron.missed_fire"), do: :needs_review
  defp inferred_status("cron.on_time"), do: :on_time
  defp inferred_status("cron.manual_run"), do: :manual_run
  defp inferred_status("limiter.blocked"), do: :blocked
  defp inferred_status("limiter.released"), do: :runnable
  defp inferred_status("limiter.reconfigured"), do: :runnable
  defp inferred_status(_event_type), do: :unknown

  defp field(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end

  defp finite_text(value, fallback) do
    optional_text(value) || fallback
  end

  defp optional_text(nil), do: nil
  defp optional_text(value) when is_atom(value), do: Atom.to_string(value)
  defp optional_text(value) when is_integer(value), do: Integer.to_string(value)

  defp optional_text(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      text -> bound_text(text)
    end
  end

  defp optional_text(_value), do: nil

  defp unix_microseconds(nil), do: 0
  defp unix_microseconds(%DateTime{} = dt), do: DateTime.to_unix(dt, :microsecond)

  defp unix_microseconds(%NaiveDateTime{} = ndt) do
    ndt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:microsecond)
  end

  defp unix_microseconds(_other), do: 0
end
