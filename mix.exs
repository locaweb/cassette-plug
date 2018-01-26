defmodule Cassette.Plug.Mixfile do
  use Mix.Project

  def version, do: "1.1.2"

  def project do
    [app: :cassette_plug,
     version: version(),
     elixir: "~> 1.3",
     description: "An auth Plug using Cassette",
     elixirc_paths: elixirc_paths(Mix.env),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/locaweb/cassette-plug",
     homepage_url: "http://developer.locaweb.com.br/",
     docs: [
       extras: ["README.md", "CONTRIBUTING.md"],
     ],
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test,
                         "coveralls.detail": :test,
                         "coveralls.html": :test],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :cassette]]
  end

  def package do
   [
       files: ["lib", "mix.exs", "README.md", "LICENSE.md", "CONTRIBUTING.md"],
       maintainers: ["Ricardo Hermida Ruiz"],
       licenses: ["MIT"],
       links: %{"GitHub" => "https://github.com/locaweb/cassette-plug",
                "Docs" => "https://hexdocs.pm/cassette_plug/#{version()}"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:ex_doc, "~> 0.11", only: :dev},
      {:earmark, "~> 1.0", only: :dev},
      {:dialyze, "~> 0.2", only: :test},
      {:cassette, "~> 1.0"},
      {:credo, "~> 0.5", only: [:dev, :test], runtime: false},
      {:plug, "~> 1.0"},
      {:excoveralls, "~> 0.7", only: :test}
    ]
  end
end
