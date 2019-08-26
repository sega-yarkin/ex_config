defmodule ExConfigSimple do
  use Application
  alias ExConfigSimple.Config

  def start(_type, _args) do
    Supervisor.start_link([], strategy: :one_for_one,
                              name: __MODULE__)
  end

  # Get various parameters
  def test() do
    [
      Config.auth_enabled,
      Config.session_prefix,
      Config._all,
      Config.Storage.type,
      Config.Storage._all,
      Config.get_buckets,
      Config.get_bucket(:pub_storage),
      Config.get_ecto_repo(ExConfigSimple.Repo),
    ]
  end
end
