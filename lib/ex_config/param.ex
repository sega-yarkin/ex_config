defmodule ExConfig.Param do
  alias __MODULE__
  alias ExConfig.Mod

  defstruct mod: nil,
            name: nil,
            type: nil,
            default: nil,
            required?: false,
            transform: [],
            data: nil,
            exist?: false,
            error: nil

  @type t() :: %__MODULE__{
    mod:        Mod.t(),
    name:       atom(),
    type:       struct(),
    default:    any(),
    required?:  boolean(),
    transform:  [transform_fun()],
    #
    data:       any(),
    exist?:     boolean(),
    error:      any(),
  }

  @type transform_fun() :: (Param.t() -> Param.t())
  @type transform_fun_any() :: (any() -> {:ok | :error, any()})

  @spec init(Mod.t() | nil, atom(), module(), Keyword.t()) :: Param.t()
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
      transform: List.wrap(transform),
    }
  end

  @spec create_type_instance(module(), Keyword.t()) :: struct()
  def create_type_instance(type, opts) do
    type.validators()
    |> ExConfig.Type.validate_options!(opts, type)
    |> type.init()
  end

  @spec read(Param.t()) :: any() | no_return()
  def read(%Param{} = param) do
    param
    |> read_app_env()
    |> maybe_invoke_source()
    |> convert_data()
    |> check_requirement()
    |> maybe_handle_error()
    |> maybe_transform()
    |> get_result()
  end

  @spec read_app_env(Param.t()) :: Param.t()
  def read_app_env(%Param{name: name,
                          mod: %Mod{path: [], otp_app: otp_app}} = param) do
    case :application_controller.get_env(otp_app, name) do
      {:ok, data} -> %{param | data: data, exist?: true}
      :undefined  -> param
    end
  end

  def read_app_env(%Param{name: name,
                          mod: %Mod{path: [key | rest_path],
                                    otp_app: otp_app}} = param) do
    case :application_controller.get_env(otp_app, key) do
      {:ok, data} ->
        case get_nested(data, rest_path ++ [name]) do
          {:ok, data} -> %{param | data: data, exist?: true}
          :error      -> param
        end

      :undefined ->
        param
    end
  end

  @spec get_nested(any(), [any()]) :: {:ok, any()} | :error
  defp get_nested(data, path) do
    case {data, path} do
      {nil, _} -> :error
      {data, [key]} -> Access.fetch(data, key)
      {data, [key | rest]} -> get_nested(Access.get(data, key), rest)
    end
  end

  @spec maybe_invoke_source(Param.t()) :: Param.t()
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

  @spec convert_data(Param.t()) :: Param.t()
  def convert_data(%Param{exist?: true, error: nil,
                          data: data, type: type} = param) do
    type_module = Map.fetch!(type, :__struct__)

    data =
      if is_list(data) and not type_module.preserve_charlist?(),
        do: to_string(data),
        else: data

    case type_module.handle(data, type) do
      {:ok, data}      -> %{param | data: data}
      {:error, reason} -> %{param | error: reason}
    end
  end

  def convert_data(param), do: param

  @spec check_requirement(Param.t()) :: Param.t()
  def check_requirement(%Param{error: nil, required?: true, data: nil,
                               name: name} = param) do
    %{param | error: "Parameter '#{name}' must be set"}
  end

  def check_requirement(param), do: param

  @spec maybe_handle_error(Param.t()) :: Param.t() | no_return()
  def maybe_handle_error(%Param{error: nil} = param), do: param
  def maybe_handle_error(%Param{error: err, mod: %Mod{on_error: :throw}}), do: throw(err)
  def maybe_handle_error(%Param{} = param), do: %{param | error: nil, data: nil}

  @spec maybe_transform(Param.t()) :: Param.t()
  def maybe_transform(%Param{transform: [_|_] = funs} = param) do
    Enum.reduce(funs, param, &transform/2)
  end

  def maybe_transform(param), do: param

  @spec transform(transform_fun() | {module(), atom()}, Param.t()) :: Param.t()
  defp transform(fun, val) when is_function(fun), do: fun.(val)
  defp transform({m, f}, val) when is_atom(m) and is_atom(f), do: apply(m, f, [val])


  @spec get_result(Param.t()) :: any()
  def get_result(%Param{error: reason}) when reason != nil do
    {:error, reason}
  end

  def get_result(%Param{data: data, default: default}) do
    case {data, default} do
      {nil, default} when is_function(default, 0) -> default.()
      {nil, default} -> default
      {data, _}      -> data
    end
  end
end
