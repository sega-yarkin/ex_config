defmodule ExConfigTest do
  use ExUnit.Case, async: false
  # doctest ExConfig

  @otp_app ExConfigTestApp
  @mod_name ExConfigTestModule
  defp mod_create(content),
    do: Module.create(@mod_name, content, Macro.Env.location(__ENV__))

  defp mod_data(), do: hd(@mod_name.module_info(:attributes)[:data])

  setup do
    :code.purge(@mod_name)
    :code.delete(@mod_name)
    :ok
  end

  describe "using" do
    test "minimal" do
      content =
        quote do
          use ExConfig, otp_app: unquote(@otp_app)
        end

      {:module, @mod_name, _, _} = mod_create(content)
      assert %ExConfig.Mod{otp_app: @otp_app} == mod_data()
    end

    test "missing otp_app" do
      content =
        quote do
          use ExConfig
        end

      assert_raise ArgumentError, "'otp_app' option is required", fn ->
        mod_create(content)
      end
    end

    test "with options" do
      content =
        quote do
          use ExConfig, otp_app: unquote(@otp_app),
                        options: [only_not_nil: true]
        end

      {:module, @mod_name, _, _} = mod_create(content)
      assert %ExConfig.Mod{otp_app: @otp_app,
                           options: [only_not_nil: true]} == mod_data()
    end
  end

end
