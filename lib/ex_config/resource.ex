defmodule ExConfig.Resource do
  @callback _all(%ExConfig.Mod{}) :: any

  defmacro __using__(opts) do
    opts = Keyword.merge([otp_app: nil], opts)
    quote do
      use ExConfig, unquote(opts)
    end
  end
end

defmodule ExConfig.Resource.EctoPostgres do
  use ExConfig.Resource, options: [only_not_nil: true]
  alias ExConfig.Type.{String, Integer, Boolean, ModuleName}

  dyn :adapter, do: Ecto.Adapters.Postgres
  env :hostname, String
  env :port, Integer, range: 1..65535, default: 5432
  env :database, String
  env :username, String
  env :password, String
  env :pool, ModuleName
  env :ssl, Boolean
  env :ssl_opts
  env :parameters
  env :connect_timeout, Integer
end
