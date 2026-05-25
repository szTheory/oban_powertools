defmodule ObanPowertools.WorkflowCallbackTestHandler do
  @behaviour ObanPowertools.Workflow.CallbackHandler

  def handle_workflow_callback(payload) do
    case :persistent_term.get({__MODULE__, :mode}, :ok) do
      :fail ->
        {:error, :boom}

      :ok ->
        if pid = Process.whereis(:workflow_callback_test) do
          send(pid, {:workflow_callback, payload})
        end

        :ok
    end
  end
end

defmodule ObanPowertools.WorkflowNoopCallbackTestHandler do
  @behaviour ObanPowertools.Workflow.CallbackHandler

  def handle_workflow_callback(_payload), do: :ok
end
