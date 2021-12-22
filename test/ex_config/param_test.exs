defmodule ExConfig.ParamTest do
  use ExUnit.Case, async: true
  alias ExConfig.{Param, Type}

  @otp_app ExConfigTestApp
  @mod1 %ExConfig.Mod{otp_app: @otp_app}
  @p1name :param1
  @t1 Type.Raw
  @p1 %Param{mod: @mod1, name: @p1name, type: %Type.Raw{}, default: &ExConfig.Type.Raw.default/0}

  test "init" do
    init = &Param.init(@mod1, @p1name, @t1, &1)

    assert init.([]) == %Param{@p1 | required?: false, default: &ExConfig.Type.Raw.default/0}
    assert init.(required: true) == %Param{@p1 | required?: true}
    assert init.(default: :some) == %Param{@p1 | default: :some}
  end

  test "read_app_env" do
    init = &Param.init(&1, @p1name, @t1, [])
    read = &Param.read_app_env/1
    val1 = "value1"
    val2 = [{@p1name, val1}]
    mod1sub1 = %{@mod1 | path: [:sub]}

    # Exists, is not null
    Application.put_env(@otp_app, @p1name, val1)
    Application.put_env(@otp_app, :sub, val2)
    assert read.(init.(@mod1)) == %Param{@p1 | data: val1, exist?: true}
    assert read.(init.(mod1sub1)) == %Param{@p1 | mod: mod1sub1, data: val2, exist?: true}
    # Exists, is null
    Application.put_env(@otp_app, @p1name, nil)
    Application.put_env(@otp_app, :sub, nil)
    assert read.(init.(@mod1)) == %Param{@p1 | data: nil, exist?: true}
    assert read.(init.(mod1sub1)) == %Param{@p1 | mod: mod1sub1, data: nil, exist?: true}
    # Does not exist
    Application.delete_env(@otp_app, @p1name)
    Application.delete_env(@otp_app, :sub)
    assert read.(init.(@mod1)) == %Param{@p1 | data: nil, exist?: false}
    assert read.(init.(mod1sub1)) == %Param{@p1 | mod: mod1sub1, data: nil, exist?: false}
  end

  test "get_nested" do
    get = &Param.get_nested/1
    param = &(%Param{@p1 | mod: %{@mod1 | path: &1},
                           exist?: true, data: &2})
    err_text = "Unsupported enumerable"

    # edge cases
    assert get.(%{@p1 | exist?: false}) == %{@p1 | exist?: false}
    assert get.(param.([], :data)) == %Param{@p1 | exist?: true, data: :data}
    # enumerables
    assert get.(param.(["w/e"], %{@p1name => :data})) == param.(["w/e"], :data)
    assert get.(param.(["w/e"], [{@p1name, :data}])) == param.(["w/e"], :data)
    assert get.(param.(["w/e"], %{})) == %{param.(["w/e"], nil) | exist?: false, data: nil}
    assert get.(param.(["w/e"], [])) == %{param.(["w/e"], nil) | exist?: false, data: nil}
    assert get.(param.(["w/e"], :data)) == %{param.(["w/e"], :data) | error: err_text}
    # nested
    assert get.(param.(["w/e", :key1, :key2], %{key1: [{:key2, %{@p1name => :data}}]})) ==
                param.(["w/e", :key1, :key2], :data)

    assert get.(param.(["w/e", :key1, :key2], %{key1: [{:key2, %{}}]})) ==
              %{param.(["w/e", :key1, :key2], nil) | exist?: false, data: nil}

    assert get.(param.(["w/e", :key1, :key2], %{key1: [{:key2, :data}]})) ==
              %{param.(["w/e", :key1, :key2], %{key1: [{:key2, :data}]}) | error: err_text}
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
    def handle(data, _), do: data
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

    assert convert.(param.({:ok, :data})) == param.(:data)
    assert convert.(param.({:error, :reason})) ==
      %Param{param.({:error, :reason}) | error: :reason}

    assert convert.(@p1) == @p1
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

    assert error.(param.(:tuple, :reason, :data)) == param.(:tuple, :reason, :data)
    assert error.(param.(:default, :reason, :data)) == param.(:default, nil, nil)
    assert catch_throw(error.(param.(:throw, :reason, :data))) == :reason
  end

  def transform_test(%{data: data} = param), do: %{param | data: data - 13}

  test "maybe_transform" do
    transform = &Param.maybe_transform/1
    fn1 = &(%{&1 | data: &1.data + 1})
    fn2 = &(%{&1 | data: &1.data * 10})

    assert transform.(%Param{@p1 | data: 7, transform: fn1}).data == 8
    assert transform.(%Param{@p1 | data: 7, transform: [fn1]}).data == 8
    assert transform.(%Param{@p1 | data: 7, transform: [fn1, fn2]}).data == 80
    assert transform.(%Param{@p1 | data: 7, transform: {__MODULE__, :transform_test}}).data == -6

    assert transform.(@p1) == @p1
  end

  test "get_result" do
    get = &Param.get_result/1

    assert get.(%Param{@p1 | error: :reason}) == {:error, :reason}
    assert get.(%Param{@p1 | data: :data}) == :data
    assert get.(%Param{@p1 | data: :data, mod: %{@mod1 | on_error: :tuple}}) == {:ok, :data}
    assert get.(%Param{@p1 | data: nil, default: :default}) == :default
    assert get.(%Param{@p1 | data: nil, default: fn -> :default_fn end}) == :default_fn
    assert get.(%Param{@p1 | data: nil, default: nil}) == nil
  end

  test "until_error" do
    until = &Param.until_error/2

    fn1 = &(%{&1 | data: &1.data + 1})
    fn2 = &(%{&1 | data: &1.data * 10})
    fn3 = &(%{&1 | data: &1.data - 13, error: :reason})
    assert until.(%Param{@p1 | data: 7}, []) == %Param{@p1 | data: 7}
    assert until.(%Param{@p1 | data: 7}, [fn1]) == %Param{@p1 | data: 8}
    assert until.(%Param{@p1 | data: 7}, [fn1, fn2]) == %Param{@p1 | data: 80}
    assert until.(%Param{@p1 | data: 7}, [fn3, fn2]) == %Param{@p1 | data: -6, error: :reason}

    fn1 = &({:ok, &1 + 1})
    fn2 = &({:ok, &1 * 10})
    fn3 = &({:error, &1})
    fn4 = &(&1 + 4)
    assert until.(7, []) == {:ok, 7}
    assert until.(7, [fn1]) == {:ok, 8}
    assert until.(7, [fn1, fn2]) == {:ok, 80}
    assert until.(7, [fn3, fn2]) == {:error, 7}
    assert until.(7, [fn4, fn2]) == {:ok, 110}
  end
end
