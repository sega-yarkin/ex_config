defmodule ExConfig.Resource.EctoPostgres do
  use ExConfig.Resource, options: [only_not_nil: true]
  alias ExConfig.Type.{Boolean, Integer, ModuleName, String}

  dyn :adapter, do: Ecto.Adapters.Postgres

  # Server hostname and port.
  env :hostname, String
  env :port, Integer, range: 1..65_535, default: 5432

  # Connect to Postgres via UNIX sockets in the given directory.
  # This is the preferred method for configuring sockets
  # and it takes precedence over the hostname.
  # If you are connecting to a socket outside of the Postgres convention,
  # use :socket instead.
  env :socket_dir, String
  # Connect to Postgres via UNIX sockets in the given path.
  env :socket, String

  # The database to connect to.
  env :database, String
  # Username and passowrd.
  env :username, String
  env :password, String

  # The connection pool module.
  env :pool, ModuleName
  # Set to true if ssl should be used.
  env :ssl, Boolean
  # A list of ssl options, see Erlang's ssl docs (https://erlang.org/doc/man/ssl.html).
  env :ssl_opts
  # Keyword list of connection parameters.
  env :parameters
  # The timeout for establishing new connections.
  env :connect_timeout, Integer, range: {:gt, 0}
end
