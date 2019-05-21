defmodule ExConfigSimple do
  use Application

  alias ExConfigSimple.Config

  def start(_type, _args) do
    # Set OS level environment variables
    System.put_env("SERVER_ID", "one")
    System.put_env("PG_PASSWORD", "neo")

    IO.inspect(Config.auth_enabled)
    IO.inspect(Config.session_prefix)
    IO.inspect(Config._all)
    IO.inspect(Config.Storage.type)
    IO.inspect(Config.Storage._all)
    IO.inspect(Config.get_buckets)
    IO.inspect(Config.get_bucket(:pub_storage))
    IO.inspect(Config.get_ecto_repo(ExConfigSimple.Repo))

    Supervisor.start_link([], strategy: :one_for_one,
                              name: __MODULE__)
  end
end
