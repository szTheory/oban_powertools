defmodule ObanPowertools.WorkflowTestWorkers.FetchCustomerWorker do
  use ObanPowertools.Worker, queue: :default, args: [account_id: :integer]

  @impl true
  def process(_job), do: :ok
end

defmodule ObanPowertools.WorkflowTestWorkers.SyncBillingWorker do
  use ObanPowertools.Worker, queue: :billing, args: [account_id: :integer, customer: :map]

  @impl true
  def process(_job), do: :ok
end

defmodule ObanPowertools.WorkflowTestWorkers.SyncSupportWorker do
  use ObanPowertools.Worker, queue: :support, args: [account_id: :integer, customer: :map]

  @impl true
  def process(_job), do: :ok
end

defmodule ObanPowertools.WorkflowTestWorkers.NotifyWorker do
  use ObanPowertools.Worker,
    queue: :notifications,
    args: [account_id: :integer, billing: :map, support: :map]

  @impl true
  def process(_job), do: :ok
end
