defmodule ExConfig.ParamTest do
  use ExUnit.Case, async: true
  alias ExConfig.{Param, Type}

  @otp_app ExConfigTestApp
  @mod1 %ExConfig.Mod{otp_app: @otp_app}
  @p1name __MODULE__
  @t1 Type.Raw
  @p1 %Param{mod: @mod1, name: @p1name, type: %Type.Raw{}, default: &ExConfig.Type.Raw.default/0}

  test "init" do
    init = &Param.init(@mod1, @p1name, @t1, &1)

    assert init.([]) == %Param{@p1 | required?: false, default: &ExConfig.Type.Raw.default/0}
    assert init.(required: true) == %Param{@p1 | required?: true}
    assert init.(default: :some) == %Param{@p1 | default: :some}
  end

  describe "read_app_env" do
    test "properly handles empty values" do
      read = &Param.read_app_env/1

      # Exists, is not null
      Application.put_env(@otp_app, @p1name, "value1")
      assert %Param{data: "value1", exist?: true} = read.(@p1)
      # Exists, is null
      Application.put_env(@otp_app, @p1name, nil)
      assert %Param{data: nil, exist?: true} = read.(@p1)
      # Does not exist
      Application.delete_env(@otp_app, @p1name)
      assert %Param{data: nil, exist?: false} = read.(@p1)
    end

    test "reads nested value" do
      read = &Param.read_app_env/1
      param = &(%Param{@p1 | mod: %{@mod1 | path: &1}})

      # Depth: 1
      :ok = Application.delete_env(@otp_app, @p1name)
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name]))

      :ok = Application.put_env(@otp_app, @p1name, nil)
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name]))

      :ok = Application.put_env(@otp_app, @p1name, [])
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name]))
      :ok = Application.put_env(@otp_app, @p1name, %{})
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name]))

      :ok = Application.put_env(@otp_app, @p1name, [{@p1name, nil}])
      assert %Param{exist?: true, data: nil, error: nil} = read.(param.([@p1name]))
      :ok = Application.put_env(@otp_app, @p1name, %{@p1name => nil})
      assert %Param{exist?: true, data: nil, error: nil} = read.(param.([@p1name]))

      :ok = Application.put_env(@otp_app, @p1name, [{@p1name, :data}])
      assert %Param{exist?: true, data: :data, error: nil} = read.(param.([@p1name]))
      :ok = Application.put_env(@otp_app, @p1name, %{@p1name => :data})
      assert %Param{exist?: true, data: :data, error: nil} = read.(param.([@p1name]))

      # Depth: 2
      :ok = Application.delete_env(@otp_app, @p1name)
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))

      :ok = Application.put_env(@otp_app, @p1name, nil)
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))

      :ok = Application.put_env(@otp_app, @p1name, [])
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))
      :ok = Application.put_env(@otp_app, @p1name, %{})
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))

      :ok = Application.put_env(@otp_app, @p1name, [nested: nil])
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))
      :ok = Application.put_env(@otp_app, @p1name, %{nested: nil})
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))

      :ok = Application.put_env(@otp_app, @p1name, [nested: []])
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))
      :ok = Application.put_env(@otp_app, @p1name, %{nested: %{}})
      assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))

      :ok = Application.put_env(@otp_app, @p1name, [nested: [{@p1name, nil}]])
      assert %Param{exist?: true, data: nil, error: nil} = read.(param.([@p1name, :nested]))
      :ok = Application.put_env(@otp_app, @p1name, %{nested: %{@p1name => nil}})
      assert %Param{exist?: true, data: nil, error: nil} = read.(param.([@p1name, :nested]))

      :ok = Application.put_env(@otp_app, @p1name, [nested: [{@p1name, :data}]])
      assert %Param{exist?: true, data: :data, error: nil} = read.(param.([@p1name, :nested]))
      :ok = Application.put_env(@otp_app, @p1name, %{nested: %{@p1name => :data}})
      assert %Param{exist?: true, data: :data, error: nil} = read.(param.([@p1name, :nested]))


      assert_raise FunctionClauseError, fn ->
        :ok = Application.put_env(@otp_app, @p1name, :data)
        assert %Param{exist?: false, data: nil, error: nil} = read.(param.([@p1name, :nested]))
      end

      Application.delete_env(@otp_app, @p1name)
    end
  end

  defmodule TestSource do
    defstruct [:return]
    def handle(%{return: data}, _), do: data
  end

  test "maybe_invoke_source" do
    invoke = &Param.maybe_invoke_source/1
    param = &(%Param{@p1 | data: {TestSource, [{:return, &1}]}})

    assert invoke.(param.({:ok, nil})) == %Param{@p1 | data: nil, exist?: false}
    assert invoke.(param.({:ok, :data})) == %Param{@p1 | data: :data, exist?: true}
    assert invoke.(param.(%Param{@p1 | data: :something, exist?: true})) ==
                          %Param{@p1 | data: :something, exist?: true}
    assert invoke.(param.({:error, :reason})) ==
            %Param{param.({:error, :reason}) | error: :reason}

    # no module exists
    assert invoke.(%Param{@p1 | data: {TestSource2, []}}) ==
                   %Param{@p1 | data: {TestSource2, []}}

    # is not keyword
    assert invoke.(%Param{@p1 | data: {TestSource, [:opts]}}) ==
                   %Param{@p1 | data: {TestSource, [:opts]}}

    # no source module
    assert invoke.(@p1) == @p1
  end


  defmodule TestType do
    use ExConfig.Type
    defstruct []

    def handle({:error, reason}, _), do: {:error, reason}
    def handle(data, _), do: {:ok, data}

    def default, do: :other_default
  end

  test "default_in_type" do
    assert Param.init(@mod1, @p1name, TestType, [])
        == %Param{@p1 | type: %TestType{}, default: &TestType.default/0}
    assert TestType.default() == :other_default
  end

  test "convert_data" do
    convert = &Param.convert_data/1
    param = &(%Param{@p1 | exist?: true, error: nil, data: &1, type: %TestType{}})

    assert convert.(param.(:data)) == param.(:data)
    assert convert.(param.({:error, :reason})) ==
      %Param{param.({:error, :reason}) | error: :reason}

    assert convert.(@p1) == @p1

    assert convert.(param.('data')) == param.("data")
  end

  test "check_requirement" do
    check = &Param.check_requirement/1

    invalid = %Param{@p1 | error: nil, required?: true, data: nil, default: nil}
    assert check.(invalid) ==
      %Param{invalid | error: "Parameter '#{@p1name}' must be set"}

    assert check.(@p1) == @p1
  end

  test "maybe_handle_error" do
    error = &Param.maybe_handle_error/1
    param = &(%Param{@p1 | mod: %{@mod1 | on_error: &1},
                           error: &2, data: &3})

    assert error.(param.(:throw, nil, :data)) == param.(:throw, nil, :data)
    assert error.(param.(:default, :reason, :data)) == param.(:default, nil, nil)
    assert catch_throw(error.(param.(:throw, :reason, :data))) == :reason
  end

  def transform_test(%{data: data} = param), do: %{param | data: data - 13}

  test "maybe_transform" do
    transform = &Param.maybe_transform/1
    fn1 = &(%{&1 | data: &1.data + 1})
    fn2 = &(%{&1 | data: &1.data * 10})

    assert transform.(%Param{@p1 | data: 7, transform: [fn1]}).data == 8
    assert transform.(%Param{@p1 | data: 7, transform: [fn1, fn2]}).data == 80
    assert transform.(%Param{@p1 | data: 7, transform: [{__MODULE__, :transform_test}]}).data == -6

    assert transform.(@p1) == @p1
  end

  test "get_result" do
    get = &Param.get_result/1

    assert get.(%Param{@p1 | error: :reason}) == {:error, :reason}
    assert get.(%Param{@p1 | data: :data}) == :data
    assert get.(%Param{@p1 | data: nil, default: :default}) == :default
    assert get.(%Param{@p1 | data: nil, default: fn -> :default_fn end}) == :default_fn
    assert get.(%Param{@p1 | data: nil, default: nil}) == nil
  end
end
