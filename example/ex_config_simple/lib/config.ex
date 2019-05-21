defmodule ExConfigSimple.Config do
  use ExConfig, otp_app: :ex_config_simple

  # Add aliases to make it short.
  # NOTE: Modules have names similar to Elixir core ones.
  alias ExConfig.Type.{Boolean, Integer, String, Enum}
  alias ExConfig.Resource.EctoPostgres

  # We can define any functions.
  defp rand(), do: :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

  # Defining application parameters as:
  # `env <name>[, <type>[, <options>]]`
  env :auth_enabled, Boolean, default: false
  env :request_timeout, Integer, default: 10_000
  env :server_id, String, required: true
  env :main_color, Enum, values: [:red, :green, :blue]
  # Defining "dynamic" parameter, equals to just defining a function,
  # but this way will add parameter into `_all` function results.
  dyn :session_prefix, do: "#{server_id()}_#{rand()}_"

  # Defining nested module to group related parameters together.
  keyword :storage do
    env :type, Enum, values: [:local, :nfs, :s3], default: :local
    env :path, String, default: "/tmp"
    env :permissions, Integer, base: 8, default: 0o644
  end

  # Before defining resource we need list of its instances.
  dyn :buckets, do: [:pub_storage, :priv_storage]
  # Defining resource with name `bucket`,
  # and list of its instances is stored in `buckets`.
  resource :bucket, :buckets do
    env :name, String, required: true
    env :access_key, String, required: true
    env :rate_limit, Integer
  end

  # Also it could use external module which implements
  # `ExConfig.Source` behaviour.
  dyn :ecto_repos, do: [ExConfigSimple.Repo]
  resource :ecto_repo, :ecto_repos, use: EctoPostgres

end
