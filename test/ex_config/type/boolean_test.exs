defmodule ExConfig.Type.BooleanTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type.Boolean

  defp instance(opts \\ []),
    do: ExConfig.Param.create_type_instance(Boolean, opts)

  test "init/1" do
    assert %Boolean{} == instance([])
  end

  describe "parsing" do
    test "when valid string" do
      handle = &Boolean.handle(&1, instance())

      assert handle.("true") == {:ok, true}
      assert handle.("TRUE") == {:ok, true}
      assert handle.("True") == {:ok, true}
      assert handle.("yes") == {:ok, true}
      assert handle.("YES") == {:ok, true}
      assert handle.("Yes") == {:ok, true}
      assert handle.("false") == {:ok, false}
      assert handle.("FALSE") == {:ok, false}
      assert handle.("False") == {:ok, false}
      assert handle.("no") == {:ok, false}
      assert handle.("NO") == {:ok, false}
      assert handle.("No") == {:ok, false}
    end

    test "when valid charlist" do
      handle = &Boolean.handle(&1, instance())

      assert handle.('true') == {:ok, true}
      assert handle.('yes') == {:ok, true}
      assert handle.('false') == {:ok, false}
      assert handle.('no') == {:ok, false}
    end

    test "when valid boolean" do
      handle = &Boolean.handle(&1, instance())

      assert handle.(true) == {:ok, true}
      assert handle.(false) == {:ok, false}
    end

    test "when invalid data" do
      handle = &Boolean.handle(&1, instance())
      err = &Boolean.error(:bad_data, &1)

      assert handle.("tru") == err.("tru")
      assert handle.('tru') == err.("tru")
      assert handle.("") == err.("")
      assert handle.(nil) == err.(nil)
      assert handle.(:ok) == err.(:ok)
    end
  end
end
