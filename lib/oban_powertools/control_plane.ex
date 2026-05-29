defmodule ObanPowertools.ControlPlane do
  @moduledoc """
  Shared machine-facing control-plane taxonomy for operator surfaces.
  """

  @statuses [:needs_review, :blocked, :waiting, :runnable, :resolved, :bridge_only]
  @ownerships [:powertools_native, :oban_web_bridge, :host_owned]
  @venues %{
    powertools_native: "Powertools-native",
    oban_web_bridge: "Oban Web bridge",
    host_owned: "Host-owned"
  }

  def statuses, do: @statuses
  def ownerships, do: @ownerships

  def ownership_badge(ownership) when ownership in @ownerships do
    Map.fetch!(@venues, ownership)
  end

  def venue_label(venue) when is_atom(venue) do
    Map.get(@venues, venue, venue |> Atom.to_string() |> String.replace("_", " "))
  end

  def limiter_status(%{cooling_down?: true}), do: :waiting
  def limiter_status(%{saturation_label: "Blocked"}), do: :blocked
  def limiter_status(%{blocked?: true}), do: :blocked
  def limiter_status(_resource), do: :runnable

  def cron_status(%{paused_at: %_{} = _paused_at}),
    do: %{operator_status: :waiting, diagnosis: :paused}

  def cron_status(%{paused_at: nil}), do: %{operator_status: :runnable, diagnosis: :ready}
  def cron_status(%{"paused_at" => paused_at}), do: cron_status(%{paused_at: paused_at})
  def cron_status(_entry), do: %{operator_status: :waiting, diagnosis: :paused}

  def workflow_status(%{latest_rejection: rejection}) when not is_nil(rejection) do
    %{operator_status: :needs_review, diagnosis: rejection.reason_code || :rejected}
  end

  def workflow_status(%{diagnosis: diagnosis})
      when diagnosis in [:waiting_on_signal, :waiting_on_dependencies] do
    %{operator_status: :waiting, diagnosis: diagnosis}
  end

  def workflow_status(%{diagnosis: diagnosis})
      when diagnosis in [:missing_executor, :cancel_requested] do
    %{operator_status: :blocked, diagnosis: diagnosis}
  end

  def workflow_status(%{diagnosis: diagnosis}) when is_binary(diagnosis) do
    workflow_status(%{diagnosis: String.to_atom(diagnosis)})
  end

  def workflow_status(%{state: state}) when state in [:completed, "completed"] do
    %{operator_status: :resolved, diagnosis: :completed}
  end

  def workflow_status(_story), do: %{operator_status: :runnable, diagnosis: :ready}

  def lifeline_status(%{status: status}) when status in [:resolved, "resolved"] do
    :resolved
  end

  def lifeline_status(%{status: status}) when status in [:active, "active"] do
    :needs_review
  end

  def lifeline_status(_incident), do: :needs_review

  def audit_status(%{source: :bridge}), do: :bridge_only
  def audit_status(%{ownership: :oban_web_bridge}), do: :bridge_only
  def audit_status(%{event_type: "oban_web.inspection"}), do: :bridge_only
  def audit_status(_event), do: :resolved
end
