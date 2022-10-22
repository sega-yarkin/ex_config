defmodule ExConfig.Cache.InModule do
  @moduledoc """
  """
  @behaviour ExConfig.Cache
  alias ExConfig.Mod

  @type opts() :: [{:target, module()}, ...]

  @impl ExConfig.Cache
  @spec wrap(module(), opts()) :: {:ok, module()}
  def wrap(source, target: target), do: compile_module(source, target)

  @impl ExConfig.Cache
  @spec get(opts()) :: module()
  def get(target: target), do: target


  @spec compile_module(module(), module()) :: {:ok, module()}
  defp compile_module(source, target) do
    meta = source.__meta__()
    data = source._all()

    :ok = generate_keyword_modules(meta, target)
    parameters = get_parameters_quote(meta, data)
    resources = get_resources_quote(meta, source)
    all = get_all_quote(data)

    content = List.flatten([parameters, all, resources])
    {:module, module, _, _} =
        Module.create(target, content, Macro.Env.location(__ENV__))
    {:ok, module}
  end

  defp get_parameters_quote(meta, data) do
    for {name, _} <- Keyword.fetch!(meta, :parameters) do
      quote do
        def unquote(name)(), do: unquote(Macro.escape(data[name]))
      end
    end
  end

  defp generate_keyword_modules(meta, target) do
    keywords = Keyword.fetch!(meta, :keywords)

    Enum.each(keywords, fn {name, mod} ->
      mod_target = Mod.child_mod_name(target, name)
      {:ok, _} = compile_module(mod, mod_target)
    end)
  end

  defp get_resources_quote(meta, source) do
    for {_name, %{one: one, all: all}} <- Keyword.fetch!(meta, :resources) do
      instances = apply(source, all, [])

      quote do
        def unquote(all)(), do: unquote(Macro.escape(instances))
        def unquote(one)(name), do: unquote(all)()[name]
      end
    end
  end

  defp get_all_quote(data) do
    quote do
      def _all(), do: unquote(Macro.escape(data))
    end
  end
end
