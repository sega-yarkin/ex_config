defmodule ExConfig.Type.ModuleNameTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.ModuleName
  alias ExConfig.Param.TypeOptionError

  defp instance(opts \\ []),
    do: ExConfig.Param.create_type_instance(ModuleName, opts)

  test "init/1" do
    assert %ModuleName{} == instance()
    assert %ModuleName{should_exist?: true} == instance()
    assert %ModuleName{should_exist?: false} == instance(should_exist?: false)
    assert_raise TypeOptionError, fn -> instance(should_exist?: :no) end
  end

  describe "handle" do
    test "when valid atom" do
      handle = &ModuleName.handle(&1, instance(should_exist?: &2))

      assert handle.(__MODULE__, true) == {:ok, __MODULE__}
      assert handle.(Enum, true) == {:ok, :"Elixir.Enum"}
      assert handle.(Some, false) == {:ok, :"Elixir.Some"}
      assert handle.(:elixir_module, true) == {:ok, :elixir_module}
    end

    test "when valid non-atom" do
      handle = &ModuleName.handle(&1, instance(should_exist?: &2))

      assert handle.(":lists", true) == {:ok, :lists}
      assert handle.(":some_module", false) == {:ok, :some_module}

      assert handle.("Elixir.Enum", true) == {:ok, :"Elixir.Enum"}
      assert handle.("Elixir.Something", false) == {:ok, :"Elixir.Something"}

      assert handle.("Enum", true) == {:ok, :"Elixir.Enum"}
      assert handle.("Something", false) == {:ok, :"Elixir.Something"}
    end

    test "when invalid input" do
      handle = &ModuleName.handle(&1, instance(should_exist?: &2))
      err_bad = &ModuleName.error(:bad_data, &1)
      err_na = &ModuleName.error(:not_available, &1)

      assert handle.(1, true) == err_bad.(1)
      assert handle.({}, true) == err_bad.({})

      assert handle.(:some_module, true) == err_na.(:some_module)
      assert handle.("Elixir.Something", true) == err_na.("Elixir.Something")
    end
  end
end
