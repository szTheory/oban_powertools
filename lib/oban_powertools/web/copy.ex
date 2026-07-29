defmodule ObanPowertools.Web.Copy do
  @moduledoc """
  Finite, production-owned policy for shared operator-facing copy.

  Page-specific consequences and support boundaries remain with their
  presenters. This module contains only deterministic policy data that is safe
  to project into the public showcase manifest.
  """

  @canonical_terms %{
    cancel_job: %{term: "Cancel job", forbidden: ["Abort job"]},
    discard_changes: %{term: "Discard changes", forbidden: ["Abandon changes"]},
    delete: %{term: "Delete", forbidden: ["Remove permanently"]},
    retry: %{term: "Retry", forbidden: ["Try again"]},
    pause: %{term: "Pause", forbidden: ["Stop"]},
    resume: %{term: "Resume", forbidden: ["Continue processing"]},
    preview: %{term: "Preview", forbidden: ["Dry run"]},
    repair: %{term: "Repair", forbidden: ["Fix"]},
    reason: %{term: "Reason", forbidden: ["Justification"]},
    audit_log: %{term: "Audit log", forbidden: ["Activity history"]},
    event_log: %{term: "Event log", forbidden: ["Event history"]},
    limiter: %{term: "Limiter", forbidden: ["Rate limit"]}
  }

  @forbidden_phrases [
    %{
      phrase: "Are you sure?",
      replacement: "state the object, scope, and consequence",
      rule: "confirmation-question"
    },
    %{
      phrase: "Confirm",
      replacement: "use an action-specific submit label",
      rule: "ambiguous-action"
    },
    %{
      phrase: "Something went wrong",
      replacement: "state what failed and how to recover",
      rule: "generic-error"
    },
    %{
      phrase: "An error occurred",
      replacement: "state what failed and how to recover",
      rule: "generic-error"
    },
    %{
      phrase: "N/A",
      replacement: "name the distinct unavailable or permission state",
      rule: "collapsed-state"
    },
    %{
      phrase: "completed",
      replacement: "describe only the request Powertools recorded",
      rule: "host-outcome-overclaim"
    },
    %{
      phrase: "delivered",
      replacement: "describe only the request Powertools recorded",
      rule: "host-outcome-overclaim"
    },
    %{
      phrase: "succeeded",
      replacement: "describe only the request Powertools recorded",
      rule: "host-outcome-overclaim"
    },
    %{
      phrase: "fixed",
      replacement: "describe only the request Powertools recorded",
      rule: "host-outcome-overclaim"
    }
  ]

  @state_requirements %{
    empty: [:fact, :next_action],
    loading: [:resource],
    unavailable: [:resource, :recovery],
    permission_denied: [:resource, :next_action],
    stale: [:fact, :recovery],
    partial: [:fact, :recovery],
    error: [:fact, :recovery]
  }

  @confirmation_order [
    :object,
    :scope,
    :consequence,
    :reversibility,
    :support_boundary,
    :reason,
    :actions
  ]

  @receipt_verbs ["requested", "recorded", "changed", "audited"]

  @source_roots [
    "lib/oban_powertools/web/components",
    "lib/oban_powertools/web/live"
  ]

  @exclusions ["lib/oban_powertools/web/copy.ex"]

  @spec contract() :: map()
  def contract do
    %{
      canonical_terms: @canonical_terms,
      confirmation_order: @confirmation_order,
      exclusions: @exclusions,
      forbidden_phrases: @forbidden_phrases,
      receipt_verbs: @receipt_verbs,
      source_roots: @source_roots,
      state_requirements: @state_requirements
    }
  end
end
