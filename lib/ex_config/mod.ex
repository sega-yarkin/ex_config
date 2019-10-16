defmodule ExConfig.Mod do
  alias __MODULE__
  alias ExConfig.Param
  alias ExConfig.Type

  defstruct otp_app: nil,
            path: [],
            options: [],
            on_error: :throw

  @type t() :: %__MODULE__{
    otp_app:  atom(),
    path:     [atom()],
    options:  keyword(),
    on_error: on_error(),
  }

  @type on_error() :: :default | :tuple | :throw
  @type mod_opts() :: [only_not_nil: boolean()]

  @type mod_params() :: [otp_app: atom(),
                         path: list(atom()),
                         options: mod_opts(),
                         on_error: on_error()]

  @self __MODULE__
  @test_env? function_exported?(Mix, :env, 0) and apply(Mix, :env, []) == :test

  @spec __using__(mod_params | %Mod{}) :: Macro.t
  defmacro __using__(opts) do
    data = opts_to_mod(opts)
    Module.put_attribute(__CALLER__.module, :data, data)
    quote do
      import unquote(@self)
      @before_compile unquote(@self)
      @behaviour ExConfig.Resource

      Module.register_attribute(__MODULE__, :data, persist: unquote(@test_env?))
      @data unquote(Macro.escape(data))
      Module.register_attribute(__MODULE__, :parameters, accumulate: true)
      Module.register_attribute(__MODULE__, :keywords, accumulate: true)
      Module.register_attribute(__MODULE__, :resources, accumulate: true)
    end
  end

  @spec env(atom, module, keyword) :: Macro.t
  defmacro env(name, type \\ Type.Raw, opts \\ []) do
    quote do
      @param unquote(@self).__env__(@data, unquote(name), unquote(type), unquote(opts))
      @parameters {unquote(name), @param}
      def unquote(name)(), do: unquote(name)(@data)
      def unquote(name)(%Mod{} = mod) do
        get_env(%{@param | mod: mod})
      end
    end
  end

  def __env__(mod, name, type, opts) do
    opts  = Keyword.merge(mod.options, opts)
    Param.init(mod, name, type, opts)
  end

  @spec dyn(atom, keyword) :: Macro.t
  defmacro dyn(name, do: block) do
    quote do
      @parameters {unquote(name), nil}
      def unquote(name)(), do: unquote(block)
      defp unquote(name)(_), do: unquote(name)()
    end
  end

  @spec keyword(atom, keyword) :: Macro.t
  defmacro keyword(name, do: block) do
    {mod_name, opts} = child_mod(__CALLER__.module, name)
    quote do
      @keywords {unquote(name), unquote(mod_name)}
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
    [
      get_all_quote(__CALLER__.module),

      quote do
        def __meta__() do
          [
            parameters: @parameters,
            keywords:   @keywords,
            resources:  @resources,
          ]
        end
      end
    ]
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
    struct(Mod, Keyword.take(opts, [:otp_app, :path, :options, :on_error]))
  end


  @spec capitalize_atom(atom) :: atom
  def capitalize_atom(value),
    do: value |> to_string() |> String.capitalize() |> String.to_atom()

  @spec child_mod_name(module, atom) :: module
  def child_mod_name(parent, name),
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
    one = String.to_atom("get_#{name}")
    all = String.to_atom("get_#{list}")
    quote do
      @resources {unquote(name), %{one: unquote(one), all: unquote(all)}}

      def unquote(one)(name) do
        mod =
          @data
          |> Map.update!(:path, &(&1 ++ [name]))
          |> Map.put(:options, unquote(Macro.escape(opts)))

        apply(unquote(mod_name), :_all, [mod])
      end

      def unquote(all)() do
        for name <- unquote(list)(), do: {name, unquote(one)(name)}
      end
    end
  end

  @spec get_all_quote(module) :: Macro.t
  defp get_all_quote(module) do
    mod_attr = &(Module.get_attribute(module, &1))

    parameters =
      for {name, _} <- mod_attr.(:parameters) do
        quote [], do: {unquote(name), unquote(name)(mod)}
      end

    keywords =
      for {name, mod} <- mod_attr.(:keywords) do
        quote [], do: {unquote(name), unquote(mod)._all()}
      end

    all = Keyword.merge(parameters, keywords) |> Enum.sort()
    own_options = Map.get(mod_attr.(:data), :options, [])

    quote do
      def _all(), do: _all(@data)
      def _all(%Mod{} = mod) do
        opts = Keyword.merge(unquote(own_options), mod.options)
        mod = %Mod{mod | options: opts}
        unquote(all)
        |> maybe_filter_nil(opts[:only_not_nil])
      end

      @compile {:inline, maybe_filter_nil: 2}
      defp maybe_filter_nil(res, true),
        do: Enum.reject(res, fn {_, v} -> is_nil(v) end)
      defp maybe_filter_nil(res, _), do: res
    end
  end

end
