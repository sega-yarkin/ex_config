use Mix.Config

alias ExConfig.Source.System

config :ex_config_simple,
  auth_enabled: {System, name: "AUTH_ENABLED"},
  request_timeout: 20_000,
  server_id: {System, name: ["INSTANCE_ID", "SERVER_ID"]}

config :ex_config_simple, :storage,
  type: "nfs",
  permissions: "777"

config :ex_config_simple, :pub_storage,
  name: "buckets/public",
  access_key: "public-key",
  rate_limit: 1_000

config :ex_config_simple, :priv_storage,
  name: "buckets/private",
  access_key: "secret-key"

config :ex_config_simple, ExConfigSimple.Repo,
  hostname: "127.0.0.1",
  port: "5433",
  database: "example",
  username: "postgres",
  password: {System, name: "PG_PASSWORD"}
