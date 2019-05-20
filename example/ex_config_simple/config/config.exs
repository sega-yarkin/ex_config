use Mix.Config

alias ExConfig.Source.System

config :ex_config_simple,
  auth_enabled: {System, name: "AUTH_ENABLED"},
  request_timeout: 20_000,
  server_id: {System, name: ["INSTANCE_ID", "SERVER_ID"]}
