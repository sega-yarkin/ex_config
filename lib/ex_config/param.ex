defmodule ExConfig.Param do
  alias __MODULE__
  alias ExConfig.Mod

  defstruct mod: nil,
            name: nil,
            type: nil,
            default: nil,
            required?: false,
            transform: nil,
            data: nil,
            exist?: false,
            error: nil

  @type t() :: %__MODULE__{
    mod:        Mod.t(),
    name:       atom(),
    type:       struct(),
    default:    any(),
    required?:  boolean(),
    transform:  transform_fun() | [transform_fun()] | nil,
    #
    data:       any(),
    exist?:     boolean(),
    error:      any(),
  }

  @type transform_fun() :: (Param.t() -> Param.t())
  @type transform_fun_any() :: (any() -> {:ok | :error, any()})

  @spec init(Mod.t | nil, atom, module, Keyword.t) :: Param.t
  def init(mod, name, type, opts) do
    {default  , opts} = Keyword.pop(opts, :default, &type.default/0)
    {required?, opts} = Keyword.pop(opts, :required, false)
    {transform, opts} = Keyword.pop(opts, :transform, nil)

    %Param{
      mod:  mod,
      name: name,
      type: create_type_instance(type, opts),
      default:   default,
      required?: required?,
      transform: transform,
    }
  end

  @spec create_type_instance(module, Keyword.t) :: struct
  def create_type_instance(type, opts) do
    apply(type, :validators, [])
    |> ExConfig.Type.validate_options!(opts, type)
    |> type.init()
  end

  @spec read(Param.t) :: any | {:error, String.t} | {:ok, any} | no_return
  def read(%Param{} = param) do
    param
    |> read_app_env()
    |> get_nested()
    |> maybe_invoke_source()
    |> convert_data()
    |> check_requirement()
    |> maybe_handle_error()
    |> maybe_transform()
    |> get_result()
  end

  @spec read_app_env(Param.t) :: Param.t
  def read_app_env(%Param{name: name,
                          mod: %Mod{path: []}} = param) do
    read_app_env0(param, name)
  end
  def read_app_env(%Param{mod: %Mod{path: [key | _]}} = param) do
    read_app_env0(param, key)
  end

  @spec read_app_env0(Param.t, atom) :: Param.t
  defp read_app_env0(%Param{mod: %Mod{otp_app: otp_app}} = param, key) do
    case :application_controller.get_env(otp_app, key) do
      {:ok, data} -> %{param | data: data, exist?: true}
      :undefined  -> %{param | data: nil, exist?: false}
    end
  end

  @spec get_nested(Param.t) :: Param.t
  def get_nested(%Param{exist?: false} = param), do: param
  def get_nested(%Param{mod: %Mod{path: []}} = param), do: param
  def get_nested(%Param{mod: %Mod{path: [_ | path]},
                        name: name,
                        data: data} = param) do
    case get_nested(data, path ++ [name]) do
      {:ok, data}     -> %{param | data: data}
      {:error, error} -> %{param | error: error}
      nil             -> %{param | data: nil, exist?: false}
    end
  end

  @spec get_nested(any, [any]) :: {:ok, any} | nil | {:error, String.t}
  defp get_nested(nil, _), do: nil
  defp get_nested(data, []), do: {:ok, data}
  defp get_nested(data, [key | rest]) when is_list(data) and is_atom(key),
    do: Keyword.get(data, key) |> get_nested(rest)
  defp get_nested(data, [key | rest]) when is_map(data),
    do: Map.get(data, key) |> get_nested(rest)
  defp get_nested(_, _),
    do: {:error, "Unsupported enumerable"}


  @spec maybe_invoke_source(Param.t) :: Param.t
  def maybe_invoke_source(%Param{data: {module, options}} = param)
                          when is_atom(module) and is_list(options) do
    if Keyword.keyword?(options) do
      source = struct!(module, options)
      case module.handle(source, param) do
        {:ok, nil}       -> %{param | data: nil, exist?: false}
        {:ok, data}      -> %{param | data: data, exist?: true}
        data = %Param{}  -> data
        {:error, reason} -> %{param | error: reason}
      end
    else
      param
    end
  rescue
    UndefinedFunctionError -> param
  end
  def maybe_invoke_source(param), do: param

  @spec convert_data(Param.t) :: Param.t
  def convert_data(%Param{exist?: true, error: nil,
                          data: data, type: type} = param) do
    case apply(Map.fetch!(type, :__struct__), :handle, [data, type]) do
      {:ok, data}      -> %{param | data: data}
      {:error, reason} -> %{param | error: reason}
    end
  end
  def convert_data(param), do: param

  @spec check_requirement(Param.t) :: Param.t
  def check_requirement(%Param{error: nil, required?: true, data: nil,
                               name: name} = param) do
    %{param | error: "Parameter '#{name}' must be set"}
  end
  def check_requirement(param), do: param

  @spec maybe_handle_error(Param.t) :: Param.t
  def maybe_handle_error(%Param{error: nil} = param), do: param
  def maybe_handle_error(%Param{error: err} = param) do
    case on_error(param) do
      :tuple   -> param
      :default -> %{param | error: nil, data: nil}
      :throw   -> throw(err)
    end
  end

  @spec maybe_transform(Param.t) :: Param.t
  def maybe_transform(%Param{transform: funs} = param) when funs != nil do
    funs
    |> List.wrap()
    |> Enum.reduce(param, &transform/2)
  end
  def maybe_transform(param), do: param

  @spec transform(transform_fun | {module, atom}, Param.t) :: Param.t
  defp transform(fun, val) when is_function(fun),
    do: apply(fun, [val])
  defp transform({m, f}, val) when is_atom(m) and is_atom(f),
    do: apply(m, f, [val])


  @spec get_result(Param.t) :: any | {:ok, any} | {:error, String.t}
  def get_result(%Param{error: reason}) when reason != nil,
    do: {:error, reason}
  def get_result(%Param{data: data, default: default} = param) do
    data =
      case {data, default} do
        {nil, default} when is_function(default, 0) -> default.()
        {nil, default} -> default
        {data, _}      -> data
      end

    # If in case of error tuple is returned, then results
    # should be returned in the same format.
    if on_error(param) == :tuple, do: {:ok, data}, else: data
  end


  @spec until_error(Param.t | any,
                    [transform_fun] | [transform_fun_any])
        :: Param.t | any
  def until_error(%Param{error: err} = param, _) when err != nil, do: param
  def until_error(%Param{} = param, []), do: param
  def until_error(%Param{} = param, [fun | rest]),
    do: until_error(fun.(param), rest)

  def until_error({:error, _} = val, _), do: val
  def until_error({:ok, val}, []), do: {:ok, val}
  def until_error({:ok, val}, [fun | rest]), do: until_error(fun.(val), rest)
  def until_error(val, funs), do: until_error({:ok, val}, funs)

  @compile {:inline, on_error: 1}
  @spec on_error(Param.t) :: Mod.on_error
  defp on_error(%Param{mod: %Mod{on_error: on_error}}), do: on_error
end

defmodule ExConfig.Param.TypeOptionError do
  alias __MODULE__
  defexception message: "Type option error",
               type: nil, name: nil, value: nil

  def message(%TypeOptionError{type: type, name: name, value: value})
              when type != nil and name != nil and value != nil,
    do: "Wrong value '#{inspect(value)}' for option #{type}::#{name}"

  def message(err), do: err.message
end
