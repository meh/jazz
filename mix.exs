defmodule Jazz.Mixfile do
  use Mix.Project

  def project do
    [ app: :jazz,
      version: "0.2.1",
      package: package,
      description: "JSON handling library for Elixir.",
      consolidate_protocols: Mix.env != :test ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/jazz"} ]
  end
end
