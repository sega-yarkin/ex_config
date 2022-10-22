# For tests, support old Elixir versions
config = if match?({:module, _}, Code.ensure_compiled(Config)), do: Config, else: Mix.Config

config.config :ex_config,
  system1: {ExConfig.Source.System, name: "SYSTEM_ENV1"}
