defmodule Mix.Tasks.ObanPowertools.Assets.Build do
  @moduledoc """
  Builds deterministic Oban Powertools CSS and JavaScript assets.
  """

  use Mix.Task

  @shortdoc "Builds Oban Powertools static assets"

  @source_dir "assets/oban_powertools"
  @static_dir "priv/static/oban_powertools"

  @impl Mix.Task
  def run(_args) do
    File.mkdir_p!(@static_dir)

    copy_normalized(
      Path.join(@source_dir, "tokens.css"),
      Path.join(@static_dir, "oban_powertools.css")
    )

    copy_normalized(
      Path.join(@source_dir, "theme.js"),
      Path.join(@static_dir, "oban_powertools.js")
    )

    Mix.shell().info("Built Oban Powertools assets in #{@static_dir}")
  end

  defp copy_normalized(source, destination) do
    source
    |> File.read!()
    |> normalize()
    |> then(&File.write!(destination, &1))
  end

  defp normalize(contents) do
    contents
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> String.trim_trailing()
    |> Kernel.<>("\n")
  end
end
