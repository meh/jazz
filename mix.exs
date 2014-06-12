defmodule Jazz.Mixfile do
  use Mix.Project

  def project do
    [ app: :jazz,
      version: "0.1.0",
      elixir: "~> 0.14.0",
      package: package,
      description: "JSON handling library for Elixir." ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: [ { "GitHub", "https://github.com/meh/jazz" } ] ]
  end
end
