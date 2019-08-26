defmodule ExConfig.Source.SystemTest do
  use ExUnit.Case, async: false
  alias ExConfig.Param
  alias ExConfig.Source.System, as: ESS

  @env_ex1 "ENV_EX_ONE"
  @env_ex1_val "ENV_EX_ONE_VALUE"
  @env_ex2 "ENV_EX_TWO"
  @env_ex2_val "ENV_EX_TWO_VALUE"
  @env_nx1 "ENV_NX_ONE"
  @env_nx2 "ENV_NX_TWO"
  @p %Param{}

  setup do
    System.put_env(@env_ex1, @env_ex1_val)
    System.put_env(@env_ex2, @env_ex2_val)
    System.delete_env(@env_nx1)
    System.delete_env(@env_nx2)
  end

  setup_all do
    on_exit(fn ->
      System.delete_env(@env_ex1)
      System.delete_env(@env_ex2)
    end)
  end

  describe "handle" do
    test "without default" do
      assert ESS.handle(%ESS{name: @env_ex1}, @p) == {:ok, @env_ex1_val}
      assert ESS.handle(%ESS{name: [@env_ex1, @env_ex2]}, @p) == {:ok, @env_ex1_val}
      assert ESS.handle(%ESS{name: [@env_nx1, @env_nx2, @env_ex1]}, @p) == {:ok, @env_ex1_val}
      assert ESS.handle(%ESS{name: @env_nx1}, @p) == {:ok, nil}
      assert ESS.handle(%ESS{name: [@env_nx1, @env_nx2]}, @p) == {:ok, nil}
    end

    test "with default" do
      assert ESS.handle(%ESS{name: @env_ex1, default: :some}, @p) == {:ok, @env_ex1_val}
      assert ESS.handle(%ESS{name: [@env_nx1, @env_nx2], default: :some}, @p) == {:ok, :some}
    end

    test "missing or wrong name option" do
      assert_raise ArgumentError, ~r/the following keys must also be given/, fn -> struct!(ESS, default: :some) end
      assert_raise FunctionClauseError, fn -> ESS.handle(%ESS{name: :test}, @p) end
    end
  end

  test "invoke_source" do
    invoke = &Param.maybe_invoke_source(%Param{data: {ESS, &1}})

    assert invoke.(name: @env_ex1) == %Param{data: @env_ex1_val, exist?: true}
    assert invoke.(name: [@env_ex1, @env_ex2]) == %Param{data: @env_ex1_val, exist?: true}
    assert invoke.(name: [@env_nx1, @env_nx2]) == %Param{data: nil, exist?: false}

    assert invoke.(name: @env_ex1, default: :some) == %Param{data: @env_ex1_val, exist?: true}
    assert invoke.(name: @env_nx1, default: :some) == %Param{data: :some, exist?: true}

    assert_raise ArgumentError, ~r/the following keys must also be given/, fn -> invoke.([]) end
  end

end
