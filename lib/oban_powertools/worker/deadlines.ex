defmodule ObanPowertools.Worker.Deadlines do
  @moduledoc false

  @meta_key "__deadline_at__"

  def meta_key, do: @meta_key

  def normalize_duration!(value, _label) when is_integer(value) and value > 0, do: value

  def normalize_duration!(value, label) do
    raise ArgumentError, "expected #{label} to be a positive integer, got: #{inspect(value)}"
  end

  def build_meta(nil, _now), do: %{}

  def build_meta(duration_ms, now) when is_integer(duration_ms) and duration_ms > 0 do
    deadline_at =
      now
      |> DateTime.add(duration_ms, :millisecond)
      |> DateTime.to_iso8601()

    %{meta_key() => deadline_at}
  end

  def expired?(meta, now \\ DateTime.utc_now())

  def expired?(%{} = meta, %DateTime{} = now) do
    with deadline_at when is_binary(deadline_at) <- Map.get(meta, meta_key()),
         {:ok, parsed_at, _offset} <- DateTime.from_iso8601(deadline_at) do
      DateTime.compare(parsed_at, now) == :lt
    else
      _missing_or_malformed -> false
    end
  end

  def expired?(_meta, _now), do: false
end
