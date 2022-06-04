defmodule ExConfig.Cache.InModuleTest do
  use ExUnit.Case, async: false
  alias ExConfig.Cache.InModule, as: IMCache

  @compile {:no_warn_undefined, ExConfig.InModuleTestModuleCache}
  @compile {:no_warn_undefined, ExConfig.InModuleTestModuleCache.Kw1}

  @otp_app ExConfigTestApp
  @mod_name  ExConfig.InModuleTestModuleOrig
  @mod_cache ExConfig.InModuleTestModuleCache
  defp mod_create(content),
    do: Module.create(@mod_name, content, Macro.Env.location(__ENV__))

  setup_all do
    content =
      quote do
        use ExConfig.Mod, otp_app: unquote(@otp_app)
        alias ExConfig.Type.String

        env :env1
        env :env2, String, required: true
        dyn :dyn1, do: 42

        keyword :kw1 do
          env :kw1_env1, String, default: "default"
          dyn :kw1_dyn1, do: :booo
        end

        dyn :resource1_names, do: [:a, :c, :b]
        resource :resource1, :resource1_names do
          env :data, String
        end

        dyn :resource2_keys, do: [:d, :e, :f]
        resource :resource2, :resource2_keys, use: unquote(@mod_name).Resource1
      end

    {:module, @mod_name, _, _} = mod_create(content)
    on_exit(fn ->
      for mod <- [@mod_name, @mod_name.Kw1, @mod_name.Resource1] do
        :code.purge(mod)
        :code.delete(mod)
      end
      @otp_app
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(@otp_app, &1))
    end)
  end

  test "in_module cache" do
    assert catch_throw(IMCache.wrap(@mod_name, target: @mod_cache)) ==
              "Parameter 'env2' must be set"

    # Set all variables
    Application.put_env(@otp_app, :env1, "env1_value")
    Application.put_env(@otp_app, :env2, "env2_value")
    Application.put_env(@otp_app, :kw1, [kw1_env1: "not default"])
    [a: [data: "eɪ"], b: [data: "biː"], c: [data: "siː"],
     d: [data: "diː"], e: [data: "iː"], f: [data: "ɛf"],
    ] |> Enum.each(fn {k, v} -> Application.put_env(@otp_app, k, v) end)

    assert IMCache.wrap(@mod_name, target: @mod_cache) == {:ok, @mod_cache}
    assert IMCache.get(target: @mod_cache) == @mod_cache

    assert @mod_cache.env1 == "env1_value"
    assert @mod_cache.env2 == "env2_value"
    assert @mod_cache.dyn1 == 42
    assert @mod_cache.Kw1.kw1_env1 == "not default"
    assert @mod_cache.Kw1.kw1_dyn1 == :booo
    assert @mod_cache.get_resource1(:a) == [data: "eɪ"]
    assert @mod_cache.get_resource2(:d) == [data: "diː"]
    assert @mod_cache.get_resource1_names() == [a: [data: "eɪ"],
                                                c: [data: "siː"],
                                                b: [data: "biː"]]

    Application.put_env(@otp_app, :env2, "env2_another_value")
    assert @mod_cache.env2 == "env2_value"
    assert IMCache.wrap(@mod_name, target: @mod_cache) == {:ok, @mod_cache}
    assert @mod_cache.env2 == "env2_another_value"
  end
end
