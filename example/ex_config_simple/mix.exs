defmodule ExConfigSimple.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_config_simple,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:erts, :kernel, :stdlib, :eprof],
        ignore_warnings: ".dialyzer.ignore",
        flags: ["-Wunderspecs", "-Werror_handling"],
      ],
    ]
  end

  def application() do
    [
      extra_applications: [:logger, :tools],
      mod: {ExConfigSimple, []},
    ]
  end

  defp deps() do
    [
      {:ex_config, path: "../../"},
      {:dialyxir, "~> 1.1.0", runtime: false},
      {:benchee, "~> 1.0"},
    ]
  end
end
