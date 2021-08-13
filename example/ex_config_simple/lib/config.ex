defmodule ExConfigSimple.Config do
  use ExConfig, otp_app: :ex_config_simple

  # Add aliases to make it short.
  # NOTE: Modules have names similar to Elixir core ones.
  alias ExConfig.Type.{Boolean, Integer, String, Enum, List}
  alias ExConfig.Resource.EctoPostgres

  @main_colors [:red, :green, :blue]

  # We can define any functions.
  defp rand(), do: :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

  def gethostname(), do: :"Elixir.List".to_string(:inet_db.gethostname())
  env :hostname, String, default: &__MODULE__.gethostname/0

  # Defining application parameters as:
  # `env <name>[, <type>[, <options>]]`
  env :auth_enabled, Boolean, default: false
  env :request_timeout, Integer, default: 10_000
  env :server_id, String, required: true
  env :main_color, Enum, values: @main_colors
  env :extra_colors, List, item: {Integer, range: 0..0xffffff, base: 16}, delim: ","
  # Defining "dynamic" parameter, equals to just defining a function,
  # but this way will add parameter into `_all` function results.
  dyn :session_prefix, do: "#{server_id()}_#{rand()}_"

  # Defining nested module to group related parameters together.
  keyword :storage do
    @supported_fs_types ~w(local nfs s3)a
    def supported_fs_types, do: @supported_fs_types

    env :type, Enum, values: @supported_fs_types, default: :local
    env :path, String, default: "/tmp"
    env :permissions, Integer, base: 8, default: 0o644

    keyword :users do
      env :admins
      env :source, Enum, values: [:local, :ldap, :radius]
    end
  end

  # Before defining resource we need list of its instances.
  dyn :buckets, do: [:pub_storage, :priv_storage]
  # Defining resource with name `bucket`,
  # and list of its instances is stored in `buckets`.
  resource :bucket, :buckets do
    env :name, String, required: true
    env :access_key, String, required: true
    env :rate_limit, Integer

    keyword :permissions do
      env :admin, String, default: "full"
      env :user, String, default: "ro"
    end
  end

  # Also it could use external module which implements
  # `ExConfig.Source` behaviour.
  dyn :ecto_repos, do: [ExConfigSimple.Repo]
  resource :ecto_repo, :ecto_repos, use: EctoPostgres

end
