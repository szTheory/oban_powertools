defmodule ObanPowertools.PrimitiveStoryCatalog do
  @moduledoc """
  Deterministic dev/test primitive story catalog for the Powertools showcase.

  Primitive stories are intentionally separate from `ObanPowertools.ShowcaseCatalog`.
  The stress fixture catalog remains domain/persona/JTBD-owned, while this module
  registers small component targets for VRT and accessibility scans.
  """

  @stories [
    %{
      id: "primitive-button-matrix",
      kind: :primitive,
      component: :button,
      components: [:button],
      name: "Button matrix",
      description: "Safe, caution, destructive, ghost, and disabled-with-reason actions.",
      variant: [:neutral, :primary, :warning, :danger, :ghost],
      state: [:default, :disabled, :disabled_reason],
      snapshot: "showcase/primitive-button-matrix",
      a11y: ~s([data-obpt-primitive-story="primitive-button-matrix"]),
      examples: [
        %{label: "Retry job", variant: :primary, state: :default},
        %{label: "Pause queue", variant: :warning, state: :default},
        %{label: "Cancel job", variant: :danger, state: :disabled_reason},
        %{label: "View audit log", variant: :ghost, state: :default}
      ],
      test_targets: %{
        story: "obpt-primitive-story-primitive-button-matrix",
        snapshot: "showcase/primitive-button-matrix",
        a11y: ~s([data-obpt-primitive-story="primitive-button-matrix"])
      }
    },
    %{
      id: "primitive-icon-button-accessible-names",
      kind: :primitive,
      component: :icon_button,
      components: [:icon_button],
      name: "Icon button accessible names",
      description: "Icon-only controls with API-level labels independent from tooltips.",
      variant: [:neutral, :primary, :danger],
      state: [:labelled, :tooltip, :disabled_reason],
      snapshot: "showcase/primitive-icon-button-accessible-names",
      a11y: ~s([data-obpt-primitive-story="primitive-icon-button-accessible-names"]),
      examples: [
        %{label: "Refresh jobs", icon: :dot, tooltip: "Refresh the job list"},
        %{label: "Acknowledge warning", icon: :check, tooltip: "Mark warning as reviewed"},
        %{label: "Cancel selected job", icon: :alert, tooltip: "Cancel selected job"}
      ],
      test_targets: %{
        story: "obpt-primitive-story-primitive-icon-button-accessible-names",
        snapshot: "showcase/primitive-icon-button-accessible-names",
        a11y: ~s([data-obpt-primitive-story="primitive-icon-button-accessible-names"])
      }
    },
    %{
      id: "primitive-link-badge-tag-status",
      kind: :primitive,
      component: :link,
      components: [:link, :badge, :tag, :status_pill],
      name: "Link, badge, tag, and status",
      description: "Navigation and non-interactive metadata with representative status tones.",
      variant: [:navigation, :tone_matrix],
      state: [:metadata, :representative_status],
      snapshot: "showcase/primitive-link-badge-tag-status",
      a11y: ~s([data-obpt-primitive-story="primitive-link-badge-tag-status"]),
      examples: [
        %{label: "View audit log", component: :link, href: "/ops/jobs/audit"},
        %{label: "executing", component: :badge, tone: :info},
        %{label: "queue: critical-mailer", component: :tag, tone: :neutral},
        %{
          label: "Retryable",
          component: :status_pill,
          tone: :warning,
          icon: :alert,
          sr_prefix: "Job state"
        },
        %{
          label: "Completed",
          component: :status_pill,
          tone: :success,
          icon: :check,
          sr_prefix: "Job state"
        },
        %{
          label: "Discarded",
          component: :status_pill,
          tone: :danger,
          icon: :alert,
          sr_prefix: "Job state"
        }
      ],
      test_targets: %{
        story: "obpt-primitive-story-primitive-link-badge-tag-status",
        snapshot: "showcase/primitive-link-badge-tag-status",
        a11y: ~s([data-obpt-primitive-story="primitive-link-badge-tag-status"])
      }
    },
    %{
      id: "primitive-surface-card-divider-density",
      kind: :primitive,
      component: :surface,
      components: [:surface, :card, :divider],
      name: "Surface, card, and divider density",
      description: "Restrained structural containers with dense operator-console content.",
      variant: [:plain, :elevated, :inset, :attention],
      state: [:density, :structure],
      snapshot: "showcase/primitive-surface-card-divider-density",
      a11y: ~s([data-obpt-primitive-story="primitive-surface-card-divider-density"]),
      examples: [
        %{label: "Filter summary", variant: :inset},
        %{label: "Job details", variant: :elevated},
        %{label: "Requires review", variant: :attention}
      ],
      test_targets: %{
        story: "obpt-primitive-story-primitive-surface-card-divider-density",
        snapshot: "showcase/primitive-surface-card-divider-density",
        a11y: ~s([data-obpt-primitive-story="primitive-surface-card-divider-density"])
      }
    },
    %{
      id: "primitive-tooltip-open",
      kind: :primitive,
      component: :tooltip,
      components: [:tooltip],
      name: "Tooltip open target",
      description: "Text-only tooltip with stable trigger and description ids.",
      variant: [:text_only],
      state: [:open, :focus],
      snapshot: "showcase/primitive-tooltip-open",
      a11y: ~s([data-obpt-primitive-story="primitive-tooltip-open"]),
      examples: [
        %{
          label: "Retry job",
          text: "Retries the selected job once and records the operator reason."
        }
      ],
      test_targets: %{
        story: "obpt-primitive-story-primitive-tooltip-open",
        snapshot: "showcase/primitive-tooltip-open",
        a11y: ~s([data-obpt-primitive-story="primitive-tooltip-open"])
      }
    },
    %{
      id: "primitive-spinner-skeleton-loading",
      kind: :primitive,
      component: :spinner,
      components: [:spinner, :skeleton],
      name: "Spinner and skeleton loading",
      description: "Named loading states for bounded progress and progressive content.",
      variant: [:bounded, :progressive],
      state: [:loading, :busy],
      snapshot: "showcase/primitive-spinner-skeleton-loading",
      a11y: ~s([data-obpt-primitive-story="primitive-spinner-skeleton-loading"]),
      examples: [
        %{label: "Loading job history", component: :spinner},
        %{label: "Loading retryable job table", component: :skeleton, lines: 3}
      ],
      test_targets: %{
        story: "obpt-primitive-story-primitive-spinner-skeleton-loading",
        snapshot: "showcase/primitive-spinner-skeleton-loading",
        a11y: ~s([data-obpt-primitive-story="primitive-spinner-skeleton-loading"])
      }
    },
    %{
      id: "primitive-kbd-stat-values",
      kind: :primitive,
      component: :kbd,
      components: [:kbd, :stat],
      name: "Kbd and stat values",
      description: "Machine literals and dense metrics with tabular numeric treatment.",
      variant: [:literal, :metric],
      state: [:dense_values],
      snapshot: "showcase/primitive-kbd-stat-values",
      a11y: ~s([data-obpt-primitive-story="primitive-kbd-stat-values"]),
      examples: [
        %{label: "Dismiss tooltip", key: "Esc"},
        %{label: "Retryable jobs", value: "12", trend: "3 blocked", tone: :warning},
        %{label: "Completed jobs", value: "248", trend: "all queues healthy", tone: :success}
      ],
      test_targets: %{
        story: "obpt-primitive-story-primitive-kbd-stat-values",
        snapshot: "showcase/primitive-kbd-stat-values",
        a11y: ~s([data-obpt-primitive-story="primitive-kbd-stat-values"])
      }
    }
  ]

  @stories_by_id Map.new(@stories, &{Map.fetch!(&1, :id), &1})

  def stories, do: @stories

  def story!(id) when is_binary(id) do
    Map.fetch!(@stories_by_id, id)
  rescue
    KeyError ->
      raise ArgumentError, "unknown primitive story: #{inspect(id)}"
  end

  def story!(id) do
    raise ArgumentError, "unknown primitive story: #{inspect(id)}"
  end

  def snapshot_name(id) when is_binary(id) do
    "showcase/#{story!(id).id}"
  end

  def a11y_target(id) when is_binary(id) do
    ~s([data-obpt-primitive-story="#{story!(id).id}"])
  end
end
