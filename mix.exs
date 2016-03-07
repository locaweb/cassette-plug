defmodule Cassette.Plug.Mixfile do
  use Mix.Project

  def project do
    [app: :cassette_plug,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/locaweb/cassette-plug",
     homepage_url: "http://developer.locaweb.com.br/",
     docs: [
       extras: ["README.md", "CONTRIBUTING.md"],
     ],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cassette]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 0.1", only: :dev},
      {:dialyze, "~> 0.2", only: :test},
      {:cassette, "~> 1.0"},
      {:plug, "~> 1.0"},
    ]
  end
end
