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

  def prof_test(n \\ 10_000) do
    fun = fn -> prof_test0(n) end
    :eprof.profile(fun)
    :eprof.analyze(:total, sort: :mfa, # time | calls | mfa
                           filter: [calls: n])
  end

  defp prof_test0(0), do: :ok
  defp prof_test0(n) do
    Config.auth_enabled
    Config.Storage.type
    Config.Storage._all
    Config.get_buckets
    Config.get_bucket(:pub_storage)
    Config.get_ecto_repo(ExConfigSimple.Repo)
    prof_test0(n-1)
  end

  @spec spec_test() :: boolean
  def spec_test() do
    Config.auth_enabled
  end
end
