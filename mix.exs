defmodule ExConfig.MixProject do
  use Mix.Project

  def project() do
    [
      app: :ex_config,
      version: "0.1.1",
      elixir: "~> 1.8",
      deps: deps(),
      description: description(),
      package: package(),
      name: "ExConfig",
      source_url: "https://github.com/sega-yarkin/ex_config",
      dialyzer: [
        plt_add_apps: [:erts, :kernel, :stdlib],
        ignore_warnings: ".dialyzer.ignore",
        flags: ["-Werror_handling", "-Wunderspecs", "-Wunmatched_returns", "-Wunknown"],
      ],
    ]
  end

  def application() do
    [extra_applications: []]
  end

  defp deps() do
    [
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
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
