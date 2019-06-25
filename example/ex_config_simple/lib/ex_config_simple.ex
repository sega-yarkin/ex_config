defmodule ExConfigSimple do
  use Application

  alias ExConfigSimple.Config

  # Also add testing cached modules:
  # 1) First one uses :persistent_term (Erlang OTP 21.2+).
  alias ExConfig.Cache.PersistentTerm, as: PTCache
  # 2) Second one compiles data into Elixir module.
  alias ExConfig.Cache.InModule, as: IMCache
  alias ExConfigSimple.ConfigCached, as: Cached

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

  # Do caching at application module load time.
  @on_load :compile_config
  def compile_config() do
    test_cached_pt_init()
    test_cached_im_init()
    :ok
  end

  def test_cached_pt_init(), do: PTCache.wrap(Config)
  def test_cached_pt() do
    config = PTCache.get()
    [
      config.auth_enabled,
      config.session_prefix,
      config.storage.type,
      config.get_buckets,
      config.get_bucket[:pub_storage],
      config.get_ecto_repo[ExConfigSimple.Repo],
    ]
  end

  def test_cached_im_init(), do: IMCache.wrap(Config, target: Cached)
  def test_cached_im() do
    [
      Cached.auth_enabled,
      Cached.session_prefix,
      Cached._all,
      Cached.Storage.type,
      Cached.Storage._all,
      Cached.get_buckets,
      Cached.get_bucket(:pub_storage),
      Cached.get_ecto_repo(ExConfigSimple.Repo),
    ]
  end


  #
  # Simple benchmarks
  #

  defp bench1_(0), do: :ok
  defp bench1_(n) do
    test()
    bench1_(n-1)
  end
  def bench1(n) do
    :timer.tc(&bench1_/1, [n])
  end

  defp bench2_(0), do: :ok
  defp bench2_(n) do
    test_cached_pt()
    bench2_(n-1)
  end
  def bench2(n) do
    :timer.tc(&bench2_/1, [n])
  end

  defp bench3_(0), do: :ok
  defp bench3_(n) do
    test_cached_im()
    bench3_(n-1)
  end
  def bench3(n) do
    :timer.tc(&bench3_/1, [n])
  end
end
