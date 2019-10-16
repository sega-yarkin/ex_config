defmodule ExConfig.Resource.EctoPostgres do
  use ExConfig.Resource, options: [only_not_nil: true]
  alias ExConfig.Type.{Boolean, Integer, ModuleName, String}

  dyn :adapter, do: Ecto.Adapters.Postgres
  env :hostname, String
  env :port, Integer, range: 1..65_535, default: 5432
  env :database, String
  env :username, String
  env :password, String
  env :pool, ModuleName
  env :ssl, Boolean
  env :ssl_opts
  env :parameters
  env :connect_timeout, Integer
end
