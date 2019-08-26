defmodule ExConfig.Type.StringTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.String

  defp instance(opts \\ []),
    do: ExConfig.Param.create_type_instance(String, opts)

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
end
