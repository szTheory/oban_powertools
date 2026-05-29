defmodule ObanPowertools.WorkflowFixtures do
  alias ObanPowertools.Workflow

  alias ObanPowertools.WorkflowTestWorkers.{
    FetchCustomerWorker,
    NotifyWorker,
    SyncBillingWorker,
    SyncSupportWorker
  }

  def workflow_fixture(opts \\ []) do
    account_id = Keyword.get(opts, :account_id, 123)

    Workflow.new(
      name: Keyword.get(opts, :name, "sync_customer"),
      workflow_context: %{
        "account_id" => account_id,
        "label" => "Customer sync"
      }
    )
    |> Workflow.add(:fetch_customer, fetch_customer_job(account_id))
    |> Workflow.add(:sync_billing, sync_billing_job(account_id), deps: [:fetch_customer])
    |> Workflow.add(:sync_support, sync_support_job(account_id), deps: [:fetch_customer])
    |> Workflow.add(:notify, notify_job(account_id), deps: [:sync_billing, :sync_support])
  end

  def fetch_customer_job(account_id) do
    FetchCustomerWorker.new(%{"account_id" => account_id})
  end

  def sync_billing_job(account_id) do
    SyncBillingWorker.new(%{
      "account_id" => account_id,
      "customer" => Workflow.result(:fetch_customer)
    })
  end

  def sync_support_job(account_id) do
    SyncSupportWorker.new(%{
      "account_id" => account_id,
      "customer" => Workflow.result(:fetch_customer)
    })
  end

  def notify_job(account_id) do
    NotifyWorker.new(%{
      "account_id" => account_id,
      "billing" => Workflow.result(:sync_billing),
      "support" => Workflow.result(:sync_support)
    })
  end
end
