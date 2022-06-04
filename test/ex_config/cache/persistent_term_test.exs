defmodule ExConfig.Cache.PersistentTermTest do
  use ExUnit.Case, async: false
  require ExConfig.Cache.PersistentTerm
  alias ExConfig.Cache.PersistentTerm, as: PTCache

  @otp_app ExConfigTestApp
  @mod_name ExConfig.PersistentTermTestModule
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

  test "persistent_term cache" do
    assert catch_throw(PTCache.wrap(@mod_name)) ==
              "Parameter 'env2' must be set"

    # Set all variables
    Application.put_env(@otp_app, :env1, "env1_value")
    Application.put_env(@otp_app, :env2, "env2_value")
    Application.put_env(@otp_app, :kw1, [kw1_env1: "not default"])
    [a: [data: "eɪ"], b: [data: "biː"], c: [data: "siː"],
     d: [data: "diː"], e: [data: "iː"], f: [data: "ɛf"],
    ] |> Enum.each(fn {k, v} -> Application.put_env(@otp_app, k, v) end)

    {:ok, cache} = PTCache.wrap(@mod_name)
    assert PTCache.get() == cache
    assert is_map(cache) == true

    # Standard access
    assert PTCache.get.env1 == "env1_value"
    assert PTCache.get.env2 == "env2_value"
    assert PTCache.get.dyn1 == 42
    assert PTCache.get.kw1.kw1_env1 == "not default"
    assert PTCache.get.kw1.kw1_dyn1 == :booo
    assert PTCache.get.get_resource1[:a] == [data: "eɪ"]
    assert PTCache.get.get_resource2[:d] == [data: "diː"]
    assert PTCache.get.get_resource1_names == [a: [data: "eɪ"],
                                               c: [data: "siː"],
                                               b: [data: "biː"]]

    # Access with macro
    assert PTCache.config.env1 == "env1_value"
    assert PTCache.config.env2 == "env2_value"
    assert PTCache.config.dyn1 == 42
    assert PTCache.config.kw1.kw1_env1 == "not default"
    assert PTCache.config.kw1.kw1_dyn1 == :booo
    assert PTCache.config.get_resource1[:a] == [data: "eɪ"]
    assert PTCache.config.get_resource2[:d] == [data: "diː"]
    assert PTCache.config.get_resource1_names == [a: [data: "eɪ"],
                                                  c: [data: "siː"],
                                                  b: [data: "biː"]]

    # Access with macro and options
    assert PTCache.config(id: :default).env1 == "env1_value"
    assert PTCache.config(id: :default).env2 == "env2_value"
    assert PTCache.config(id: :default).dyn1 == 42
    assert PTCache.config(id: :default).kw1.kw1_env1 == "not default"
    assert PTCache.config(id: :default).kw1.kw1_dyn1 == :booo
    assert PTCache.config(id: :default).get_resource1[:a] == [data: "eɪ"]
    assert PTCache.config(id: :default).get_resource2[:d] == [data: "diː"]
    assert PTCache.config(id: :default).get_resource1_names == [a: [data: "eɪ"],
                                                                c: [data: "siː"],
                                                                b: [data: "biː"]]

    Application.put_env(@otp_app, :env2, "env2_another_value")
    assert PTCache.get() == cache
    {:ok, _} = PTCache.wrap(@mod_name)
    assert PTCache.get.env2 == "env2_another_value"
  end
end
