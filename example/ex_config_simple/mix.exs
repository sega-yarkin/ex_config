defmodule ExConfigSimple.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_config_simple,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  def application() do
    [
      extra_applications: [:logger],
      mod: {ExConfigSimple, []},
    ]
  end

  defp deps() do
    [
      {:ex_config, path: "../../"},
      {:benchee, "~> 1.0"},
      {:exprof, "~> 0.2.0"},
    ]
  end
end