defmodule ExConfig.Type.NumberTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.Number
  alias ExConfig.Param.TypeOptionError
  alias ExConfig.Utils.NumRange

  defp instance(opts \\ []) do
    ExConfig.Param.create_type_instance(Number, opts)
  end

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

    test "when invalid data" do
      handle = &Number.handle(&1, instance())
      should_error = fn value ->
        assert handle.(value) == Number.error(:bad_data, value)
      end

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
      handle = &Number.handle(&1, instance(range: &2))

      assert handle.(100.0, {0, 100}) == {:ok, 100.0}
      assert handle.(100.0, 0..100) == {:ok, 100.0}
      assert handle.(100.0, 100..0) == {:ok, 100.0}
      assert handle.(100.0, {:gt, 99}) == {:ok, 100.0}
      assert handle.(100.0, {:ge, 100}) == {:ok, 100.0}
      assert handle.(100.0, {:lt, 101}) == {:ok, 100.0}
      assert handle.(100.0, {:le, 100}) == {:ok, 100.0}
    end

    test "when number is out" do
      handle = &Number.handle(&1, instance(range: &2))
      should_error = fn value, range ->
        {:ok, range2} = NumRange.validate(range)
        assert handle.(value, range) == Number.error(:out_of_range, {value/1, range2})
      end

      should_error.(101.0, {0, 100})
      should_error.(101.0, 0..100)
      should_error.(101.0, 100..0)
      should_error.(0.0, {:gt, 100})
      should_error.(0.0, {:ge, 100})
      should_error.(101.0, {:lt, 100})
      should_error.(101.0, {:le, 100})
    end
  end

end
