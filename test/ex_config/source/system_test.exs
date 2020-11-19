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

    test "with pattern" do
      handle = &ESS.handle(%ESS{name: &1, expand: true}, %Param{name: &2})
      assert handle.("ENV_EX_ONE", :not_used) == {:ok, @env_ex1_val}
      assert handle.("ENV_EX_${name}", :one) == {:ok, @env_ex1_val}
      assert handle.("ENV_${name}_ONE", :ex) == {:ok, @env_ex1_val}
      assert handle.("ENV_EX_${name}", :some) == {:ok, nil}
      assert handle.("${name}NV_${name}X_ON${name}", :e) == {:ok, @env_ex1_val}
      assert handle.([@env_nx1, "${name}NV_${name}X_ON${name}"], :e) == {:ok, @env_ex1_val}
      assert handle.([@env_nx1, @env_ex2, "${name}NV_${name}X_ON${name}"], :e) == {:ok, @env_ex2_val}
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

  describe "get_all_sensitive_envs" do
    test "when empty" do
      assert ESS.get_all_sensitive_envs() == []
    end

    test "when exists" do
      filter = &Keyword.get(&1, :sensitive)
      gto = &ExConfig.Source.get_source_occurrences(ESS, filter, &1)

      assert ESS.get_all_sensitive_envs(gto.([app: [
        env1: {ESS, name: "ENV1", sensitive: true},
        env2: {ESS, name: "ENV2", sensitive: false},
        env3: {ESS, name: ["ENV31", "ENV32"], sensitive: true},
        env4: {ESS, name: ["ENV41", "ENV42"], sensitive: false},
        env5: {Keyword, name: "ENV5", sensitive: true},
        env6: [
          env61: [
            env611: {ESS, name: "ENV611", sensitive: true},
            env612: {Keyword, name: "ENV612"},
          ],
          env62: %{
            env621: {ESS, name: "ENV621", sensitive: true},
            env622: {ESS, name: "ENV622", sensitive: false},
          },
        ],
        env7: {ESS, name: "ENV7"},
        env8: {ESS, sensitive: true},
        env9: {ESS, name: "ENV1", sensitive: true},
      ]])) == ["ENV1", "ENV31", "ENV32", "ENV611", "ENV621"]
    end

    test "with patterns" do
      filter = &Keyword.get(&1, :sensitive)
      gto = &ExConfig.Source.get_source_occurrences(ESS, filter, &1)

      assert ESS.get_all_sensitive_envs(gto.([app: [
        env1: {ESS, name: "ENV_EX_${name}", sensitive: true, expand: true},
      ]])) == ["ENV_EX_ONE", "ENV_EX_TWO"]

      assert ESS.get_all_sensitive_envs(gto.([app: [
        env1: {ESS, name: "${name}NV_${name}X_ON${name}", sensitive: true, expand: true},
      ]])) == ["ENV_EX_ONE"]

      assert ESS.get_all_sensitive_envs(gto.([app: [
        env1: {ESS, name: "${name}NV_${name}X_ON${name}", sensitive: true, expand: true},
        env2: {ESS, name: "ENV_EX_TWO", sensitive: true, expand: true},
      ]])) == ["ENV_EX_ONE", "ENV_EX_TWO"]
    end
  end
end
