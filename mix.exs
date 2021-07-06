defmodule ExConfig.MixProject do
  use Mix.Project

  def project() do
    [
      app: :ex_config,
      version: "0.2.0",
      elixir: "~> 1.8",
      deps: deps(),
      description: description(),
      package: package(),
      name: "ExConfig",
      source_url: "https://github.com/sega-yarkin/ex_config",
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_apps: [:erts, :kernel, :stdlib],
        ignore_warnings: ".dialyzer_ignore.exs",
        flags: [:error_handling, :underspecs, :unmatched_returns, :unknown],
      ],
    ]
  end

  def application() do
    [extra_applications: []]
  end

  defp deps() do
    [
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5.0", only: [:dev, :test], runtime: false},
    ]
  end

  defp description() do
    "Yet another Elixir app configuration package for fun and profit."
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/sega-yarkin/ex_config"},
      files: ~w(mix.exs README.md LICENSE lib),
    ]
  end
end
