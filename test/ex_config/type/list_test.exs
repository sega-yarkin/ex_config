defmodule ExConfig.Type.ListTest do
  use ExUnit.Case, async: true
  alias ExConfig.Type
  alias ExConfig.Param.TypeOptionError

  defp instance(opts),
    do: ExConfig.Param.create_type_instance(Type.List, opts)

  test "init/1" do
    assert %Type.List{item: %Type.String{}, delim: ",", keep_empty?: false} == instance([])
    # item
    assert %Type.Integer{} == instance(item: Type.Integer).item
    assert %Type.Integer{base: 8} == instance(item: {Type.Integer, base: 8}).item
    assert_raise TypeOptionError, fn -> instance(item: Integer) end
    assert_raise TypeOptionError, fn -> instance(item: SomeRandomModuleName) end
    assert %Type.List{} == instance(item: {Type.List, []}).item
    assert %Type.String{} == instance(item: {Type.List, [item: {Type.List, []}]}).item.item.item
    # delim
    assert ";" == instance(delim: ";").delim
    assert ~r/(,|;)/ == instance(delim: ~r/(,|;)/).delim
    assert_raise TypeOptionError, fn -> instance(delim: :atom) end
    # trim?
    assert false == instance(keep_empty?: false).keep_empty?
    assert true == instance(keep_empty?: true).keep_empty?
    # invalid item
    assert_raise ExConfig.Param.TypeOptionError, fn ->
      assert :ok = instance(item: __MODULE__.InitError)
    end
  end

  test "default/0" do
    assert Type.List.default() == []
  end

  test "handle (splitting)" do
    handle = &Type.List.handle(&1, instance(delim: &2))
    handle2 = &Type.List.handle(&1, instance(delim: &2, keep_empty?: true))
    # simple cases
    assert handle.("", ",") == {:ok, []}
    assert handle.(",", ",") == {:ok, []}
    assert handle.(",", ~r/,/) == {:ok, []}
    assert handle.("a,b,c,", ",") == {:ok, ["a", "b", "c"]}
    assert handle.("a,b,c,", ~r/,/) == {:ok, ["a", "b", "c"]}
    assert handle2.("a,b,c,", ",") == {:ok, ["a", "b", "c", ""]}
    assert handle2.("a,b,c,", ~r/,/) == {:ok, ["a", "b", "c", ""]}
    assert handle.("a,b;c,d;", [",", ";"]) == {:ok, ["a", "b", "c", "d"]}
    # with spaces
    assert handle.("a, b, c, ", ",") == {:ok, ["a", " b", " c", " "]}
    assert handle.("a, b, c, ", ", ") == {:ok, ["a", "b", "c"]}
    assert handle.("a, b,c, ", ~r/,\s*/) == {:ok, ["a", "b", "c"]}
    # longer words
    assert handle.("one;two;three", ";") == {:ok, ["one", "two", "three"]}
    assert handle.("one;two;three", ~r/;\s*/) == {:ok, ["one", "two", "three"]}
    # other types of input data
    assert handle.('a,b,c,', ",") == {:ok, ["a", "b", "c"]}
    assert handle.(:'a,b,c,', ",") == Type.List.error(:bad_data, :'a,b,c,')

    # nested lists
    nested = &{Type.List, &1}
    handle = &Type.List.handle(&1, instance(item: &2, delim: ";"))
    assert handle.("a,b,c;d,e,f;g,h,", nested.(item: Type.String, delim: ",")) ==
            {:ok, [["a", "b", "c"], ["d", "e", "f"], ["g", "h"]]}

  end

  test "handle (item type)" do
    handle = &Type.List.handle(&1, instance(&2))

    assert handle.("1,2,3,4", item: {Type.Integer, []}) == {:ok, [1, 2, 3, 4]}
    assert handle.("0x1,0x2,0x03,0x04", item: {Type.Integer, [base: 16]}) == {:ok, [1, 2, 3, 4]}
    assert handle.("1,2,b", item: Type.Integer) == Type.Integer.error(:bad_data, "b")

    # nested lists
    nested = &{Type.List, &1}
    handle = &Type.List.handle(&1, instance(item: &2, delim: ";"))
    assert handle.("1.2,3.4;55,66;78.1,971", nested.(item: Type.Number, delim: ",")) ==
            {:ok, [[1.2, 3.4], [55.0, 66.0], [78.1, 971.0]]}
  end

end
