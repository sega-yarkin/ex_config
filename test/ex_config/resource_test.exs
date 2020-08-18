defmodule ExConfig.ResourceTest do
  use ExUnit.Case, async: false

  @mod_name ExConfig.ResourceTestModule
  defp mod_create(content),
    do: Module.create(@mod_name, content, Macro.Env.location(__ENV__))

  defp mod_data(), do: hd(@mod_name.module_info(:attributes)[:data])

  test "using" do
    content =
      quote do
        use ExConfig.Resource, options: [opt1: :option1]
      end

    {:module, @mod_name, _, _} = mod_create(content)
    assert %ExConfig.Mod{otp_app: nil, options: [opt1: :option1]} == mod_data()
    :code.purge(@mod_name)
    :code.delete(@mod_name)
  end

end
