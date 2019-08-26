defmodule ExConfig.Type.NumberTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.Number
  alias ExConfig.Param.TypeOptionError

  defp instance(opts \\ []),
    do: ExConfig.Param.create_type_instance(Number, opts)

  test "init/1" do
    assert %Number{} == instance([])
    assert %Number{range: {2, 10}} == instance(range: 2..10)
    assert %Number{range: {2, 10}} == instance(range: 10..2)
    assert_raise TypeOptionError, fn -> instance(range: 1) end
  end

  describe "parsing" do
    test "when valid number" do
      handle = &Number.handle(&1, instance())

      assert handle.(42) == {:ok, 42.0}
      assert handle.(-42) == {:ok, -42.0}
      assert handle.(0) == {:ok, 0.0}
      assert handle.(12345678901234567890) == {:ok, 1.2345678901234567e19}
      assert handle.(0.0001) == {:ok, 0.0001}
    end

    test "when valid string" do
      handle = &Number.handle(&1, instance())

      assert handle.("42") == {:ok, 42.0}
      assert handle.("-42") == {:ok, -42.0}
      assert handle.("0") == {:ok, 0.0}
      assert handle.("12345678901234567890") == {:ok, 1.2345678901234567e19}
      assert handle.("0.0001") == {:ok, 0.0001}
      assert handle.("12345.67890") == {:ok, 12345.6789}
      assert handle.("-0.000004") == {:ok, -0.000004}
      assert handle.("  -0.04  ") == {:ok, -0.04}
    end

    test "when valid charlist" do
      handle = &Number.handle(&1, instance())

      assert handle.('42') == {:ok, 42.0}
      assert handle.('-42') == {:ok, -42.0}
      assert handle.('0') == {:ok, 0.0}
      assert handle.('12345678901234567890') == {:ok, 1.2345678901234567e19}
      assert handle.('0.0001') == {:ok, 0.0001}
      assert handle.('12345.67890') == {:ok, 12345.6789}
      assert handle.('-0.000004') == {:ok, -0.000004}
    end

    test "when invalid data" do
      handle = &Number.handle(&1, instance())
      err = &Number.error(:bad_data, &1)

      assert handle.("0.01.01") == err.("0.01.01")
      assert handle.('0.01.01') == err.("0.01.01")
      assert handle.("") == err.("")
      assert handle.("abc") == err.("abc")
      assert handle.(nil) == err.(nil)
      assert handle.(:ok) == err.(:ok)
    end
  end

  describe "with range" do
    test "when number is in" do
      handle = &Number.handle(&1, instance(range: &2))

      assert handle.(100, {0, 100}) == {:ok, 100}
      assert handle.(100, 0..100) == {:ok, 100}
      assert handle.(100, 100..0) == {:ok, 100}
      assert handle.(100, {:gt, 99}) == {:ok, 100}
      assert handle.(100, {:ge, 100}) == {:ok, 100}
      assert handle.(100, {:lt, 101}) == {:ok, 100}
      assert handle.(100, {:le, 100}) == {:ok, 100}
    end

    test "when number is out" do
      handle = &Number.handle(&1, instance(range: &2))
      err = &Number.error(:out_of_range, {&1/1, &2})

      assert handle.(101, {0, 100}) == err.(101, {0, 100})
      assert handle.(101, 0..100) == err.(101, {0, 100})
      assert handle.(101, 100..0) == err.(101, {0, 100})
      assert handle.(0, {:gt, 100}) == err.(0, {:gt, 100})
      assert handle.(0, {:ge, 100}) == err.(0, {:ge, 100})
      assert handle.(101, {:lt, 100}) == err.(101, {:lt, 100})
      assert handle.(101, {:le, 100}) == err.(101, {:le, 100})
    end
  end

end
