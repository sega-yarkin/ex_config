defmodule Type.NumberTest do
  use ExUnit.Case
  alias ExConfig.Type.Number

  test "init/1" do
    assert Number.init([]) == %Number{}
  end

  describe "parsing" do
    defp handle(data), do: Number.handle(data, %Number{})

    test "when valid number" do
      assert handle(42) == {:ok, 42.0}
      assert handle(-42) == {:ok, -42.0}
      assert handle(0) == {:ok, 0.0}
      assert handle(12345678901234567890) == {:ok, 1.2345678901234567e19}
      assert handle(0.0001) == {:ok, 0.0001}
    end

    test "when valid string" do
      assert handle("42") == {:ok, 42.0}
      assert handle("-42") == {:ok, -42.0}
      assert handle("0") == {:ok, 0.0}
      assert handle("12345678901234567890") == {:ok, 1.2345678901234567e19}
      assert handle("0.0001") == {:ok, 0.0001}
      assert handle("12345.67890") == {:ok, 12345.6789}
      assert handle("-0.000004") == {:ok, -0.000004}
      assert handle("  -0.04  ") == {:ok, -0.04}
    end

    test "when valid charlist" do
      assert handle('42') == {:ok, 42.0}
      assert handle('-42') == {:ok, -42.0}
      assert handle('0') == {:ok, 0.0}
      assert handle('12345678901234567890') == {:ok, 1.2345678901234567e19}
      assert handle('0.0001') == {:ok, 0.0001}
      assert handle('12345.67890') == {:ok, 12345.6789}
      assert handle('-0.000004') == {:ok, -0.000004}
    end

    defp parse_err(data),
      do: {:error, "Cannot parse '#{inspect(data)}' as a number"}

    test "when no valid data" do
      assert handle("0.01.01") == parse_err("0.01.01")
      assert handle('0.01.01') == parse_err("0.01.01")
      assert handle("") == parse_err("")
      assert handle("abc") == parse_err("abc")
      assert handle(nil) == parse_err(nil)
      assert handle(:ok) == parse_err(:ok)
    end
  end

  describe "with range" do
    defp handle(data, range), do: Number.handle(data, %Number{range: range})

    test "when number is in" do
      assert handle(100, {0, 100}) == {:ok, 100}
      assert handle(100, 0..100) == {:ok, 100}
      assert handle(100, 100..0) == {:ok, 100}
      assert handle(100, {:gt, 99}) == {:ok, 100}
      assert handle(100, {:ge, 100}) == {:ok, 100}
      assert handle(100, {:lt, 101}) == {:ok, 100}
      assert handle(100, {:le, 100}) == {:ok, 100}
    end

    defp handle_err(data, range),
      do: {:error, "#{data/1} is out of range #{range}"}

    test "when number is out" do
      assert handle(101, {0, 100}) == handle_err(101, "[0, 100]")
      assert handle(101, 0..100) == handle_err(101, "[0, 100]")
      assert handle(101, 100..0) == handle_err(101, "[0, 100]")
      assert handle(0, {:gt, 100}) == handle_err(0, "(100, inf)")
      assert handle(0, {:ge, 100}) == handle_err(0, "[100, inf)")
      assert handle(101, {:lt, 100}) == handle_err(101, "(-inf, 100)")
      assert handle(101, {:le, 100}) == handle_err(101, "(-inf, 100]")
    end
  end

end
