defmodule ExConfig.ModTest do
  use ExUnit.Case, async: true
  @compile {:no_warn_undefined, ExConfig.ModTestModule}
  @compile {:no_warn_undefined, ExConfig.ModTestModule.Kw1}

  @otp_app ExConfigTestApp
  @mod_name ExConfig.ModTestModule
  defp mod_create(content, mod \\ @mod_name),
    do: Module.create(mod, content, Macro.Env.location(__ENV__))

  defp mod_data(mod \\ @mod_name), do: hd(mod.module_info(:attributes)[:data])

  defp mod_meta(name), do: @mod_name.__meta__()[name] |> Map.new()

  setup_all do
    content =
      quote do
        use ExConfig.Mod, otp_app: unquote(@otp_app)
        alias ExConfig.Type.String

        env :env1
        env :env2, ExConfig.Type.Integer, range: 1..100, default: 32
        env :env3, String, required: true

        dyn :dyn1, do: 42

        keyword :kw1 do
          env :kw1_env1, String, default: "default"
          dyn :kw1_dyn1, do: :booo

          keyword :kw11 do
            env :kw11_env1, String, default: "go deeeeper!"

            keyword :kw111 do
              env :kw111_env1, ExConfig.Type.Integer, default: 111
            end
          end
        end

        dyn :resource1_names, do: [:a, :c, :b]
        resource :resource1, :resource1_names do
          env :data, String
        end

        dyn :resource2_keys, do: [:d, :e, :f]
        resource :resource2, :resource2_keys, use: unquote(@mod_name).Resource1

        resource :resource3, use: unquote(@mod_name).Resource1

        resource :resource4 do
          env :data4, String
          keyword :nested do
            env :key1, String, default: "key-one"
          end
        end
      end

    {:module, @mod_name, _, _} = mod_create(content)
    on_exit(fn ->
      for mod <- [@mod_name, @mod_name.Kw1, @mod_name.Resource1, @mod_name.Resource4] do
        :code.purge(mod)
        :code.delete(mod)
      end
      @otp_app
      |> Application.get_all_env()
      |> Keyword.keys()
      |> Enum.each(&Application.delete_env(@otp_app, &1))
    end)
  end

  test "using" do
    assert mod_data() == %ExConfig.Mod{otp_app: @otp_app}
  end

  test "using 2" do
    mod_name = ExConfig.ModTestModuleUsing2
    content =
      quote do
        alias ExConfig.Type
        use ExConfig.Mod, otp_app: unquote(@otp_app),
                          path: [:nested, Type.String]
      end
    {:module, ^mod_name, _, _} = mod_create(content, mod_name)
    assert %ExConfig.Mod{otp_app: @otp_app, path: path} = mod_data(mod_name)
    assert path == [:nested, ExConfig.Type.String]
    :code.purge(mod_name)
  end

  test "env" do
    params = mod_meta(:parameters)
    keys = [:name, :type, :default, :required?]
    assert Map.take(params[:env1], keys) ==
          %{name: :env1, type: %ExConfig.Type.Raw{}, default: nil, required?: false}
    assert Map.take(params[:env2], keys) ==
          %{name: :env2, type: %ExConfig.Type.Integer{range: {1, 100}}, default: 32, required?: false}
    assert Map.take(params[:env3], keys) ==
          %{name: :env3, type: %ExConfig.Type.String{}, default: nil, required?: true}

    assert @mod_name.env1 == nil
    assert @mod_name.env2 == 32
    assert catch_throw(@mod_name.env3) == "Parameter 'env3' must be set"

    Application.put_env(@otp_app, :env1, 'env1_value')
    Application.put_env(@otp_app, :env2, "64")
    Application.put_env(@otp_app, :env3, 'env3_value')
    assert @mod_name.env1 == 'env1_value'
    assert @mod_name.env2 == 64
    assert @mod_name.env3 == "env3_value"
  end

  test "dyn" do
    params = mod_meta(:parameters)
    assert Map.has_key?(params, :dyn1)
    assert @mod_name.dyn1 == 42
  end

  test "keyword" do
    assert mod_data(@mod_name.Kw1) ==
            %ExConfig.Mod{otp_app: @otp_app, path: [:kw1]}
    assert mod_data(@mod_name.Kw1.Kw11) ==
            %ExConfig.Mod{otp_app: @otp_app, path: [:kw1, :kw11]}
    assert mod_data(@mod_name.Kw1.Kw11.Kw111) ==
            %ExConfig.Mod{otp_app: @otp_app, path: [:kw1, :kw11, :kw111]}
    kws = mod_meta(:keywords)
    assert kws[:kw1] == @mod_name.Kw1

    assert @mod_name.Kw1.kw1_env1 == "default"
    assert @mod_name.Kw1.kw1_dyn1 == :booo
    assert @mod_name.Kw1._all == [kw11: [
                                    kw111: [kw111_env1: 111],
                                    kw11_env1: "go deeeeper!",
                                  ],
                                  kw1_dyn1: :booo,
                                  kw1_env1: "default"]

    Application.put_env(@otp_app, :kw1, [kw1_env1: "not default",
                                         kw1_dyn1: :useless,
                                         kw11: [
                                          kw111: [kw111_env1: 222],
                                          kw11_env1: "indeed!",
                                         ]])
    assert @mod_name.Kw1.kw1_env1 == "not default"
    assert @mod_name.Kw1.kw1_dyn1 == :booo
    assert @mod_name.Kw1._all == [kw11: [
                                    kw111: [kw111_env1: 222],
                                    kw11_env1: "indeed!",
                                  ],
                                  kw1_dyn1: :booo,
                                  kw1_env1: "not default"]
  end

  test "resource" do
    assert mod_data(@mod_name.Resource1) ==
            %ExConfig.Mod{otp_app: @otp_app, path: [:resource1]}
    assert mod_data(@mod_name.Resource4) ==
            %ExConfig.Mod{otp_app: @otp_app, path: [:resource4]}
    assert mod_data(@mod_name.Resource4.Nested) ==
            %ExConfig.Mod{otp_app: @otp_app, path: [:resource4, :nested]}
    assert_raise UndefinedFunctionError, fn -> mod_data(@mod_name.Resource2) end
    assert_raise UndefinedFunctionError, fn -> mod_data(@mod_name.Resource3) end
    resources = mod_meta(:resources)
    assert resources[:resource1] == %{all: :get_resource1_names, one: :get_resource1}
    assert resources[:resource2] == %{all: :get_resource2_keys , one: :get_resource2}
    assert resources[:resource3] == nil
    assert resources[:resource4] == nil

    assert function_exported?(@mod_name, :get_resource1_names, 0) == true
    assert function_exported?(@mod_name, :get_resource1, 1) == true
    assert function_exported?(@mod_name, :get_resource2_keys, 0) == true
    assert function_exported?(@mod_name, :get_resource2, 1) == true
    assert function_exported?(@mod_name, :resource3, 0) == true
    assert function_exported?(@mod_name, :resource4, 0) == true

    assert @mod_name.get_resource1(:a) == [data: nil]
    assert @mod_name.get_resource1(:d) == [data: nil]
    assert @mod_name.get_resource2(:a) == [data: nil]
    assert @mod_name.get_resource2(:d) == [data: nil]
    assert Keyword.keys(@mod_name.get_resource1_names()) == @mod_name.resource1_names()
    assert Keyword.keys(@mod_name.get_resource2_keys()) == @mod_name.resource2_keys()
    assert @mod_name.resource3() == [data: nil]
    assert @mod_name.resource4() == [data4: nil, nested: [key1: "key-one"]]

    [a: [data: "eɪ"], b: [data: "biː"], c: [data: "siː"],
     d: [data: "diː"], e: [data: "iː"], f: [data: "ɛf"],
     resource3: [data: "three"], resource4: [data4: "four", nested: [key1: "key-1"]],
    ] |> Enum.each(fn {k, v} -> Application.put_env(@otp_app, k, v) end)

    assert @mod_name.get_resource1(:a) == [data: "eɪ"]
    assert @mod_name.get_resource1(:d) == [data: "diː"]
    assert @mod_name.get_resource2(:a) == [data: "eɪ"]
    assert @mod_name.get_resource2(:d) == [data: "diː"]
    assert @mod_name.get_resource1_names() == [a: [data: "eɪ"], c: [data: "siː"], b: [data: "biː"]]
    assert @mod_name.get_resource2_keys() == [d: [data: "diː"], e: [data: "iː"], f: [data: "ɛf"]]
    assert @mod_name.resource3() == [data: "three"]
    assert @mod_name.resource4() == [data4: "four", nested: [key1: "key-1"]]
  end
end
