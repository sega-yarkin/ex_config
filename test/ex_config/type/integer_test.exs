defmodule ExConfig.Type.IntegerTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.{Integer, Number}
  alias ExConfig.Param.TypeOptionError
  alias ExConfig.Utils.NumRange

  defp instance(opts \\ []) do
    ExConfig.Param.create_type_instance(Integer, opts)
  end

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

    test "when invalid data" do
      handle = &Integer.handle(&1, instance())
      should_error = fn value ->
        assert handle.(value) == Integer.error(:bad_data, value)
      end

      should_error.("0.01")
      should_error.("0.01.01")
      should_error.('0.01.01')
      should_error.("")
      should_error.("abc")
      should_error.(nil)
      should_error.(:ok)
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
      should_error = fn value, range ->
        {:ok, range2} = NumRange.validate(range)
        assert handle.(value, range) == Number.error(:out_of_range, {value, range2})
      end

      should_error.(101, {0, 100})
      should_error.(101, 0..100)
      should_error.(101, 100..0)
      should_error.(0, {:gt, 100})
      should_error.(0, {:ge, 100})
      should_error.(101, {:lt, 100})
      should_error.(101, {:le, 100})
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

    test "and invalid prefix" do
      handle = &Integer.handle(&1, instance(base: &2))
      should_error = fn value, base ->
        assert handle.(value, base) == Integer.error(:bad_data, value)
      end

      should_error.("0b10101010", 8)
      should_error.("0o12345670", 2)
      should_error.("0xabcdef09", 10)

      should_error.("0b0b10101010", 2)
      should_error.("0o0o12345670", 8)
      should_error.("0x0xabcdef09", 16)
    end
  end

end
