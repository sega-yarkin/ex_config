defmodule ExConfig.Type.StringTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.String
  alias ExConfig.Param

  defp instance(opts \\ []),
    do: Param.create_type_instance(String, opts)

  test "init/1" do
    assert %String{} == instance()
  end

  describe "parsing" do
    test "when valid string" do
      handle = &String.handle(&1, instance())

      assert handle.("text") == {:ok, "text"}
      assert handle.('text') == {:ok, "text"}
      assert handle.("") == {:ok, ""}
      assert handle.('') == {:ok, ""}
    end

    test "when invalid data" do
      handle = &String.handle(&1, instance())
      err = &String.error(:bad_data, &1)

      assert handle.(:atom) == err.(:atom)
      assert handle.(1) == err.(1)
      assert handle.({1,2,3}) == err.({1,2,3})
    end
  end

  describe "helpers" do
    test "to_charlist" do
      to_chl = &(String.to_charlist(%Param{data: &1}).data)
      assert to_chl.("test string") == 'test string'
      assert to_chl.(nil) == nil
      assert to_chl.(123) == 123
    end

    test "transform_downcase" do
      transform = &(String.transform_downcase(%Param{data: &1}).data)
      assert transform.("TEST String") == "test string"
      assert transform.(nil) == nil
      assert transform.(123) == 123
    end

    test "transform_upcase" do
      transform = &(String.transform_upcase(%Param{data: &1}).data)
      assert transform.("TeST String") == "TEST STRING"
      assert transform.(nil) == nil
      assert transform.(123) == 123
    end
  end
end
