defmodule ExConfig.Type.EnumTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.Enum
  alias ExConfig.Param.TypeOptionError

  defp instance(opts),
    do: ExConfig.Param.create_type_instance(Enum, opts)

  test "init/1" do
    assert %Enum{values: [:a, :b, :c]} == instance(values: [:a, :b, :c])
    assert_raise TypeOptionError, fn -> instance([]) end
    assert_raise TypeOptionError, fn -> instance(values: []) end
    assert_raise TypeOptionError, fn -> instance(values: ["a"]) end
    assert_raise TypeOptionError, fn -> instance(values: [:a, :b, "c"]) end
  end

  test "handle" do
    handle = &Enum.handle(&1, instance(values: &2))
    err_bad = &Enum.error(:bad_data, &1)
    err_wrong = &Enum.error(:wrong_value, {&1, &2})

    assert handle.(:a, [:a, :b, :c]) == {:ok, :a}
    assert handle.("a", [:a, :b, :c]) == {:ok, :a}

    assert handle.(1, [:a, :b, :c]) == err_bad.(1)
    assert handle.('a', [:a, :b, :c]) == err_bad.('a')

    assert handle.(:d, [:a, :b, :c]) == err_wrong.(:d, [:a, :b, :c])
    assert handle.("d", [:a, :b, :c]) == err_wrong.(:d, [:a, :b, :c])
    assert handle.("random_nonexistent_atom", [:a, :b, :c]) == err_wrong.("random_nonexistent_atom", [:a, :b, :c])
  end
end
