defmodule ExConfig.MixProject do
  use Mix.Project

  @source_url "https://github.com/sega-yarkin/ex_config"
  @version "0.2.1"

  def project() do
    [
      app: :ex_config,
      version: @version,
      elixir: "~> 1.8",
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :dev],
      dialyzer: dialyzer(),
    ]
  end

  def application do
    [extra_applications: []]
  end

  defp deps do
    [
      {:credo, "~> 1.6.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.1.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.4", only: :dev, runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_apps: [:erts, :kernel, :stdlib],
      ignore_warnings: ".dialyzer_ignore.exs",
      flags: [:error_handling, :underspecs, :unmatched_returns, :unknown],
    ]
  end

  defp description do
    "Yet another Elixir app configuration package for fun and profit."
  end

  defp package do
    [
      files: ~w(mix.exs README.md LICENSE lib),
      licenses: ["MIT"],
      links: %{GitHub: @source_url},
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "ExConfig",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/ex_config",
      source_url: @source_url,
      extras: ["README.md"],
    ]
  end
end
