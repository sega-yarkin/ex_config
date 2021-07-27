
alias ExConfigSimple.Config
require ExConfig.Cache.PersistentTerm
alias ExConfig.Cache.PersistentTerm, as: PTCache # (Erlang OTP 21.2+)
alias ExConfig.Cache.InModule, as: IMCache
alias ExConfigSimple.ConfigCached, as: Cached # Will be generated at runtime

# Init caches
PTCache.wrap(Config)
IMCache.wrap(Config, target: Cached)

uncached_test = fn ->
  Config.auth_enabled
  Config.session_prefix
  Config._all
  Config.Storage.type
  Config.Storage._all
  Config.get_buckets
  Config.get_bucket(:pub_storage)
  Config.get_ecto_repo(ExConfigSimple.Repo)
  :ok
end

uncached_test_no_crypto = fn ->
  Config.auth_enabled
  Config.Storage.type
  Config.Storage._all
  Config.get_buckets
  Config.get_bucket(:pub_storage)
  Config.get_ecto_repo(ExConfigSimple.Repo)
  :ok
end

ptcache_test = fn ->
  PTCache.get.auth_enabled
  PTCache.get.session_prefix
  PTCache.get
  PTCache.get.storage.type
  PTCache.get.storage
  PTCache.get.get_buckets
  PTCache.get.get_bucket[:pub_storage]
  PTCache.get.get_ecto_repo[ExConfigSimple.Repo]
  :ok
end

ptcache_macro_test = fn ->
  import ExConfig.Cache.PersistentTerm, only: [config: 0]
  config.auth_enabled
  config.session_prefix
  config()
  config.storage.type
  config.storage
  config.get_buckets
  config.get_bucket[:pub_storage]
  config.get_ecto_repo[ExConfigSimple.Repo]
  :ok
end

imcache_test = fn ->
  Cached.auth_enabled
  Cached.session_prefix
  Cached._all
  Cached.Storage.type
  Cached.Storage._all
  Cached.get_buckets
  Cached.get_bucket(:pub_storage)
  Cached.get_ecto_repo(ExConfigSimple.Repo)
  :ok
end


Benchee.run(
  %{
    "Uncached"               => uncached_test,
    "Uncached (no crypto)"   => uncached_test_no_crypto,
    "PersistentTerm"         => ptcache_test,
    "PersistentTerm (macro)" => ptcache_macro_test,
    "InModule"               => imcache_test,
  },
  warmup: 5,
  time: 15,
  memory_time: 5,
  unit_scaling: :smallest,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}]
)
