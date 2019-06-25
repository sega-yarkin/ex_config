defmodule ExConfig.Cache.InModule do
  alias ExConfig.Mod

  def wrap(source, target: target) do
    compile_module(source, target)
  end


  defp compile_module(source, target) do
    meta = source.__meta__()
    data = source._all()

    parameters =
      for {name, _} <- meta[:parameters] do
        quote do
          def unquote(name)(), do: unquote(Macro.escape(data[name]))
        end
      end

    for {name, mod} <- meta[:keywords] do
      mod_target = Mod.child_mod_name(target, name)
      {:ok, _} = compile_module(mod, mod_target)
    end

    resources =
      for {_name, %{one: one, all: all}} <- meta[:resources] do
        instances = apply(source, all, [])
        quote do
          def unquote(all)(), do: unquote(Macro.escape(instances))
          def unquote(one)(name), do: unquote(all)()[name]
        end
      end

    all =
      quote do
        def _all(), do: unquote(Macro.escape(data))
      end

    content = List.flatten([parameters, all, resources])
    {:module, module, _, _} =
        Module.create(target, content, Macro.Env.location(__ENV__))
    {:ok, module}
  end

end
