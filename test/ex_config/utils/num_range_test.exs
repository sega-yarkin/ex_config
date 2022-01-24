defmodule ExConfig.Utils.NumRangeTest do
  use ExUnit.Case, async: true

  alias ExConfig.Utils.NumRange


  describe "validate/1" do
    test "skip" do
      assert NumRange.validate(nil) == :skip
    end

    test "min and max" do
      import NumRange, only: [validate: 1]

      assert validate({10, 20}) == {:ok, {10, 20}}
      assert validate({20, 10}) == {:ok, {10, 20}}
      assert validate({-10.0, 20.0}) == {:ok, {-10.0, 20.0}}
      assert validate({"10", "20"}) == :error
    end

    test "op and number" do
      import NumRange, only: [validate: 1]

      assert validate({:gt, 10}) == {:ok, {:gt, 10}}
      assert validate({:ge, 10}) == {:ok, {:ge, 10}}
      assert validate({:lt, 10}) == {:ok, {:lt, 10}}
      assert validate({:le, 10}) == {:ok, {:le, 10}}

      assert validate({:gt, "10"}) == :error
      assert validate({:atom, "10"}) == :error
    end

    test "from Range" do
      import NumRange, only: [validate: 1]
      assert validate(10..20) == {:ok, {10, 20}}
      assert validate(20..10) == {:ok, {10, 20}}
    end
  end

  if Version.match?(System.version(), ">= 1.12.0") do
    test "validate/1 from Range/3" do
      import NumRange, only: [validate: 1]
      assert validate(10..20//1) == {:ok, {10, 20}}
      assert validate(20..10//-1) == {:ok, {10, 20}}
      assert validate(10..20//2) == :error
    end
  end

  test "in_range?/2" do
    import NumRange, only: [in_range?: 2]

    assert in_range?(100, {:gt, 90})
    refute in_range?(100, {:gt, 100})
    assert in_range?(100, {:ge, 100})
    refute in_range?(100, {:ge, 101})
    assert in_range?(100, {:lt, 101})
    refute in_range?(100, {:lt, 90})
    assert in_range?(100, {:le, 100})
    refute in_range?(100, {:le, 90})

    assert in_range?(100, {90, 110})
    assert in_range?(100, {100, 100})
    refute in_range?(100, {90, 99})
  end

  test "to_string/1" do
    to_string = &NumRange.to_string/1

    assert to_string.({:gt, 100.5}) == "(100.5, inf)"
    assert to_string.({:ge, 100.5}) == "[100.5, inf)"
    assert to_string.({:lt, 100.5}) == "(-inf, 100.5)"
    assert to_string.({:le, 100.5}) == "(-inf, 100.5]"
    assert to_string.({50, 100.5}) == "[50, 100.5]"
  end
end
