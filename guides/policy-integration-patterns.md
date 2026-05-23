# Policy Integration Patterns

The host owns auth, authorization, durable audit identity, and display/redaction posture. That is
not optional glue around Powertools; it is part of the public contract.

## Auth seam shape

The configured `auth_module` should implement `ObanPowertools.Auth`:

```elixir
defmodule MyAppWeb.ObanPowertoolsAuth do
  @behaviour ObanPowertools.Auth

  @impl true
  def current_actor(%Plug.Conn{assigns: %{current_user: user}}), do: user
  def current_actor(%{"current_user" => user}), do: user
  def current_actor(_), do: nil

  @impl true
  def authorize(nil, _action, _resource), do: {:error, :unauthorized}

  def authorize(%{role: :ops}, _action, _resource), do: :ok
  def authorize(_actor, _action, _resource), do: {:error, :unauthorized}

  @impl true
  def audit_principal(%{id: id, email: email}) do
    %{id: to_string(id), type: :user, label: email}
  end
end
```

The key responsibilities are distinct:

- `current_actor/1` extracts the current operator from the host session or socket context
- `authorize/3` decides whether a page or mutation is allowed
- `audit_principal/1` returns the stable identity stored on immutable operator events

Do not collapse those into a single “is admin?” helper if your production app needs clearer
operator attribution.

## Display policy seam shape

The configured `display_policy` module should expose `display/3`.

The configured `display_policy` owns redaction and human-readable rendering:

```elixir
defmodule MyAppWeb.ObanPowertoolsDisplayPolicy do
  def display(:actor_label, actor, _context), do: actor.email
  def display(:reason, reason, _context), do: reason

  def display(:workflow_result, result, _context) do
    %{summary: "Result available", payload: "[redacted]", redacted?: true, status: result.status}
  end

  def display(_kind, _value, _context), do: nil
end
```

Use it to control:

- actor labels shown in native pages
- reason text rendering
- workflow result payload visibility
- any host-specific redaction of sensitive job metadata

## Read-only vs mutation posture

Powertools-native pages are the supported mutation surface. Your policy should make the read-only
case explicit instead of pretending unauthorized operators can “almost mutate.”

Practical pattern:

- allow broad page visibility for trusted support or SRE roles
- gate preview and execute actions separately in `authorize/3`
- keep the optional `/ops/jobs/oban` bridge read-only even for operators with broader native
  mutation permissions

## Multi-tenant and support patterns

For real Phoenix SaaS apps, decide these seams deliberately:

- whether operators can cross tenant boundaries
- what tenant context must be visible in audit labels
- which payloads are redacted by default
- whether support impersonation is allowed and how it is labeled durably

If those answers are fuzzy, the library is not your real risk. The host policy is.
