defmodule ExConfig.Type.IntegerTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.{Integer, Number}
  alias ExConfig.Param.TypeOptionError

  defp instance(opts \\ []),
    do: ExConfig.Param.create_type_instance(Integer, opts)

  test "init/1" do
    assert %Integer{} == instance()
    assert %Integer{base: 10} == instance()
    assert %Integer{base: 2} == instance(base: 2)
    assert %Integer{range: {2, 10}} == instance(range: 2..10)
    assert %Integer{range: {2, 10}} == instance(range: 10..2)
    assert %Integer{range: {2, 10}, base: 2} == instance(range: 10..2, base: 2)

    assert_raise TypeOptionError, fn -> instance(range: 1) end
    assert_raise TypeOptionError, fn -> instance(base: 1) end
    assert_raise TypeOptionError, fn -> instance(base: 40) end
  end

  describe "parsing" do
    test "when valid number" do
      handle = &Integer.handle(&1, instance())

      assert handle.(42) == {:ok, 42}
      assert handle.(-42) == {:ok, -42}
      assert handle.(0) == {:ok, 0}
      assert handle.(12345678901234567890) == {:ok, 12345678901234567890}
    end

    test "when valid string" do
      handle = &Integer.handle(&1, instance())

      assert handle.("42") == {:ok, 42}
      assert handle.("-42") == {:ok, -42}
      assert handle.("0") == {:ok, 0}
      assert handle.("12345678901234567890") == {:ok, 12345678901234567890}
      assert handle.("  -4  ") == {:ok, -4}
    end

    test "when valid charlist" do
      handle = &Integer.handle(&1, instance())

      assert handle.('42') == {:ok, 42}
      assert handle.('-42') == {:ok, -42}
      assert handle.('0') == {:ok, 0}
      assert handle.('12345678901234567890') == {:ok, 12345678901234567890}
    end

    test "when invalid data" do
      handle = &Integer.handle(&1, instance())
      err = &Integer.error(:bad_data, &1)

      assert handle.("0.01") == err.("0.01")
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
      handle = &Integer.handle(&1, instance(range: &2))

      assert handle.(100, {0, 100}) == {:ok, 100}
      assert handle.(100, 0..100) == {:ok, 100}
      assert handle.(100, 100..0) == {:ok, 100}
      assert handle.(100, {:gt, 99}) == {:ok, 100}
      assert handle.(100, {:ge, 100}) == {:ok, 100}
      assert handle.(100, {:lt, 101}) == {:ok, 100}
      assert handle.(100, {:le, 100}) == {:ok, 100}
    end

    test "when number is out" do
      handle = &Integer.handle(&1, instance(range: &2))
      err = &Number.error(:out_of_range, {&1, &2})

      assert handle.(101, {0, 100}) == err.(101, {0, 100})
      assert handle.(101, 0..100) == err.(101, {0, 100})
      assert handle.(101, 100..0) == err.(101, {0, 100})
      assert handle.(0, {:gt, 100}) == err.(0, {:gt, 100})
      assert handle.(0, {:ge, 100}) == err.(0, {:ge, 100})
      assert handle.(101, {:lt, 100}) == err.(101, {:lt, 100})
      assert handle.(101, {:le, 100}) == err.(101, {:le, 100})
    end
  end

  describe "with base" do
    test "and no prefix" do
      handle = &Integer.handle(&1, instance(base: &2))

      assert handle.("10101010", 2) == {:ok, 170}
      assert handle.("12345670", 8) == {:ok, 2739128}
      assert handle.("abcdef09", 16) == {:ok, 2882400009}
      assert handle.("abcdxyz05", 36) == {:ok, 29100069386933}
    end

    test "and prefix" do
      handle = &Integer.handle(&1, instance(base: &2))

      assert handle.("0b10101010", 2) == {:ok, 170}
      assert handle.("0o12345670", 8) == {:ok, 2739128}
      assert handle.("0xabcdef09", 16) == {:ok, 2882400009}
    end
  end

end
