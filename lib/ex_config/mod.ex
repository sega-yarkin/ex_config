defmodule ExConfig.Mod do
  alias __MODULE__
  alias ExConfig.Param
  alias ExConfig.Type

  defstruct otp_app: nil,
            path: [],
            options: []

  @type t() :: %__MODULE__{
    otp_app: atom(),
    path:    [atom()],
    options: keyword(),
  }

  @type mod_opts() :: [only_not_nil: boolean()]

  @type mod_params() :: [otp_app: atom(),
                         path: list(atom()),
                         options: mod_opts()]

  @self __MODULE__

  @spec __using__(mod_params | %Mod{}) :: Macro.t
  defmacro __using__(opts) do
    data = opts_to_mod(opts)
    mod = __CALLER__.module
    Module.put_attribute(mod, :data, data)
    Module.register_attribute(mod, :exports, accumulate: true)
    Module.register_attribute(mod, :keywords, accumulate: true)
    Module.register_attribute(mod, :resources, accumulate: true)
    quote do
      import unquote(@self)
      @before_compile unquote(@self)
      @behaviour ExConfig.Resource
    end
  end

  @spec env(atom, module, keyword) :: Macro.t
  defmacro env(name, type \\ Type.Raw, opts \\ []) do
    mod   = Module.get_attribute(__CALLER__.module, :data)
    opts  = prepare_opts(mod, opts)
    param = Param.init(mod, name, Macro.expand(type, __CALLER__), opts)
    quote do
      @exports unquote(name)
      def unquote(name)(), do: unquote(name)(@data)
      defp unquote(name)(%Mod{} = mod) do
        unquote(Macro.escape(param))
        |> Map.put(:mod, mod)
        |> get_env()
      end
    end
  end

  @spec dyn(atom, keyword) :: Macro.t
  defmacro dyn(name, do: block) do
    quote do
      @exports unquote(name)
      def unquote(name)(), do: unquote(block)
      defp unquote(name)(_), do: unquote(name)()
    end
  end

  @spec keyword(atom, keyword) :: Macro.t
  defmacro keyword(name, do: block) do
    {mod_name, opts} = child_mod(__CALLER__.module, name)
    quote do
      @keywords unquote(name)
      defmodule unquote(mod_name) do
        use unquote(@self), unquote(opts)
        unquote(block)
      end
    end
  end

  @spec resource(atom, atom, keyword) :: Macro.t
  defmacro resource(name, list, do: block) do
    {mod_name, opts} = child_mod(__CALLER__.module, name)
    [
      quote do
        defmodule unquote(mod_name) do
          use unquote(@self), unquote(opts)
          unquote(block)
        end
      end,
      get_resource_funs_quote(mod_name, name, list),
    ]
  end

  defmacro resource(name, list, [{:use, mod_name} | opts]) do
    mod_name = Macro.expand(mod_name, __CALLER__)
    get_resource_funs_quote(mod_name, name, list, opts)
  end


  @spec __before_compile__(keyword) :: Macro.t
  defmacro __before_compile__(_env) do
    all =
      __CALLER__.module
      |> Module.get_attribute(:exports)
      |> Enum.reverse() # Sort by name?
      |> Enum.map(&quote [], do: {unquote(&1), unquote(&1)(mod)})

    own_options =
      __CALLER__.module
      |> Module.get_attribute(:data)
      |> Map.get(:options, [])

    quote do
      def _all(), do: _all(@data)
      def _all(%Mod{} = mod) do
        opts = Keyword.merge(unquote(own_options), mod.options)
        mod = %Mod{mod | options: opts}
        unquote(all)
        |> maybe_filter_nil(opts[:only_not_nil])
      end

      defp maybe_filter_nil(res, true),
        do: Enum.reject(res, fn {_, v} -> is_nil(v) end)
      defp maybe_filter_nil(res, _), do: res
    end
  end


  @spec get_env(%Param{}) :: any | {:error, String.t}
  def get_env(%Param{} = param) do
    param
    |> Param.read_app_env()
    |> Param.get_nested()
    |> Param.maybe_invoke_source()
    |> Param.convert_data()
    |> Param.check_requirement()
    |> Param.maybe_handle_error()
    |> Param.maybe_transform()
    |> Param.get_result()
  end


  @spec opts_to_mod(%Mod{} | keyword) :: %Mod{}
  defp opts_to_mod(%Mod{} = mod), do: mod
  defp opts_to_mod(opts) do
    struct(Mod, Keyword.take(opts, [:otp_app, :path, :options]))
  end

  @spec prepare_opts(%Mod{}, keyword) :: keyword
  defp prepare_opts(mod, opts) do
    opts = for {name, val} <- opts,
               {val, _} = Code.eval_quoted(val),
            do: {name, val}
    Keyword.merge(mod.options, opts)
  end


  @spec capitalize_atom(atom) :: atom
  defp capitalize_atom(value),
    do: value |> to_string() |> String.capitalize() |> String.to_atom()

  @spec child_mod_name(module, atom) :: module
  defp child_mod_name(parent, name),
    do: Module.concat(parent, capitalize_atom(name))

  @spec extend_path(%Mod{}, atom) :: %Mod{}
  defp extend_path(%Mod{path: path} = val, name),
    do: %Mod{val | path: path ++ [name]}

  @spec child_mod(module, atom) :: {module, %Mod{}}
  defp child_mod(parent, name) do
    mod_name = child_mod_name(parent, name)
    opts =
      parent
      |> Module.get_attribute(:data)
      |> extend_path(name)
    {mod_name, opts}
  end


  @spec get_resource_funs_quote(module, atom, atom, keyword) :: Macro.t
  defp get_resource_funs_quote(mod_name, name, list, opts \\ []) do
    single = String.to_atom("get_#{name}")
    all    = String.to_atom("get_#{list}")
    quote do
      @resources {unquote(single), unquote(all)}

      def unquote(single)(name) do
        mod =
          @data
          |> Map.update!(:path, &(&1 ++ [name]))
          |> Map.put(:options, unquote(Macro.escape(opts)))
        apply(unquote(mod_name), :_all, [mod])
      end

      def unquote(all)() do
        for name <- unquote(list)(), do: {name, unquote(single)(name)}
        # names  = unquote(list)()
        # values = Enum.map(names, &(unquote(single)(&1)))
        # Enum.zip(names, values)
      end
    end
  end

end
