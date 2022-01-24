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
    options:  Keyword.t(),
    on_error: on_error(),
  }

  @type on_error() :: :default | :tuple | :throw
  @type mod_opts() :: [only_not_nil: boolean()]

  @type mod_params() :: [otp_app: atom(),
                         path: list(atom()),
                         options: mod_opts(),
                         on_error: on_error()]

  @self __MODULE__
  # credo:disable-for-next-line Credo.Check.Refactor.Apply
  @test_env? function_exported?(Mix, :env, 0) and apply(Mix, :env, []) in [:dev, :test]

  @spec __using__(mod_params | Mod.t) :: Macro.t
  defmacro __using__(opts) do
    data = opts_to_mod(opts, __CALLER__)
    Module.put_attribute(Map.fetch!(__CALLER__, :module), :data, data)
    quote do
      import unquote(@self)
      @before_compile unquote(@self)
      @behaviour ExConfig.Resource

      Module.register_attribute(__MODULE__, :data, persist: unquote(@test_env?))
      @data unquote(Macro.escape(data))
      Module.register_attribute(__MODULE__, :parameters, accumulate: true)
      Module.register_attribute(__MODULE__, :keywords, accumulate: true)
      Module.register_attribute(__MODULE__, :resources, accumulate: true)

      @compile {:inline, __mod_data__: 0}
      defp __mod_data__(), do: unquote(Macro.escape(data))

      defp __resource_mod__(name, options) do
        mod = %{path: path} = __mod_data__()
        %{mod | path: path ++ [name], options: options}
      end
    end
  end

  @spec env(atom, module, Keyword.t) :: Macro.t
  defmacro env(name, type \\ Type.Raw, opts \\ []) do
    quote do
      @param unquote(@self).__env__(@data, unquote(name), unquote(type), unquote(opts))
      @parameters {unquote(name), @param}
      @spec unquote(name)() :: unquote(type).result()
                             | {:ok, unquote(type).result()}
                             | {:error, String.t}
                             | no_return
      def unquote(name)(), do: unquote(name)(__mod_data__())

      @doc false
      def unquote(name)(%Mod{} = mod) do
        get_env(%{__parameter__(unquote(name)) | mod: mod})
      end
    end
  end

  @spec __env__(Mod.t, atom, module, keyword) :: Param.t
  def __env__(%Mod{options: mod_opts}, name, type, opts) do
    opts = Keyword.merge(mod_opts, opts)
    Param.init(nil, name, type, opts)
  end

  @spec dyn(atom, Keyword.t) :: Macro.t
  defmacro dyn(name, do: block) do
    quote do
      @parameters {unquote(name), nil}
      def unquote(name)(), do: unquote(block)
      defp unquote(name)(_), do: unquote(name)()
    end
  end

  @spec keyword(atom, Keyword.t) :: Macro.t
  defmacro keyword(name, do: block) do
    {mod_name, opts} = child_mod(Map.fetch!(__CALLER__, :module), name)
    quote do
      @keywords {unquote(name), unquote(mod_name)}
      defmodule unquote(mod_name) do
        use unquote(@self), unquote(opts)
        unquote(block)
      end
    end
  end

  @spec resource(atom, atom, Keyword.t) :: Macro.t
  defmacro resource(name, list \\ nil, block_or_opts)
  defmacro resource(name, list, do: block) do
    {mod_name, opts} = child_mod(Map.fetch!(__CALLER__, :module), name)
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


  @spec __before_compile__(Keyword.t) :: Macro.t
  defmacro __before_compile__(_env) do
    module = Map.fetch!(__CALLER__, :module)
    parameters = get_all_parameters_quote(module)
    [
      get_parameters_data_quote(module),
      get_all_quote(module),

      quote do
        def __meta__() do
          [
            parameters: unquote(parameters),
            keywords:   @keywords,
            resources:  @resources,
          ]
        end
      end
    ] |> List.flatten()
  end

  @spec get_env(Param.t) :: any | {:error, String.t} | {:ok, any} | no_return
  def get_env(%Param{} = param), do: Param.read(param)

  @spec reject_nil_values(Keyword.t) :: Keyword.t
  def reject_nil_values([{_, nil} | tail]), do: reject_nil_values(tail)
  def reject_nil_values([head     | tail]), do: [head | reject_nil_values(tail)]
  def reject_nil_values([]), do: []

  @spec opts_to_mod(Mod.t | Keyword.t, Macro.Env.t) :: Mod.t
  defp opts_to_mod(%Mod{} = mod, _), do: mod
  defp opts_to_mod(opts, env) when is_list(opts) do
    opts = expand_ast_kw([otp_app: :basic, path: :list,
                          options: :kw, on_error: :basic],
                         opts, env)
    struct(Mod, opts)
  end

  @spec expand_ast(atom, any, Macro.Env.t) :: any
  defp expand_ast(:basic, value, env), do: Macro.expand(value, env)
  defp expand_ast(:list, values, env), do: Enum.map(values, &Macro.expand(&1, env))
  defp expand_ast(:kw, pairs, env) do
    for {key, value} <- pairs, do: {key, Macro.expand(value, env)}
  end

  @spec expand_ast_kw(Keyword.t, Keyword.t, Macro.Env.t) :: Keyword.t
  defp expand_ast_kw(meta, pairs, env) do
    for {key, type}  <- meta,
        {:ok, value} <- [Keyword.fetch(pairs, key)] do
      {key, expand_ast(type, value, env)}
    end
  end

  @spec camelize_atom(atom) :: atom
  def camelize_atom(value) when is_atom(value) do
    value |> Atom.to_string() |> Macro.camelize() |> String.to_atom()
  end

  @spec child_mod_name(module, atom) :: module
  def child_mod_name(parent, name) do
    Module.concat(parent, camelize_atom(name))
  end

  @spec extend_path(Mod.t, atom) :: Mod.t
  def extend_path(%Mod{path: path} = val, name) do
    %{val | path: path ++ [name]}
  end

  @spec child_mod(module, atom) :: {module, Mod.t}
  defp child_mod(parent, name) do
    mod_name = child_mod_name(parent, name)
    opts =
      parent
      |> Module.get_attribute(:data)
      |> extend_path(name)
    {mod_name, opts}
  end


  @spec get_parameters_data_quote(module) :: Macro.t
  defp get_parameters_data_quote(module) do
    parameters =
      module
      |> Module.get_attribute(:parameters)
      |> Enum.filter(fn {_, param} -> param != nil end)

    [
      quote do
        @compile {:inline, __parameter__: 1}
        @dialyzer {:nowarn_function, __parameter__: 1}
      end,
      Enum.map(parameters, fn {name, param} ->
        quote do
          defp __parameter__(unquote(name)), do: unquote(Macro.escape(param))
        end
      end),
      quote do
        defp __parameter__(_), do: nil
      end
    ]
  end

  @spec get_all_parameters_quote(module) :: Macro.t
  defp get_all_parameters_quote(module) do
    parameters = Module.get_attribute(module, :parameters)
    Enum.map(parameters, fn {name, _} ->
      quote [], do: {unquote(name), __parameter__(unquote(name))}
    end)
  end

  @spec get_resource_funs_quote(module, atom, atom, Keyword.t) :: Macro.t
  defp get_resource_funs_quote(mod_name, name, list, opts \\ [])
  defp get_resource_funs_quote(mod_name, name, nil, opts) do
    quote do
      def unquote(name)() do
        mod = __resource_mod__(unquote(name), unquote(Macro.escape(opts)))
        unquote(mod_name)._all(mod)
      end
    end
  end

  defp get_resource_funs_quote(mod_name, name, list, opts) do
    one = :"get_#{name}"
    all = :"get_#{list}"
    quote do
      @resources {unquote(name), %{one: unquote(one), all: unquote(all)}}

      def unquote(one)(name) do
        mod = __resource_mod__(name, unquote(Macro.escape(opts)))
        unquote(mod_name)._all(mod)
      end

      def unquote(all)() do
        Enum.map(unquote(list)(), &{&1, unquote(one)(&1)})
      end
    end
  end

  @spec get_all_quote(module) :: Macro.t
  defp get_all_quote(module) do
    mod_attr = &Module.get_attribute(module, &1)

    parameters =
      Enum.map(mod_attr.(:parameters), fn {name, _} ->
        quote [], do: {unquote(name), unquote(name)(mod)}
      end)

    keywords =
      Enum.map(mod_attr.(:keywords), fn {name, module} ->
        quote do
          {unquote(name),
           unquote(module)._all(extend_path.(unquote(name)))}
        end
      end)

    all = Keyword.merge(parameters, keywords) |> Enum.sort()
    own_options = Map.get(mod_attr.(:data), :options, [])

    quote do
      def _all(), do: _all(__mod_data__())
      def _all(%Mod{options: options} = mod) do
        options = Keyword.merge(unquote(own_options), options)
        mod = %{mod | options: options}
        extend_path = &ExConfig.Mod.extend_path(mod, &1)
        res = unquote(all)
        case Keyword.get(options, :only_not_nil, false) do
          true  -> ExConfig.Mod.reject_nil_values(res)
          false -> res
        end
      end
    end
  end

end
