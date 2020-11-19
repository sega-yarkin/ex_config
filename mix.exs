defmodule ExConfig.MixProject do
  use Mix.Project

  def project() do
    [
      app: :ex_config,
      version: "0.1.4",
      elixir: "~> 1.8",
      deps: deps(),
      description: description(),
      package: package(),
      name: "ExConfig",
      source_url: "https://github.com/sega-yarkin/ex_config",
      dialyzer: [
        plt_add_apps: [:erts, :kernel, :stdlib],
        ignore_warnings: ".dialyzer.ignore",
        flags: [:error_handling, :underspecs, :unmatched_returns, :unknown],
      ],
    ]
  end

  def application() do
    [extra_applications: []]
  end

  defp deps() do
    [
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
    ]
  end

  defp description() do
    "Yet another Elixir app configuration package for fun and profit."
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{github: "https://github.com/sega-yarkin/ex_config"},
      files: ~w(mix.exs README.md LICENSE lib),
    ]
  end
end
