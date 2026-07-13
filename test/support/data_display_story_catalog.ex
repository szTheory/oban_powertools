defmodule ObanPowertools.DataDisplayStoryCatalog do
  @moduledoc """
  Deterministic dev/test data-display stories for the Powertools showcase.

  The catalog contains normalized display fixtures only. It deliberately keeps
  raw secrets out of the fixture graph while preserving representative
  redaction, hostile-text, long-value, and large-result evidence.
  """

  alias ObanPowertools.Web.StatusTaxonomy

  @large_row_total 2_500
  @large_row_window (for index <- 1..20 do
                       %{
                         id: "job-#{String.pad_leading(Integer.to_string(index), 4, "0")}",
                         worker:
                           "MyApp.Workers.Job#{String.pad_leading(Integer.to_string(index), 2, "0")}",
                         state: Enum.at([:available, :retryable, :completed], rem(index - 1, 3)),
                         queue: Enum.at(["default", "critical-mailer"], rem(index - 1, 2))
                       }
                     end)

  @long_value_fixture %{
    id: "01JZ8M5P999999999999999999",
    module: "MyApp.Workers.ReconcileAccountNotificationDeliveryWithAnIntentionallyLongIdentifier",
    url:
      "https://operator.example.test/jobs/01JZ8M5P999999999999999999?queue=critical-mailer&attempt=20",
    stacktrace:
      "** (RuntimeError) delivery failed\n    (my_app 1.0.0) lib/my_app/workers/reconcile_account_notification_delivery.ex:142",
    hostile: "<script>alert('data')</script>",
    unicode: "مرحبا ✅"
  }

  @timeline_fixture [
    %{
      timestamp: "2026-07-12T14:05:00Z",
      title: "Job inserted",
      source: "MyApp.Accounts",
      domain: :job,
      state: :available,
      detail: "Inserted into critical-mailer by the account reconciliation workflow."
    },
    %{
      timestamp: "2026-07-12T14:06:30Z",
      title: "Attempt failed",
      source: "Oban.Executor",
      domain: :job,
      state: :retryable,
      detail: "Remote endpoint returned 503; retry scheduled with backoff."
    },
    %{
      timestamp: "2026-07-12T14:11:00Z",
      title: "Job completed",
      source: "Oban.Executor",
      domain: :job,
      state: :completed,
      detail: "Delivery reconciled successfully on the second attempt."
    }
  ]

  @huge_args_fixture %{
    raw_json:
      {:raw_json,
       ~s|{"account_id":"safe sibling","message":"Redacted at enqueue","hostile":"<script>alert('data')</script>","locale":"مرحبا ✅"}|},
    policy: %{
      available?: true,
      redacted?: true,
      summary: "Hidden by display policy",
      status: "redacted",
      payload: "Sensitive payload intentionally unavailable"
    },
    fallback: {:fallback, "[redacted]"},
    metadata: %{"safe sibling" => true, "redacted?" => true}
  }

  @taxonomy_fixture StatusTaxonomy.all_specs()

  @story_specs [
    %{
      id: "data-table-sort-states",
      kind: :data,
      component: :data_table,
      components: [:data_table, :status_pill],
      name: "Sortable job states",
      description: "Deterministic sortable columns and representative job-state pills.",
      variant: [:sortable, :dense],
      state: [:available, :retryable, :completed],
      fixtures: %{rows: Enum.take(@large_row_window, 6)},
      test_targets: nil
    },
    %{
      id: "data-table-320-stacked",
      kind: :data,
      component: :data_table,
      components: [:data_table, :machine_value],
      name: "Stacked table at 320 pixels",
      description: "Selection and machine values remain labelled when table cells stack.",
      variant: [:stacked, :selection],
      state: [:ready, :narrow],
      fixtures: %{rows: Enum.take(@large_row_window, 3), long: @long_value_fixture},
      test_targets: nil
    },
    %{
      id: "data-table-explicit-states",
      kind: :data,
      component: :data_table,
      components: [:data_table, :empty_state],
      name: "Explicit table states",
      description: "Loading, empty, error, unavailable, and permission denied copy.",
      variant: [:state_matrix],
      state: [:loading, :empty, :error, :unavailable, :permission_denied],
      fixtures: %{states: [:loading, :empty, :error, :unavailable, :permission_denied]},
      test_targets: nil
    },
    %{
      id: "data-status-taxonomy-all",
      kind: :data,
      component: :status_pill,
      components: [:status_pill],
      name: "Complete status taxonomy",
      description: "Every registered domain and state uses the shared status taxonomy.",
      variant: [:taxonomy],
      state: [:available, :retryable, :permission_denied],
      fixtures: %{taxonomy: @taxonomy_fixture},
      test_targets: nil
    },
    %{
      id: "data-description-list-long-values",
      kind: :data,
      component: :description_list,
      components: [:description_list, :key_value, :machine_value],
      name: "Long description values",
      description: "Long IDs, modules, URLs, hostile text, RTL text, and emoji wrap safely.",
      variant: [:long_values, :expanded],
      state: [:ready, :long_content],
      fixtures: %{values: @long_value_fixture},
      test_targets: nil
    },
    %{
      id: "data-timeline-event-log",
      kind: :data,
      component: :timeline,
      components: [:timeline, :code_block],
      name: "Operational event timeline",
      description: "Chronological job events preserve source, state, timestamp, and detail.",
      variant: [:event_log],
      state: [:available, :retryable, :completed],
      fixtures: %{events: @timeline_fixture},
      test_targets: nil
    },
    %{
      id: "data-progress-metric-cards",
      kind: :data,
      component: :progress_bar,
      components: [:progress_bar, :metric_card],
      name: "Progress and metrics",
      description: "Bounded progress, unavailable progress, and dense operational metrics.",
      variant: [:determinate, :metric],
      state: [:ready, :unavailable],
      fixtures: %{progress: %{value: 162, max: 100}, metrics: %{retryable: 12, completed: 248}},
      test_targets: nil
    },
    %{
      id: "data-code-args-redaction",
      kind: :data,
      component: :args_viewer,
      components: [:code_block, :args_viewer, :redacted_value],
      name: "Code, args, and redaction",
      description:
        "Normalized displays distinguish Redacted at enqueue, Hidden by display policy, and [redacted].",
      variant: [:json, :stacktrace, :redaction],
      state: [:ready, :redacted],
      fixtures: %{args: @huge_args_fixture, values: @long_value_fixture},
      test_targets: nil
    },
    %{
      id: "data-empty-toast-flash",
      kind: :data,
      component: :empty_state,
      components: [:empty_state, :toast, :flash_group],
      name: "Empty state and notifications",
      description: "Recovery copy and polite or assertive notifications remain explicit.",
      variant: [:empty, :notification],
      state: [:empty, :warning, :error],
      fixtures: %{flash: %{info: "Filters cleared.", error: "Job data did not load."}},
      test_targets: nil
    },
    %{
      id: "data-table-thousands-row-stress",
      kind: :data,
      component: :data_table,
      components: [:data_table],
      name: "Thousands-row table stress",
      description: "A bounded twenty-row window truthfully reports a 2,500-row result set.",
      variant: [:large_result, :paginated],
      state: [:ready, :stress],
      fixtures: %{
        total: @large_row_total,
        window: @large_row_window,
        pagination: %{page: 50, per_page: 20, total_pages: 125}
      },
      test_targets: nil
    }
  ]

  @stories Enum.map(@story_specs, fn story ->
             id = story.id

             %{
               story
               | test_targets: %{
                   story: "obpt-data-story-#{id}",
                   snapshot: "showcase/#{id}",
                   a11y: ~s([data-obpt-data-story="#{id}"])
                 }
             }
           end)

  @stories_by_id Map.new(@stories, &{&1.id, &1})

  def stories, do: @stories

  def story!(id) when is_binary(id) do
    Map.fetch!(@stories_by_id, id)
  rescue
    KeyError -> raise ArgumentError, "unknown data-display story: #{inspect(id)}"
  end

  def story!(id), do: raise(ArgumentError, "unknown data-display story: #{inspect(id)}")
  def snapshot_name(id), do: "showcase/#{story!(id).id}"
  def a11y_target(id), do: ~s([data-obpt-data-story="#{story!(id).id}"])
  def large_row_total, do: @large_row_total
  def large_row_window, do: @large_row_window
  def huge_args_fixture, do: @huge_args_fixture
  def long_value_fixture, do: @long_value_fixture
  def timeline_fixture, do: @timeline_fixture
end
